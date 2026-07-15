# ---------------------------------------------------------------------------
# Runner — BehaviouralAssessment / Class-Mapping (single comprehensive suite)
# Test file: tests/Browser/Modules/BehaviouralAssessment/ClassMapping/bha_ClassMapping_TestCas.php
# Class     : bha_ClassMapping_TestCas  (44 Dusk methods, ONE file per screen — no V1/V2 split)
# ---------------------------------------------------------------------------

param(
    [string]$Filter = "",
    [switch]$SyncDB,
    [string]$PhpPath = "php"
)

$ProjectRoot = Resolve-Path "$PSScriptRoot\..\..\..\..\..\.."
$ProofDir = "$PSScriptRoot\proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputFile = "$ProofDir\dusk_run_$Timestamp.txt"
$LatestLink = "$ProofDir\dusk_run_latest.txt"

# There is exactly ONE test file for this screen; default the filter to its class.
$TestClass = "bha_ClassMapping_TestCas"
if (-not $Filter) { $Filter = $TestClass }

if ($SyncDB) {
    & $PhpPath "$ProjectRoot\artisan" migrate:fresh --seed --force
}

$FilterArg = if ($Filter) { "--filter=$Filter" } else { "" }

& $PhpPath "$ProjectRoot\artisan" dusk $FilterArg 2>&1 | Tee-Object -FilePath $OutputFile
$DuskExit = $LASTEXITCODE
Copy-Item $OutputFile $LatestLink -Force

Write-Host "`n=== Class-Mapping Test Run Complete ==="
$Summary = Select-String -Path $OutputFile -Pattern "Tests:|Assertions:|Failures:|OK \(" | Select-Object -Last 3
if ($Summary) { $Summary | ForEach-Object { Write-Host $_.Line } }
Write-Host "Output    : $OutputFile"
Write-Host "Exit code : $DuskExit"

exit $DuskExit
