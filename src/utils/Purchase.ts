import { Property } from './Property';
import { LandRegistry } from './LandRegistry';

export class Purchase {

    address:any; //
    phase:any;
    property:Property; //
    price:any; //
    paymentSignal:any;//
    qualification:boolean;//
    contractHash:any;//
    
    seller:Participant;//
    buyer:Participant;//
    

    canceller:any;//
    
    notary:any;//
    
    

    constructor(address, property, price) {
       this.address = address; 
       this.phase = 0;
       this.price = price;
    }

    setPhase(phase) {this.phase = phase;}
    setHash(hash) {this.contractHash = hash;}
    setQualification(qualification) {this.qualification = qualification;}
    setCanceller(canceller) {this.canceller = canceller;}
    setNotary(notary) {this.notary = notary;}
    setPaymentSignal(paymentSignal) {this.paymentSignal = paymentSignal;}
    setBuyer(address, validation, signature) {
        this.buyer = new Participant(address, validation, signature);
    }
    setSeller(address, validation, signature) {
        this.seller = new Participant(address, validation, signature);
    }
    setBuyerPaid(totalPaid, totalDebts) {
        this.buyer.setPaid(totalPaid, totalDebts);
    }

    setBuyerDebts(destinataries, debts) {
        this.buyer.setDebts(destinataries, debts);
    }
    setSellerPaid(totalPaid, totalDebts) {
        this.seller.setPaid(totalPaid, totalDebts);
    }

    setSellerDebts(destinataries, debts) {
        this.seller.setDebts(destinataries, debts);
    }
}

class Participant {
    address:any;
    validation:boolean;
    signature:boolean;

    totalDebts:any;
    totalPaid:any;
    debts: Debt[];


    constructor(address, validation, signature) {
        this.address = address;
        this.validation = validation;
        this.signature = signature;
    }

    setPaid(totalPaid, totalDebts) {
        this.totalPaid = totalPaid;
        this.totalDebts = totalDebts;
    }

    setDebts(destinataries, debts) {
        let tmp: Debt[] = [];
        for(let i = 0; i < destinataries.length; i ++) {
            tmp.push(new Debt(destinataries[i], debts[i]))
        }
    }
}

class Debt {
    destinatary:any;
    debt:any;

    constructor(destinatary, debt) {
        this.destinatary;
        this.debt;
    }

}