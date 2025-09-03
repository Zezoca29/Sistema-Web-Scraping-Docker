# Load Testing Script - Demonstrates System Scalability
# This script shows how the system handles high load and concurrent requests

param(
    [int]$NumRequests = 10,
    [int]$BatchSize = 5,
    [int]$DelayBetweenBatches = 2
)

Write-Host "=== Load Testing - Demonstrating System Scalability ===" -ForegroundColor Green
Write-Host "Requests: $NumRequests | Batch Size: $BatchSize | Delay: ${DelayBetweenBatches}s" -ForegroundColor Cyan
Write-Host ""

# Predefined URLs for testing different scenarios
$testUrls = @(
    "https://httpbin.org/html",
    "https://httpbin.org/json", 
    "https://httpbin.org/xml",
    "https://example.com",
    "https://jsonplaceholder.typicode.com/posts/1",
    "https://jsonplaceholder.typicode.com/users/1",
    "https://httpbin.org/uuid",
    "https://httpbin.org/base64/SFRUUEJJTiBpcyBhd2Vzb21l",
    "https://httpbin.org/delay/1",
    "https://httpbin.org/status/200"
)

$successCount = 0
$errorCount = 0
$totalStartTime = Get-Date

Write-Host "Starting load test..." -ForegroundColor Yellow

for ($batch = 1; $batch -le [math]::Ceiling($NumRequests / $BatchSize); $batch++) {
    Write-Host "Processing Batch $batch..." -ForegroundColor Yellow
    
    $batchStartTime = Get-Date
    $urlsForBatch = @()
    
    # Select random URLs for this batch
    for ($i = 0; $i -lt $BatchSize -and (($batch - 1) * $BatchSize + $i) -lt $NumRequests; $i++) {
        $randomUrl = $testUrls | Get-Random
        $urlsForBatch += $randomUrl
    }
    
    $batchBody = @{
        urls = $urlsForBatch
    } | ConvertTo-Json
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/enqueue" -Method POST -ContentType "application/json" -Body $batchBody -TimeoutSec 30
        $batchEndTime = Get-Date
        $batchDuration = ($batchEndTime - $batchStartTime).TotalMilliseconds
        
        Write-Host "  ✓ Batch $batch completed: $($response.StatusCode) (${batchDuration}ms)" -ForegroundColor Green
        $successCount += $urlsForBatch.Count
        
        # Show enqueued URLs
        $responseData = $response.Content | ConvertFrom-Json
        Write-Host "    Enqueued $($responseData.enqueued) URLs" -ForegroundColor Cyan
        
    } catch {
        Write-Host "  ✗ Batch $batch failed: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount += $urlsForBatch.Count
    }
    
    # Delay between batches (except for the last one)
    if ($batch -lt [math]::Ceiling($NumRequests / $BatchSize)) {
        Start-Sleep -Seconds $DelayBetweenBatches
    }
}

$totalEndTime = Get-Date
$totalDuration = ($totalEndTime - $totalStartTime).TotalSeconds

Write-Host ""
Write-Host "=== Load Test Results ===" -ForegroundColor Green
Write-Host "Total Duration: $([math]::Round($totalDuration, 2)) seconds" -ForegroundColor White
Write-Host "Successful Requests: $successCount" -ForegroundColor Green
Write-Host "Failed Requests: $errorCount" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round(($successCount / ($successCount + $errorCount)) * 100, 2))%" -ForegroundColor Cyan
Write-Host "Average Throughput: $([math]::Round(($successCount + $errorCount) / $totalDuration, 2)) requests/second" -ForegroundColor Yellow

Write-Host ""
Write-Host "Waiting 15 seconds for processing to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Check final results
try {
    $resultsResponse = Invoke-WebRequest -Uri "http://localhost:8000/results?limit=100" -Method GET
    $results = $resultsResponse.Content | ConvertFrom-Json
    
    Write-Host ""
    Write-Host "=== Processing Results ===" -ForegroundColor Green
    Write-Host "Total Results in Database: $($results.items.Count)" -ForegroundColor Cyan
    
    $successfulScrapes = ($results.items | Where-Object { $_.status_code -eq 200 }).Count
    $failedScrapes = $results.items.Count - $successfulScrapes
    
    Write-Host "Successful Scrapes: $successfulScrapes" -ForegroundColor Green
    Write-Host "Failed Scrapes: $failedScrapes" -ForegroundColor Red
    
    if ($results.items.Count -gt 0) {
        $avgDuration = ($results.items | Measure-Object duration_ms -Average).Average
        Write-Host "Average Scraping Duration: $([math]::Round($avgDuration, 2))ms" -ForegroundColor Yellow
        
        # Show sample results
        Write-Host ""
        Write-Host "Sample Results (Last 5):" -ForegroundColor Cyan
        $results.items | Select-Object -First 5 | ForEach-Object {
            $status = if($_.status_code -eq 200) {"✓"} else {"✗"}
            Write-Host "  $status $($_.url) - $($_.title)" -ForegroundColor White
        }
    }
    
} catch {
    Write-Host "Error retrieving results: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Load test completed! Check monitoring dashboards for detailed metrics." -ForegroundColor Green