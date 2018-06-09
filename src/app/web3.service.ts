import { Injectable, OnInit } from '@angular/core';
import { Account } from '../utils/account';
import { User } from '../utils/User';
import { Property } from '../utils/Property';
import { LandRegistry } from '../utils/LandRegistry';
import { BehaviorSubject, Observable } from 'rxjs';

const Web3 = require('web3');
const contract = require('truffle-contract');

const landRegistryArtifacts = require('../../truffle/build/contracts/LandRegistry.json');
const euroTokenBankingArtifacts = require('../../truffle/build/contracts/EuroTokenBanking.json');
const euroTokenArtifacts = require('../../truffle/build/contracts/EuroToken.json');
const propertyArtifacts = require('../../truffle/build/contracts/Property.json');

@Injectable({
  providedIn: 'root'
})

export class Web3Service implements OnInit {

  LandRegistryContract = contract(landRegistryArtifacts);
  EuroTokenBanking = contract(euroTokenBankingArtifacts);
  EuroToken = contract(euroTokenArtifacts);
  PropertyContract = contract(propertyArtifacts);

  web3: any;
  accounts: Account[] = [];

  manager: User;
  seller: User;
  buyer: User;
  notary: User;
  registrar: User;

  selectedUserSource = new BehaviorSubject<User>(new User('','',''));
  selectedUser = this.selectedUserSource.asObservable();
  // Contract Instances
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
    console.log('Users initialized');
    this.setContracts();
  }
 
  async setContracts() {
    // Land Registry Init
    this.landRegistry = await this.LandRegistryContract.new(
      'Hospitalet de Llobregat, L\' Nº 02',
      'Sevilla, 11-13,2º-2ª - Cornella de Llobregat [08940]',
      'Barcelona',
      '(93)475 26 86',
      '(93)475 26 86',
      'hospitalet2registrodelapropiedad.org'
    , {from: this.manager.address});
    console.log('Registry: ', this.landRegistry);
    await this.landRegistry.setRegistrar(this.registrar.address, {from: this.manager.address});
    // // Banking Init
    this.euroTokenBanking = await this.EuroTokenBanking.new({from: this.manager.address});
    console.log(this.euroTokenBanking);

    this.euroToken = await this.EuroToken.at(
      await this.euroTokenBanking.euroToken.call({from: this.manager.address})
    , {from: this.manager.address});

    this.listenPropertyRegistrations();
  }



  updateAccounts(account: Account, modify = false) {
    if (modify) {
      this.accounts.forEach((item, index) => {
        if (item.address == account.address) {
          this.accounts[index] = account;
        }
      });
    } else {
      console.log('Pushing account: ', account.address);
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
    console.log('User selected: ', newUser);
  }

  // Events

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
    console.log(landRegistryInfo);
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

}
