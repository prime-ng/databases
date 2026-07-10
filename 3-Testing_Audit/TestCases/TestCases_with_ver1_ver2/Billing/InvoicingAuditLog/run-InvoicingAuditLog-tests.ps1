<#
=============================================================================
 Invoicing Audit Log (Billing) - Dusk runner (Windows / PowerShell)
 Mirrors the golden reference runner. Runs the mirrored test classes under
 prime_testing:
   tests/Browser/Modules/Prime/Billing/InvoicingAuditLog/bil_InvoicingAuditLogV1_TestCas.php
   tests/Browser/Modules/Prime/Billing/InvoicingAuditLog/bil_InvoicingAuditLogV2_TestCas.php

 PREREQUISITES
   - Run from the prime_testing repo root (Dusk runner).
   - prime_ai cloned alongside; MAIN_PROJECT_PATH set (source-truth asserts read it).
   - APP_ENV=testing (bypasses CSRF/419).
   - Billing module ENABLED in modules_statuses.json (else every route 404s).
   - Prime tests run on http://127.0.0.1:8000 (central / prime_db - no tenant init).

 USAGE
   ./run-InvoicingAuditLog-tests.ps1 [-Php <path>] [-V1Only] [-V2Only] [-Filter <method>]
=============================================================================
#>
param(
    [string]$Php = "php",
    [string]$Filter = "",
    [switch]$V1Only,
    [switch]$V2Only
)

$ErrorActionPreference = "Continue"
$env:APP_ENV = "testing"

$V1Class = "bil_InvoicingAuditLogV1_TestCas"
$V2Class = "bil_InvoicingAuditLogV2_TestCas"

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir  = "tests/Browser/Modules/Prime/Billing/InvoicingAuditLog/proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$ProofFile = Join-Path $ProofDir "invoicing_audit_log_run_$Timestamp.log"

# Clean old screenshots
$ShotDir = "tests/Browser/Modules/Prime/Billing/InvoicingAuditLog/screenshots"
if (Test-Path $ShotDir) { Get-ChildItem -Path $ShotDir -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }

function Run-Class {
    param([string]$Class)
    $F = $Class
    if ($Filter -ne "") { $F = "$Class::$Filter" }
    "=== Running $F ===" | Tee-Object -FilePath $ProofFile -Append
    & $Php artisan dusk --filter="$F" 2>&1 | Tee-Object -FilePath $ProofFile -Append
    return $LASTEXITCODE
}

$Exit = 0
if (-not $V2Only) { $c = Run-Class $V1Class; if ($c -ne 0) { $Exit = $c } }
if (-not $V1Only) { $c = Run-Class $V2Class; if ($c -ne 0) { $Exit = $c } }

"" | Tee-Object -FilePath $ProofFile -Append
"=== SUMMARY ===" | Tee-Object -FilePath $ProofFile -Append
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|OK|FAILURES|Skipped" | Select-Object -Last 20 | ForEach-Object { $_.Line } | Tee-Object -FilePath $ProofFile -Append
"Proof: $ProofFile"
exit $Exit
