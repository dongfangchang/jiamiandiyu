$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$godot = Join-Path $projectRoot ".tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe"
$consoleGodot = Join-Path $projectRoot ".tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe"
$playLauncher = Join-Path $projectRoot "play.cmd"
$editorLauncher = Join-Path $projectRoot "open-editor.cmd"
$buildScript = Join-Path $projectRoot "build-windows.ps1"
$logDirectory = Join-Path $projectRoot ".tools\qa-logs"

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw "This compatibility test must run on Windows."
}
foreach ($path in @(
    $godot,
    $consoleGodot,
    $playLauncher,
    $editorLauncher,
    $buildScript
)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required Windows asset is missing: $path"
    }
}

New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
$playLog = Join-Path $logDirectory "windows_play_launcher.stdout.log"
$playErr = Join-Path $logDirectory "windows_play_launcher.stderr.log"
$process = Start-Process `
    -FilePath "cmd.exe" `
    -ArgumentList @(
        "/c",
        "call `"$playLauncher`" --headless --quit-after 2"
    ) `
    -WorkingDirectory $projectRoot `
    -Wait `
    -PassThru `
    -NoNewWindow `
    -RedirectStandardOutput $playLog `
    -RedirectStandardError $playErr
if ($process.ExitCode -ne 0) {
    Get-Content -LiteralPath $playLog | Select-Object -Last 20
    Get-Content -LiteralPath $playErr | Select-Object -Last 20
    throw "play.cmd smoke failed with exit code $($process.ExitCode)"
}

$editorLog = Join-Path $logDirectory "windows_editor_launcher.stdout.log"
$editorErr = Join-Path $logDirectory "windows_editor_launcher.stderr.log"
$editorProcess = Start-Process `
    -FilePath "cmd.exe" `
    -ArgumentList @(
        "/c",
        "call `"$editorLauncher`" --headless --quit"
    ) `
    -WorkingDirectory $projectRoot `
    -Wait `
    -PassThru `
    -NoNewWindow `
    -RedirectStandardOutput $editorLog `
    -RedirectStandardError $editorErr
if ($editorProcess.ExitCode -ne 0) {
    Get-Content -LiteralPath $editorLog | Select-Object -Last 20
    Get-Content -LiteralPath $editorErr | Select-Object -Last 20
    throw "open-editor.cmd smoke failed with exit code $($editorProcess.ExitCode)"
}

Write-Host "WINDOWS_COMPAT_OK godot=$(& $consoleGodot --version) launchers=play.cmd,open-editor.cmd"
