# ---------------------------------------------------------------------------
# Runner (Windows) — GlobalMaster :: Session & Board Setup (CENTRAL / prime Dusk)
#
# Prerequisites:
#   * GlobalMaster AND Prime = "true" in prime_testing/modules_statuses.json (both currently false → 404).
#   * APP_ENV=testing (bypasses CSRF; else 419).
#   * Chrome + ChromeDriver running; app served at http://127.0.0.1:8000.
#   * MAIN_PROJECT_PATH pointing at the prime_ai checkout (for source-shape asserts).
#
# Usage:
#   ./run-SessionBoardSetup-tests.ps1 [-Php <path>] [-V1Only] [-V2Only] [-Filter <name>]
# ---------------------------------------------------------------------------
param(
    [string]$Php = "php",
    [string]$Filter = "",
    [switch]$V1Only,
    [switch]$V2Only
)

$ErrorActionPreference = "Continue"

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RunnerRoot = if ($env:TEST_FILE_REPO) { $env:TEST_FILE_REPO } else { "/Users/bkwork/Herd/prime_testing" }
$ProofDir   = Join-Path $ScriptDir "proof"
if (-not (Test-Path $ProofDir)) { New-Item -ItemType Directory -Path $ProofDir | Out-Null }
$Stamp      = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile  = Join-Path $ProofDir "SessionBoardSetup_$Stamp.log"

$V1Class = "glb_SessionBoardSetupV1_TestCas"
$V2Class = "glb_SessionBoardSetupV2_TestCas"

"== Session & Board Setup Dusk run @ $Stamp ==" | Tee-Object -FilePath $ProofFile
"Runner root: $RunnerRoot" | Tee-Object -FilePath $ProofFile -Append

# Clean stale screenshots (best-effort).
Get-ChildItem -Path (Join-Path $RunnerRoot "tests/Browser/screenshots") -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -ErrorAction SilentlyContinue

Set-Location $RunnerRoot
$env:APP_ENV = "testing"

function Run-Suite([string]$Cls) {
    $flt = if ($Filter -ne "") { $Filter } else { $Cls }
    "" | Tee-Object -FilePath $ProofFile -Append
    "--- Running $Cls (filter=$flt) ---" | Tee-Object -FilePath $ProofFile -Append
    & $Php artisan dusk --filter="$flt" 2>&1 | Tee-Object -FilePath $ProofFile -Append
    return $LASTEXITCODE
}

$Exit = 0
if (-not $V2Only) { $rc = Run-Suite $V1Class; if ($rc -ne 0) { $Exit = $rc } }
if (-not $V1Only) { $rc = Run-Suite $V2Class; if ($rc -ne 0) { $Exit = $rc } }

"" | Tee-Object -FilePath $ProofFile -Append
"== Summary ==" | Tee-Object -FilePath $ProofFile -Append
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|OK|FAILURES|Skipped" | Select-Object -Last 8 | ForEach-Object { $_.Line } | Tee-Object -FilePath $ProofFile -Append
"Proof: $ProofFile" | Tee-Object -FilePath $ProofFile -Append
"Exit code: $Exit" | Tee-Object -FilePath $ProofFile -Append
exit $Exit
