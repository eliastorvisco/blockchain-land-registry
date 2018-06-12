pragma solidity ^0.4.17;

import "./Property.sol";
import "./EuroToken.sol";
import "./PublicFinance.sol";

contract PurchaseAndSale {

    enum State { Joining, EarnestMoneyPayment, PurchaseAndSaleContractWritting, PurchaseAndSaleContractValidation, OutstandingPaymentsPayment, SignatureTime, QualififyingTime, Closed, Canceled }

    struct Signer {
        bool validated;
        bool signed;
        uint earnestMoneyPaid;
        uint totalDue;
        uint totalPaid;
        address[] paymentRecipients;
        mapping(address => uint) dueWith;
        bool canceled;    
    }
    Property public property;
    PublicFinance public publicFinance;
    EuroToken public euroToken;
    

    State public state;
    uint public price;
    uint public earnestMoney;
    string public purchaseAndSaleContractHash;
    bool public qualification;

    address public seller;
    address public buyer;
    mapping(address => Signer) public signer;

    address public notary;

    function PurchaseAndSale(address _property, address _buyer, uint _price, uint _earnestMoney) public onlyPropertyOwner(_property) {
        
        require(_price > _earnestMoney);

        property = Property(_property);
        publicFinance = property.landRegistry().publicFinance();
        euroToken = publicFinance.euroToken();

        state = State.Joining;
        price = _price;
        earnestMoney = _earnestMoney;

        seller = property.owner();
        buyer = _buyer;

        addOutstandingPayment(buyer, publicFinance, publicFinance.calculate("ITP", price));
        addOutstandingPayment(buyer, seller, price - earnestMoney);

    }
    
    // State Functions

    //Always

    function cancel() public onlySignerOrNotary onlyBefore(State.QualififyingTime) {

        if (state == State.EarnestMoneyPayment) {
            // Devolver lo pagado
            if (signer[buyer].earnestMoneyPaid > 0)
                euroToken.transfer(buyer, signer[buyer].earnestMoneyPaid);

            if (signer[seller].earnestMoneyPaid > 0)
                euroToken.transfer(seller, signer[seller].earnestMoneyPaid);

        } else {
            // Ya se ha pagado la paga y señal, la cancelación implica la perdida de este dinero
            if (isSeller(msg.sender))
                euroToken.transfer(buyer, 2 * earnestMoney);

            if (isBuyer(msg.sender))
                euroToken.transfer(seller, 2 * earnestMoney);

            if (state >= State.OutstandingPaymentsPayment) {
                // Puede que todavia no hayan pagado todo
                euroToken.transfer(buyer, signer[buyer].totalPaid);
                euroToken.transfer(seller, signer[seller].totalPaid);
            }
        }

        if (isSigner(msg.sender)) signer[msg.sender].canceled = true;
        changeState(State.Canceled);
        property.resolvePurchase();
    }

    // -- Joining
    function addNotary(address _notary) public onlyBuyer onlyWhen(State.Joining) {
        notary = _notary;
        changeState(State.EarnestMoneyPayment);
    }

    // -- EarnestMoneyPayment
    function payEarnestMoney() public onlySigners onlyWhen(State.EarnestMoneyPayment) {
        if (signer[msg.sender].earnestMoneyPaid == earnestMoney) revert(); //Already Paid
        uint allowed = euroToken.allowance(msg.sender, this);
        uint pending = earnestMoney - signer[msg.sender].earnestMoneyPaid;
        if (allowed >= pending) {
            euroToken.transferFrom(msg.sender, this, pending);
            signer[msg.sender].earnestMoneyPaid = signer[msg.sender].earnestMoneyPaid + pending;
        } else {
            euroToken.transferFrom(msg.sender, this, allowed);
            signer[msg.sender].earnestMoneyPaid = signer[msg.sender].earnestMoneyPaid + allowed;
        }

        if (signer[buyer].earnestMoneyPaid == earnestMoney && signer[seller].earnestMoneyPaid == earnestMoney) {
            changeState(State.PurchaseAndSaleContractWritting);
        }
    }

    // -- PurchaseAndSaleContractWritting

    function setPurchaseAndSaleContractHash(string _purchaseAndSaleContractHash) public onlyNotary onlyWhen(State.PurchaseAndSaleContractWritting) {
        require(bytes(_purchaseAndSaleContractHash).length > 0);
        purchaseAndSaleContractHash = _purchaseAndSaleContractHash;
        changeState(State.PurchaseAndSaleContractValidation);
    }

    // -- purchaseAndSaleContractValidation

    function validatePurchaseAndSaleContractHash(string _purchaseAndSaleContractHash) public onlySigners onlyWhen(State.PurchaseAndSaleContractValidation) {
        if (keccak256(bytes(purchaseAndSaleContractHash)) == keccak256(bytes(_purchaseAndSaleContractHash))) {
            signer[msg.sender].validated = true;
        }

        if (signer[seller].validated && signer[buyer].validated) {
            changeState(State.OutstandingPaymentsPayment);
        }
    }

    // -- OutstandingPaymentsPayment

    function payOutstandingPayments() public onlySigners onlyWhen(State.OutstandingPaymentsPayment) {
        if (signer[msg.sender].totalPaid == signer[msg.sender].totalDue) revert(); //Already Paid
        uint allowed = euroToken.allowance(msg.sender, this);
        uint pending = signer[msg.sender].totalDue - signer[msg.sender].totalPaid;
        if (allowed >= pending) {
            euroToken.transferFrom(msg.sender, this, pending);
            signer[msg.sender].totalPaid = signer[msg.sender].totalPaid + pending;
        } else {
            euroToken.transferFrom(msg.sender, this, allowed);
            signer[msg.sender].totalPaid = signer[msg.sender].totalPaid + allowed;
        }

        if (signer[buyer].totalPaid == signer[buyer].totalDue && signer[seller].totalPaid == signer[seller].totalDue) {
            changeState(State.SignatureTime);
        }
    }

    function sign() public onlySigners onlyWhen(State.SignatureTime) {
        if (signer[msg.sender].signed) revert(); // Already signed
        signer[msg.sender].signed = true;

        if(signer[seller].signed && signer[buyer].signed) {
            changeState(State.QualififyingTime);
        }
    }

    // -- QualififyingTime

    function qualify(bool _qualification) public onlyRegistrar onlyWhen(State.QualififyingTime) {
        qualification = _qualification;
        if (qualification) pay();
        else refund();

        changeState(State.Closed);
        property.resolvePurchase();
    }

    function pay() internal {
        address recipient;

        for (uint i = 0; i < signer[seller].paymentRecipients.length; i++) {
            recipient = signer[seller].paymentRecipients[i];
            euroToken.transfer(recipient, signer[seller].dueWith[recipient]);
        }

        for (i = 0; i < signer[buyer].paymentRecipients.length; i++) {
            recipient = signer[buyer].paymentRecipients[i];
            euroToken.transfer(recipient, signer[buyer].dueWith[recipient]);
        }

        euroToken.transfer(seller, 2 * earnestMoney);
    }

    function refund() internal {
        euroToken.transfer(seller, signer[seller].totalPaid);
        euroToken.transfer(buyer, signer[buyer].totalPaid);
        euroToken.transfer(seller, earnestMoney);
        euroToken.transfer(buyer, earnestMoney);
    }

    // Logics

    function addOutstandingPayment(address debtor, address paymentRecipient, uint outstandingPayment) internal {
        require(isSeller(debtor) || isBuyer(debtor)); 
        if (signer[debtor].dueWith[paymentRecipient] == 0) signer[debtor].paymentRecipients.push(paymentRecipient);
        signer[debtor].dueWith[paymentRecipient] = signer[debtor].dueWith[paymentRecipient] + outstandingPayment;
        signer[debtor].totalDue = signer[debtor].totalDue + outstandingPayment;
    }

    function changeState(State newState) internal {
        state = newState;
    }

    // Getters

    function getPurchaseAndSaleInfo() public view returns (
        address _property,
        address _publicFinance,
        address _euroToken,
        uint _state,
        uint _price,
        uint _earnestMoney,
        string _purchaseAndSaleContractHash,
        bool _qualification,
        address _seller,
        address _buyer,
        address _notary
    ) {
        return (
            property, 
            publicFinance,
            euroToken,
            uint(state),
            price,
            earnestMoney,
            purchaseAndSaleContractHash,
            qualification,
            seller,
            buyer,
            notary
        );
    }

    function getSignerInfo(address _signer) public view returns (
        bool _validated,
        bool _signed,
        uint _earnestMoneyPaid,
        uint _totalDue,
        uint _totalPaid,
        bool _canceled
    ) {
        return (
            signer[_signer].validated, 
            signer[_signer].signed, 
            signer[_signer].earnestMoneyPaid,
            signer[_signer].totalDue,
            signer[_signer].totalPaid,
            signer[_signer].canceled
        );
    }

    function getSignerPaymentRecipients(address _signer) public view returns (address[] _recipients) {
        return signer[_signer].paymentRecipients;
    }

    function getSignerDueWith(address _signer, address _recipient) public view returns (uint _due) {
        return signer[_signer].dueWith[_recipient];
    }

   

    // Auxiliar Functions

    function isSeller(address unknown) public view returns (bool) {return (unknown == seller);}
    function isBuyer(address unknown) public view returns (bool) {return (unknown == buyer);}
    function isNotary(address unknown) public view returns (bool) {return (unknown == notary);}
    function isRegistrar(address unknown) public view returns (bool) {return (unknown == property.landRegistry().registrar());}
    function isSigner(address unknown) public view returns (bool) {return (isSeller(msg.sender) || isBuyer(msg.sender));}

    function hasBeenCanceled() public view returns (bool) {return (state == State.Canceled);}
    function hasBeenQualified() public view returns (bool) {return (state == State.Closed);}


    // Modifiers
    modifier onlyPropertyOwner(address _property) {
        require(msg.sender == Property(_property).owner());
        _;
    }
    modifier onlySigners() {require(isSigner(msg.sender)); _;}
    modifier onlySignerOrNotary() {require(isSigner(msg.sender) || isNotary(msg.sender)); _;}
    modifier onlyBuyer() {require(isBuyer(msg.sender)); _;}
    modifier onlySeller() {require(isSeller(msg.sender)); _;}
    modifier onlyNotary() {require(isNotary(msg.sender)); _;}
    modifier onlyRegistrar() {require(isRegistrar(msg.sender)); _;}
    modifier onlyWhen(State requiredState) {require(state == requiredState); _;}
    modifier onlyBefore(State limitState) {require(state < limitState); _;}
}