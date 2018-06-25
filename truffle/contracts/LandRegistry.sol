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
    event DiaryBook(uint indexed identifier, address document, address registrar);
    event InscriptionBook(uint indexed identifier, uint indexed inscriptionType, address indexed property, address document, address registrar);
    event PropertyRegistration(uint indexed IDUFIR, uint indexed CRU, bool firstRegistration, address indexed property, address owner, address registrar);

    string public name;
    string public addressInfo; // Street - Town [Postcode]
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
    function addPresentationEntry(uint identifier, address document) public onlyRegistrar {
        emit DiaryBook(identifier, document, registrar);
    }

    /// @param identifier The off-chain identifier of the inscription entry
    /// @param inscriptionType The inscription type: inscription, cancelation ...
    /// @param description A public description of the entry
    /// @param document The address of the contract Document containing the reference to IPFS
    /// @dev Only the registrar must be allowed to call this function.
    function addInscriptionEntry(uint identifier, uint inscriptionType, address property, address document) public onlyRegistrar {
        emit InscriptionBook(identifier, inscriptionType, property, document, registrar);
    }

    /// @notice This function allows you to register a Property contract in the Land Registry
    /// @param property The address of the property to be registered
    /// @param identifier The off-chain identifier of the inscription entry
    /// @param description A public description of the entry
    /// @param document The address of the contract Document containing the reference to IPFS
    /// @dev Only the registrar must be allowed to call this function.
    function register(address property) public onlyRegistrar {
        Property newProperty = Property(property);
        require(newProperty.landRegistry() == address(this));
        bool firstRegistration = !isRegistered[property];
        uint IDUFIR;
        uint CRU;
        address owner;
        (IDUFIR, CRU,, owner,,) = newProperty.getPropertyInfo();

        isRegistered[property] = true;
        emit PropertyRegistration(IDUFIR, CRU, firstRegistration, property, owner, registrar);
    }

    /// @notice Modifier that will restrict access to functions. 
    /// Only the registrar will be allowed.
    modifier onlyRegistrar() {
        require(msg.sender == registrar);
        _;
    }
}