<#
.SYNOPSIS
    run-StudentRemark-tests.ps1 — BehaviouralAssessment / StudentRemark Dusk suite runner (Windows PowerShell).

.DESCRIPTION
    Runs the single comprehensive test file bha_StudentRemark_TestCas.php (41 methods):
      * cleans old feature screenshots,
      * optionally syncs the DB,
      * runs `artisan dusk --filter=...`,
      * tees output to a timestamped proof/ file,
      * parses the "Tests: N, Assertions: A" summary,
      * exits with the dusk exit code.

.PARAMETER Php
    PHP binary to use (default: php).

.PARAMETER Filter
    Dusk --filter value (default: the whole class bha_StudentRemark_TestCas).

.PARAMETER SyncDb
    Run `artisan migrate --force` before the suite.

.NOTES
    Prerequisites (see the Validation Report):
      * Run from the prime_testing runner root.
      * BehaviouralAssessment ENABLED in modules_statuses.json (else 404 on every route).
      * APP_ENV=testing (this script sets it so Dusk bypasses CSRF).
      * prime_ai cloned alongside; MAIN_PROJECT_PATH set.
      * A tenant with sch_employees + sch_class_section_jnt + sch_org_academic_sessions_jnt + std_students rows
        (else the remark-graph tests self-skip defensively).

.EXAMPLE
    ./run-StudentRemark-tests.ps1
    ./run-StudentRemark-tests.ps1 -Filter test_student_remark_47_bulk_rate_write_path_fatals_on_draft_bug_ba_rem_001
    ./run-StudentRemark-tests.ps1 -SyncDb
#>

param(
    [string]$Php = "php",
    [string]$Filter = "bha_StudentRemark_TestCas",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"
$env:APP_ENV = "testing"

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$proofDir  = "proof"
if (-not (Test-Path $proofDir)) { New-Item -ItemType Directory -Path $proofDir | Out-Null }
$proofFile = Join-Path $proofDir "StudentRemark_dusk_$timestamp.log"

Write-Host "======================================================================"
Write-Host " BehaviouralAssessment / StudentRemark - Dusk suite"
Write-Host " PHP     : $Php"
Write-Host " Filter  : $Filter"
Write-Host " Proof   : $proofFile"
Write-Host "======================================================================"

# Clean previously captured screenshots for this feature (best-effort).
$shotDir = "tests/Browser/Modules/BehaviouralAssessment/StudentRemark/screenshots"
if (Test-Path $shotDir) {
    Write-Host "Cleaning old screenshots in $shotDir ..."
    Get-ChildItem -Path $shotDir -Filter *.png -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

if ($SyncDb) {
    Write-Host "Syncing DB (migrate --force) ..."
    & $Php artisan migrate --force 2>&1 | Tee-Object -FilePath $proofFile -Append
}

Write-Host "Running: $Php artisan dusk --filter=$Filter"
& $Php artisan dusk --filter=$Filter 2>&1 | Tee-Object -FilePath $proofFile -Append
$duskExit = $LASTEXITCODE

Write-Host "----------------------------------------------------------------------"
$summaryLine = Select-String -Path $proofFile -Pattern 'Tests:\s+\d+' | Select-Object -Last 1
if ($summaryLine) {
    Write-Host " Result summary: $($summaryLine.Line.Trim())"
} else {
    Write-Host " Result summary: (no 'Tests:' line parsed — check $proofFile)"
}
Write-Host " Dusk exit code : $duskExit"
Write-Host " Proof file     : $proofFile"
Write-Host "======================================================================"

exit $duskExit
