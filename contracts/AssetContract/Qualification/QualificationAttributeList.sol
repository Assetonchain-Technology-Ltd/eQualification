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
        attributeList.add(keccak256("ENGNAME"));
        attributeList.add(keccak256("CHINAME"));
        attributeList.add(keccak256("DOB"));
        attributeList.add(keccak256("IDNUMBER"));
        attributeList.add(keccak256("MOBILE"));
        attributeList.add(keccak256("RESIDENALADDRESS"));
        attributeList.add(keccak256("MOBILE2"));
        attributeList.add(keccak256("MOBILE3"));
        
        attributename[keccak256("ENGNAME")]="ENGNAME";
        attributename[keccak256("CHINAME")]="CHINAME";
        attributename[keccak256("DOB")]="DOB";
        attributename[keccak256("IDNUMBER")]="IDNUMBER";
        attributename[keccak256("MOBILE")]="MOBILE";
        attributename[keccak256("RESIDENALADDRESS")]="RESIDENALADDRESS";
        attributename[keccak256("MOBILE2")]="MOBILE2";
        attributename[keccak256("MOBILE3")]="MOBILE3";
        
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