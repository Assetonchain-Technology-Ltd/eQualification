pragma solidity ^0.7.0;

import "./WorkerProfileDS.sol";
import "../../Utils/access.sol";
import "../../Utils/ENS.sol";
import "../../Utils/Resolver.sol";


contract WorkerProfileProxy is WorkerProfileDS {
    using Address for address;
    using SafeMath for uint256;
    
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes32 constant private root = 0x0000000000000000000000000000000000000000000000000000000000000000;
    ENS ens;
    
    constructor(bytes32  _imp,bytes32 _attributelist, address _ensaddress)  {
        
        require(_imp!=0x0 && _ensaddress !=address(0) &&  _attributelist !=0x0,"WP01");
        publicENSRegistar = _ensaddress;
        ens = ENS(publicENSRegistar);
        
        Resolver res = Resolver(ens.resolver(_imp));
        require(res.addr(_imp)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WP02");
        
        res = Resolver(ens.resolver(_attributelist));
        require(res.addr(_attributelist)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WP03");
        
        
        attributeListENS = _attributelist;
        profileLogicENSName = _imp;
     
        status="NEW";
    }
    
    function updateImplemetENSname(bytes32 _imp) public {
        _updatePublicAccess();
        require(_isAdmin(msg.sender),"WP06");
        profileLogicENSName = _imp;
    }
    
    function updateENSAddress(address _ens) public {
        _updatePublicAccess();
        require(_isAdmin(msg.sender),"WP07");
        publicENSRegistar = _ens;
        ens = ENS(publicENSRegistar);
    }
    
    
    fallback() external payable  {
        
       Resolver res = Resolver(ens.resolver(profileLogicENSName));
       address _impl =res.addr(profileLogicENSName);
       require(_impl != address(0),"WP08");
       assembly {
                calldatacopy(0, 0, calldatasize())
                let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 { revert(0, returndatasize()) }
                default { return(0, returndatasize()) }
            }
    }
    
    
    function _updatePublicAccess() internal {
        bytes32 accessENS = _computeNamehash(ens.getPredefineENSPrefix("access"),root);
        Resolver res = Resolver(ens.resolver(accessENS));
        address accessadr = res.addr(accessENS);
        require(accessadr!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WP10");
        access = PermissionControl(accessadr);
        
    }
    
    
    function _computeNamehash(bytes32 _prefix,bytes32 _postfix) internal pure 
    returns (bytes32) 
    {
      
      bytes32 namehash = keccak256(abi.encodePacked(_postfix, _prefix));
      return namehash;
      
    }

}