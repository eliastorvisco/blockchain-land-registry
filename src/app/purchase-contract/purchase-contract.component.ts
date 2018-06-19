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

  state:string[] = [
    'Inicialización',
    'Paga y señal',
    'Redacción del contrato de compraventa',
    'Validación del contrato de compraventa',
    'Pago de la vivienda e impuestos',
    'Firma',
    'Calificación',
    'Contrato concluído',
    'Cancelación'
  ];

  stateDescription:string[] = [
    'El comprador deberá invitar a un notario, de su elección, para proseguir con la compraventa',
    'Tanto comprador como vendedor deberán depositar una cantidad igual a la paga y señal fijada a la cuenta del contrato de compraventa',
    'El notario deberá redactar el contrato de compraventa y subir un código único e identificativo del mismo a la blockchain', 
    'Comprador y vendedor deberán validar el documento físico del contrato de compraventa a través de la copia del mismo que les haya proporcionado el notario',
    'Comprador y vendedor deberán abonar las cantidades indicadas en la cuenta ethereum del contrato de compraventa',
    'Comprador y vendedor deberán firmar para proceder con la tramitación de la compraventa. La firma del contrato supondrá la renuncia a la cancelación del mismo.',
    'El registrador asignado al Registro de la Propiedad donde se inscribió la finca deberá calificar el contrato de compraventa.',
    '',
    'El contrato de compraventa ha sido cancelado.'
  ]

  cancelationWarning:string[] = [
    'La cancelación puede realizarse tanto por el comprador y vendedor como por el notario. Cualquier pago realizado será devuelto.',
    'En el caso de que la cancelación se realice por parte del comprador o del vendedor, éste perderá la paga y señal y se devolverá las otras cantidades abonadas. En el caso de que quién cancele sea el notario se abonara la totalidad de los pagos realizados, incluidos la paga y señal.'
  ]

  // form notary
  fileToUpload: File = null;

  ipfs = new IPFS({host: 'ipfs.infura.io', port: 5001, protocol: 'https'});

  nav: number = 0;

  constructor(public router:Router, private route: ActivatedRoute, private web3Service: Web3Service) { }

  ngOnInit() {
    let address = this.route.snapshot.paramMap.get('address');
    this.address = address;
    this.updatePurchaseContract(address);
  }

  ngOnDestroy() {

  }

  navigate(nav) {
    this.nav = nav;
  }

  getNameFromAccount(address):string {
    if(this.purchaseAndSale == undefined) return "";
    if (address == this.purchaseAndSale.buyer) return "Comprador";
    else if (address == this.purchaseAndSale.seller) return "Vendedor";
    else if (address == this.purchaseAndSale.notary) return "Notario";
    else if (address == this.purchaseAndSale.publicFinance) return "Hacienda";

  }

  isState(state): boolean {
    return (this.purchaseAndSale != undefined && this.purchaseAndSale.state == state);
  }

  async updatePurchaseContract(address = this.address) {
    this.purchaseAndSale = await this.web3Service.getPurchaseAndSaleContract(address);
    console.log(this.purchaseAndSale); 
  }

  async addNotary(notary) {
    console.log(notary);
    await this.web3Service.addNotary(this.address, notary);
    this.updatePurchaseContract();
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

  async sign() {
    console.log('Signed!');
    await this.web3Service.sign(this.address);
    this.updatePurchaseContract();
  }

  async cancel() {
    console.log('Canceling...');
    await this.web3Service.cancel(this.address);
    this.updatePurchaseContract();
    this.nav = 0;
  }

  async qualify(qualification) {
    console.log('Qualifying...');
    console.log(qualification);
    await this.web3Service.qualify(this.address, qualification);
    this.updatePurchaseContract();
  }

}
