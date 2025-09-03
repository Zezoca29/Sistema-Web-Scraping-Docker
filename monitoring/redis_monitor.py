#!/usr/bin/env python3
"""
Redis monitoring script for the distributed web scraping system
This script provides metrics about Redis queue status and performance
"""

import redis
import time
import json
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
import os

# Redis connection
REDIS_URL = os.getenv('REDIS_URL', 'redis://localhost:6379/0')
redis_client = redis.from_url(REDIS_URL)

def get_redis_metrics():
    """Collect Redis metrics for monitoring"""
    try:
        # Redis info
        info = redis_client.info()
        
        # Queue sizes (if using Redis for task queuing)
        queue_metrics = {
            'redis_connected_clients': info.get('connected_clients', 0),
            'redis_used_memory': info.get('used_memory', 0),
            'redis_used_memory_peak': info.get('used_memory_peak', 0),
            'redis_total_commands_processed': info.get('total_commands_processed', 0),
            'redis_keyspace_hits': info.get('keyspace_hits', 0),
            'redis_keyspace_misses': info.get('keyspace_misses', 0),
        }
        
        # Queue-specific metrics (if you implement Redis queues)
        try:
            # Example queue names - adjust based on your implementation
            queue_names = ['scraping:pending', 'scraping:processing', 'scraping:completed']
            for queue_name in queue_names:
                queue_length = redis_client.llen(queue_name)
                queue_metrics[f'queue_{queue_name.replace(":", "_")}_length'] = queue_length
        except Exception as e:
            print(f"Queue metrics error: {e}")
        
        return queue_metrics
    except Exception as e:
        print(f"Redis metrics error: {e}")
        return {}

def print_metrics():
    """Print current Redis metrics"""
    metrics = get_redis_metrics()
    print("Redis Metrics:")
    print("=" * 50)
    for key, value in metrics.items():
        print(f"{key}: {value}")
    print("=" * 50)

if __name__ == "__main__":
    while True:
        print_metrics()
        time.sleep(10)