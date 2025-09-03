import os
from celery import Celery


CELERY_BROKER_URL = os.getenv("CELERY_BROKER_URL")
CELERY_RESULT_BACKEND = os.getenv("CELERY_RESULT_BACKEND")


celery_app = Celery(
"scraper",
broker=CELERY_BROKER_URL,
backend=CELERY_RESULT_BACKEND,
)


celery_app.conf.update(
task_acks_late=True,
worker_prefetch_multiplier=1,
task_time_limit=60,
)