import { Component, OnInit, OnDestroy } from '@angular/core';
import { Web3Service } from '../web3.service';
import { Property } from '../../utils/Property';
import { User } from '../../utils/User';
import { Router } from '@angular/router';

@Component({
  selector: 'app-land-registry',
  templateUrl: './land-registry.component.html',
  styleUrls: ['./land-registry.component.css']
})
export class LandRegistryComponent implements OnInit {
  

  page = 0;
  error:string;
  model: Property = new Property('', '', '', '', '', '', '');
  user: User;
  userSubscription:any;

  constructor(public router:Router, private web3: Web3Service) {
    
  }

  ngOnInit() {
    this.userSubscription = this.web3.selectedUser.subscribe(
      selectedUser => {this.user = selectedUser; console.log('HELLO: ', selectedUser.name)}, 
      err => {console.log('Something happened: ', err);
    });
  }

  ngOnDestroy() {
    this.userSubscription.unsubscribe();
  }

  changePage(newPage) {
    this.page = newPage;
    console.log(this.page);
  }

  async newProperty() {
    try {
      let newProperty = await this.web3.PropertyContract.new(
        this.model.IDUFIR, this.model.CRU, 
        this.model.description, 
        this.model.owner, 
        this.web3.landRegistry.address, 
        {from: this.user.address}
      );
  
      console.log('Nueva Propiedad: ', newProperty.address);
      await this.web3.landRegistry.register(newProperty.address, 2345, 'Nueva Inscripcion', this.model.owner, {from: this.user.address});
    } catch(err) {
      console.log(err);
      this.error = 'Could not create or register the property';
      setTimeout(() => { 
        this.error = ""; 
      }, 5000);
    }
    
  }

  async openProperty(property) {
    this.router.navigate(['property', property]);
    console.log(property);
  }
  

}