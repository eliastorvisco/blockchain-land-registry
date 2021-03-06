pragma solidity ^0.4.17;

import "./Property.sol";
import "./EuroToken.sol";
import "./PublicFinance.sol";

/// @title Purchase And Sale
/// @author Elias Torvisco
/// @notice Purchase and sale contract that will allow a property owner to transfer their property to a buyer
/// and register the property into the Land Registry with the new owner.
/// @dev All function calls are currently implement without side effects
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
    
    /// @dev Cancelation function
    /// @notice Used to cancel the purchase and sale. Its behaviour will be 
    /// different depending on the state of the contract.
    function cancel() public onlySignerOrNotary onlyBefore(State.QualififyingTime) {

        if (state == State.EarnestMoneyPayment) {
            // Refund earnest money paid
            if (signer[buyer].earnestMoneyPaid > 0)
                euroToken.transfer(buyer, signer[buyer].earnestMoneyPaid);

            if (signer[seller].earnestMoneyPaid > 0)
                euroToken.transfer(seller, signer[seller].earnestMoneyPaid);

        } else {
            if (isSeller(msg.sender))
                euroToken.transfer(buyer, 2 * earnestMoney);

            if (isBuyer(msg.sender))
                euroToken.transfer(seller, 2 * earnestMoney);

            if (isNotary(msg.sender)) {
                euroToken.transfer(buyer, earnestMoney);
                euroToken.transfer(seller, earnestMoney);
            }
                
            if (state >= State.OutstandingPaymentsPayment) {
                euroToken.transfer(buyer, signer[buyer].totalPaid);
                euroToken.transfer(seller, signer[seller].totalPaid);
            }
        }

        if (isSigner(msg.sender)) signer[msg.sender].canceled = true;
        changeState(State.Canceled);
        property.resolvePurchase();
    }

    /// @dev Joining state function.

    /// @notice Adds a notary to the purchase and sale contract. 
    /// When done, the state of the contract will change.
    /// @param _notary The address of the notary that will guide the negotiation.
    /// @dev Only the buyer can add a notary.
    function addNotary(address _notary) public onlyBuyer onlyWhen(State.Joining) {
        notary = _notary;
        changeState(State.EarnestMoneyPayment);
    }

    /// @dev EarnestMoneyPayment state funciton.

    /// @notice Function used to pay the earnest money.
    /// When both buyer and seller have paid the state of the contract will change.
    /// @dev The payment must be done earlier to this contract address through
    /// the Euro Token specified in the Public Finance contract. 
    /// @dev The function is restricted to the signers. No one else should pay the earnest signal.
    /// @dev It will revert if the caller has already paid.
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

    /// @dev PurchaseAndSaleContractWritting state function

    /// @notice Links the real purchase and sale contract to this smart contract 
    /// through the hash of the physical document.
    /// @param _purchaseAndSaleContract The hash of the physical purchase contract
    function setPurchaseAndSaleContractHash(string _purchaseAndSaleContractHash) public onlyNotary onlyWhen(State.PurchaseAndSaleContractWritting) {
        require(bytes(_purchaseAndSaleContractHash).length > 0);
        purchaseAndSaleContractHash = _purchaseAndSaleContractHash;
        changeState(State.PurchaseAndSaleContractValidation);
    }

    /// @dev PurchaseAndSaleContractValidation state function

    /// @notice Signers should validate the contract hash specified by the notary. 
    /// @param _purchaseAndSaleContractHash The hash of the physical purchase contract
    function validatePurchaseAndSaleContractHash(string _purchaseAndSaleContractHash) public onlySigners onlyWhen(State.PurchaseAndSaleContractValidation) {
        if (keccak256(bytes(purchaseAndSaleContractHash)) == keccak256(bytes(_purchaseAndSaleContractHash))) {
            signer[msg.sender].validated = true;
        }

        if (signer[seller].validated && signer[buyer].validated) {
            changeState(State.OutstandingPaymentsPayment);
        }
    }

    /// @dev OutstandingPaymentsPayment state function

    /// @notice Used to pay both seller or buyers debts.
    /// As soon as all payments have been made, the state 
    /// of the contract will change.
    /// @dev The function is restricted to the signers.
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

    /// @dev SignatureTime state function

    /// @notice Used to pay both seller or buyers debts.
    /// As soon as all payments have been made, the state 
    /// of the contract will change.
    /// @dev The function is restricted to the signers.
    function sign() public onlySigners onlyWhen(State.SignatureTime) {
        if (signer[msg.sender].signed) revert(); // Already signed
        signer[msg.sender].signed = true;

        if(signer[seller].signed && signer[buyer].signed) {
            changeState(State.QualififyingTime);
        }
    }

    /// @dev QualificationTime state function

    /// @notice Allows the registrar to qualify the sale.
    /// @dev The function is restricted to the registrar
    function qualify(bool _qualification) public onlyRegistrar onlyWhen(State.QualififyingTime) {
        qualification = _qualification;
        if (qualification) pay();
        else refund();

        changeState(State.Closed);
        property.resolvePurchase();
    }

    /// @dev Internal funtion
    /// @notice Used in case the registrar's qualification is positive.
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

    /// @dev Internal funtion
    /// @notice Used in case the registrar's qualification is negative.
    function refund() internal {
        euroToken.transfer(seller, signer[seller].totalPaid);
        euroToken.transfer(buyer, signer[buyer].totalPaid);
        euroToken.transfer(seller, earnestMoney);
        euroToken.transfer(buyer, earnestMoney);
    }

    /// @notice Adds an outstanding payment to a debtor
    function addOutstandingPayment(address debtor, address paymentRecipient, uint outstandingPayment) internal {
        require(isSeller(debtor) || isBuyer(debtor)); 
        if (signer[debtor].dueWith[paymentRecipient] == 0) signer[debtor].paymentRecipients.push(paymentRecipient);
        signer[debtor].dueWith[paymentRecipient] = signer[debtor].dueWith[paymentRecipient] + outstandingPayment;
        signer[debtor].totalDue = signer[debtor].totalDue + outstandingPayment;
    }

    /// @notice Changes the contract state
    /// @dev Can't be called from outside the contract
    function changeState(State newState) internal {
        state = newState;
    }

    /// @notice Returns basic contract information
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

    /// @notice Returns basic signer information
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

    /// @notice Returns a list of the beneficiaries of the outstanding payments from the signer indicated.
    function getSignerPaymentRecipients(address _signer) public view returns (address[] _recipients) {
        return signer[_signer].paymentRecipients;
    }

    /// @notice Returns the signer's debt to the specified recipient.
    function getSignerDueWith(address _signer, address _recipient) public view returns (uint _due) {
        return signer[_signer].dueWith[_recipient];
    }

   
    /**
     *  Auxiliar Functions
     */

    function isSeller(address unknown) public view returns (bool) {return (unknown == seller);}
    function isBuyer(address unknown) public view returns (bool) {return (unknown == buyer);}
    function isNotary(address unknown) public view returns (bool) {return (unknown == notary);}
    function isRegistrar(address unknown) public view returns (bool) {return (unknown == property.landRegistry().registrar());}
    function isSigner(address unknown) public view returns (bool) {return (isSeller(msg.sender) || isBuyer(msg.sender));}

    function hasBeenCanceled() public view returns (bool) {return (state == State.Canceled);}
    function hasBeenQualified() public view returns (bool) {return (state == State.Closed);}


    /**
     *  Permission Modifiers
     */

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