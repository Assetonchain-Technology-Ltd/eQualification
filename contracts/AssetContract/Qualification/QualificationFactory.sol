pragma solidity >=0.6.0;

import "./QualificationProxy.sol";
import "../../Utils/Roles.sol";
import "../../Utils/Library.sol";
import "../../Utils/ENSRegistry.sol";
import "../../Utils/Resolver.sol";

contract QualificationFactory is Roles{
    
    
    address orgENSRegistar;
    string implementENS;
    string attributeENS;
    ENS ens;
    PermissionControl access;
    
    constructor(address _orgENSRegistar,string memory _imp,string memory _attlist) public {
        require(_orgENSRegistar!=address(0),"QF01");
        ens = ENS(_orgENSRegistar);
        require(_orgAccessCheck(msg.sender,ADMIN),"QF02");
        orgENSRegistar=_orgENSRegistar;
        implementENS=_imp;
        attributeENS=_attlist;
    
    }
    
    function updateOrgENSRegistar(address _a) public {
        require(_orgAccessCheck(msg.sender,ADMIN),"QF03");
        ens = ENS(_a);
        orgENSRegistar=_a;
    }
    
    function updateImplementationENS(string memory _imp) public {
        require(_orgAccessCheck(msg.sender,ADMIN),"QF04");
        bytes32 namehash = Utility._computeNamehash(_imp);
        require(ens.recordExists(namehash),"QF05");
        Resolver res = Resolver(ens.resolver(namehash));
        address a = res.addr(namehash);
        require(_checkInterfaceID(a,Utility.INTERFACE_ID_QUALIFICATIONLOGIC),"QF06");
        implementENS=_imp;
        
    }
    
    function updateAttributeListENS(string memory _imp) public {
        require(_orgAccessCheck(msg.sender,ADMIN),"QF07");
        bytes32 namehash = Utility._computeNamehash(_imp);
        require(ens.recordExists(namehash),"QF08");
        Resolver res = Resolver(ens.resolver(namehash));
        address a = res.addr(namehash);
        require(_checkInterfaceID(a,Utility.INTERFACE_ID_QUALIFICATIONLOGIC),"QF09");
        attributeENS=_imp;
        
    }
    
    function createNewQualificaitonContract(address _owner,address _orgENSRegistar) public
    returns(address _i)
    {
        
        require(_orgAccessCheck(msg.sender,TOKEN),"QF");
        QualificationProxy q = new QualificationProxy(implementENS,attributeENS,_orgENSRegistar,_owner);
        return(address(q));
        
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
    
    function _checkInterfaceID(address _a,bytes4 _interfaceID) internal 
    returns(bool)
    {
        bytes memory payload = abi.encodeWithSignature("supportsInterface(bytes4)",_interfaceID);
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"QT");
        return abi.decode(result, (bool));
    }
    
    function qualificationFactory() public{
        
    }
    
    
    
    
    
}