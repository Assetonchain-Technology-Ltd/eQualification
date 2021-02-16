pragma solidity ^0.7.0;


import "../Utils/access.sol";
import "./AttributeList.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract WorkerProfileDS is Ownable,Access {
    

    using SafeMath for uint256;
    
    struct Endorse {
        bytes signature;
        uint256 endorseDate;
        uint256 endorseExpiryDate;
        address endorser;
        bool active;
    }
    
    struct Attribute {
        bytes value;
        uint256 createDate;
        string datatype;
        mapping(uint256 => Endorse) endorsements;
        uint256 endorsementcount;
    }
    
    //System Para
    bytes32 attributeListENS;
    bytes32 publicAccessENSName;
    bytes32 profileLogicENSName;
    address publicENSRegistar;
    
    //Profile Para
    mapping (bytes32=> Attribute) Attributes;
    uint256 attributecount;
    mapping (uint256=>string) qualifications;
    uint256 qualificationcount;
    string status;
    
}