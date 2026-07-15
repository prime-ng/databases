<#
    Runner: StudentProfile / StudentCreate Dusk suite (single file: std_StudentCreate_TestCas.php)
    Usage: .\run-StudentCreate-tests.ps1 [-Php php] [-Filter methodName] [-SyncDb]
    NOTE: STUDENT module must be enabled in modules_statuses.json (else 404).
#>
param(
    [string]$Php = "php",
    [string]$Filter = "std_StudentCreate_TestCas",
    [switch]$SyncDb
)

$ErrorActionPreference = "Stop"

$RunnerRoot = $env:MAIN_PROJECT_PATH
if ([string]::IsNullOrEmpty($RunnerRoot)) { $RunnerRoot = "C:\Herd\prime_testing" }
Set-Location $RunnerRoot

$env:APP_ENV = "testing"

Write-Host "== StudentCreate Dusk run =="
Write-Host "PHP:     $Php"
Write-Host "Filter:  $Filter"
Write-Host "Runner:  $RunnerRoot"

# Clean old screenshots for this feature
Get-ChildItem "tests/Browser/console/screenshots/student-create-*.png" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

if ($SyncDb) {
    Write-Host "-- Syncing tenant DB --"
    & $Php artisan migrate --database=tenant --force
}

$ProofDir = "proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "StudentCreate_$Stamp.log"

& $Php artisan dusk --filter="$Filter" 2>&1 | Tee-Object -FilePath $ProofFile
$ExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "== Summary =="
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|OK|FAILURES" | Select-Object -Last 5 | ForEach-Object { $_.Line }
Write-Host "Proof: $ProofFile"
Write-Host "Exit:  $ExitCode"
exit $ExitCode
