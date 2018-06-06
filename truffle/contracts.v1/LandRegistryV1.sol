pragma solidity ^0.4.17;

import "./Property.sol";

contract LandRegistry {

    enum EntryCode { Presentation, Inscription }

    event EntrySubmission(uint entryCode, address property, string description, address document);
    event PropertyRegistered(address property, uint index);

    struct PropertyRegister {
        address[] list;
        mapping (address => bool) registered;
        // mapping (address => address[]) byOwner //Why should we store this. If we want to know the property owner we can do it thorugh Property contract
    }

    struct LandRegistryInfo {
        string autonomousCommunity;
        string name;
        string description;
        address registrar;
        //string registrarPk;
    }



    PropertyRegister properties;
    LandRegistryInfo public landRegistry;
   

    function LandRegistry(string _autonomousCommunityName, string _registryName, string _registryDescription) public {
        landRegistry = LandRegistryInfo({
            autonomousCommunity: _autonomousCommunityName,
            name: _registryName,
            description: _registryDescription,
            registrar: 0x0
        });  
    }

    /***********************************************
     *  Info getters
     */

    function getRegistrar() public view returns (address registrar) {
        return landRegistry.registrar;
    }

    function getLandRegistryInfo() public view returns (string autonomuousCommunity, string name, string description, address registrar) {
        return (
            landRegistry.autonomousCommunity,
            landRegistry.name,
            landRegistry.description,
            landRegistry.registrar
        );
    }

    /***********************************************
     *  Property Getters
     */

    function getAllProperties() public view returns (address[]) {
        return properties.list;
    }

    function getNumberOfProperties() public view returns (uint) {
        return properties.list.length;
    }

    function getPropertyAt(uint index) public view returns (address) {
        return properties.list[index];
    }

    /***********************************************
     *  Land Registry Logics
     */

    function registerEntry(uint entryCode, address property, string description, address document) public onlyRegistrar {
        emit EntrySubmission(entryCode, property, description, document);
    }

    function nameRegistrar(address _registrar) public {
        landRegistry.registrar = _registrar;
    }

    function registerProperty(uint IDUFIR, uint CRU, string description, address owner) public onlyRegistrar {
        Property property = new Property(IDUFIR, CRU, description, owner, this); 
        properties.list.push(address(property));  
        PropertyRegistered(address(property), properties.list.length -1);
    }

    modifier onlyRegistrar() {
        require(msg.sender == landRegistry.registrar);
        _;
    }
}