import { HttpClient } from '@angular/common/http';
import { Injectable, SkipSelf } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { DataCsv } from 'src/app/shared/interfaces/dataCsv';
import { DeleteService } from 'src/app/shared/interfaces/DeleteService';
import { Fichaje } from '../model/fichaje';
import { FichajeDto } from '../model/fichajeDto';
import { environment } from 'src/environments/environment';

@Injectable({
  providedIn: 'root'
})
export class FichajeService implements DataCsv, DeleteService {

  //endPoint = 'http://localhost:8080/fichaje';
  endPoint = environment.apiURL + '/fichaje';

  constructor(private httpClient: HttpClient) { }

  // Métodos de conversión de zona horaria
  private convertUTCToLocal(utcDateString: string): string {
    if (!utcDateString) return '';
    
    try {
      // Intentar diferentes formatos de fecha
      let date: Date;
      
      // Caso 1: Si ya tiene 'Z' al final (formato ISO UTC)
      if (utcDateString.endsWith('Z')) {
        date = new Date(utcDateString);
      }
      // Caso 2: Si es formato ISO sin 'Z' - FORZAR interpretación como UTC
      else if (utcDateString.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/)) {
        // IMPORTANTE: El backend envía hora local, pero queremos tratarla como UTC
        // para luego convertirla a la zona horaria correcta
        date = new Date(utcDateString + 'Z'); // Agregar Z para forzar UTC
      }
      // Caso 3: Si es solo fecha (YYYY-MM-DD)
      else if (utcDateString.match(/^\d{4}-\d{2}-\d{2}$/)) {
        date = new Date(utcDateString + 'T00:00:00Z');
      }
      // Caso 4: Si es solo hora (HH:mm:ss o HH:mm)
      else if (utcDateString.match(/^\d{2}:\d{2}(:\d{2})?$/)) {
        const today = new Date().toISOString().split('T')[0];
        // Asegurar formato HH:mm:ss
        const timeWithSeconds = utcDateString.length === 5 ? utcDateString + ':00' : utcDateString;
        date = new Date(today + 'T' + timeWithSeconds + 'Z');
      }
      // Caso 5: Cualquier otro formato, intentar parsearlo directamente
      else {
        date = new Date(utcDateString);
      }
      
      // Verificar si la fecha es válida
      if (isNaN(date.getTime())) {
        console.warn('Fecha inválida recibida:', utcDateString);
        return utcDateString; // Devolver el valor original si no se puede convertir
      }
      
      // Forzar conversión a zona horaria local (Europe/Madrid para España)
      const localTimeZone = 'Europe/Madrid';
      return date.toLocaleString('es-ES', {
        timeZone: localTimeZone,
        hour12: false,
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      });
    } catch (error) {
      console.warn('Error convirtiendo fecha:', utcDateString, error);
      return utcDateString; // Devolver el valor original en caso de error
    }
  }

  private extractLocalTime(localDateTime: string): string {
    if (!localDateTime) return '';
    // Extraer solo la hora (HH:mm:ss) de la fecha/hora local completa
    const timePart = localDateTime.split(' ')[1];
    return timePart ? timePart.substring(0, 8) : ''; // Asegurar HH:mm:ss sin milisegundos
  }

  private extractLocalDate(localDateTime: string): string {
    if (!localDateTime) return '';
    // Extraer solo la fecha (DD/MM/YYYY) de la fecha/hora local completa y quitar comas
    const datePart = localDateTime.split(' ')[0];
    return datePart ? datePart.replace(/,/g, '') : ''; // Eliminar comas de la fecha
  }

  private addLocalTimezoneProperties(fichaje: Fichaje | FichajeDto): FichajeDto {
    // Si es un Fichaje, crear FichajeDto básico
    let fichajeDto: FichajeDto;
    if ('diaDesde' in fichaje) {
      // Ya es un FichajeDto
      fichajeDto = { ...fichaje };
    } else {
      // Es un Fichaje, crear FichajeDto con propiedades requeridas
      fichajeDto = {
        ...fichaje,
        diaDesde: '',
        diaHasta: '',
        horaDesde: '',
        horaHasta: '',
        numeroUsuario: fichaje.usuario?.numero || '',
        nombreUsuario: fichaje.usuario?.nombreEmpleado || '',
        usuario: fichaje.usuario // Preservar la propiedad usuario
      };
    }
    
    // LOG DE DEPURACIÓN: Ver qué datos llegan del backend
    console.log('🔍 Datos originales del backend:', {
      id: fichajeDto.id,
      dia: fichajeDto.dia,
      hora: fichajeDto.hora,
      tipo: fichajeDto.tipo
    });
    
    // Convertir combinando dia y hora si ambos existen
    if (fichajeDto.dia && fichajeDto.hora) {
      try {
        // Combinar fecha y hora para crear un datetime completo
        const combinedDateTime = fichajeDto.dia + 'T' + fichajeDto.hora;
        console.log('🔗 Fecha/hora combinada:', combinedDateTime);
        
        // IMPORTANTE: Backend registra en UTC pero envía como strings sin timezone
        // Necesitamos interpretar como UTC y convertir a zona horaria local
        
        // Crear fecha tratando los datos como UTC (agregando 'Z')
        const utcDate = new Date(combinedDateTime + 'Z');
        console.log('⏰ Interpretado como UTC:', utcDate.toISOString());
        
        // Convertir a zona horaria de España (Europe/Madrid)
        const madridTime = new Intl.DateTimeFormat('es-ES', {
          timeZone: 'Europe/Madrid',
          year: 'numeric',
          month: '2-digit',
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit',
          hour12: false
        }).formatToParts(utcDate);
        
        // Reconstruir fecha y hora en formato español
        const dayPart = madridTime.find(part => part.type === 'day')?.value;
        const monthPart = madridTime.find(part => part.type === 'month')?.value;
        const yearPart = madridTime.find(part => part.type === 'year')?.value;
        const hourPart = madridTime.find(part => part.type === 'hour')?.value;
        const minutePart = madridTime.find(part => part.type === 'minute')?.value;
        const secondPart = madridTime.find(part => part.type === 'second')?.value;
        
        fichajeDto.diaLocal = `${dayPart}/${monthPart}/${yearPart}`;
        fichajeDto.horaLocal = `${hourPart}:${minutePart}:${secondPart}`;
        
        console.log('✅ Resultado final (UTC→Madrid):', {
          original: `${fichajeDto.dia} ${fichajeDto.hora}`,
          utc: utcDate.toISOString(),
          diaLocal: fichajeDto.diaLocal,
          horaLocal: fichajeDto.horaLocal,
          diferenciaHoras: (utcDate.getTimezoneOffset() / -60) + 'h'
        });
      } catch (error) {
        console.warn('❌ Error procesando dia y hora:', fichajeDto.dia, fichajeDto.hora, error);
        // Fallback: usar valores originales con formato básico
        fichajeDto.horaLocal = fichajeDto.hora;
        fichajeDto.diaLocal = fichajeDto.dia;
      }
    } else {
      // Convertir hora principal a zona horaria local (método anterior)
      if (fichajeDto.hora) {
        console.log('🔄 Convirtiendo solo hora:', fichajeDto.hora);
        const localDateTime = this.convertUTCToLocal(fichajeDto.hora);
        console.log('⏰ Hora convertida:', localDateTime);
        fichajeDto.horaLocal = this.extractLocalTime(localDateTime);
        fichajeDto.diaLocal = this.extractLocalDate(localDateTime);
      }
      
      // Si no hay horaLocal pero hay dia, usar dia original
      if (!fichajeDto.diaLocal && fichajeDto.dia) {
        fichajeDto.diaLocal = fichajeDto.dia;
      }
    }
    
    // Convertir horaDesde si existe
    if (fichajeDto.horaDesde) {
      fichajeDto.horaDesdeLocal = this.extractLocalTime(this.convertUTCToLocal(fichajeDto.horaDesde));
    }
    
    // Convertir horaHasta si existe
    if (fichajeDto.horaHasta) {
      fichajeDto.horaHastaLocal = this.extractLocalTime(this.convertUTCToLocal(fichajeDto.horaHasta));
    }
    
    return fichajeDto;
  }

  getElements(
    dto: FichajeDto,
    page: number,
    size: number,
    order: string,
    asc: boolean): Observable<any> {

    return this.httpClient.post<any[]>(this.endPoint + `/pagesFiltered?page=${page}&size=${size}&order=${order}&asc=${asc}`, dto)
      .pipe(
        map((response: any) => ({
          ...response,
          content: response.content?.map((fichaje: Fichaje) => this.addLocalTimezoneProperties(fichaje))
        }))
      );
  }

  public detail(id: number): Observable<FichajeDto> {
    return this.httpClient.get<Fichaje>(this.endPoint + `/${id}`)
      .pipe(
        map((fichaje: Fichaje) => this.addLocalTimezoneProperties(fichaje))
      );
  }

  public update(id: number, model: Fichaje): Observable<any> {
    return this.httpClient.put<any>(this.endPoint + `/${id}`, model)
  }

  // Método específico para update que envía FichajeDto simple como espera el backend
  public updateDto(id: number, dto: {hora: string, dia: string, tipo: string, origen: string | null}): Observable<any> {
    return this.httpClient.put<any>(this.endPoint + `/${id}`, dto)
  }
  
  public delete(id: number): Observable<any> {
    return this.httpClient.delete<any>(this.endPoint + `/${id}`)
  }

  getCsvData(dto: FichajeDto): Observable<FichajeDto[]> {
    return this.httpClient.post<Fichaje[]>(this.endPoint + `/listFiltered`, dto)
      .pipe(
        map((fichajes: Fichaje[]) => fichajes.map((fichaje: Fichaje) => this.addLocalTimezoneProperties(fichaje)))
      );
  }
}
