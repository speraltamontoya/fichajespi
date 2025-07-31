import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'utcToLocal'
})
export class UtcToLocalPipe implements PipeTransform {

  /**
   * Convierte una fecha UTC a la zona horaria local del navegador
   * @param value Fecha en formato UTC (string)
   * @param format Formato de salida: 'full' | 'date' | 'time' | 'datetime'
   * @returns Fecha formateada en zona horaria local
   */
  transform(value: string, format: 'full' | 'date' | 'time' | 'datetime' = 'full'): string {
    if (!value) return '';

    // Si ya tiene 'UTC' en el string, extraer solo la parte de la fecha
    let cleanValue = value;
    if (value.includes(' UTC ')) {
      cleanValue = value.split(' UTC ')[0];
    }

    // Crear fecha UTC
    const utcDate = new Date(cleanValue + 'Z'); // Agregar Z para indicar UTC
    
    if (isNaN(utcDate.getTime())) {
      return value; // Si no es una fecha válida, devolver el valor original
    }

    switch (format) {
      case 'date':
        return utcDate.toLocaleDateString();
      case 'time':
        return utcDate.toLocaleTimeString();
      case 'datetime':
        return utcDate.toLocaleDateString() + ' ' + utcDate.toLocaleTimeString();
      case 'full':
      default:
        return utcDate.toLocaleString();
    }
  }
}
