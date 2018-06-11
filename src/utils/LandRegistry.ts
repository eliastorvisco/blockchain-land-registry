export class LandRegistry {
    address: any;
    name: string;
    street: string; // Street - Town [Postcode]
    province: string;
    telephone: string;
    fax: string;
    email: string;
    registrar: any;

    constructor(address, name, street, province, telephone, fax, email, registrar) {
        this.address = address;
        this.name = name;
        this.street = street;
        this.province = province;
        this.telephone = telephone;
        this.fax = fax;
        this.email = email;
        this.registrar = registrar;
    }
}