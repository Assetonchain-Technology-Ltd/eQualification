pragma solidity >=0.7.0;
// SPDX-License-Identifier: GPL-3.0-or-later
pragma abicoder v2;

import "./WorkerProfileDS.sol";
import "../../Utils/ENS.sol";
import "../../Utils/Resolver.sol";
import "../../Utils/Roles.sol";
import "../../Utils/Library.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract WorkerProfileLogic_BK is WorkerProfileDS,Roles {
    
    
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    event WPstatusChange(address _a,string _s);
    
    constructor(address _ensAddress) {
        ENS ens = ENS(_ensAddress);
        bytes32 orgAccessENS = Utility._computeNamehash(ens.getPredefineENSPrefix("access"));
        Resolver res = Resolver(ens.resolver(orgAccessENS));
        require(res.addr(orgAccessENS)!=address(0) && res.supportsInterface(Utility.ADDR_INTERFACE_ID),"WL28");
        address orgAccessAdr = res.addr(orgAccessENS);
        access = PermissionControl(orgAccessAdr);
        require(access.hasRole(ADMIN,msg.sender),"WL29");
    }
    
    
    
    function addAttribute(string memory _name, bytes calldata _value, uint256 _datetime, string calldata _datatype) public onlyOwner 
    returns (bytes32)
    {
        ENS ens = ENS(publicENSRegistar);
        bytes32 _key = keccak256(bytes(_name));
        bytes32 hash = Utility._computeNamehash(attributeListENS);
        Resolver res = Resolver(ens.resolver(hash));
        AttributeList ab = AttributeList(res.addr(hash));
        require(ab.exists(_key),"WL05");
        attributeList.add(_key);
        Attributes[_key].name=_name;
        Attributes[_key].value=_value;
        Attributes[_key].createDate = _datetime;
        Attributes[_key].datatype = _datatype;
        hash = Utility._prefixed(keccak256(abi.encodePacked(msg.sender,_key,_value,_datatype,_datetime,uint256(0),address(this))));
        return hash;
    }
    
    function upateAttribute(bytes32 _key, bytes calldata _value, uint256 _datetime, string calldata _datatype) public onlyOwner 
    returns (bytes32)
    {
        ENS ens = ENS(publicENSRegistar);
        bytes32 hash = Utility._computeNamehash(attributeListENS);
        Resolver res = Resolver(ens.resolver(hash));
        AttributeList ab = AttributeList(res.addr(hash));
        require(ab.exists(_key),"WL23");
        require(attributeList.contains(_key),"WL24");
        uint256 ecount = Attributes[_key].endorsementcount;
        for(uint256 i=0;i<ecount;i++){
            Attributes[_key].endorsements[i].active = false;
        }
        Attributes[_key].value=_value;
        Attributes[_key].createDate = _datetime;
        Attributes[_key].datatype = _datatype;
        hash = Utility._prefixed(keccak256(abi.encodePacked(msg.sender,_key,_value,_datatype,_datetime,ecount,address(this))));
        return hash;
    }
    
    function removeAttribute(bytes32 _key,uint256 _datetime) public onlyOwner {
        require(attributeList.contains(_key),"WL06");
        delete Attributes[_key];
        attributeList.remove(_key);
    }
    
    function endorseAttribute(bytes32 _key,uint256 _datetime,uint256 _expiryDate,string memory _org,bytes calldata _signature) public {
        require(_orgRoleCheck(_org,msg.sender,ENDORSE),"WL09");
        require(_verifyAttributeSignature(msg.sender,_key,_signature),"WL10");
        require(attributeList.contains(_key),"WL25");
        uint256 ecount = Attributes[_key].endorsementcount;
        Attributes[_key].endorsementcount=Attributes[_key].endorsementcount.add(1);
        Attributes[_key].endorsements[ecount].signature = _signature;
        Attributes[_key].endorsements[ecount].endorseDate = _datetime;
        Attributes[_key].endorsements[ecount].endorseExpiryDate = _expiryDate;
        Attributes[_key].endorsements[ecount].endorser = msg.sender;
        Attributes[_key].endorsements[ecount].active = true;
    }
    

    function removeEndorsement(bytes32 _key,uint256 _endorseNumber,string memory _org) public {
        require(_orgRoleCheck(_org,msg.sender,ENDORSE),"WL11");
        require(attributeList.contains(_key),"WL12");
        require(Attributes[_key].endorsements[_endorseNumber].endorser==msg.sender,"WL13");
        delete Attributes[_key].endorsements[_endorseNumber];
        Attributes[_key].endorsementcount=Attributes[_key].endorsementcount.sub(1);
    }

    
    function addQualification(string memory _qERC721Name,string memory _org,bytes memory _encryptKey,uint256 _tokenid,string memory _ref) public{
        bytes32 hashqname = Utility._computeNamehash(_qERC721Name);
        require(_orgRoleCheck(_org,msg.sender,ISSUE),"WL14");
        require(_hasqERC721Token(_org,hashqname,_tokenid,address(this)),"WL16");
        qualificationList.add(hashqname);
        qualificationNames[hashqname].prefix=_qERC721Name;
        qualificationNames[hashqname].postfix=_org;
        qualificationNames[hashqname].ref = _ref;
        keystore[hashqname]=_encryptKey;
    }
    
    function revokeQualification(string memory _qERC721Name,string memory _org,uint256 _tokenid,address _receiver) public{
        bytes32 hashqname = Utility._computeNamehash(_qERC721Name);
        require(_orgRoleCheck(_org,msg.sender,ISSUE),"WL17");
        require(qualificationList.contains(hashqname),"WL18");
        require(_hasqERC721Token(_org,hashqname,_tokenid,address(this)),"WL19");
        require(keccak256(bytes(qualificationNames[hashqname].postfix))==keccak256(bytes(_org)),"WL30");
        _withdrawERC721Token(_org,hashqname,_tokenid,_receiver);
        qualificationList.remove(hashqname);
        delete qualificationNames[hashqname];
        delete keystore[hashqname];
    }
    
    function updateQualification(string memory _qERC721Name,string memory _org,bytes memory _encryptKey,uint256 _tokenid) public{
        bytes32 hashqname = Utility._computeNamehash(_qERC721Name);
        require(_orgRoleCheck(_org,msg.sender,ISSUE),"WL19");
        require(qualificationList.contains(hashqname),"WL20");
        require(_hasqERC721Token(_org,hashqname,_tokenid,address(this)),"WL21");
        keystore[hashqname]=_encryptKey;
    }
    
    function setStatus(string memory _status,string memory _org) public{
        require(_orgRoleCheck(_org,msg.sender,ADMIN),"WL36");
        status=_status;
        emit WPstatusChange(address(this),_status);
        
    }
    
    function getStatus() public view
    returns(string memory)
    {
        return status;
    }
    
    function getAttribute(bytes32 _key,string memory _org) public view 
    returns(bytes memory,string memory)
    {
        
        require(_orgRoleCheck(_org,msg.sender,VIEW)||msg.sender==owner(),"WL25");
        require(attributeList.contains(_key),"WL26");
        return (Attributes[_key].value,Attributes[_key].datatype);
    }
    
    function length(string memory _org) public view
    returns(uint256)
    {
        require(_orgRoleCheck(_org,msg.sender,VIEW)||msg.sender==owner(),"WL25");
        return attributeList.length();
    }
    
    function getAttributeByIndex(string memory _org,uint256 _i) public view
    returns(bytes32,bytes memory,string memory)
    {
        require(_orgRoleCheck(_org,msg.sender,VIEW)||msg.sender==owner(),"WL25");
        require(_i<attributeList.length(),"WL27");
        bytes32 _key = attributeList.at(_i);
        return (_key,Attributes[_key].value,Attributes[_key].datatype);
    }
    
    function getEndorsement(bytes32 _key,string memory _org) public view
    returns(Endorse[] memory)
    {
        require(_orgRoleCheck(_org,msg.sender,VIEW)||msg.sender==owner(),"WL25");
        Endorse[] memory list;
        uint256 count = Attributes[_key].endorsementcount;
        for(uint256 i=0;i<count;i++){
            list[i]=Attributes[_key].endorsements[i];
        }
        return list;
    }
    
    function qlength(string memory _org) public view
    returns(uint256)
    {
        require(_orgRoleCheck(_org,msg.sender,VIEW)||msg.sender==owner(),"WL31");
        return qualificationList.length();
    }
    
    function getQualificationByIndex(string memory _org,uint256 _i) public view
    returns(string memory,string memory,string memory _ref)
    {
        require(_orgRoleCheck(_org,msg.sender,VIEW)||msg.sender==owner(),"WL32");
        require(_i<qualificationList.length(),"WL33");
        bytes32 _key = qualificationList.at(_i);
        return (qualificationNames[_key].prefix,qualificationNames[_key].postfix,qualificationNames[_key].ref);
    }
    
    function isExistsQualificaiton(string memory _org,string memory _q) public view
    returns(bool,string memory,string memory,string memory)
    {
        bytes32 _hash = Utility._computeNamehash(_q);
        require(_orgRoleCheck(_org,msg.sender,VIEW)||msg.sender==owner(),"WL34");
        if(qualificationList.contains(_hash)){
            
            return (true,qualificationNames[_hash].prefix,qualificationNames[_hash].postfix,qualificationNames[_hash].ref);
        }else{
            return (false,"","","");
        }
    }
    
    function getQualificationKey(bytes32 _key,string memory _org) public view
    returns(bytes memory)
    {
        require(_orgRoleCheck(_org,msg.sender,VIEW)||msg.sender==owner(),"WL25");
        require(qualificationList.contains(_key),"WL35");
        return keystore[_key];
    }
    
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == Utility.INTERFACE_ID_WORKERLOGIC;
    }
    
    
    function _orgRoleCheck(string memory _org,address _caller,bytes32 _role) internal view
    returns(bool)
    {
        ENS ens = ENS(publicENSRegistar);
        bytes32 namehash = Utility._computeNamehash(_org);
        Resolver res = Resolver(ens.resolver(namehash));
        require(res.addr(namehash)!=address(0) && res.supportsInterface(Utility.ORG_INTERFACE_ID),"WL07");
        address orgENSAddress =  res.addr(namehash);
        if(_role==ISSUE || _role==ENDORSE)
            require(res.hasRole(namehash,_role),"WL08");
        ENS orgENS = ENS(orgENSAddress);
        bytes32 orgAccessENS = Utility._computeNamehash(orgENS.getPredefineENSPrefix("access"));
        res = Resolver(orgENS.resolver(orgAccessENS));
        require(res.addr(orgAccessENS)!=address(0) && res.supportsInterface(Utility.ADDR_INTERFACE_ID),"WL09");
        address orgAccessAdr = res.addr(orgAccessENS);
        PermissionControl access = PermissionControl(orgAccessAdr);
        return access.hasRole(_role,_caller);
        
    }
    
    function _pubAccessCheck(address _caller,bytes32 _role) internal 
    returns(bool)
    {
        ENS ens = ENS(publicENSRegistar);
        bytes32 orgAccessENS = Utility._computeNamehash(ens.getPredefineENSPrefix("access"));
        Resolver res = Resolver(ens.resolver(orgAccessENS));
        require(res.addr(orgAccessENS)!=address(0) && res.supportsInterface(Utility.ADDR_INTERFACE_ID),"QL07");
        address orgAccessAdr = res.addr(orgAccessENS);
        access = PermissionControl(orgAccessAdr);
        return access.hasRole(_role,_caller);
        
    }
    
    
    
    function _hasqERC721Token(string memory _org,bytes32 _qERC721Name, uint256 _tokenid,address _owner) internal view
    returns(bool)
    {
        bytes32 namehash = Utility._computeNamehash(_org);
        ENS ens = ENS(publicENSRegistar);
        Resolver res = Resolver(ens.resolver(namehash));
        require(res.addr(namehash)!=address(0) && res.supportsInterface(Utility.ORG_INTERFACE_ID),"WL07");
        address _a =  res.addr(namehash);
        ENS orgENS = ENS(_a);
        res = Resolver(orgENS.resolver(_qERC721Name));
        require(res.addr(_qERC721Name)!=address(0) && res.supportsInterface(Utility.ADDR_INTERFACE_ID),"WL09");
        ERC721 token = ERC721(res.addr(_qERC721Name));
        return (_owner==token.ownerOf(_tokenid));
        
    }
    
    
    function _withdrawERC721Token(string memory _org,bytes32 _qERC721Name, uint256 _tokenid,address _receiver) internal
    {
        bytes32 namehash = Utility._computeNamehash(_org);
        ENS ens = ENS(publicENSRegistar);
        Resolver res = Resolver(ens.resolver(namehash));
        require(res.addr(namehash)!=address(0) && res.supportsInterface(Utility.ORG_INTERFACE_ID),"WL07");
        address orgENSAddress =  res.addr(namehash);
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