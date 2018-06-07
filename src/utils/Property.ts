export class Property {
    IDUFIR:any;
    CRU:any;
    address:any;
    description:any;
    owner:any

    constructor(IDUFIR, CRU, address, description, owner) {
        this.IDUFIR = IDUFIR;
        this.CRU = CRU;
        this.address = address;
        this.description = description;
        this.owner = owner;
    }
}