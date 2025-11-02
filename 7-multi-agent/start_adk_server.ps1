# ADK Travel Booking Server Launcher
# Run this script to start the ADK-integrated backend on port 8001

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  ADK TRAVEL BOOKING SERVER" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to backend directory
Set-Location "c:\Hack2skill\Hack2skill finale\7-multi-agent"

Write-Host "📍 Current directory: $(Get-Location)" -ForegroundColor Yellow
Write-Host ""

# Check if port 8001 is already in use
Write-Host "🔍 Checking port 8001..." -ForegroundColor Yellow
$portCheck = netstat -ano | findstr :8001
if ($portCheck) {
    Write-Host "⚠️  Port 8001 is already in use!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Running processes on port 8001:" -ForegroundColor Red
    Write-Host $portCheck -ForegroundColor Red
    Write-Host ""
    $response = Read-Host "Kill existing process and restart? (y/n)"
    if ($response -eq "y") {
        $pid = $portCheck.Split()[4]
        Write-Host "Killing process $pid..." -ForegroundColor Yellow
        taskkill /PID $pid /F
        Start-Sleep -Seconds 2
    } else {
        Write-Host "Cancelled. Exiting." -ForegroundColor Red
        exit
    }
}

Write-Host "✅ Port 8001 is free" -ForegroundColor Green
Write-Host ""

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "❌ Error: .env file not found" -ForegroundColor Red
    Write-Host "Please create a .env file with your GOOGLE_API_KEY" -ForegroundColor Red
    exit 1
}
Write-Host "✅ .env file found" -ForegroundColor Green

# Verify data files exist
$dataFiles = @("data/hotels_india.csv", "data/flights_india.csv")
foreach ($file in $dataFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "❌ Error: Data file not found at $file" -ForegroundColor Red
        Write-Host "Cannot start server without travel database" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✅ Data files found" -ForegroundColor Green

# Verify adk_server.py exists
if (-not (Test-Path "adk_server.py")) {
    Write-Host "❌ Error: Server file not found" -ForegroundColor Red
    exit 1
}
Write-Host "✅ ADK server file found" -ForegroundColor Green

# Check Python environment
Write-Host ""
Write-Host "🐍 Checking Python environment..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Python available: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python not found in PATH" -ForegroundColor Red
    exit 1
}

# Check if required packages are installed
Write-Host ""
Write-Host "📦 Checking dependencies..." -ForegroundColor Yellow
$requiredPackages = @("fastapi", "uvicorn", "pandas", "google-generativeai", "python-dotenv")
$missingPackages = @()

foreach ($package in $requiredPackages) {
    try {
        python -c "import $package" 2>$null
        Write-Host "✅ $package installed" -ForegroundColor Green
    } catch {
        $missingPackages += $package
        Write-Host "❌ $package missing" -ForegroundColor Red
    }
}

if ($missingPackages.Count -gt 0) {
    Write-Host ""
    Write-Host "📦 Installing missing packages..." -ForegroundColor Yellow
    pip install $missingPackages
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install packages" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Packages installed successfully" -ForegroundColor Green
}

Write-Host ""
Write-Host "🚀 Starting ADK Travel Booking Server..." -ForegroundColor Cyan
Write-Host "📡 Server will be available at: http://localhost:8001" -ForegroundColor Cyan
Write-Host "🤖 Google ADK Manager Agent integrated!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Start the server
python adk_server.py</content>
<parameter name="filePath">c:\Hack2skill\Hack2skill finale\7-multi-agent\start_adk_server.ps1