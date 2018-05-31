import { Component } from '@angular/core';
import { Router } from '@angular/router';
@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  title = 'TeletubbieLand';

  constructor(public router:Router) { }

  myFunc() {
    console.log("hello!");
    this.router.navigate(['/home']);
  }
}
