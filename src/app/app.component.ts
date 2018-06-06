import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Web3Service } from './web3.service';

import { Account } from '../utils/account';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent implements OnInit {

  accounts: Account[] = [];
  seller: Account;
  buyer: Account;
  notary: Account;
  registrar: Account;


  constructor(public router:Router) { }

  ngOnInit() {

    // this.accounts = this.web3Service.accounts;
    // console.log(this.accounts);
    // this.seller = null;
    // console.log(typeof this.accounts[0]);
    // this.buyer = this.accounts[2];
    // this.notary = this.accounts[3];
    // this.registrar = this.accounts[4];
  }

  open(newRoute) {
    console.log("hello!");
    this.router.navigate([newRoute]);
  }

}
