import { Component, OnInit, OnDestroy } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { Web3Service } from '../web3.service';
import { Property } from '../../utils/Property';
import { LandRegistry } from '../../utils/LandRegistry';
import { User } from '../../utils/User';
import { Router } from '@angular/router';
import { FormControl, FormGroup } from '@angular/forms';

@Component({
  selector: 'app-property',
  templateUrl: './property.component.html',
  styleUrls: ['./property.component.css']
})
export class PropertyComponent implements OnInit {

  address:any;
  property: Property;
  landRegistry: LandRegistry;

  user: User;
  userSubscription:any;

  purchaseForm = new FormGroup ({
    price: new FormControl(),
    buyer: new FormControl(),
    paymentSignal: new FormControl()
  });

  constructor(public router: Router, private route: ActivatedRoute, private web3Service: Web3Service) {

  }

  ngOnInit() {
    let address = this.route.snapshot.paramMap.get('address');
    this.userSubscription = this.web3Service.selectedUser.subscribe(
      user => {this.user = user; console.log('PropertyComponent User: ', this.user.address.toLowerCase())},
      err => {console.log(err);}
    );
    this.updateProperty(address);
    this.updateLandRegistry()
  }

  async newPurchaseContract() {
    console.log(this.purchaseForm.value);
    await this.web3Service.createPurchaseContract(
      this.property.address, 
      this.purchaseForm.value.buyer,
      parseInt(this.purchaseForm.value.price),
      parseInt(this.purchaseForm.value.paymentSignal)
    );
    this.updateProperty();

  }

  ngOnDestroy() {
    this.userSubscription.unsubscribe();
  }

  async updateProperty(address = this.property.address) {
    this.property = await this.web3Service.getProperty(address);
  }

  async updateLandRegistry() {
    this.landRegistry = await this.web3Service.getLandRegistry();
  }

  openPurchaseContract() {
    if (parseInt(this.property.purchaseContract) != 0) this.router.navigate(['purchase-contract', this.property.purchaseContract]);
  }
}
