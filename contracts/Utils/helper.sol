pragma solidity >=0.5.8;
import "../TokenContract/QualificationToken.sol";
contract Selector {
  // 0x75b24222
  function calcInterfaceId() external pure returns (bytes4) {
    QualificationToken i;
    return i.qualificationToken.selector;
    
  }
}