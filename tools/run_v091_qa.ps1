param(
    [switch]$Full
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$godot = Join-Path $projectRoot ".tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe"
$logDirectory = Join-Path $projectRoot ".tools\qa-logs"
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null

$checks = @(
    @{ Name = "infrastructure"; Args = @("--headless","--path",$projectRoot,"--script","res://tests/infrastructure/test_runner.gd") },
    @{ Name = "route_backend"; Args = @("--headless","--path",$projectRoot,"res://tests/infrastructure/route_backend_runner.tscn") },
    @{ Name = "challenge_backend"; Args = @("--headless","--path",$projectRoot,"res://tests/infrastructure/challenge_backend_runner.tscn") },
    @{ Name = "v07_backend"; Args = @("--headless","--path",$projectRoot,"res://tests/infrastructure/v07_backend_runner.tscn") },
    @{ Name = "preferences"; Args = @("--headless","--path",$projectRoot,"--script","res://tests/infrastructure/preferences_service_runner.gd") },
    @{ Name = "diagnostics"; Args = @("--headless","--path",$projectRoot,"--script","res://tests/infrastructure/diagnostics_service_runner.gd") },
    @{ Name = "gameplay"; Args = @("--headless","--path",$projectRoot,"res://tests/gameplay/test_runner.tscn") },
    @{ Name = "progression"; Args = @("--headless","--path",$projectRoot,"res://tests/gameplay/progression_test_runner.tscn") },
    @{ Name = "route"; Args = @("--headless","--path",$projectRoot,"res://tests/gameplay/route_test_runner.tscn") },
    @{ Name = "challenge"; Args = @("--headless","--path",$projectRoot,"res://tests/gameplay/challenge_test_runner.tscn") },
    @{ Name = "v07_deck"; Args = @("--headless","--path",$projectRoot,"res://tests/gameplay/v07_deck_test_runner.tscn") },
    @{ Name = "v07_challenge"; Args = @("--headless","--path",$projectRoot,"res://tests/gameplay/v07_challenge_test_runner.tscn") },
    @{ Name = "ui"; Args = @("--headless","--path",$projectRoot,"res://tests/ui/ui_smoke_runner.tscn") },
    @{ Name = "progression_ui"; Args = @("--headless","--path",$projectRoot,"res://tests/ui/ui_progression_smoke_runner.tscn") },
    @{ Name = "route_ui"; Args = @("--headless","--path",$projectRoot,"res://tests/ui/v05_route_ui_smoke_runner.tscn") },
    @{ Name = "challenge_ui"; Args = @("--headless","--path",$projectRoot,"res://tests/ui/v06_challenge_ui_smoke_runner.tscn") },
    @{ Name = "deck_ui"; Args = @("--headless","--path",$projectRoot,"res://tests/ui/v07_deck_ui_smoke_runner.tscn") },
    @{ Name = "system_ui"; Args = @("--headless","--path",$projectRoot,"res://tests/ui/v08_system_ui_smoke_runner.tscn") },
    @{ Name = "integration"; Args = @("--headless","--path",$projectRoot,"res://tests/integration/v07_app_flow_runner.tscn") },
    @{ Name = "v091_regression"; Args = @("--headless","--path",$projectRoot,"res://tests/integration/v091_regression_runner.tscn") },
    @{ Name = "v091_app_destructive"; Args = @("--headless","--path",$projectRoot,"res://tests/integration/v091_app_destructive_runner.tscn") },
    @{ Name = "v092_destructive"; Args = @("--headless","--path",$projectRoot,"res://tests/integration/v092_destructive_runner.tscn") },
    @{ Name = "simulation_contract"; Args = @("--headless","--path",$projectRoot,"res://tests/simulation/balance_contract_runner.tscn") },
    @{ Name = "economy"; Args = @("--headless","--path",$projectRoot,"res://tests/simulation/v04_economy_contract_runner.tscn") },
    @{ Name = "route_contract"; Args = @("--headless","--path",$projectRoot,"res://tests/simulation/v05_route_contract_runner.tscn") },
    @{ Name = "challenge_contract"; Args = @("--headless","--path",$projectRoot,"res://tests/simulation/v06_challenge_contract_runner.tscn") },
    @{ Name = "deck_contract"; Args = @("--headless","--path",$projectRoot,"res://tests/simulation/v07_deck_contract_runner.tscn") },
    @{ Name = "main"; Args = @("--headless","--path",$projectRoot,"--quit-after","5") }
)

$failed = @()
foreach ($check in $checks) {
    $stdout = Join-Path $logDirectory ($check.Name + ".stdout.log")
    $stderr = Join-Path $logDirectory ($check.Name + ".stderr.log")
    $process = Start-Process -FilePath $godot -ArgumentList $check.Args -Wait -PassThru -NoNewWindow -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    if ($process.ExitCode -eq 0) {
        Write-Host "[PASS] $($check.Name)"
    } else {
        Write-Host "[FAIL] $($check.Name) exit=$($process.ExitCode)"
        Get-Content -LiteralPath $stdout | Select-Object -Last 15
        Get-Content -LiteralPath $stderr | Select-Object -Last 15
        $failed += $check.Name
    }
}

if ($failed.Count -gt 0) {
    throw "QA failed: $($failed -join ', ')"
}
Write-Host "V0.9.2 QA PASS: $($checks.Count) checks"
