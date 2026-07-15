<#
    Runner — BehaviouralAssessment / CategoryPerformance Dusk suite (single comprehensive file).
    Class name = bha_CategoryPerformance_TestCas (no V1/V2 split).

    Usage:
      ./run-CategoryPerformance-tests.ps1 [-Php <php-bin>] [-Filter <pattern>] [-SyncDb]

    Prerequisites:
      - prime_ai cloned alongside prime_testing; MAIN_PROJECT_PATH set (see TEST_SETUP.md)
      - BehaviouralAssessment ENABLED in prime_testing/modules_statuses.json (else 404 on all routes)
      - APP_ENV=testing (set below so state-changing requests bypass CSRF)

    NOTE: test _12 expects the Category Performance page to currently return HTTP 500 (BUG-BA-013:
          categories() aggregates AVG(score) on a non-existent column). This is intentional — the
          test proves current broken behaviour. When BUG-BA-013 is fixed, flip _12 to expect 200.
#>

param(
    [string]$Php = "php",
    [string]$Filter = "bha_CategoryPerformance_TestCas",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"

$ScriptDir      = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot    = (Resolve-Path (Join-Path $ScriptDir "..\..\..\..\..")).Path
$ScreenshotsDir = Join-Path $ScriptDir "screenshots"
$ProofDir       = Join-Path $ScriptDir "proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null

if (Test-Path $ScreenshotsDir) {
    Remove-Item -Path (Join-Path $ScreenshotsDir "*.png") -Force -ErrorAction SilentlyContinue
    Write-Host "Cleaned old screenshots"
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "dusk_run_$Timestamp.txt"
$LatestFile = Join-Path $ProofDir "dusk_run_latest.txt"

Push-Location $ProjectRoot
try {
    if ($SyncDb) {
        Write-Host "Detecting matching ChromeDriver..."
        & $Php artisan dusk:chrome-driver --detect *> $null
    }

    $env:APP_ENV = "testing"
    Write-Host "Running Dusk with filter: $Filter"
    Write-Host "Prerequisite: BehaviouralAssessment must be enabled in modules_statuses.json"

    & $Php artisan dusk --filter="$Filter" 2>&1 | Tee-Object -FilePath $ProofFile
    $ExitCode = $LASTEXITCODE

    Copy-Item -Path $ProofFile -Destination $LatestFile -Force

    $summary = Select-String -Path $ProofFile -Pattern 'Tests:\s+(\d+),\s+Assertions:\s+(\d+),\s+Failures:\s+(\d+)' | Select-Object -Last 1
    if ($summary) {
        $total = [int]$summary.Matches[0].Groups[1].Value
        $fails = [int]$summary.Matches[0].Groups[3].Value
        $passed = $total - $fails
        Write-Host ""
        Write-Host "============================================"
        Write-Host "  RESULTS (CategoryPerformance):"
        Write-Host "  Total: $total, Passed: $passed, Failed: $fails"
        if ($fails -eq 0) { Write-Host "  STATUS: ALL PASSED!" } else { Write-Host "  STATUS: SOME FAILED" }
        Write-Host "============================================"
    }
    elseif (Select-String -Path $ProofFile -Pattern "OK \(") {
        Write-Host "STATUS: ALL PASSED (see proof)."
    }

    Write-Host "Proof saved at: $ProofFile"
    exit $ExitCode
}
finally {
    Pop-Location
}
