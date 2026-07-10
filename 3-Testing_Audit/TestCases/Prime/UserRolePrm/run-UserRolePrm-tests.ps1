# UserRolePrm (Prime / central) Dusk runner (Windows).
# Placement: prime_testing/tests/Browser/Modules/Prime/UserRolePrm/.
# Prereqs: dev server on http://127.0.0.1:8000 ; APP_ENV=testing ; Prime area reachable ;
#          admin root@tenant.com verified. Central feature — NO tenant scaffolding.

param(
    [string]$Filter = "",
    [switch]$SyncDb,
    [string]$PhpPath = "php"
)

$D = Split-Path -Parent $MyInvocation.MyCommand.Path
$R = (Resolve-Path (Join-Path $D "..\..\..\..\..")).Path   # prime_testing root
$P = Join-Path $D "proof"
$SS = Join-Path $D "screenshots"
New-Item -ItemType Directory -Force -Path $P | Out-Null
if (Test-Path $SS) { Remove-Item "$SS\*" -Force -ErrorAction SilentlyContinue }

$T = Get-Date -Format "yyyyMMdd_HHmmss"
$L = Join-Path $P "dusk_run_$T.txt"

$FC = "sys_UserRolePrm_TestCas"
$FF = if ($Filter -ne "") { "$FC::$Filter" } else { $FC }

Write-Host "=== UserRolePrm Dusk Tests (filter: $FF) ==="
$env:APP_ENV = "testing"
Set-Location $R
if ($SyncDb) { & $PhpPath "$R\artisan" dusk:chrome-driver --detect | Out-Null }

& $PhpPath "$R\artisan" dusk --filter="$FF" 2>&1 | Tee-Object -FilePath $L
$EXIT = $LASTEXITCODE
Copy-Item $L (Join-Path $P "dusk_run_latest.txt") -Force

$line = Select-String -Path $L -Pattern "Tests:\s+[0-9]+" | Select-Object -Last 1
if ($line) {
    Write-Host "============================================"
    Write-Host "  UserRolePrm RESULTS: $($line.Line)"
    Write-Host "============================================"
}
Write-Host "Proof saved at: $L"
exit $EXIT
