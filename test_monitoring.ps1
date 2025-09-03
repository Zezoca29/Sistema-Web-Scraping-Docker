# Monitoring Setup and Verification Script
# This script helps set up and verify the monitoring stack

Write-Host "=== Monitoring Stack Setup and Verification ===" -ForegroundColor Green
Write-Host ""

# Function to test endpoint availability
function Test-Endpoint {
    param($url, $name, $timeout = 10)
    
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec $timeout -UseBasicParsing
        Write-Host "✓ $name is accessible: $($response.StatusCode)" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ $name is not accessible: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Test all monitoring endpoints
Write-Host "1. Testing Monitoring Stack Availability..." -ForegroundColor Yellow

$endpoints = @(
    @{url="http://localhost:8000/health"; name="API Health"},
    @{url="http://localhost:8000/docs"; name="API Documentation"},
    @{url="http://localhost:9090"; name="Prometheus"},
    @{url="http://localhost:9090/targets"; name="Prometheus Targets"},
    @{url="http://localhost:3000"; name="Grafana"}
)

$allHealthy = $true
foreach ($endpoint in $endpoints) {
    $result = Test-Endpoint -url $endpoint.url -name $endpoint.name
    $allHealthy = $allHealthy -and $result
}

Write-Host ""

if ($allHealthy) {
    Write-Host "✓ All monitoring services are healthy!" -ForegroundColor Green
} else {
    Write-Host "⚠ Some monitoring services are not available. Check Docker containers." -ForegroundColor Yellow
    Write-Host "Run: docker-compose ps" -ForegroundColor Cyan
}

Write-Host ""

# Test metrics endpoints
Write-Host "2. Testing Metrics Collection..." -ForegroundColor Yellow

try {
    # Generate some API activity for metrics
    $testBody = @{
        urls = @("https://httpbin.org/json", "https://example.com")
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri "http://localhost:8000/enqueue" -Method POST -ContentType "application/json" -Body $testBody
    Write-Host "✓ Generated API activity for metrics collection" -ForegroundColor Green
    
    # Check if metrics endpoint exists
    try {
        $metricsResponse = Invoke-WebRequest -Uri "http://localhost:8000/metrics" -UseBasicParsing
        Write-Host "✓ API metrics endpoint is working" -ForegroundColor Green
    } catch {
        Write-Host "⚠ API metrics endpoint not available (this is expected in current setup)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "✗ Error generating metrics activity: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Prometheus queries to test
Write-Host "3. Testing Prometheus Metrics..." -ForegroundColor Yellow

$prometheusQueries = @(
    "up",
    "prometheus_notifications_total",
    "prometheus_config_last_reload_successful"
)

foreach ($query in $prometheusQueries) {
    try {
        $queryUrl = "http://localhost:9090/api/v1/query?query=$query"
        $response = Invoke-WebRequest -Uri $queryUrl -UseBasicParsing
        $data = $response.Content | ConvertFrom-Json
        
        if ($data.status -eq "success") {
            Write-Host "✓ Prometheus query '$query' successful" -ForegroundColor Green
        } else {
            Write-Host "⚠ Prometheus query '$query' returned: $($data.status)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ Prometheus query '$query' failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Generate monitoring dashboard URLs
Write-Host "=== MONITORING DASHBOARD ACCESS ===" -ForegroundColor Green
Write-Host ""

Write-Host "📊 Grafana Dashboard:" -ForegroundColor Cyan
Write-Host "   URL: http://localhost:3000" -ForegroundColor White
Write-Host "   Default Login: admin / admin" -ForegroundColor Gray
Write-Host ""

Write-Host "📈 Prometheus Metrics:" -ForegroundColor Cyan  
Write-Host "   URL: http://localhost:9090" -ForegroundColor White
Write-Host "   Targets: http://localhost:9090/targets" -ForegroundColor Gray
Write-Host ""

Write-Host "🔌 API Documentation:" -ForegroundColor Cyan
Write-Host "   URL: http://localhost:8000/docs" -ForegroundColor White
Write-Host "   Health: http://localhost:8000/health" -ForegroundColor Gray
Write-Host ""

Write-Host "📋 API Results:" -ForegroundColor Cyan
Write-Host "   URL: http://localhost:8000/results" -ForegroundColor White
Write-Host ""

# Grafana setup instructions
Write-Host "=== GRAFANA SETUP INSTRUCTIONS ===" -ForegroundColor Green
Write-Host ""
Write-Host "1. Open Grafana: http://localhost:3000" -ForegroundColor Yellow
Write-Host "2. Login with admin/admin (change password when prompted)" -ForegroundColor Yellow
Write-Host "3. Add Prometheus as data source:" -ForegroundColor Yellow
Write-Host "   - Go to Configuration > Data Sources" -ForegroundColor White
Write-Host "   - Add new data source > Prometheus" -ForegroundColor White
Write-Host "   - URL: http://prometheus:9090" -ForegroundColor White
Write-Host "   - Click 'Save & Test'" -ForegroundColor White
Write-Host ""
Write-Host "4. Create dashboard with these metrics:" -ForegroundColor Yellow
Write-Host "   - API request rate: rate(api_requests_total[5m])" -ForegroundColor White
Write-Host "   - Queue jobs: queue_jobs_total" -ForegroundColor White
Write-Host "   - Request latency: api_request_latency" -ForegroundColor White
Write-Host "   - System uptime: up" -ForegroundColor White

Write-Host ""

# Performance baseline
Write-Host "=== PERFORMANCE BASELINE ===" -ForegroundColor Green
Write-Host ""

try {
    $baselineStart = Get-Date
    
    # Run a baseline performance test
    $baselineBody = @{
        urls = @(
            "https://httpbin.org/html",
            "https://httpbin.org/json", 
            "https://example.com"
        )
    } | ConvertTo-Json
    
    $baselineResponse = Invoke-WebRequest -Uri "http://localhost:8000/enqueue" -Method POST -ContentType "application/json" -Body $baselineBody
    $baselineEnd = Get-Date
    $baselineDuration = ($baselineEnd - $baselineStart).TotalMilliseconds
    
    Write-Host "Baseline Performance Test:" -ForegroundColor Cyan
    Write-Host "  Request Duration: $([math]::Round($baselineDuration, 2))ms" -ForegroundColor White
    Write-Host "  URLs Enqueued: 3" -ForegroundColor White
    Write-Host "  Response Code: $($baselineResponse.StatusCode)" -ForegroundColor White
    
    # Wait and check processing
    Write-Host ""
    Write-Host "Checking processing results..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    $resultsResponse = Invoke-WebRequest -Uri "http://localhost:8000/results?limit=10" -Method GET
    $results = $resultsResponse.Content | ConvertFrom-Json
    
    if ($results.items.Count -gt 0) {
        $avgProcessingTime = ($results.items | Where-Object { $_.duration_ms } | Measure-Object duration_ms -Average).Average
        Write-Host "  Average Processing Time: $([math]::Round($avgProcessingTime, 2))ms per URL" -ForegroundColor White
        Write-Host "  Success Rate: $([math]::Round((($results.items | Where-Object { $_.status_code -eq 200 }).Count / $results.items.Count) * 100, 2))%" -ForegroundColor White
    }
    
} catch {
    Write-Host "Error running baseline test: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== MONITORING VERIFICATION COMPLETE ===" -ForegroundColor Green
Write-Host "The monitoring stack is ready for tracking system performance!" -ForegroundColor Cyan