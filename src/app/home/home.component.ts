import { Component, OnInit } from '@angular/core';
import { Web3Service } from '../web3.service';
import { Account } from '../../utils/account';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.css']
})
export class HomeComponent implements OnInit {

  accounts: Account[] = [];
  seller: Account;
  buyer: Account;
  notary: Account;
  registrar: Account;

  constructor(private web3Service: Web3Service) { }

  ngOnInit() {
    this.accounts = this.web3Service.accounts;
    console.log(this.accounts);
    this.seller = null;
    console.log(typeof this.accounts[0]);
    this.buyer = this.accounts[2];
    this.notary = this.accounts[3];
    this.registrar = this.accounts[4];
  }

}
