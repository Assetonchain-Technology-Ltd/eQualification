pragma solidity >=0.7.0;
// SPDX-License-Identifier: GPL-3.0-or-later

import "../../Utils/RBAC.sol";
import "./QualificationAttributeList.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";


contract QualificationDS  {
    

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    
    struct Endorse {
        bytes signature;
        uint256 endorseDate;
        uint256 endorseExpiryDate;
        address endorser;
        bool active;
    }
    
    struct Attribute {
        string name;
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
    string attributeListENS;
    string qualificationLogicENSName;
    address orgENSRegistar;
    
    //Profile Para
    address qualificationOwner;
    EnumerableSet.Bytes32Set attributeList;
    mapping (bytes32=> Attribute) Attributes;
    PermissionControl access;

    Keystore key;
    string status;
 
    
}