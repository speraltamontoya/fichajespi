import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';

export interface EstimacionDto {
  usuarioId: number;
  horasEstimadas: number;
  fecha: string;
}

@Injectable({
  providedIn: 'root'
})
export class EstimacionesService {
  private endPoint = environment.apiURL + '/api/estimaciones';

  constructor(private http: HttpClient) { }

  crearEstimacion(dto: EstimacionDto): Observable<any> {
    return this.http.post(this.endPoint, dto);
  }
}
