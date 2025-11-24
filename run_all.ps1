<#
.SYNOPSIS
    Runs the Django backend and Flutter frontend together.

.DESCRIPTION
    This script starts the Django backend server and Flutter user app.
    If you get an execution policy error, run:
        powershell -ExecutionPolicy Bypass -File .\run_all.ps1 -Device chrome
    Or set execution policy once:
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

.PARAMETER Release
    Run Flutter app in release mode.

.PARAMETER Device
    Target device: windows, chrome, edge, web-server, or android (default: windows)

.EXAMPLE
    .\run_all.ps1 -Device chrome
    .\run_all.ps1 -Release -Device windows
    
.NOTES
    Email Configuration:
    - By default, uses SMTP backend (Gmail - smtp.gmail.com:587)
    - To use console backend (see OTPs in terminal), set environment variable:
        $env:USE_CONSOLE_EMAIL = 'true'
        .\run_all.ps1
    
    Flutter Hot Reload:
    - While Flutter app is running, press 'r' for hot reload (quick refresh)
    - Press 'R' (capital) for hot restart (full restart)
    - Press 'q' to quit the Flutter app
#>

param(
    [switch]$Release,
    [ValidateSet('windows', 'chrome', 'edge', 'web-server', 'android')]
    [string]$Device = 'windows'
)

$ErrorActionPreference = 'Stop'

# Determine project root relative to this script
$projectRoot = $PSScriptRoot
$backendPath = Join-Path $projectRoot 'backend'
$flutterPath = Join-Path $projectRoot 'apps\app_user'
$pythonExe = Join-Path $projectRoot '.venv\Scripts\python.exe'

if (!(Test-Path $pythonExe)) {
    $fallbackPythonExe = Join-Path $backendPath 'venv\Scripts\python.exe'
    if (Test-Path $fallbackPythonExe) {
        $pythonExe = $fallbackPythonExe
    }
}

# If venv python not found, try to use system python (py launcher)
if (!(Test-Path $pythonExe)) {
    # Try to find py launcher
    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
    if ($pyLauncher) {
        Write-Host "Virtual environment not found. Using system Python (py launcher)." -ForegroundColor Yellow
        Write-Host "For best results, create a virtual environment:" -ForegroundColor Yellow
        Write-Host "  cd backend" -ForegroundColor Yellow
        Write-Host "  py -m venv venv" -ForegroundColor Yellow
        Write-Host "  .\venv\Scripts\activate" -ForegroundColor Yellow
        Write-Host "  pip install -r requirements.txt" -ForegroundColor Yellow
        Write-Host ""
        
        # Use py launcher with -3 flag to ensure Python 3
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

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Django Backend + User App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
# Backend port will be determined dynamically (8000 or 8001)
# Will be updated after port detection
Write-Host "Device: $Device" -ForegroundColor Green
Write-Host "Mode: $(if ($Release) { 'Release' } else { 'Debug' })" -ForegroundColor Green
# Email configuration - check environment variable
$useConsoleEmail = $env:USE_CONSOLE_EMAIL
if ($useConsoleEmail -eq 'true') {
    Write-Host "Email: Console backend (OTPs in terminal)" -ForegroundColor Green
    [Environment]::SetEnvironmentVariable('USE_CONSOLE_EMAIL', 'true', 'Process')
} else {
    Write-Host "Email: SMTP backend (Gmail - smtp.gmail.com:587)" -ForegroundColor Green
    [Environment]::SetEnvironmentVariable('USE_CONSOLE_EMAIL', 'false', 'Process')
}
Write-Host ""

Write-Host "[1/2] Starting Django backend..." -ForegroundColor Cyan
Write-Host ""

# Run database migrations first
Write-Host "Creating migrations (if needed)..." -ForegroundColor Cyan
Push-Location $backendPath
try {
    $makemigrationsArgs = $pythonArgs + @('manage.py', 'makemigrations')
    $makemigrationsProcess = Start-Process -FilePath $pythonExe `
        -ArgumentList $makemigrationsArgs `
        -WorkingDirectory $backendPath `
        -NoNewWindow `
        -Wait `
        -PassThru `
        -RedirectStandardOutput "$env:TEMP\django_makemigrations.txt" `
        -RedirectStandardError "$env:TEMP\django_makemigrations_err.txt"

    if ($makemigrationsProcess.ExitCode -eq 0) {
        Write-Host "Migrations created/checked." -ForegroundColor Green
        if (Test-Path "$env:TEMP\django_makemigrations.txt") {
            $output = Get-Content "$env:TEMP\django_makemigrations.txt" -Raw
            if ($output -and $output.Trim()) {
                Write-Host $output -ForegroundColor Gray
            }
        }
    } else {
        Write-Warning "makemigrations had issues (exit code: $($makemigrationsProcess.ExitCode))"
        if (Test-Path "$env:TEMP\django_makemigrations_err.txt") {
            $errorOutput = Get-Content "$env:TEMP\django_makemigrations_err.txt" -Raw
            if ($errorOutput) {
                Write-Host $errorOutput -ForegroundColor Yellow
            }
        }
        Write-Warning "Continuing anyway..."
    }
}
finally {
    Pop-Location
}

Write-Host "Applying migrations..." -ForegroundColor Cyan
Push-Location $backendPath
try {
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
        Write-Host "Migrations applied successfully." -ForegroundColor Green
    } else {
        Write-Error "Migration failed with exit code $($migrateProcess.ExitCode):"
        if (Test-Path "$env:TEMP\django_migrate_err.txt") {
            $errorOutput = Get-Content "$env:TEMP\django_migrate_err.txt" -Raw
            if ($errorOutput) {
                Write-Host $errorOutput -ForegroundColor Red
            }
        }
        Write-Error "Cannot continue without migrations. Please fix the errors above."
        exit 1
    }
}
finally {
    Pop-Location
}

Write-Host ""

# Test if Django can start (check for syntax errors)
Write-Host "Checking Django configuration..." -ForegroundColor Cyan
Push-Location $backendPath
try {
    $checkArgs = $pythonArgs + @('manage.py', 'check')
    $checkProcess = Start-Process -FilePath $pythonExe `
        -ArgumentList $checkArgs `
    -WorkingDirectory $backendPath `
    -NoNewWindow `
        -Wait `
        -PassThru `
        -RedirectStandardOutput "$env:TEMP\django_check.txt" `
        -RedirectStandardError "$env:TEMP\django_check_err.txt"

    if ($checkProcess.ExitCode -ne 0) {
        Write-Error "Django configuration check failed:"
        if (Test-Path "$env:TEMP\django_check_err.txt") {
            $errorOutput = Get-Content "$env:TEMP\django_check_err.txt" -Raw
            if ($errorOutput) {
                Write-Host $errorOutput -ForegroundColor Red
            }
        }
        Write-Error "Please fix the errors above before starting the server."
        exit 1
    } else {
        Write-Host "Django configuration is valid." -ForegroundColor Green
    }
}
finally {
    Pop-Location
}

Write-Host ""

# Check if port 8000 is already in use and stop any existing server
Write-Host "Checking for existing server on port 8000..." -ForegroundColor Cyan

# Function to find all processes using port 8000
function Find-Port8000Processes {
    $processes = @()
    
    # Method 1: Check for processes using port 8000 via Get-NetTCPConnection
    try {
        $portConnections = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
        if ($portConnections) {
            $processes += $portConnections | Select-Object -ExpandProperty OwningProcess -Unique
        }
    } catch {
        # If Get-NetTCPConnection fails, continue with other methods
    }
    
    # Method 2: Check for Python processes that might be running Django/Daphne
    try {
        $allPython = Get-Process -Name python,pythonw -ErrorAction SilentlyContinue
        foreach ($proc in $allPython) {
            try {
                $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction SilentlyContinue).CommandLine
                if ($cmdLine) {
                    if ($cmdLine -like "*daphne*" -or 
                        $cmdLine -like "*manage.py*runserver*" -or 
                        $cmdLine -like "*core.asgi*" -or
                        $cmdLine -like "*8000*") {
                        $processes += $proc.Id
                    }
                }
            } catch {
                # If we can't get command line, check if it's a Python process (might be our server)
                # Only add if we don't already have it from port check
                if ($processes -notcontains $proc.Id) {
                    # Be conservative - don't kill Python processes without confirmation
                }
            }
        }
    } catch {
        # If process check fails, continue
    }
    
    # Method 3: Use netstat as fallback (more reliable on some systems)
    try {
        $netstatOutput = netstat -ano | Select-String ":8000.*LISTENING"
        if ($netstatOutput) {
            $netstatPids = $netstatOutput | ForEach-Object {
                if ($_ -match '\s+(\d+)\s*$') {
                    [int]$matches[1]
                }
            }
            $processes += $netstatPids
        }
    } catch {
        # If netstat fails, continue
    }
    
    return ($processes | Select-Object -Unique | Where-Object { $_ -ne $null -and $_ -gt 0 })
}

# Check multiple times to catch processes that might be starting
$maxAttempts = 3
$allFoundProcesses = @()
for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
    $foundProcesses = Find-Port8000Processes
    $allFoundProcesses += $foundProcesses
    if ($foundProcesses.Count -gt 0) {
        Write-Host "  Attempt $attempt : Found $($foundProcesses.Count) process(es) using port 8000" -ForegroundColor Gray
    }
    if ($attempt -lt $maxAttempts) {
        Start-Sleep -Milliseconds 500
    }
}

# Get unique list of all processes found
$allProcesses = $allFoundProcesses | Select-Object -Unique | Where-Object { $_ -ne $null -and $_ -gt 0 }

if ($allProcesses) {
    Write-Host "Found existing server(s) on port 8000. Stopping them..." -ForegroundColor Yellow
    $stoppedCount = 0
    $allProcesses | ForEach-Object {
        try {
            $proc = Get-Process -Id $_ -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Host "  Stopping process: $($proc.ProcessName) (PID: $_)" -ForegroundColor Yellow
                Stop-Process -Id $_ -Force -ErrorAction Stop
                $stoppedCount++
            }
        } catch {
            Write-Warning "  Could not stop process (PID: $_). You may need to stop it manually."
        }
    }
    
    # Wait longer for port to be released
    Write-Host "  Waiting for port 8000 to be released..." -ForegroundColor Gray
    Start-Sleep -Seconds 4
    
    # Verify port is free - check multiple times
    $portStillInUse = $true
    for ($check = 1; $check -le 5; $check++) {
        try {
            $stillInUse = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
            if (-not $stillInUse) {
                $portStillInUse = $false
                break
            }
        } catch {
            # If check fails, assume port might be free
            $portStillInUse = $false
            break
        }
        Start-Sleep -Seconds 1
    }
    
    if ($portStillInUse) {
        Write-Host "  Warning: Port 8000 may still be in use after stopping processes." -ForegroundColor Yellow
        Write-Host "  Attempting to continue anyway..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    } else {
        Write-Host "  Stopped $stoppedCount process(es). Port 8000 is now free." -ForegroundColor Green
    }
} else {
    Write-Host "Port 8000 is free. Proceeding..." -ForegroundColor Green
}

# Start backend in background (output will appear in this terminal)
Write-Host "Starting Django server with Daphne (ASGI)..." -ForegroundColor Cyan
Write-Host "Backend will run in this terminal. All output will appear here." -ForegroundColor Yellow
Write-Host ""

# Determine which port to use (8000 or 8001 as fallback)
# Wait a moment for port to fully release after process cleanup
Start-Sleep -Seconds 2

# Function to reliably check if a port is in use
function Test-PortInUse {
    param([int]$Port)
    
    try {
        # Method 1: Try to bind to the port (most reliable)
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        $listener.Stop()
        return $false  # Port is free
    } catch {
        return $true  # Port is in use
    }
}

# Check ports with multiple methods
$backendPort = $null
$testPorts = @(8000, 8001, 8002, 8003)

foreach ($testPort in $testPorts) {
    $isInUse = Test-PortInUse -Port $testPort
    if (-not $isInUse) {
        $backendPort = $testPort
        if ($testPort -ne 8000) {
            Write-Host "Port 8000 is in use, using port $testPort instead..." -ForegroundColor Yellow
        }
        break
    } else {
        # Also check with Get-NetTCPConnection for better visibility
        $connCheck = Get-NetTCPConnection -LocalPort $testPort -ErrorAction SilentlyContinue
        if ($connCheck) {
            Write-Host "Port $testPort is in use (checked via Get-NetTCPConnection)" -ForegroundColor Gray
        }
    }
}

if (-not $backendPort) {
    Write-Error "All tested ports ($($testPorts -join ', ')) are in use. Please free one of them or stop other Django servers."
    Write-Host "`nTo manually free a port, run:" -ForegroundColor Yellow
    Write-Host "  netstat -ano | findstr :8000" -ForegroundColor Cyan
    Write-Host "  taskkill /PID <PID> /F" -ForegroundColor Cyan
    exit 1
}

# Update the API URL display
Write-Host "Backend API: http://127.0.0.1:$backendPort/api" -ForegroundColor Green

# Start Django server with Daphne (for WebSocket support)
Write-Host "Starting Django server with Daphne on port $backendPort..." -ForegroundColor Cyan
Push-Location $backendPath

# Build command arguments for Daphne
$daphneArgs = @('-m', 'daphne', 'core.asgi:application', '--bind', '0.0.0.0', '--port', "$backendPort")

# Redirect backend output to avoid interfering with Flutter's interactive commands
# Store in script scope so cleanup block can access them
$script:backendOutputFile = Join-Path $env:TEMP "django_backend_output_$backendPort.txt"
$script:backendErrorFile = Join-Path $env:TEMP "django_backend_error_$backendPort.txt"

if ($pythonArgs.Count -gt 0) {
    $allArgs = $pythonArgs + $daphneArgs
    $backendProcess = Start-Process -FilePath $pythonExe `
        -ArgumentList $allArgs `
        -WorkingDirectory $backendPath `
        -NoNewWindow `
        -PassThru `
        -RedirectStandardOutput $script:backendOutputFile `
        -RedirectStandardError $script:backendErrorFile
} else {
    $backendProcess = Start-Process -FilePath $pythonExe `
        -ArgumentList $daphneArgs `
    -WorkingDirectory $backendPath `
    -NoNewWindow `
        -PassThru `
        -RedirectStandardOutput $script:backendOutputFile `
        -RedirectStandardError $script:backendErrorFile
}

Pop-Location

# Wait a moment for server to start
Start-Sleep -Seconds 3

# Check if backend process is still running
if ($backendProcess -and !$backendProcess.HasExited) {
    Write-Host "Backend started successfully with Daphne (ASGI) - WebSocket support enabled" -ForegroundColor Green
    Write-Host "Server should be available at http://127.0.0.1:$backendPort" -ForegroundColor Green
    Write-Host "WebSocket endpoint: ws://127.0.0.1:$backendPort/ws/chat/<chat_id>/" -ForegroundColor Green
    Write-Host ""
    Write-Host "Backend logs will appear in this terminal below..." -ForegroundColor Green
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    
    # Set up log tailing using runspace for real-time console output
    # Wait a moment for log file to be created
    Start-Sleep -Seconds 1
    
    # Create a runspace that outputs directly to console
    $script:logTailRunspace = [runspacefactory]::CreateRunspace()
    $script:logTailRunspace.ApartmentState = [System.Threading.ApartmentState]::STA
    # ThreadOptions is not available in all PowerShell versions, so we skip it
    # The runspace will work fine without it
    $script:logTailRunspace.Open()
    
    $ps = [PowerShell]::Create()
    $ps.Runspace = $script:logTailRunspace
    
    # Script that tails logs and writes directly to host
    $tailScript = @"
        `$outputFile = '$($script:backendOutputFile)'
        `$errorFile = '$($script:backendErrorFile)'
        `$lastSize = 0
        `$lastErrorSize = 0
        
        while (`$true) {
            # Check output file
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
            
            # Check error file
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
    
    # Store reference for cleanup
    $script:backendProcess = $backendProcess
    $script:backendPort = $backendPort
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Daphne server failed to start!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
Write-Host ""
    
    if ($backendProcess -and $backendProcess.HasExited) {
        Write-Host "Process exited with code: $($backendProcess.ExitCode)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Make sure Daphne is installed: pip install daphne" -ForegroundColor Yellow
    Write-Host "2. Check if port $backendPort is already in use" -ForegroundColor Yellow
    Write-Host "3. Verify virtual environment is activated" -ForegroundColor Yellow
    Write-Host "4. Check Python path: $pythonExe" -ForegroundColor Yellow
    Write-Host "5. Try running manually: cd backend; python -m daphne core.asgi:application --bind 0.0.0.0 --port $backendPort" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "IMPORTANT: If you see 'OSError: [WinError 10106]', this is a Windows asyncio issue." -ForegroundColor Red
    Write-Host "This usually means your Python installation has a corrupted asyncio module." -ForegroundColor Red
    Write-Host ""
    Write-Host "Try these fixes:" -ForegroundColor Yellow
    Write-Host "  a) python -m pip install --upgrade pip setuptools wheel" -ForegroundColor Cyan
    Write-Host "  b) python -m pip install --force-reinstall asyncio" -ForegroundColor Cyan
    Write-Host "  c) Reinstall Python 3.11 or try Python 3.12" -ForegroundColor Cyan
    Write-Host "  d) Use WSL (Windows Subsystem for Linux) if available" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

if ($Device -eq 'windows') {
    Write-Host "Ensuring no stale Flutter desktop processes..." -ForegroundColor Cyan
    Get-Process -Name 'app_user' -ErrorAction SilentlyContinue | ForEach-Object {
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

Write-Host "[2/2] Launching Flutter User App..." -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "All output will appear in this terminal:" -ForegroundColor Cyan
Write-Host "  - Backend logs (prefixed with [BACKEND])" -ForegroundColor Yellow
Write-Host "  - Flutter app output (below)" -ForegroundColor Yellow
Write-Host "  - Press Ctrl+C to stop both" -ForegroundColor Yellow
Write-Host ""
Write-Host "Flutter Hot Reload Commands:" -ForegroundColor Cyan
Write-Host "  - Press 'r' (lowercase) to hot reload (quick refresh)" -ForegroundColor Green
Write-Host "  - Press 'R' (capital) to hot restart (full restart)" -ForegroundColor Green
Write-Host "  - Press 'q' to quit the Flutter app" -ForegroundColor Green
Write-Host ""
Write-Host "Note: Chrome DevTools cleanup errors (SocketException) are harmless" -ForegroundColor Gray
Write-Host "      and can be safely ignored. They don't affect app functionality." -ForegroundColor Gray
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host ""

Push-Location $flutterPath
try {
    $flutterArgs = @('run', '-d', $Device)
    if ($Release) {
        $flutterArgs += '--release'
    }
    
    Write-Host "Starting Flutter app..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Backend logs will appear in real-time with [BACKEND] prefix." -ForegroundColor Green
    Write-Host "Flutter output will appear below." -ForegroundColor Green
    Write-Host ""
    
    # Run Flutter directly - this blocks and shows output in this terminal
    # Backend logs are being displayed in real-time via the runspace (running in parallel)
    # Note: DevTools cleanup errors are harmless and can be ignored
    flutter @flutterArgs
}
catch {
    $errorMsg = $_.ToString()
    # DevTools cleanup errors are harmless - don't show them as critical errors
    if ($errorMsg -match "DevTools|websocket.*tooling|SocketException.*refused.*network connection") {
        Write-Host "`nNote: Flutter DevTools cleanup warning (harmless)" -ForegroundColor Yellow
    } else {
        Write-Host "`nError: $errorMsg" -ForegroundColor Red
    }
}
finally {
    Pop-Location
    Write-Host ""
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host "`nCleaning up..." -ForegroundColor Yellow
    
    # Stop log tailing runspace
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
    
    # Stop the backend process gracefully
    Write-Host "Stopping Django backend..." -ForegroundColor Yellow
    if ($script:backendProcess -and !$script:backendProcess.HasExited) {
        try {
            $script:backendProcess.CloseMainWindow() | Out-Null
            if (-not $script:backendProcess.HasExited) {
                Start-Sleep -Seconds 1
                $script:backendProcess.Kill()
            }
        }
        catch {
            if (-not $script:backendProcess.HasExited) {
                $script:backendProcess.Kill()
            }
        }
        $script:backendProcess.WaitForExit()
    }
    
    # Show backend log locations before cleanup
    if ($script:backendOutputFile -and (Test-Path $script:backendOutputFile)) {
        Write-Host "Backend output log: $script:backendOutputFile" -ForegroundColor Gray
    }
    if ($script:backendErrorFile -and (Test-Path $script:backendErrorFile)) {
        Write-Host "Backend error log: $script:backendErrorFile" -ForegroundColor Gray
    }
    
    # Clean up any remaining Flutter/Chrome processes (for web builds)
    # Note: This is optional - Chrome will close when Flutter exits
    if ($Device -match 'chrome|edge|web') {
        Write-Host "Note: Chrome DevTools cleanup errors are harmless and can be ignored" -ForegroundColor Gray
    }
}

Write-Host "All processes stopped." -ForegroundColor Green