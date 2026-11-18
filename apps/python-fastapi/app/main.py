from fastapi import FastAPI
from app.routers import lab

app = FastAPI(
    title="Formatio Failure Lab — Python/FastAPI",
    description="Multi-framework architectural chaos lab for Formatio Autonomous SRE testing.",
    version="1.0.0",
)

app.include_router(lab.router)


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
