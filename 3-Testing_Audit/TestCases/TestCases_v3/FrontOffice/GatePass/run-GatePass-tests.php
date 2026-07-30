<?php

/**
 * Cross-platform Dusk runner for FrontOffice → GatePass.
 *
 * Single portable PHP runner (replaces the .ps1 + .sh pair). Runs natively on
 * Windows and Linux/macOS via PHP's proc_open — no shell-dialect duplication.
 *
 * Usage (from prime_testing project root, where artisan lives):
 *   php run-GatePass-tests.php [--php=/path/to/php] [--filter=test_gatePass_20] [--sync-db]
 *
 * ENV PREREQUISITES (see the Validation Report):
 *   - FrontOffice must be `true` in prime_testing/modules_statuses.json (else /front-office/* → 404,
 *     and every browser/route test markTestSkipped by design).
 *   - APP_ENV=testing (Dusk CSRF bypass), a running ChromeDriver, and DUSK_TENANT_URL set.
 */

$options = getopt('', ['php::', 'filter::', 'sync-db']);

$phpBinary   = $options['php']    ?? PHP_BINARY;
$filter      = $options['filter'] ?? 'fof_GatePass_TestCas';
$syncDatabase = array_key_exists('sync-db', $options);

$projectRoot = getcwd();
$artisanPath = $projectRoot . DIRECTORY_SEPARATOR . 'artisan';

if (!file_exists($artisanPath)) {
    fwrite(STDERR, "ERROR: artisan not found in {$projectRoot}. Run this from the prime_testing project root.\n");
    exit(2);
}

$proofDir = $projectRoot . DIRECTORY_SEPARATOR . 'proof';
if (!is_dir($proofDir)) {
    @mkdir($proofDir, 0775, true);
}
$timestamp = date('Ymd_His');
$proofFile = $proofDir . DIRECTORY_SEPARATOR . "GatePass_{$timestamp}.log";

// Clean stale Dusk screenshots so a fresh run is unambiguous.
$screenshotDir = $projectRoot . DIRECTORY_SEPARATOR . 'tests' . DIRECTORY_SEPARATOR . 'Browser'
    . DIRECTORY_SEPARATOR . 'screenshots';
if (is_dir($screenshotDir)) {
    foreach (glob($screenshotDir . DIRECTORY_SEPARATOR . 'failure-*') ?: [] as $shot) {
        @unlink($shot);
    }
}

echo "==================================================================\n";
echo " FrontOffice / GatePass — Dusk suite\n";
echo " PHP     : {$phpBinary}\n";
echo " Filter  : {$filter}\n";
echo " Proof   : {$proofFile}\n";
echo " OS      : " . PHP_OS_FAMILY . "\n";
echo "==================================================================\n\n";

if ($syncDatabase) {
    echo "[--sync-db] Running dusk with --browse database sync is delegated to the app config.\n";
}

$command = [
    $phpBinary,
    $artisanPath,
    'dusk',
    '--filter=' . $filter,
];

$descriptors = [
    0 => ['pipe', 'r'],
    1 => ['pipe', 'w'],
    2 => ['pipe', 'w'],
];

$process = proc_open($command, $descriptors, $pipes, $projectRoot);

if (!is_resource($process)) {
    fwrite(STDERR, "ERROR: Failed to start dusk process.\n");
    exit(3);
}

fclose($pipes[0]);

$log = fopen($proofFile, 'w');
$fullOutput = '';

foreach ([1, 2] as $streamIndex) {
    stream_set_blocking($pipes[$streamIndex], false);
}

while (true) {
    $stdout = stream_get_contents($pipes[1]);
    $stderr = stream_get_contents($pipes[2]);

    if ($stdout !== '' && $stdout !== false) {
        echo $stdout;
        fwrite($log, $stdout);
        $fullOutput .= $stdout;
    }
    if ($stderr !== '' && $stderr !== false) {
        fwrite(STDERR, $stderr);
        fwrite($log, $stderr);
        $fullOutput .= $stderr;
    }

    $status = proc_get_status($process);
    if (!$status['running']) {
        // Drain any remaining buffered output.
        $tail = stream_get_contents($pipes[1]) . stream_get_contents($pipes[2]);
        if ($tail !== '' && $tail !== false) {
            echo $tail;
            fwrite($log, $tail);
            $fullOutput .= $tail;
        }
        break;
    }
    usleep(100000);
}

fclose($pipes[1]);
fclose($pipes[2]);
fclose($log);

$exitCode = proc_close($process);

// Parse the Pest/PHPUnit summary line.
$tests = $assertions = $failures = $skipped = 0;
if (preg_match('/Tests:\s+(\d+)/', $fullOutput, $m)) {
    $tests = (int) $m[1];
}
if (preg_match('/Assertions:\s+(\d+)/', $fullOutput, $m)) {
    $assertions = (int) $m[1];
}
if (preg_match('/(\d+)\s+failed/i', $fullOutput, $m)) {
    $failures = (int) $m[1];
}
if (preg_match('/(\d+)\s+skipped/i', $fullOutput, $m)) {
    $skipped = (int) $m[1];
}

echo "\n==================================================================\n";
echo " SUMMARY\n";
echo "   Tests      : {$tests}\n";
echo "   Assertions : {$assertions}\n";
echo "   Failures   : {$failures}\n";
echo "   Skipped    : {$skipped}\n";
echo "   Exit code  : {$exitCode}\n";
echo "   Proof file : {$proofFile}\n";
echo "==================================================================\n";

exit($exitCode);
