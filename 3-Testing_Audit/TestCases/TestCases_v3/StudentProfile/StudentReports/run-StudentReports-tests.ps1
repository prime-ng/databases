# ---------------------------------------------------------------------------
# StudentProfile / StudentReports - Dusk runner (Windows PowerShell)
# ONE test file per screen: std_StudentReports_TestCas.php
#
# Prerequisites:
#   - module STUDENT enabled in prime_testing/modules_statuses.json (else 404)
#   - APP_ENV=testing ; Chromedriver running ; tenant seeded with students
# ---------------------------------------------------------------------------
param(
    [string]$PhpPath = "php",
    [string]$Filter  = ""
)

$ErrorActionPreference = "Continue"
$TestClass    = "std_StudentReports_TestCas"
$ProjectRoot  = if ($env:MAIN_PROJECT_PATH) { $env:MAIN_PROJECT_PATH } else { "C:\Herd\prime_testing" }
$ProofDir     = Join-Path $PSScriptRoot "proof"
if (-not (Test-Path $ProofDir)) { New-Item -ItemType Directory -Path $ProofDir | Out-Null }
$Stamp        = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile    = Join-Path $ProofDir "StudentReports_$Stamp.log"

Set-Location $ProjectRoot

# Clean stale screenshots
Get-ChildItem "tests/Browser/console/screenshots/student-reports-fail-*.png" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$FilterArg = "--filter=$TestClass"
if ($Filter -ne "") { $FilterArg = "--filter=$Filter" }

Write-Host "Running Dusk: $TestClass ($FilterArg)"
Write-Host "Proof: $ProofFile"

$env:APP_ENV = "testing"
& $PhpPath artisan dusk $FilterArg 2>&1 | Tee-Object -FilePath $ProofFile
$DuskExit = $LASTEXITCODE

Write-Host ""
Write-Host "===================== SUMMARY ====================="
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|OK|FAILURES|Error" | Select-Object -Last 5
Write-Host "Exit code: $DuskExit"
Write-Host "==================================================="

exit $DuskExit
