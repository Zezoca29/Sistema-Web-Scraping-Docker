$body = @{
    urls = @("https://investidor10.com.br/")
} | ConvertTo-Json

$response = Invoke-WebRequest -Uri "http://localhost:8000/enqueue" -Method POST -ContentType "application/json" -Body $body

Write-Output "Status: $($response.StatusCode)"
Write-Output "Response: $($response.Content)"