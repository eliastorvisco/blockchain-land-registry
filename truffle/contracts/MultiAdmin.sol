pragma solidity ^0.4.17;

/// @title Multi Administration contract
/// @author Elias Torvisco
/// @dev The MultiAdmin contract has administrators addresses, and provides basic authorization control
/// functions, this simplifies the implementation of "user permissions".
/// @dev All function calls are currently implement without side effects
contract MultiAdmin {
    
    mapping(address => bool) public isAdmin;
    mapping(address => mapping(uint => bool)) public adminLevel;

    function MultiAdmin() public {
        isAdmin[msg.sender] = true;
        adminLevel[msg.sender][0] = true;
    }

    /// @param admin The address of the new administrator
    /// @param level The level of administration of the new administrator
    /// @dev Only the contract creator or administrators of the same level can add new administrators.
    function addAdmin(address admin, uint level) public onlyAdmin(0) {
        isAdmin[admin] = true;
        adminLevel[admin][level] = true;
    }

    /// @notice Modifier that will restrict access to functions. 
    /// Only an administrator of the indicated level will be able to access it.
    /// @param requiredLevel The level required to access the function
    modifier onlyAdmin(uint requiredLevel) {
        require(isAdmin[msg.sender] && adminLevel[msg.sender][requiredLevel]);
        _;
    }

    /// @notice Modifier that will restrict access to functions. 
    /// Only administrators with one of the specified levels will have access.
    /// @param requiredLevels The levels required to access the function
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