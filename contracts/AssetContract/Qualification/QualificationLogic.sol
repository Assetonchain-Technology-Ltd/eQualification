pragma solidity ^0.7.0;
pragma abicoder v2;
import "./QualificationDS.sol";
import "../../Utils/ENS.sol";
import "../../Utils/Resolver.sol";
import "../../Utils/Roles.sol";
import "../../Utils/Library.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract QualificationLogic is QualificationDS,Roles {
    

    
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    

    
    address orgRegistarAddress;
    ENS ens;
    
    constructor(address _ensAddress) {
        require( _ensAddress !=address(0),"QL01");
        orgRegistarAddress = _ensAddress;
        ens = ENS(orgRegistarAddress);
    }
    
    
    
    function addAttribute(string memory _name, bytes calldata _value, uint256 _datetime, string calldata _datatype) public 
    returns (bytes32)
    {
        bytes32 _key = keccak256(bytes(_name));
        require(_orgAccessCheck(msg.sender,TOKEN)||_orgAccessCheck(msg.sender,OPERATOR)||_orgAccessCheck(msg.sender,ADMIN) ,"QL09");
        Resolver res = Resolver(ens.resolver(attributeListENS));
        require(res.addr(attributeListENS)!=address(0) && res.supportsInterface(Utility.ADDR_INTERFACE_ID),"QL02");
        QualificationAttributeList ab = QualificationAttributeList(res.addr(attributeListENS));
        require(attributeList.contains(_key),"QL04");
        require(ab.exists(_key)==false,"QL03");
        attributeList.add(_key);
        Attributes[_key].name=_name;
        Attributes[_key].value=_value;
        Attributes[_key].createDate = _datetime;
        Attributes[_key].datatype = _datatype;
        Attributes[_key].initiator = msg.sender;
        bytes32 datatosign = Utility._prefixed(keccak256(abi.encodePacked(msg.sender,_key,_value,_datatype,_datetime,uint256(0),address(this))));
        return datatosign;
    }
    
    function removeAttribute(bytes32 _key,uint256 _datetime) public  {
        
        require(_orgAccessCheck(msg.sender,TOKEN)||_orgAccessCheck(msg.sender,OPERATOR)||_orgAccessCheck(msg.sender,ADMIN) ,"QL05");
        require(attributeList.contains(_key),"QL06");
        delete Attributes[_key];
        attributeList.remove(_key);
    }
    
    function endorseAttribute(bytes32 _key,uint256 _datetime,uint256 _expiryDate,bytes calldata _signature) public {
        
        require(_orgAccessCheck(msg.sender,ENDORSE),"QL09");
        require(_verifyAttributeSignature(msg.sender,_key,_signature),"QL10");
        uint256 ecount = Attributes[_key].endorsementcount;
        Attributes[_key].endorsementcount=Attributes[_key].endorsementcount.add(1);
        Attributes[_key].endorsements[ecount].signature = _signature;
        Attributes[_key].endorsements[ecount].endorseDate = _datetime;
        Attributes[_key].endorsements[ecount].endorseExpiryDate = _expiryDate;
        Attributes[_key].endorsements[ecount].endorser = msg.sender;
        Attributes[_key].endorsements[ecount].active = true;
    }
    
    function removeEndorsement(bytes32 _key,uint256 _endorseNumber) public {
       
        require(_orgAccessCheck(msg.sender,ENDORSE),"QL11");
        require(attributeList.contains(_key),"QL12");
        require(Attributes[_key].endorsements[_endorseNumber].endorser==msg.sender,"QL13");
        Attributes[_key].endorsements[_endorseNumber].active=false;
        Attributes[_key].endorsementcount=Attributes[_key].endorsementcount.sub(1);
        
    }
    
    function addKeyStore(bytes memory _dercert,uint256 _datetime) public{
        
        require(_orgAccessCheck(msg.sender,TOKEN)||_orgAccessCheck(msg.sender,OPERATOR)
                ||_orgAccessCheck(msg.sender,ADMIN)||msg.sender==qualificationOwner ,"QL14");
        key.cert=_dercert;
        key.createDate=_datetime;
    }
    
    function delKeyStore() public{
        
        require(_orgAccessCheck(msg.sender,TOKEN)||_orgAccessCheck(msg.sender,OPERATOR)
                ||_orgAccessCheck(msg.sender,ADMIN)||msg.sender==qualificationOwner ,"QL15");
        delete key;
    }
    
    function getAttribute(bytes32 _key) public
    returns(bytes memory,string memory)
    {
        
        require(_orgAccessCheck(msg.sender,TOKEN)||_orgAccessCheck(msg.sender,OPERATOR)
                ||_orgAccessCheck(msg.sender,ADMIN)||msg.sender==qualificationOwner ,"QL16");
        require(attributeList.contains(_key),"QL17");
        return (Attributes[_key].value,Attributes[_key].datatype);
    }
    
    function listofAttribute() public
    returns(string[] memory)
    {
       
        require(_orgAccessCheck(msg.sender,TOKEN)||_orgAccessCheck(msg.sender,OPERATOR)
                ||_orgAccessCheck(msg.sender,ADMIN)||msg.sender==qualificationOwner ,"QL17");
       string[] memory list;
        uint256 count = attributeList.length();
        for(uint256 i=0;i<count;i++){
            list[i]=Attributes[attributeList.at(i)].name;
        }
        return list;
    }
    
    function getKey() public 
    returns(bytes memory,uint256)
    {
        
        require(_orgAccessCheck(msg.sender,TOKEN)||_orgAccessCheck(msg.sender,OPERATOR)
                ||_orgAccessCheck(msg.sender,ADMIN)||msg.sender==qualificationOwner ,"QL14");
        return (key.cert,key.createDate);
    }
    
    function _orgAccessCheck(address _caller,bytes32 _role) internal 
    returns(bool)
    {
        bytes32 orgAccessENS = Utility._computeNamehash(ens.getPredefineENSPrefix("access"));
        Resolver res = Resolver(ens.resolver(orgAccessENS));
        require(res.addr(orgAccessENS)!=address(0) && res.supportsInterface(Utility.ADDR_INTERFACE_ID),"QL07");
        address orgAccessAdr = res.addr(orgAccessENS);
        access = PermissionControl(orgAccessAdr);
        return access.hasRole(_role,_caller);
        
    }
    
    function _verifyAttributeSignature(address _signer,bytes32 _key, bytes memory signature) internal view 
    returns (bool)
    {
        Attribute storage attr = Attributes[_key];
        bytes32 datatosign = Utility._prefixed(keccak256(abi.encodePacked(attr.initiator,_key,attr.value,attr.datatype,attr.createDate,attr.endorsementcount,address(this))));
        datatosign = Utility._prefixed(datatosign);
        return Utility._recoverSigner(datatosign, signature) == _signer;
    }

}