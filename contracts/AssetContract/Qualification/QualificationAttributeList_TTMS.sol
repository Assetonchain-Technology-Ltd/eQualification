pragma solidity >=0.7.0;
// SPDX-License-Identifier: GPL-3.0-or-later
pragma abicoder v2;
import "@openzeppelin/contracts/utils/EnumerableSet.sol";


contract QualificationAttributeListTTMS {
    
    using EnumerableSet for EnumerableSet.Bytes32Set;
    mapping(bytes32=>string) attributename;
    EnumerableSet.Bytes32Set  attributeList;
    

    
    constructor()
    {
        attributeList.add(keccak256("enrollmentId"));
        attributeList.add(keccak256("card_Number"));
        attributeList.add(keccak256("issue_Date"));
        attributeList.add(keccak256("valid_From"));
        attributeList.add(keccak256("expiry_Date"));
        attributeList.add(keccak256("tradeCode"));
        attributeList.add(keccak256("card_Template_Id"));
        attributeList.add(keccak256("QHash"));
        attributeList.add(keccak256("Pcert"));
        attributeList.add(keccak256("tradeType_Code"));
        attributeList.add(keccak256("examDate"));
        attributeList.add(keccak256("first_Issue_Date"));
        
        attributename[keccak256("enrollmentId")]="enrollmentId";
        attributename[keccak256("card_Number")]="card_Number";
        attributename[keccak256("issue_Date")]="issue_Date";
        attributename[keccak256("valid_From")]="valid_From";
        attributename[keccak256("expiry_Date")]="expiry_Date";
        attributename[keccak256("tradeCode")]="tradeCode";
        attributename[keccak256("card_Template_Id")]="card_Template_Id";
        attributename[keccak256("QHash")]="QHash";
        attributename[keccak256("Pcert")]="Pcert";
        attributename[keccak256("tradeType_Code")]="tradeType_Code";
        attributename[keccak256("examDate")]="examDate";
        attributename[keccak256("first_Issue_Date")]="first_Issue_Date";
    }
    
    function addAttribute(string memory _attr) public{
        bytes32 _key = keccak256(bytes(_attr));
        require(attributeList.contains(_key)==false,"A01");
        attributeList.add(_key);
        attributename[_key]=_attr;
    }
    
    function exists(bytes32 _key) public view 
    returns(bool)
    {
        return attributeList.contains(_key);
    }
    
    function length() public view
    returns(uint256 _i ){
        return attributeList.length();
    }
    
    function getAttributeNamebyIndex(uint256 _i) public view
    returns(string memory _name)
    {
        require(_i<attributeList.length(),"AL02");
        return (attributename[attributeList.at(_i)]);
    }
    
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == 0xa4d1215e;
    }
    
    function qualificationattributeListInterface() public{}
}