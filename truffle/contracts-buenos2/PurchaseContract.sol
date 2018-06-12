pragma solidity ^0.4.17;

import "./Property.sol";
import "./EuroToken.sol";
import "./PublicFinance.sol";

contract PurchaseContract {
    // Property Info

    event PhaseChanged(uint oldPhase, uint newPhase);
    event Signed(address signer);
    event Paid(address from, uint paid);
    event Qualified(address property, bool qualification, address oldOwner, address newOwner);

    enum Phases { Join, SignalPayment, Writting, Validation, Paying, Signing, Calificating, Finished, Canceled }

    struct Debts {
        uint totalDebt;
        uint totalPaid;
        address[] destinataries;
        mapping(address => uint) debtWith;
    }

    struct SignerInfo {
        address addr;
        bool contractValidation;
        bool hasSigned;
        
    }

    EuroToken public euroToken;

    Phases public phase;

    Property public property;
    uint public price;  
    uint public paymentSignal;  
    string public contractHash;
    bool public qualification;

    SignerInfo public seller;
    SignerInfo public buyer;
    Debts public sellerDebts;
    Debts public buyerDebts;
    
    address public notary;

    address public canceller;


    function PurchaseContract(address _property, address _buyer, uint _price, uint _paymentSignal) public {
        require(Property(_property).owner() == msg.sender);

        property = Property(_property);
        price = _price;
        paymentSignal = _paymentSignal;
        euroToken = property.landRegistry().publicFinance().euroToken();

        seller.addr = property.owner();
        buyer.addr = _buyer;
        addBuyerDebt(seller.addr, price - paymentSignal);
        addBuyerDebt(property.landRegistry().publicFinance(), property.landRegistry().publicFinance().calculate("ITP", price));

    }

    function addSellerDebt(address destinatary, uint debt) internal {
        if (sellerDebts.debtWith[destinatary] == 0) sellerDebts.destinataries.push(destinatary);
        sellerDebts.debtWith[destinatary] = sellerDebts.debtWith[destinatary] + debt;
        sellerDebts.totalDebt = sellerDebts.totalDebt + debt;
    }

    function addBuyerDebt(address destinatary, uint debt) internal {
        if (buyerDebts.debtWith[destinatary] == 0) buyerDebts.destinataries.push(destinatary);
        buyerDebts.debtWith[destinatary] = buyerDebts.debtWith[destinatary] + debt;
        buyerDebts.totalDebt = buyerDebts.totalDebt + debt;
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

    function cancel() public onlyParticipantOrNotary onlyBefore(Phases.Calificating) {

        if (phase <= Phases.SignalPayment || isNotary()) {
            // Returns all the money
            refund();
        } else if (isBuyer()) {
            euroToken.transferFrom(buyer.addr, seller.addr, paymentSignal);
            refund();
        } else if (isSeller()) {
            euroToken.transferFrom(seller.addr, buyer.addr, paymentSignal);
            refund();
        }

        canceller = msg.sender;
        changePhase(Phases.Canceled);
        property.resolvePurchase();

    }

    /***********************************************
     *  Phase: Join
     */

    function addNotary(address _notary) public onlyWhen(Phases.Join) onlyBuyer {
        notary = _notary;
        changePhase(Phases.SignalPayment);
    }

    function checkSignalPayment() public onlyWhen(Phases.SignalPayment) onlySellerOrBuyer {
        if (euroToken.allowance(buyer.addr, this) >= paymentSignal && euroToken.allowance(seller.addr, this) >= paymentSignal) {
            
            changePhase(Phases.Writting);
            
        }
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
        
        if (euroToken.allowance(buyer.addr, this) >= (buyerDebts.totalDebt + paymentSignal) 
            && euroToken.allowance(seller.addr, this) >= (sellerDebts.totalDebt + paymentSignal)) {
            changePhase(Phases.Signing);
        }
    }

    /***********************************************
     *  Phase.Signing
     */

    function sign() public onlySellerOrBuyer onlyWhen(Phases.Signing) {
        
        if (isSeller()) {
            seller.hasSigned = true;
        } else if (isBuyer()) {
            require(!buyer.hasSigned);
            buyer.hasSigned = true;
        }

        emit Signed(msg.sender);

        if (buyer.hasSigned && seller.hasSigned) {
            changePhase(Phases.Calificating);
        }
    }

    /***********************************************
     *  Phase.Calificating
     */

    function qualify(bool _qualification) public onlyRegistrar onlyWhen(Phases.Calificating) {
        qualification = _qualification;
        
        if (qualification) pay();
        else refund();

        changePhase(Phases.Finished);
        property.resolvePurchase(); 
    }

    function refund() internal {
        euroToken.transferFrom(buyer.addr, buyer.addr, euroToken.allowance(buyer.addr, this));
        euroToken.transferFrom(seller.addr, seller.addr, euroToken.allowance(seller.addr, this));
    }

    function pay() internal {
        for(uint i = 0; i < buyerDebts.destinataries.length; i ++) {
            euroToken.transferFrom(buyer.addr, buyerDebts.destinataries[i], buyerDebts.debtWith[buyerDebts.destinataries[i]]);
        }
        euroToken.transferFrom(buyer.addr, seller.addr, paymentSignal);
        euroToken.transferFrom(buyer.addr, buyer.addr, euroToken.allowance(buyer.addr, this));

        for(i = 0; i < sellerDebts.destinataries.length; i ++) {
            euroToken.transferFrom(seller.addr, sellerDebts.destinataries[i], sellerDebts.debtWith[sellerDebts.destinataries[i]]);
        }
        euroToken.transferFrom(seller.addr, seller.addr, euroToken.allowance(seller.addr, this));
    }

    /***********************************************
     *  Auxiliar Functions
     */

    function isBuyer() internal view returns (bool) {return (msg.sender == buyer.addr);}
    function isSeller() internal view returns (bool) {return (msg.sender == seller.addr);}
    function isNotary() internal view returns (bool) {return (msg.sender == notary);}
    function isRegistrar() internal view returns (bool) {return (msg.sender == property.landRegistry().registrar());}
    function hasBeenCanceled() public view returns (bool) {return (phase == Phases.Canceled);}
    function hasBeenQualified() public view returns (bool) {return (phase == Phases.Finished);}

    /***********************************************
     *  Modifiers
     */

    modifier onlySellerOrBuyer() {require(isSeller() || isBuyer()); _;}
    modifier onlyParticipant() {require(isSeller() || isBuyer()); _;}
    modifier onlyParticipantOrNotary() {require(isSeller() || isBuyer() || isNotary()); _;}
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

    function getSellerInfo() public view returns (address addr, bool contractValidation, bool hasSigned) {
        return (
            seller.addr,
            seller.contractValidation,
            seller.hasSigned
        );
    }

    

    function getSellerDebtDestinataries() public view returns (address[] destinataries) {return sellerDebts.destinataries;}
    function getBuyerDebtDestinataries() public view returns (address[] destinataries) {return buyerDebts.destinataries;}

    function getSellerDebtWith(address destinatary) public view returns (uint) {return sellerDebts.debtWith[destinatary];} 
    function getBuyerDebtWith(address destinatary) public view returns (uint) {return buyerDebts.debtWith[destinatary];} 


    function getBuyerInfo() public view returns (address addr, bool contractValidation, bool hasSigned) {
        return (
            buyer.addr,
            buyer.contractValidation,
            buyer.hasSigned
        );
    }
    function getBuyerPaymentStatus() public view returns (uint totalPaid, uint totalDebt) {

        totalDebt = buyerDebts.totalDebt;

        if (phase <= Phases.SignalPayment && euroToken.allowance(buyer.addr, this) < paymentSignal) {
            totalPaid = 0;
        } else {
            totalPaid = euroToken.allowance(buyer.addr, this) - paymentSignal;
        }

        return(totalPaid, totalDebt);
    }

    function getSellerPaymentStatus() public view returns (uint totalPaid, uint totalDebt) {
        totalDebt = sellerDebts.totalDebt;

        if (phase == Phases.Join && euroToken.allowance(seller.addr, this) < paymentSignal) {
            totalPaid = 0;
        } else {
            totalPaid = euroToken.allowance(seller.addr, this) - paymentSignal;
        }

        return(totalPaid, totalDebt);
    }

    function getSellerSignalPayment() public view returns (uint signal, uint paid) {
        signal = paymentSignal;

        if (phase > Phases.SignalPayment) paid = signal;
        else paid = euroToken.allowance(seller.addr, this);

        return(signal, paid);
    }

    function getBuyerSignalPayment() public view returns (uint signal, uint paid) {
        signal = paymentSignal;

        if (phase > Phases.SignalPayment) paid = signal;
        else paid = euroToken.allowance(buyer.addr, this);
        
        return(signal, paid);
    }
}