# Quick Access to Monitoring Dashboards
Write-Host "=== Acesso Rapido ao Monitoramento ===" -ForegroundColor Green
Write-Host ""

Write-Host "1. Abrindo Grafana Dashboard..." -ForegroundColor Yellow
Start-Process "http://localhost:3000"

Write-Host "2. Abrindo Prometheus..." -ForegroundColor Yellow  
Start-Process "http://localhost:9090"

Write-Host ""
Write-Host "Credenciais do Grafana:" -ForegroundColor Cyan
Write-Host "   Usuario: admin" -ForegroundColor White
Write-Host "   Senha: admin" -ForegroundColor White

Write-Host ""
Write-Host "Endpoints importantes:" -ForegroundColor Cyan
Write-Host "   API Health: http://localhost:8000/health" -ForegroundColor White
Write-Host "   API Metrics: http://localhost:8000/metrics" -ForegroundColor White
Write-Host "   Sistema Status: .\monitor_system.ps1" -ForegroundColor White

Write-Host ""
Write-Host "Para gerar dados de teste:" -ForegroundColor Yellow
Write-Host "   .\test_working.ps1" -ForegroundColor White