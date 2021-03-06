pragma solidity ^0.4.17;

import "./LandRegistry.sol";
import "./PurchaseContract.sol";

/// @title Property
/// @author Elias Torvisco
/// @notice Simulates a real property.
/// @dev All function calls are currently implement without side effects
contract Property {

    uint public IDUFIR;
    uint public CRU;
    string public description;
    address public owner;
    LandRegistry public landRegistry;
    PurchaseContract public purchaseContract;

    /// @notice The property will be initialized with the usual property identifiers: IDUFIR and CRU, and owner and the land registry
    /// @dev Only the registrar can create a Property linked with the Land Registry
    function Property(uint _IDUFIR, uint _CRU, string _description, address _owner, address _landRegistry) public {
        landRegistry = LandRegistry(_landRegistry);
        require(msg.sender == landRegistry.registrar());
        IDUFIR = _IDUFIR;
        CRU = _CRU;
        description = _description;
        owner = _owner;
    }

    /// @notice Returns all the information about the Property
    function getPropertyInfo() public view returns (uint _IDUFIR, uint _CRU, string _description, address _owner, address _landRegistry, address _purchaseContract) {
        return (IDUFIR, CRU, description, owner, landRegistry, purchaseContract);
    }

    /// @notice Allows the owner to link a sales contract to the property.
    function setPurchaseContract(address _purchaseContract) public onlyOwner {
        require(purchaseContract == PurchaseContract(0));
        purchaseContract = PurchaseContract(_purchaseContract);
        require(purchaseContract.property() == address(this) && purchaseContract.getSeller() == owner && purchaseContract.getRegistrar() == landRegistry.registrar());
    }

    /// @notice This function will be called from the purchase and sale contract
    /// to apply the result of the negotiation.
    function resolvePurchase() public {

        require(msg.sender == address(purchaseContract));

        if (purchaseContract.hasBeenQualified() && purchaseContract.qualification() == true) {
            transferOwnership(purchaseContract.getSeller(), purchaseContract.getBuyer());
        } 

        purchaseContract = PurchaseContract(0); 
    }

    /// @notice Internal function that will be called modify the owner of the property
    function transferOwnership(address currentOwner, address newOwner) internal  {
        require(currentOwner == owner);
        owner = newOwner;
    }

    /// @notice Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}