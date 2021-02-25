pragma solidity >=0.6.0;
pragma abicoder v2;

import "./WorkerProfileDS.sol";
import "../../Utils/ENS.sol";
import "../../Utils/Resolver.sol";
import "../../Utils/Roles.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract WorkerProfileLogic is WorkerProfileDS,Roles {
    
    
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    
    
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant private ORG_INTERFACE_ID = 0x136ff12d;

    
    address publicENSRegistarAddress;
    ENS ens;
    
    constructor(address _ensAddress) {
        require( _ensAddress !=address(0),"WL01");
        publicENSRegistarAddress = _ensAddress;
        ens = ENS(publicENSRegistarAddress);
    }
    
    
    
    function addAttribute(string memory _name, bytes calldata _value, uint256 _datetime, string calldata _datatype) public onlyOwner 
    returns (bytes32)
    {
        bytes32 _key = keccak256(bytes(_name));
        Resolver res = Resolver(ens.resolver(attributeListENS));
        require(res.addr(attributeListENS)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WL02");
        AttributeList ab = AttributeList(res.addr(attributeListENS));
        require(ab.exists(_key),"WL03");
        attributeList.add(_key);
        require(Attributes[_key].createDate==0,"WL04");
        Attributes[_key].name=_name;
        Attributes[_key].value=_value;
        Attributes[_key].createDate = _datetime;
        Attributes[_key].datatype = _datatype;
        bytes32 datatosign = _prefixed(keccak256(abi.encodePacked(msg.sender,_key,_value,_datatype,_datetime,uint256(0),address(this))));
        return datatosign;
    }
    
    function upateAttribute(bytes32 _key, bytes calldata _value, uint256 _datetime, string calldata _datatype) public onlyOwner 
    returns (bytes32)
    {
        Resolver res = Resolver(ens.resolver(attributeListENS));
        require(res.addr(attributeListENS)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WL22");
        AttributeList ab = AttributeList(res.addr(attributeListENS));
        require(ab.exists(_key),"WL23");
        require(Attributes[_key].createDate>0,"WL24");
        uint256 ecount = Attributes[_key].endorsementcount;
        for(uint256 i=0;i<ecount;i++){
            Attributes[_key].endorsements[i].active = false;
        }
        Attributes[_key].value=_value;
        Attributes[_key].createDate = _datetime;
        Attributes[_key].datatype = _datatype;
        bytes32 datatosign = _prefixed(keccak256(abi.encodePacked(msg.sender,_key,_value,_datatype,_datetime,ecount,address(this))));
        return datatosign;
    }
    
    function removeAttribute(bytes32 _key,uint256 _datetime) public onlyOwner {
        require(attributeList.contains(_key),"WL06");
        delete Attributes[_key];
        attributeList.remove(_key);
    }
    
    function endorseAttribute(bytes32 _key,uint256 _datetime,uint256 _expiryDate,string memory _org,bytes calldata _signature) public {
        require(_orgRoleCheck(keccak256(bytes(_org)),msg.sender,ENDORSE),"WL09");
        require(_verifyAttributeSignature(msg.sender,_key,_signature),"WL10");
        uint256 ecount = Attributes[_key].endorsementcount;
        Attributes[_key].endorsementcount=Attributes[_key].endorsementcount.add(1);
        Attributes[_key].endorsements[ecount].signature = _signature;
        Attributes[_key].endorsements[ecount].endorseDate = _datetime;
        Attributes[_key].endorsements[ecount].endorseExpiryDate = _expiryDate;
        Attributes[_key].endorsements[ecount].endorser = msg.sender;
        Attributes[_key].endorsements[ecount].active = true;
    }
    

    function removeEndorsement(bytes32 _key,uint256 _endorseNumber,string memory _org) public {
        require(_orgRoleCheck(keccak256(bytes(_org)),msg.sender,ENDORSE),"WL11");
        require(attributeList.contains(_key),"WL12");
        require(Attributes[_key].endorsements[_endorseNumber].endorser==msg.sender,"WL13");
        delete Attributes[_key].endorsements[_endorseNumber];
        Attributes[_key].endorsementcount=Attributes[_key].endorsementcount.sub(1);
    }

    
    function addQualification(string memory _qERC721Name,string memory _org,bytes memory _encryptKey,uint256 _tokenid) public{
        bytes32 hashorg=keccak256(bytes(_org));
        bytes32 hashqname = _computeNamehash(keccak256(bytes(_qERC721Name)),hashorg);
        require(_orgRoleCheck(hashorg,msg.sender,ISSUE),"WL14");
        require(qualificationList.contains(hashqname),"WL15");
        require(_hasqERC721Token(hashorg,hashqname,_tokenid,address(this)),"WL16");
        qualificationList.add(hashqname);
        qualificationNames[hashqname].prefix=_qERC721Name;
        qualificationNames[hashqname].postfix=_org;
        keystore[hashqname]=_encryptKey;
    }
    
    function revokeQualification(string memory _qERC721Name,string memory _org,uint256 _tokenid,address _receiver) public{
        bytes32 hashorg=keccak256(bytes(_org));
        bytes32 hashqname = _computeNamehash(keccak256(bytes(_qERC721Name)),hashorg);
        require(_orgRoleCheck(hashorg,msg.sender,ISSUE),"WL17");
        require(qualificationList.contains(hashqname),"WL18");
        require(_hasqERC721Token(hashorg,hashqname,_tokenid,address(this)),"WL19");
        _withdrawERC721Token(hashorg,hashqname,_tokenid,_receiver);
        qualificationList.remove(hashqname);
        delete qualificationNames[hashqname];
        delete keystore[hashqname];
    }
    
    function updateQualification(string memory _qERC721Name,string memory _org,bytes memory _encryptKey,uint256 _tokenid) public{
        bytes32 hashorg=keccak256(bytes(_org));
        bytes32 hashqname = _computeNamehash(keccak256(bytes(_qERC721Name)),hashorg);
        require(_orgRoleCheck(hashorg,msg.sender,ISSUE),"WL19");
        require(qualificationList.contains(hashqname),"WL20");
        require(_hasqERC721Token(hashorg,hashqname,_tokenid,address(this)),"WL21");
        keystore[hashqname]=_encryptKey;
    }
    
    function getAttribute(bytes32 _key,string memory _org) public
    returns(bytes memory,string memory)
    {
        require(_orgRoleCheck(keccak256(bytes(_org)),msg.sender,VIEW)||msg.sender==owner(),"WL25");
        require(attributeList.contains(_key),"WL26");
        return (Attributes[_key].value,Attributes[_key].datatype);
    }
    
    function listofAttribute(string memory _org) public
    returns(string[] memory)
    {
        require(_orgRoleCheck(keccak256(bytes(_org)),msg.sender,VIEW)||msg.sender==owner(),"WL25");
        string[] memory list;
        uint256 count = attributeList.length();
        for(uint256 i=0;i<count;i++){
            list[i]=Attributes[attributeList.at(i)].name;
        }
        return list;
    }
    
    function getEndorsement(bytes32 _key,string memory _org) public
    returns(Endorse[] memory)
    {
        require(_orgRoleCheck(keccak256(bytes(_org)),msg.sender,VIEW)||msg.sender==owner(),"WL25");
        Endorse[] memory list;
        uint256 count = Attributes[_key].endorsementcount;
        for(uint256 i=0;i<count;i++){
            list[i]=Attributes[_key].endorsements[i];
        }
        return list;
    }
    
    function getQualifications(string memory _org) public 
    returns(qualificationname[] memory)
    {
        require(_orgRoleCheck(keccak256(bytes(_org)),msg.sender,VIEW)||msg.sender==owner(),"WL25");
        qualificationname [] memory list;
        uint256 count = qualificationList.length();
        for(uint256 i=0;i<count;i++){
            list[i]=qualificationNames[qualificationList.at(i)];
        }
        return list;
    }
    
    function getQualificationKey(bytes32 _key,string memory _org) public
    returns(bytes memory)
    {
        require(_orgRoleCheck(keccak256(bytes(_org)),msg.sender,VIEW)||msg.sender==owner(),"WL25");
        require(qualificationList.contains(_key));
        return keystore[_key];
    }
    
    function _orgRoleCheck(bytes32 _org,address _caller,bytes32 _role) internal 
    returns(bool)
    {
        Resolver res = Resolver(ens.resolver(_org));
        require(res.addr(_org)!=address(0) && res.supportsInterface(ORG_INTERFACE_ID),"WL07");
        address orgENSAddress =  res.addr(_org);
        require(res.hasRole(_org,_role),"WL08");
        ENS orgENS = ENS(orgENSAddress);
        bytes32 orgAccessENS = _computeNamehash(orgENS.getPredefineENSPrefix("access"),_org);
        res = Resolver(orgENS.resolver(orgAccessENS));
        require(res.addr(orgAccessENS)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WL09");
        address orgAccessAdr = res.addr(orgAccessENS);
        access = PermissionControl(orgAccessAdr);
        return access.hasRole(_role,_caller);
        
    }
    
    function _hasqERC721Token(bytes32 _org,bytes32 _qERC721Name, uint256 _tokenid,address _owner) internal view
    returns(bool)
    {
        Resolver res = Resolver(ens.resolver(_org));
        require(res.addr(_org)!=address(0) && res.supportsInterface(ORG_INTERFACE_ID),"WL07");
        address orgENSAddress =  res.addr(_org);
        ENS orgENS = ENS(orgENSAddress);
        res = Resolver(orgENS.resolver(_qERC721Name));
        require(res.addr(_qERC721Name)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WL09");
        ERC721 token = ERC721(res.addr(_qERC721Name));
        return (token.ownerOf(_tokenid) == _owner);
        
    }
    
    
    function _withdrawERC721Token(bytes32 _org,bytes32 _qERC721Name, uint256 _tokenid,address _receiver) internal
    {
        Resolver res = Resolver(ens.resolver(_org));
        require(res.addr(_org)!=address(0) && res.supportsInterface(ORG_INTERFACE_ID),"WL07");
        address orgENSAddress =  res.addr(_org);
        ENS orgENS = ENS(orgENSAddress);
        res = Resolver(orgENS.resolver(_qERC721Name));
        require(res.addr(_qERC721Name)!=address(0) && res.supportsInterface(ADDR_INTERFACE_ID),"WL09");
        ERC721 token = ERC721(res.addr(_qERC721Name));
        token.safeTransferFrom(address(this),_receiver,_tokenid);
    }
    
    
    function _prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    
    function _computeNamehash(bytes32 _prefix,bytes32 _postfix) internal pure 
    returns (bytes32) 
    {
      
      bytes32 namehash = keccak256(abi.encodePacked(_postfix, keccak256(abi.encodePacked(_prefix))));
      return namehash;
      
    }

    function _verifyAttributeSignature(address _signer,bytes32 _key, bytes memory signature) internal view 
    returns (bool)
    {
        Attribute storage attr = Attributes[_key];
        bytes32 datatosign = _prefixed(keccak256(abi.encodePacked(owner(),_key,attr.value,attr.datatype,attr.createDate,attr.endorsementcount,address(this))));
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