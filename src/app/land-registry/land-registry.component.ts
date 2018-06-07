import { Component, OnInit } from '@angular/core';
import { Web3Service } from '../web3.service';
import { Property } from '../../utils/Property';

@Component({
  selector: 'app-land-registry',
  templateUrl: './land-registry.component.html',
  styleUrls: ['./land-registry.component.css']
})
export class LandRegistryComponent implements OnInit {
  

  page = 0;
  model: Property = new Property('', '', '', '', '');


  constructor(private web3: Web3Service) {
    
  }

  ngOnInit() {
   
  }

  changePage(newPage) {
    this.page = newPage;
    console.log(this.page);
  }

  async newProperty() {
    let info = await this.web3.landRegistry.createProperty(
      this.model.IDUFIR, this.model.CRU, this.model.description, this.model.owner, {from: this.web3.selectedUser.address});
    console.log('Nueva Propiedad: ', info.logs[0].args.property);
    await this.web3.landRegistry.register(info.logs[0].args.property, 2345, 'Nueva Inscripcion', this.model.owner, {from: this.web3.selectedUser.address});
  }

  

}

class PropertyRegistrationUnit {
  IDUFIR:any;
  CRU:any;
  firstRegistration:any;
  property:any;
  owner:any;
  
  constructor(IDUFIR, CRU, firstRegistration, property, owner) {
      this.IDUFIR = IDUFIR;
      this.CRU = CRU;
      this.firstRegistration = firstRegistration;
      this.property = property;
      this.owner = owner;
  }
}
