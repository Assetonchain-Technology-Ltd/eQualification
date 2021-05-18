pragma solidity >=0.7.0;
// SPDX-License-Identifier: GPL-3.0-or-later
pragma abicoder v2;
import "@openzeppelin/contracts/utils/EnumerableSet.sol";


contract QualificationAttributeListCWRS {
    
    using EnumerableSet for EnumerableSet.Bytes32Set;
    mapping(bytes32=>string) attributename;
    EnumerableSet.Bytes32Set  attributeList;
    

    
    constructor()
    {
        attributeList.add(keccak256("TradeCode"));
        attributeList.add(keccak256("ReferenceNo"));
        attributeList.add(keccak256("IssueDate"));
        attributeList.add(keccak256("ExpiryDate"));
        attributeList.add(keccak256("AuthorityCode"));
        attributeList.add(keccak256("SkillLevel"));
        attributeList.add(keccak256("QualificationCode"));
    
        
        attributename[keccak256("TradeCode")]="TradeCode";
        attributename[keccak256("ReferenceNo")]="ReferenceNo";
        attributename[keccak256("IssueDate")]="IssueDate";
        attributename[keccak256("ExpiryDate")]="ExpiryDate";
        attributename[keccak256("AuthorityCode")]="AuthorityCode";
        attributename[keccak256("SkillLevel")]="SkillLevel";
        attributename[keccak256("QualificationCode")]="QualificationCode";
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