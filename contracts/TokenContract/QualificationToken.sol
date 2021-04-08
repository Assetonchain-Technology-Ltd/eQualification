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
    
    function grantQualification(address _workerprofile,address _individual) public {
        require(_orgAccessCheck(msg.sender,ISSUE),"QT05");
        bytes32 hashname = Utility._computeNamehash(qFactory);
        address resolverAddr = ens.resolver(hashname);
        Resolver res = Resolver(resolverAddr);
        address _a = res.addr(hashname);
        bytes memory payload = abi.encodeWithSignature("createNewQualificaitonContract(address,address)",_individual,orgRoot);
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"QT08");
        address qaddress = abi.decode(result, (address)); 
        _mint(_workerprofile,uint256(qaddress));
        
        hashname = Utility._computeNamehash(name());
        _a = ens.owner(hashname);
        bytes32 fullhashname = keccak256(abi.encodePacked(hashname, keccak256(abi.encodePacked(_individual))));
        res.setAddr(fullhashname,qaddress);
        if(!ens.recordExists(fullhashname))
            ens.setSubnodeRecord(hashname,keccak256(abi.encodePacked(_individual)),_a,resolverAddr,120000); 
        
        
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