import os
import time
from contextlib import asynccontextmanager
from typing import List
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, AnyHttpUrl
import requests
from sqlalchemy import create_engine, text

try:
    from metrics import router as metrics_router, api_requests_total, queue_jobs_total, api_request_latency
except ImportError as e:
    print(f"Warning: Could not import metrics: {e}")
    # Create mock objects to prevent startup failure
    from fastapi import APIRouter
    
    class MockCounter:
        def labels(self, **kwargs):
            return self
        def inc(self, value=1):
            pass
    
    class MockHistogram:
        def observe(self, value):
            pass
    
    metrics_router = APIRouter()
    api_requests_total = MockCounter()
    queue_jobs_total = MockCounter()
    api_request_latency = MockHistogram()


CELERY_ENQUEUE_URL = "http://worker:5555/enqueue" # endpoint simples no worker (ver abaixo)
DATABASE_URL = os.getenv("DATABASE_URL")


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    engine = create_engine(DATABASE_URL, pool_pre_ping=True)
    app.state.engine = engine
    
    # cria tabela mínima se não existir
    with engine.begin() as conn:
        conn.exec_driver_sql(
            """
            CREATE TABLE IF NOT EXISTS page_results (
            id SERIAL PRIMARY KEY,
            url TEXT NOT NULL,
            status_code INT,
            title TEXT,
            description TEXT,
            duration_ms INT,
            error TEXT,
            fetched_at TIMESTAMP DEFAULT NOW()
            );
            """
        )
    
    yield
    
    # Shutdown
    engine.dispose()


app = FastAPI(title="Scraping Scheduler API", lifespan=lifespan)
app.include_router(metrics_router)


class UrlBatch(BaseModel):
    urls: List[AnyHttpUrl]


@app.get("/health")
def health():
    return {"ok": True}


@app.post("/enqueue")
def enqueue(batch: UrlBatch):
    start = time.time()
    try:
        # Convert URLs to strings for JSON serialization
        batch_data = {"urls": [str(url) for url in batch.urls]}
        # Send to worker for processing
        r = requests.post(CELERY_ENQUEUE_URL, json=batch_data, timeout=30)
        r.raise_for_status()
        print(f"Successfully processed URLs: {batch_data['urls']}")
    except Exception as e:
        api_requests_total.labels(path="/enqueue", method="POST", status="500").inc()
        raise HTTPException(status_code=500, detail=str(e))

    queue_jobs_total.inc(len(batch.urls))
    api_requests_total.labels(path="/enqueue", method="POST", status="200").inc()
    api_request_latency.observe(time.time() - start)
    return {"enqueued": len(batch.urls), "urls": [str(url) for url in batch.urls]}


@app.get("/results")
def results(limit: int = 50):
    with app.state.engine.begin() as conn:
        rows = conn.exec_driver_sql(
            "SELECT id, url, status_code, title, description, duration_ms, error, fetched_at FROM page_results ORDER BY fetched_at DESC LIMIT %s",
            (limit,),
        ).mappings().all()
    api_requests_total.labels(path="/results", method="GET", status="200").inc()
    return {"items": list(rows)}