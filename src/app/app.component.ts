import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Web3Service } from './web3.service';

import { account } from '../utils/account';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent implements OnInit {

  title = 'TeletubbieLand';
  accounts: account[] = []

  constructor(public router:Router, private web3Service: Web3Service) { }

  ngOnInit() {
    this.accounts = this.web3Service.accounts;
  }

  myFunc() {
    console.log("hello!");
    this.router.navigate(['/home']);
  }

}
