pragma solidity ^0.4.17;

import "./Property.sol";
import "./MultiAdmin.sol";

contract LandRegistry is MultiAdmin {

    enum InscriptionType { Inscription, Cancelation, MarginalNote }

    event PropertyCreated(address property);
    event DiaryBook(uint identifier, string description, address document, address registrar);
    event InscriptionBook(InscriptionType inscriptionType, address property, uint identifier, string description, address document);
    event IncapacitationBook(address subject, uint identifier, string description, address document);
    event PropertyRegistration(uint indexed IDUFIR, uint indexed CRU, bool firstRegistration, address property, address owner);

    string public name;
    string public addressInfo; // Street - Town [Postcode]
    string public province;
    string public telephone;
    string public fax;
    string public email;
    
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

    /***********************************************
     *  Info getters
     */


    function getLandRegistryInfo() public view returns (string, string, string, string, string, string, address) {
        return (name, addressInfo, province, telephone, fax, email, registrar);
    }

    /***********************************************
     *  Land Registry Logics
     */

    function setRegistrar(address _registrar) public onlyAdmin(0) {
        registrar = _registrar;
    }

    function addPresentationEntry(uint identifier, string description, address document) public onlyRegistrar {
        emit DiaryBook(identifier, description, document, registrar);
    }

    function addInscriptionEntry(address property, uint identifier, string description, address document) public onlyRegistrar {
        emit InscriptionBook(InscriptionType.Inscription, property, identifier, description, document);
    }

    function addCancelationEntry(address property, uint identifier, string description, address document) public onlyRegistrar {
        emit InscriptionBook(InscriptionType.Cancelation, property, identifier, description, document);
    }

    function addMarginalNoteEntry(address property, uint identifier, string description, address document) public onlyRegistrar {
        emit InscriptionBook(InscriptionType.MarginalNote, property, identifier, description, document);
    }

    function addIncapacitationEntry(address subject, uint identifier, string description, address document) public onlyRegistrar {
        emit IncapacitationBook(subject, identifier, description, document);
    }

    function createProperty(uint IDUFIR, uint CRU, string description, address owner) public onlyRegistrar {
        Property property = new Property(IDUFIR, CRU, description, owner, this); 
        emit PropertyCreated(property);
    }

    function register(address property, uint identifier, string description, address document) public onlyRegistrar {
        bool firstRegistration = !isRegistered[property];
        uint IDUFIR;
        uint CRU;
        address owner;
        (IDUFIR, CRU,, owner) = Property(property).getPropertyInfo();

        isRegistered[property] = true;
        emit PropertyRegistration(IDUFIR, CRU, firstRegistration, property, owner);
        addInscriptionEntry(property, identifier, description, document);
    }


    modifier onlyRegistrar() {
        require(msg.sender == registrar);
        _;
    }
}