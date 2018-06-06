import { Injectable, OnInit } from '@angular/core';
import { Account } from '../utils/account';
import { User } from '../utils/User';

const Web3 = require('web3');
const contract = require('truffle-contract');

const landRegistryArtifacts = require('../../truffle/build/contracts/LandRegistry.json');
const euroTokenBankingArtifacts = require('../../truffle/build/contracts/EuroTokenBanking.json');
const euroTokenArtifacts = require('../../truffle/build/contracts/EuroToken.json');

@Injectable({
  providedIn: 'root'
})

export class Web3Service implements OnInit {

  web3: any;
  accounts: Account[] = [];

  manager: User;
  seller: User;
  buyer: User;
  notary: User;
  registrar: User;

  LandRegistry = contract(landRegistryArtifacts);
  EuroTokenBanking = contract(euroTokenBankingArtifacts);
  EuroToken = contract(euroTokenArtifacts);

  landRegistry: any;
  euroTokenBanking: any;
  euroToken: any;

  constructor() {
    this.initializeWeb3();
    this.getAccounts();
    //this.initializeAccounts();
    
    //this.initializeContracts();
  }

  ngOnInit() {
    
  }

  async getAccounts() {
    const res =  await this.web3.eth.getAccounts();
    for (let acc of res) {
      let balance = await this.web3.eth.getBalance(acc);
      let newAccount = new Account(acc, this.web3.utils.fromWei(balance.toString()));
      console.log('New account: ', newAccount.address);
      this.updateAccounts(newAccount);
    }
    this.initializeUsers();
  }

  initializeWeb3() {
    if (typeof this.web3 !== 'undefined') {
      this.web3 = new Web3(this.web3.currentProvider);
    } else {
      this.web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:7545'));
    }
    this.setProviders();
  }

  setProviders() {
    Web3.providers.HttpProvider.prototype.sendAsync = Web3.providers.HttpProvider.prototype.send;
    this.LandRegistry.setProvider(this.web3.currentProvider);
    this.LandRegistry.defaults({
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
  }

  initializeAccounts() {
    
    //console.log(this.web3);

    this.web3.eth.getAccounts((err, res) => {
      //console.log('Hello?');
      if (err) {
        console.log('There was an error fetching your accounts.');
        return;
      }

      if (res.length === 0) {
        console.log('Could\'t get any accounts! Make sure your Ethereum client is configured correctly.');
        return;
      }

      for (let acc of res) {
        this.web3.eth.getBalance(acc, (err, val) => {
          if (err) {
            alert('There was an error fetching balance of account ' + acc + ': ' + err);
            return;
          }
          //console.log("Account: ", acc);
          let newAccount = new Account(acc, this.web3.utils.fromWei(val.toString()));
          console.log('New account: ', newAccount.address);
          this.updateAccounts(newAccount);
        });
      }
    });
  }

  initializeUsers() {
    this.manager = new User('Manager', this.accounts[0].address, this.accounts[0].balance);
    this.seller = new User('Seller', this.accounts[1].address, this.accounts[1].balance);
    this.buyer = new User('Buyer', this.accounts[2].address, this.accounts[2].balance);
    this.notary = new User('Notary', this.accounts[3].address, this.accounts[3].balance);
    this.registrar = new User('Registrar', this.accounts[4].address, this.accounts[4].balance);
    console.log(this.seller);
    this.initializeContracts();
  }

  async initializeContracts() {
    
    this.landRegistry = await this.LandRegistry.new(
      'Hospitalet de Llobregat, L\' Nº 02',
      'Sevilla, 11-13,2º-2ª - Cornella de Llobregat [08940]',
      'Barcelona',
      '(93)475 26 86',
      '(93)475 26 86',
      'hospitalet2registrodelapropiedad.org'
    , {from: this.manager.address});
    this.euroTokenBanking = await this.EuroTokenBanking.new({from: this.manager.address});
    this.euroToken = await this.EuroToken.at(
      await this.euroTokenBanking.euroToken.call({from: this.manager.address})
    , {from: this.manager.address});

    // console.log('LandRegistry initialized...');
    // console.log(this.landRegistry);
    // let info = await this.landRegistry.getLandRegistryInfo.call({from: this.manager.address});
    // console.log(info);
    // this.propertyCreatedEvent();
    // await this.landRegistry.setRegistrar(this.registrar.address, {from: this.manager.address});
    // let info = await this.landRegistry.createProperty(123, 123, "Casa", this.seller.address, {from: this.registrar.address});
    // console.log('Property Created: ', info);
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

  propertyCreatedEvent() {
    let event = this.landRegistry.PropertyCreated({}, {fromBlock: 0});
    event.watch((err,res) => {
      if (err != null) {
        console.error('Something happened while creating a property...');
      }
      console.log(res);
    });
  }


}
