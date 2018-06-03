pragma solidity ^0.4.17;

contract Document {

    address public creator;
    string public description;
    string public link;
    string public hash;

    function Document(string _description, string _link, string _hash) public {
        creator = msg.sender;
        description = _description;
        link = _link;
        hash = _hash;
    }

    function getDocumentInfo() public view returns (address creator, string description, string link, string hash) {
        return (
            creator, 
            description,
            link,
            hash
        );
    }
}


contract PurchaseContract {
    // Property Info

    event DocumentDistributed(address indexed origin, address indexed destinatary, address document);
    event DocumentRequest(address indexed origin, address indexed destinatary, string description);

    enum Phases { Join, Writting, Paying, Signing, Calificating, Finished }
    Phases public phase;

    address public property;
    uint public price;

    mapping (address => address[]) public documentsFor;
    mapping (address => string) public pkFrom;
    
    mapping (address => )

    address public seller;
    address public buyer;

    address public notary;
    address public registrar;

    address public buyerBank;
    address public sellerBank;

    mapping (address => bool) public signature;
    bool public calification;

    function PurchaseContract(address _property, address _seller) public {
        property = _property;
        seller = _seller;
    }

    /***********************************************
     *  Getters
     */

    function getAllActors() public view returns (address seller, address buyer, address sellerBank, address buyerBank, address notary, address registrar) {
        return (seller, buyer, sellerBank, buyerBank, notary, registrar);
    }

    function getParticipantsInfo() public view returns (address seller, bool sellerSignature, address buyer, bool buyerSignature) {
        return (
            seller,
            signature[seller],
            buyer,
            signature[buyer]
        );
    }

    /***********************************************
     *  Phase Functions
     */

    function changePhase(Phases newPhase) internal view {
        phase = newPhase;
    } 

    /***********************************************
     *  Setters
     */

    function setSelfPk(string pk) onlyContractActors public {
        pkFrom[msg.sender] = pk;
    }

    function addSeller(address _seller) public {
        seller = _seller;
    }

    function addNotary(address _notary) public {
        notary = _notary;
    }

    function addRegistrar(address _registrar) public {
        registrar = _registrar;
    }

    

    /***********************************************
     *  Contract Logics
     */

    function sign(bool _signature) public {
        signature[msg.sender] = _signature;
    }

    function calificate(bool _calification, address[] destinataries, address[] documents) public {
        calification = _calification;
        sendMultipleDocuments(destinataries, documents);
    }


    function sendMultipleDocuments(address[] destinataries, address[] documents) public {
        for (uint i = 0; i < destinataries.length; i++) {
            if (isContractActor(destinataries[i])) {
                sendDocument(destinataries[i], documents[i]);
            }     
        }
    }

    function sendDocument(address destinatary, address document) public {
        documentsFor[destinatary].push(document);
        DocumentDistributed(msg.sender, destinatary, document);
    }

    function requestDocument(address origin, address destinatary, string description) onlyContractActors public {
        DocumentRequest(origin, destinatary, description);
    }

    modifier onlyContractActors() {
        require(isContractActor(msg.sender));
        _;
    }

    modifier onlyWhen(Phases phs) {
        require(phase == phs);
        _;
    }

    function isContractActor(address actor) private returns (bool) {
        return (actor == seller || actor == buyer || actor == sellerBank || actor == buyerBank || actor == notary || actor == registrar);
    }



}