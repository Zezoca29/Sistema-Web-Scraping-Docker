from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from fastapi import APIRouter, Response


router = APIRouter()


api_requests_total = Counter("api_requests_total", "Total de requisições na API", ["path", "method", "status"])
queue_jobs_total = Counter("queue_jobs_total", "Total de URLs enfileiradas")
api_request_latency = Histogram("api_request_latency_seconds", "Latência de requisições da API")
worker_replicas = Gauge("worker_replicas", "Workers desejados (simulados via compose)")


@router.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)