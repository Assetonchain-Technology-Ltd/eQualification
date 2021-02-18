pragma solidity >=0.5.8;
import "./OrgResolver.sol";
contract Selector {
  // 0x75b24222
  function calcInterfaceId() external pure returns (bytes4) {
    OrgResolver i;
    return bytes4(keccak256("setAddr(bytes32,address)")) ^ bytes4(keccak256("addr(bytes32)")) ^ bytes4(keccak256("setAddr(bytes32,uint,bytes)")) ^ i.setRoles.selector ^ bytes4(keccak256("addr(bytes32,uint)")) ^ i.hasRoles.selector ^ i.supportsInterface.selector;
  }
}