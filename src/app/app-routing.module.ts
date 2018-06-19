import { NgModule } from '@angular/core';

import { RouterModule, Routes } from '@angular/router';

import { HomeComponent } from './home/home.component';
import { LandRegistryComponent } from './land-registry/land-registry.component';
import { PropertyComponent } from './property/property.component';
import { PurchaseContractComponent } from './purchase-contract/purchase-contract.component';
import { BankComponent } from './bank/bank.component';
import { RegistryBooksComponent } from './registry-books/registry-books.component';



const appRoutes: Routes = [
    { path: '', redirectTo: '/land-registry', pathMatch: 'full'},
    { path: 'land-registry', component: LandRegistryComponent },
    { path: 'home', component: HomeComponent },
    { path: 'property/:address', component: PropertyComponent },
    { path: 'purchase-contract/:address', component: PurchaseContractComponent },
    { path: 'bank', component: BankComponent },
    { path: 'registry-books', component: RegistryBooksComponent }
];

@NgModule({
  imports: [
    RouterModule.forRoot(appRoutes)
  ],
  exports: [RouterModule]
})
export class AppRoutingModule { }
