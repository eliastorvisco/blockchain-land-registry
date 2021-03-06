import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ReactiveFormsModule } from '@angular/forms'; 
import { AppComponent } from './app.component';
import { HomeComponent } from './home/home.component';
import { AppRoutingModule } from './app-routing.module';
import { LandRegistryComponent } from './land-registry/land-registry.component';
import { PropertyComponent } from './property/property.component';
import { PurchaseContractComponent } from './purchase-contract/purchase-contract.component';
import { BankComponent } from './bank/bank.component';
import { RegistryBooksComponent } from './registry-books/registry-books.component';
import { NewDocumentComponent } from './new-document/new-document.component';





@NgModule({
  declarations: [
    AppComponent,
    HomeComponent,
    LandRegistryComponent,
    PropertyComponent,
    PurchaseContractComponent,
    BankComponent,
    RegistryBooksComponent,
    NewDocumentComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    FormsModule,
    ReactiveFormsModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
