import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Empleado } from 'src/app/intranet/empleados/model/empleado';
import { Fichaje } from '../../model/fichaje';
import { FichajeDto } from '../../model/fichajeDto';
import { FichajeService } from '../../service/fichaje.service';

import { Popup } from 'src/app/shared/helper/popup';

@Component({
  selector: 'app-fichajes-detalle',
  templateUrl: './fichajes-detalle.component.html',
  styleUrls: ['./fichajes-detalle.component.css']
})
export class FichajesDetalleComponent implements OnInit {

  model: FichajeDto = {
    id: undefined,
    diaDesde: '',
    diaHasta: '',
    horaDesde: '',
    horaHasta: '',
    hora: '',
    dia: '',
    origen: null,
    tipo: '',
    numeroUsuario: '',
    nombreUsuario: '',
    usuario: new Empleado('', '', '', '', null, null, null, null, null,'')
  }

  // Propiedades para edición en zona horaria local
  get diaLocalEdit(): string {
    if (!this.model) return '';
    
    try {
      // Prioridad: usar diaLocal convertido, luego dia original
      if (this.model.diaLocal) {
        // Convertir formato DD/MM/YYYY a YYYY-MM-DD para input date
        const parts = this.model.diaLocal.split('/');
        if (parts.length === 3) {
          const day = parts[0].padStart(2, '0');
          const month = parts[1].padStart(2, '0');
          const year = parts[2];
          return `${year}-${month}-${day}`;
        }
      }
      
      // Fallback: usar dia original si está en formato YYYY-MM-DD
      if (this.model.dia && this.model.dia.match(/^\d{4}-\d{2}-\d{2}$/)) {
        return this.model.dia;
      }
      
      return '';
    } catch (error) {
      console.warn('Error en diaLocalEdit getter:', error);
      return '';
    }
  }

  set diaLocalEdit(value: string) {
    if (!value || !this.model) return;
    
    // Convertir formato input (YYYY-MM-DD) a formato local (DD/MM/YYYY)
    const parts = value.split('-');
    if (parts.length === 3) {
      const [year, month, day] = parts;
      this.model.diaLocal = `${day}/${month}/${year}`;
      console.log('🔄 Día local actualizado:', this.model.diaLocal);
    }
    
    // También actualizar dia (aunque no se usa para conversión, por compatibilidad)
    this.model.dia = value;
    console.log('🔄 Día backend actualizado:', value);
    
    // Recalcular campos locales si es necesario
    this.updateLocalFields();
  }

  get horaLocalEdit(): string {
    if (!this.model) return '';
    
    try {
      // Prioridad: usar horaLocal convertida
      if (this.model.horaLocal) {
        // Convertir HH:mm:ss a HH:mm para input time
        return this.model.horaLocal.substring(0, 5);
      }
      
      // Fallback: usar hora original
      if (this.model.hora) {
        return this.model.hora.substring(0, 5);
      }
      
      return '';
    } catch (error) {
      console.warn('Error en horaLocalEdit getter:', error);
      return '';
    }
  }

  set horaLocalEdit(value: string) {
    if (!value || !this.model) return;
    
    // Convertir formato input (HH:mm) a formato backend con segundos
    this.model.hora = value.length === 5 ? value + ':00' : value;
    console.log('🔄 Hora actualizada:', this.model.hora);
    
    // Recalcular campos locales si es necesario
    this.updateLocalFields();
  }

  private updateLocalFields(): void {
    // Si tenemos ambos campos, podemos recalcular los campos locales
    if (this.model.dia && this.model.hora) {
      console.log('🔄 Recalculando campos locales después de edición');
      // El servicio se encargará de la conversión en el próximo fetch
    }
  }

  // Método para convertir de zona horaria local (Madrid) de vuelta a UTC usando timestamps
  private convertLocalToUTC(dia: string, hora: string): {dia: string, hora: string} {
    try {
      console.log('🔄 Convirtiendo Madrid → UTC usando timestamps:', dia, hora);
      
      // Detectar formato de entrada
      let dateStr: string;
      let timeStr: string;
      
      if (dia.includes('-')) {
        // Formato YYYY-MM-DD
        dateStr = dia;
        timeStr = hora.substring(0, 5); // Asegurar HH:mm
      } else {
        // Formato DD/MM/YYYY - convertir a YYYY-MM-DD
        const [day, month, year] = dia.split('/');
        dateStr = `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
        timeStr = hora.substring(0, 5); // Asegurar HH:mm
      }
      
      // Crear timestamp de Madrid (CEST) usando el formato ISO con timezone
      const madridTimestamp = `${dateStr}T${timeStr}:00+02:00`; // +02:00 para CEST en agosto
      console.log('📅 Timestamp Madrid creado:', madridTimestamp);
      
      // Convertir a Date object (esto automáticamente maneja la conversión a UTC)
      const madridDate = new Date(madridTimestamp);
      console.log('⏰ Date object (UTC automático):', madridDate.toISOString());
      
      // Obtener componentes UTC
      const utcYear = madridDate.getUTCFullYear();
      const utcMonth = madridDate.getUTCMonth() + 1;
      const utcDay = madridDate.getUTCDate();
      const utcHours = madridDate.getUTCHours();
      const utcMinutes = madridDate.getUTCMinutes();
      
      // Formatear resultado según el formato esperado por el backend
      const utcDia = `${utcYear}-${String(utcMonth).padStart(2, '0')}-${String(utcDay).padStart(2, '0')}`;
      const utcHora = `${String(utcHours).padStart(2, '0')}:${String(utcMinutes).padStart(2, '0')}`;
      
      console.log('✅ Conversión completa usando timestamps:');
      console.log(`  Original (Madrid CEST): ${dia} ${hora}`);
      console.log(`  Timestamp intermedio: ${madridTimestamp}`);
      console.log(`  Resultado UTC: ${utcDia} ${utcHora}`);
      console.log(`  Cambio de día: ${dateStr !== utcDia ? 'SÍ' : 'NO'}`);
      
      return {
        dia: utcDia,
        hora: utcHora
      };
    } catch (error) {
      console.error('❌ Error en conversión usando timestamps:', error);
      console.error('❌ Datos problemáticos:', { dia, hora });
      // Fallback: devolver valores originales limpios
      const cleanHora = hora.substring(0, 5); // HH:mm
      const cleanDia = dia.includes('-') ? dia : dia.split('/').reverse().join('-');
      return { dia: cleanDia, hora: cleanHora };
    }
  }

  // Método auxiliar para detectar horario de verano
  private isDaylightSavingTime(date: Date): boolean {
    const january = new Date(date.getFullYear(), 0, 1);
    const july = new Date(date.getFullYear(), 6, 1);
    const stdTimezoneOffset = Math.max(january.getTimezoneOffset(), july.getTimezoneOffset());
    return date.getTimezoneOffset() < stdTimezoneOffset;
  }

  constructor(
    private service: FichajeService,
    private activatedRoute: ActivatedRoute,
    private router: Router,
  ) {
  }


  ngOnInit(): void {
    const id = this.activatedRoute.snapshot.params.id
    this.service.detail(id).subscribe(
      data => {
        console.log(data)
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
    
    console.log('🔍 DATOS ANTES DE UPDATE:');
    console.log('- ID:', id);
    console.log('- model.dia (UTC backend):', this.model.dia);
    console.log('- model.diaLocal (lo que ve usuario):', this.model.diaLocal);
    console.log('- model.hora:', this.model.hora);
    console.log('- model.tipo:', this.model.tipo);
    console.log('- model.origen:', this.model.origen);
    console.log('- model completo:', this.model);
    
    // IMPORTANTE: Usar diaLocal (lo que editó el usuario) NO dia (UTC del backend)
    const fechaUsuario = this.model.diaLocal || this.model.dia; // Fallback por seguridad
    console.log('📅 FECHA PARA CONVERSIÓN (usuario):', fechaUsuario);
    
    // Convertir de zona horaria local (Madrid) de vuelta a UTC para la base de datos
    const utcDateTime = this.convertLocalToUTC(fechaUsuario, this.model.hora);
    
    // Crear FichajeDto simple como espera el backend
    const fichajeDtoForUpdate = {
      hora: utcDateTime.hora,    // HH:mm sin segundos
      dia: utcDateTime.dia,      // Fecha en UTC
      tipo: this.model.tipo,
      origen: this.model.origen
    };
    
    console.log('🔄 CONVERSIÓN MADRID → UTC:');
    console.log('- Original (Madrid):', fechaUsuario, this.model.hora);
    console.log('- Convertido (UTC):', utcDateTime.dia, utcDateTime.hora);
    console.log('🚀 ENVIANDO AL BACKEND (FichajeDto):', fichajeDtoForUpdate);
    console.log('🚀 JSON enviado:', JSON.stringify(fichajeDtoForUpdate));
    
    this.service.updateDto(id, fichajeDtoForUpdate).subscribe(
      data => {
        console.log('✅ RESPUESTA EXITOSA:', data);
        Popup.toastSucess('', 'Cambios Guardados');
      },
      err => {
        console.error('❌ ERROR DETALLADO:', err);
        console.error('❌ Status:', err.status);
        console.error('❌ Error object:', err.error);
        console.error('❌ Message:', err.message);
        Popup.toastDanger('Ocurrió un error', err.message);
      }
    )
  }

  onDelete(): void {
    const id = this.activatedRoute.snapshot.params.id
    Popup.dangerConfirmBox('¿Desea eliminar el fichaje?', 'Esta operación no se puede deshacer', 'SI', 'NO').openConfirmBox$().subscribe(resp => {
      // IConfirmBoxPublicResponse
      if (resp.Success) {
        this.delete(id)
      }
    });
  }

  delete(id: number) {
    this.service.delete(id).subscribe(
      data => {
        Popup.toastWarning('', 'Fichaje Eliminado');
        this.router.navigate(['intranet/fichajes'])
      },
      err => {
        Popup.toastDanger('Ocurrió un error', err.message);
        console.log(err)
      }
    )
  }



}
