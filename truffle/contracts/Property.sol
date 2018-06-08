pragma solidity ^0.4.17;

import "./LandRegistry.sol";
import "./PurchaseContract.sol";

contract Property {

    /***********************************************
     *  Property Attributes
     */

    uint public IDUFIR;
    uint public CRU;
    string public description;
    address public owner;
    LandRegistry public landRegistry;
    PurchaseContract public purchaseContract;

    function Property(uint _IDUFIR, uint _CRU, string _description, address _owner, address _landRegistry) public {
        landRegistry = LandRegistry(_landRegistry);
        require(msg.sender == landRegistry.registrar());
        IDUFIR = _IDUFIR;
        CRU = _CRU;
        description = _description;
        owner = _owner;
        
    }

    /***********************************************
     *  Property Getters
     */

    function getPropertyInfo() public view returns (uint _IDUFIR, uint _CRU, string _description, address _owner) {
        return (IDUFIR, CRU, description, owner);
    }

    /***********************************************
     *  Property Logics
     */

    function setPurchaseContract(address _purchaseContract) public onlyOwner {
        require(purchaseContract == PurchaseContract(0));
        purchaseContract = PurchaseContract(_purchaseContract);
        require(purchaseContract.property() == address(this) && purchaseContract.getSeller() == owner && purchaseContract.getRegistrar() == landRegistry.registrar());
    }

    function resolvePurchase() public {
        require(msg.sender == address(purchaseContract) && purchaseContract.hasCalificated());
        if(purchaseContract.calification()) {
            transferOwnership(purchaseContract.getSeller(), purchaseContract.getBuyer());
        } 
        purchaseContract = PurchaseContract(0); 
    }

    function transferOwnership(address currentOwner, address newOwner) internal  {
        require(currentOwner == owner);
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}