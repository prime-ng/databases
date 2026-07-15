<#
=============================================================================
 StudentEdit (StudentProfile) - Dusk runner (Windows / PowerShell)
 ONE test file per screen: std_StudentEdit_TestCas.php

 Prerequisites:
   - StudentProfile ENABLED in prime_testing/modules_statuses.json (else 404 on all routes)
   - APP_ENV=testing (bypasses CSRF; else 419 on state-changing requests)
   - Chromedriver running; tenant seeded at DUSK_TENANT_URL
=============================================================================
#>
param(
    [string]$Filter = "",
    [string]$PhpBin = "php"
)

$ErrorActionPreference = "Continue"
$TestClass = "std_StudentEdit_TestCas"
$ProofDir  = "proof"
$Stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "StudentEdit_$Stamp.log"

New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null

Write-Host "== Cleaning old screenshots =="
Remove-Item "tests/Browser/console/screenshots/student-edit-*.png" -ErrorAction SilentlyContinue

if ([string]::IsNullOrWhiteSpace($Filter)) { $Filter = $TestClass }

Write-Host "== Running $TestClass (filter: $Filter) =="
& $PhpBin artisan dusk --filter="$Filter" 2>&1 | Tee-Object -FilePath $ProofFile
$DuskExit = $LASTEXITCODE

Write-Host ""
Write-Host "== Summary =="
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|OK|FAILURES|Error" |
    Select-Object -Last 5 | ForEach-Object { $_.Line }

Write-Host "Proof saved to: $ProofFile"
Write-Host "Dusk exit code: $DuskExit"
exit $DuskExit
