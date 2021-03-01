pragma solidity >=0.7.0;
// SPDX-License-Identifier: GPL-3.0-or-later
import "./WorkerProfileDS.sol";
import "../../Utils/access.sol";
import "../../Utils/ENS.sol";
import "../../Utils/Resolver.sol";
import "../../Utils/Library.sol";
import "../../Utils/Roles.sol";


contract WorkerProfileProxy is WorkerProfileDS,Roles {
    using Address for address;
    using SafeMath for uint256;
    
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    ENS ens;
    
    constructor(string memory  _imp,string memory _attributelist, address _ensaddress)  {
        
        require(keccak256(bytes(_imp))!=keccak256("") && _ensaddress !=address(0) &&  keccak256(bytes(_attributelist)) !=keccak256(""),"WP01");
        require(Utility._checkInterfaceID(_ensaddress,Utility.INTERFACE_ID_ENSREGISTRY),"WP11");
        publicENSRegistar = _ensaddress;
        ens = ENS(publicENSRegistar);
        
        bytes32 hashname = Utility._computeNamehash(_imp);
        Resolver res = Resolver(ens.resolver(hashname));
        require(Utility._checkInterfaceID(res.addr(hashname),Utility.INTERFACE_ID_WORKERLOGIC) && res.supportsInterface(ADDR_INTERFACE_ID),"WP02");
        profileLogicENSName = _imp;
        
        hashname = Utility._computeNamehash(_attributelist);
        res = Resolver(ens.resolver(hashname));
        require(Utility._checkInterfaceID(res.addr(hashname),Utility.INTERFACE_ID_ATTRIBUTELIST) && res.supportsInterface(ADDR_INTERFACE_ID),"WP03");
        attributeListENS = _attributelist;
        
        status="NEW";
    }
    
    function updateImplemetENSname(string memory _imp) public {
        require(_pubAccessCheck(msg.sender,ADMIN),"WP06");
        bytes32 hashname = Utility._computeNamehash(_imp);
        Resolver res = Resolver(ens.resolver(hashname));
        require(Utility._checkInterfaceID(res.addr(hashname),Utility.INTERFACE_ID_WORKERLOGIC) && res.supportsInterface(ADDR_INTERFACE_ID),"WP12");
        profileLogicENSName = _imp;
    }
    
    function updateENSAddress(address _ens) public {
        require(_pubAccessCheck(msg.sender,ADMIN),"WP07");
        require(Utility._checkInterfaceID(_ens,Utility.INTERFACE_ID_ENSREGISTRY),"WP11");
        publicENSRegistar = _ens;
        ens = ENS(publicENSRegistar);
    }
    
    function updateAttributeListENSname(string memory _attributelist) public {
        require(_pubAccessCheck(msg.sender,ADMIN),"WP13");
        bytes32 hashname = Utility._computeNamehash(_attributelist);
        Resolver res = Resolver(ens.resolver(hashname));
        require(Utility._checkInterfaceID(res.addr(hashname),Utility.INTERFACE_ID_ATTRIBUTELIST) && res.supportsInterface(ADDR_INTERFACE_ID),"WP14");
        attributeListENS = _attributelist;
    }
    
    function getSystemPara() public
    returns(string memory,string memory,address)
    {
        require(_pubAccessCheck(msg.sender,VIEW)||_pubAccessCheck(msg.sender,ADMIN),"WP09");
        return (profileLogicENSName,attributeListENS,publicENSRegistar);
    }
    
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == Utility.INTERFACE_ID_WORKERPROFILE;
    }
    
 
    
    fallback() external payable  {
       bytes32 namehash = Utility._computeNamehash(profileLogicENSName);
       Resolver res = Resolver(ens.resolver(namehash));
       address _impl =res.addr(namehash);
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
    

    
    function _pubAccessCheck(address _caller,bytes32 _role) internal 
    returns(bool)
    {
        bytes32 orgAccessENS = Utility._computeNamehash(ens.getPredefineENSPrefix("access"));
        Resolver res = Resolver(ens.resolver(orgAccessENS));
        require(res.addr(orgAccessENS)!=address(0) && res.supportsInterface(Utility.ADDR_INTERFACE_ID),"QL07");
        address orgAccessAdr = res.addr(orgAccessENS);
        access = PermissionControl(orgAccessAdr);
        return access.hasRole(_role,_caller);
        
    }

    
    function workerProfileProxy() public view {}
}