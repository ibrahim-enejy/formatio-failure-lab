import os
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from app.routers import lab

app = FastAPI(
    title="Formatio Failure Lab — Python/FastAPI",
    description="Multi-framework chaos lab for Formatio IDP, OpenTelemetry observability, built-in AI SRE, and Govern.",
    version="2.0.0",
)

app.include_router(lab.router)


@app.get("/healthz")
async def healthz():
    if os.getenv("SIMULATE_BAD_HEALTHCHECK") == "true":
        return JSONResponse(
            status_code=503,
            content={"status": "unhealthy", "reason": "SIMULATE_BAD_HEALTHCHECK=true"},
        )
    return {"status": "ok", "service": "python-fastapi"}


@app.get("/")
async def root():
    return {
        "lab": "Formatio Open-Source Failure Lab",
        "framework": "Python / FastAPI",
        "telemetry_url": "/api/lab/status",
        "scenarios": {
            "oom": "POST /api/lab/scenarios/01-oom",
            "pool_lockup": "POST /api/lab/scenarios/05-pool-lockup",
            "asyncio_starvation": "POST /api/lab/scenarios/07-asyncio-cpu-starvation?ms=5000",
        },
    }
