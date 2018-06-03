pragma solidity ^0.4.17;

import "./EuroToken.sol";

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

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a && c >= b);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract PurchaseContract {
    // Property Info

    using SafeMath for uint;

    event DocumentDistributed(address indexed origin, address indexed destinatary, address document);
    event DocumentRequest(address indexed origin, address indexed destinatary, string description);

    enum Phases { Join, Writting, Paying, Signing, Calificating, Finished }
    Phases public phase;

    // Contract and Property Info

    address public property;
    uint public price;
    uint public priceDecimals;
    address euroToken;
    
    // Participants

    struct ContractParticipant {
        address addr;
        string pk;
        bool signature;
        address contractCopy;
        string sha256ContractHash;
        address[] documents;
        uint debts;
        uint paid;
    }

    ContractParticipant public seller;
    ContractParticipant public buyer;


    // Public Agents

    struct PublicAgent {
        address addr;
        string pk;
        bool calification;
        address contractCopy;
        string sha256ContractHash;
        address[] documents;
    }

    PublicAgent public notary;
    PublicAgent public registrar;


    function PurchaseContract(address _property, uint _price, address _seller, address _registrar, address _euroToken) public {
        property = _property;
        price = _price;
        priceDecimals = 4; // = euroToken.decimals;
        euroToken = _euroToken;
        seller.addr = _seller;
        registrar.addr = _registrar;
    }

    /***********************************************
     *  Getters
     */

    function getAllActors() public view returns (address sellerAddr, address buyerAddr, address notaryAddr, address registrarAddr) {
        return (seller.addr, buyer.addr, notary.addr, registrar.addr);
    }


    function getSellerInfo() public view returns (address addr, bool signature, uint debt, string pk) {
        return (
            seller.addr,
            seller.signature,
            seller.debts,
            seller.pk
        );
    }

    function getBuyerInfo() public view returns (address addr, bool signature, uint debt, string pk) {
        return (
            buyer.addr,
            buyer.signature,
            buyer.debts,
            buyer.pk
        );
    }

    function getNotaryInfo() public view returns (address addr, bool calification, string pk) {
        return(
            notary.addr,
            notary.calification,
            notary.pk
        );
    }

    /***********************************************
     *  Phase Functions
     */

    function changePhase(Phases newPhase) internal view {
        phase = newPhase;
    } 

    /***********************************************
     *  Phase: Join
     */

    function addBuyer(address _buyer) public onlyWhen(Phases.Join) {
        buyer.addr = _buyer;
        buyer.debts = price + price*(5+6)/100;
    }

    function addNotary(address _notary) public onlyWhen(Phases.Join){
        notary.addr = _notary;
    }
    
    function setSelfPk(string pk) onlyContractActors public onlyWhen(Phases.Join) {
        if (msg.sender == buyer.addr) buyer.pk = pk;
        else if (msg.sender == seller.addr) seller.pk = pk;
        else if (msg.sender == notary.addr) notary.pk = pk;
        else if (msg.sender == registrar.addr) registrar.pk = pk;
        else revert();

        if(bytes(buyer.pk).length != 0 && bytes(seller.pk).length != 0 && bytes(notary.pk).length != 0) {
            changePhase(Phases.Writting);
        }
    }

    /***********************************************
     *  Phase.Writting
     */

    function requestDocument(address origin, address destinatary, string description) onlyContractActors onlyWhen(Phases.Writting) public {
        DocumentRequest(origin, destinatary, description);
    }

    function setContractDocument(address buyerDocument, address sellerDocument, address registrarDocument) public {
        buyer.contractCopy = buyerDocument;
        seller.contractCopy = sellerDocument;
        registrar.contractCopy = registrarDocument;
    }

    function validateContractDocument(string hash) public {
        if (msg.sender == seller.addr) seller.sha256ContractHash = hash;
        else if (msg.sender == buyer.addr) seller.sha256ContractHash = hash;
        else revert();

        if (keccak256(seller.sha256ContractHash) == keccak256(seller.sha256ContractHash)) {
            changePhase(Phases.Signing);
        }
    }

    // function uploadDocuments(address[] destinataries, address[] documents) public onlyContractActors onlyWhen(Phases.Writting) {
    //     sendDocuments(destinataries, documents);
    // }

    // function sendDocuments(address[] destinataries, address[] documents) internal {
    //     for (uint i = 0; i < destinataries.length; i++) {
    //         if (isContractActor(destinataries[i])) {
    //             sendDocument(destinataries[i], documents[i]);
    //         }     
    //     }
    // }

    // function sendDocument(address destinatary, address document) internal {
    //     documentsFor[destinatary].push(document);
    //     DocumentDistributed(msg.sender, destinatary, document);
    // }

    /***********************************************
     *  Phase.Paying
     */
    
    function pay() public onlyWhen(Phases.Paying) {
        EuroToken memory euro = EuroToken(euro);
        if (isBuyer() && buyer.paid < buyer.debts) {
            buyer.paid = euro.allowance(msg.sender, this);
            if (seller.paid > seller.debts) {
                euro.transferFrom(seller.addr, this, seller.paid.sub(seller.debts));
                euro.transfer(seller.addr, seller.paid.sub(seller.debts));
                seller.paid = euro.allowance(msg.sender, this);
            }
        } else if (isSeller() && seller.paid < seller.debts) {
            seller.paid = euro.allowance(msg.sender, this);
            if (seller.paid > seller.debts) {
                euro.transferFrom(seller.addr, this, seller.paid.sub(seller.debts));
                euro.transfer(seller.addr, seller.paid.sub(seller.debts));
                seller.paid = euro.allowance(msg.sender, this);
            }
        } else if (!isBuyer() || !isSeller()) revert();

        if (buyer.debts == buyer.paid && seller.debts == seller.paid) {
            changePhase(Phases.Signing);
        }
    }

    /***********************************************
     *  Phase.Signing
     */

    function sign(bool _signature) public onlyWhen(Phases.Signing) {
        if (msg.sender == seller) seller.signature = _signature;
        else if (msg.sender == buyer) buyer.signature = _signature;
        else revert();
        
        if(buyer.signature == true && seller.signature == true) {
            //addRegistrar();
            changePhase(Phases.Calificating);
        } 
    }

    
    /***********************************************
     *  Phase.Calificating
     */

    function calificate(bool _calification) public onlyWhen(Phases.Calificating) {
        registrar.calification = _calification;
        changePhase(Phases.Finished);
    }

    /***********************************************
     *  Phase.Calificating
     */



    /***********************************************
     *  Auxiliar Functions and Modifiers
     */

    function isBuyer() internal view returns(bool) {return (msg.sender == buyer.addr)}
    function isSeller() internal view returns(bool) {return (msg.sender == seller.addr)}
    function isNotary() internal view returns(bool) {return (msg.sender == notary.addr)}
    function isRegistrar() internal view returns(bool) {return (msg.sender == registrar.addr)}

    modifier onlyContractActors() {
        require(isContractActor(msg.sender));
        _;
    }

    modifier onlyWhen(Phases phs) {
        require(phase == phs);
        _;
    }

    function isContractActor(address actor) private returns (bool) {
        return (actor == seller || actor == buyer || actor == notary);
    }
}

