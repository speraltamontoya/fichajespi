import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Empleado } from '../../model/empleado';
import { EmpleadosService } from '../../service/empleados.service';
import { Popup } from 'src/app/shared/helper/popup';

@Component({
  selector: 'app-empleado-detalle',
  templateUrl: './empleado-detalle.component.html',
  styleUrls: ['./empleado-detalle.component.css']
})
export class EmpleadoDetalleComponent implements OnInit {

  model: Empleado = new Empleado('', '', '', '', null, null, null, null, null,'')

  constructor(
    private service: EmpleadosService,
    private activatedRoute: ActivatedRoute,
    private router: Router,
  ) { }

  ngOnInit(): void {
    const id = this.activatedRoute.snapshot.params.id
    this.service.detail(id).subscribe(
      data => {
        this.model = data
      },
      err => {
        Popup.toastDanger('Ocurrió un error', err.message);
        console.log(err)
      }
    )
  }

  onUpdate(): void {
    const id = this.activatedRoute.snapshot.params.id
    this.service.update(id, this.model).subscribe(
      data => {
        Popup.toastSucess('', 'Cambios Guardados');
      },
      err => {
        Popup.toastDanger('Ocurrió un error', err.message);
        console.log(err)
      }
    )
  }


  onDelete(): void {
    const id = this.activatedRoute.snapshot.params.id
    Popup.dangerConfirmBox('¿Desea eliminar el usuario?', 'Esta operación no se puede deshacer', 'SI', 'NO').openConfirmBox$().subscribe(resp => {
      // IConfirmBoxPublicResponse
      if (resp.Success) {
        this.delete(id)
      }
    });
  }

  delete(id: number) {
    this.service.delete(id).subscribe(
      data => {
        Popup.toastWarning('', 'Usuario Eliminado');
        this.router.navigate(['intranet/empleados'])
      },
      err => {
        Popup.toastDanger('Ocurrió un error', err.message);
        console.log(err)
      }
    )
  }


  onResetPassword(): void {
    const id = this.model.id;
    if (!id) return;
    this.service.resetPassword(id).subscribe(
      _ => {
        Popup.toastSucess('', 'Contraseña reseteada y enviada por email');
      },
      err => {
        Popup.toastDanger('Ocurrió un error', err.message);
        console.log(err)
      }
    );
  }

  onSetPassword(): void {
    const id = this.model.id;
    if (!id) return;
    // Popup.inputBox('Nueva contraseña', 'Indique la nueva contraseña para el usuario', 'Establecer', 'Cancelar').openConfirmBox$().subscribe(resp => {
    //   if (resp.Success && resp.InputValue) {
    //     this.service.setPassword(id, resp.InputValue).subscribe(
    //       _ => {
    //         Popup.toastSucess('', 'Contraseña establecida correctamente');
    //       },
    //       err => {
    //         Popup.toastDanger('Ocurrió un error', err.message);
    //         console.log(err)
    //       }
    //     );
    //   }
    // });
    const password = prompt('Indique la nueva contraseña para el usuario:');
    if (password) {
      this.service.setPassword(id, password).subscribe(
        _ => {
          Popup.toastSucess('', 'Contraseña establecida correctamente');
        },
        err => {
          Popup.toastDanger('Ocurrió un error', err.message);
          console.log(err)
        }
      );
    }
  }

}
