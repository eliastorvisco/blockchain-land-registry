pragma solidity ^0.4.17;

import "./EuroToken.sol";
import "./MultiAdmin.sol";

/// @title PublicFinance
/// @author Elias Torvisco
/// @notice A contract designed to be controlled by the Public Finance.
/// Includes information and tax calculation functions.
/// @dev All function calls are currently implement without side effects
contract PublicFinance is MultiAdmin {

    mapping(bytes32 => uint) taxPercentage;
    EuroToken public euroToken;

    function PublicFinance() public {}

    /// @notice Function used to indicate the Euro Token contract to be used for making tax payments.
    /// @param _euroToken Euro Token contract address to use
    /// @dev Only an administrator can call this function. The administrator level is arbritrary.
    /// Future applications can change this value.
    function setEuroToken(address _euroToken) public onlyAdmin(0) {
        euroToken = EuroToken(_euroToken);
    }

    /// @notice Adds a new tax
    /// @param tax Tax diminutive
    /// @param percentage Porcentaje aplicado por el impuesto
    /// @dev Only an administrator can call this function. The administrator level is arbritrary.
    /// Future applications can change this value.
    function addTax(bytes32 tax, uint percentage) public onlyAdmin(0) {
        taxPercentage[tax] = percentage;
    }

    /// @notice Calculate the payment to be made 
    /// @param tax Identifier of the tax to be applied
    /// @param subject Value on which the tax will be applied
    function calculate(bytes32 tax, uint subject) public returns (uint) {
        return subject * taxPercentage[tax]/100;
    }
}