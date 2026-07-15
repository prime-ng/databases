<#
    Runner: GlobalMaster -> SessionBoardSetup Dusk suite (glb_SessionBoardSetup_TestCas.php)
    READ-ONLY composite screen served by Prime at /prime/session-board-setup.
    Requires prime_ai served on http://127.0.0.1:8000, GlobalMaster AND Prime modules ENABLED
    in modules_statuses.json, APP_ENV=testing, and a reachable global_master_mysql / prime_db.

    Usage:
      ./run-SessionBoardSetup-tests.ps1                       # run the whole class
      ./run-SessionBoardSetup-tests.ps1 -Filter test_sessionboardsetup_60_index_renders_at_prime_path
      ./run-SessionBoardSetup-tests.ps1 -PhpBin "C:\php\php.exe" -TestRepo "C:\Herd\prime_testing"
#>
param(
    [string]$Filter   = "",
    [string]$PhpBin   = "php",
    [string]$TestRepo = "/Users/bkwork/Herd/prime_testing"
)

$ErrorActionPreference = "Continue"
$TestClass = "glb_SessionBoardSetup_TestCas"
$TestPath  = "tests/Browser/Modules/GlobalMaster/SessionBoardSetup/$TestClass.php"

if (-not (Test-Path $TestRepo)) { Write-Error "TestRepo not found: $TestRepo"; exit 2 }
Set-Location $TestRepo

$Stamp    = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir = Join-Path $TestRepo "tests/Browser/Modules/GlobalMaster/SessionBoardSetup/proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$ProofFile = Join-Path $ProofDir "session_board_setup_run_$Stamp.log"

# Clean old screenshots
$Shots = Join-Path $TestRepo "tests/Browser/Modules/GlobalMaster/SessionBoardSetup/screenshots"
if (Test-Path $Shots) { Remove-Item "$Shots/*.png" -Force -ErrorAction SilentlyContinue }

"== GlobalMaster SessionBoardSetup Dusk run @ $Stamp ==" | Tee-Object -FilePath $ProofFile

$env:APP_ENV = "testing"
$Args = @("artisan", "dusk", $TestPath)
if ($Filter -ne "") { $Args += "--filter=$Filter" } else { $Args += "--filter=$TestClass" }
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
