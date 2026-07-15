# Runner for the BehaviouralAssessment > Categories & Criteria Dusk suite.
# Single comprehensive test file: bha_Category_TestCas.php (55 methods, class bha_Category_TestCas).
#
# These artifacts live OUTSIDE the test repo, so the runner resolves prime_testing
# via -Project / $env:PRIME_TESTING_PATH with a sensible default.
#   .\run-Category-tests.ps1 -SyncDB
param(
    [string]$Filter = "bha_Category_TestCas",   # default: the whole Category suite
    [switch]$SyncDB,
    [string]$PhpPath = "php",
    [string]$Project = ""
)

if (-not $Project) {
    $Project = if ($env:PRIME_TESTING_PATH) { $env:PRIME_TESTING_PATH } else { "/Users/bkwork/Herd/prime_testing" }
}

if (-not (Test-Path "$Project\artisan")) {
    Write-Error "artisan not found at $Project. Set PRIME_TESTING_PATH or pass -Project."
    exit 1
}

$ProofDir = "$PSScriptRoot\proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputFile = "$ProofDir\dusk_run_$Timestamp.txt"
$LatestLink = "$ProofDir\dusk_run_latest.txt"

# Prerequisite reminder: the module must be enabled in modules_statuses.json,
# else every /behavioural-assessment route returns 404.
Write-Host "== Prereq: ensure `"BehaviouralAssessment`": true in $Project\modules_statuses.json =="

$env:APP_ENV = "testing"

if ($SyncDB) {
    & $PhpPath "$Project\artisan" migrate:fresh --seed --force
}

$FilterArg = if ($Filter) { "--filter=$Filter" } else { "" }

& $PhpPath "$Project\artisan" dusk $FilterArg 2>&1 | Tee-Object -FilePath $OutputFile
$DuskExit = $LASTEXITCODE
Copy-Item $OutputFile $LatestLink -Force

Write-Host "`n=== Test Run Complete ==="
Write-Host "Output: $OutputFile"
$Summary = Select-String -Path $OutputFile -Pattern "Tests:\s+\d" | Select-Object -Last 1
if ($Summary) { Write-Host "Result: $($Summary.Line.Trim())" }
Write-Host "Dusk exit code: $DuskExit"
exit $DuskExit
