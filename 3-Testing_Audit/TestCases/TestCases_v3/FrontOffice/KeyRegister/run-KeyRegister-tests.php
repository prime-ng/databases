<?php

/**
 * Cross-platform Dusk runner for the FrontOffice :: KeyRegister suite.
 * Runs natively on Windows and Linux/macOS (no .ps1 / .sh needed).
 *
 * Usage:
 *   php run-KeyRegister-tests.php [--php=/path/to/php] [--filter=test_keyregister_20] [--sync-db]
 *
 * Prerequisites (see fof_KeyRegisterValidation_Report.md):
 *   - Copy fof_KeyRegister_TestCas.php into prime_testing/tests/Browser/ before running.
 *   - FrontOffice must be ENABLED in prime_testing/modules_statuses.json (currently false).
 *   - APP_ENV=testing, a valid tenant domain reachable at DUSK_TENANT_URL, ChromeDriver running.
 */

$options = getopt('', ['php::', 'filter::', 'sync-db', 'test-repo::']);

$phpBinary = $options['php']    ?? PHP_BINARY;
$filter    = $options['filter'] ?? 'fof_KeyRegister_TestCas';
$syncDb    = array_key_exists('sync-db', $options);

// Resolve the prime_testing repo root (default sibling layout).
$testRepo = $options['test-repo'] ?? realpath(__DIR__ . '/../../../../../../Herd/prime_testing');
if (!$testRepo || !is_dir($testRepo)) {
    $testRepo = getcwd();
}

$proofDir = __DIR__ . '/proof';
if (!is_dir($proofDir)) {
    @mkdir($proofDir, 0777, true);
}
$timestamp = date('Ymd_His');
$proofFile = $proofDir . DIRECTORY_SEPARATOR . "KeyRegister_dusk_{$timestamp}.log";

// Clean stale Dusk screenshots so failures map to this run.
$shotDir = $testRepo . '/tests/Browser/screenshots';
if (is_dir($shotDir)) {
    foreach (glob($shotDir . '/failure-*') ?: [] as $shot) {
        @unlink($shot);
    }
}

echo "==================================================================\n";
echo " FrontOffice :: KeyRegister — Dusk run\n";
echo "  php     : {$phpBinary}\n";
echo "  repo    : {$testRepo}\n";
echo "  filter  : {$filter}\n";
echo "  proof   : {$proofFile}\n";
echo "==================================================================\n\n";

$commands = [];
if ($syncDb) {
    $commands[] = [$phpBinary, 'artisan', 'migrate', '--force'];
}
$commands[] = [$phpBinary, 'artisan', 'dusk', '--filter=' . $filter];

$exitCode = 0;
$fullOutput = '';

foreach ($commands as $argv) {
    $printable = implode(' ', array_map(static fn ($a) => (str_contains($a, ' ') ? '"' . $a . '"' : $a), $argv));
    echo "> {$printable}\n";
    $fullOutput .= "> {$printable}\n";

    $descriptors = [0 => STDIN, 1 => ['pipe', 'w'], 2 => ['pipe', 'w']];
    $process = proc_open($argv, $descriptors, $pipes, $testRepo, null);

    if (!is_resource($process)) {
        echo "ERROR: failed to launch process.\n";
        $exitCode = 1;
        break;
    }

    foreach ([1, 2] as $fd) {
        stream_set_blocking($pipes[$fd], false);
    }

    while (true) {
        $status = proc_get_status($process);
        foreach ([1, 2] as $fd) {
            $chunk = stream_get_contents($pipes[$fd]);
            if ($chunk !== '' && $chunk !== false) {
                echo $chunk;
                $fullOutput .= $chunk;
            }
        }
        if (!$status['running']) {
            break;
        }
        usleep(100000);
    }

    foreach ([1, 2] as $fd) {
        $chunk = stream_get_contents($pipes[$fd]);
        if ($chunk !== '' && $chunk !== false) {
            echo $chunk;
            $fullOutput .= $chunk;
        }
        fclose($pipes[$fd]);
    }

    $exitCode = proc_close($process);
    if ($exitCode !== 0) {
        break;
    }
}

file_put_contents($proofFile, $fullOutput);

// Parse the Pest/PHPUnit summary line.
$tests = $assertions = $failures = 0;
if (preg_match('/Tests:\s*.*?(\d+)\s+passed/i', $fullOutput, $m)) {
    $tests = (int) $m[1];
}
if (preg_match('/(\d+)\s+failed/i', $fullOutput, $m)) {
    $failures = (int) $m[1];
}
if (preg_match('/Assertions:\s*(\d+)/i', $fullOutput, $m)) {
    $assertions = (int) $m[1];
}

echo "\n------------------------------------------------------------------\n";
echo " Summary\n";
echo "   passed     : {$tests}\n";
echo "   failed     : {$failures}\n";
echo "   assertions : {$assertions}\n";
echo "   exit code  : {$exitCode}\n";
echo "   proof      : {$proofFile}\n";
echo "------------------------------------------------------------------\n";

exit($exitCode);
