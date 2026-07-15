<#
    Runner for MarksheetGeneration -> Dashboard & Navigation Dusk tests (single file).
    PREREQ: MarksheetGeneration must be ENABLED in prime_testing/modules_statuses.json
            (a disabled module returns 404 on every route), and APP_ENV=testing.

    Usage: .\run-Dashboard-tests.ps1 [-Php <path>] [-Filter <f>] [-SyncDb]
#>

param(
    [string]$Php = "php",
    [string]$Filter = "",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"

$ScriptDir      = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot    = (Resolve-Path (Join-Path $ScriptDir "..\..\..\..\..")).Path
$ScreenshotsDir = Join-Path $ScriptDir "screenshots"
$ProofDir       = Join-Path $ScriptDir "proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null

if (Test-Path $ScreenshotsDir) {
    Get-ChildItem -Path $ScreenshotsDir -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "Cleaned old screenshots"
}

# One comprehensive test file per screen — no V1/V2 split.
if ($Filter -ne "") {
    $DuskFilter = $Filter
} else {
    $DuskFilter = "msh_Dashboard_TestCas"
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "dusk_run_$Timestamp.txt"
$LatestFile = Join-Path $ProofDir "dusk_run_latest.txt"

Push-Location $ProjectRoot
try {
    if ($SyncDb) {
        Write-Host "Detecting chrome driver..."
        & $Php artisan dusk:chrome-driver --detect *> $null
    }

    $env:APP_ENV = "testing"
    Write-Host "Running Dusk with filter: $DuskFilter"

    & $Php artisan dusk --filter="$DuskFilter" 2>&1 | Tee-Object -FilePath $ProofFile
    $ExitCode = $LASTEXITCODE

    Copy-Item -Force $ProofFile $LatestFile

    $SummaryLine = Select-String -Path $ProofFile -Pattern 'Tests:\s+\d+, Assertions:\s+\d+, Failures:\s+\d+' |
        Select-Object -Last 1 -ExpandProperty Line
    if (-not $SummaryLine) {
        $SummaryLine = Select-String -Path $ProofFile -Pattern 'OK \(\d+ test' |
            Select-Object -Last 1 -ExpandProperty Line
    }

    Write-Host ""
    Write-Host "============================================"
    if ($SummaryLine) { Write-Host "  RESULTS: $SummaryLine" } else { Write-Host "  RESULTS: see proof file" }
    if ($ExitCode -eq 0) {
        Write-Host "  STATUS: ALL PASSED!"
    } else {
        Write-Host "  STATUS: SOME FAILED (exit $ExitCode)"
    }
    Write-Host "============================================"
    Write-Host "Proof saved at: $ProofFile"
}
finally {
    Remove-Item Env:\APP_ENV -ErrorAction SilentlyContinue
    Pop-Location
}

exit $ExitCode
