$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$godot = Join-Path $projectRoot ".tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe"
$outputDirectory = Join-Path $projectRoot "build\windows"
$outputExecutable = Join-Path $outputDirectory "MaskWhispers.exe"
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

Write-Host "Windows build: $outputExecutable"
