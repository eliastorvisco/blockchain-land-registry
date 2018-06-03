pragma solidity ^0.4.17;

import "./Property.sol";

contract LandRegistry {

    struct PropertyRegister {
        address[] list;
        // mapping (address => address[]) byOwner //Why should we store this. If we want to know the property owner we can do it thorugh Property contract
    }

    struct LandRegistryInfo {
        string autonomousCommunity;
        string name;
        string description;
        address registrar;
        //string registrarPk;
    }

    struct AdminOrganizations {
        address justiceMinistry;
        address DGRN;
        address autonomousCommunity;
        address publicFinance;
    }

    PropertyRegister public properties;
    LandRegistryInfo public landRegistry;
    AdminOrganizations public adminOrganizations;

    function LandRegistry(string _autonomousCommunityName, string _registryName, string _registryDescription, address _justiceMinistry, address _DGRN, address _autonomousCommunity, address _publicFinance) public {
        landRegistry = LandRegistryInfo({
            autonomousCommunity: _autonomousCommunityName,
            name: _registryName,
            description: _registryDescription,
            registrar: 0x0
        });

        adminOrganizations = AdminOrganizations({
            justiceMinistry: _justiceMinistry,
            DGRN: _DGRN,
            autonomousCommunity: _autonomousCommunity,
            publicFinance: _publicFinance
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

    function getAdminOrganizations() public view returns (address justiceMinistry, address DGRN, address autonomousCommunity, address publicFinance) {
        return (
            adminOrganizations.justiceMinistry,
            adminOrganizations.DGRN,
            adminOrganizations.autonomousCommunity,
            adminOrganizations.publicFinance
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

    function getPropertiesAtRange(uint indexA, uint indexB) public view returns (address[]) {
        require (indexA < indexB && indexA >= 0 && indexB >= 0);
        address[] tmp;
        
        for (uint i = indexA; i < indexB; i++) {
            tmp.push(properties.list[i]);
        }
        return tmp;
    }

    // function getOwnerProperties(address owner) public view returns (address[]) {
    //     return properties.byOwner[owner];
    // }

    // function getOwnerPropertyAt(address owner, uint index) public view returns (address) {
    //     return properties.byOwner[owner][index];
    // }

    /***********************************************
     *  Land Registry Logics
     */

    function nameRegistrar(address _registrar) public {
        landRegistry.registrar = _registrar;
    }

    function registerProperty(uint IDUFIR, uint CRU, string description, address owner) public {
        Property property = new Property(IDUFIR, CRU, description, owner, this); 
        properties.list.push(address(property));
    }
}

