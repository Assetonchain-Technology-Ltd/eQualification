pragma solidity >=0.7.0;
// SPDX-License-Identifier: GPL-3.0-or-later
pragma abicoder v2;
import "../Utils/ENS.sol";
import "../Utils/Resolver.sol";
import "../Utils/Roles.sol";
import "../Utils/RBAC.sol";
import "../Utils/Library.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";


contract QualificationToken is ERC721Pausable,ERC721Burnable,Roles {
    event NewQualificationToken(string _name,address _a,uint256 _tokenid);
    
    
    address orgRoot;
    PermissionControl access;
    string[] ensnode;
    string qFactory;
    ENS ens;
    address parent=address(0);
    
    constructor(string memory _name,string memory _syb,string memory _qFactory ,address _orgENSRoot) ERC721(_name,_syb)
    {
        require(Utility._checkInterfaceID(_orgENSRoot,Utility.INTERFACE_ID_ENSREGISTRY),"QT01");
        ens = ENS(_orgENSRoot);
        require(_orgAccessCheck(msg.sender,ISSUE) || _orgAccessCheck(msg.sender,ADMIN),"QT02");
        bytes32 hashname = Utility._computeNamehash(_name);
        require(ens.recordExists(hashname),"QT03");
        
        hashname = Utility._computeNamehash(_qFactory);
        Resolver res = Resolver(ens.resolver(hashname));
        address a = res.addr(hashname);
        require(Utility._checkInterfaceID(a,Utility.INTERFACE_ID_QUALIFICATIONFACTORY),"QT04");
        
        
        hashname = Utility._computeParentNamehash(_name);
        if(hashname!=0x0000000000000000000000000000000000000000000000000000000000000000){
            res = Resolver(ens.resolver(hashname));
            a = res.addr(hashname);
            require(a!=address(0),"QT04A" );
            if(Utility._checkInterfaceID(a,Utility.INTERFACE_ID_QUALIFICATIONTOKEN))
                parent=a;
        }
        _pause();
        ensnode=Utility.split(_name);
        qFactory = _qFactory;
        orgRoot=_orgENSRoot;
    }
    
    function grantQualification(address _individual,address payable _to) public {
        require(_orgAccessCheck(msg.sender,ISSUE),"QT05");
        if(parent!=address(0)){
            require(Utility._checkInterfaceID(_to,Utility.INTERFACE_ID_QUALIFICATIONPROXY),"QT06");
            require(_isOwnerOf(uint256(_to),_individual,2),"QT12");
        }else{
            require(Utility._checkInterfaceID(_to,Utility.INTERFACE_ID_WORKERPROFILE),"QT07");
            require(_isOwnerOf(uint256(_to),_individual,1),"QT13");
        }
        bytes32 hashname = Utility._computeNamehash(qFactory);
        Resolver res = Resolver(ens.resolver(hashname));
        address _a = res.addr(hashname);
        bytes memory payload = abi.encodeWithSignature("createNewQualificaitonContract(address,address)",_individual,orgRoot);
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"QT08");
        address qaddress = abi.decode(result, (address)); 
        _mint(_to,uint256(qaddress));
        emit NewQualificationToken(name(),qaddress,uint256(qaddress));
    }
    
     function _mint(address to, uint256 tokenId) internal virtual override(ERC721) {
        require(_orgAccessCheck(msg.sender,ISSUE),"QT09");
        super._mint(to,tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    
    function _orgAccessCheck(address _caller,bytes32 _role) internal 
    returns(bool)
    {
        bytes32 orgAccessENS = Utility._computeNamehash(ens.getPredefineENSPrefix("access"));
        Resolver res = Resolver(ens.resolver(orgAccessENS));
        require(res.addr(orgAccessENS)!=address(0) && res.supportsInterface(Utility.ADDR_INTERFACE_ID),"QL07");
        address orgAccessAdr = res.addr(orgAccessENS);
        access = PermissionControl(orgAccessAdr);
        return access.hasRole(_role,_caller);
        
    }
    
    //Normal case : _tokenid is workerprofile tokenid , check if _tokenid is owned by _owner
    //Multi case : _tokenid is parent's tokenid ,  worker profile is the owner of parnet token 
    function _isOwnerOf(uint256 _tokenid,address _owner,uint256 _type) internal
    returns(bool)
    {
        address a;
        uint8 mask;
        mask = (parent!=address(0))?((_type!=1)?mask:(mask|1)):mask;
        mask = (parent==address(0))?((_type==1)?mask:(mask|2)):mask;
        require(mask==0,"QT14");
        string memory t = ens.getPredefineENSPrefix("pub");
        require(keccak256(bytes(t))!=keccak256(""),"QT15");
        bytes32 namehash = Utility._computeNamehash(t);
        Resolver res = Resolver(ens.resolver(namehash));
        a = res.addr(namehash);
        require(Utility._checkInterfaceID(a,Utility.INTERFACE_ID_ENSREGISTRY),"QT16");
        ENS pubENS = ENS(a);
        t = pubENS.getPredefineENSPrefix("workerprofile");
        require(keccak256(bytes(t))!=keccak256(""),"QT17");
        namehash = Utility._computeNamehash(t);
        res = Resolver(pubENS.resolver(namehash));
        require(res.addr(namehash)!=address(0) && Utility._checkInterfaceID(res.addr(namehash),Utility.INTERFACE_ID_WORKERTOKEN),"QT18");
        a = res.addr(namehash);
        //token is workerprofiletoken
        ERC721 token = ERC721(a);
        if(_type==1){
            //Normal token case
            return (token.ownerOf(_tokenid) == _owner);
        }
        // Multi token case , _tokenid is parent's tokenid , check ( getowner of it == _ower's wp address )
        uint256 wpid = token.tokenOfOwnerByIndex(_owner,0);
        //token is change to parent now
        token =ERC721(parent);
        return (token.ownerOf(_tokenid)==address(wpid));
        
    }
    
    function getParent() public view
    returns(address)
    {
        return parent;
    }
    
    function qualificationToken() public{}
    
    function supportsInterface(bytes4 interfaceId) public virtual override(ERC165) view returns (bool) {
        return interfaceId == Utility.INTERFACE_ID_QUALIFICATIONTOKEN;
    }
    
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override (ERC721,ERC721Pausable) {
        if(!_orgAccessCheck(msg.sender,ISSUE)){
            super._beforeTokenTransfer(from,to,tokenId);
        }
        
    }
    
    
}