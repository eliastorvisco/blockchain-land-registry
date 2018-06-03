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
        if (sellerSignature && buyerSignature && buyersBankAcceptance && sellersBankAcceptance && notaryCalification) {
            phase = ContractPhases.RegistrarCalification;
            addRegistrar();
        } 
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