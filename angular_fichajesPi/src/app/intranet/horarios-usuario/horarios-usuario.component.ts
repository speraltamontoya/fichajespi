import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { HorarioUsuarioService, HorarioUsuario, DiaSemana, TurnoDTO, Timezone } from '../../shared/services/horario-usuario.service';
import { EmpleadosService } from '../empleados/service/empleados.service';
import { EmpleadoDto } from '../empleados/model/empleadoDto';

@Component({
  selector: 'app-horarios-usuario',
  templateUrl: './horarios-usuario.component.html',
  styleUrls: ['./horarios-usuario.component.css']
})
export class HorariosUsuarioComponent implements OnInit {
  
  usuarios: any[] = [];
  diasSemana: DiaSemana[] = [];
  timezones: Timezone[] = [];
  horarios: HorarioUsuario[] = [];
  
  usuarioSeleccionado: string | null = null;
  diaSeleccionado: number | null = null;
  timezoneSeleccionado: string = 'Europe/Madrid'; // Default timezone
  
  horarioForm: FormGroup;
  isLoading = false;
  isEditMode = false;

  constructor(
    private fb: FormBuilder,
    private horarioService: HorarioUsuarioService,
    private empleadosService: EmpleadosService,
    private cdr: ChangeDetectorRef
  ) {
    this.horarioForm = this.fb.group({
      turnos: this.fb.array([])
    });
  }

  ngOnInit(): void {
    this.loadUsuarios();
    this.loadDiasSemana();
    this.loadTimezones();
  }

  /**
   * Cuando el usuario seleccionado cambia
   */
  onUsuarioSeleccionado(event: Event): void {
    const target = event.target as HTMLSelectElement;
    const usuarioId = target.value || null;
    this.usuarioSeleccionado = usuarioId;
    this.diaSeleccionado = null;
    this.horarios = [];
    this.resetForm();
    if (usuarioId) {
      this.loadHorariosUsuario();
    }
  }

  /**
   * TrackBy function para optimizar ngFor
   */
  trackByUsuarioId(index: number, usuario: any): any {
    return usuario ? usuario.id : index;
  }

  /**
   * Cargar usuarios disponibles
   */
  loadUsuarios(): void {
    // Crear DTO vacío como antes
    const emptyDto: EmpleadoDto = {
      email: '',
      numero: '',
      nombreEmpleado: '',
      dni: '',
      diasVacacionesDesde: null,
      diasVacacionesHasta: null,
      horasGeneradasDesde: null,
      horasGeneradasHasta: null,
      enVacaciones: null,
      deBaja: null,
      working: null
    };
    
    this.empleadosService.getElements(emptyDto, 0, 100, 'id', true).subscribe({
      next: (response: any) => {
        if (response && response.content && Array.isArray(response.content)) {
          this.usuarios = response.content;
          this.cdr.markForCheck();
          this.cdr.detectChanges();
        }
      },
      error: (error: any) => {
        console.error('Error al cargar usuarios:', error);
      }
    });
  }

  /**
   * Cargar días de la semana
   */
  loadDiasSemana(): void {
    // Datos estáticos de días de la semana
    this.diasSemana = [
      { id: 1, nombre: 'Lunes' },
      { id: 2, nombre: 'Martes' },
      { id: 3, nombre: 'Miércoles' },
      { id: 4, nombre: 'Jueves' },
      { id: 5, nombre: 'Viernes' },
      { id: 6, nombre: 'Sábado' },
      { id: 7, nombre: 'Domingo' }
    ];
  }

  /**
   * Cargar zonas horarias disponibles
   */
  loadTimezones(): void {
    this.horarioService.getTimezones().subscribe({
      next: (timezones: Timezone[]) => {
        this.timezones = timezones;
        this.cdr.markForCheck();
      },
      error: (error: any) => {
        console.error('Error al cargar zonas horarias:', error);
      }
    });
  }

  /**
   * Seleccionar día de la semana
   */
  onDiaSeleccionado(event: Event): void {
    const target = event.target as HTMLSelectElement;
    const diaSemana = +target.value;
    this.diaSeleccionado = diaSemana || null;
    if (this.usuarioSeleccionado) {
      this.loadHorariosDia();
    }
  }

  /**
   * Cargar todos los horarios del usuario
   */
  loadHorariosUsuario(): void {
    if (!this.usuarioSeleccionado) return;
    
    const usuarioId = parseInt(this.usuarioSeleccionado, 10);
    this.isLoading = true;
    this.horarioService.getHorariosByUsuario(usuarioId).subscribe({
      next: (horarios: any) => {
        this.horarios = horarios;
        this.isLoading = false;
      },
      error: (error: any) => {
        console.error('Error al cargar horarios del usuario');
        this.isLoading = false;
      }
    });
  }

  /**
   * Cargar horarios para el día seleccionado
   */
  loadHorariosDia(): void {
    if (!this.usuarioSeleccionado || !this.diaSeleccionado) return;
    
    const usuarioId = parseInt(this.usuarioSeleccionado, 10);
    this.isLoading = true;
    this.horarioService.getHorariosByUsuarioYDia(usuarioId, this.diaSeleccionado).subscribe({
      next: (horarios: any) => {
        this.setupFormConHorarios(horarios);
        this.isEditMode = horarios.length > 0;
        this.isLoading = false;
      },
      error: (error: any) => {
        console.error('Error al cargar horarios del día');
        this.setupFormVacio();
        this.isEditMode = false;
        this.isLoading = false;
      }
    });
  }

  /**
   * Configurar formulario con horarios existentes
   */
  setupFormConHorarios(horarios: HorarioUsuario[]): void {
    const turnosArray = this.fb.array([]);
    
    // Si hay horarios, usar el timezone del primer horario
    if (horarios.length > 0 && horarios[0].timezone) {
      this.timezoneSeleccionado = horarios[0].timezone;
    }
    
    horarios.forEach(horario => {
      turnosArray.push(this.fb.group({
        turnoNumero: [horario.turnoNumero, Validators.required],
        horaInicio: [horario.horaInicio, Validators.required],
        horaFin: [horario.horaFin, Validators.required],
        descripcion: [horario.descripcion || '']
      }));
    });
    
    this.horarioForm.setControl('turnos', turnosArray);
  }

  /**
   * Configurar formulario vacío
   */
  setupFormVacio(): void {
    this.horarioForm.setControl('turnos', this.fb.array([]));
    this.addTurno(); // Agregar un turno por defecto
  }

  /**
   * Obtener FormArray de turnos
   */
  get turnos(): FormArray {
    return this.horarioForm.get('turnos') as FormArray;
  }

  /**
   * Agregar nuevo turno
   */
  addTurno(): void {
    const nuevoTurno = this.fb.group({
      turnoNumero: [this.turnos.length + 1, Validators.required],
      horaInicio: ['', Validators.required],
      horaFin: ['', Validators.required],
      descripcion: ['']
    });
    
    this.turnos.push(nuevoTurno);
  }

  /**
   * Eliminar turno
   */
  removeTurno(index: number): void {
    if (this.turnos.length > 1) {
      this.turnos.removeAt(index);
      this.actualizarNumerosTurnos();
    }
  }

  /**
   * Actualizar números de turnos después de eliminación
   */
  actualizarNumerosTurnos(): void {
    this.turnos.controls.forEach((control: any, index: number) => {
      control.patchValue({ turnoNumero: index + 1 });
    });
  }

  /**
   * Guardar horarios
   */
  saveHorarios(): void {
    if (!this.usuarioSeleccionado || !this.diaSeleccionado) {
      return;
    }

    if (this.horarioForm.invalid) {
      return;
    }

    const turnos: TurnoDTO[] = this.turnos.value;
    
    // Validar horarios
    if (!this.validarHorarios(turnos)) {
      return;
    }

    const usuarioId = parseInt(this.usuarioSeleccionado, 10);
    const createUpdateDTO = {
      usuarioId: usuarioId,
      diaSemana: this.diaSeleccionado,
      turnos: turnos,
      timezone: this.timezoneSeleccionado
    };

    this.isLoading = true;
    this.horarioService.saveHorariosUsuarioDia(usuarioId, this.diaSeleccionado, createUpdateDTO).subscribe({
      next: (response: any) => {
        this.loadHorariosUsuario();
        this.loadHorariosDia();
        this.isLoading = false;
      },
      error: (error: any) => {
        console.error('Error al guardar horarios');
        this.isLoading = false;
      }
    });
  }

  /**
   * Validar que los horarios sean correctos
   */
  validarHorarios(turnos: TurnoDTO[]): boolean {
    for (let i = 0; i < turnos.length; i++) {
      const turno = turnos[i];
      
      // Validar que hora inicio sea menor que hora fin
      if (turno.horaInicio >= turno.horaFin) {
        return false;
      }
      
      // Validar solapamiento con otros turnos
      for (let j = i + 1; j < turnos.length; j++) {
        const otroTurno = turnos[j];
        if (this.turnosSeSuperponen(turno, otroTurno)) {
          return false;
        }
      }
    }
    return true;
  }

  /**
   * Verificar si dos turnos se superponen
   */
  turnosSeSuperponen(turno1: TurnoDTO, turno2: TurnoDTO): boolean {
    return turno1.horaInicio < turno2.horaFin && turno2.horaInicio < turno1.horaFin;
  }

  /**
   * Resetear formulario
   */
  resetForm(): void {
    this.horarioForm.reset();
    this.setupFormVacio();
    this.isEditMode = false;
    this.timezoneSeleccionado = 'Europe/Madrid'; // Reset a timezone por defecto
  }

  /**
   * Obtener nombre del día por ID
   */
  getNombreDia(diaSemana: number | null): string {
    if (diaSemana === null) return '';
    const dia = this.diasSemana.find(d => d.id === diaSemana);
    return dia ? dia.nombre : 'Desconocido';
  }

  /**
   * Obtener descripción del timezone
   */
  getTimezoneDescription(timezoneId: string): string {
    const timezone = this.timezones.find(tz => tz.id === timezoneId);
    return timezone ? timezone.descripcion : timezoneId;
  }

  /**
   * Obtener horarios agrupados por día
   */
  getHorariosAgrupadosPorDia(): any[] {
    const grupos: any[] = [];
    
    this.diasSemana.forEach(dia => {
      const horariosDelDia = this.horarios.filter(h => h.diaSemana === dia.id);
      if (horariosDelDia.length > 0) {
        grupos.push({
          dia: dia,
          horarios: horariosDelDia.sort((a, b) => a.turnoNumero - b.turnoNumero)
        });
      }
    });
    
    return grupos;
  }
}
