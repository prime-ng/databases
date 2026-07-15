<#
    Runner: Prime / ActivityLog (central, read-only) Dusk suite.
    One comprehensive test file: sys_ActivityLog_TestCas.php
#>
param(
    [string]$PhpBin = "php",
    [string]$Filter = "sys_ActivityLog_TestCas",
    [string]$RunnerDir = $(if ($env:MAIN_PROJECT_PATH) { $env:MAIN_PROJECT_PATH } else { "C:\Herd\prime_testing" })
)

Write-Host "== Prime/ActivityLog Dusk run =="
Write-Host "Runner:  $RunnerDir"
Write-Host "Filter:  $Filter"

if (-not (Test-Path $RunnerDir)) {
    Write-Error "Runner dir not found: $RunnerDir"
    exit 2
}
Set-Location $RunnerDir

Write-Host "-- prerequisites: APP_ENV=testing, Chrome driver up, app at http://127.0.0.1:8000, prime_db migrated (sys_central_activity_logs)."

# Clean old screenshots.
$shots = "tests/Browser/Modules/Prime/ActivityLog/screenshots"
if (Test-Path $shots) { Remove-Item "$shots/*.png" -ErrorAction SilentlyContinue }

# Proof capture.
$proofDir = "tests/Browser/Modules/Prime/ActivityLog/proof"
New-Item -ItemType Directory -Force -Path $proofDir | Out-Null
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$proofFile = Join-Path $proofDir "activitylog_$stamp.log"

$env:APP_ENV = "testing"
& $PhpBin artisan dusk --filter=$Filter 2>&1 | Tee-Object -FilePath $proofFile
$code = $LASTEXITCODE

Write-Host ""
Write-Host "== Summary =="
Select-String -Path $proofFile -Pattern "Tests:|Assertions:|Failures:|OK|FAILURES" | Select-Object -Last 5 | ForEach-Object { $_.Line }
Write-Host "Proof: $proofFile"
Write-Host "Exit:  $code"
exit $code
