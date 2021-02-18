pragma solidity ^0.7.0;


import "../../Utils/access.sol";
import "./QualificationAttributeList.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract QualificationDS is Access {
    

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
        address initiator;
        mapping(uint256 => Endorse) endorsements;
        uint256 endorsementcount;
    }
    
    struct Keystore {
        bytes cert;
        uint256 createDate;
    }
    
    //System Para
    bytes32 attributeListENS;
    bytes32 qualificationLogicENSName;
    address orgENSRegistar;
    
    //Profile Para
    address qualificationOwner;
    mapping (bytes32=> Attribute) Attributes;
    uint256 attributecount;
    Keystore key;
    string status;
 
    
}