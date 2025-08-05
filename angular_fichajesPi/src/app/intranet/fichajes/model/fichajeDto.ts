
export interface FichajeDto {
  id?: number
  diaDesde: string
  diaHasta: string
  horaDesde: string
  horaHasta: string
  hora: string
  dia: string
  origen: string | null
  tipo: string

  numeroUsuario: string
  nombreUsuario: string
  
  // Propiedad de relación (opcional para compatibilidad)
  usuario?: import('../../empleados/model/empleado').Empleado | null
  
  // Propiedades para zona horaria local
  horaLocal?: string
  diaLocal?: string
  horaDesdeLocal?: string
  horaHastaLocal?: string
}