# ---------------------------------------------------------------------------
# MarksheetGeneration - Scheduling & Lifecycle - Dusk runner (Windows PowerShell)
# Runs the single comprehensive suite msh_SchedulingAndLifecycle_TestCas.
#
# Usage:
#   ./run-SchedulingAndLifecycle-tests.ps1 [-Php <php.exe>] [-Filter <method>] [-SyncDb]
#
# Prereqs (see Validation Report Section 7):
#   * MarksheetGeneration: true in prime_testing/modules_statuses.json
#   * APP_ENV=testing (bypasses CSRF)
#   * tenant DB seeded with a config template, an academic session, and the
#     5 status dropdown rows on sys_dropdown_table (key msh_marksheet_schedules.status_id)
# ---------------------------------------------------------------------------
param(
    [string]$Php = "php",
    [string]$Filter = "msh_SchedulingAndLifecycle_TestCas",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"

$ProjectRoot = $env:MAIN_PROJECT_PATH
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = "C:\Herd\prime_testing" }
Set-Location $ProjectRoot

$Ts = Get-Date -Format "yyyyMMdd-HHmmss"
$ProofDir = Join-Path $PSScriptRoot "proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$ProofFile = Join-Path $ProofDir "SchedulingAndLifecycle-$Ts.log"

$Shots = "tests\Browser\Modules\MarksheetGeneration\SchedulingAndLifecycle\screenshots"
if (Test-Path $Shots) { Remove-Item "$Shots\*.png" -Force -ErrorAction SilentlyContinue }

"=== MarksheetGeneration / SchedulingAndLifecycle Dusk run ($Ts) ===" | Tee-Object -FilePath $ProofFile
"Filter: $Filter" | Tee-Object -FilePath $ProofFile -Append

$env:APP_ENV = "testing"

if ($SyncDb) {
    "--- migrating test DB ---" | Tee-Object -FilePath $ProofFile -Append
    & $Php artisan migrate --force 2>&1 | Tee-Object -FilePath $ProofFile -Append
}

"--- running dusk ---" | Tee-Object -FilePath $ProofFile -Append
& $Php artisan dusk --filter="$Filter" 2>&1 | Tee-Object -FilePath $ProofFile -Append
$DuskExit = $LASTEXITCODE

"--- summary ---" | Tee-Object -FilePath $ProofFile -Append
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|OK|FAILURES|Errors" | Select-Object -Last 5 | ForEach-Object { $_.Line } | Tee-Object -FilePath $ProofFile -Append
"Proof: $ProofFile"
"Dusk exit code: $DuskExit"
exit $DuskExit
