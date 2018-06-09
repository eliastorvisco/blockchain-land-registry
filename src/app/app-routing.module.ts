import { NgModule } from '@angular/core';

import { RouterModule, Routes } from '@angular/router';

import { HomeComponent } from './home/home.component';
import { LandRegistryComponent } from './land-registry/land-registry.component';
import { PropertyComponent } from './property/property.component';


const appRoutes: Routes = [
    { path: '', redirectTo: '/land-registry', pathMatch: 'full'},
    { path: 'land-registry', component: LandRegistryComponent },
    { path: 'home', component: HomeComponent },
    { path: 'property/:address', component: PropertyComponent }
];

@NgModule({
  imports: [
    RouterModule.forRoot(appRoutes)
  ],
  exports: [RouterModule]
})
export class AppRoutingModule { }
