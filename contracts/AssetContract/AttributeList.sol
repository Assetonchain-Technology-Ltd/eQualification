pragma solidity ^0.7.0;

contract AttributeList {
    
    bytes32 public constant ENGNAME = keccak256("ENGNAME");
    bytes32 public constant CHINAME = keccak256("CHINAME");
    bytes32 public constant DOB = keccak256("DOB");
    bytes32 public constant IDNUMBER = keccak256("IDNUMBER");
    bytes32 public constant MOBILE = keccak256("MOBILE");
    bytes32 public constant RESIDENALADDRESS = keccak256("RESIDENALADDRESS");
    bytes32 public constant MOBILE2 = keccak256("MOBILE2");
    bytes32 public constant MOBILE3 = keccak256("MOBILE3");
    
    function exists(bytes32 _key) public view 
    returns(bool)
    {
        return (_key==ENGNAME) || (_key==CHINAME) || (_key==DOB) || (_key==IDNUMBER) || (_key==MOBILE) || (_key==RESIDENALADDRESS)
                || (_key==MOBILE2) || (_key==MOBILE3);
                
    }
    
}