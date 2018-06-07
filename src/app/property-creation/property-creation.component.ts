import { Component, OnInit } from '@angular/core';
import { Web3Service } from '../web3.service';

@Component({
  selector: 'app-property-creation',
  templateUrl: './property-creation.component.html',
  styleUrls: ['./property-creation.component.css']
})
export class PropertyCreationComponent implements OnInit {

  model: any = {};

  constructor(private web3:Web3Service) {

  }

  ngOnInit() {
  }

  onSubmit() {
    alert('SUCCESS!! :-)\n\n' + JSON.stringify(this.model))
  }



}
