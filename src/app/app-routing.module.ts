import { NgModule } from '@angular/core';

import { RouterModule, Routes } from '@angular/router';

import { HomeComponent } from './home/home.component';
import { LandRegistryComponent } from './land-registry/land-registry.component';
import { SellerComponent } from './seller/seller.component';
import { BuyerComponent } from './buyer/buyer.component';
import { NotaryComponent } from './notary/notary.component';
import { RegistrarComponent } from './registrar/registrar.component';

const appRoutes: Routes = [
    { path: '', redirectTo: '/land-registry', pathMatch: 'full'},
    { path: 'land-registry', component: LandRegistryComponent },
    { path: 'seller', component: SellerComponent },
    { path: 'buyer', component: BuyerComponent },
    { path: 'notary', component: NotaryComponent },
    { path: 'registrar', component: RegistrarComponent },
    { path: 'home', component: HomeComponent } 
];

@NgModule({
  imports: [
    RouterModule.forRoot(appRoutes)
  ],
  exports: [RouterModule]
})
export class AppRoutingModule { }
