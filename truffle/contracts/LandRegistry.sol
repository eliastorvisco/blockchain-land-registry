pragma solidity ^0.4.17;

import "./Property.sol";
import "./MultiAdmin.sol";
import "./PublicFinance.sol";

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

    /***********************************************
     *  Info getters
     */


    function getLandRegistryInfo() public view returns (string, string, string, string, string, string, address) {
        return (name, addressInfo, province, telephone, fax, email, registrar);
    }

    /***********************************************
     *  Land Registry Logics
     */

    function setPublicFinance(address _publicFinance) public onlyAdmin(0) {
        publicFinance = PublicFinance(_publicFinance);
    }

    function setRegistrar(address _registrar) public onlyAdmin(0) {
        registrar = _registrar;
    }

    function addPresentationEntry(uint identifier, address document) public onlyRegistrar {
        emit DiaryBook(identifier, document, registrar);
    }

    function addInscriptionEntry(uint identifier, uint inscriptionType, address property, address document) public onlyRegistrar {
        emit InscriptionBook(identifier, inscriptionType, property, document, registrar);
    }

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


    modifier onlyRegistrar() {
        require(msg.sender == registrar);
        _;
    }
}