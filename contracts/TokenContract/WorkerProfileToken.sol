pragma solidity >=0.7.0;
// SPDX-License-Identifier: GPL-3.0-or-later
pragma abicoder v2;
import "../Utils/ENS.sol";
import "../Utils/Resolver.sol";
import "../Utils/Roles.sol";
import "../Utils/access.sol";
import "../Utils/Library.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";


contract WorkerProfileToken is ERC721Pausable,ERC721Burnable,Roles {
    
    address pubENSRegistry;
    PermissionControl access;
    string wFactory;
    ENS ens;
    
    constructor(string memory _name,string memory _syb,string memory _wFactory ,address _pubENSRoot) ERC721(_name,_syb)
    {
        require(Utility._checkInterfaceID(_pubENSRoot,Utility.INTERFACE_ID_ENSREGISTRY),"WT01");
        ens = ENS(_pubENSRoot);
        require(_pubAccessCheck(msg.sender,ISSUE) || _pubAccessCheck(msg.sender,ADMIN),"WT02");
        bytes32 hashname = Utility._computeNamehash(_name);
        require(ens.recordExists(hashname),"WT03");
        
        hashname = Utility._computeNamehash(_wFactory);
        Resolver res = Resolver(ens.resolver(hashname));
        address a = res.addr(hashname);
        require(Utility._checkInterfaceID(a,Utility.INTERFACE_ID_WORKERFACTORY),"WT04");
        _pause();
        wFactory = _wFactory;
        pubENSRegistry=_pubENSRoot;
    }
    
    function createWorkerProfile(address _individual) public {
        require(_pubAccessCheck(msg.sender,ISSUE),"WT05");
        bytes32 hashname = Utility._computeNamehash(wFactory);
        Resolver res = Resolver(ens.resolver(hashname));
        address _a = res.addr(hashname);
        
        bytes memory payload = abi.encodeWithSignature("createNewWorkerProfileContract(address,address) ",_individual,pubENSRegistry);
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"WT07");
        address waddress = abi.decode(result, (address)); 
        _mint(_individual,uint256(waddress));
             
    }
    
     function _mint(address to, uint256 tokenId) internal virtual override(ERC721) {
        require(_pubAccessCheck(msg.sender,ISSUE),"WT09");
        super._mint(to,tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    
    function _pubAccessCheck(address _caller,bytes32 _role) internal 
    returns(bool)
    {
        bytes32 pubAccessENS = Utility._computeNamehash(ens.getPredefineENSPrefix("access"));
        Resolver res = Resolver(ens.resolver(pubAccessENS));
        require(res.addr(pubAccessENS)!=address(0) && res.supportsInterface(Utility.ADDR_INTERFACE_ID),"WT07");
        address pubAccessAdr = res.addr(pubAccessENS);
        access = PermissionControl(pubAccessAdr);
        return access.hasRole(_role,_caller);
        
    }
    
    function workerProfileToken() public{}
    
    function supportsInterface(bytes4 interfaceId) public virtual override(ERC165) view returns (bool) {
        return interfaceId == Utility.INTERFACE_ID_WORKERTOKEN;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override (ERC721,ERC721Pausable) {
         if(!_pubAccessCheck(msg.sender,ISSUE)){
            super._beforeTokenTransfer(from,to,tokenId);
        }
    }
    
}