<#
.SYNOPSIS
    Runs the Django backend and Flutter User App on Android emulator.

.DESCRIPTION
    This script starts the Django backend server and launches the Flutter user app
    on an Android emulator or connected Android device.
    
    IMPORTANT: Android emulator uses 10.0.2.2 to access host's 127.0.0.1
    
    If you get an execution policy error, run:
        powershell -ExecutionPolicy Bypass -File .\run_android.ps1
    Or set execution policy once:
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

.PARAMETER Release
    Run Flutter app in release mode.

.PARAMETER Port
    Backend port (default: 8000)

.EXAMPLE
    .\run_android.ps1
    .\run_android.ps1 -Release
    
.NOTES
    Email Configuration:
    - By default, uses SMTP backend (Gmail - smtp.gmail.com:587)
    - To use console backend (see OTPs in terminal), set environment variable:
        $env:USE_CONSOLE_EMAIL = 'true'
        .\run_android.ps1
    
    Flutter Hot Reload:
    - While Flutter app is running, press 'r' for hot reload
    - Press 'R' for hot restart
    - Press 'q' to quit
#>

param(
    [switch]$Release,
    [int]$Port = 8000
)

$ErrorActionPreference = 'Stop'

# Determine project root relative to this script
$projectRoot = $PSScriptRoot
$backendPath = Join-Path $projectRoot 'backend'
$flutterPath = Join-Path $projectRoot 'apps\app_user'
$pythonExe = Join-Path $projectRoot 'venv\Scripts\python.exe'

if (!(Test-Path $pythonExe)) {
    $fallbackPythonExe = Join-Path $backendPath 'venv\Scripts\python.exe'
    if (Test-Path $fallbackPythonExe) {
        $pythonExe = $fallbackPythonExe
    }
}

# If venv python not found, try to use system python (py launcher)
if (!(Test-Path $pythonExe)) {
    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
    if ($pyLauncher) {
        Write-Host "Virtual environment not found. Using system Python (py launcher)." -ForegroundColor Yellow
        $pythonExe = "py"
        $pythonArgs = @("-3")
    } else {
        Write-Error "Python virtualenv not found. Expected at $projectRoot\.venv or $backendPath\venv."
        Write-Host "Please create a virtual environment first:" -ForegroundColor Yellow
        Write-Host "  cd backend" -ForegroundColor Yellow
        Write-Host "  py -m venv venv" -ForegroundColor Yellow
        Write-Host "  .\venv\Scripts\activate" -ForegroundColor Yellow
        Write-Host "  pip install -r requirements.txt" -ForegroundColor Yellow
        exit 1
    }
} else {
    $pythonArgs = @()
}

if (!(Test-Path (Join-Path $flutterPath 'pubspec.yaml'))) {
    Write-Error "Flutter project (pubspec.yaml) not found at $flutterPath."
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Android Emulator + Backend Runner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend: http://0.0.0.0:$Port (host)" -ForegroundColor Green
Write-Host "Android: http://10.0.2.2:$Port (emulator -> host)" -ForegroundColor Green
Write-Host "Mode: $(if ($Release) { 'Release' } else { 'Debug' })" -ForegroundColor Green
Write-Host ""

# Email configuration
$useConsoleEmail = $env:USE_CONSOLE_EMAIL
if ($useConsoleEmail -eq 'true') {
    Write-Host "Email: Console backend (OTPs in terminal)" -ForegroundColor Green
    [Environment]::SetEnvironmentVariable('USE_CONSOLE_EMAIL', 'true', 'Process')
} else {
    Write-Host "Email: SMTP backend (Gmail)" -ForegroundColor Green
    [Environment]::SetEnvironmentVariable('USE_CONSOLE_EMAIL', 'false', 'Process')
}
Write-Host ""

# ========================================
# Step 1: Check for Android device/emulator
# ========================================
Write-Host "[1/4] Checking for Android device/emulator..." -ForegroundColor Cyan

$adbDevices = & adb devices 2>&1
$deviceLines = $adbDevices | Select-String -Pattern "device$" | Where-Object { $_ -notmatch "List of devices" }

if (-not $deviceLines) {
    Write-Host ""
    Write-Host "No Android device or emulator found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please do one of the following:" -ForegroundColor Yellow
    Write-Host "  1. Start an Android emulator from Android Studio" -ForegroundColor Yellow
    Write-Host "  2. Connect a physical Android device with USB debugging enabled" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To start an emulator from command line:" -ForegroundColor Cyan
    Write-Host "  emulator -list-avds" -ForegroundColor White
    Write-Host "  emulator -avd <avd_name>" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "Found Android device(s):" -ForegroundColor Green
$deviceLines | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
Write-Host ""

# ========================================
# Step 2: Database migrations
# ========================================
Write-Host "[2/4] Running database migrations..." -ForegroundColor Cyan

Push-Location $backendPath
try {
    # Makemigrations
    Write-Host "  Creating migrations (if needed)..." -ForegroundColor Gray
    $makemigrationsArgs = $pythonArgs + @('manage.py', 'makemigrations')
    $makemigrationsProcess = Start-Process -FilePath $pythonExe `
        -ArgumentList $makemigrationsArgs `
        -WorkingDirectory $backendPath `
        -NoNewWindow `
        -Wait `
        -PassThru `
        -RedirectStandardOutput "$env:TEMP\django_makemigrations.txt" `
        -RedirectStandardError "$env:TEMP\django_makemigrations_err.txt"

    if ($makemigrationsProcess.ExitCode -ne 0) {
        Write-Warning "  makemigrations had issues (continuing anyway)"
    }

    # Migrate
    Write-Host "  Applying migrations..." -ForegroundColor Gray
    $migrateArgs = $pythonArgs + @('manage.py', 'migrate', '--noinput')
    $migrateProcess = Start-Process -FilePath $pythonExe `
        -ArgumentList $migrateArgs `
        -WorkingDirectory $backendPath `
        -NoNewWindow `
        -Wait `
        -PassThru `
        -RedirectStandardOutput "$env:TEMP\django_migrate.txt" `
        -RedirectStandardError "$env:TEMP\django_migrate_err.txt"

    if ($migrateProcess.ExitCode -eq 0) {
        Write-Host "  Migrations applied successfully." -ForegroundColor Green
    } else {
        Write-Error "Migration failed. Check $env:TEMP\django_migrate_err.txt for details."
        exit 1
    }
}
finally {
    Pop-Location
}
Write-Host ""

# ========================================
# Step 3: Start Django backend
# ========================================
Write-Host "[3/4] Starting Django backend (Daphne ASGI)..." -ForegroundColor Cyan

# Function to check if port is in use
function Test-PortInUse {
    param([int]$TestPort)
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $TestPort)
        $listener.Start()
        $listener.Stop()
        return $false
    } catch {
        return $true
    }
}

# Stop any existing server on the port
$existingProcesses = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
if ($existingProcesses) {
    Write-Host "  Stopping existing server on port $Port..." -ForegroundColor Yellow
    $existingProcesses | ForEach-Object {
        try {
            Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue
        } catch { }
    }
    Start-Sleep -Seconds 2
}

# Find available port
$backendPort = $null
$testPorts = @($Port, 8001, 8002, 8003)
foreach ($testPort in $testPorts) {
    if (-not (Test-PortInUse -TestPort $testPort)) {
        $backendPort = $testPort
        break
    }
}

if (-not $backendPort) {
    Write-Error "All ports ($($testPorts -join ', ')) are in use. Please free one."
    exit 1
}

if ($backendPort -ne $Port) {
    Write-Host "  Port $Port in use, using port $backendPort instead" -ForegroundColor Yellow
}

# Start Daphne in background
$script:backendOutputFile = Join-Path $env:TEMP "django_android_output_$backendPort.txt"
$script:backendErrorFile = Join-Path $env:TEMP "django_android_error_$backendPort.txt"

Push-Location $backendPath
$daphneArgs = $pythonArgs + @('-m', 'daphne', 'core.asgi:application', '--bind', '0.0.0.0', '--port', "$backendPort")

$backendProcess = Start-Process -FilePath $pythonExe `
    -ArgumentList $daphneArgs `
    -WorkingDirectory $backendPath `
    -NoNewWindow `
    -PassThru `
    -RedirectStandardOutput $script:backendOutputFile `
    -RedirectStandardError $script:backendErrorFile
Pop-Location

# Wait for server to start
Start-Sleep -Seconds 3

if ($backendProcess -and !$backendProcess.HasExited) {
    Write-Host "  Backend started on port $backendPort" -ForegroundColor Green
    Write-Host "  API: http://127.0.0.1:$backendPort/api" -ForegroundColor Gray
    Write-Host "  WebSocket: ws://127.0.0.1:$backendPort/ws/chat/<id>/" -ForegroundColor Gray
    $script:backendProcess = $backendProcess
    $script:backendPort = $backendPort
} else {
    Write-Error "Backend failed to start. Check logs at $script:backendErrorFile"
    exit 1
}
Write-Host ""

# ========================================
# Step 4: Launch Flutter on Android
# ========================================
Write-Host "[4/4] Launching Flutter on Android..." -ForegroundColor Cyan
Write-Host ""
Write-Host "  Backend URL for Android: http://10.0.2.2:$backendPort/api" -ForegroundColor Yellow
Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "Flutter Hot Reload:" -ForegroundColor Cyan
Write-Host "  r - Hot reload (quick)" -ForegroundColor Green
Write-Host "  R - Hot restart (full)" -ForegroundColor Green
Write-Host "  q - Quit" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# Set up log tailing for backend in background
$script:logTailRunspace = [runspacefactory]::CreateRunspace()
$script:logTailRunspace.Open()

$ps = [PowerShell]::Create()
$ps.Runspace = $script:logTailRunspace

$tailScript = @"
    `$outputFile = '$($script:backendOutputFile)'
    `$errorFile = '$($script:backendErrorFile)'
    `$lastSize = 0
    `$lastErrorSize = 0
    
    while (`$true) {
        if (Test-Path `$outputFile) {
            try {
                `$file = Get-Item `$outputFile -ErrorAction SilentlyContinue
                if (`$file -and `$file.Length -gt `$lastSize) {
                    `$stream = [System.IO.FileStream]::new(`$outputFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                    `$stream.Position = `$lastSize
                    `$reader = New-Object System.IO.StreamReader(`$stream)
                    while (`$null -ne (`$line = `$reader.ReadLine())) {
                        if (`$line.Trim()) {
                            [Console]::WriteLine("[BACKEND] `$line")
                        }
                    }
                    `$lastSize = `$stream.Position
                    `$reader.Close()
                    `$stream.Close()
                }
            } catch { }
        }
        
        if (Test-Path `$errorFile) {
            try {
                `$file = Get-Item `$errorFile -ErrorAction SilentlyContinue
                if (`$file -and `$file.Length -gt `$lastErrorSize) {
                    `$stream = [System.IO.FileStream]::new(`$errorFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                    `$stream.Position = `$lastErrorSize
                    `$reader = New-Object System.IO.StreamReader(`$stream)
                    while (`$null -ne (`$line = `$reader.ReadLine())) {
                        if (`$line.Trim()) {
                            [Console]::ForegroundColor = [ConsoleColor]::Red
                            [Console]::WriteLine("[BACKEND ERROR] `$line")
                            [Console]::ResetColor()
                        }
                    }
                    `$lastErrorSize = `$stream.Position
                    `$reader.Close()
                    `$stream.Close()
                }
            } catch { }
        }
        
        Start-Sleep -Milliseconds 300
    }
"@

$ps.AddScript($tailScript) | Out-Null
$script:logTailHandle = $ps.BeginInvoke()
$script:logTailPowerShell = $ps

# Run Flutter with Android-specific backend URL
Push-Location $flutterPath
try {
    # Build Flutter arguments with Android emulator backend URL (10.0.2.2 maps to host's 127.0.0.1)
    $androidBackendUrl = "http://10.0.2.2:$backendPort/api"
    
    $flutterArgs = @(
        'run',
        '-d', 'android',
        '--dart-define', "BACKEND_BASE_URL=$androidBackendUrl"
    )
    
    if ($Release) {
        $flutterArgs += '--release'
    }
    
    Write-Host "Running: flutter $($flutterArgs -join ' ')" -ForegroundColor Gray
    Write-Host ""
    
    # Run Flutter
    flutter @flutterArgs
}
catch {
    Write-Host "`nError: $_" -ForegroundColor Red
}
finally {
    Pop-Location
    Write-Host ""
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host "Cleaning up..." -ForegroundColor Yellow
    
    # Stop log tailing
    if ($script:logTailPowerShell) {
        try {
            $script:logTailPowerShell.Stop() | Out-Null
            $script:logTailPowerShell.Dispose() | Out-Null
        } catch { }
    }
    if ($script:logTailRunspace) {
        try {
            $script:logTailRunspace.Close() | Out-Null
            $script:logTailRunspace.Dispose() | Out-Null
        } catch { }
    }
    
    # Stop backend
    Write-Host "Stopping Django backend..." -ForegroundColor Yellow
    if ($script:backendProcess -and !$script:backendProcess.HasExited) {
        try {
            $script:backendProcess.Kill()
            $script:backendProcess.WaitForExit()
        } catch { }
    }
    
    Write-Host ""
    Write-Host "All processes stopped." -ForegroundColor Green
}

