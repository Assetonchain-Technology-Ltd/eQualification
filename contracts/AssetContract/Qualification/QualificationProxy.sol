pragma solidity ^0.7.0;

import "./QualificationDS.sol";
import "../../Utils/access.sol";
import "../../Utils/ENS.sol";
import "../../Utils/Resolver.sol";


contract QualificationProxy is QualificationDS {
    using Address for address;
    using SafeMath for uint256;
    
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes32 private root;
    ENS ens;
    
    constructor(bytes32  _imp,bytes32 _attributelist, address _ensaddress, string memory _ensOrgRoot ,address _qualificationOwner)  {
        
        require(_imp!=0x0 && _ensaddress !=address(0) &&  _attributelist !=0x0,"QP01");
        orgENSRegistar = _ensaddress;
        ens = ENS(orgENSRegistar);
        
        Resolver res = Resolver(ens.resolver(_imp));
        require(res.addr(_imp)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"QP02");
        
        res = Resolver(ens.resolver(_attributelist));
        require(res.addr(_attributelist)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"QP03");
        
        
        attributeListENS = _attributelist;
        qualificationLogicENSName = _imp;
        root = keccak256(bytes(_ensOrgRoot));
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
        bytes32 accessENS = _computeNamehash(ens.getPredefineENSPrefix("access"),root);
        Resolver res = Resolver(ens.resolver(accessENS));
        address accessadr = res.addr(accessENS);
        require(accessadr!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"QP10");
        access = PermissionControl(accessadr);
        
    }
    
    function _computeNamehash(bytes32 _prefix,bytes32 _postfix) internal pure 
    returns (bytes32) 
    {
      
      bytes32 namehash = keccak256(abi.encodePacked(_postfix, _prefix));
      return namehash;
      
    }

}