import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { Purchase } from '../../utils/Purchase';
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

  purchaseContract: Purchase;

  // form notary
  fileReader: FileReader = new FileReader();
  fileToUpload: File = null;
  ipfs = new IPFS({host: 'ipfs.infura.io', port: 5001, protocol: 'https'});

  constructor(public router:Router, private route: ActivatedRoute, private web3Service: Web3Service) { }

  ngOnInit() {
    let address = this.route.snapshot.paramMap.get('address');
    this.updatePurchaseContract(address);


  }

  ngOnDestroy() {

  }

  async updatePurchaseContract(address = this.purchaseContract.address) {
    this.purchaseContract = await this.web3Service.getPurchaseContract(address);
    console.log(this.purchaseContract); 
  }

  addNotary(notary) {
    console.log(notary);
  }

  handleFileInput(files: FileList) {
    this.fileToUpload = files.item(0);
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

  setContract() {
    let hash = CryptoJS.SHA256(this.fileToUpload).toString(CryptoJS.enc.Hex);
    console.log(hash);
  }

  validateContract() {
    let hash = CryptoJS.SHA256(this.fileToUpload).toString(CryptoJS.enc.Hex);
    console.log(hash);
  }

  pay(payment) {
    console.log(payment);
  }

  sign() {
    console.log('Signed!');
  }

}
