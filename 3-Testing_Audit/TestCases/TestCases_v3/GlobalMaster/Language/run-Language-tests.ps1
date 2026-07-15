param(
    [string]$Filter = "glb_Language_TestCas",
    [switch]$SyncDB,
    [string]$PhpPath = "php"
)

# Runner for the central GlobalMaster "Language" Dusk suite (single test file).
# Intended install path: prime_testing\tests\Browser\Modules\GlobalMaster\Language\

$ScriptDir = $PSScriptRoot

# Walk up until we find artisan (robust to install depth).
$ProjectRoot = $ScriptDir
while ($ProjectRoot -and -not (Test-Path (Join-Path $ProjectRoot "artisan"))) {
    $ProjectRoot = Split-Path $ProjectRoot -Parent
}
if (-not $ProjectRoot -or -not (Test-Path (Join-Path $ProjectRoot "artisan"))) {
    Write-Error "Could not locate artisan above $ScriptDir"; exit 1
}

$ProofDir = Join-Path $ScriptDir "proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputFile = Join-Path $ProofDir "dusk_run_$Timestamp.txt"
$LatestLink = Join-Path $ProofDir "dusk_run_latest.txt"

# Clean prior screenshots.
Remove-Item (Join-Path $ScriptDir "screenshots\*.png") -ErrorAction SilentlyContinue

if ($SyncDB) {
    & $PhpPath (Join-Path $ProjectRoot "artisan") migrate:fresh --seed --force
}

$FilterArg = if ($Filter) { "--filter=$Filter" } else { "" }

$env:APP_ENV = "testing"
& $PhpPath (Join-Path $ProjectRoot "artisan") dusk $FilterArg 2>&1 | Tee-Object -FilePath $OutputFile
$DuskExit = $LASTEXITCODE
Copy-Item $OutputFile $LatestLink -Force

Write-Host "`n=== GlobalMaster Language Test Run Complete ==="
Select-String -Path $OutputFile -Pattern "Tests:|Assertions:|Failures:|OK \(" | Select-Object -Last 3 | ForEach-Object { $_.Line }
Write-Host "Output: $OutputFile"
exit $DuskExit
