<?php

/**
 * Single cross-platform runner for the FrontOffice → Circular Dusk suite.
 * Runs natively on Windows and Linux/macOS (no .ps1/.sh pair).
 *
 * Usage:
 *   php run-Circular-tests.php [--php=/path/to/php] [--filter=test_circular_13] [--sync-db]
 *
 * It: locates the prime_testing project root, optionally migrates the test DB,
 * cleans stale screenshots, runs `php artisan dusk` filtered to this class,
 * tees output to a timestamped proof/ file, parses the Pest/PHPUnit summary,
 * prints a compact result, and exits with the underlying dusk exit code.
 */

$options = getopt('', ['php::', 'filter::', 'sync-db']);

$phpBinary   = $options['php']    ?? PHP_BINARY;
$filterClass = $options['filter'] ?? 'fof_Circular_TestCas';
$syncDb      = array_key_exists('sync-db', $options);

// ── Resolve the prime_testing project root (where artisan lives). ──────────────
$candidates = [
    getcwd(),
    '/Users/bkwork/Herd/prime_testing',
    dirname(__DIR__, 6) . '/Herd/prime_testing',
];
$projectRoot = null;
foreach ($candidates as $candidate) {
    if ($candidate && is_file(rtrim($candidate, '/\\') . DIRECTORY_SEPARATOR . 'artisan')) {
        $projectRoot = rtrim($candidate, '/\\');
        break;
    }
}
if ($projectRoot === null) {
    fwrite(STDERR, "ERROR: could not locate the prime_testing project root (artisan not found).\n");
    fwrite(STDERR, "Run this script from the prime_testing directory, or pass its path via cwd.\n");
    exit(2);
}

$proofDir = __DIR__ . DIRECTORY_SEPARATOR . 'proof';
if (!is_dir($proofDir) && !@mkdir($proofDir, 0777, true) && !is_dir($proofDir)) {
    fwrite(STDERR, "ERROR: cannot create proof directory: {$proofDir}\n");
    exit(2);
}
$timestamp = date('Ymd_His');
$proofFile = $proofDir . DIRECTORY_SEPARATOR . "Circular_dusk_{$timestamp}.log";

echo "==============================================================\n";
echo " FrontOffice / Circular — Dusk runner\n";
echo " project : {$projectRoot}\n";
echo " php     : {$phpBinary}\n";
echo " filter  : {$filterClass}\n";
echo " proof   : {$proofFile}\n";
echo "==============================================================\n\n";

// ── Clean stale Dusk screenshots (best-effort). ───────────────────────────────
foreach ([
    $projectRoot . '/tests/Browser/screenshots',
    $projectRoot . '/tests/Browser/console',
] as $artifactDir) {
    if (is_dir($artifactDir)) {
        foreach (glob($artifactDir . '/*') ?: [] as $file) {
            if (is_file($file)) {
                @unlink($file);
            }
        }
    }
}

$runCommand = function (array $command) use ($projectRoot): int {
    $descriptors = [0 => STDIN, 1 => ['pipe', 'w'], 2 => ['pipe', 'w']];
    $process = proc_open($command, $descriptors, $pipes, $projectRoot, null);
    if (!is_resource($process)) {
        return 1;
    }
    $output = '';
    while (!feof($pipes[1])) {
        $chunk = fgets($pipes[1]);
        if ($chunk !== false) {
            echo $chunk;
            $output .= $chunk;
        }
    }
    $err = stream_get_contents($pipes[2]);
    if ($err) {
        echo $err;
    }
    fclose($pipes[1]);
    fclose($pipes[2]);
    return proc_close($process);
};

// ── Optional: migrate the Dusk test DB. ───────────────────────────────────────
if ($syncDb) {
    echo "→ Syncing test database (migrate)...\n";
    $runCommand([$phpBinary, 'artisan', 'migrate', '--force']);
    echo "\n";
}

// ── Ensure a clean route cache (stale cache is a documented prereq). ───────────
$runCommand([$phpBinary, 'artisan', 'route:clear']);

// ── Run Dusk, capturing output for the proof file. ────────────────────────────
$duskCommand = [$phpBinary, 'artisan', 'dusk', '--filter=' . $filterClass];
echo '→ ' . implode(' ', $duskCommand) . "\n\n";

$descriptors = [0 => STDIN, 1 => ['pipe', 'w'], 2 => ['pipe', 'w']];
$process = proc_open($duskCommand, $descriptors, $pipes, $projectRoot, null);
$fullOutput = '';
$exitCode = 1;
if (is_resource($process)) {
    while (!feof($pipes[1])) {
        $chunk = fgets($pipes[1]);
        if ($chunk !== false) {
            echo $chunk;
            $fullOutput .= $chunk;
        }
    }
    $err = stream_get_contents($pipes[2]);
    if ($err) {
        echo $err;
        $fullOutput .= $err;
    }
    fclose($pipes[1]);
    fclose($pipes[2]);
    $exitCode = proc_close($process);
}

file_put_contents($proofFile, $fullOutput);

// ── Parse the summary line(s). ────────────────────────────────────────────────
$tests = $assertions = $failures = $skipped = null;
if (preg_match('/Tests:\s*.*?(\d+)\s+passed/i', $fullOutput, $m)) {
    $tests = (int) $m[1];
}
if (preg_match('/(\d+)\s+failed/i', $fullOutput, $m)) {
    $failures = (int) $m[1];
}
if (preg_match('/(\d+)\s+skipped/i', $fullOutput, $m)) {
    $skipped = (int) $m[1];
}
if (preg_match('/Assertions:\s*(\d+)/i', $fullOutput, $m)) {
    $assertions = (int) $m[1];
}

echo "\n==============================================================\n";
echo " RESULT\n";
echo '  passed     : ' . ($tests ?? 'n/a') . "\n";
echo '  failed     : ' . ($failures ?? 'n/a') . "\n";
echo '  skipped    : ' . ($skipped ?? 'n/a') . "\n";
echo '  assertions : ' . ($assertions ?? 'n/a') . "\n";
echo '  exit code  : ' . $exitCode . "\n";
echo '  proof      : ' . $proofFile . "\n";
echo "==============================================================\n";

exit($exitCode);
