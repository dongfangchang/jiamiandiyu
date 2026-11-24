# Unified headless test entry for Windows (ROADMAP R0-01). Mirrors tools/run_tests.sh.
# Usage: tools\run_tests.ps1 [-IncludeMonkey] [-Filter substring]
param(
    [switch]$IncludeMonkey,
    [string]$Filter = ""
)

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$godot = $env:GODOT
if (-not $godot) {
    $godot = Get-ChildItem -Path (Join-Path $root ".tools\godot-4.7.2") -Recurse -File `
        -Include "Godot_v4.7.2-stable_win64.exe", "Godot_v4.7.2-stable_win64_console.exe" `
        -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $godot -or -not (Test-Path $godot)) {
    Write-Error "run_tests: Godot binary not found; set `$env:GODOT"
    exit 2
}
$timeoutSec = if ($env:TEST_TIMEOUT) { [int]$env:TEST_TIMEOUT } else { 180 }
$logDir = Join-Path $root ".tools\test-logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$targets = @()
Get-ChildItem -Path tests -Recurse -Filter "*_runner.tscn" | Sort-Object FullName | ForEach-Object {
    $script = [IO.Path]::ChangeExtension($_.FullName, ".gd")
    if ((Test-Path $script) -and (Select-String -Path $script -Pattern "^extends SceneTree" -Quiet)) { return }
    $targets += @{ Kind = "scene"; Path = (Resolve-Path -Relative $_.FullName).TrimStart(".\").Replace("\", "/") }
}
Get-ChildItem -Path tests -Recurse -Filter "*.gd" | Sort-Object FullName | ForEach-Object {
    if ((Select-String -Path $_.FullName -Pattern "^extends SceneTree" -Quiet)) {
        $targets += @{ Kind = "script"; Path = (Resolve-Path -Relative $_.FullName).TrimStart(".\").Replace("\", "/") }
    }
}

$pass = 0; $fail = 0; $skipped = 0; $failures = @()
foreach ($t in $targets) {
    $path = $t.Path
    if ($path -like "*capture*" -or (-not $IncludeMonkey -and $path -like "*monkey*")) { $skipped++; continue }
    if ($Filter -and $path -notlike "*$Filter*") { continue }
    $log = Join-Path $logDir (($path -replace "/", "_") + ".log")
    $args = if ($t.Kind -eq "scene") { @("--headless", "--path", ".", "res://$path") } else { @("--headless", "--path", ".", "--script", "res://$path") }
    $proc = Start-Process -FilePath $godot -ArgumentList $args -NoNewWindow -PassThru `
        -RedirectStandardOutput $log -RedirectStandardError "$log.err"
    if (-not $proc.WaitForExit($timeoutSec * 1000)) {
        $proc.Kill(); $code = 124
    } else { $code = $proc.ExitCode }
    $text = (Get-Content -Raw $log -ErrorAction SilentlyContinue) + (Get-Content -Raw "$log.err" -ErrorAction SilentlyContinue)
    if ($code -eq 0 -and $text -notmatch "SCRIPT ERROR|Parse Error") {
        $pass++; Write-Host "PASS  $path"
    } else {
        $fail++; $failures += "$path (exit $code)"; Write-Host "FAIL  $path (exit $code, log $log)"
    }
}

$guardFail = $false
function Guard($mode, $label, $paths, $pattern) {
    $hits = Get-ChildItem -Path $paths -Recurse -Filter "*.gd" -ErrorAction SilentlyContinue |
        Select-String -Pattern $pattern
    if ($hits) {
        Write-Host "GUARD[$mode] ${label}:"
        $hits | Select-Object -First 20 | ForEach-Object { Write-Host "    $_" }
        if ($mode -eq "block") { $script:guardFail = $true }
    }
}
Guard "block" "gameplay/core must stay pure" @("src/gameplay", "src/core") 'FileAccess|randi\(|randf\(|RandomNumberGenerator|^extends (Node|Control)'
Guard "block" "tests must not pin project version" @("tests") 'config/version='
Guard "report" "ui reads files directly (blocking from R2-09)" @("src/ui") 'FileAccess'

Write-Host ""
Write-Host "run_tests: pass=$pass fail=$fail skipped=$skipped guard_block=$guardFail"
$failures | ForEach-Object { Write-Host "  failed: $_" }
if ($fail -gt 0 -or $guardFail) { exit 1 }
exit 0
