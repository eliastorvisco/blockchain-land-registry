pragma solidity ^0.4.17;

import "./LandRegistry.sol";
import "./PurchaseAndSale.sol";

contract Property {

    /***********************************************
     *  Property Attributes
     */

    uint public IDUFIR;
    uint public CRU;
    string public description;
    address public owner;
    LandRegistry public landRegistry;
    PurchaseAndSale public purchaseAndSaleContract;

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

    function getPropertyInfo() public view returns (uint _IDUFIR, uint _CRU, string _description, address _owner, address _landRegistry, address _purchaseAndSaleContract) {
        return (IDUFIR, CRU, description, owner, landRegistry, purchaseAndSaleContract);
    }

    /***********************************************
     *  Property Logics
     */

    function setPurchaseAndSaleContract(address _purchaseAndSaleContract) public onlyOwner {
        require(purchaseAndSaleContract == PurchaseAndSale(0));
        purchaseAndSaleContract = PurchaseAndSale(_purchaseAndSaleContract);
        require(purchaseAndSaleContract.property() == address(this) && purchaseAndSaleContract.seller() == owner); 
    }

    function resolvePurchase() public {

        require(msg.sender == address(purchaseAndSaleContract));

        if (purchaseAndSaleContract.hasBeenQualified() && purchaseAndSaleContract.qualification() == true) {
            transferOwnership(purchaseAndSaleContract.seller(), purchaseAndSaleContract.buyer());
        } 

        purchaseAndSaleContract = PurchaseAndSale(0); 
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