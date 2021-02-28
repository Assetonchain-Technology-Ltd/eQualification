pragma solidity >=0.5.8;
import "../AssetContract/Qualification/QualificationFactory.sol";
contract Selector {
  // 0x75b24222
  function calcInterfaceId() external pure returns (bytes4) {
    QualificationFactory i;
    return i.qualificationFactory.selector;
    
  }
}