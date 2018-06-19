import { Component, OnInit, OnDestroy } from '@angular/core';
import { Web3Service } from '../web3.service';
import IPFS from 'ipfs-api';
import CryptoJS from 'crypto-js';
import { IPFSDocument } from '../../utils/IPFSDocument';

@Component({
  selector: 'app-registry-books',
  templateUrl: './registry-books.component.html',
  styleUrls: ['./registry-books.component.css']
})
export class RegistryBooksComponent implements OnInit {

  openedBook:number = 0;

  event:any;
  inscriptionEntries:InscriptionEntry[] = [];
  presentationEntries:PresentationEntry[] = [];
  newEntryNav:number = 0;
  fileToUpload: File = null;
  ipfs = new IPFS({host: 'ipfs.infura.io', port: 5001, protocol: 'https'});

  web3StatusSubscription:any;

  constructor(private web3Service: Web3Service) { }


  ngOnInit() {
    this.web3StatusSubscription = this.web3Service.ready.subscribe(
      ready => {if(ready) {console.log("WEB3 is now ready for Registry Book"); this.openBook(0);}},
      err => {console.log(err);}
    ); 
  }

  ngOnDestroy() {
    this.web3StatusSubscription.unsubscribe();
  }

  openBook(book) {
    this.openedBook = book;
    if (book == 0) this.listenDiaryBookEvent({}, {fromBlock: 0});
    else if (book == 1) this.listenInscriptionBookEvent({}, {fromBlock: 0});
  }

  filterInscriptions(property, type, id) {
    let filters = { property: property, inscriptionType: type, identifier: id };
    if (property == "") delete filters.property;
    if (type == -1) delete filters.inscriptionType;
    if (id == "") delete filters.identifier;
    this.listenInscriptionBookEvent(filters, {fromBlock: 0});
  }

  filterPresentations(property, id) {
    let filters = { property: property, identifier: id };
    if (property == "") delete filters.property;
    if (id == "") delete filters.identifier;
    this.listenDiaryBookEvent(filters, {fromBlock: 0});
  }
  
  filter(IDUFIR, CRU, property) {
    let filters = {
      IDUFIR: IDUFIR,
      CRU: CRU,
      property:property
    }
    if (IDUFIR == "") delete filters.IDUFIR;
    if (CRU == "") delete filters.CRU;
    if (property == "") delete filters.property;

    if(this.openedBook = 1) this.listenInscriptionBookEvent(filters, {fromBlock: 0});
  } 

  listenInscriptionBookEvent(filters, options) {
    this.inscriptionEntries = [];
    this.event = this.web3Service.getInscriptionBookEvent(filters, options);
    this.event.watch(async (err, res) => {
      if (err) {console.error('Could not retrieve an inscription entry.'); return;}
      let entry = res.args;
      console.log('New Inscription Document: ', await this.web3Service.getIPFSDocument(entry.document));
      this.inscriptionEntries.push(new InscriptionEntry(
        entry.identifier,
        entry.inscriptionType,
        entry.property,
        await this.web3Service.getIPFSDocument(entry.document),
        entry.registrar
      ));
    });
  }

  listenDiaryBookEvent(filters, options) {
    this.presentationEntries = [];
    this.event = this.web3Service.getDiaryBookEvent(filters, options);
    this.event.watch(async (err, res) => {
      if (err) {console.error('Could not retrieve an inscription entry.'); return;}
      let entry = res.args;
      console.log('Nueva Presentacion!');
      this.presentationEntries.push(new PresentationEntry(
        entry.identifier, 
        await this.web3Service.getIPFSDocument(entry.document), 
        entry.registrar
      ));
    })
  }

  openNewEntryNav(nav) {
    this.newEntryNav = nav;
  }

  handleFileInput(files: FileList) {
    this.fileToUpload = files.item(0);
    console.log(this.fileToUpload);
  }

  newInscriptionEntry(property, type, id) {
    let fileReader = new FileReader();
    fileReader.onload = (event) => {
      let contents:string = fileReader.result;
      this.ipfs.files.add(Buffer.from(contents), async (err, result) => {
        if (err) {console.log(err); return;}
        let hash = CryptoJS.SHA256(contents).toString(CryptoJS.enc.Hex);
        console.log('Hash: ', hash);
        console.log('IPFS: ', result[0].hash);
        let document = await this.web3Service.newDocument(result[0].hash, hash);
        console.log('Document Address:', document.address);
        this.web3Service.registerInscriptionEntry(id, type, property, document.address);

      })
    };

    fileReader.onerror = function(event) {
        let error:any = fileReader.error;
        console.error("File could not be read! Code " + error.code);
    };
  
    fileReader.readAsArrayBuffer(this.fileToUpload); 
  }



  newPresentationEntry(id) {
    let fileReader = new FileReader();
    fileReader.onload = (event) => {
      let contents:string = fileReader.result;
      this.ipfs.add(Buffer.from(contents), async (err, result) => {
        if (err) {console.log(err); return;}
        let hash = CryptoJS.SHA256(contents).toString(CryptoJS.enc.Hex);
        console.log('Hash: ', hash);
        console.log('IPFS: ', result[0].hash);
        let document = await this.web3Service.newDocument(result[0].hash, hash);
        this.web3Service.registerPresentationEntry(id, document.address);

      })
    };
    fileReader.onerror = function(event) {
        let error:any = fileReader.error;
        console.error("File could not be read! Code " + error.code);
    };
    fileReader.readAsArrayBuffer(this.fileToUpload); 
  }

}

class InscriptionEntry {
  identifier:any;
  type:any;
  property:any;
  document:IPFSDocument;
  registrar:any;

  constructor(identifier, type, property, document, registrar) {
    this.identifier = identifier;
    this.type = type;
    this.property = property;
    this.document = document;
    this.registrar = registrar;
  }
}

class PresentationEntry {
  identifier:any;
  document:IPFSDocument;
  registrar:any;

  constructor(identifier, document, registrar) {
    this.identifier = identifier;
    this.document = document;
    this.registrar = registrar;
  }

}


