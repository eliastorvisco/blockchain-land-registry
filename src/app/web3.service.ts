import { Injectable, OnInit } from '@angular/core';
import { Account } from '../utils/account';
import { User } from '../utils/User';
import { Property } from '../utils/Property';
import { LandRegistry } from '../utils/LandRegistry';
import { Purchase } from '../utils/Purchase';
import { IPFSDocument } from '../utils/IPFSDocument'; 
import { PurchaseAndSale } from '../utils/PurchaseAndSale';
import { BehaviorSubject, Observable } from 'rxjs';

const Web3 = require('web3');
const contract = require('truffle-contract');

const landRegistryArtifacts = require('../../truffle/build/contracts/LandRegistry.json');
const euroTokenBankingArtifacts = require('../../truffle/build/contracts/EuroTokenBanking.json');
const euroTokenArtifacts = require('../../truffle/build/contracts/EuroToken.json');
const propertyArtifacts = require('../../truffle/build/contracts/Property.json');
const purchaseContractArtifacts = require('../../truffle/build/contracts/PurchaseContract.json');
const publicFinanceArtifacts = require('../../truffle/build/contracts/PublicFinance.json');
const purchaseAndSaleArtifacts = require('../../truffle/build/contracts/PurchaseAndSale.json');
const documentArtifacts = require('../../truffle/build/contracts/Document.json');

@Injectable({
  providedIn: 'root'
})

export class Web3Service implements OnInit {

  LandRegistryContract = contract(landRegistryArtifacts);
  EuroTokenBanking = contract(euroTokenBankingArtifacts);
  EuroToken = contract(euroTokenArtifacts);
  PropertyContract = contract(propertyArtifacts);
  PurchaseContract = contract(purchaseContractArtifacts);
  PurchaseAndSaleContract = contract(purchaseAndSaleArtifacts);
  PublicFinance = contract(publicFinanceArtifacts);
  DocumentContract = contract(documentArtifacts);

  web3: any;
  accounts: Account[] = [];

  manager: User;
  seller: User;
  buyer: User;
  notary: User;
  registrar: User;

  readySource = new BehaviorSubject<boolean>(false);
  ready = this.readySource.asObservable();

  selectedUserSource = new BehaviorSubject<User>(new User('','',''));
  selectedUser = this.selectedUserSource.asObservable();
  // Contract Instances
  publicFinance: any;
  landRegistry: any;
  euroTokenBanking: any;
  euroToken: any;

  properties: Property[] = [];

  constructor() {
    this.setWeb3();
    this.setProviders();
    this.setAccounts();

  }

  ngOnInit() {
    
  }

  /***************************************
   * Initialization Methods
   */

  
  setWeb3() {
    if (typeof this.web3 !== 'undefined') {
      this.web3 = new Web3(this.web3.currentProvider);
    } else {
      this.web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:7545'));
    }  
  }

  setProviders() {
    Web3.providers.HttpProvider.prototype.sendAsync = Web3.providers.HttpProvider.prototype.send;
    this.LandRegistryContract.setProvider(this.web3.currentProvider);
    this.LandRegistryContract.defaults({
      gas: 6721975,
      gasPrice: 20000000000
    });
    this.EuroTokenBanking.setProvider(this.web3.currentProvider);
    this.EuroTokenBanking.defaults({
      gas: 6721975,
      gasPrice: 20000000000
    });
    this.EuroToken.setProvider(this.web3.currentProvider);
    this.EuroToken.defaults({
      gas: 6721975,
      gasPrice: 20000000000
    });
    this.PropertyContract.setProvider(this.web3.currentProvider);
    this.PropertyContract.defaults({
      gas: 6721975,
      gasPrice: 20000000000
    });
    this.PurchaseContract.setProvider(this.web3.currentProvider);
    this.PurchaseContract.defaults({
      gas: 6721975,
      gasPrice: 20000000000
    });
    this.PublicFinance.setProvider(this.web3.currentProvider);
    this.PublicFinance.defaults({
      gas: 6721975,
      gasPrice: 20000000000
    });
    this.PurchaseAndSaleContract.setProvider(this.web3.currentProvider);
    this.PurchaseAndSaleContract.defaults({
      gas: 6721975,
      gasPrice: 20000000000
    });
    this.DocumentContract.setProvider(this.web3.currentProvider);
    this.DocumentContract.defaults({
      gas: 6721975,
      gasPrice: 20000000000
    });
  }

  async setAccounts() {
    const res =  await this.web3.eth.getAccounts();
    for (let acc of res) {
      let balance = await this.web3.eth.getBalance(acc);
      let newAccount = new Account(acc, this.web3.utils.fromWei(balance.toString()));
      this.updateAccounts(newAccount);
    }
    this.setUsers();
  }

  async setUsers() {
    this.manager = new User('Manager', this.accounts[0].address, this.accounts[0].balance);
    this.seller = new User('Seller', this.accounts[1].address, this.accounts[1].balance);
    this.buyer = new User('Buyer', this.accounts[2].address, this.accounts[2].balance);
    this.notary = new User('Notary', this.accounts[3].address, this.accounts[3].balance);
    this.registrar = new User('Registrar', this.accounts[4].address, this.accounts[4].balance);
    this.selectUser('seller');
    this.setContracts();
  }
 
  async setContracts() {
    
    this.euroTokenBanking = await this.EuroTokenBanking.new({from: this.manager.address});
    // await this.euroTokenBanking.cashIn(this.seller.address, 2000000000, {from: this.manager.address});
    // await this.euroTokenBanking.cashIn(this.buyer.address, 2000000000, {from: this.manager.address});
    this.euroToken = await this.EuroToken.at(
      await this.euroTokenBanking.euroToken.call({from: this.manager.address})
    , {from: this.manager.address});

    this.publicFinance = await this.PublicFinance.new({from: this.manager.address});
    await this.publicFinance.setEuroToken(this.euroToken.address, {from: this.manager.address});
    await this.publicFinance.addTax("ITP", 6, {from: this.manager.address});
    
    this.landRegistry = await this.LandRegistryContract.new(
      'Hospitalet de Llobregat, L\' Nº 02',
      'Sevilla, 11-13,2º-2ª - Cornella de Llobregat [08940]',
      'Barcelona',
      '(93)475 26 86',
      '(93)475 26 86',
      'hospitalet2registrodelapropiedad.org'
    , {from: this.manager.address});
    
    await this.landRegistry.setRegistrar(this.registrar.address, {from: this.manager.address});
    await this.landRegistry.setPublicFinance(this.publicFinance.address, {from: this.manager.address});

    this.readySource.next(true);
  }



  updateAccounts(account: Account, modify = false) {
    if (modify) {
      this.accounts.forEach((item, index) => {
        if (item.address == account.address) {
          this.accounts[index] = account;
        }
      });
    } else {
      this.accounts.push(account);
    }

  }

  selectUser(newUser) {
    switch(newUser) {
      case 'seller':
        this.selectedUserSource.next(this.seller);
        break;
      case 'buyer':
        this.selectedUserSource.next(this.buyer);
        break;
      case 'notary': 
        this.selectedUserSource.next(this.notary);
        break;
      case 'registrar': 
        this.selectedUserSource.next(this.registrar);
        break;
    }
    console.log('User selected: ', newUser, 'Account: ', this.selectedUserSource.value.address);
  }

  // Events

  getPropertyRegistrationEvent(filters, options): any {
    return this.landRegistry.PropertyRegistration(filters, options);
  }

  getDiaryBookEvent(filters, options): any {
    return this.landRegistry.DiaryBook(filters, options);
  }

  getInscriptionBookEvent(filters, options): any {
    return this.landRegistry.InscriptionBook(filters, options);
  }

  async listenPropertyRegistrations() {
    let event = this.landRegistry.PropertyRegistration({}, {fromBlock: 0});
    event.watch(async (err, res) => {
      if (err) {
        console.log(err);
        return;
      } 
      this.properties.push(await this.getProperty(res.args.property));
    })
  }

  //Banking
  async getEuroTokenBalance(address = this.selectedUserSource.value.address, caller = this.selectedUserSource.value.address):Promise<number> {
    try {
      let number = await this.euroToken.balanceOf(address, {from: caller});
      return number;
    } catch (err) {
      return 0;
    }
  }

  async cashIn(address = this.selectedUserSource.value.address, quantity): Promise<boolean> {
    try {
      console.log('Cashing in: ', quantity);
      await this.euroTokenBanking.cashIn(address, quantity, {from: this.manager.address});
      return true;
    } catch (err) {
      return false;
    }
    
  }

  async newDocument(ipfsHash, documentHash, caller = this.selectedUserSource.value.address): Promise<IPFSDocument> {
    let document = await this.DocumentContract.new(ipfsHash, documentHash, {from: caller});
    let ipfsDocument = new IPFSDocument(
      document.address,
      await document.ipfsHash.call({from: caller}),
      await document.documentHash.call({form: caller}),
      await document.creator.call({from: caller})
    );
    return ipfsDocument;
  }

  async getIPFSDocument(address, caller = this.selectedUserSource.value.address): Promise<IPFSDocument> {
    let document = await this.DocumentContract.at(address, {from: caller});
    let ipfsDocument = new IPFSDocument(
      document.address,
      await document.ipfsHash.call({from: caller}),
      await document.documentHash.call({form: caller}),
      await document.creator.call({from: caller})
    );
    return ipfsDocument;
  }

  async registerPresentationEntry(id, document, caller = this.selectedUserSource.value.address) {
    console.log('Registrando asiento presentación');
    await this.landRegistry.addPresentationEntry(id, document, {from:caller});
  }

  async registerInscriptionEntry(id, type, property, document, caller = this.selectedUserSource.value.address) {
    await this.landRegistry.addInscriptionEntry(id, type, property, document, {from:caller});
  }

  async getProperty(address, caller = this.selectedUserSource.value.address): Promise<Property> {
    let newProperty = await this.PropertyContract.at(address, {from: caller});
    let propertyInfo = await newProperty.getPropertyInfo({from: caller});
    return new Property(
      propertyInfo[0].toNumber(), // IDUFIR
      propertyInfo[1].toNumber(), // CRU
      newProperty.address,        //Address
      propertyInfo[2],            //Description
      propertyInfo[3],            //Owner
      propertyInfo[4],            //Land Registry
      propertyInfo[5]             //Purchase Contract
    );
  }

  async getLandRegistry(caller = this.selectedUserSource.value.address): Promise<LandRegistry> {
    let landRegistryInfo = await this.landRegistry.getLandRegistryInfo({from: caller});
    return new LandRegistry(
      this.landRegistry.address,
      landRegistryInfo[0],
      landRegistryInfo[1],
      landRegistryInfo[2],
      landRegistryInfo[3],
      landRegistryInfo[4],
      landRegistryInfo[5],
      landRegistryInfo[6],
    );  
  }


  // Purchase Contract

  async createPurchaseAndSaleContract(property, buyer, price, paymentSignal, caller = this.selectedUserSource.value.address) {

    let propertyInstance = await this.PropertyContract.at(property, {from: caller}); 
    let purchaseAndSale = await this.PurchaseAndSaleContract.new(property, buyer, price, paymentSignal, {from: caller});
    await propertyInstance.setPurchaseAndSaleContract(purchaseAndSale.address, {from: caller});
    
  }

  async getPurchaseAndSaleContract(address, caller = this.selectedUserSource.value.address): Promise<PurchaseAndSale> {
    let purchaseAndSaleContract = await this.PurchaseAndSaleContract.at(address, {from: caller});
    let purchaseAndSaleInfo = await purchaseAndSaleContract.getPurchaseAndSaleInfo({from: caller});

    let purchaseAndSaleObject = new PurchaseAndSale(
      purchaseAndSaleInfo[0],
      purchaseAndSaleInfo[1],
      purchaseAndSaleInfo[2],
      purchaseAndSaleInfo[3].toNumber(),
      purchaseAndSaleInfo[4].toNumber(),
      purchaseAndSaleInfo[5].toNumber(),
      purchaseAndSaleInfo[6],
      purchaseAndSaleInfo[7],
      purchaseAndSaleInfo[8],
      purchaseAndSaleInfo[9],
      purchaseAndSaleInfo[10]
    );

    let buyerPaymentRecipients = await purchaseAndSaleContract.getSignerPaymentRecipients(purchaseAndSaleObject.buyer, {from: caller});
    let debtsPromise =  buyerPaymentRecipients.map(async recipient => {
        let res = await purchaseAndSaleContract.getSignerDueWith(purchaseAndSaleObject.buyer, recipient, {from: caller});
        return res.toNumber();
    });
    let buyerDebts = await Promise.all(debtsPromise);
    let buyerInfo = await purchaseAndSaleContract.getSignerInfo(purchaseAndSaleObject.buyer, {from: caller});
    purchaseAndSaleObject.setBuyerInfo(
      buyerInfo[0],
      buyerInfo[1],
      buyerInfo[2].toNumber(),
      buyerInfo[3].toNumber(),
      buyerInfo[4].toNumber(),
      buyerInfo[5],
      buyerPaymentRecipients,
      buyerDebts
      
    );

    let sellerPaymentRecipients = await purchaseAndSaleContract.getSignerPaymentRecipients(purchaseAndSaleObject.seller, {from: caller});
    debtsPromise =  sellerPaymentRecipients.map(async recipient => {
        let res = await purchaseAndSaleContract.getSignerDueWith(purchaseAndSaleObject.buyer, recipient, {from: caller});
        return res.toNumber();
    });
    let sellerDebts = await Promise.all(debtsPromise);
    let sellerInfo = await purchaseAndSaleContract.getSignerInfo(purchaseAndSaleObject.seller, {from: caller});
    purchaseAndSaleObject.setSellerInfo(
      sellerInfo[0],
      sellerInfo[1],
      sellerInfo[2].toNumber(),
      sellerInfo[3].toNumber(),
      sellerInfo[4].toNumber(),
      sellerInfo[5],
      sellerPaymentRecipients,
      sellerDebts
      
    );

    return purchaseAndSaleObject;
  }

  async addNotary(address, notary, caller = this.selectedUserSource.value.address): Promise<boolean> {
    try{
      let purchaseAndSaleContract = await this.PurchaseAndSaleContract.at(address, {from: caller});
      await purchaseAndSaleContract.addNotary(notary, {from: caller});
      return true;
    } catch(err) {
      console.log(err);
      return false;
    }  
  }

  async payEarnestMoney(address, quantity, caller = this.selectedUserSource.value.address): Promise<boolean>{
    try {
      let purchaseAndSaleContract = await this.PurchaseAndSaleContract.at(address, {from: caller});
      console.log('Paying: ', quantity);
      await this.euroToken.approve(purchaseAndSaleContract.address, quantity, {from: caller})
      console.log('Approved: ', await this.euroToken.allowance(caller, purchaseAndSaleContract.address, {from: caller}));
      await purchaseAndSaleContract.payEarnestMoney({from: caller});
      let paid = (await purchaseAndSaleContract.getSignerInfo(caller, {from: caller}))[2].toNumber();
      console.log('Really Paid: ', paid);
      return true;
    } catch (err) {
      console.log(err);
      return false;
    }
  }

  async setPurchaseAndSaleContractHash(address, hash, caller = this.selectedUserSource.value.address): Promise<boolean> {
    try {
      let purchaseAndSaleContract = await this.PurchaseAndSaleContract.at(address, {from: caller});
      await purchaseAndSaleContract.setPurchaseAndSaleContractHash(hash, {from: caller});
      return true;
    } catch(err) {
      console.log(err);
      return false;
    }
  }

  async validatePurchaseAndSaleContractHash(address, hash, caller = this.selectedUserSource.value.address): Promise<boolean> {
    try {
      let purchaseAndSaleContract = await this.PurchaseAndSaleContract.at(address, {from: caller});
      await purchaseAndSaleContract.validatePurchaseAndSaleContractHash(hash, {from: caller});
      return true;
    } catch(err) {
      console.log(err);
      return false;
    }
  }

  async payOutstandingPayments(address, quantity, caller = this.selectedUserSource.value.address): Promise<boolean>{
    try {
      let purchaseAndSaleContract = await this.PurchaseAndSaleContract.at(address, {from: caller});
      console.log('Paying: ', quantity);
      await this.euroToken.approve(purchaseAndSaleContract.address, quantity, {from: caller})
      console.log('Approved: ', await this.euroToken.allowance(caller, purchaseAndSaleContract.address, {from: caller}));
      await purchaseAndSaleContract.payOutstandingPayments({from: caller});
      let paid = (await purchaseAndSaleContract.getSignerInfo(caller, {from: caller}))[4].toNumber();
      console.log('Really Paid: ', paid);
      return true;
    } catch (err) {
      console.log(err);
      return false;
    }
  }

  async sign(address, caller = this.selectedUserSource.value.address): Promise<boolean> {
    try {
      let purchaseAndSaleContract = await this.PurchaseAndSaleContract.at(address, {from: caller});
      purchaseAndSaleContract.sign({from: caller});
      return true;
    } catch(err) {
      console.log(err);
      return false;
    }
  }

  async qualify(address, qualification, caller = this.selectedUserSource.value.address): Promise<boolean> {
    try {
      let purchaseAndSaleContract = await this.PurchaseAndSaleContract.at(address, {from: caller});
      purchaseAndSaleContract.qualify(qualification, {from: caller});
      return true;
    } catch(err) {
      console.log(err);
      return false;
    }
  }

  async cancel(address, caller = this.selectedUserSource.value.address): Promise<boolean> {
    try {
      let purchaseAndSaleContract = await this.PurchaseAndSaleContract.at(address, {from: caller});
      purchaseAndSaleContract.cancel({from: caller});
      return true;
    } catch(err) {
      console.log(err);
      return false;
    }
  }
  

}
