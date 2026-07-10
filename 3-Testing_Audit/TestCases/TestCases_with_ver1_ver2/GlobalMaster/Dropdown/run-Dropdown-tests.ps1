<#
    Dusk runner (Windows) - GlobalMaster > Dropdown (central / prime-side)

    Prerequisites (see Validation Report):
      * prime_ai cloned alongside; MAIN_PROJECT_PATH set (TEST_SETUP.md)
      * modules_statuses.json: "GlobalMaster": true AND "Prime": true (else 404)
      * APP_ENV=testing (bypasses CSRF; else 419 on POST)
      * Central host reachable at http://127.0.0.1:8000

    Copy sys_DropdownV1_TestCas.php / sys_DropdownV2_TestCas.php into
      prime_testing\tests\Browser\Modules\Prime\GlobalMaster\Dropdown\
    before running.

    Usage:
      .\run-Dropdown-tests.ps1 [-Php <path>] [-V1Only] [-V2Only] [-Filter <name>] [-SyncDb]
#>
param(
    [string]$Php = "php",
    [string]$Filter = "",
    [switch]$V1Only,
    [switch]$V2Only,
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProofDir  = Join-Path $ScriptDir "proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$Stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "dropdown_dusk_$Stamp.log"

$env:APP_ENV = "testing"
"== GlobalMaster > Dropdown Dusk run @ $Stamp ==" | Tee-Object -FilePath $ProofFile

# Clean stale screenshots.
Get-ChildItem -Path $ScriptDir -Recurse -Directory -Filter "screenshots" -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ChildItem -Path $_.FullName -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }

if ($SyncDb) {
    "-- Refreshing test DB --" | Tee-Object -FilePath $ProofFile -Append
    & $Php artisan migrate:fresh --seed --env=testing 2>&1 | Tee-Object -FilePath $ProofFile -Append
}

function Run-Suite([string]$ClassName) {
    $flt = "--filter=$ClassName"
    if ($Filter -ne "") { $flt = "--filter=$Filter" }
    "-- Running $ClassName ($flt) --" | Tee-Object -FilePath $ProofFile -Append
    & $Php artisan dusk $flt 2>&1 | Tee-Object -FilePath $ProofFile -Append
    return $LASTEXITCODE
}

$exit = 0
if (-not $V2Only) { $c = Run-Suite "sys_DropdownV1_TestCas"; if ($c -ne 0) { $exit = $c } }
if (-not $V1Only) { $c = Run-Suite "sys_DropdownV2_TestCas"; if ($c -ne 0) { $exit = $c } }

"== Summary ==" | Tee-Object -FilePath $ProofFile -Append
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|OK|FAILURES|Failures:|Error" |
    Select-Object -Last 8 | ForEach-Object { $_.Line } | Tee-Object -FilePath $ProofFile -Append
"Proof: $ProofFile"
exit $exit
