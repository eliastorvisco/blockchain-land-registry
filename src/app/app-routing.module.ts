import { NgModule } from '@angular/core';

import { RouterModule, Routes } from '@angular/router';

import { HomeComponent } from './home/home.component';
import { LandRegistryComponent } from './land-registry/land-registry.component';
import { PropertyComponent } from './property/property.component';
import { PurchaseContractComponent } from './purchase-contract/purchase-contract.component';
import { Purchase } from '../utils/Purchase';


const appRoutes: Routes = [
    { path: '', redirectTo: '/land-registry', pathMatch: 'full'},
    { path: 'land-registry', component: LandRegistryComponent },
    { path: 'home', component: HomeComponent },
    { path: 'property/:address', component: PropertyComponent },
    { path: 'purchase-contract/:address', component: PurchaseContractComponent }
];

@NgModule({
  imports: [
    RouterModule.forRoot(appRoutes)
  ],
  exports: [RouterModule]
})
export class AppRoutingModule { }
