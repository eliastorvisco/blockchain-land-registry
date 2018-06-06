import { Component, OnInit } from '@angular/core';

@Component({
  selector: 'app-land-registry',
  templateUrl: './land-registry.component.html',
  styleUrls: ['./land-registry.component.css']
})
export class LandRegistryComponent implements OnInit {

  page = 0;

  constructor() { }

  ngOnInit() {
  }

  changePage(newPage) {
    this.page = newPage;
    console.log(this.page);
  }

}
