pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later
import "@ensdomains/resolver/contracts/PublicResolver.sol";

contract OrgResolver is PublicResolver {
    bytes4 constant private ORG_INTERFACE_ID = 0x136ff12d;
    

    mapping(bytes32=>mapping(bytes32=>bool)) _roles;

    constructor(ENS _ens) PublicResolver(_ens) {
    }

    function setRoles(bytes32 node, bytes32 role) public authorised(node){
        _roles[node][role]=true;
    }
    
    function hasRole(bytes32 node,bytes32  role) public view
    returns(bool)
    {
        return _roles[node][role];
    }
 
   
    function supportsInterface(bytes4 interfaceID) public pure override(PublicResolver) returns(bool) {
        return interfaceID == ORG_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}
