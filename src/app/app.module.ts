import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';

import { AppComponent } from './app.component';
import { HomeComponent } from './home/home.component';
import { AppRoutingModule } from './app-routing.module';
import { LandRegistryComponent } from './land-registry/land-registry.component';
import { RegistrarComponent } from './registrar/registrar.component';
import { NotaryComponent } from './notary/notary.component';
import { SellerComponent } from './seller/seller.component';
import { BuyerComponent } from './buyer/buyer.component';

@NgModule({
  declarations: [
    AppComponent,
    HomeComponent,
    LandRegistryComponent,
    RegistrarComponent,
    NotaryComponent,
    SellerComponent,
    BuyerComponent,
  ],
  imports: [
    BrowserModule,
    AppRoutingModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
