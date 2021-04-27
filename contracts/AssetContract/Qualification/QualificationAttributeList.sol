pragma solidity >=0.7.0;
// SPDX-License-Identifier: GPL-3.0-or-later
pragma abicoder v2;
import "@openzeppelin/contracts/utils/EnumerableSet.sol";


contract QualificationAttributeList {
    
    using EnumerableSet for EnumerableSet.Bytes32Set;
    mapping(bytes32=>string) attributename;
    EnumerableSet.Bytes32Set  attributeList;
    

    
    constructor()
    {
        attributeList.add(keccak256("Reference_Number"));
        attributeList.add(keccak256("CIC_Qualification_Seq_No"));
        attributeList.add(keccak256("Issue_Date"));
        attributeList.add(keccak256("Validity_From"));
        attributeList.add(keccak256("Validity_To"));
        attributeList.add(keccak256("Trade"));
        attributeList.add(keccak256("Card_Template_Id"));
        
        attributename[keccak256("Reference_Number")]="Reference_Number";
        attributename[keccak256("CIC_Qualification_Seq_No")]="CIC_Qualification_Seq_No";
        attributename[keccak256("Issue_Date")]="Issue_Date";
        attributename[keccak256("Validity_From")]="Validity_From";
        attributename[keccak256("Validity_To")]="Validity_To";
        attributename[keccak256("Trade")]="Trade";
        attributename[keccak256("Card_Template_Id")]="Card_Template_Id";
        
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