pragma solidity ^0.4.17;

import "./LandRegistry.sol";
import "./PurchaseContract.sol";

contract Property {





    struct PropertyInfo {
        uint IDUFIR;
        uint CRU;
        string description;
        address owner;
    }

    struct AdministrativeInfo {
        address registry;
    }

    struct TransfershipInfo {
        bool transferingState;
        address purchaseContract;
    }

    PropertyInfo public propertyInfo;
    AdministrativeInfo public adminInfo;
    TransfershipInfo public transfer;


    function Property(uint _IDUFIR, uint _CRU, string _description, address _owner, address _registry) public {

        propertyInfo = PropertyInfo ({
            IDUFIR: _IDUFIR,
            CRU: _CRU,
            description: _description,
            owner: _owner
        });

        adminInfo = AdministrativeInfo({
            registry: _registry
        });

        transfer = TransfershipInfo({
            transferingState: false,
            purchaseContract: 0x0
        });
    }

    /***********************************************
     *  Property Getters
     */

    function getIDUFIR() public view returns (uint IDUFIR) {return propertyInfo.IDUFIR;}
    function getCRU() public view returns (uint CRU) {return propertyInfo.CRU;}
    function getDescription() public view returns (string description) {return propertyInfo.description;}
    function getOwner() public view returns (address owner) {return propertyInfo.owner;}

    function getPropertyInfo() public view returns (uint IDUFIR, uint CRU, string description, address owner) {
        return (
            propertyInfo.IDUFIR,
            propertyInfo.CRU,
            propertyInfo.description,
            propertyInfo.owner
        );
    }
    

    function getAdministrativeInfo() public view returns (address registry) {
        return (
            adminInfo.registry
        );
    }
    
    function getTransfershipInfo() public view returns (bool transferingState, address purchaseContract) {
        return (
            transfer.transferingState,
            transfer.purchaseContract
        );
    }

    /***********************************************
     *  Property Logics
     */

    function createPurchaseContract(uint price, address euroToken) onlyOwner public {
        require(transfer.purchaseContract == address(0));
        transfer = TransfershipInfo({
            transferingState: true,
            purchaseContract: new PurchaseContract(this, price, propertyInfo.owner, LandRegistry(adminInfo.registry).getRegistrar(), euroToken)
        });
    }

    function transferOwnership(address from, address to) public {
        require(msg.sender == transfer.purchaseContract);
        require(from == propertyInfo.owner);

        propertyInfo.owner = to;
        transfer = TransfershipInfo({
            transferingState: false,
            purchaseContract: 0x0
        });
    }

    modifier onlyOwner() {
        require(msg.sender == propertyInfo.owner);
        _;
    }
}