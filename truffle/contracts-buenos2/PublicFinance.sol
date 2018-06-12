pragma solidity ^0.4.17;

import "./EuroToken.sol";
import "./MultiAdmin.sol";

contract PublicFinance is MultiAdmin {

    mapping(bytes32 => uint) taxPercentage;
    EuroToken public euroToken;

    function PublicFinance() public {}

    function setEuroToken(address _euroToken) public onlyAdmin(0) {
        euroToken = EuroToken(_euroToken);
    }

    function addTax(bytes32 tax, uint percentage) public onlyAdmin(0) {
        taxPercentage[tax] = percentage;
    }

    function calculate(bytes32 tax, uint subject) public returns (uint) {
        return subject * taxPercentage[tax]/100;
    }
}