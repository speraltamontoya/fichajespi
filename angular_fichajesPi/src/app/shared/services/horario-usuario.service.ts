import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface HorarioUsuario {
  id?: number;
  usuarioId: number;
  usuarioNombre?: string;
  diaSemana: number;
  diaSemanaDescripcion?: string;
  turnoNumero: number;
  horaInicio: string;
  horaFin: string;
  activo?: boolean;
  descripcion?: string;
}

export interface TurnoDTO {
  turnoNumero: number;
  horaInicio: string;
  horaFin: string;
  descripcion?: string;
}

export interface CreateUpdateHorarioDTO {
  usuarioId: number;
  diaSemana: number;
  turnos: TurnoDTO[];
}

export interface DiaSemana {
  id: number;
  nombre: string;
}

@Injectable({
  providedIn: 'root'
})
export class HorarioUsuarioService {
  
  private apiUrl = `${environment.apiURL}/horarios`;

  constructor(private http: HttpClient) { }

  /**
   * Obtener todos los horarios de un usuario
   */
  getHorariosByUsuario(usuarioId: number): Observable<HorarioUsuario[]> {
    return this.http.get<HorarioUsuario[]>(`${this.apiUrl}/usuario/${usuarioId}`);
  }

  /**
   * Obtener horarios de un usuario para un día específico
   */
  getHorariosByUsuarioYDia(usuarioId: number, diaSemana: number): Observable<HorarioUsuario[]> {
    return this.http.get<HorarioUsuario[]>(`${this.apiUrl}/usuario/${usuarioId}/dia/${diaSemana}`);
  }

  /**
   * Crear o actualizar horarios para un usuario en un día específico
   */
  saveHorariosUsuarioDia(usuarioId: number, diaSemana: number, createUpdateDTO: CreateUpdateHorarioDTO): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/usuario/${usuarioId}/dia/${diaSemana}`, createUpdateDTO);
  }

  /**
   * Eliminar un horario específico
   */
  deleteHorario(horarioId: number): Observable<any> {
    return this.http.delete<any>(`${this.apiUrl}/${horarioId}`);
  }

  /**
   * Obtener todos los horarios activos (para administradores)
   */
  getAllHorariosActivos(): Observable<HorarioUsuario[]> {
    return this.http.get<HorarioUsuario[]>(`${this.apiUrl}/todos`);
  }

  /**
   * Obtener usuarios que tienen horarios para un día específico
   */
  getUsuariosConHorarioPorDia(diaSemana: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/usuarios-con-horario/dia/${diaSemana}`);
  }

  /**
   * Obtener un horario específico por ID
   */
  getHorarioById(horarioId: number): Observable<HorarioUsuario> {
    return this.http.get<HorarioUsuario>(`${this.apiUrl}/${horarioId}`);
  }

  /**
   * Verificar si un usuario tiene horarios configurados
   */
  usuarioTieneHorarios(usuarioId: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/usuario/${usuarioId}/tiene-horarios`);
  }

  /**
   * Obtener días de la semana disponibles
   */
  getDiasSemana(): Observable<DiaSemana[]> {
    // Devolvemos los días de la semana como datos estáticos
    const diasSemana: DiaSemana[] = [
      { id: 1, nombre: 'Lunes' },
      { id: 2, nombre: 'Martes' },
      { id: 3, nombre: 'Miércoles' },
      { id: 4, nombre: 'Jueves' },
      { id: 5, nombre: 'Viernes' },
      { id: 6, nombre: 'Sábado' },
      { id: 7, nombre: 'Domingo' }
    ];
    
    // Usamos Promise.resolve y convertimos a Observable
    return new Observable<DiaSemana[]>(observer => {
      observer.next(diasSemana);
      observer.complete();
    });
  }
}
