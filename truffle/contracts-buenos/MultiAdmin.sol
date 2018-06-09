pragma solidity ^0.4.17;

contract MultiAdmin {
    
    mapping(address => bool) public isAdmin;
    mapping(address => mapping(uint => bool)) public adminLevel;

    function MultiAdmin() public {
        isAdmin[msg.sender] = true;
        adminLevel[msg.sender][0] = true;
    }

    function addAdmin(address admin, uint level) public onlyAdmin(0) {
        isAdmin[admin] = true;
        adminLevel[admin][level] = true;
    }

    modifier onlyAdmin(uint requiredLevel) {
        require(isAdmin[msg.sender] && adminLevel[msg.sender][requiredLevel]);
        _;
    }

    modifier onlyAdmins(uint[] requiredLevels) {
        bool allowed = false;
        for (uint i = 0; i < requiredLevels.length; i++) {
            if (adminLevel[msg.sender][requiredLevels[i]]) {
                allowed = true;
                break;
            }
        }
        require(allowed);
        _;
    }

    
}