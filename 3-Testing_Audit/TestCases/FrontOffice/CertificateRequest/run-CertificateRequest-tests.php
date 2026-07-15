<?php

/**
 * Cross-platform test runner for the FrontOffice / CertificateRequest Dusk suite.
 * Replaces the legacy .ps1 + .sh pair — pure PHP, runs on Windows and Linux/macOS.
 *
 * USAGE (run from the prime_testing project root, or pass --project):
 *   php run-CertificateRequest-tests.php
 *   php run-CertificateRequest-tests.php --php=/usr/bin/php8.3
 *   php run-CertificateRequest-tests.php --filter=test_cert_70_duplicate_request_number_is_rejected
 *   php run-CertificateRequest-tests.php --sync-db
 *   php run-CertificateRequest-tests.php --project=/Users/bkwork/Herd/prime_testing
 *
 * PREREQUISITES (see fof_CertificateRequestValidation_Report.md):
 *   - FrontOffice must be ENABLED in prime_testing/modules_statuses.json (else /front-office/* routes 404).
 *   - APP_ENV=testing (Dusk CSRF bypass); ChromeDriver aligned to the installed Chrome.
 *   - The class file (fof_CertificateRequest_TestCas.php) copied into
 *     tests/Browser/Modules/FrontOffice/CertificateRequest/ (namespace Tests\Browser).
 */

declare(strict_types=1);

$options = getopt('', ['php::', 'filter::', 'sync-db', 'project::']);

$phpBinary = $options['php'] ?? PHP_BINARY;
$filter = $options['filter'] ?? 'fof_CertificateRequest_TestCas';
$syncDb = array_key_exists('sync-db', $options);
$projectRoot = rtrim($options['project'] ?? getcwd(), DIRECTORY_SEPARATOR);

$isWindows = PHP_OS_FAMILY === 'Windows';

fwrite(STDOUT, "==============================================================\n");
fwrite(STDOUT, " FrontOffice · CertificateRequest — Dusk suite runner\n");
fwrite(STDOUT, " OS: " . PHP_OS_FAMILY . " | PHP: {$phpBinary}\n");
fwrite(STDOUT, " Project: {$projectRoot}\n");
fwrite(STDOUT, " Filter: {$filter}\n");
fwrite(STDOUT, "==============================================================\n\n");

$artisan = $projectRoot . DIRECTORY_SEPARATOR . 'artisan';
if (!is_file($artisan)) {
    fwrite(STDERR, "ERROR: artisan not found at {$artisan}\n");
    fwrite(STDERR, "Pass --project=/path/to/prime_testing (the Dusk-enabled project root).\n");
    exit(2);
}

// 1. Clean old screenshots so a failed run's artifacts are unambiguous.
$screenshotDir = $projectRoot . DIRECTORY_SEPARATOR . 'tests' . DIRECTORY_SEPARATOR . 'Browser' . DIRECTORY_SEPARATOR . 'screenshots';
if (is_dir($screenshotDir)) {
    foreach (glob($screenshotDir . DIRECTORY_SEPARATOR . '*.png') ?: [] as $png) {
        @unlink($png);
    }
    fwrite(STDOUT, "Cleaned old screenshots in {$screenshotDir}\n");
}

// 2. Optional DB sync before running.
if ($syncDb) {
    fwrite(STDOUT, "Running migrations (--sync-db)...\n");
    runProcess($phpBinary, [$artisan, 'migrate', '--force'], $projectRoot);
}

// 3. Prepare a timestamped proof file.
$proofDir = $projectRoot . DIRECTORY_SEPARATOR . 'proof';
if (!is_dir($proofDir)) {
    @mkdir($proofDir, 0777, true);
}
$stamp = date('Ymd_His');
$proofFile = $proofDir . DIRECTORY_SEPARATOR . "CertificateRequest_{$stamp}.log";

// 4. Run the Dusk suite, teeing output to the proof file.
$duskArgs = [$artisan, 'dusk', '--filter=' . $filter];
fwrite(STDOUT, "\nRunning: {$phpBinary} " . implode(' ', array_slice($duskArgs, 1)) . "\n\n");

$output = '';
$exitCode = runProcess($phpBinary, $duskArgs, $projectRoot, function (string $chunk) use (&$output): void {
    fwrite(STDOUT, $chunk);
    $output .= $chunk;
});

@file_put_contents($proofFile, $output);

// 5. Parse the Pest/PHPUnit summary line.
$tests = $assertions = $failures = null;
if (preg_match('/Tests:\s+.*?(\d+)\s+passed/i', $output, $m)) {
    $tests = (int) $m[1];
}
if (preg_match('/Assertions:\s+(\d+)/i', $output, $m)) {
    $assertions = (int) $m[1];
}
if (preg_match('/(\d+)\s+failed/i', $output, $m)) {
    $failures = (int) $m[1];
}

fwrite(STDOUT, "\n==============================================================\n");
fwrite(STDOUT, " SUMMARY\n");
fwrite(STDOUT, "   Passed tests   : " . ($tests ?? 'n/a') . "\n");
fwrite(STDOUT, "   Assertions     : " . ($assertions ?? 'n/a') . "\n");
fwrite(STDOUT, "   Failures       : " . ($failures ?? '0') . "\n");
fwrite(STDOUT, "   Exit code      : {$exitCode}\n");
fwrite(STDOUT, "   Proof          : {$proofFile}\n");
fwrite(STDOUT, "==============================================================\n");

exit($exitCode);

/**
 * Portable process runner using proc_open (works identically on Windows and *nix).
 *
 * @param callable|null $onOutput  Optional streaming callback for each output chunk.
 */
function runProcess(string $binary, array $args, string $cwd, ?callable $onOutput = null): int
{
    $command = array_merge([$binary], $args);

    $descriptors = [
        0 => ['pipe', 'r'],
        1 => ['pipe', 'w'],
        2 => ['pipe', 'w'],
    ];

    $process = proc_open($command, $descriptors, $pipes, $cwd);
    if (!is_resource($process)) {
        fwrite(STDERR, "ERROR: failed to start process: " . implode(' ', $command) . "\n");
        return 1;
    }

    fclose($pipes[0]);
    stream_set_blocking($pipes[1], false);
    stream_set_blocking($pipes[2], false);

    do {
        foreach ([1, 2] as $i) {
            $chunk = stream_get_contents($pipes[$i]);
            if ($chunk !== '' && $chunk !== false) {
                if ($onOutput) {
                    $onOutput($chunk);
                } else {
                    fwrite(STDOUT, $chunk);
                }
            }
        }
        $status = proc_get_status($process);
        usleep(50000);
    } while ($status['running']);

    // Drain any remaining buffered output.
    foreach ([1, 2] as $i) {
        $chunk = stream_get_contents($pipes[$i]);
        if ($chunk !== '' && $chunk !== false) {
            if ($onOutput) {
                $onOutput($chunk);
            } else {
                fwrite(STDOUT, $chunk);
            }
        }
        fclose($pipes[$i]);
    }

    return proc_close($process);
}
