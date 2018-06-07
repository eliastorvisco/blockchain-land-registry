import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Web3Service } from './web3.service';

import { Account } from '../utils/account';
import { User } from '../utils/User';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent implements OnInit {

  user: string = 'seller';
  constructor(public router:Router, private web3:Web3Service) { 
  }

  ngOnInit() {
  }

  open(newRoute) {
    console.log("hello!");
    this.router.navigate([newRoute]);
  }

  selectUser(newUser) {
    this.user = newUser;
    this.web3.selectUser(newUser);
  }


}
