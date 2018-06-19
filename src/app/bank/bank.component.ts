import { Component, OnInit, OnDestroy } from '@angular/core';
import { User } from '../../utils/User';
import { Web3Service } from '../web3.service';

@Component({
  selector: 'app-bank',
  templateUrl: './bank.component.html',
  styleUrls: ['./bank.component.css']
})
export class BankComponent implements OnInit {

  user: User;
  userSubscription:any;
  euroTokens:number = 0;

  constructor(private web3Service: Web3Service) { }

  ngOnInit() {
    this.userSubscription = this.web3Service.selectedUser.subscribe(
      selectedUser => {this.user = selectedUser; this.updateEuroTokens(); console.log('¡Helo!');}, 
      err => {console.log('Something happened: ', err);
    });
  }

  ngOnDestroy() {
    this.userSubscription.unsubscribe();
  }

  async updateEuroTokens() {
    
    this.euroTokens = await this.web3Service.getEuroTokenBalance(this.user.address);
  }

  async cashIn(quantity) {
    await this.web3Service.cashIn(this.user.address,parseInt(quantity) * 10000);
    this.updateEuroTokens();
  }

}
