<#
.SYNOPSIS
    Runner - BehaviouralAssessment / Incident Dusk suite.
    One comprehensive test file: bha_Incident_TestCas.php (49 methods).

.EXAMPLE
    ./run-Incident-tests.ps1
    ./run-Incident-tests.ps1 -Filter test_incident_92
    ./run-Incident-tests.ps1 -Php "C:\php\php.exe" -SyncDb
#>
[CmdletBinding()]
param(
    [string]$Php    = "php",
    [string]$Filter = "",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"

# --- Config -----------------------------------------------------------------
$AppRepo   = if ($env:APP_REPO) { $env:APP_REPO } else { "/Users/bkwork/Herd/prime_testing" }
$TestClass = "bha_Incident_TestCas"

if (-not (Test-Path $AppRepo)) {
    Write-Error "APP_REPO not found: $AppRepo"
    exit 2
}
Set-Location $AppRepo

# --- Proof dir + screenshots ------------------------------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProofDir  = Join-Path $ScriptDir "proof"
if (-not (Test-Path $ProofDir)) { New-Item -ItemType Directory -Path $ProofDir | Out-Null }
$Stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "Incident_$Stamp.log"

$ShotDir = Join-Path $AppRepo "tests/Browser/Modules/BehaviouralAssessment/Incident/screenshots"
if (Test-Path $ShotDir) {
    Write-Host "Cleaning old screenshots in $ShotDir"
    Get-ChildItem -Path $ShotDir -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

# --- Optional DB sync -------------------------------------------------------
if ($SyncDb) {
    Write-Host "Syncing tenant migrations..."
    & $Php artisan tenants:migrate --force 2>&1 | Tee-Object -FilePath $ProofFile -Append
}

# --- Build dusk filter ------------------------------------------------------
$DuskFilter = $TestClass
if ($Filter -ne "") { $DuskFilter = $Filter }

Write-Host "======================================================================"
Write-Host " Incident Dusk suite"
Write-Host " php     : $Php"
Write-Host " filter  : $DuskFilter"
Write-Host " proof   : $ProofFile"
Write-Host "======================================================================"

& $Php artisan dusk --filter="$DuskFilter" 2>&1 | Tee-Object -FilePath $ProofFile -Append
$DuskExit = $LASTEXITCODE

# --- Parse summary ----------------------------------------------------------
Write-Host ""
Write-Host "---------------------------- SUMMARY ---------------------------------"
$SummaryLine = Select-String -Path $ProofFile -Pattern 'Tests:.*Assertions:' | Select-Object -Last 1
if ($SummaryLine) {
    Write-Host $SummaryLine.Line
} else {
    Write-Host "No PHPUnit summary line found (see $ProofFile)."
}
Write-Host "Dusk exit code: $DuskExit"
Write-Host "Proof: $ProofFile"
Write-Host "----------------------------------------------------------------------"

exit $DuskExit
