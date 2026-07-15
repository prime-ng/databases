<#
    Dropdown (PRM / Prime, central) - Dusk runner (Windows PowerShell)
    Runs the single comprehensive suite: sys_Dropdown_TestCas.php

    Prerequisites:
      - Prime module ENABLED in prime_testing/modules_statuses.json
      - App served at http://127.0.0.1:8000 (APP_ENV=testing)
      - Test file copied into: tests/Browser/Modules/Prime/Dropdown/sys_Dropdown_TestCas.php
    Usage:
      ./run-Dropdown-tests.ps1 [-Php C:\php\php.exe] [-Filter test_dropdown_01] [-SyncDb]
#>
param(
    [string]$Php    = "php",
    [string]$Filter = "sys_Dropdown_TestCas",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProofDir  = Join-Path $ScriptDir "proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$Stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "dropdown_dusk_$Stamp.log"

$RunnerRoot = if ($env:MAIN_PROJECT_PATH) { $env:MAIN_PROJECT_PATH } else { "C:\Herd\prime_testing" }
if (-not (Test-Path $RunnerRoot)) { Write-Error "Runner root not found: $RunnerRoot"; exit 3 }
Set-Location $RunnerRoot

"== Dropdown Dusk run ==" | Tee-Object -FilePath $ProofFile
"Runner root : $RunnerRoot" | Tee-Object -FilePath $ProofFile -Append
"Filter      : $Filter"     | Tee-Object -FilePath $ProofFile -Append

# Clean old per-feature screenshots.
$ShotDir = Join-Path $RunnerRoot "tests/Browser/Modules/Prime/Dropdown/screenshots"
if (Test-Path $ShotDir) { Remove-Item "$ShotDir/*.png" -Force -ErrorAction SilentlyContinue }

if ($SyncDb) {
    "-- migrating central DB --" | Tee-Object -FilePath $ProofFile -Append
    & $Php artisan migrate --force 2>&1 | Tee-Object -FilePath $ProofFile -Append
}

$env:APP_ENV = "testing"
"-- running dusk --" | Tee-Object -FilePath $ProofFile -Append
& $Php artisan dusk --filter="$Filter" 2>&1 | Tee-Object -FilePath $ProofFile -Append
$DuskExit = $LASTEXITCODE

""                                | Tee-Object -FilePath $ProofFile -Append
"== Summary =="                   | Tee-Object -FilePath $ProofFile -Append
$Summary = Select-String -Path $ProofFile -Pattern 'Tests:|Assertions:|OK \(|FAILURES!' | Select-Object -Last 3
if ($Summary) { $Summary.Line | Tee-Object -FilePath $ProofFile -Append } else { "<no summary line parsed>" | Tee-Object -FilePath $ProofFile -Append }
"Dusk exit code: $DuskExit"       | Tee-Object -FilePath $ProofFile -Append
"Proof: $ProofFile"

exit $DuskExit
