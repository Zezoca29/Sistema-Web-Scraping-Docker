import os
import time
from typing import List
from fastapi import FastAPI
from pydantic import BaseModel, AnyHttpUrl
from bs4 import BeautifulSoup
import requests
from sqlalchemy import text
from celery_app import celery_app
from metrics import ensure_metrics_server, scrape_total, scrape_success_total, scrape_fail_total, scrape_latency
from db import engine


# Inicia métrica HTTP server
ensure_metrics_server()

# FastAPI app for receiving scraping requests
app = FastAPI(title="Scraping Worker")

# Rate limit simples por processo (tokens/seg)
TOKENS_PER_SECOND = float(os.getenv("TASK_RATE_LIMIT_PER_WORKER", 1))
_last_request_ts = 0.0


def _rate_limit():
    global _last_request_ts
    now = time.time()
    min_interval = 1.0 / max(TOKENS_PER_SECOND, 0.001)
    elapsed = now - _last_request_ts
    if elapsed < min_interval:
        time.sleep(min_interval - elapsed)
    _last_request_ts = time.time()


class UrlBatch(BaseModel):
    urls: List[str]


def scrape_url(url: str) -> dict:
    """Scrape a single URL and return extracted data"""
    start_time = time.time()
    scrape_total.inc()
    
    try:
        _rate_limit()
        
        # Make HTTP request
        response = requests.get(url, timeout=30, headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        })
        
        duration_ms = int((time.time() - start_time) * 1000)
        
        # Parse HTML content
        title = None
        description = None
        
        if response.headers.get('content-type', '').startswith('text/html'):
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Extract title
            title_tag = soup.find('title')
            if title_tag:
                title = title_tag.get_text().strip()[:500]  # Limit length
            
            # Extract description from meta tag
            desc_tag = soup.find('meta', attrs={'name': 'description'})
            if desc_tag:
                description = desc_tag.get('content', '')[:1000]  # Limit length
        
        # Store in database
        with engine.begin() as conn:
            conn.exec_driver_sql(
                """
                INSERT INTO page_results (url, status_code, title, description, duration_ms, error)
                VALUES (%s, %s, %s, %s, %s, %s)
                """,
                (url, response.status_code, title, description, duration_ms, None)
            )
        
        scrape_success_total.inc()
        scrape_latency.observe(time.time() - start_time)
        
        return {
            "url": url,
            "status_code": response.status_code,
            "title": title,
            "description": description,
            "duration_ms": duration_ms,
            "error": None
        }
        
    except Exception as e:
        duration_ms = int((time.time() - start_time) * 1000)
        error_msg = str(e)[:500]  # Limit error message length
        
        # Store error in database
        try:
            with engine.begin() as conn:
                conn.exec_driver_sql(
                    """
                    INSERT INTO page_results (url, status_code, title, description, duration_ms, error)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    (url, None, None, None, duration_ms, error_msg)
                )
        except Exception as db_error:
            print(f"Failed to store error in database: {db_error}")
        
        scrape_fail_total.inc()
        scrape_latency.observe(time.time() - start_time)
        
        return {
            "url": url,
            "status_code": None,
            "title": None,
            "description": None,
            "duration_ms": duration_ms,
            "error": error_msg
        }


@app.get("/health")
def health():
    return {"status": "healthy", "service": "scraper-worker"}


@app.post("/enqueue")
def enqueue_urls(batch: UrlBatch):
    """Process a batch of URLs for scraping"""
    results = []
    
    for url in batch.urls:
        print(f"Processing URL: {url}")
        result = scrape_url(url)
        results.append(result)
    
    return {
        "processed": len(results),
        "results": results
    }


# Celery task for async processing (if needed)
@celery_app.task
def scrape_url_task(url: str):
    """Async task for scraping a single URL"""
    return scrape_url(url)
