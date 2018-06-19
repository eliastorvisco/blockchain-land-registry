export class IPFSDocument {
    address:any;
    ipfsHash:string;
    documentHash:string;
    creator:any;

    constructor(address, ipfsHash, documentHash, creator) {
        this.address = address;
        this.ipfsHash = ipfsHash;
        this.documentHash = documentHash;
        this.creator = creator;
    }
}