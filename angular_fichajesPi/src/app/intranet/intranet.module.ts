import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { CoreModule } from '../core/core.module';
import { SharedModule } from '../shared/shared.module';

import { IntranetRoutingModule } from './intranet-routing.module';
import { IntranetComponent } from './intranet.component';
import { HorariosUsuarioComponent } from './horarios-usuario/horarios-usuario.component';


@NgModule({
  declarations: [
    IntranetComponent,
    HorariosUsuarioComponent
  ],
  imports: [
    CommonModule,
    IntranetRoutingModule,
    CoreModule,
    SharedModule,
    ReactiveFormsModule,
    FormsModule
  ],
  exports: [
  ]
})
export class IntranetModule { }
