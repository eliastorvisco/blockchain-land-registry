export class PurchaseAndSale {
    property:any;
    publicFinance: any;
    euroToken: any;

    state:any;
    price:any;
    earnestMoney:any;
    purchaseAndSaleContractHash:any;
    qualification:any;

    seller:any;
    buyer:any;
    notary:any;

    buyerInfo:SignerInfo;
    sellerInfo:SignerInfo;


    constructor(property, publicFinance, euroToken, state, price, earnestMoney, purchaseAndSaleContractHash, qualification, seller, buyer, notary) {
        this.property = property;
        this.publicFinance = publicFinance;
        this.euroToken = euroToken;
        this.state = state;
        this.price = price;
        this.earnestMoney = earnestMoney;
        this.purchaseAndSaleContractHash = purchaseAndSaleContractHash;
        this.qualification = qualification;
        this.seller = seller;
        this.buyer = buyer;
        this.notary = notary;
        
    }

    setBuyerInfo(validated, signed, earnestMoneyPaid, totalDue, totalPaid, paymentRecipients, debts, canceled) {
        this.buyerInfo = new SignerInfo(validated, signed, earnestMoneyPaid, totalDue, totalPaid, paymentRecipients, debts, canceled);
    }

    setSellerInfo(validated, signed, earnestMoneyPaid, totalDue, totalPaid, paymentRecipients, debts, canceled) {
        this.sellerInfo = new SignerInfo(validated, signed, earnestMoneyPaid, totalDue, totalPaid, paymentRecipients, debts, canceled);
    }
}

class SignerInfo {
    validated:boolean;
    signed:boolean;
    earnestMoneyPaid:number;
    totalDue:number;
    totalPaid:number;
    paymentRecipients:any[] = [];
    debts:any[] = [];
    canceled: boolean;

    constructor(validated, signed, earnestMoneyPaid, totalDue, totalPaid, canceled, paymentRecipients, debts) {
        this.validated = validated;
        this.signed = signed;
        this.earnestMoneyPaid = earnestMoneyPaid;
        this.totalDue = totalDue;
        this.totalPaid = totalPaid;
        this.paymentRecipients = paymentRecipients;
        this.debts = debts;
        this.canceled = canceled;
    }
}