from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI(
    title="${{ values.nombre }}",
    description="${{ values.descripcion }}",
    version="0.1.0",
)

@app.get("/health")
async def health_check():
    """Health check para Kubernetes liveness/readiness probe."""
    return JSONResponse(content={"status": "ok", "service": "${{ values.nombre }}"})

@app.get("/")
async def root():
    return {"message": "Hola desde ${{ values.nombre }} 🚀"}
