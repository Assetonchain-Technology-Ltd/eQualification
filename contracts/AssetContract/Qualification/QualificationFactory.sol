pragma solidity >=0.7.0;
// SPDX-License-Identifier: GPL-3.0-or-later
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
    
    constructor(address _orgENSRegistar,string memory _imp,string memory _attlist) {
        require(Utility._checkInterfaceID(_orgENSRegistar,Utility.INTERFACE_ID_ENSREGISTRY),"QF01");
        ens = ENS(_orgENSRegistar);
        require(_orgAccessCheck(msg.sender,ADMIN),"QF02");
        
        bytes32 namehash = Utility._computeNamehash(_imp);
        Resolver res = Resolver(ens.resolver(namehash));
        require(Utility._checkInterfaceID(res.addr(namehash),Utility.INTERFACE_ID_QUALIFICATIONLOGIC),"QF03");
        namehash = Utility._computeNamehash(_attlist);
        res = Resolver(ens.resolver(namehash));
        require(Utility._checkInterfaceID(res.addr(namehash),Utility.INTERFACE_ID_QUALIFICATIONATTLIST),"QF04");
        orgENSRegistar=_orgENSRegistar;
        implementENS=_imp;
        attributeENS=_attlist;
    }
    
    function updateOrgENSRegistar(address _a) public {
        require(_orgAccessCheck(msg.sender,ADMIN),"QF05");
        require(Utility._checkInterfaceID(_a,Utility.INTERFACE_ID_ENSREGISTRY),"QF06");
        ens = ENS(_a);
        orgENSRegistar=_a;
    }
    
    function updateImplementationENS(string memory _imp) public {
        require(_orgAccessCheck(msg.sender,ADMIN),"QF07");
        bytes32 namehash = Utility._computeNamehash(_imp);
        Resolver res = Resolver(ens.resolver(namehash));
        address a = res.addr(namehash);
        require(Utility._checkInterfaceID(a,Utility.INTERFACE_ID_QUALIFICATIONLOGIC),"QF09");
        implementENS=_imp;
        
    }
    
    function updateAttributeListENS(string memory _imp) public {
        require(_orgAccessCheck(msg.sender,ADMIN),"QF10");
        bytes32 namehash = Utility._computeNamehash(_imp);
        Resolver res = Resolver(ens.resolver(namehash));
        address a = res.addr(namehash);
        require(Utility._checkInterfaceID(a,Utility.INTERFACE_ID_QUALIFICATIONATTLIST),"QF12");
        attributeENS=_imp;
        
    }
    
    function createNewQualificaitonContract(address _owner,address _orgENSRegistar) public
    returns(address _i)
    {
        
        require(_orgAccessCheck(msg.sender,TOKEN),"QF13");
        QualificationProxy q = new QualificationProxy(implementENS,attributeENS,_orgENSRegistar,_owner);
        return(address(q));
        
    }
    
    function _orgAccessCheck(address _caller,bytes32 _role) internal 
    returns(bool)
    {
        bytes32 orgAccessENS = Utility._computeNamehash(ens.getPredefineENSPrefix("access"));
        Resolver res = Resolver(ens.resolver(orgAccessENS));
        require(res.addr(orgAccessENS)!=address(0) && res.supportsInterface(Utility.ADDR_INTERFACE_ID),"QL08");
        address orgAccessAdr = res.addr(orgAccessENS);
        access = PermissionControl(orgAccessAdr);
        return access.hasRole(_role,_caller);
        
    }
    
    function qualificationFactory() public{}
    
    
    
    
    
}