import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class DateUtilsService {

  /**
   * Convierte una fecha UTC (como string) a la zona horaria local del navegador
   * @param utcDateString Fecha en formato UTC (ej: "2025-07-30T15:30:00")
   * @returns Fecha formateada en zona horaria local
   */
  convertUtcToLocalString(utcDateString: string): string {
    const utcDate = new Date(utcDateString + 'Z'); // Agregar Z para indicar UTC
    return utcDate.toLocaleString();
  }

  /**
   * Convierte una fecha UTC a formato de solo hora local
   * @param utcDateString Fecha en formato UTC
   * @returns Hora formateada (HH:MM:SS)
   */
  convertUtcToLocalTime(utcDateString: string): string {
    const utcDate = new Date(utcDateString + 'Z');
    return utcDate.toLocaleTimeString();
  }

  /**
   * Convierte una fecha UTC a formato de solo fecha local
   * @param utcDateString Fecha en formato UTC
   * @returns Fecha formateada (DD/MM/YYYY)
   */
  convertUtcToLocalDate(utcDateString: string): string {
    const utcDate = new Date(utcDateString + 'Z');
    return utcDate.toLocaleDateString();
  }

  /**
   * Obtiene la fecha/hora actual en UTC como string
   * @returns Fecha UTC en formato ISO (sin Z final)
   */
  getCurrentUtcString(): string {
    const now = new Date();
    const year = now.getUTCFullYear();
    const month = String(now.getUTCMonth() + 1).padStart(2, '0');
    const day = String(now.getUTCDate()).padStart(2, '0');
    const hours = String(now.getUTCHours()).padStart(2, '0');
    const minutes = String(now.getUTCMinutes()).padStart(2, '0');
    const seconds = String(now.getUTCSeconds()).padStart(2, '0');
    return `${year}-${month}-${day}T${hours}:${minutes}:${seconds}`;
  }

  /**
   * Obtiene la zona horaria del usuario
   * @returns Nombre de la zona horaria (ej: "Europe/Madrid")
   */
  getUserTimezone(): string {
    return Intl.DateTimeFormat().resolvedOptions().timeZone;
  }
}
