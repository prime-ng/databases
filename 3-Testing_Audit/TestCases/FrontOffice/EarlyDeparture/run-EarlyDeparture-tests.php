<?php

/**
 * Cross-platform Dusk runner for the FrontOffice EarlyDeparture suite.
 * Replaces the legacy .ps1 + .sh pair — one PHP file runs on Windows AND Linux/macOS.
 *
 * Usage:
 *   php run-EarlyDeparture-tests.php [--php=/path/to/php] [--filter=test_name] [--sync-db]
 *
 * It must be run from the prime_testing project root (where `artisan` lives), e.g.:
 *   cd /Users/bkwork/Herd/prime_testing
 *   php /path/to/run-EarlyDeparture-tests.php
 *
 * PREREQUISITES (see fof_EarlyDepartureValidation_Report.md):
 *   - Copy fof_EarlyDeparture_TestCas.php into tests/Browser/Modules/FrontOffice/EarlyDeparture/ of prime_testing.
 *   - Enable "FrontOffice": true in prime_testing/modules_statuses.json (currently false → /front-office/* routes 404).
 *   - APP_ENV=testing; a valid tenant in DUSK_TENANT_URL; ChromeDriver aligned with Chrome; std_students has ≥1 row.
 */

declare(strict_types=1);

$options = getopt('', ['php::', 'filter::', 'sync-db']);

$phpBinary   = $options['php'] ?? PHP_BINARY;
$filter      = $options['filter'] ?? 'fof_EarlyDeparture_TestCas';
$syncDb      = array_key_exists('sync-db', $options);
$isWindows   = PHP_OS_FAMILY === 'Windows';

$projectRoot = getcwd();
$artisan     = $projectRoot . DIRECTORY_SEPARATOR . 'artisan';

fwrite(STDOUT, "== FrontOffice / EarlyDeparture Dusk runner ==\n");
fwrite(STDOUT, 'PHP binary : ' . $phpBinary . "\n");
fwrite(STDOUT, 'Project    : ' . $projectRoot . "\n");
fwrite(STDOUT, 'Filter     : ' . $filter . "\n");
fwrite(STDOUT, 'OS family  : ' . PHP_OS_FAMILY . "\n\n");

if (! file_exists($artisan)) {
    fwrite(STDERR, "ERROR: artisan not found in {$projectRoot}. Run this from the prime_testing project root.\n");
    exit(2);
}

// ---- Clean old failure screenshots -------------------------------------------------
$screenshotDir = $projectRoot . DIRECTORY_SEPARATOR . 'tests' . DIRECTORY_SEPARATOR . 'Browser' . DIRECTORY_SEPARATOR . 'screenshots';
if (is_dir($screenshotDir)) {
    foreach (glob($screenshotDir . DIRECTORY_SEPARATOR . 'failure-*') ?: [] as $file) {
        @unlink($file);
    }
    fwrite(STDOUT, "Cleaned old failure screenshots.\n");
}

// ---- Optional: refresh route cache (stale cache → 404) -----------------------------
runCommand($phpBinary, [$artisan, 'route:clear'], $projectRoot);

// ---- Optional DB sync --------------------------------------------------------------
if ($syncDb) {
    fwrite(STDOUT, "Running tenant migrations (--sync-db)...\n");
    runCommand($phpBinary, [$artisan, 'tenants:migrate', '--force'], $projectRoot);
}

// ---- Proof directory ---------------------------------------------------------------
$proofDir = __DIR__ . DIRECTORY_SEPARATOR . 'proof';
if (! is_dir($proofDir)) {
    @mkdir($proofDir, 0775, true);
}
$timestamp = date('Ymd_His');
$proofFile = $proofDir . DIRECTORY_SEPARATOR . "EarlyDeparture_run_{$timestamp}.log";

// ---- Run Dusk ----------------------------------------------------------------------
$duskArgs = [$artisan, 'dusk', '--filter=' . $filter];
fwrite(STDOUT, "\nRunning: {$phpBinary} artisan dusk --filter={$filter}\n");
fwrite(STDOUT, str_repeat('-', 60) . "\n");

$exitCode = 0;
$captured = '';

$descriptors = [
    0 => ['pipe', 'r'],
    1 => ['pipe', 'w'],
    2 => ['pipe', 'w'],
];

$process = proc_open(
    buildCommand($phpBinary, $duskArgs, $isWindows),
    $descriptors,
    $pipes,
    $projectRoot,
    array_merge($_ENV, ['APP_ENV' => 'testing'])
);

if (is_resource($process)) {
    fclose($pipes[0]);
    stream_set_blocking($pipes[1], false);
    stream_set_blocking($pipes[2], false);

    while (true) {
        $out = fgets($pipes[1]);
        if ($out !== false) {
            fwrite(STDOUT, $out);
            $captured .= $out;
        }
        $err = fgets($pipes[2]);
        if ($err !== false) {
            fwrite(STDERR, $err);
            $captured .= $err;
        }
        $status = proc_get_status($process);
        if (! $status['running'] && $out === false && $err === false) {
            break;
        }
        if ($out === false && $err === false) {
            usleep(50000);
        }
    }

    fclose($pipes[1]);
    fclose($pipes[2]);
    $exitCode = proc_close($process);
} else {
    fwrite(STDERR, "ERROR: failed to start the dusk process.\n");
    $exitCode = 3;
}

// ---- Parse summary -----------------------------------------------------------------
$tests = $assertions = $failures = 0;
if (preg_match('/Tests:\s+(\d+)/i', $captured, $m)) {
    $tests = (int) $m[1];
}
if (preg_match('/Assertions:\s+(\d+)/i', $captured, $m)) {
    $assertions = (int) $m[1];
}
if (preg_match('/(\d+)\s+failed/i', $captured, $m)) {
    $failures = (int) $m[1];
}

$summary = "\n" . str_repeat('=', 60) . "\n"
    . "EarlyDeparture Dusk Summary\n"
    . str_repeat('=', 60) . "\n"
    . "Tests      : {$tests}\n"
    . "Assertions : {$assertions}\n"
    . "Failures   : {$failures}\n"
    . "Exit code  : {$exitCode}\n"
    . 'Proof      : ' . $proofFile . "\n";

fwrite(STDOUT, $summary);
@file_put_contents($proofFile, $captured . $summary);

exit($exitCode);

// ---- Helpers -----------------------------------------------------------------------

/**
 * @param array<int,string> $args
 */
function buildCommand(string $php, array $args, bool $isWindows): array|string
{
    $parts = array_merge([$php], $args);
    // proc_open accepts an array on both platforms in PHP 7.4+; keep it portable.
    return $parts;
}

/**
 * @param array<int,string> $args
 */
function runCommand(string $php, array $args, string $cwd): void
{
    $descriptors = [0 => ['pipe', 'r'], 1 => ['pipe', 'w'], 2 => ['pipe', 'w']];
    $proc = proc_open(array_merge([$php], $args), $descriptors, $pipes, $cwd);
    if (! is_resource($proc)) {
        return;
    }
    fclose($pipes[0]);
    echo stream_get_contents($pipes[1]);
    $err = stream_get_contents($pipes[2]);
    if ($err) {
        fwrite(STDERR, $err);
    }
    fclose($pipes[1]);
    fclose($pipes[2]);
    proc_close($proc);
}
