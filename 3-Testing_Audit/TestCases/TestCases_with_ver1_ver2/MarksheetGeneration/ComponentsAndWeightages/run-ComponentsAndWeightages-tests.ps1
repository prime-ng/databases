# =============================================================================
# Runner - MarksheetGeneration / Components & Weightages Dusk tests (Windows)
# Mirrors the golden reference runner. Runs V1 then V2 (or filtered), tees the
# output to a timestamped proof file, parses the summary and exits with the
# dusk exit code.
#
# Prerequisites:
#   - MarksheetGeneration ENABLED in prime_testing/modules_statuses.json (else 404).
#   - APP_ENV=testing (bypasses CSRF/419).
#   - prime_ai cloned alongside; MAIN_PROJECT_PATH set (see TEST_SETUP.md).
#   - MSH permissions granted (suite grants them in setUp / D39-MSH).
#
# Usage:
#   .\run-ComponentsAndWeightages-tests.ps1 [-Php <path>] [-Filter <name>]
#                                           [-V1Only] [-V2Only]
# =============================================================================
param(
    [string]$Php = "php",
    [string]$Filter = "",
    [switch]$V1Only,
    [switch]$V2Only
)

$ErrorActionPreference = "Continue"

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = if ($env:MAIN_PROJECT_PATH) { $env:MAIN_PROJECT_PATH } else { "C:\Herd\prime_testing" }
$ProofDir    = Join-Path $ScriptDir "proof"
if (-not (Test-Path $ProofDir)) { New-Item -ItemType Directory -Path $ProofDir | Out-Null }
$Stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "components-and-weightages-$Stamp.log"

$V1Class = "msh_ComponentsAndWeightagesV1_TestCas"
$V2Class = "msh_ComponentsAndWeightagesV2_TestCas"

# Clean stale screenshots.
$ShotDir = Join-Path $ProjectRoot "tests\Browser\Modules\MarksheetGeneration\ComponentsAndWeightages\screenshots"
if (Test-Path $ShotDir) { Remove-Item "$ShotDir\*.png" -ErrorAction SilentlyContinue }

function Run-Suite([string]$FilterName) {
    "=== Running: --filter=$FilterName ===" | Tee-Object -FilePath $ProofFile -Append
    Push-Location $ProjectRoot
    & $Php artisan dusk --filter="$FilterName" 2>&1 | Tee-Object -FilePath $ProofFile -Append
    $code = $LASTEXITCODE
    Pop-Location
    return $code
}

$ExitCode = 0
if ($Filter -ne "") {
    $ExitCode = Run-Suite $Filter
} elseif ($V1Only) {
    $ExitCode = Run-Suite $V1Class
} elseif ($V2Only) {
    $ExitCode = Run-Suite $V2Class
} else {
    $rc1 = Run-Suite $V1Class
    $rc2 = Run-Suite $V2Class
    $ExitCode = if ($rc1 -ne 0) { $rc1 } else { $rc2 }
}

"" | Tee-Object -FilePath $ProofFile -Append
"=== Summary ===" | Tee-Object -FilePath $ProofFile -Append
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|OK|FAILURES|Errors:" |
    Select-Object -Last 6 | ForEach-Object { $_.Line } | Tee-Object -FilePath $ProofFile -Append
"Proof: $ProofFile" | Tee-Object -FilePath $ProofFile -Append
"Exit code: $ExitCode" | Tee-Object -FilePath $ProofFile -Append
exit $ExitCode
