pragma solidity >=0.7.0;
// SPDX-License-Identifier: GPL-3.0-or-later
import "./QualificationDS.sol";
import "../../Utils/ENS.sol";
import "../../Utils/Resolver.sol";
import "../../Utils/Library.sol";
import "../../Utils/Roles.sol";


contract QualificationProxy is QualificationDS,Roles {
    using Address for address;
    using SafeMath for uint256;
    
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    ENS ens;
    
    constructor(string memory _imp,string memory _attributelist, address _ensaddress ,address _qualificationOwner)  {
        
        require(keccak256(bytes(_imp))!=keccak256("") &&  keccak256(bytes(_attributelist))!= keccak256("") ,"QP01");
        require(Utility._checkInterfaceID(_ensaddress,Utility.INTERFACE_ID_ENSREGISTRY),"QP01A");
        orgENSRegistar = _ensaddress;
        ens = ENS(orgENSRegistar);
        
        bytes32 namehash=Utility._computeNamehash(_imp);
        Resolver res = Resolver(ens.resolver(namehash));
        require(Utility._checkInterfaceID(res.addr(namehash),Utility.INTERFACE_ID_QUALIFICATIONLOGIC) && res.supportsInterface(ADDR_INTERFACE_ID),"QP02");
        qualificationLogicENSName = _imp;
        
        namehash=Utility._computeNamehash(_attributelist);
        res = Resolver(ens.resolver(namehash));
        require(Utility._checkInterfaceID(res.addr(namehash),Utility.INTERFACE_ID_QUALIFICATIONATTLIST) && res.supportsInterface(ADDR_INTERFACE_ID),"QP03");
        attributeListENS = _attributelist;
        
        qualificationOwner = _qualificationOwner;     
        status="NEW";
    }
    
    function updateImplemetENSname(string memory _imp) public {
        require(_orgAccessCheck(msg.sender,ADMIN),"QP06");
        bytes32 namehash=Utility._computeNamehash(_imp);
        Resolver res = Resolver(ens.resolver(namehash));
        require(Utility._checkInterfaceID(res.addr(namehash),Utility.INTERFACE_ID_QUALIFICATIONLOGIC) && res.supportsInterface(ADDR_INTERFACE_ID),"QP06A");
        qualificationLogicENSName = _imp;
    }
     
    function updateENSAddress(address _ens) public {
        require(_orgAccessCheck(msg.sender,ADMIN),"QP12");
        require(Utility._checkInterfaceID(_ens,Utility.INTERFACE_ID_ENSREGISTRY),"QP13");
        orgENSRegistar = _ens;
        ens = ENS(orgENSRegistar);
    }
    
    function updateAttributeListENSname(string memory _imp) public {
        require(_orgAccessCheck(msg.sender,ADMIN),"QP09");
        bytes32 namehash=Utility._computeNamehash(_imp);
        Resolver res = Resolver(ens.resolver(namehash));
        require(Utility._checkInterfaceID(res.addr(namehash),Utility.INTERFACE_ID_QUALIFICATIONATTLIST) && res.supportsInterface(ADDR_INTERFACE_ID),"QP09A");
        qualificationLogicENSName = _imp;
    }
    
    function getSystemPara() public 
    returns(string memory,string memory,address)
    {
        require(_orgAccessCheck(msg.sender,ADMIN)||_orgAccessCheck(msg.sender,VIEW),"QP11");
        return(qualificationLogicENSName,attributeListENS,orgENSRegistar);
    }
    
    fallback() external payable  {
       bytes32 namehash = Utility._computeNamehash(qualificationLogicENSName);
       Resolver res = Resolver(ens.resolver(namehash));
       address _impl =res.addr(namehash);
       require(_impl != address(0),"QP08");
       assembly {
                calldatacopy(0, 0, calldatasize())
                let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 { revert(0, returndatasize()) }
                default { return(0, returndatasize()) }
            }
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
    
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == Utility.INTERFACE_ID_QUALIFICATIONPROXY;
    }

    function qualificationProxy() public{}
    

}