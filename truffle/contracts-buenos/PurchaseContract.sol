pragma solidity ^0.4.17;

import "./Property.sol";
import "./EuroToken.sol";

contract PurchaseContract {
    // Property Info

    event PhaseChanged(uint oldPhase, uint newPhase);
    event Signed(address from, bool signature);
    event Paid(address from, uint paid);
    event Calificated(address property, bool calification, address oldOwner, address newOwner);

    enum Phases { Join, Writting, Validation, Paying, Signing, Calificating, Finished, Canceled }
    struct ContractParticipant {
        address addr;
        uint debt;
        bool hasValidated;
        bool contractValidation;
        bool hasSigned;
        bool signature;
    }

    Phases public phase;
    Property public property;
    uint public price;    
    string public contractHash;
    bool public calification;
   
    ContractParticipant public seller;
    ContractParticipant public buyer;
    address public notary;

    EuroToken public euroToken;

    address whoCanceled;

    function PurchaseContract(address _property, uint _price, address _euroToken) public {
        property = Property(_property);
        seller.addr = property.owner();
        
        price = _price;
        
        buyer.debt = _price;
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
     *  -> Cancel
     */

    function cancel() public onlySellerOrBuyer onlyBefore(Phases.Calificating) {
        whoCanceled = msg.sender;
        changePhase(Phases.Canceled);
    }

    /***********************************************
     *  Phase: Join
     */

    function addBuyer(address _buyer) public onlyWhen(Phases.Join) onlySeller {
        buyer.addr = _buyer;
    }

    function addNotary(address _notary) public onlyWhen(Phases.Join) onlyBuyer {
        notary = _notary;
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

        if (keccak256(bytes(contractHash)) == keccak256(bytes(hash))) {
            if (isSeller()) seller.contractValidation = true;
            else if (isBuyer()) buyer.contractValidation = true;
        }

        if (seller.contractValidation && buyer.contractValidation) {
            changePhase(Phases.Paying);
        }
    }

    /***********************************************
     *  Phase.Paying
     */

    function updatePayment() public onlySellerOrBuyer onlyWhen(Phases.Paying) {
        emit Paid(msg.sender, euroToken.allowance(msg.sender, this));
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

        emit Signed(msg.sender, _signature);

        if (!_signature) cancel();
        else if (buyer.hasSigned && buyer.signature && seller.hasSigned && seller.signature) {
            changePhase(Phases.Calificating);
        }
    }

    /***********************************************
     *  Phase.Calificating
     */

    function calificate(bool _calification) public onlyRegistrar onlyWhen(Phases.Calificating) {
        calification = _calification;
        changePhase(Phases.Finished);
        if (_calification) {
            Property(property).resolvePurchase();
            euroToken.transferFrom(buyer.addr, seller.addr, buyer.debt);
        }
        emit Calificated(property, _calification, seller.addr, buyer.addr);
    }

    /***********************************************
     *  Auxiliar Functions
     */

    function isBuyer() internal view returns (bool) {return (msg.sender == buyer.addr);}
    function isSeller() internal view returns (bool) {return (msg.sender == seller.addr);}
    function isNotary() internal view returns (bool) {return (msg.sender == notary);}
    function isRegistrar() internal view returns (bool) {return (msg.sender == property.landRegistry().registrar());}

    /***********************************************
     *  Modifiers
     */

    modifier onlySellerOrBuyer() {require(isSeller() || isBuyer()); _;}
    modifier onlyBuyer() {require(isBuyer()); _;}
    modifier onlySeller() {require(isSeller()); _;}
    modifier onlyNotary() {require(isNotary()); _;}
    modifier onlyRegistrar() {require(isRegistrar()); _;}
    modifier onlyWhen(Phases strictPhase) {require(phase == strictPhase); _;}
    modifier onlyBefore(Phases beforePhase) {require(phase < beforePhase); _;}
    /***********************************************
    *  Info Getters
    */
    
    function getSeller() public view returns (address) {
        return seller.addr;
    }
    
    function getBuyer() public view returns (address) {
        return buyer.addr;
    }
    
    function getNotary() public view returns (address) {
        return notary;
    }
    
    function getRegistrar() public view returns (address) {
        return property.landRegistry().registrar();
    }
    
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

    function getContractSummary() public view returns (uint, string, bool, address, address, address) {
        return(
            uint(phase),
            contractHash,
            calification,
            whoCanceled,
            notary,
            property.landRegistry()
        );
    }
}