pragma solidity >=0.7.0;
// SPDX-License-Identifier: GPL-3.0-or-later
pragma abicoder v2;

import "./WorkerProfileDS.sol";
import "../../Utils/ENS.sol";
import "../../Utils/Resolver.sol";
import "../../Utils/Roles.sol";
import "../../Utils/Library.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract WorkerProfileLogic is WorkerProfileDS,Roles {
    
    
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    
    address publicENSRegistarAddress;
    ENS ens;
    
    constructor(address _ensAddress) {
        require(Utility._checkInterfaceID(_ensAddress,Utility.INTERFACE_ID_ENSREGISTRY),"WL01");
        publicENSRegistarAddress = _ensAddress;
        ens = ENS(publicENSRegistarAddress);
    }
    
    
    
    function addAttribute(string memory _name, bytes calldata _value, uint256 _datetime, string calldata _datatype) public onlyOwner 
    returns (bytes32)
    {
        bytes32 _key = keccak256(bytes(_name));
        bytes32 namehash = Utility._computeNamehash(attributeListENS);
        Resolver res = Resolver(ens.resolver(namehash));
        AttributeList ab = AttributeList(res.addr(namehash));
        require(ab.exists(_key)==false,"WL03");
        attributeList.add(_key);
        require(Attributes[_key].createDate==0,"WL04");
        Attributes[_key].name=_name;
        Attributes[_key].value=_value;
        Attributes[_key].createDate = _datetime;
        Attributes[_key].datatype = _datatype;
        bytes32 datatosign = Utility._prefixed(keccak256(abi.encodePacked(msg.sender,_key,_value,_datatype,_datetime,uint256(0),address(this))));
        return datatosign;
    }
    
    function upateAttribute(bytes32 _key, bytes calldata _value, uint256 _datetime, string calldata _datatype) public onlyOwner 
    returns (bytes32)
    {
        bytes32 namehash = Utility._computeNamehash(attributeListENS);
        Resolver res = Resolver(ens.resolver(namehash));
        AttributeList ab = AttributeList(res.addr(namehash));
        require(ab.exists(_key),"WL23");
        require(Attributes[_key].createDate>0,"WL24");
        uint256 ecount = Attributes[_key].endorsementcount;
        for(uint256 i=0;i<ecount;i++){
            Attributes[_key].endorsements[i].active = false;
        }
        Attributes[_key].value=_value;
        Attributes[_key].createDate = _datetime;
        Attributes[_key].datatype = _datatype;
        bytes32 datatosign = Utility._prefixed(keccak256(abi.encodePacked(msg.sender,_key,_value,_datatype,_datetime,ecount,address(this))));
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
        bytes32 hashqname = Utility._computeNamehash(_qERC721Name);
        require(_orgRoleCheck(hashorg,msg.sender,ISSUE),"WL14");
        require(qualificationList.contains(hashqname)==false,"WL15");
        require(_hasqERC721Token(hashorg,hashqname,_tokenid,address(this)),"WL16");
        qualificationList.add(hashqname);
        qualificationNames[hashqname].prefix=_qERC721Name;
        qualificationNames[hashqname].postfix=_org;
        keystore[hashqname]=_encryptKey;
    }
    
    function revokeQualification(string memory _qERC721Name,string memory _org,uint256 _tokenid,address _receiver) public{
        bytes32 hashorg=keccak256(bytes(_org));
        bytes32 hashqname = Utility._computeNamehash(_qERC721Name);
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
        bytes32 hashqname = Utility._computeNamehash(_qERC721Name);
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
    
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == Utility.INTERFACE_ID_WORKERPROFILE;
    }
    
    function updateENSAddress(address _ens) public {
        require(_pubAccessCheck(msg.sender,ADMIN),"WL27");
        require(Utility._checkInterfaceID(_ens,Utility.INTERFACE_ID_ENSREGISTRY),"WP28");
        publicENSRegistarAddress = _ens;
        ens = ENS(publicENSRegistarAddress);
    }
    
    function _orgRoleCheck(bytes32 _org,address _caller,bytes32 _role) internal 
    returns(bool)
    {
        Resolver res = Resolver(ens.resolver(_org));
        require(res.addr(_org)!=address(0) && res.supportsInterface(Utility.ORG_INTERFACE_ID),"WL07");
        address orgENSAddress =  res.addr(_org);
        if(_role==ISSUE || _role==ENDORSE)
            require(res.hasRole(_org,_role),"WL08");
        ENS orgENS = ENS(orgENSAddress);
        bytes32 orgAccessENS = Utility._computeNamehash(orgENS.getPredefineENSPrefix("access"));
        res = Resolver(orgENS.resolver(orgAccessENS));
        require(res.addr(orgAccessENS)!=address(0) && res.supportsInterface(Utility.ADDR_INTERFACE_ID),"WL09");
        address orgAccessAdr = res.addr(orgAccessENS);
        access = PermissionControl(orgAccessAdr);
        return access.hasRole(_role,_caller);
        
    }
    
    function _pubAccessCheck(address _caller,bytes32 _role) internal 
    returns(bool)
    {
        bytes32 orgAccessENS = Utility._computeNamehash(ens.getPredefineENSPrefix("access"));
        Resolver res = Resolver(ens.resolver(orgAccessENS));
        require(res.addr(orgAccessENS)!=address(0) && res.supportsInterface(Utility.ADDR_INTERFACE_ID),"QL07");
        address orgAccessAdr = res.addr(orgAccessENS);
        access = PermissionControl(orgAccessAdr);
        return access.hasRole(_role,_caller);
        
    }
    
    
    
    function _hasqERC721Token(bytes32 _org,bytes32 _qERC721Name, uint256 _tokenid,address _owner) internal view
    returns(bool)
    {
        Resolver res = Resolver(ens.resolver(_org));
        require(res.addr(_org)!=address(0) && res.supportsInterface(Utility.ORG_INTERFACE_ID),"WL07");
        address orgENSAddress =  res.addr(_org);
        ENS orgENS = ENS(orgENSAddress);
        res = Resolver(orgENS.resolver(_qERC721Name));
        require(res.addr(_qERC721Name)!=address(0) && res.supportsInterface(Utility.ADDR_INTERFACE_ID),"WL09");
        ERC721 token = ERC721(res.addr(_qERC721Name));
        return (token.ownerOf(_tokenid) == _owner);
        
    }
    
    
    function _withdrawERC721Token(bytes32 _org,bytes32 _qERC721Name, uint256 _tokenid,address _receiver) internal
    {
        Resolver res = Resolver(ens.resolver(_org));
        require(res.addr(_org)!=address(0) && res.supportsInterface(Utility.ORG_INTERFACE_ID),"WL07");
        address orgENSAddress =  res.addr(_org);
        ENS orgENS = ENS(orgENSAddress);
        res = Resolver(orgENS.resolver(_qERC721Name));
        require(res.addr(_qERC721Name)!=address(0) && res.supportsInterface(Utility.ADDR_INTERFACE_ID),"WL09");
        ERC721 token = ERC721(res.addr(_qERC721Name));
        token.safeTransferFrom(address(this),_receiver,_tokenid);
    }
    
    
    function _verifyAttributeSignature(address _signer,bytes32 _key, bytes memory signature) internal view 
    returns (bool)
    {
        Attribute storage attr = Attributes[_key];
        bytes32 datatosign = Utility._prefixed(keccak256(abi.encodePacked(owner(),_key,attr.value,attr.datatype,attr.createDate,attr.endorsementcount,address(this))));
        datatosign = Utility._prefixed(datatosign);
        return Utility._recoverSigner(datatosign, signature) == _signer;
    }

    
}