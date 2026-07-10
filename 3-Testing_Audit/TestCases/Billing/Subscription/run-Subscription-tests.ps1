<#
    Subscription (Billing / Prime-central) Dusk runner — Windows PowerShell
    Mirrors the Billing golden runners. ONE test file per screen.

    Prerequisites (see Validation Report):
      - prime_ai cloned alongside prime_testing; MAIN_PROJECT_PATH set
      - modules_statuses.json: "Billing": true AND "Prime": true (both false by default -> 404)
      - Prime/central features run on http://127.0.0.1:8000 (NOT test.localhost)
      - APP_ENV=testing (CSRF bypassed); ChromeDriver running

    Usage:  ./run-Subscription-tests.ps1 [-Filter test_subscription_10_...] [-PhpPath php] [-PrimeTestingPath C:\path\prime_testing]
#>
param(
    [string]$Filter = "",
    [string]$PhpPath = "php",
    [string]$PrimeTestingPath = ""
)

$ErrorActionPreference = "Continue"

if ($PrimeTestingPath -ne "") { Set-Location $PrimeTestingPath }

$TestPath  = "tests/Browser/Modules/Prime/Billing/Subscription/prm_Subscription_TestCas.php"
$Stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir  = "tests/Browser/Modules/Prime/Billing/Subscription/proof"
$ProofFile = Join-Path $ProofDir "subscription_run_$Stamp.txt"
$ShotDir   = "tests/Browser/Modules/Prime/Billing/Subscription/screenshots"

New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
if (Test-Path $ShotDir) { Remove-Item "$ShotDir/*.png" -Force -ErrorAction SilentlyContinue }

"== Subscription Dusk run @ $Stamp ==" | Tee-Object -FilePath $ProofFile
"PHP: $PhpPath"                          | Tee-Object -FilePath $ProofFile -Append

$Args = @("artisan", "dusk", $TestPath)
if ($Filter -ne "") {
    $Args += @("--filter", $Filter)
    "Filter: $Filter" | Tee-Object -FilePath $ProofFile -Append
}

"Running: $PhpPath $($Args -join ' ')" | Tee-Object -FilePath $ProofFile -Append
& $PhpPath @Args 2>&1 | Tee-Object -FilePath $ProofFile -Append
$ExitCode = $LASTEXITCODE

$Summary = (Select-String -Path $ProofFile -Pattern 'Tests:\s.*' | Select-Object -Last 1).Line
""                                        | Tee-Object -FilePath $ProofFile -Append
"Summary: $Summary"                       | Tee-Object -FilePath $ProofFile -Append
"Proof written to: $ProofFile"            | Tee-Object -FilePath $ProofFile -Append
"Exit code: $ExitCode"                    | Tee-Object -FilePath $ProofFile -Append

exit $ExitCode
