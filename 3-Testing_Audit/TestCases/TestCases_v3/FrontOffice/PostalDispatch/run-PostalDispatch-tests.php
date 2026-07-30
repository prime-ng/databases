<?php

/**
 * Cross-platform test runner for the FrontOffice PostalDispatch suite.
 * Runs natively on Windows AND Linux/macOS (no .ps1/.sh duplication).
 *
 * Usage:
 *   php run-PostalDispatch-tests.php [--php=/path/to/php] [--filter=test_postaldispatch_20] [--sync-db]
 *
 * It expects the test file to be copied/symlinked into the prime_testing Dusk suite
 * (tests/Browser/) before running, since `artisan dusk` resolves from the app root.
 */

declare(strict_types=1);

$options = getopt('', ['php::', 'filter::', 'sync-db', 'help']);

if (isset($options['help'])) {
    echo "Usage: php run-PostalDispatch-tests.php [--php=BIN] [--filter=PATTERN] [--sync-db]\n";
    exit(0);
}

$phpBinary   = $options['php']    ?? PHP_BINARY;
$filter      = $options['filter'] ?? 'fof_PostalDispatch_TestCas';
$syncDb      = array_key_exists('sync-db', $options);

// ---- Resolve the app (prime_testing) root ----
$appRoot = getenv('PRIME_TESTING_PATH')
    ?: (is_dir('/Users/bkwork/Herd/prime_testing') ? '/Users/bkwork/Herd/prime_testing' : getcwd());

$isWindows = PHP_OS_FAMILY === 'Windows';

fwrite(STDOUT, "==============================================\n");
fwrite(STDOUT, " PostalDispatch (FOF) — Dusk runner\n");
fwrite(STDOUT, " OS        : " . PHP_OS_FAMILY . "\n");
fwrite(STDOUT, " PHP       : {$phpBinary}\n");
fwrite(STDOUT, " App root  : {$appRoot}\n");
fwrite(STDOUT, " Filter    : {$filter}\n");
fwrite(STDOUT, "==============================================\n\n");

// ---- proof dir + timestamped log ----
$proofDir = __DIR__ . DIRECTORY_SEPARATOR . 'proof';
if (!is_dir($proofDir)) {
    @mkdir($proofDir, 0775, true);
}
$stamp    = date('Ymd_His');
$logFile  = $proofDir . DIRECTORY_SEPARATOR . "PostalDispatch_{$stamp}.log";

// ---- clean stale Dusk screenshots ----
$shotDir = $appRoot . DIRECTORY_SEPARATOR . 'tests' . DIRECTORY_SEPARATOR . 'Browser'
         . DIRECTORY_SEPARATOR . 'screenshots';
if (is_dir($shotDir)) {
    foreach ((array) glob($shotDir . DIRECTORY_SEPARATOR . 'failure-*') as $f) {
        if (is_file($f)) {
            @unlink($f);
        }
    }
    fwrite(STDOUT, "Cleaned stale failure screenshots.\n");
}

// ---- build the command ----
$cmd = [
    $phpBinary,
    $appRoot . DIRECTORY_SEPARATOR . 'artisan',
    'dusk',
    '--filter=' . $filter,
];
if ($syncDb) {
    // hint: caller wants a DB sync first; run migrate on the testing connection.
    fwrite(STDOUT, "Running migrations (--sync-db)…\n");
    runProcess([$phpBinary, $appRoot . DIRECTORY_SEPARATOR . 'artisan', 'migrate', '--force'], $appRoot, $logFile, true);
}

fwrite(STDOUT, "Command   : " . implode(' ', $cmd) . "\n\n");

// ---- run + tee ----
$exitCode = runProcess($cmd, $appRoot, $logFile, false, ['APP_ENV' => 'testing']);

// ---- parse summary ----
$output = is_file($logFile) ? (string) file_get_contents($logFile) : '';
$tests = $assertions = $failures = 0;
if (preg_match('/Tests:\s+(\d+)/', $output, $m))      { $tests      = (int) $m[1]; }
if (preg_match('/Assertions:\s+(\d+)/', $output, $m)) { $assertions = (int) $m[1]; }
if (preg_match('/Failures:\s+(\d+)/', $output, $m))   { $failures   = (int) $m[1]; }
// PHPUnit-style fallback
if ($tests === 0 && preg_match('/OK \((\d+) tests?, (\d+) assertions?\)/', $output, $m)) {
    $tests = (int) $m[1];
    $assertions = (int) $m[2];
}

fwrite(STDOUT, "\n----------------------------------------------\n");
fwrite(STDOUT, " Summary\n");
fwrite(STDOUT, "   Tests      : {$tests}\n");
fwrite(STDOUT, "   Assertions : {$assertions}\n");
fwrite(STDOUT, "   Failures   : {$failures}\n");
fwrite(STDOUT, "   Exit code  : {$exitCode}\n");
fwrite(STDOUT, "   Log        : {$logFile}\n");
fwrite(STDOUT, "----------------------------------------------\n");

exit($exitCode);

/**
 * Run a process, streaming to STDOUT and appending to $logFile.
 *
 * @param array<int,string> $cmd
 * @param array<string,string> $env
 */
function runProcess(array $cmd, string $cwd, string $logFile, bool $quiet = false, array $env = []): int
{
    $descriptors = [
        0 => ['pipe', 'r'],
        1 => ['pipe', 'w'],
        2 => ['pipe', 'w'],
    ];

    $mergedEnv = array_merge(getEnvArray(), $env);

    $proc = proc_open($cmd, $descriptors, $pipes, $cwd, $mergedEnv);
    if (!is_resource($proc)) {
        fwrite(STDERR, "Failed to start process.\n");
        return 1;
    }

    fclose($pipes[0]);
    stream_set_blocking($pipes[1], false);
    stream_set_blocking($pipes[2], false);

    $handle = fopen($logFile, 'a');

    while (true) {
        $out = stream_get_contents($pipes[1]);
        $err = stream_get_contents($pipes[2]);
        if ($out !== '' && $out !== false) {
            if (!$quiet) { fwrite(STDOUT, $out); }
            if ($handle) { fwrite($handle, $out); }
        }
        if ($err !== '' && $err !== false) {
            if (!$quiet) { fwrite(STDERR, $err); }
            if ($handle) { fwrite($handle, $err); }
        }
        $status = proc_get_status($proc);
        if (!$status['running']) {
            break;
        }
        usleep(100000);
    }

    fclose($pipes[1]);
    fclose($pipes[2]);
    if ($handle) { fclose($handle); }

    return proc_close($proc);
}

/** @return array<string,string> */
function getEnvArray(): array
{
    $env = [];
    foreach ($_SERVER as $k => $v) {
        if (is_string($v)) {
            $env[$k] = $v;
        }
    }
    return $env;
}
