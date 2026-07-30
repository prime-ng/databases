<?php

/**
 * Cross-platform Dusk runner for the FrontOffice → Complaint suite.
 *
 * Replaces the legacy .ps1 + .sh pair — PHP is guaranteed present in this Laravel/Dusk
 * project, so this single file runs natively on Windows and Linux/macOS.
 *
 * Usage:
 *   php run-Complaint-tests.php [--php=/path/to/php] [--filter=test_complaint_20] [--sync-db]
 *
 * Options:
 *   --php=BINARY   PHP binary used to invoke `artisan dusk` (default: current PHP).
 *   --filter=NAME  Pass through to PHPUnit --filter (run a single method or band).
 *   --sync-db      Run `php artisan migrate --env=testing` before the suite.
 *
 * Prerequisites (see fof_ComplaintValidation_Report.md):
 *   - FrontOffice must be ENABLED in prime_testing/modules_statuses.json (else /front-office/* 404).
 *   - APP_ENV=testing (Dusk CSRF bypass); ChromeDriver aligned with the installed Chrome.
 *   - DUSK_TENANT_URL / DUSK_ADMIN_EMAIL / DUSK_ADMIN_PASSWORD set for the tenant.
 */

declare(strict_types=1);

$TEST_CLASS = 'fof_Complaint_TestCas';
$TEST_FILE  = 'tests/Browser/' . $TEST_CLASS . '.php';

// ---- parse args ------------------------------------------------------------
$phpBinary = PHP_BINARY;
$filter    = null;
$syncDb    = false;

foreach ($argv ?? [] as $arg) {
    if (str_starts_with($arg, '--php=')) {
        $phpBinary = substr($arg, 6);
    } elseif (str_starts_with($arg, '--filter=')) {
        $filter = substr($arg, 9);
    } elseif ($arg === '--sync-db') {
        $syncDb = true;
    }
}

// ---- locate the prime_testing project root --------------------------------
$candidates = [
    getcwd(),
    __DIR__,
    '/Users/bkwork/Herd/prime_testing',
];
$projectRoot = null;
foreach ($candidates as $dir) {
    if ($dir && is_file(rtrim($dir, '/\\') . DIRECTORY_SEPARATOR . 'artisan')) {
        $projectRoot = rtrim($dir, '/\\');
        break;
    }
}
if ($projectRoot === null) {
    fwrite(STDERR, "[ERROR] Could not locate the prime_testing project root (no artisan found).\n");
    fwrite(STDERR, "        Run this script from the prime_testing directory, or copy the test file there first.\n");
    exit(2);
}

// ---- clean old screenshots -------------------------------------------------
$shotDir = $projectRoot . '/tests/Browser/screenshots';
if (is_dir($shotDir)) {
    foreach (glob($shotDir . '/failure-*') ?: [] as $f) {
        @unlink($f);
    }
    echo "[info] Cleaned old failure screenshots.\n";
}

// ---- optional DB sync ------------------------------------------------------
if ($syncDb) {
    echo "[info] Syncing test database (migrate --env=testing)...\n";
    passthru(escapeshellarg($phpBinary) . ' ' . escapeshellarg($projectRoot . '/artisan') . ' migrate --env=testing --force');
}

// ---- build the dusk command ------------------------------------------------
$cmd = [
    escapeshellarg($phpBinary),
    escapeshellarg($projectRoot . '/artisan'),
    'dusk',
];
if ($filter !== null) {
    $cmd[] = '--filter=' . escapeshellarg($filter);
} else {
    $cmd[] = escapeshellarg($TEST_FILE);
}
$command = implode(' ', $cmd);

echo "[info] Project : {$projectRoot}\n";
echo "[info] PHP     : {$phpBinary}\n";
echo "[info] Class   : {$TEST_CLASS}\n";
echo "[info] Command : {$command}\n";
echo str_repeat('-', 70) . "\n";

// ---- proof directory + tee -------------------------------------------------
$proofDir = __DIR__ . '/proof';
if (!is_dir($proofDir)) {
    @mkdir($proofDir, 0777, true);
}
$stamp     = date('Ymd_His');
$proofFile = $proofDir . "/Complaint_run_{$stamp}.log";

$capture   = '';
$exitCode  = 0;

$descriptors = [
    0 => STDIN,
    1 => ['pipe', 'w'],
    2 => ['pipe', 'w'],
];
$process = proc_open($command, $descriptors, $pipes, $projectRoot);
if (is_resource($process)) {
    foreach ([1, 2] as $i) {
        stream_set_blocking($pipes[$i], false);
    }
    while (true) {
        $out = stream_get_contents($pipes[1]);
        $err = stream_get_contents($pipes[2]);
        if ($out !== '' && $out !== false) {
            echo $out;
            $capture .= $out;
        }
        if ($err !== '' && $err !== false) {
            fwrite(STDERR, $err);
            $capture .= $err;
        }
        $status = proc_get_status($process);
        if (!$status['running']) {
            // drain remaining
            $out = stream_get_contents($pipes[1]);
            $err = stream_get_contents($pipes[2]);
            $capture .= (string) $out . (string) $err;
            echo (string) $out;
            fwrite(STDERR, (string) $err);
            $exitCode = $status['exitcode'];
            break;
        }
        usleep(100000);
    }
    foreach ($pipes as $p) {
        if (is_resource($p)) {
            fclose($p);
        }
    }
    proc_close($process);
} else {
    fwrite(STDERR, "[ERROR] Failed to start the dusk process.\n");
    exit(2);
}

// ---- parse summary ---------------------------------------------------------
@file_put_contents($proofFile, $capture);
echo "\n" . str_repeat('-', 70) . "\n";

$tests = $assertions = $failures = $skipped = null;
if (preg_match('/Tests:\s*(\d+)/', $capture, $m)) {
    $tests = (int) $m[1];
}
if (preg_match('/Assertions:\s*(\d+)/', $capture, $m)) {
    $assertions = (int) $m[1];
}
if (preg_match('/Failures:\s*(\d+)/', $capture, $m)) {
    $failures = (int) $m[1];
}
if (preg_match('/Skipped:\s*(\d+)/', $capture, $m)) {
    $skipped = (int) $m[1];
}

echo "SUMMARY\n";
echo "  Tests      : " . ($tests ?? 'n/a') . "\n";
echo "  Assertions : " . ($assertions ?? 'n/a') . "\n";
echo "  Failures   : " . ($failures ?? 'n/a') . "\n";
echo "  Skipped    : " . ($skipped ?? 'n/a') . "\n";
echo "  Exit code  : {$exitCode}\n";
echo "  Proof log  : {$proofFile}\n";

exit((int) $exitCode);
