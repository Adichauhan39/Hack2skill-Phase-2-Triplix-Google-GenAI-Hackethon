# Start AI Server in Background
Write-Host "Starting AI Hotel Search Server..." -ForegroundColor Cyan

$serverPath = "c:\Hack2skill\Hack2skill finale\7-multi-agent"
$scriptPath = "ultra_simple_server.py"  # Changed to ultra_simple_server for /api/manager endpoint

# Start Python server in a new window
$process = Start-Process -FilePath "python" `
    -ArgumentList $scriptPath `
    -WorkingDirectory $serverPath `
    -WindowStyle Normal `
    -PassThru

Write-Host "Server starting in PID: $($process.Id)" -ForegroundColor Green
Write-Host "Waiting for server to initialize..." -ForegroundColor Yellow

# Wait for server to start
Start-Sleep -Seconds 6

# Test server
try {
    $test = Invoke-RestMethod -Uri "http://localhost:8001/" -Method Get
    Write-Host "`n✓ Server is RUNNING!" -ForegroundColor Green
    Write-Host "  Status: $($test.status)" -ForegroundColor Gray
    Write-Host "  Model: $($test.model)" -ForegroundColor Gray
    Write-Host "  CORS: $($test.cors_enabled)" -ForegroundColor Gray
    Write-Host "`nServer is ready for Flutter app!" -ForegroundColor Cyan
} catch {
    Write-Host "`n❌ Server failed to start!" -ForegroundColor Red
    $errMsg = $_.Exception.Message
    Write-Host "  Error: $errMsg" -ForegroundColor Red
}
