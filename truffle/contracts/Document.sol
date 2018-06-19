pragma solidity ^0.4.17;

contract Document {
    string public ipfsHash;
    string public documentHash;
    address public creator;

    function Document(string _ipfsHash, string _documentHash) public {
        ipfsHash = _ipfsHash;
        documentHash = _documentHash;
        creator = msg.sender;
    }

}