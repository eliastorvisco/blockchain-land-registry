pragma solidity ^0.4.17;

contract PropertyMarket {

    event Sale(address property, string description);

    struct PurchaseRequest {
        address property;
        bool accepted;
    }

    mapping (address => PurchaseRequest[]) buyerRequests;

    mapping (address => bool) marketAvailability;
}

contract LandRegistry {
    address public registrar;

    address[] properties;

    function LandRegistry() public {

    }


    function nameRegistrar(address _registrar) public {
        //Check ColegioRegistradores has it
        registrar = _registrar;
    }

    function registerProperty(uint IDUFIR, uint CRU, string description, address owner) public {
        properties.push(new Property(IDUFIR, CRU, description, owner, this));
    }
}

contract Property {

    uint IDUFIR;
    uint CRU;
    address public registry;

    string description;

    address owner;

    address purchaseContract;

    function Property(uint _IDUFIR, uint _CRU, string _description, address _owner, address _registry) public {
        IDUFIR = _IDUFIR;
        CRU = _CRU;
        description = _description;
        owner = _owner;
        registry = _registry;
    }

    function createPurchaseContract() onlyOwner public {
        require(purchaseContract == 0x0);
        purchaseContract = new PurchaseContract(this, owner);
    }

    function transferOwnership(address from, address to) public {
        require(msg.sender == purchaseContract);
        require(from == owner);

        owner = to;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }



}

contract PurchaseContract {

    enum ContractPhases { Writting, Signing, RegistrarCalification, Finished }
    ContractPhases phase;


    address public property;

    string contractConditions;

    address public seller;
    bool public sellerSignature;

    address public buyer;
    bool public buyerSignature;

    address public notary;
    bool public notaryCalification;

    address public registrar;
    bool public registrarCalification;
    string public registrarCalificationDescription;

    address public sellersBank;
    string sellersBankConditions;
    bool public sellersBankAcceptance;


    address public buyersBank;
    string buyersBankCompromise;
    bool public buyersBankAcceptance;

    

    function PurchaseContract(address _property, address _seller) public {
        property = _property;
        seller = _seller;
        phase = ContractPhases.Writting;
    }

    function addBuyer(address _buyer)  public {
        require (buyer != 0x0);
        buyer = _buyer;
    }

    function addNotary(address _notary)  public {
        require (notary != 0x0);
        notary = _notary;
    }

    function addRegistrar() private {
        registrar = LandRegistry((Property(property).registry())).registrar();
    } 

    function writeConditions(string conditions) onlyNotary public {
        contractConditions = conditions;
        phase = ContractPhases.Signing;
    }

    function sign(bool signature) public {
        if (msg.sender == buyer) buyerSignature = signature;
        else if (msg.sender == seller) sellerSignature = signature;
        else revert();
    }

    function calificateNotary(bool calification) public onlyNotary {
        notaryCalification = calification;
    }

    function calificateRegistrar(bool calification, string description) public onlyRegistrar {
        registrarCalification = calification;
        registrarCalificationDescription = description;
    }

    function setBankAcceptance(bool acceptance) public {
        if (msg.sender == buyersBank) buyersBankAcceptance = acceptance;
        else if (msg.sender == sellersBank) sellersBankAcceptance = acceptance;
        else revert();
        checkAllSigned();
    }

    function checkAllSigned() private {
        if (sellerSignature && buyerSignature && buyersBankAcceptance && sellersBankAcceptance && notaryCalification);
        phase = ContractPhases.RegistrarCalification;
        addRegistrar();
    }

    modifier onlySeller() {
        require(msg.sender == seller);
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer);
        _;
    }

    modifier onlyNotary() {
        require(msg.sender == notary);
        _;
    }

    modifier onlyRegistrar() {
        require(msg.sender == registrar);
        _;
    }

    modifier onlySellersBank() {
        require(msg.sender == sellersBank);
        _;
    }

    modifier onlyBuyersBank() {
        require(msg.sender == buyersBank);
        _;
    }
}