import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { PropertyCreationComponent } from './property-creation.component';

describe('PropertyCreationComponent', () => {
  let component: PropertyCreationComponent;
  let fixture: ComponentFixture<PropertyCreationComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ PropertyCreationComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(PropertyCreationComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
