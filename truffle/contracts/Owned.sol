pragma solidity ^0.4.17;

/// @title Owned
/// @notice The Owned contract has an owner address, and provides basic authorization control
/// functions, this simplifies the implementation of "user permissions".
/// @dev All function calls are currently implement without side effects
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    /// @notice The Owned constructor sets the original 'owner' of the contract to the
    /// sender account.
    function Owned() public {
        owner = msg.sender;
    }

    /// @notice Throws if called by any account other than the owner.
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /// @notice Transfers control of the contract to a newOwner.
    /// @param _newOwner The address to transfer ownership to.
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    /// @notice Allows the new owner to accept control of the contract
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}