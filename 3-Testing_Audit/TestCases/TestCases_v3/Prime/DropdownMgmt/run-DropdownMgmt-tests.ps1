<#
=============================================================================
 DropdownMgmt (Prime / PRM - CENTRAL) Dusk test runner (Windows PowerShell)
 Single comprehensive suite: sys_DropdownMgmt_TestCas.php
=============================================================================
 Prerequisites (see Validation Report - Environment):
   * Prime module ENABLED in prime_testing/modules_statuses.json (currently false -> routes 404)
   * APP_ENV=testing (bypasses CSRF; else 419 on state-changing requests)
   * Central app served at http://127.0.0.1:8000 (Prime tests hard-require 127.0.0.1)
   * ChromeDriver running for the browser-tagged methods
=============================================================================
#>
param(
    [string]$Filter = "",
    [string]$PhpPath = "php"
)

$ErrorActionPreference = "Continue"
$TestClass = "sys_DropdownMgmt_TestCas"
$TestPath  = "tests/Browser/Modules/Prime/DropdownMgmt/$TestClass.php"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProofDir  = Join-Path $ScriptDir "proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$Stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "dropdownmgmt_dusk_$Stamp.log"

$ShotDir = "tests/Browser/Modules/Prime/DropdownMgmt/screenshots"
if (Test-Path $ShotDir) { Remove-Item "$ShotDir/*.png" -Force -ErrorAction SilentlyContinue }

Write-Host "==============================================================="
Write-Host " DropdownMgmt (PRM central) - Dusk suite"
Write-Host " File   : $TestPath"
if ($Filter -ne "") { Write-Host " Filter : $Filter" } else { Write-Host " Filter : <all methods>" }
Write-Host " Proof  : $ProofFile"
Write-Host "==============================================================="

$env:APP_ENV = "testing"
$Args = @("artisan", "dusk", $TestPath)
if ($Filter -ne "") { $Args += @("--filter", $Filter) }

& $PhpPath @Args 2>&1 | Tee-Object -FilePath $ProofFile
$ExitCode = $LASTEXITCODE

Write-Host "---------------------------------------------------------------"
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|OK|FAILURES|Skipped|Error" | Select-Object -Last 5
Write-Host "---------------------------------------------------------------"
Write-Host "Exit code: $ExitCode"
exit $ExitCode
