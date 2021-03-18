pragma solidity >=0.6.0;
import "./strings.sol";


contract Test {

    using strings for *;
    string private text;
    string[] private parts;
    
    
    
    function setText(string memory _t) public {
        text = _t;
    }
    
    function split() public {
        strings.slice memory s = text.toSlice();
        strings.slice memory delim = ".".toSlice();
        parts = new string[](s.count(delim) + 1);
        for(uint i = 0 ; i < parts.length; i++) {
             parts[i] = s.split(delim).toString();
        }
    }
    
    function getPartLen() public view
    returns(uint256)
    {
        return parts.length;
    }
    
    function getPartByIndex(uint256 _index) public view
    returns(string memory)
    {
        require(_index<parts.length,"Length");
        return(parts[_index]);
    }
    
    function computeNamehash(bytes32 _label) public view
    returns (bytes32) 
    {
        bytes32 namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        //for(uint i = parts.length ; i>0 ; i--) {
            
             namehash = keccak256(abi.encodePacked(namehash,_label ));
        //}
      
        return namehash; 
    }
    
    
    function _computeNamehash(string memory _name) public
    returns (bytes32) 
    {
        bytes32 namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        strings.slice memory s = _name.toSlice();
        strings.slice memory delim = ".".toSlice();
        string[] memory p = new string[](s.count(delim) + 1);
        for(uint i = 0 ; i < p.length; i++) {
             p[i] = s.split(delim).toString();
             
        }
        for(uint i=p.length;i>0;i--){
            bytes32 label =     keccak256(abi.encodePacked(p[i-1]));
            namehash = keccak256(abi.encodePacked(namehash, label));
        }
        
    
      return namehash;
      
    }
    
    function _computeParentNamehash(string memory _name) public
    returns (bytes32) 
    {
        bytes32 namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        strings.slice memory s = _name.toSlice();
        strings.slice memory delim = ".".toSlice();
        string[] memory p = new string[](s.count(delim)+1);
        for(uint i = 0 ; i < p.length; i++) {
             p[i] = s.split(delim).toString();
             
        }
        for(uint i=p.length;i>1;i--){
            namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked(p[i-1]))));
        }
        
        
      return namehash;
      
    }
    
    function convertUint256_Address(uint256 _d) public
    returns(address)
    {
        return(address(_d));
    }
}