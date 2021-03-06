pragma solidity >=0.7.0;
// SPDX-License-Identifier: GPL-3.0-or-later
pragma abicoder v2;
import "@openzeppelin/contracts/utils/EnumerableSet.sol";


contract AttributeList {
    
    using EnumerableSet for EnumerableSet.Bytes32Set;
    mapping(bytes32=>string) attributename;
    EnumerableSet.Bytes32Set  attributeList;
    

    
    constructor()
    {
        attributeList.add(keccak256("Applicant_Name_English"));
        attributeList.add(keccak256("Applicant_Name_Chinese"));
        attributeList.add(keccak256("HKID"));
        attributeList.add(keccak256("Passport"));
        attributeList.add(keccak256("Applicant_Photo"));
        attributeList.add(keccak256("RESIDENALADDRESS"));
        attributeList.add(keccak256("MOBILE"));
        attributeList.add(keccak256("MOBILE2"));
        attributeList.add(keccak256("AHash"));
        attributeList.add(keccak256("TMSQHash"));
        attributeList.add(keccak256("TTMSQHash"));
        attributeList.add(keccak256("CWRSQHash"));
        
        attributename[keccak256("Applicant_Name_English")]="Applicant_Name_English";
        attributename[keccak256("Applicant_Name_Chinese")]="Applicant_Name_Chinese";
        attributename[keccak256("HKID")]="HKID";
        attributename[keccak256("Passport")]="Passport";
        attributename[keccak256("Applicant_Photo")]="Applicant_Photo";
        attributename[keccak256("RESIDENALADDRESS")]="RESIDENALADDRESS";
        attributename[keccak256("MOBILE")]="MOBILE";
        attributename[keccak256("MOBILE2")]="MOBILE2";
        attributename[keccak256("QHash")]="QHash";
        attributename[keccak256("AHash")]="AHash";
        attributename[keccak256("TMSQHash")]="TMSQHash";
        attributename[keccak256("TTMSQHash")]="TTMSQHash";
        attributename[keccak256("CWRSQHash")]="CWRSQHash";
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
    
    function attributeListInterface() public{}
    
    
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == 0x3fe29da2;
    }
}