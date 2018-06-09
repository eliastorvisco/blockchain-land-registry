export class Property {
    IDUFIR:any;
    CRU:any;
    address:any;
    description:any;
    owner:any
    landRegistry:any;
    purchaseContract:any;

    constructor(IDUFIR, CRU, address, description, owner, landRegistry, purchaseContract) {
        this.IDUFIR = IDUFIR;
        this.CRU = CRU;
        this.address = address;
        this.description = description;
        this.owner = owner;
        this.landRegistry = landRegistry;
        this.purchaseContract = purchaseContract;
    }
}