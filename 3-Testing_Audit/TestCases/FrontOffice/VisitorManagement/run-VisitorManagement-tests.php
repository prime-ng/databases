<?php

/**
 * Cross-platform Dusk runner for FrontOffice → VisitorManagement.
 * Runs natively on Windows and Linux/macOS (pure PHP, no shell dialect).
 *
 * Usage:
 *   php run-VisitorManagement-tests.php [--php=/path/to/php] [--filter=test_name] [--sync-db]
 *
 * Prerequisites (see fof_VisitorManagementValidation_Report.md):
 *   - Copy fof_VisitorManagement_TestCas.php into prime_testing/tests/Browser/ (namespace Tests\Browser).
 *   - FrontOffice must be ENABLED in prime_testing/modules_statuses.json (else all /front-office/* routes 404).
 *   - APP_ENV=testing; ChromeDriver aligned with installed Chrome; run from the prime_testing repo root.
 */

$options = getopt('', ['php::', 'filter::', 'sync-db']);

$phpBinary = $options['php'] ?? PHP_BINARY;
$filter    = $options['filter'] ?? 'fof_VisitorManagement_TestCas';
$syncDb    = array_key_exists('sync-db', $options);

$repoRoot = getcwd();
$artisan  = $repoRoot . DIRECTORY_SEPARATOR . 'artisan';

if (!file_exists($artisan)) {
    fwrite(STDERR, "ERROR: artisan not found in {$repoRoot}. Run this from the prime_testing repo root.\n");
    exit(2);
}

// --- Clean old screenshots ---
$screenshotDir = $repoRoot . DIRECTORY_SEPARATOR . 'tests' . DIRECTORY_SEPARATOR . 'Browser'
    . DIRECTORY_SEPARATOR . 'screenshots';
if (is_dir($screenshotDir)) {
    foreach (glob($screenshotDir . DIRECTORY_SEPARATOR . '*.png') ?: [] as $png) {
        @unlink($png);
    }
    echo "Cleaned old screenshots in {$screenshotDir}\n";
}

// --- Proof directory ---
$proofDir = __DIR__ . DIRECTORY_SEPARATOR . 'proof';
if (!is_dir($proofDir)) {
    @mkdir($proofDir, 0775, true);
}
$timestamp = date('Ymd_His');
$proofFile = $proofDir . DIRECTORY_SEPARATOR . "VisitorManagement_{$timestamp}.log";

// --- Optional DB sync ---
if ($syncDb) {
    echo "Syncing test DB (migrate)...\n";
    runProcess($phpBinary, [$artisan, 'migrate', '--force'], $repoRoot, $proofFile);
}

// --- Run Dusk ---
echo "Running: {$phpBinary} artisan dusk --filter={$filter}\n";
$exitCode = runProcess(
    $phpBinary,
    [$artisan, 'dusk', '--filter=' . $filter],
    $repoRoot,
    $proofFile
);

// --- Parse summary ---
$log = file_exists($proofFile) ? (string) file_get_contents($proofFile) : '';
$summary = 'Tests: n/a';
if (preg_match('/Tests:\s+\d+.*$/mi', $log, $m)) {
    $summary = trim($m[0]);
} elseif (preg_match('/(OK|FAILURES).*$/mi', $log, $m)) {
    $summary = trim($m[0]);
}

echo "\n=====================================================\n";
echo "VisitorManagement Dusk run complete.\n";
echo "  Summary : {$summary}\n";
echo "  Proof   : {$proofFile}\n";
echo "  Exit    : {$exitCode}\n";
echo "=====================================================\n";

exit($exitCode);

/**
 * Run a child process, streaming output to console AND appending to $logFile.
 */
function runProcess(string $binary, array $args, string $cwd, string $logFile): int
{
    $command = array_merge([$binary], $args);

    $descriptors = [
        0 => ['pipe', 'r'],
        1 => ['pipe', 'w'],
        2 => ['pipe', 'w'],
    ];

    $process = proc_open($command, $descriptors, $pipes, $cwd);
    if (!is_resource($process)) {
        fwrite(STDERR, "ERROR: failed to start process.\n");
        return 1;
    }

    fclose($pipes[0]);
    $handle = fopen($logFile, 'a');

    foreach ([1, 2] as $fd) {
        stream_set_blocking($pipes[$fd], false);
    }

    do {
        $status = proc_get_status($process);
        foreach ([1, 2] as $fd) {
            $chunk = stream_get_contents($pipes[$fd]);
            if ($chunk !== '' && $chunk !== false) {
                echo $chunk;
                if ($handle) {
                    fwrite($handle, $chunk);
                }
            }
        }
        usleep(50000);
    } while ($status['running']);

    // drain remaining
    foreach ([1, 2] as $fd) {
        $chunk = stream_get_contents($pipes[$fd]);
        if ($chunk !== '' && $chunk !== false) {
            echo $chunk;
            if ($handle) {
                fwrite($handle, $chunk);
            }
        }
        fclose($pipes[$fd]);
    }

    if ($handle) {
        fclose($handle);
    }

    return proc_close($process);
}
