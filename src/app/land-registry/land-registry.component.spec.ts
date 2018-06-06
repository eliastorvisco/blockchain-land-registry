import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { LandRegistryComponent } from './land-registry.component';

describe('LandRegistryComponent', () => {
  let component: LandRegistryComponent;
  let fixture: ComponentFixture<LandRegistryComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ LandRegistryComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(LandRegistryComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
