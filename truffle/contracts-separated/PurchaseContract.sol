pragma solidity ^0.4.17;

import "./EuroToken.sol";
import "./Property.sol";

contract PurchaseContract {
    // Property Info

    event PhaseChanged(uint oldPhase, uint newPhase);
    event Signed(address from, bool signature);
    event Paid(address from, uint paid);
    event Calificated(address property, bool calification, address oldOwner, address newOwner);

    enum Phases { Join, Writting, Validation, Paying, Signing, Calificating, Finished }
    Phases public phase;

    EuroToken public euroToken;

    address public property;
    uint public price;    
    string public contractHash;
   

    struct ContractParticipant {
        address addr;
        uint debt;
        bool hasValidated;
        bool contractValidation;
        bool hasSigned;
        bool signature;
    }

    struct Registrar {
        address addr;
        bool hasCalificated;
        bool calification;
    }

    struct Notary {
        address addr;
    }

    ContractParticipant public seller;
    ContractParticipant public buyer;
    Notary public notary;
    Registrar public registrar;

    function PurchaseContract(address _property, uint _price, address _seller, address _registrar, address _euroToken) public {
        require(Property(_property).propertyInfo.owner == _seller);
        property = _property;
        price = _price;
        seller.addr = _seller;
        buyer.debt = _price;
        registrar.addr = _registrar;
        euroToken = EuroToken(_euroToken);
    }

    /***********************************************
    *  Phase Functions
    */

    function changePhase(Phases newPhase) internal {
        PhaseChanged(uint(phase), uint(newPhase));
        phase = newPhase;
    } 

    /***********************************************
     *  Phase: Join
     */

    function addBuyer(address _buyer) public onlyWhen(Phases.Join) onlySeller {
        buyer.addr = _buyer;
    }

    function addNotary(address _notary) public onlyWhen(Phases.Join) onlyBuyer {
        notary.addr = _notary;
        changePhase(Phases.Writting);
    }

    /***********************************************
     *  Phase.Writting
     */

    function setContractHash(string hash) public onlyNotary onlyWhen(Phases.Writting) {
        require(bytes(hash).length != 0);
        contractHash = hash;
        changePhase(Phases.Validation);
    }

    /***********************************************
     *  Phase.Validation
     */

    function validateContractDocument(string hash) public onlySellerOrBuyer onlyWhen(Phases.Validation) {

        if (keccak256(contractHash) == keccak256(hash)) {
            if (isSeller()) seller.contractValidation = true;
            else if (isBuyer()) buyer.contractValidation = true;
        } else {}

        if (seller.contractValidation && buyer.contractValidation) {
            changePhase(Phases.Paying);
        }
    }

    /***********************************************
     *  Phase.Paying
     */

    function updatePayment() public onlySellerOrBuyer onlyWhen(Phases.Paying) {
        Paid(msg.sender, euroToken.allowance(msg.sender, this));
        if (euroToken.allowance(buyer.addr, this) == buyer.debt && euroToken.allowance(seller.addr, this) == seller.debt) {
            changePhase(Phases.Signing);
        }
    }

    /***********************************************
     *  Phase.Signing
     */

    function sign(bool _signature) public onlySellerOrBuyer onlyWhen(Phases.Signing) {
        
        if (isSeller()) {
            require(!seller.hasSigned);
            seller.signature = _signature;
            seller.hasSigned = true;
        } else if (isBuyer()) {
            require(!buyer.hasSigned);
            buyer.signature = _signature;
            buyer.hasSigned = true;
        }

        Signed(msg.sender, _signature);

        if (buyer.hasSigned && buyer.signature && seller.hasSigned && seller.signature) {
            changePhase(Phases.Calificating);
        }
    }

    /***********************************************
     *  Phase.Calificating
     */

    function calificate(bool _calification) public onlyRegistrar onlyWhen(Phases.Calificating) {
        registrar.calification = _calification;
        registrar.hasCalificated = true;
        changePhase(Phases.Finished);
        if (_calification) {
            Property(property).transferOwnership(seller.addr, buyer.addr);
            euroToken.transferFrom(buyer.addr, seller.addr, buyer.debt);
        }
        Calificated(property, _calification, seller.addr, buyer.addr);
    }

    /***********************************************
     *  Auxiliar Functions
     */

    function isBuyer() internal view returns (bool) {return (msg.sender == buyer.addr);}
    function isSeller() internal view returns (bool) {return (msg.sender == seller.addr);}
    function isNotary() internal view returns (bool) {return (msg.sender == notary.addr);}
    function isRegistrar() internal view returns (bool) {return (msg.sender == registrar.addr);}

    /***********************************************
     *  Modifiers
     */

    modifier onlySellerOrBuyer() {require(isSeller() || isBuyer()); _;}
    modifier onlyBuyer() {require(isBuyer()); _;}
    modifier onlySeller() {require(isSeller()); _;}
    modifier onlyNotary() {require(isNotary()); _;}
    modifier onlyRegistrar() {require(isRegistrar()); _;}
    modifier onlyWhen(Phases strictPhase) {require(phase == strictPhase); _;}
    /***********************************************
    *  Info Getters
    */
    
    function getSellerSummary() public view returns (address addr, uint debt, uint paid, bool contractValidation, bool hasSigned, bool signature) {
        return (
            seller.addr,
            seller.debt,
            (phase > Phases.Paying)? seller.debt: euroToken.allowance(seller.addr, this),
            seller.contractValidation,
            seller.hasSigned,
            seller.signature
        );
    }

    function getBuyerSummary() public view returns (address addr, uint debt, uint paid, bool contractValidation, bool hasSigned, bool signature) {
        return (
            buyer.addr,
            buyer.debt,
            (phase > Phases.Paying)? buyer.debt: euroToken.allowance(buyer.addr, this),
            buyer.contractValidation,
            buyer.hasSigned,
            buyer.signature
        );
    }

    function getContractSummary() public view returns (uint currentPhase, bool contractWritten, bool hasBeenCalificated, bool calification) {
        return(
            uint(phase),
            (bytes(contractHash).length > 0),
            registrar.hasCalificated,
            registrar.calification
        );
    }
}