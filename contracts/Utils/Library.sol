pragma solidity >=0.7.0;
import "./strings.sol";

library Utility {
    
    bytes4 constant  ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant  ORG_INTERFACE_ID = 0x136ff12d;
    bytes4 constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 constant INTERFACE_ID_WORKERPROFILE = 0xdfd270ac;
    bytes4 constant INTERFACE_ID_WORKERLOGIC = 0xae9fcec8;
    bytes4 constant INTERFACE_ID_QUALIFICATIONPROXY = 0xae9fcec8;
    bytes4 constant INTERFACE_ID_QUALIFICATIONLOGIC = 0xae9fcec8;
    bytes4 constant INTERFACE_ID_QUALIFICATIONFACTORY = 0x468a0d57;
    
    using strings for *;
    
    function _prefixed(bytes32 hash) internal pure
    returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    
    function _computeNamehash(string memory _name) internal pure
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
            namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked(p[i-1]))));
        }
        
        
      return namehash;
      
    }
    
    function _computeParentNamehash(string memory _name) internal pure
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
    
    function split(string memory _text) internal pure 
    returns(string[] memory)
    {
        strings.slice memory s = _text.toSlice();
        strings.slice memory delim = ".".toSlice();
        string[] memory parts = new string[](s.count(delim) + 1);
        for(uint i = 0 ; i < parts.length; i++) {
             parts[i] = s.split(delim).toString();
        }
        return parts;
    }

    function _recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal  pure
    returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _splitSignature(bytes memory sig) internal  pure
    returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

