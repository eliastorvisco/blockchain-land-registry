pragma solidity ^0.4.17;

import "./Property.sol";
import "./MultiAdmin.sol";
import "./PublicFinance.sol";

/// @title Land Registry
/// @author Elias Torvisco
/// @dev All function calls are currently implement without side effects
contract LandRegistry is MultiAdmin {

    enum InscriptionType { Inscription, Cancelation, MarginalNote }

    event PropertyCreated(address property);
    event DiaryBook(uint identifier, string description, address document, address registrar);
    event InscriptionBook(InscriptionType inscriptionType, address property, uint identifier, string description, address document);
    event IncapacitationBook(address subject, uint identifier, string description, address document);
    event PropertyRegistration(uint indexed IDUFIR, uint indexed CRU, bool firstRegistration, address property, address owner);

    string public name;
    string public addressInfo;
    string public province;
    string public telephone;
    string public fax;
    string public email;

    PublicFinance public publicFinance;
    
    address public registrar;

    mapping (address => bool) public isRegistered;
   

    function LandRegistry(string _name, string _addressInfo, string _province, string _telephone, string _fax, string _email) public {
        name = _name;
        addressInfo = _addressInfo;
        province = _province;
        telephone = _telephone;
        fax = _fax;
        email = _email;
    }



    /// @notice Returns the contact and location information about the Land Registry
    function getLandRegistryInfo() public view returns (string, string, string, string, string, string, address) {
        return (name, addressInfo, province, telephone, fax, email, registrar);
    }

    /// @param _publicFinance The address of the Public Finance contract
    /// @dev Only an administrator can call this function. The administrator level is arbritrary.
    /// Future applications can change this value.
    function setPublicFinance(address _publicFinance) public onlyAdmin(0) {
        publicFinance = PublicFinance(_publicFinance);
    }

    /// @param _registrar The address of the new registrar who will administer the Land Registry
    /// @dev Only an administrator can call this function. The administrator level is arbritrary.
    /// Future applications can change this value.
    function setRegistrar(address _registrar) public onlyAdmin(0) {
        registrar = _registrar;
    }

    /// @param identifier The off-chain identifier of the presentation entry
    /// @param description A public description of the entry
    /// @param document The address of the contract Document containing the reference to IPFS
    /// @dev Only the registrar must be allowed to call this function.
    function addPresentationEntry(uint identifier, string description, address document) public onlyRegistrar {
        emit DiaryBook(identifier, description, document, registrar);
    }

    /// @param identifier The off-chain identifier of the inscription entry
    /// @param description A public description of the entry
    /// @param document The address of the contract Document containing the reference to IPFS
    /// @dev Only the registrar must be allowed to call this function.
    function addInscriptionEntry(address property, uint identifier, string description, address document) public onlyRegistrar {
        emit InscriptionBook(InscriptionType.Inscription, property, identifier, description, document);
    }

    /// @param identifier The off-chain identifier of the cancelation entry
    /// @param description A public description of the entry
    /// @param document The address of the contract Document containing the reference to IPFS        
    /// @dev Only the registrar must be allowed to call this function.
    function addCancelationEntry(address property, uint identifier, string description, address document) public onlyRegistrar {
        emit InscriptionBook(InscriptionType.Cancelation, property, identifier, description, document);
    }

    /// @param identifier The off-chain identifier of the marginal note entry
    /// @param description A public description of the entry
    /// @param document The address of the contract Document containing the reference to IPFS
    /// @dev Only the registrar must be allowed to call this function.
    function addMarginalNoteEntry(address property, uint identifier, string description, address document) public onlyRegistrar {
        emit InscriptionBook(InscriptionType.MarginalNote, property, identifier, description, document);
    }

    /// @notice This function allows you to register a Property contract in the Land Registry
    /// @param property The address of the property to be registered
    /// @param identifier The off-chain identifier of the inscription entry
    /// @param description A public description of the entry
    /// @param document The address of the contract Document containing the reference to IPFS
    /// @dev Only the registrar must be allowed to call this function.
    function register(address property, uint identifier, string description, address document) public onlyRegistrar {
        Property newProperty = Property(property);
        require(newProperty.landRegistry() == address(this));
        bool firstRegistration = !isRegistered[property];
        uint IDUFIR;
        uint CRU;
        address owner;
        (IDUFIR, CRU,, owner,,) = newProperty.getPropertyInfo();

        isRegistered[property] = true;
        emit PropertyRegistration(IDUFIR, CRU, firstRegistration, property, owner);
        addInscriptionEntry(property, identifier, description, document);
    }

    /// @notice Modifier that will restrict access to functions. 
    /// Only the registrar will be allowed.
    modifier onlyRegistrar() {
        require(msg.sender == registrar);
        _;
    }
}