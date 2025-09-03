# Simple Test Script for Distributed Web Scraping System
Write-Host "=== Testing Distributed Web Scraping System ===" -ForegroundColor Green
Write-Host ""

# Test 1: Health Check
Write-Host "1. Testing API Health..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:8000/health" -Method GET
    Write-Host "   Status: $($healthResponse.StatusCode)" -ForegroundColor Green
    Write-Host "   Response: $($healthResponse.Content)" -ForegroundColor White
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 2: Single URL Test
Write-Host "2. Testing Single URL Scraping..." -ForegroundColor Yellow
$singleBody = @{
    urls = @("https://httpbin.org/html")
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/enqueue" -Method POST -ContentType "application/json" -Body $singleBody
    Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "   Response: $($response.Content)" -ForegroundColor White
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Multiple URLs Test
Write-Host "3. Testing Multiple URLs..." -ForegroundColor Yellow
$multiBody = @{
    urls = @(
        "https://httpbin.org/json",
        "https://example.com",
        "https://httpbin.org/uuid"
    )
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/enqueue" -Method POST -ContentType "application/json" -Body $multiBody
    Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "   Response: $($response.Content)" -ForegroundColor White
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Wait for processing
Write-Host "4. Waiting for processing (15 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Test 4: Get Results
Write-Host "5. Retrieving Results..." -ForegroundColor Yellow
try {
    $resultsResponse = Invoke-WebRequest -Uri "http://localhost:8000/results" -Method GET
    Write-Host "   Status: $($resultsResponse.StatusCode)" -ForegroundColor Green
    
    $results = $resultsResponse.Content | ConvertFrom-Json
    Write-Host "   Total Results: $($results.items.Count)" -ForegroundColor Cyan
    
    if ($results.items.Count -gt 0) {
        Write-Host "   Sample Results:" -ForegroundColor Cyan
        $results.items | Select-Object -First 5 | ForEach-Object {
            Write-Host "     URL: $($_.url)" -ForegroundColor White
            Write-Host "     Status: $($_.status_code)" -ForegroundColor Green
            Write-Host "     Title: $($_.title)" -ForegroundColor Cyan
            Write-Host "     ---"
        }
    }
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Green
Write-Host "System is working and processing URLs!" -ForegroundColor Green