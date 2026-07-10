# ---------------------------------------------------------------------------
# Subscription (Billing / prime-side) Dusk runner - PowerShell
# Mirrors the golden-reference runner: filter, V1/V2 toggles, proof capture,
# result parsing, dusk exit code passthrough.
#
# Prereqs:
#   - Billing module ENABLED in prime_testing/modules_statuses.json (else 404)
#   - App reachable at http://127.0.0.1:8000 (central), APP_ENV=testing
#   - ChromeDriver running for Dusk
# Usage:
#   ./run-Subscription-tests.ps1 [-Php <path>] [-Filter <name>] [-V1Only] [-V2Only]
# ---------------------------------------------------------------------------
param(
    [string]$Php = "php",
    [string]$Filter = "",
    [switch]$V1Only,
    [switch]$V2Only
)

$ErrorActionPreference = "Continue"
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = if ($env:MAIN_PROJECT_PATH) { $env:MAIN_PROJECT_PATH } else { $ScriptDir }
$ProofDir   = Join-Path $ScriptDir "proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$Ts         = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile  = Join-Path $ProofDir "subscription_dusk_$Ts.log"

$env:APP_ENV = "testing"

$Classes = @()
if (-not $V2Only) { $Classes += "prm_SubscriptionV1_TestCas" }
if (-not $V1Only) { $Classes += "prm_SubscriptionV2_TestCas" }

"== Subscription Dusk run @ $Ts ==" | Tee-Object -FilePath $ProofFile
"PHP: $Php | project: $ProjectRoot" | Tee-Object -FilePath $ProofFile -Append

# Clean old screenshots
Get-ChildItem -Path (Join-Path $ScriptDir "screenshots") -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$ExitCode = 0
foreach ($Cls in $Classes) {
    "--- Running $Cls ---" | Tee-Object -FilePath $ProofFile -Append
    $FilterArg = $Cls
    if ($Filter -ne "") { $FilterArg = "$Cls::$Filter" }
    Push-Location $ProjectRoot
    & $Php artisan dusk --filter="$FilterArg" 2>&1 | Tee-Object -FilePath $ProofFile -Append
    if ($LASTEXITCODE -ne 0) { $ExitCode = $LASTEXITCODE }
    Pop-Location
}

"== Summary ==" | Tee-Object -FilePath $ProofFile -Append
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|OK|FAILURES|Error" | Select-Object -Last 20 | ForEach-Object { $_.Line } | Tee-Object -FilePath $ProofFile -Append
"Proof: $ProofFile"
exit $ExitCode
