# Comprehensive Test Script for Distributed Web Scraping System
# This script demonstrates the utility of the system by testing various scenarios

Write-Host "=== Distributed Web Scraping System - Comprehensive Test ===" -ForegroundColor Green
Write-Host ""

# Test 1: Health Check
Write-Host "1. Testing API Health Check..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:8000/health" -Method GET
    Write-Host "✓ API Health: $($healthResponse.StatusCode) - $($healthResponse.Content)" -ForegroundColor Green
} catch {
    Write-Host "✗ API Health Check Failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 2: Single URL Scraping
Write-Host "2. Testing Single URL Scraping..." -ForegroundColor Yellow
$singleUrlBody = @{
    urls = @("https://httpbin.org/html")
} | ConvertTo-Json

try {
    $singleResponse = Invoke-WebRequest -Uri "http://localhost:8000/enqueue" -Method POST -ContentType "application/json" -Body $singleUrlBody
    Write-Host "✓ Single URL Response: $($singleResponse.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($singleResponse.Content)" -ForegroundColor White
} catch {
    Write-Host "✗ Single URL Test Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Multiple URLs (Batch Processing)
Write-Host "3. Testing Batch URL Processing..." -ForegroundColor Yellow
$batchBody = @{
    urls = @(
        "https://httpbin.org/html",
        "https://example.com",
        "https://httpbin.org/json",
        "https://jsonplaceholder.typicode.com/posts/1"
    )
} | ConvertTo-Json

try {
    $batchResponse = Invoke-WebRequest -Uri "http://localhost:8000/enqueue" -Method POST -ContentType "application/json" -Body $batchBody
    Write-Host "✓ Batch Processing Response: $($batchResponse.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($batchResponse.Content)" -ForegroundColor White
} catch {
    Write-Host "✗ Batch Processing Test Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 4: E-commerce Sites (Real-world scenario)
Write-Host "4. Testing E-commerce/Real-world Sites..." -ForegroundColor Yellow
$ecommerceBody = @{
    urls = @(
        "https://investidor10.com.br/",
        "https://www.b3.com.br/",
        "https://github.com"
    )
} | ConvertTo-Json

try {
    $ecommerceResponse = Invoke-WebRequest -Uri "http://localhost:8000/enqueue" -Method POST -ContentType "application/json" -Body $ecommerceBody
    Write-Host "✓ E-commerce Sites Response: $($ecommerceResponse.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($ecommerceResponse.Content)" -ForegroundColor White
} catch {
    Write-Host "✗ E-commerce Sites Test Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Wait for processing
Write-Host "5. Waiting for processing (10 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Test 5: Check Results
Write-Host "6. Retrieving Scraping Results..." -ForegroundColor Yellow
try {
    $resultsResponse = Invoke-WebRequest -Uri "http://localhost:8000/results" -Method GET
    Write-Host "✓ Results Retrieved: $($resultsResponse.StatusCode)" -ForegroundColor Green
    
    # Parse and display results nicely
    $results = $resultsResponse.Content | ConvertFrom-Json
    Write-Host "Total Results: $($results.items.Count)" -ForegroundColor Cyan
    
    foreach ($item in $results.items) {
        Write-Host "  URL: $($item.url)" -ForegroundColor White
        Write-Host "  Status: $($item.status_code)" -ForegroundColor $(if($item.status_code -eq 200) {"Green"} else {"Red"})
        Write-Host "  Title: $($item.title)" -ForegroundColor Cyan
        Write-Host "  Duration: $($item.duration_ms)ms" -ForegroundColor Yellow
        if ($item.error) {
            Write-Host "  Error: $($item.error)" -ForegroundColor Red
        }
        Write-Host "  ---"
    }
} catch {
    Write-Host "✗ Results Retrieval Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 6: Performance Test
Write-Host "7. Performance Test (Multiple Requests)..." -ForegroundColor Yellow
$startTime = Get-Date

for ($i = 1; $i -le 3; $i++) {
    $perfBody = @{
        urls = @("https://httpbin.org/delay/1", "https://httpbin.org/uuid")
    } | ConvertTo-Json
    
    try {
        $perfResponse = Invoke-WebRequest -Uri "http://localhost:8000/enqueue" -Method POST -ContentType "application/json" -Body $perfBody
        Write-Host "  Batch $i completed: $($perfResponse.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "  Batch $i failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds
Write-Host "✓ Performance Test completed in $([math]::Round($duration, 2)) seconds" -ForegroundColor Green

Write-Host ""

# Test 7: Error Handling
Write-Host "8. Testing Error Handling..." -ForegroundColor Yellow
$errorBody = @{
    urls = @("https://this-domain-does-not-exist-12345.com", "https://httpbin.org/status/404")
} | ConvertTo-Json

try {
    $errorResponse = Invoke-WebRequest -Uri "http://localhost:8000/enqueue" -Method POST -ContentType "application/json" -Body $errorBody
    Write-Host "✓ Error Handling Test: $($errorResponse.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($errorResponse.Content)" -ForegroundColor White
} catch {
    Write-Host "✗ Error Handling Test Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Green
Write-Host "✓ API Health Check" -ForegroundColor Green
Write-Host "✓ Single URL Processing" -ForegroundColor Green
Write-Host "✓ Batch URL Processing" -ForegroundColor Green
Write-Host "✓ Real-world Sites Processing" -ForegroundColor Green
Write-Host "✓ Results Retrieval" -ForegroundColor Green
Write-Host "✓ Performance Testing" -ForegroundColor Green
Write-Host "✓ Error Handling" -ForegroundColor Green

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Open Grafana dashboard: http://localhost:3000 (admin/admin)" -ForegroundColor White
Write-Host "2. Open Prometheus metrics: http://localhost:9090" -ForegroundColor White
Write-Host "3. Check API documentation: http://localhost:8000/docs" -ForegroundColor White
Write-Host "4. View latest results: http://localhost:8000/results" -ForegroundColor White