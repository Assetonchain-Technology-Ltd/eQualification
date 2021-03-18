pragma solidity >=0.7.0;
// SPDX-License-Identifier: GPL-3.0-or-later

import "../../Utils/RBAC.sol";
import "./AttributeList.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract WorkerProfileDS is Ownable {
    

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
        mapping(uint256 => Endorse) endorsements;
        uint256 endorsementcount;
    }
    
    struct qualificationname{
        string prefix;
        string postfix;
    }
    
    //System Para
    string attributeListENS;
    string profileLogicENSName;
    address publicENSRegistar;
    
    //Profile Para
    EnumerableSet.Bytes32Set attributeList;
    mapping (bytes32=> Attribute) Attributes;
    EnumerableSet.Bytes32Set qualificationList;
    mapping (bytes32=>qualificationname) qualificationNames;
    mapping (bytes32=>bytes) keystore;
    string status;
    PermissionControl access;
    
}