pragma solidity >=0.7.0;
pragma abicoder v2;
import "../Utils/ENS.sol";
import "../Utils/Resolver.sol";
import "../Utils/Roles.sol";
import "../Utils/access.sol";
import "../Utils/Library.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";


contract QualificationToken is ERC721Pausable,ERC721Burnable,Roles {
    
    address private orgRoot;
    PermissionControl access;
    string[] ensnode;
    string qFactory;
    ENS ens;
    address parent=address(0);
    
    constructor(string memory _name,string memory _syb,string memory _qFactory ,address _orgENSRoot) ERC721(_name,_syb)
    {
        ens = ENS(_orgENSRoot);
        require(_orgAccessCheck(msg.sender,ISSUE),"QT01");
        bytes32 hashname = Utility._computeNamehash(_name);
        require(ens.recordExists(hashname)==false,"QT02");
        
        hashname = Utility._computeNamehash(_qFactory);
        require(ens.recordExists(hashname),"QT03");
        Resolver res = Resolver(ens.resolver(hashname));
        address a = res.addr(hashname);
        require(_checkInterfaceID(a,Utility.INTERFACE_ID_QUALIFICATIONFACTORY),"QT04");
        
    
        hashname = Utility._computeParentNamehash(_name);
        res = Resolver(ens.resolver(hashname));
        a = res.addr(hashname);
        require(parent!=address(0) && (res.supportsInterface(Utility.ADDR_INTERFACE_ID) || res.supportsInterface(Utility.ORG_INTERFACE_ID)),"QT04" );
        
        if(_checkInterfaceID(a,Utility.INTERFACE_ID_ERC721))
            parent=a;
        _pause();
        ensnode=Utility.split(_name);
        qFactory = _qFactory;
        orgRoot=_orgENSRoot;
    }
    
    function grantQualification(address _individual,address payable _to, bytes memory _cert) public {
        require(_orgAccessCheck(msg.sender,ISSUE),"QT05");
        if(parent!=address(0)){
            require(_checkInterfaceID(_to,Utility.INTERFACE_ID_QUALIFICATIONPROXY),"QT06");
        }else{
            require(_checkInterfaceID(_to,Utility.INTERFACE_ID_WORKERPROFILE),"QT07");
        }
        bytes32 hashname = Utility._computeNamehash(qFactory);
        Resolver res = Resolver(ens.resolver(hashname));
        address _a = res.addr(hashname);
        bytes memory payload = abi.encodeWithSignature("createNewQualificaitonContract(address,address) ",_individual,orgRoot);
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"QT08");
        address qaddress = abi.decode(result, (address)); 
        _mint(_to,uint256(qaddress));
             
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
    
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override (ERC721,ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);

    }
    
    function _checkInterfaceID(address _a,bytes4 _interfaceID) internal 
    returns(bool)
    {
        bytes memory payload = abi.encodeWithSignature("supportsInterface(bytes4)",_interfaceID);
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"QT");
        return abi.decode(result, (bool));
    }

    
}