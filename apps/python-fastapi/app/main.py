import asyncio
import json
import os
import random
import signal
import sys
import time
import urllib.request
from urllib.error import HTTPError

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, PlainTextResponse
from opentelemetry import trace
from opentelemetry.trace import Status, StatusCode

from app.routers import lab

app = FastAPI(
    title="Formatio Failure Lab — Python/FastAPI (Stock OTel)",
    description="Lean Python ASGI microservice for Formatio OTel tracing, distributed cascades, and Failure Lab chaos scenarios.",
    version="3.0.0",
)

tracer = trace.get_tracer("failure-lab-python")
app.include_router(lab.router)


class NotFoundError(Exception):
    pass


# Ensure PID-1 SIGTERM exits through sys.exit(0) so OTel's atexit hook flushes final spans.
signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))


def _record_span_exception(exc: Exception) -> None:
    span = trace.get_current_span()
    span.record_exception(exc)
    span.set_status(Status(StatusCode.ERROR, str(exc)))


@app.exception_handler(NotFoundError)
async def handle_not_found(_request: Request, exc: NotFoundError):
    _record_span_exception(exc)
    return JSONResponse(
        status_code=404,
        content={"error": type(exc).__name__, "message": str(exc)},
    )


@app.exception_handler(Exception)
async def handle_generic_error(_request: Request, exc: Exception):
    _record_span_exception(exc)
    return JSONResponse(
        status_code=500,
        content={"error": type(exc).__name__, "message": str(exc)},
    )


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
        "framework": "Python / FastAPI (OTel auto-instrumented)",
        "status_url": "/api/lab/status",
        "routes": [
            "/healthz",
            "/ok",
            "/slow?ms=1500",
            "/exception",
            "/not-found/{id}",
            "/status-500",
            "/crash",
            "/downstream?path=/exception",
            "POST /charge",
            "/recommendations",
            "/loyalty[?healthy=1]",
            "/api/lab/scenarios/01-oom",
            "/api/lab/scenarios/02-hang",
            "/api/lab/scenarios/05-pool-lockup",
            "/api/lab/scenarios/07-asyncio-cpu-starvation?ms=5000",
        ],
    }


@app.get("/ok")
async def ok():
    with tracer.start_as_current_span("load dashboard"):
        for step in ("query users", "query orders", "render"):
            with tracer.start_as_current_span(step):
                await asyncio.sleep(0.005 + random.random() * 0.02)
    return PlainTextResponse("ok\n")


@app.get("/slow")
async def slow(ms: int = 1500):
    duration = ms if ms > 0 else 1500
    with tracer.start_as_current_span("slow work") as span:
        span.set_attribute("sleep.ms", duration)
        await asyncio.sleep(duration / 1000.0)
    return PlainTextResponse(f"slept {duration}ms\n")


@app.get("/exception")
async def exception():
    invoice = {"lines": []}
    return PlainTextResponse(str(invoice["total"]))


@app.get("/not-found/{user_id}")
async def not_found(user_id: str):
    raise NotFoundError(f"user {user_id} not found")


@app.get("/status-500")
async def status_500():
    trace.get_current_span().set_status(Status(StatusCode.ERROR, "upstream quota exhausted"))
    return PlainTextResponse("upstream quota exhausted\n", status_code=500)


@app.get("/crash")
async def crash(request: Request):
    ratio = len(request.query_params) / len(request.query_params)
    return PlainTextResponse(str(ratio))


@app.get("/downstream")
def downstream(path: str = "/exception"):
    base = os.environ.get("DOWNSTREAM_URL", "http://go-gin:8080")
    try:
        with urllib.request.urlopen(base + path, timeout=10) as response:
            return PlainTextResponse(f"downstream {base}{path} → {response.status}: {response.read().decode()}")
    except HTTPError as error:
        if error.code >= 500:
            trace.get_current_span().set_status(Status(StatusCode.ERROR, f"downstream answered {error.code}"))
        return PlainTextResponse(f"downstream {base}{path} → {error.code}: {error.read().decode()}", status_code=502)


@app.post("/charge")
async def charge(request: Request):
    """Scenario 17 payments worker: crashes with TypeError when amount is null from upstream."""
    payment = json.loads((await request.body()) or b"{}")
    with tracer.start_as_current_span("compute fees") as span:
        span.set_attribute("payment.currency", payment.get("currency", ""))
        fee = round(payment["amount"] * 0.029 + 0.30, 2)
    with tracer.start_as_current_span("capture payment"):
        await asyncio.sleep(0.01 + random.random() * 0.03)
    return JSONResponse(status_code=201, content={"status": "captured", "amount": payment["amount"], "fee": fee})


@app.get("/recommendations")
async def recommendations():
    with tracer.start_as_current_span("rank items"):
        await asyncio.sleep(0.01 + random.random() * 0.02)
    return [
        {"sku": "kb-01", "title": "Mechanical keyboard"},
        {"sku": "mouse-02", "title": "Wireless mouse"},
    ]


@app.get("/loyalty")
def loyalty(healthy: str = ""):
    """Scenario 18 widget: calls Go rates-db and returns 502 when upstream rates fails."""
    base = os.environ.get("GO_URL") or os.environ.get("DOWNSTREAM_URL") or "http://go-gin:8080"
    with tracer.start_as_current_span("load points"):
        points = 12840
    suffix = "?healthy=1" if healthy else ""
    try:
        with urllib.request.urlopen(f"{base}/internal/rates{suffix}", timeout=5) as response:
            rates = json.load(response)
    except HTTPError as error:
        trace.get_current_span().set_status(Status(StatusCode.ERROR, f"rates answered {error.code}"))
        return JSONResponse(status_code=502, content={"error": f"exchange rates unavailable ({error.code})"})
    return {"points": points, "value": round(points * 0.01 * rates["EUR"], 2), "currency": "EUR"}
