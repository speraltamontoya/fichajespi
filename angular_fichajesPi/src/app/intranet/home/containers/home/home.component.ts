import { Component, OnInit } from '@angular/core';
import { HomeService } from '../../service/home.service';
import { Popup } from 'src/app/shared/helper/popup';
import { FichajeDto } from 'src/app/intranet/fichajes/model/fichajeDto';
import { Empleado } from 'src/app/intranet/empleados/model/empleado';
import { Router } from '@angular/router';
import { EmpleadosService } from 'src/app/intranet/empleados/service/empleados.service';
import { EstimacionesService, EstimacionDto } from '../../service/estimaciones.service';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.css']
})
export class HomeComponent implements OnInit {

  model: Empleado = new Empleado('', '', '', '', null, null, null, null, null, '');
  horasEstimadas: number = 4;
  horasLista: number[] = [];
  dto: FichajeDto = {
    diaDesde: '',
    diaHasta: '',
    horaDesde: '',
    horaHasta: '',
    hora: '',
    dia: '',
    origen: 'web',
    tipo: '',
    numeroUsuario: '',
    nombreUsuario: '',
  };

  constructor(
    private service: HomeService,
    private empleadoService: EmpleadosService,
    private estimacionesService: EstimacionesService,
    private router: Router
  ) { }

  ngOnInit(): void {
    // Generar lista de horas de 1 a 12, incluyendo decimales .00, .25, .5, .75
    for (let i = 1; i <= 12; i++) {
      this.horasLista.push(i);
      this.horasLista.push(i + 0.25);
      this.horasLista.push(i + 0.5);
      this.horasLista.push(i + 0.75);
    }
    // Eliminar los que superen 12
    this.horasLista = this.horasLista.filter(h => h <= 12);
    // Quitar decimales innecesarios
    this.horasLista = Array.from(new Set(this.horasLista.map(h => Math.round(h * 100) / 100))).sort((a, b) => a - b);
    this.loadData();
  }

  loadData(): void {
    this.empleadoService.getMyUsuario().subscribe(
      data => {
        this.model = data
        this.dto.numeroUsuario = data.numero;
      },
      err => {
        Popup.toastDanger('Ocurrió un error', err.message);
        console.log(err)
      }
    )
  }

  fichar(): void {
    // Si el usuario está fuera (próximo fichaje es entrada), enviar estimación
    if (!this.model.working) {
      if (typeof this.model.id !== 'number' || this.model.id === null) {
        Popup.toastDanger('Error', 'No se ha podido identificar el usuario. Intenta recargar la página.');
        return;
      }
      const estimacion: EstimacionDto = {
        usuarioId: this.model.id,
        horasEstimadas: this.horasEstimadas || 4,
        fecha: new Date().toISOString()
      };
      this.estimacionesService.crearEstimacion(estimacion).subscribe({
        next: () => {
          this.realizarFichaje();
        },
        error: err => {
          Popup.toastDanger('Ocurrió un error al guardar la estimación', err.message);
          console.log(err);
        }
      });
    } else {
      // Si está dentro (próximo fichaje es salida), solo fichar
      this.realizarFichaje();
    }
  }

  private realizarFichaje(): void {
    this.service.now(this.dto).subscribe(
      data => {
        Popup.toastSucess('', 'Fichaje realizado');
        this.loadData();
      },
      err => {
        Popup.toastDanger('Ocurrió un error', err.message);
        console.log(err)
      }
    );
  }

}
