<?php
/**
 * Cross-platform test runner for the FrontOffice · Feedback Dusk suite.
 *
 * Runs natively on Windows and Linux/macOS (PHP is guaranteed present in this
 * Laravel/Dusk project). Replaces the old .ps1 + .sh pair.
 *
 * Usage:
 *   php run-Feedback-tests.php [--php=/path/to/php] [--filter=test_feedback_01] [--sync-db]
 *
 * Behaviour:
 *   - copies fof_Feedback_TestCas.php into the prime_testing Dusk tree (if not already there),
 *   - cleans old screenshots,
 *   - runs `php artisan dusk` filtered to the Feedback suite,
 *   - tees output to a timestamped file under ./proof/,
 *   - parses "Tests: N, Assertions: A, Failures: F" and prints a summary,
 *   - exits with the underlying dusk exit code.
 */

$options = getopt('', ['php::', 'filter::', 'sync-db', 'test-repo::']);

$phpBinary   = $options['php']      ?? PHP_BINARY;
$filter      = $options['filter']   ?? 'fof_Feedback_TestCas';
$syncDb      = array_key_exists('sync-db', $options);

// Resolve the prime_testing repo (Dusk host project).
$defaultTestRepo = '/Users/bkwork/Herd/prime_testing';
$testRepo = $options['test-repo'] ?? getenv('TEST_FILE_REPO') ?: $defaultTestRepo;
$testRepo = rtrim($testRepo, DIRECTORY_SEPARATOR);

$suiteFile   = __DIR__ . DIRECTORY_SEPARATOR . 'fof_Feedback_TestCas.php';
$destDir     = $testRepo . '/tests/Browser/Modules/FrontOffice/Feedback';
$destFile    = $destDir . '/fof_Feedback_TestCas.php';
$proofDir    = __DIR__ . DIRECTORY_SEPARATOR . 'proof';

function line(string $s = ''): void { fwrite(STDOUT, $s . PHP_EOL); }

line('==================================================================');
line(' FrontOffice · Feedback — Dusk runner');
line('==================================================================');
line(' PHP binary : ' . $phpBinary);
line(' Test repo  : ' . $testRepo);
line(' Filter     : ' . $filter);
line(' OS family  : ' . PHP_OS_FAMILY);
line('');

if (!is_dir($testRepo)) {
    line('ERROR: prime_testing repo not found at ' . $testRepo);
    line('Pass --test-repo=/path/to/prime_testing or set TEST_FILE_REPO.');
    exit(2);
}
if (!is_file($suiteFile)) {
    line('ERROR: suite file missing: ' . $suiteFile);
    exit(2);
}

// Stage the suite into the Dusk tree.
if (!is_dir($destDir)) {
    @mkdir($destDir, 0777, true);
}
if (!@copy($suiteFile, $destFile)) {
    line('WARNING: could not copy suite into ' . $destFile . ' — will run against any existing copy.');
} else {
    line('Staged suite → ' . $destFile);
}

// Clean old screenshots.
$shotDir = $testRepo . '/tests/Browser/screenshots';
if (is_dir($shotDir)) {
    foreach (glob($shotDir . '/failure-*') ?: [] as $f) {
        @unlink($f);
    }
    line('Cleaned old failure screenshots.');
}

// Prep proof dir + file.
if (!is_dir($proofDir)) {
    @mkdir($proofDir, 0777, true);
}
$stamp     = date('Ymd-His');
$proofFile = $proofDir . DIRECTORY_SEPARATOR . "feedback-dusk-{$stamp}.log";

// Optional DB sync.
$commands = [];
if ($syncDb) {
    $commands[] = [$phpBinary, 'artisan', 'migrate', '--force'];
}
$duskCmd = [$phpBinary, 'artisan', 'dusk', '--filter=' . $filter];
$commands[] = $duskCmd;

$env = array_merge($_ENV, getenv() ?: [], ['APP_ENV' => 'testing']);

$capturedTail = '';
$exitCode = 0;

foreach ($commands as $cmd) {
    line('');
    line('> ' . implode(' ', $cmd));
    line('------------------------------------------------------------------');

    $descriptors = [0 => ['pipe', 'r'], 1 => ['pipe', 'w'], 2 => ['pipe', 'w']];
    $proc = proc_open($cmd, $descriptors, $pipes, $testRepo, $env);
    if (!is_resource($proc)) {
        line('ERROR: failed to launch: ' . implode(' ', $cmd));
        $exitCode = 1;
        break;
    }
    fclose($pipes[0]);
    stream_set_blocking($pipes[1], false);
    stream_set_blocking($pipes[2], false);

    $handle = fopen($proofFile, 'a');
    if ($handle) {
        fwrite($handle, '$ ' . implode(' ', $cmd) . PHP_EOL);
    }

    while (true) {
        $out = fgets($pipes[1]);
        $err = fgets($pipes[2]);
        if ($out === false && $err === false) {
            $status = proc_get_status($proc);
            if (!$status['running']) {
                break;
            }
            usleep(50000);
            continue;
        }
        foreach ([$out, $err] as $chunk) {
            if ($chunk === false || $chunk === '') {
                continue;
            }
            fwrite(STDOUT, $chunk);
            if ($handle) {
                fwrite($handle, $chunk);
            }
            $capturedTail .= $chunk;
            if (strlen($capturedTail) > 20000) {
                $capturedTail = substr($capturedTail, -20000);
            }
        }
    }

    fclose($pipes[1]);
    fclose($pipes[2]);
    if ($handle) {
        fclose($handle);
    }
    $exitCode = proc_close($proc);
    if ($exitCode !== 0) {
        break; // stop the chain on first failure
    }
}

// Parse the PHPUnit/Pest summary.
$tests = $assertions = $failures = null;
if (preg_match('/Tests:\s*(\d+)/i', $capturedTail, $m)) { $tests = (int) $m[1]; }
if (preg_match('/Assertions:\s*(\d+)/i', $capturedTail, $m)) { $assertions = (int) $m[1]; }
if (preg_match('/(\d+)\s+failed/i', $capturedTail, $m)) { $failures = (int) $m[1]; }
if ($failures === null && preg_match('/Failures:\s*(\d+)/i', $capturedTail, $m)) { $failures = (int) $m[1]; }

line('');
line('==================================================================');
line(' SUMMARY');
line('==================================================================');
line(' Tests      : ' . ($tests ?? 'n/a'));
line(' Assertions : ' . ($assertions ?? 'n/a'));
line(' Failures   : ' . ($failures ?? 'n/a'));
line(' Exit code  : ' . $exitCode);
line(' Proof file : ' . $proofFile);
line('==================================================================');

exit($exitCode);
