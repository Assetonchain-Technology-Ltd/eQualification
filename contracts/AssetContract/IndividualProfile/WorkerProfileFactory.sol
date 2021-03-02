pragma solidity >=0.7.0;
// SPDX-License-Identifier: GPL-3.0-or-later
import "./WorkerProfileProxy.sol";
import "../../Utils/Roles.sol";
import "../../Utils/Library.sol";
import "../../Utils/ENSRegistry.sol";
import "../../Utils/Resolver.sol";

contract WorkerProfileFactory is Roles {
    
    address pubENSRegistar;
    string implementENS;
    string attributeENS;
    ENS ens;
    PermissionControl access;
    
    constructor(address _pubENSRegistar,string memory _imp,string memory _attlist) {
        require(Utility._checkInterfaceID(_pubENSRegistar,Utility.INTERFACE_ID_ENSREGISTRY),"WF01");
        ens = ENS(_pubENSRegistar);
        require(_pubAccessCheck(msg.sender,ADMIN),"WF02");
        
        bytes32 namehash = Utility._computeNamehash(_imp);
        Resolver res = Resolver(ens.resolver(namehash));
        require(Utility._checkInterfaceID(res.addr(namehash),Utility.INTERFACE_ID_WORKERLOGIC),"WF03");
        namehash = Utility._computeNamehash(_attlist);
        res = Resolver(ens.resolver(namehash));
        require(Utility._checkInterfaceID(res.addr(namehash),Utility.INTERFACE_ID_ATTRIBUTELIST),"WF04");
        pubENSRegistar=_pubENSRegistar;
        implementENS=_imp;
        attributeENS=_attlist;
    }
    
    function updatepubENSRegistar(address _a) public {
        require(_pubAccessCheck(msg.sender,ADMIN),"WF05");
        require(Utility._checkInterfaceID(_a,Utility.INTERFACE_ID_ENSREGISTRY),"WF06");
        ens = ENS(_a);
        pubENSRegistar=_a;
    }
    
    function updateImplementationENS(string memory _imp) public {
        require(_pubAccessCheck(msg.sender,ADMIN),"QF07");
        bytes32 namehash = Utility._computeNamehash(_imp);
        Resolver res = Resolver(ens.resolver(namehash));
        address a = res.addr(namehash);
        require(Utility._checkInterfaceID(a,Utility.INTERFACE_ID_WORKERLOGIC),"WF09");
        implementENS=_imp;
        
    }
    
    function updateAttributeListENS(string memory _imp) public {
        require(_pubAccessCheck(msg.sender,ADMIN),"WF10");
        bytes32 namehash = Utility._computeNamehash(_imp);
        Resolver res = Resolver(ens.resolver(namehash));
        address a = res.addr(namehash);
        require(Utility._checkInterfaceID(a,Utility.INTERFACE_ID_ATTRIBUTELIST),"WF12");
        attributeENS=_imp;
        
    }
    
    function createNewWorkerProfileContract(address _owner,address _pubENSRegistar) public
    returns(address _i)
    {
        
        require(_pubAccessCheck(msg.sender,TOKEN),"WF13");
        WorkerProfileProxy w = new WorkerProfileProxy(implementENS,attributeENS,_pubENSRegistar);
        w.transferOwnership(_owner);
        return(address(w));
        
    }
    
    function _pubAccessCheck(address _caller,bytes32 _role) internal 
    returns(bool)
    {
        bytes32 pubAccessENS = Utility._computeNamehash(ens.getPredefineENSPrefix("access"));
        Resolver res = Resolver(ens.resolver(pubAccessENS));
        require(res.addr(pubAccessENS)!=address(0) && res.supportsInterface(Utility.ADDR_INTERFACE_ID),"WF14");
        address pubAccessAdr = res.addr(pubAccessENS);
        access = PermissionControl(pubAccessAdr);
        return access.hasRole(_role,_caller);
        
    }
    
    function workerProfileFactory() public{}
    
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == Utility.INTERFACE_ID_WORKERFACTORY;
    }
    
}