<#
    Runner: Billing -> Invoicing Dusk suite (bil_Invoicing_TestCas.php)
    Central/prime feature. Requires prime_ai served on http://127.0.0.1:8000, Billing module
    ENABLED in modules_statuses.json, APP_ENV=testing, and a reachable prime_db.

    Usage:
      ./run-Invoicing-tests.ps1                       # run all
      ./run-Invoicing-tests.ps1 -Filter test_invoicing_60_invoicing_tab_loads_with_filters
      ./run-Invoicing-tests.ps1 -PhpBin "C:\php\php.exe" -TestRepo "C:\Herd\prime_testing"
#>
param(
    [string]$Filter   = "",
    [string]$PhpBin   = "php",
    [string]$TestRepo = "/Users/bkwork/Herd/prime_testing"
)

$ErrorActionPreference = "Continue"
$TestClass = "bil_Invoicing_TestCas"
$TestPath  = "tests/Browser/Modules/Prime/Billing/Invoicing/$TestClass.php"

if (-not (Test-Path $TestRepo)) { Write-Error "TestRepo not found: $TestRepo"; exit 2 }
Set-Location $TestRepo

$Stamp    = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir = Join-Path $TestRepo "tests/Browser/Modules/Prime/Billing/Invoicing/proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$ProofFile = Join-Path $ProofDir "invoicing_run_$Stamp.log"

# Clean old screenshots
$Shots = Join-Path $TestRepo "tests/Browser/Modules/Prime/Billing/Invoicing/screenshots"
if (Test-Path $Shots) { Remove-Item "$Shots/*.png" -Force -ErrorAction SilentlyContinue }

"== Billing Invoicing Dusk run @ $Stamp ==" | Tee-Object -FilePath $ProofFile

$env:APP_ENV = "testing"
$Args = @("artisan", "dusk", $TestPath)
if ($Filter -ne "") { $Args += "--filter=$Filter" }
"> $PhpBin $($Args -join ' ')" | Tee-Object -FilePath $ProofFile -Append

& $PhpBin @Args 2>&1 | Tee-Object -FilePath $ProofFile -Append
$ExitCode = $LASTEXITCODE

"" | Tee-Object -FilePath $ProofFile -Append
"== Summary ==" | Tee-Object -FilePath $ProofFile -Append
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|Errors:|OK|FAILURES|Skipped" |
    Select-Object -Last 6 | ForEach-Object { $_.Line } | Tee-Object -FilePath $ProofFile -Append
"Proof: $ProofFile" | Tee-Object -FilePath $ProofFile -Append
"Exit code: $ExitCode" | Tee-Object -FilePath $ProofFile -Append
exit $ExitCode
