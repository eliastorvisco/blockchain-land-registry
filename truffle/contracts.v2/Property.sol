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
    address public landRegistry;
    address public purchaseContract;

    function Property(uint _IDUFIR, uint _CRU, string _description, address _owner, address _landRegistry) public {

        IDUFIR = _IDUFIR;
        CRU = _CRU;
        description = _description;
        owner = _owner;
        landRegistry = _landRegistry;
    }

    /***********************************************
     *  Property Getters
     */

    function getIDUFIR() public view returns (uint _IDUFIR) {return IDUFIR;}
    function getCRU() public view returns (uint _CRU) {return CRU;}
    function getDescription() public view returns (string _description) {return description;}
    function getOwner() public view returns (address _owner) {return owner;}

    function getPropertyInfo() public view returns (uint _IDUFIR, uint _CRU, string _description, address _owner) {
        return (IDUFIR, CRU, description, owner);
    }

    /***********************************************
     *  Property Logics
     */

    function createPurchaseContract(uint price, address euroToken) onlyOwner public {
        require(purchaseContract == address(0));
        purchaseContract = new PurchaseContract(this, price, owner, LandRegistry(landRegistry).registrar(), euroToken);
    }

    function transferOwnership(address from, address to) public {
        require(msg.sender == purchaseContract);
        owner = to;
        purchaseContract = address(0); 
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}