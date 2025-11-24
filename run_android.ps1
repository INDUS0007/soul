param(
    [switch]$Release,
    [string]$DeviceId,
    [string]$LanIp,
    [int]$BackendPort = 8000,
    [int]$DeviceBootTimeoutSeconds = 240,
    [switch]$SkipEmulatorLaunch,
    [ValidateSet("host", "angle_indirect", "swiftshader_indirect")]
    [string]$GpuMode = "host"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "➡ $Message" -ForegroundColor Cyan
}

function Ensure-Path {
    param([string]$Path, [string]$Description)
    if (-not (Test-Path $Path)) {
        throw "$Description not found at '$Path'."
    }
}

function Ensure-Command {
    param([string]$Command, [string]$Hint)
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        if (-not $Hint) { $Hint = "Install $Command and add it to PATH." }
        throw "Required command '$Command' not found. $Hint"
    }
}

function Add-EnvPath {
    param([string]$PathToAdd)
    if ([string]::IsNullOrWhiteSpace($PathToAdd)) { return }
    if (-not (Test-Path $PathToAdd)) { return }
    if ($env:PATH.Split([IO.Path]::PathSeparator) -notcontains $PathToAdd) {
        $env:PATH = "$env:PATH$([IO.Path]::PathSeparator)$PathToAdd"
    }
}

function Get-AndroidSdkRoot {
    if ($env:ANDROID_HOME) { return $env:ANDROID_HOME }
    if ($env:ANDROID_SDK_ROOT) { return $env:ANDROID_SDK_ROOT }
    return Join-Path $env:LOCALAPPDATA "Android\Sdk"
}

function Get-AdbDevices {
    $output = (& adb devices) 2>$null
    foreach ($line in $output) {
        $trimmed = $line.Trim()
        if (-not $trimmed) { continue }
        if ($trimmed -like "List of devices*") { continue }
        $parts = $trimmed -split "\s+"
        if ($parts.Count -ge 2) {
            [PSCustomObject]@{
                Id     = $parts[0]
                Status = $parts[1]
            }
        }
    }
}

function Wait-ForDeviceReady {
    param(
        [string]$DeviceId,
        [int]$TimeoutSeconds = 240
    )

    $timer = [Diagnostics.Stopwatch]::StartNew()
    while ($timer.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        $state = Get-AdbDevices | Where-Object { $_.Id -eq $DeviceId -and $_.Status -eq "device" }
        if ($state) {
            $booted = (& adb -s $DeviceId shell getprop sys.boot_completed 2>$null | Out-String).Trim()
            if ($booted -eq "1") { return $true }
        }
        Start-Sleep -Seconds 3
    }
    return $false
}

function Launch-Emulator {
    param(
        [string]$EmulatorExecutable,
        [string]$GpuMode,
        [int]$TimeoutSeconds
    )

    $avdList = (& $EmulatorExecutable -list-avds 2>$null | Out-String).Trim().Split("`r`n", [System.StringSplitOptions]::RemoveEmptyEntries)
    if (-not $avdList -or $avdList.Count -eq 0) {
        throw "No Android Virtual Devices defined. Create one from Android Studio."
    }

    $avdName = $avdList[0].Trim()
    Write-Step "Launching emulator '$avdName' (GPU: $GpuMode)"

    $emuArgs = @(
        "-avd", $avdName,
        "-netfast",
        "-no-snapshot-save",
        "-gpu", $GpuMode
    )

    $process = Start-Process -FilePath $EmulatorExecutable -ArgumentList $emuArgs -PassThru
    Start-Sleep -Seconds 5

    $timer = [Diagnostics.Stopwatch]::StartNew()
    while ($timer.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        $device = Get-AdbDevices | Select-Object -First 1
        if ($device) {
            if (Wait-ForDeviceReady -DeviceId $device.Id -TimeoutSeconds ($TimeoutSeconds - [int]$timer.Elapsed.TotalSeconds)) {
                return [PSCustomObject]@{
                    Id       = $device.Id
                    Process  = $process
                    Launched = $true
                }
            }
            break
        }
        Start-Sleep -Seconds 3
    }

    $process | Stop-Process -Force -ErrorAction SilentlyContinue
    throw "Emulator failed to boot within $TimeoutSeconds seconds. Check emulator logs (missing opengl32sw.dll is common)."
}

function Resolve-Device {
    param(
        [string]$DeviceId,
        [switch]$AllowLaunch,
        [string]$EmulatorExecutable,
        [string]$GpuMode,
        [int]$TimeoutSeconds
    )

    if ($DeviceId) {
        Write-Step "Targeting requested device '$DeviceId'"
        if (Wait-ForDeviceReady -DeviceId $DeviceId -TimeoutSeconds $TimeoutSeconds) {
            return [PSCustomObject]@{ Id = $DeviceId; Launched = $false; Process = $null }
        }
        throw "Device '$DeviceId' not detected over adb."
    }

    $connected = Get-AdbDevices | Where-Object { $_.Status -eq "device" } | Select-Object -First 1
    if ($connected) {
        Write-Step "Using connected device $($connected.Id)"
        return [PSCustomObject]@{ Id = $connected.Id; Launched = $false; Process = $null }
    }

    if (-not $AllowLaunch) {
        throw "No Android devices detected and emulator launch disabled."
    }

    return Launch-Emulator -EmulatorExecutable $EmulatorExecutable -GpuMode $GpuMode -TimeoutSeconds $TimeoutSeconds
}

function Resolve-LanIp {
    param([string]$Preferred, [string]$DeviceId)

    if ($Preferred) { return $Preferred }
    if ($DeviceId -like "emulator-*") { return "10.0.2.2" }

    $ip = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -notlike "169.254.*" -and
            $_.IPAddress -ne "127.0.0.1" -and
            $_.InterfaceAlias -notlike "*Virtual*"
        } |
        Sort-Object SkipAsSource, PrefixOrigin |
        Select-Object -First 1

    if ($ip) { return $ip.IPAddress }
    return "127.0.0.1"
}

function Stop-ProcessSafe {
    param([Diagnostics.Process]$Process)
    if (-not $Process) { return }
    try {
        if (-not $Process.HasExited) {
            $Process.CloseMainWindow() | Out-Null
            Start-Sleep -Milliseconds 300
        }
        if (-not $Process.HasExited) {
            $Process.Kill()
        }
        $Process.WaitForExit()
    } catch {
        # ignore
    }
}

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $projectRoot) { $projectRoot = Get-Location }

$backendDir = Join-Path $projectRoot "backend"
$flutterDir = Join-Path $projectRoot "apps\app_user"
$pythonExe  = Join-Path $backendDir "venv\Scripts\python.exe"
$managePy   = Join-Path $backendDir "manage.py"

Write-Step "Validating project structure"
Ensure-Path $backendDir "Backend directory"
Ensure-Path $flutterDir "Flutter directory"
Ensure-Path $pythonExe  "Backend virtualenv Python"
Ensure-Path $managePy   "manage.py"
Ensure-Path (Join-Path $flutterDir "pubspec.yaml") "Flutter pubspec"

Ensure-Command "flutter" "Install Flutter SDK and ensure 'flutter' is in PATH."

$sdkRoot = Get-AndroidSdkRoot
Ensure-Path $sdkRoot "Android SDK root"
Add-EnvPath (Join-Path $sdkRoot "platform-tools")
Add-EnvPath (Join-Path $sdkRoot "emulator")
Ensure-Command "adb" "Install Android platform-tools from the SDK Manager."

$emulatorExe = Join-Path $sdkRoot "emulator\emulator.exe"
Ensure-Path $emulatorExe "Android emulator executable"

$softwareGl = Join-Path $sdkRoot "emulator\lib64\opengl32sw.dll"
if (-not (Test-Path $softwareGl)) {
    Write-Warning "opengl32sw.dll missing. Install/repair the 'Android Emulator' package if the emulator fails to start."
}

Write-Step "Resolving Android target"
$deviceInfo = Resolve-Device -DeviceId $DeviceId -AllowLaunch:(-not $SkipEmulatorLaunch) -EmulatorExecutable $emulatorExe -GpuMode $GpuMode -TimeoutSeconds $DeviceBootTimeoutSeconds
$targetDeviceId = $deviceInfo.Id

Write-Step "Running database migrations"
Push-Location $backendDir
try {
    $migrateArgs = @("manage.py", "migrate", "--noinput")
    $migrateProcess = Start-Process -FilePath $pythonExe -ArgumentList $migrateArgs -WorkingDirectory $backendDir -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$env:TEMP\django_migrate_android.txt" -RedirectStandardError "$env:TEMP\django_migrate_android_err.txt"
    
    if ($migrateProcess.ExitCode -ne 0) {
        Write-Warning "Migration had issues (exit code: $($migrateProcess.ExitCode))"
        if (Test-Path "$env:TEMP\django_migrate_android_err.txt") {
            $errorOutput = Get-Content "$env:TEMP\django_migrate_android_err.txt" -Raw
            if ($errorOutput) {
                Write-Host $errorOutput -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "Migrations applied successfully." -ForegroundColor Green
    }
}
finally {
    Pop-Location
}

Write-Step "Starting Django backend with Daphne (ASGI for WebSocket support)"
# Check if port is already in use
$existingProcesses = Get-NetTCPConnection -LocalPort $BackendPort -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
if ($existingProcesses) {
    Write-Host "Found existing server(s) on port $BackendPort. Stopping them..." -ForegroundColor Yellow
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

# Use Daphne for ASGI (WebSocket support) - REQUIRED for WebSocket functionality
# Build arguments as array for Start-Process
$backendArgs = @("-m", "daphne", "core.asgi:application", "--bind", "0.0.0.0", "--port", "$BackendPort")
$backendProcess = Start-Process -FilePath $pythonExe -ArgumentList $backendArgs -WorkingDirectory $backendDir -NoNewWindow -PassThru
Start-Sleep -Seconds 3

Write-Step "Running Flutter app"
$lanIp = Resolve-LanIp -Preferred $LanIp -DeviceId $targetDeviceId
$backendUrl = "http://$($lanIp):$BackendPort/api"
Write-Host "Backend URL injected into Flutter: $backendUrl" -ForegroundColor Yellow

$flutterArgs = @("run", "-d", $targetDeviceId, "--dart-define=BACKEND_BASE_URL=$backendUrl")
if ($Release) { $flutterArgs += "--release" }

Push-Location $flutterDir
try {
    flutter @flutterArgs
} finally {
    Pop-Location
    Write-Step "Cleaning up"
    Stop-ProcessSafe -Process $backendProcess
    if ($deviceInfo.Launched) {
        Stop-ProcessSafe -Process $deviceInfo.Process
    }
}
