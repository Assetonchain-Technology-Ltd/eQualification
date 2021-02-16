pragma solidity ^0.7.0;

import "./WorkerProfileDS.sol";
import "@ensdomains/ens/contracts/ENS.sol";
import "@ensdomains/resolver/contracts/Resolver.sol";

contract WorkerProfileLogic is WorkerProfileDS {
    
    
    using Address for address;
    using SafeMath for uint256;
    
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    address publicENSRegistarAddress;
    ENS ens;
    
    constructor(address _ensAddress) {
        require( _ensAddress !=address(0),"WL01");
        publicENSRegistarAddress = _ensAddress;
        ens = ENS(publicENSRegistarAddress);
    }
    
    
    
    function addAttribute(bytes32 _key, bytes calldata _value, uint256 _datetime, string calldata _datatype) public onlyOwner 
    returns (bytes32)
    {
        
        Resolver res = Resolver(ens.resolver(attributeListENS));
        require(res.addr(attributeListENS)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WL02");
        AttributeList ab = AttributeList(res.addr(attributeListENS));
        require(ab.exists(_key),"WL03");
        attributecount+=1;
        require(Attributes[_key].createDate==0,"WL04");
        Attributes[_key].value=_value;
        Attributes[_key].createDate = _datetime;
        Attributes[_key].datatype = _datatype;
        bytes32 datatosign = _prefixed(keccak256(abi.encodePacked(msg.sender,_key,_value,_datatype,_datetime,uint256(0),this)));
        return datatosign;
    }
    
    function removeAttribute(bytes32 _key,uint256 _datetime) public onlyOwner {
        require(attributecount>0 && Attributes[_key].createDate>0,"WL06");
        delete Attributes[_key];
    }
    
    function endorseAttribute(bytes32 _key,uint256 _datetime,uint256 _expiryDate,bytes32 _org,bytes calldata _signature) public {
        require(_isEndorser(_org,msg.sender),"WL09");
        require(_verifyAttributeSignature(msg.sender,_key,_signature),"WL10");
        uint256 ecount = Attributes[_key].endorsementcount;
        Attributes[_key].endorsementcount.add(1);
        Attributes[_key].endorsements[ecount].signature = _signature;
        Attributes[_key].endorsements[ecount].endorseDate = _datetime;
        Attributes[_key].endorsements[ecount].endorseExpiryDate = _expiryDate;
        Attributes[_key].endorsements[ecount].endorser = msg.sender;
        Attributes[_key].endorsements[ecount].active = true;
    }
    
    function removeEndorsement(bytes32 _key,uint256 _endorseNumber,bytes32 _org) public {
        require(_isEndorser(_org,msg.sender),"WL11");
        require(Attributes[_key].endorsements[_endorseNumber].endorser==msg.sender,"WL12");
        Attributes[_key].endorsements[_endorseNumber].active=false;
        
    }
    
    
    function _isEndorser(bytes32 _org,address _caller) internal 
    returns(bool)
    {
        Resolver res = Resolver(ens.resolver(_org));
        require(res.addr(_org)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WL07");
        address orgENSAddress =  res.addr(_org);
        bytes32 orgAccessENS = _computeNamehash("access",_org);
        ENS orgENS = ENS(orgENSAddress);
        res = Resolver(orgENS.resolver(orgAccessENS));
        require(res.addr(orgAccessENS)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WL08");
        address orgAccessAdr = res.addr(orgAccessENS);
        access = PermissionControl(orgAccessAdr);
        return _isAdmin(_caller);
        
    }
    
    function _updateAccess(bytes32 _accessENS) internal {
        Resolver res = Resolver(ens.resolver(_accessENS));
        address accessadr = res.addr(_accessENS);
        require(accessadr!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WPXX");
        access = PermissionControl(accessadr);
        
    }
    
    function _updatePublicAccess() internal {
        Resolver res = Resolver(ens.resolver(publicAccessENSName));
        address accessadr = res.addr(publicAccessENSName);
        require(accessadr!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WPXXX");
        access = PermissionControl(accessadr);
        
    }
    

    
    function _prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    
    function _computeNamehash(string memory _prefix,bytes32 _postfix) internal pure 
    returns (bytes32) 
    {
      
      bytes32 namehash = keccak256(abi.encodePacked(_postfix, keccak256(abi.encodePacked(_prefix))));
      return namehash;
      
    }

    function _verifyAttributeSignature(address _signer,bytes32 _key, bytes memory signature) internal view 
    returns (bool)
    {
        Attribute storage attr = Attributes[_key];
        bytes32 datatosign = _prefixed(keccak256(abi.encodePacked(owner(),_key,attr.value,attr.datatype,attr.createDate,attr.endorsementcount,this)));
        datatosign = _prefixed(datatosign);
        return _recoverSigner(datatosign, signature) == _signer;
    }

    function _recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure 
    returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _splitSignature(bytes memory sig) internal pure 
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