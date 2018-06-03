pragma solidity ^0.4.17;

contract NotaryAcademy {
    address admin;

    mapping (address => bool) public isValidNotary;

    function NotaryAcademy() public {
        admin = msg.sender;
    }

    function addNotary(address _notary) public {
        isValidNotary[_notary] = true;
    } 

    function deleteNotary(address _notary) public {
        isValidNotary[_notary] = true;
    }


}