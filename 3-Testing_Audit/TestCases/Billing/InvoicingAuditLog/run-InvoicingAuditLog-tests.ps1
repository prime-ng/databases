# Runner: Invoice Audit Log Dusk suite (bil_InvoicingAuditLog_TestCas)
# Central/PRIME feature - runs on http://127.0.0.1:8000. Billing module must be ENABLED.
param(
    [string]$Php = "php",
    [string]$Filter = ""
)

$ErrorActionPreference = "Continue"
$Class = "bil_InvoicingAuditLog_TestCas"
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir = "proof"
$ProofFile = Join-Path $ProofDir "InvoicingAuditLog_$Stamp.log"

if (-not (Test-Path $ProofDir)) { New-Item -ItemType Directory -Path $ProofDir | Out-Null }
$env:APP_ENV = "testing"

Write-Host "== Invoice Audit Log Dusk suite =="
Write-Host "PHP: $Php | Class: $Class | Filter: $(if ($Filter) { $Filter } else { '<all>' })"
Write-Host "Base URL: http://127.0.0.1:8000 (central/prime) | proof: $ProofFile"

$ShotDir = "tests/Browser/Modules/Prime/Billing/InvoicingAuditLog/screenshots"
if (Test-Path $ShotDir) { Remove-Item "$ShotDir/*.png" -Force -ErrorAction SilentlyContinue }

if ($Filter) { $DuskFilter = "$Class::$Filter" } else { $DuskFilter = $Class }

& $Php artisan dusk --filter="$DuskFilter" 2>&1 | Tee-Object -FilePath $ProofFile
$ExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "== Summary =="
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|OK \(" | Select-Object -Last 5 | ForEach-Object { $_.Line }
Write-Host "Exit code: $ExitCode"
exit $ExitCode
