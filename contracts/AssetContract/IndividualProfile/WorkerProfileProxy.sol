pragma solidity ^0.7.0;

import "./WorkerProfileDS.sol";
import "../../Utils/access.sol";
import "../../Utils/ENS.sol";
import "../../Utils/Resolver.sol";
import "../../Utils/Library.sol";


contract WorkerProfileProxy is WorkerProfileDS {
    using Address for address;
    using SafeMath for uint256;
    
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    ENS ens;
    
    constructor(string memory  _imp,string memory _attributelist, address _ensaddress)  {
        
        require(keccak256(bytes(_imp))!=keccak256("") && _ensaddress !=address(0) &&  keccak256(bytes(_attributelist)) !=keccak256(""),"WP01");
        publicENSRegistar = _ensaddress;
        ens = ENS(publicENSRegistar);
        
        bytes32 hashname = Utility._computeNamehash(_imp);
        Resolver res = Resolver(ens.resolver(hashname));
        require(res.addr(hashname)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WP02");
        profileLogicENSName = hashname;
        hashname = Utility._computeNamehash(_attributelist);
        res = Resolver(ens.resolver(hashname));
        require(res.addr(hashname)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WP03");
        attributeListENS = hashname;
        
     
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
    
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == Utility.INTERFACE_ID_WORKERPROFILE;
    }
    
    function workerProfileProxy() public view {}
    
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
        bytes32 accessENS = Utility._computeNamehash(ens.getPredefineENSPrefix("access"));
        Resolver res = Resolver(ens.resolver(accessENS));
        address accessadr = res.addr(accessENS);
        require(accessadr!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WP10");
        access = PermissionControl(accessadr);
        
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