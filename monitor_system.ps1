# Distributed Web Scraping System Health Monitor
# This script checks the health of all system components

Write-Host "=== Sistema de Monitoramento do Web Scraping Distribuido ===" -ForegroundColor Green
Write-Host ""

# Function to check service health
function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$Url,
        [string]$ExpectedContent = ""
    )
    
    Write-Host "Verificando $ServiceName..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            if ($ExpectedContent -and $response.Content -notlike "*$ExpectedContent*") {
                Write-Host "   WARNING: $ServiceName respondendo mas conteudo inesperado" -ForegroundColor Orange
                return $false
            }
            Write-Host "   OK: $ServiceName funcionando (Status: $($response.StatusCode))" -ForegroundColor Green
            return $true
        } else {
            Write-Host "   ERRO: $ServiceName falha (Status: $($response.StatusCode))" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "   ERRO: $ServiceName nao acessivel - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Check all services
$services = @{
    "API" = "http://localhost:8000/health"
    "Prometheus" = "http://localhost:9090"
    "Grafana" = "http://localhost:3000"
}

$allHealthy = $true

foreach ($service in $services.GetEnumerator()) {
    $isHealthy = Test-ServiceHealth -ServiceName $service.Key -Url $service.Value
    $allHealthy = $allHealthy -and $isHealthy
}

Write-Host ""

# Check Docker containers
Write-Host "Verificando containers Docker..." -ForegroundColor Yellow
try {
    $containers = docker-compose ps
    Write-Host $containers
} catch {
    Write-Host "   ERRO: Erro ao verificar containers: $($_.Exception.Message)" -ForegroundColor Red
    $allHealthy = $false
}

Write-Host ""

# Check system metrics
Write-Host "Metricas do Sistema:" -ForegroundColor Cyan
try {
    $metricsResponse = Invoke-WebRequest -Uri "http://localhost:8000/metrics" -Method GET
    $metricsLines = $metricsResponse.Content -split "`n"
    
    # Extract key metrics
    $apiRequests = ($metricsLines | Where-Object { $_ -like "*api_requests_total*" } | Select-Object -First 1)
    $queueJobs = ($metricsLines | Where-Object { $_ -like "*queue_jobs_total*" } | Select-Object -First 1)
    
    if ($apiRequests) {
        Write-Host "   Dados: $apiRequests" -ForegroundColor White
    }
    if ($queueJobs) {
        Write-Host "   Dados: $queueJobs" -ForegroundColor White
    }
} catch {
    Write-Host "   ERRO: Nao foi possivel obter metricas" -ForegroundColor Red
}

Write-Host ""

# Summary
if ($allHealthy) {
    Write-Host "SUCCESS: Sistema totalmente operacional!" -ForegroundColor Green
    Write-Host "   Grafana: http://localhost:3000 (admin/admin)"
    Write-Host "   Prometheus: http://localhost:9090"
    Write-Host "   API: http://localhost:8000"
} else {
    Write-Host "WARNING: Alguns componentes apresentam problemas" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Para monitoramento continuo, acesse:" -ForegroundColor Cyan
Write-Host "   • Grafana Dashboard: http://localhost:3000" -ForegroundColor White
Write-Host "   • Prometheus Metrics: http://localhost:9090" -ForegroundColor White
Write-Host "   • API Health: http://localhost:8000/health" -ForegroundColor White
Write-Host "   • API Metrics: http://localhost:8000/metrics" -ForegroundColor White