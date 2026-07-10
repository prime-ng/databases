<#
    Configuration Templates (MarksheetGeneration) - Dusk runner (Windows PowerShell)

    ONE comprehensive suite (no V1/V2 split). Copy the PHP file into the runner:
      prime_testing/tests/Browser/msh_ConfigurationTemplates_TestCas.php

    Prerequisites:
      - MarksheetGeneration enabled in prime_testing/modules_statuses.json
      - tenant.msh-* permissions seeded/granted for the Dusk admin (D39-MSH)
      - APP_ENV=testing ; ChromeDriver running ; tenant reachable at DUSK_TENANT_URL

    Usage:
      ./run-ConfigurationTemplates-tests.ps1
      ./run-ConfigurationTemplates-tests.ps1 -Filter test_config_template_10_create_persists_with_activity_stored
      ./run-ConfigurationTemplates-tests.ps1 -PhpBin "C:\php\php.exe"
#>
param(
    [string]$PhpBin = "php",
    [string]$Filter = ""
)

$ErrorActionPreference = "Continue"
$Suite = "msh_ConfigurationTemplates_TestCas"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProofDir  = Join-Path $ScriptDir "proof"
if (-not (Test-Path $ProofDir)) { New-Item -ItemType Directory -Path $ProofDir | Out-Null }
$Stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "ConfigurationTemplates_$Stamp.log"

# Clean stale screenshots for this feature (best effort)
Get-ChildItem -Path . -Recurse -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match "MarksheetGeneration[\\/]ConfigurationTemplates[\\/]screenshots" } |
    ForEach-Object { Get-ChildItem -Path $_.FullName -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }

$Arg = $Suite
if ($Filter -ne "") { $Arg = "$Suite::$Filter" }

"===== Running $Suite =====" | Tee-Object -FilePath $ProofFile -Append
& $PhpBin artisan dusk --filter="$Arg" 2>&1 | Tee-Object -FilePath $ProofFile -Append
$ExitCode = $LASTEXITCODE

"" | Tee-Object -FilePath $ProofFile -Append
"===== Summary =====" | Tee-Object -FilePath $ProofFile -Append
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|OK|FAILURES|Error" |
    Select-Object -Last 20 | ForEach-Object { $_.Line }
"Proof written to: $ProofFile"
exit $ExitCode
