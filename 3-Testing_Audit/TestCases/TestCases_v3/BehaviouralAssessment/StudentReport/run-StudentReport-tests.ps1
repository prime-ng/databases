<#
    Runner — BehaviouralAssessment / StudentReport Dusk suite (single comprehensive file).
    Class name = bha_StudentReport_TestCas (no V1/V2 split).

    Usage:
        ./run-StudentReport-tests.ps1 [-Php <php-bin>] [-Filter <pattern>] [-SyncDb]

    Prerequisites:
        - prime_ai cloned alongside prime_testing; MAIN_PROJECT_PATH set (see TEST_SETUP.md)
        - BehaviouralAssessment ENABLED in prime_testing/modules_statuses.json (else 404 on all routes)
        - APP_ENV=testing (set below so state-changing requests bypass CSRF)
#>

param(
    [string]$Php = "php",
    [string]$Filter = "bha_StudentReport_TestCas",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"

$ScriptDir      = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot    = (Resolve-Path (Join-Path $ScriptDir "..\..\..\..\..")).Path
$ScreenshotsDir = Join-Path $ScriptDir "screenshots"
$ProofDir       = Join-Path $ScriptDir "proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null

# Clean old screenshots
if (Test-Path $ScreenshotsDir) {
    Get-ChildItem -Path $ScreenshotsDir -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
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

    $SummaryLine = Select-String -Path $ProofFile -Pattern 'Tests:\s+\d+,\s+Assertions:\s+\d+,\s+Failures:\s+\d+' | Select-Object -Last 1
    if ($SummaryLine) {
        $Total = [regex]::Match($SummaryLine.Line, 'Tests:\s+(\d+)').Groups[1].Value
        $Fails = [regex]::Match($SummaryLine.Line, 'Failures:\s+(\d+)').Groups[1].Value
        $Passed = [int]$Total - [int]$Fails
        Write-Host ""
        Write-Host "============================================"
        Write-Host "  RESULTS (StudentReport):"
        Write-Host "  Total: $Total, Passed: $Passed, Failed: $Fails"
        if ([int]$Fails -eq 0) {
            Write-Host "  STATUS: ALL PASSED!"
        } else {
            Write-Host "  STATUS: SOME FAILED"
        }
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
