pragma solidity ^0.5.0;

import "@ensdomains/resolver/contracts/ResolverBase.sol";

contract OrgResolver is ResolverBase {
    bytes4 constant private ORG_INTERFACE_ID = 0x136ff12d;
    
    uint constant private COIN_TYPE_ETH = 60;

    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    mapping(bytes32=>mapping(uint=>bytes)) _addresses;
    mapping(bytes32=>mapping(bytes32=>bool)) _roles;
    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) external authorised(node) {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view returns (address payable) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if(a.length == 0) {
            return address(0);
        }
        return bytesToAddress(a);
    }

    function setAddr(bytes32 node, uint coinType, bytes memory a) public authorised(node) {
        emit AddressChanged(node, coinType, a);
        if(coinType == COIN_TYPE_ETH) {
            emit AddrChanged(node, bytesToAddress(a));
        }
        _addresses[node][coinType] = a;
    }
    
    function setRoles(bytes32 node, bytes32 role) public authorised(node){
        _roles[node][role]=true;
    }

    function addr(bytes32 node, uint coinType) public view returns(bytes memory) {
        return _addresses[node][coinType];
    }
    
    function hasRole(bytes32 node,bytes32  role) public view
    returns(bool)
    {
        return _roles[node][role];
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == ORG_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}
