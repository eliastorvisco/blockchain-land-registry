import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { Purchase } from '../../utils/Purchase';
import { PurchaseAndSale } from '../../utils/PurchaseAndSale';
import { ActivatedRoute } from '@angular/router';
import { Web3Service } from '../web3.service';
import CryptoJS from 'crypto-js';
import IPFS from 'ipfs-mini';


@Component({
  selector: 'app-purchase-contract',
  templateUrl: './purchase-contract.component.html',
  styleUrls: ['./purchase-contract.component.css']
})
export class PurchaseContractComponent implements OnInit {

  address:any;
  purchaseAndSale: PurchaseAndSale;

  // form notary
  fileReader: FileReader = new FileReader();
  fileToUpload: File = null;
  fileToUploadFromNotary: File = null;

  ipfs = new IPFS({host: 'ipfs.infura.io', port: 5001, protocol: 'https'});

  constructor(public router:Router, private route: ActivatedRoute, private web3Service: Web3Service) { }

  ngOnInit() {
    let address = this.route.snapshot.paramMap.get('address');
    this.address = address;
    this.updatePurchaseContract(address);


  }

  ngOnDestroy() {

  }

  async updatePurchaseContract(address = this.address) {
    this.purchaseAndSale = await this.web3Service.getPurchaseAndSaleContract(address);
    console.log(this.purchaseAndSale); 
  }

  addNotary(notary) {
    console.log(notary);
    this.web3Service.addNotary(this.address, notary);
  }
  
  async paySignal(quantity) {
    console.log('Introdujo: ', quantity);
    await this.web3Service.payEarnestMoney(this.address, parseInt(quantity));
    this.updatePurchaseContract();
  }


  handleFileInput(files: FileList) {
    this.fileToUpload = files.item(0);
    console.log(this.fileToUpload);
    // IPFS

    // let fileReader = new FileReader();
    // fileReader.onload = (event) => {
    //   var contents = event.target.result;
    //   console.log();
    //   this.ipfs.add(Buffer.from(contents), (err, hash) => {
    //     if (err) {
    //       return console.log(err);
    //     }
    //     console.log("HASH: ", hash);
    //    });
    // };
  
    // fileReader.onerror = function(event) {
    //     console.error("File could not be read! Code " + event.target.error.code);
    // };
  
    // fileReader.readAsArrayBuffer(this.fileToUpload); 
  }

  async setContract() {
    var reader = new FileReader();
    reader.onloadend = async () => {
      let hash = CryptoJS.SHA256(reader.result).toString(CryptoJS.enc.Hex);
      console.log(hash);
      await this.web3Service.setPurchaseAndSaleContractHash(this.address, hash);
      this.updatePurchaseContract();
    }
    reader.readAsBinaryString(this.fileToUpload);
    
    
  }

  async validateContract() {
    var reader = new FileReader();
    reader.onloadend = async () => {
      let hash = CryptoJS.SHA256(reader.result).toString(CryptoJS.enc.Hex);
      console.log(hash);
      await this.web3Service.validatePurchaseAndSaleContractHash(this.address, hash);
      this.updatePurchaseContract();
    }
    reader.readAsBinaryString(this.fileToUpload);
    
  }

  async pay(quantity) {
    await this.web3Service.payOutstandingPayments(this.address, parseInt(quantity));
    this.updatePurchaseContract();
  }

  sign() {
    console.log('Signed!');
  }

}
