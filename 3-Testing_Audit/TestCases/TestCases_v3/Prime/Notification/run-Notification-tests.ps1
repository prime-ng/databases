# Prime (PRM) - Notification Dusk runner (central; host http://127.0.0.1:8000)
# Single comprehensive suite: prm_Notification_TestCas.php
param(
    [string]$PhpBin  = "php",
    [string]$Filter  = "prm_Notification_TestCas",
    [string]$TestRepo = "C:\Herd\prime_testing"
)

$ErrorActionPreference = "Continue"
$TestPath = "tests/Browser/Modules/Prime/Notification/prm_Notification_TestCas.php"

Set-Location $TestRepo

# Prime/central tests must run on 127.0.0.1:8000 and under APP_ENV=testing (CSRF bypass).
$env:APP_ENV = "testing"

$Stamp    = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir = Join-Path $TestRepo "tests/Browser/Modules/Prime/Notification/proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$ProofFile = Join-Path $ProofDir "notification_dusk_$Stamp.log"

# Clean old screenshots
$ShotDir = Join-Path $TestRepo "tests/Browser/Modules/Prime/Notification/screenshots"
if (Test-Path $ShotDir) { Remove-Item "$ShotDir\*.png" -Force -ErrorAction SilentlyContinue }

Write-Host "== Prime Notification Dusk run =="
Write-Host "Filter : $Filter"
Write-Host "Proof  : $ProofFile"
Write-Host "Host   : http://127.0.0.1:8000  (ensure the app is served here)"
Write-Host "Prereq : Prime module enabled in modules_statuses.json"
Write-Host "================================="

& $PhpBin artisan dusk --filter=$Filter $TestPath 2>&1 | Tee-Object -FilePath $ProofFile
$ExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "== Summary =="
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|OK|FAILURES|Errors:" | Select-Object -Last 5
Write-Host "Exit code: $ExitCode"
exit $ExitCode
