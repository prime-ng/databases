<#
    Configuration Templates (MarksheetGeneration) - Dusk runner (Windows PowerShell)

    Copy the two PHP suites into the runner before executing:
      prime_testing\tests\Browser\msh_ConfigurationTemplatesV1_TestCas.php
      prime_testing\tests\Browser\msh_ConfigurationTemplatesV2_TestCas.php

    Prerequisites:
      - MarksheetGeneration enabled in prime_testing\modules_statuses.json
      - MSH permissions seeded/granted for the Dusk admin (D39-MSH)
      - APP_ENV=testing ; ChromeDriver running ; tenant reachable at DUSK_TENANT_URL

    Usage:
      .\run-ConfigurationTemplates-tests.ps1
      .\run-ConfigurationTemplates-tests.ps1 -V1
      .\run-ConfigurationTemplates-tests.ps1 -V2
      .\run-ConfigurationTemplates-tests.ps1 -Filter test_config_template_10_create_persists_with_activity_stored
      .\run-ConfigurationTemplates-tests.ps1 -Php "C:\php\php.exe"
#>
param(
    [switch]$V1,
    [switch]$V2,
    [string]$Filter = "",
    [string]$Php = "php"
)

$ErrorActionPreference = "Continue"

$suites = @("msh_ConfigurationTemplatesV1_TestCas", "msh_ConfigurationTemplatesV2_TestCas")
if ($V1 -and -not $V2) { $suites = @("msh_ConfigurationTemplatesV1_TestCas") }
if ($V2 -and -not $V1) { $suites = @("msh_ConfigurationTemplatesV2_TestCas") }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$proofDir  = Join-Path $scriptDir "proof"
if (-not (Test-Path $proofDir)) { New-Item -ItemType Directory -Path $proofDir | Out-Null }
$stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$proofFile = Join-Path $proofDir "ConfigurationTemplates_$stamp.log"

# Clean stale screenshots (best effort)
Get-ChildItem -Recurse -Directory -Filter "screenshots" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match "MarksheetGeneration[\\/]ConfigurationTemplates" } |
    ForEach-Object { Get-ChildItem -Path $_.FullName -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }

$exitCode = 0
foreach ($suite in $suites) {
    $arg = $suite
    if ($Filter -ne "") { $arg = "$suite::$Filter" }
    "===== Running $suite =====" | Tee-Object -FilePath $proofFile -Append
    & $Php artisan dusk --filter="$arg" 2>&1 | Tee-Object -FilePath $proofFile -Append
    if ($LASTEXITCODE -ne 0) { $exitCode = $LASTEXITCODE }
}

"" | Tee-Object -FilePath $proofFile -Append
"===== Summary =====" | Tee-Object -FilePath $proofFile -Append
Select-String -Path $proofFile -Pattern "Tests:|Assertions:|Failures:|OK|FAILURES|Error" |
    Select-Object -Last 20 | ForEach-Object { $_.Line }
Write-Host "Proof written to: $proofFile"
exit $exitCode
