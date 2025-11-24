# Runs the Django backend and Flutter Counsellor App together.
# Usage: .\run_counsellor.ps1 [-Release] [-Device <device>]
#        .\run_counsellor.ps1 -release -device windows
#        .\run_counsellor.ps1 -r -d chrome

param(
    [Alias('r')]
    [switch]$Release,
    [Alias('d')]
    [ValidateSet('windows', 'chrome', 'edge', 'web-server', 'android', ignorecase=$true)]
    [string]$Device = 'chrome'
)

$ErrorActionPreference = 'Stop'

# Determine project root relative to this script
$projectRoot = $PSScriptRoot
$backendPath = Join-Path $projectRoot 'backend'
$flutterPath = Join-Path $projectRoot 'apps\app_counsellor'
$pythonExe = Join-Path $projectRoot '.venv\Scripts\python.exe'
if (!(Test-Path $pythonExe)) {
    $fallbackPythonExe = Join-Path $backendPath 'venv\Scripts\python.exe'
    if (Test-Path $fallbackPythonExe) {
        $pythonExe = $fallbackPythonExe
    }
}

if (!(Test-Path $pythonExe)) {
    Write-Error "Python virtualenv not found. Expected at $projectRoot\.venv or $backendPath\venv."
    Write-Host "Please create a virtual environment first:" -ForegroundColor Yellow
    Write-Host "  cd backend" -ForegroundColor Yellow
    Write-Host "  python -m venv venv" -ForegroundColor Yellow
    Write-Host "  .\venv\Scripts\activate" -ForegroundColor Yellow
    Write-Host "  pip install -r requirements.txt" -ForegroundColor Yellow
    exit 1
}

if (!(Test-Path (Join-Path $flutterPath 'pubspec.yaml'))) {
    Write-Error "Flutter project (pubspec.yaml) not found at $flutterPath."
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Django Backend + Counsellor App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Backend API: http://127.0.0.1:8000/api" -ForegroundColor Green
Write-Host "Device: $Device" -ForegroundColor Green
Write-Host "Mode: $(if ($Release) { 'Release' } else { 'Debug' })" -ForegroundColor Green
Write-Host ""

Write-Host "[1/2] Starting Django backend with Daphne (ASGI)..." -ForegroundColor Cyan
Write-Host "Backend will run in background in this terminal." -ForegroundColor Yellow
Write-Host "WebSocket support: ENABLED" -ForegroundColor Green
Write-Host ""

# Check if port 8000 is already in use
Write-Host "Checking for existing server on port 8000..." -ForegroundColor Cyan
$existingProcesses = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
if ($existingProcesses) {
    Write-Host "Found existing server(s) on port 8000. Stopping them..." -ForegroundColor Yellow
    $existingProcesses | ForEach-Object {
        try {
            $proc = Get-Process -Id $_ -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Host "  Stopping process: $($proc.ProcessName) (PID: $_)" -ForegroundColor Yellow
                Stop-Process -Id $_ -Force -ErrorAction Stop
            }
        } catch {
            Write-Warning "  Could not stop process (PID: $_). You may need to stop it manually."
        }
    }
    Start-Sleep -Seconds 2
    Write-Host "Existing server(s) stopped." -ForegroundColor Green
}

# Set environment variable for unbuffered output
[Environment]::SetEnvironmentVariable('PYTHONUNBUFFERED', '1', 'Process')

# Start backend in background job
Write-Host "Starting backend server..." -ForegroundColor Cyan
$backendJob = Start-Job -ScriptBlock {
    param($pythonExe, $backendPath)
    Set-Location $backendPath
    & $pythonExe -m daphne core.asgi:application --bind 0.0.0.0 --port 8000 2>&1
} -ArgumentList $pythonExe, $backendPath

# Wait a moment for server to start
Start-Sleep -Seconds 3

# Check if backend started successfully
$jobState = $backendJob.State
if ($jobState -eq 'Running') {
    Write-Host "Backend started successfully (Job ID: $($backendJob.Id))" -ForegroundColor Green
    Write-Host "API: http://127.0.0.1:8000/api" -ForegroundColor Green
    Write-Host "WebSocket: ws://127.0.0.1:8000/ws/chat/<chat_id>/" -ForegroundColor Green
} else {
    Write-Host "Backend job state: $jobState" -ForegroundColor Yellow
    $output = Receive-Job -Job $backendJob
    if ($output) {
        Write-Host "Backend output: $output" -ForegroundColor Yellow
    }
}
Write-Host ""

if ($Device -eq 'windows') {
    Write-Host "Ensuring no stale Flutter desktop processes..." -ForegroundColor Cyan
    Get-Process -Name 'app_counsellor' -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $_.Kill()
            $_.WaitForExit()
        }
        catch {
            Write-Warning "Failed to terminate process $($_.Name): $_"
        }
    }

    $generatedPluginFile = Join-Path $flutterPath 'windows\flutter\generated_plugin_registrant.h'
    if (Test-Path $generatedPluginFile) {
        try {
            Remove-Item $generatedPluginFile -Force
        }
        catch {
            Write-Warning "Could not remove locked file $generatedPluginFile. Continuing..."
        }
    }
}

Write-Host "[2/2] Launching Flutter Counsellor App..." -ForegroundColor Cyan
Write-Host ""

Push-Location $flutterPath
try {
    $flutterArgs = @('run', '-d', $Device)
    if ($Release) {
        $flutterArgs += '--release'
    }
    
    Write-Host "Backend is running in background. Starting Flutter app (logs will appear below)...`n" -ForegroundColor Cyan
    Write-Host "Note: Backend logs are running in background. Press Ctrl+C to stop both." -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    
    # Run Flutter in foreground - this will show all Flutter logs in the terminal
    flutter @flutterArgs
    
    Write-Host ""
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host "`nFlutter exited." -ForegroundColor Yellow
}
catch {
    Write-Host "`nError: $_" -ForegroundColor Red
}
finally {
    Pop-Location
    Write-Host "`nStopping Django backend..." -ForegroundColor Yellow
    
    # Stop backend job
    if ($backendJob -and $backendJob.State -eq 'Running') {
        try {
            Stop-Job -Job $backendJob
            Remove-Job -Job $backendJob -Force
            Write-Host "Backend stopped." -ForegroundColor Green
        }
        catch {
            Write-Warning "Error stopping backend job: $_"
        }
    }
}

Write-Host "All processes stopped." -ForegroundColor Green

