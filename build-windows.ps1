$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectConfig = Get-Content -Raw -LiteralPath (
    Join-Path $projectRoot "project.godot"
)
$versionMatch = [regex]::Match(
    $projectConfig,
    'config/version="([^"]+)"'
)
if (-not $versionMatch.Success) {
    throw "project.godot does not define application/config/version."
}
$projectVersion = $versionMatch.Groups[1].Value
$godot = Join-Path $projectRoot ".tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe"
$outputDirectory = Join-Path $projectRoot "build\windows"
$outputExecutable = Join-Path $outputDirectory "MaskWhispers.exe"
$versionedExecutable = Join-Path $outputDirectory (
    "MaskWhispers_v$projectVersion.exe"
)
$logDirectory = Join-Path $projectRoot ".tools\export-logs"

if (-not (Test-Path -LiteralPath $godot)) {
    throw "Godot executable not found: $godot"
}

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null

$stdout = Join-Path $logDirectory "windows-export.stdout.log"
$stderr = Join-Path $logDirectory "windows-export.stderr.log"
$process = Start-Process `
    -FilePath $godot `
    -ArgumentList @("--headless", "--path", $projectRoot, "--export-release", '"Windows Desktop"', $outputExecutable) `
    -Wait `
    -PassThru `
    -NoNewWindow `
    -RedirectStandardOutput $stdout `
    -RedirectStandardError $stderr

Get-Content -LiteralPath $stdout | Write-Host
if ((Get-Item -LiteralPath $stderr).Length -gt 0) {
    Get-Content -LiteralPath $stderr | Write-Error
}
if ($process.ExitCode -ne 0) {
    throw "Windows export failed with exit code $($process.ExitCode)"
}
if (-not (Test-Path -LiteralPath $outputExecutable)) {
    throw "Windows export exited successfully but did not create $outputExecutable"
}

Copy-Item `
    -LiteralPath $outputExecutable `
    -Destination $versionedExecutable `
    -Force

$smokeStdout = Join-Path $logDirectory "windows-smoke.stdout.log"
$smokeStderr = Join-Path $logDirectory "windows-smoke.stderr.log"
$smoke = Start-Process `
    -FilePath $versionedExecutable `
    -ArgumentList @("--headless", "--quit-after", "5") `
    -WorkingDirectory $env:TEMP `
    -WindowStyle Hidden `
    -Wait `
    -PassThru `
    -RedirectStandardOutput $smokeStdout `
    -RedirectStandardError $smokeStderr
if ($smoke.ExitCode -ne 0) {
    Get-Content -LiteralPath $smokeStdout | Select-Object -Last 20
    Get-Content -LiteralPath $smokeStderr | Select-Object -Last 20
    throw "Exported game failed the project-external smoke test."
}

$hash = Get-FileHash -Algorithm SHA256 -LiteralPath $versionedExecutable
$size = (Get-Item -LiteralPath $versionedExecutable).Length
Write-Host "Windows build: $outputExecutable"
Write-Host "Windows versioned build: $versionedExecutable"
Write-Host "Windows build size: $size"
Write-Host "Windows build SHA256: $($hash.Hash)"
Write-Host "Windows external smoke: PASS"
