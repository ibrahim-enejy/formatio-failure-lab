import asyncio
import os
import sys
import time
import psutil
from fastapi import APIRouter, HTTPException, Query

router = APIRouter(prefix="/api/lab", tags=["formatio-failure-lab"])

START_TIME = time.time()


@router.get("/status")
async def get_lab_status():
    """Health & Live System Telemetry Status"""
    process = psutil.Process(os.getpid())
    mem_info = process.memory_info()
    return {
        "status": "online",
        "app": "Formatio Failure Lab — Python/FastAPI Service",
        "runtime": {
            "python": sys.version.split()[0],
            "platform": sys.platform,
            "pid": os.getpid(),
            "uptime_seconds": int(time.time() - START_TIME),
        },
        "memory": {
            "rss_mb": round(mem_info.rss / 1024 / 1024, 2),
            "vms_mb": round(mem_info.vms / 1024 / 1024, 2),
        },
        "scenarios": {
            "01-heap-oom": "POST /api/lab/scenarios/01-oom",
            "05-postgres-pool-lockup": "POST /api/lab/scenarios/05-pool-lockup",
            "07-asyncio-cpu-starvation": "POST /api/lab/scenarios/07-asyncio-cpu-starvation",
        },
    }


@router.post("/scenarios/01-oom")
async def trigger_oom():
    """SABOTAGE: Unbounded RAM allocation causing cgroup OOM killer"""
    leak_list = []
    chunk_size = 10 * 1024 * 1024  # 10MB chunks
    try:
        while True:
            leak_list.append(bytearray(chunk_size))
    except MemoryError:
        raise HTTPException(status_code=500, detail="Out of Memory caught locally")


@router.post("/scenarios/07-asyncio-cpu-starvation")
async def trigger_asyncio_cpu_starvation(duration_ms: int = Query(5000, alias="ms")):
    """
    SABOTAGE: Synchronous CPU-bound computation inside an async def route.
    Freezes the asyncio event loop and starves all concurrent requests.
    """
    start = time.time()
    duration_sec = duration_ms / 1000.0
    while (time.time() - start) < duration_sec:
        # Busy loop starving asyncio event loop
        _ = [x**2 for x in range(1000)]
    return {
        "status": "resolved",
        "scenario": "07-asyncio-cpu-starvation",
        "blocked_ms": duration_ms,
        "message": f"Asyncio event loop was blocked synchronously for {duration_ms}ms.",
    }


@router.post("/scenarios/05-pool-lockup")
async def trigger_pool_lockup():
    """SABOTAGE: Simulated connection starvation holding worker sockets"""
    await asyncio.sleep(15)
    return {
        "status": "resolved",
        "scenario": "05-postgres-pool-lockup",
        "message": "Simulated slow dependency held socket for 15s.",
    }
