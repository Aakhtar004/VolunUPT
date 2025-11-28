from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
from jinja2 import Environment, FileSystemLoader
from weasyprint import HTML
from io import BytesIO
from fastapi.responses import StreamingResponse
from datetime import datetime

app = FastAPI()

# --- MODELOS PARA CERTIFICADO (Endpoint 1) ---
class DatosCertificado(BaseModel):
    nombre_completo: str
    escuela: str
    nombre_campana: str
    horas: int
    codigo_verificacion: str

# --- MODELOS PARA REPORTE (Endpoint 2) ---
class Actividad(BaseModel):
    id: int
    nombre: str

class Inscrito(BaseModel):
    nombre: str
    codigo: str
    asistencias: List[int] # Lista de IDs de actividades asistidas

class DatosReporte(BaseModel):
    tituloEvento: str
    actividades: List[Actividad]
    inscritos: List[Inscrito]

# Configuración Jinja2
env = Environment(loader=FileSystemLoader('templates'))

# --- ENDPOINT 1: CERTIFICADO INDIVIDUAL ---
@app.post("/generar-certificado")
async def generar_pdf_certificado(datos: DatosCertificado):
    try:
        template = env.get_template('certificate.html')
        html_content = template.render(
            nombre_completo=datos.nombre_completo,
            escuela=datos.escuela,
            nombre_campana=datos.nombre_campana,
            horas=datos.horas,
            codigo_verificacion=datos.codigo_verificacion,
            fecha=datetime.now().strftime("%d/%m/%Y")
        )
        pdf_file = BytesIO()
        HTML(string=html_content).write_pdf(pdf_file)
        pdf_file.seek(0)
        return StreamingResponse(pdf_file, media_type="application/pdf", headers={"Content-Disposition": "attachment; filename=certificado.pdf"})
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# --- ENDPOINT 2: REPORTE DE ASISTENCIA (NUEVO) ---
@app.post("/generar-reporte")
async def generar_pdf_reporte(datos: DatosReporte):
    try:
        template = env.get_template('report.html')
        
        # Renderizamos pasando todos los datos complejos
        html_content = template.render(
            tituloEvento=datos.tituloEvento,
            actividades=datos.actividades,
            inscritos=datos.inscritos,
            fecha_generacion=datetime.now().strftime("%d/%m/%Y %H:%M")
        )

        pdf_file = BytesIO()
        # Generar PDF (Horizontal se define en el CSS @page)
        HTML(string=html_content).write_pdf(pdf_file)
        pdf_file.seek(0)

        return StreamingResponse(
            pdf_file, 
            media_type="application/pdf", 
            headers={"Content-Disposition": f"attachment; filename=reporte_{datos.tituloEvento}.pdf"}
        )

    except Exception as e:
        print(f"Error reporte: {e}")
        raise HTTPException(status_code=500, detail=str(e))