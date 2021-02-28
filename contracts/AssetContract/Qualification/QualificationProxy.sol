pragma solidity >=0.7.0;

import "./QualificationDS.sol";
import "../../Utils/access.sol";
import "../../Utils/ENS.sol";
import "../../Utils/Resolver.sol";
import "../../Utils/Library.sol";


contract QualificationProxy is QualificationDS {
    using Address for address;
    using SafeMath for uint256;
    
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    ENS ens;
    
    constructor(string memory _imp,string memory _attributelist, address _ensaddress ,address _qualificationOwner)  {
        
        require(keccak256(bytes(_imp))!=keccak256("") && _ensaddress !=address(0) &&  keccak256(bytes(_attributelist))!= keccak256(""),"QP01");
        orgENSRegistar = _ensaddress;
        ens = ENS(orgENSRegistar);
        
        bytes32 namehash=Utility._computeNamehash(_imp);
        Resolver res = Resolver(ens.resolver(namehash));
        require(res.addr(namehash)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"QP02");
        qualificationLogicENSName = namehash;
        
        namehash=Utility._computeNamehash(_attributelist);
        res = Resolver(ens.resolver(namehash));
        require(res.addr(namehash)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"QP03");
        attributeListENS = namehash;
        
        qualificationOwner = _qualificationOwner;     
        status="NEW";
    }
    
    function updateImplemetENSname(bytes32 _imp) public {
        _updateAccess();
        require(_isAdmin(msg.sender),"QP06");
        qualificationLogicENSName = _imp;
    }
    
    function updateENSAddress(address _ens) public {
        _updateAccess();
        require(_isAdmin(msg.sender),"QP07");
        orgENSRegistar = _ens;
        ens = ENS(orgENSRegistar);
    }
    
    
    fallback() external payable  {
        
       Resolver res = Resolver(ens.resolver(qualificationLogicENSName));
       address _impl =res.addr(qualificationLogicENSName);
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
    
    
    
    function _updateAccess() internal {
        bytes32 accessENS = Utility._computeNamehash(ens.getPredefineENSPrefix("access"));
        Resolver res = Resolver(ens.resolver(accessENS));
        address accessadr = res.addr(accessENS);
        require(accessadr!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"QP10");
        access = PermissionControl(accessadr);
        
    }
    

}