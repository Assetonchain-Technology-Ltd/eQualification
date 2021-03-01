pragma solidity >=0.5.8;
import "../AssetContract/Qualification/QualificationLogic.sol";
contract Selector {
  // 0x75b24222
  function calcInterfaceId() external pure returns (bytes4) {
    QualificationLogic i;
    return i.qualificationLogic.selector;
    
  }
}