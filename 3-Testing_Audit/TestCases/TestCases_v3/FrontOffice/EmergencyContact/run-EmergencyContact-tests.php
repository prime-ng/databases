<?php

/**
 * Cross-platform Dusk runner for the FrontOffice ▸ EmergencyContact suite.
 * Runs natively on Windows and Linux/macOS (PHP only — no .sh / .ps1).
 *
 * Usage:
 *   php run-EmergencyContact-tests.php [--php=/path/to/php] [--filter=methodName] [--sync-db]
 *
 * Prerequisites (see fof_EmergencyContactValidation_Report.md §6):
 *   - Enable FrontOffice in prime_testing/modules_statuses.json (else /front-office/* → 404).
 *   - APP_ENV=testing; ChromeDriver aligned; DUSK_TENANT_URL reachable.
 *
 * Copy fof_EmergencyContact_TestCas.php into
 *   prime_testing/tests/Browser/Modules/FrontOffice/EmergencyContact/
 * before running (the runner drives `php artisan dusk` from the prime_testing root).
 */

$TEST_CLASS = 'fof_EmergencyContact_TestCas';
$TEST_FILE  = 'tests/Browser/Modules/FrontOffice/EmergencyContact/' . $TEST_CLASS . '.php';

// ---- Parse args -----------------------------------------------------------
$phpBinary = PHP_BINARY;
$filter = null;
$syncDb = false;

foreach (array_slice($argv, 1) as $arg) {
    if (str_starts_with($arg, '--php=')) {
        $phpBinary = substr($arg, 6);
    } elseif (str_starts_with($arg, '--filter=')) {
        $filter = substr($arg, 9);
    } elseif ($arg === '--sync-db') {
        $syncDb = true;
    } elseif ($arg === '--help' || $arg === '-h') {
        fwrite(STDOUT, "Usage: php run-EmergencyContact-tests.php [--php=PHP] [--filter=METHOD] [--sync-db]\n");
        exit(0);
    }
}

// ---- Resolve the prime_testing project root -------------------------------
$candidates = [
    getcwd(),
    getcwd() . '/prime_testing',
    dirname(__DIR__, 6) . '/Herd/prime_testing',
    '/Users/bkwork/Herd/prime_testing',
];
$projectRoot = null;
foreach ($candidates as $dir) {
    if (is_string($dir) && is_file($dir . '/artisan')) {
        $projectRoot = realpath($dir);
        break;
    }
}
if ($projectRoot === null) {
    fwrite(STDERR, "[ERROR] Could not locate the prime_testing project root (no artisan found).\n");
    fwrite(STDERR, "        Run this script from the prime_testing directory, or pass --php and cd there.\n");
    exit(2);
}

// ---- Clean old screenshots ------------------------------------------------
$shotDir = $projectRoot . '/tests/Browser/screenshots';
if (is_dir($shotDir)) {
    foreach (glob($shotDir . '/*.png') ?: [] as $png) {
        @unlink($png);
    }
    fwrite(STDOUT, "[info] Cleaned old screenshots.\n");
}

// ---- Optional DB sync -----------------------------------------------------
if ($syncDb) {
    fwrite(STDOUT, "[info] --sync-db requested; ensure your tenant DB has fof_emergency_contacts migrated.\n");
}

// ---- Prepare proof directory ----------------------------------------------
$proofDir = __DIR__ . '/proof';
if (! is_dir($proofDir)) {
    @mkdir($proofDir, 0777, true);
}
$stamp = date('Ymd_His');
$proofFile = $proofDir . "/EmergencyContact_{$stamp}.log";

// ---- Build the dusk command ----------------------------------------------
$cmd = [$phpBinary, 'artisan', 'dusk'];
if ($filter !== null) {
    $cmd[] = '--filter=' . $filter;
} else {
    $cmd[] = $TEST_FILE;
}

fwrite(STDOUT, '[info] Project : ' . $projectRoot . "\n");
fwrite(STDOUT, '[info] Command : ' . implode(' ', $cmd) . "\n");
fwrite(STDOUT, '[info] Proof   : ' . $proofFile . "\n\n");

// ---- Run (portable, via proc_open) ---------------------------------------
$descriptors = [0 => STDIN, 1 => ['pipe', 'w'], 2 => ['pipe', 'w']];
$env = $_ENV;
$env['APP_ENV'] = $env['APP_ENV'] ?? 'testing';

$process = proc_open($cmd, $descriptors, $pipes, $projectRoot, $env);
if (! is_resource($process)) {
    fwrite(STDERR, "[ERROR] Failed to start the dusk process.\n");
    exit(2);
}

$buffer = '';
foreach ([1, 2] as $i) {
    stream_set_blocking($pipes[$i], false);
}
$proofHandle = fopen($proofFile, 'w');

while (true) {
    $out = stream_get_contents($pipes[1]);
    $err = stream_get_contents($pipes[2]);
    if ($out !== false && $out !== '') {
        fwrite(STDOUT, $out);
        if ($proofHandle) { fwrite($proofHandle, $out); }
        $buffer .= $out;
    }
    if ($err !== false && $err !== '') {
        fwrite(STDERR, $err);
        if ($proofHandle) { fwrite($proofHandle, $err); }
        $buffer .= $err;
    }
    $status = proc_get_status($process);
    if (! $status['running'] && ($out === '' || $out === false) && ($err === '' || $err === false)) {
        break;
    }
    usleep(50000);
}

foreach ([1, 2] as $i) {
    if (isset($pipes[$i]) && is_resource($pipes[$i])) {
        fclose($pipes[$i]);
    }
}
$exitCode = proc_close($process);
if ($proofHandle) { fclose($proofHandle); }

// ---- Parse the summary line ----------------------------------------------
$tests = $assertions = $failures = $skipped = null;
if (preg_match('/Tests:\s*(\d+)/i', $buffer, $m)) { $tests = (int) $m[1]; }
if (preg_match('/Assertions:\s*(\d+)/i', $buffer, $m)) { $assertions = (int) $m[1]; }
if (preg_match('/Failures:\s*(\d+)/i', $buffer, $m)) { $failures = (int) $m[1]; }
if (preg_match('/Skipped:\s*(\d+)/i', $buffer, $m)) { $skipped = (int) $m[1]; }

fwrite(STDOUT, "\n========================================\n");
fwrite(STDOUT, "  EmergencyContact — Dusk Summary\n");
fwrite(STDOUT, "========================================\n");
fwrite(STDOUT, '  Tests      : ' . ($tests ?? 'n/a') . "\n");
fwrite(STDOUT, '  Assertions : ' . ($assertions ?? 'n/a') . "\n");
fwrite(STDOUT, '  Failures   : ' . ($failures ?? 'n/a') . "\n");
fwrite(STDOUT, '  Skipped    : ' . ($skipped ?? 'n/a') . "\n");
fwrite(STDOUT, '  Exit code  : ' . $exitCode . "\n");
fwrite(STDOUT, '  Proof      : ' . $proofFile . "\n");
fwrite(STDOUT, "========================================\n");

exit($exitCode);
