import os
from prometheus_client import Counter, Histogram, Gauge, start_http_server


WORKER_METRICS_PORT = int(os.getenv("WORKER_METRICS_PORT", 8001))


scrape_total = Counter("scrape_total", "Total de tentativas de scraping")
scrape_success_total = Counter("scrape_success_total", "Total de scrapes com sucesso")
scrape_fail_total = Counter("scrape_fail_total", "Total de scrapes com falha")
scrape_latency = Histogram("scrape_latency_seconds", "Latência por scraping")
rate_limiter_tokens = Gauge("rate_limiter_tokens", "Tokens disponíveis (simples)")


_started = False


def ensure_metrics_server():
    global _started
    if not _started:
        start_http_server(WORKER_METRICS_PORT)
        _started = True