pragma solidity >=0.6.0;
// SPDX-License-Identifier: GPL-3.0-or-later
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Roles.sol";
contract PermissionControl is AccessControl ,Roles{
    
    

    constructor()  {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN, msg.sender);
    }
    
    PermissionControl access;
    
   
}