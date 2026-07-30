<?php

/**
 * Cross-platform Dusk runner for the FrontOffice → Appointment suite.
 * Single portable PHP script (no .ps1/.sh pair). Runs on Windows and Linux/macOS.
 *
 * Usage:
 *   php run-Appointment-tests.php [--php=/path/to/php] [--filter=test_appointment_20] [--sync-db]
 *
 * It:
 *   - resolves the prime_testing project root (where artisan lives),
 *   - copies this test file into tests/Browser/Modules/FrontOffice/Appointment/ if missing,
 *   - optionally migrates the tenant DB (--sync-db),
 *   - cleans old screenshots,
 *   - runs `php artisan dusk --filter=...`,
 *   - tees output to a timestamped proof/ file,
 *   - parses Tests/Assertions/Failures and exits with the dusk exit code.
 */

$args = array_slice($argv, 1);
$phpBinary = PHP_BINARY;
$filter = 'fof_Appointment_TestCas';
$syncDb = false;

foreach ($args as $arg) {
    if (str_starts_with($arg, '--php=')) {
        $phpBinary = substr($arg, 6);
    } elseif (str_starts_with($arg, '--filter=')) {
        $filter = substr($arg, 9);
    } elseif ($arg === '--sync-db') {
        $syncDb = true;
    }
}

$here = __DIR__;

/** Locate the prime_testing project root (artisan present). */
function locateTestRepo(string $start): ?string
{
    $candidates = [
        getenv('TEST_FILE_REPO') ?: '',
        '/Users/bkwork/Herd/prime_testing',
        dirname($start, 8) . '/Herd/prime_testing',
    ];
    foreach ($candidates as $c) {
        if ($c !== '' && is_file(rtrim($c, '/\\') . DIRECTORY_SEPARATOR . 'artisan')) {
            return rtrim($c, '/\\');
        }
    }
    return null;
}

$testRepo = locateTestRepo($here);
if ($testRepo === null) {
    fwrite(STDERR, "ERROR: could not locate prime_testing (artisan). Set TEST_FILE_REPO env var.\n");
    exit(2);
}

$targetDir = $testRepo . str_replace('/', DIRECTORY_SEPARATOR, '/tests/Browser/Modules/FrontOffice/Appointment');
$targetFile = $targetDir . DIRECTORY_SEPARATOR . 'fof_Appointment_TestCas.php';
$sourceFile = $here . DIRECTORY_SEPARATOR . 'fof_Appointment_TestCas.php';

if (!is_dir($targetDir)) {
    @mkdir($targetDir, 0777, true);
}
if (is_file($sourceFile)) {
    @copy($sourceFile, $targetFile);
    echo "Staged test file → {$targetFile}\n";
}

/** Clean old Dusk screenshots. */
$shotDir = $testRepo . str_replace('/', DIRECTORY_SEPARATOR, '/tests/Browser/screenshots');
if (is_dir($shotDir)) {
    foreach (glob($shotDir . DIRECTORY_SEPARATOR . 'failure-*') ?: [] as $f) {
        @unlink($f);
    }
}

/** Proof directory + timestamped log. */
$proofDir = $here . DIRECTORY_SEPARATOR . 'proof';
if (!is_dir($proofDir)) {
    @mkdir($proofDir, 0777, true);
}
$stamp = date('Ymd_His');
$proofFile = $proofDir . DIRECTORY_SEPARATOR . "Appointment_dusk_{$stamp}.log";

$env = $_ENV;
$env['APP_ENV'] = 'testing';

/** Run a command in $testRepo, tee to $proofFile, return [exitCode, output]. */
function runTee(string $php, array $cmdArgs, string $cwd, array $env, string $proofFile): array
{
    $full = array_merge([$php], $cmdArgs);
    $descriptors = [0 => ['pipe', 'r'], 1 => ['pipe', 'w'], 2 => ['pipe', 'w']];
    $proc = proc_open($full, $descriptors, $pipes, $cwd, $env);
    if (!is_resource($proc)) {
        return [1, ''];
    }
    fclose($pipes[0]);
    $log = fopen($proofFile, 'a');
    $buffer = '';
    while (true) {
        $out = fgets($pipes[1]);
        $err = fgets($pipes[2]);
        if ($out === false && $err === false) {
            if (feof($pipes[1]) && feof($pipes[2])) {
                break;
            }
        }
        foreach ([$out, $err] as $line) {
            if ($line !== false) {
                echo $line;
                if ($log) {
                    fwrite($log, $line);
                }
                $buffer .= $line;
            }
        }
    }
    fclose($pipes[1]);
    fclose($pipes[2]);
    if ($log) {
        fclose($log);
    }
    $code = proc_close($proc);
    return [$code, $buffer];
}

if ($syncDb) {
    echo "== Migrating tenant DB (--sync-db) ==\n";
    runTee($phpBinary, ['artisan', 'tenants:migrate', '--force'], $testRepo, $env, $proofFile);
}

echo "== Clearing route cache ==\n";
runTee($phpBinary, ['artisan', 'route:clear'], $testRepo, $env, $proofFile);

echo "== Running Dusk: --filter={$filter} ==\n";
[$exitCode, $output] = runTee(
    $phpBinary,
    ['artisan', 'dusk', '--filter=' . $filter],
    $testRepo,
    $env,
    $proofFile
);

/** Parse the PHPUnit/Pest summary line(s). */
$tests = $assertions = $failures = $skipped = null;
if (preg_match('/Tests:\s*(\d+)/i', $output, $m)) {
    $tests = (int) $m[1];
}
if (preg_match('/Assertions:\s*(\d+)/i', $output, $m)) {
    $assertions = (int) $m[1];
}
if (preg_match('/Failures:\s*(\d+)/i', $output, $m)) {
    $failures = (int) $m[1];
}
if (preg_match('/(Skipped|Incomplete):\s*(\d+)/i', $output, $m)) {
    $skipped = (int) $m[2];
}

echo "\n=====================================================\n";
echo "  FrontOffice → Appointment — Dusk Run Summary\n";
echo "-----------------------------------------------------\n";
echo "  Filter     : {$filter}\n";
echo '  Tests      : ' . ($tests ?? 'n/a') . "\n";
echo '  Assertions : ' . ($assertions ?? 'n/a') . "\n";
echo '  Failures   : ' . ($failures ?? 'n/a') . "\n";
echo '  Skipped    : ' . ($skipped ?? 'n/a') . "\n";
echo "  Exit code  : {$exitCode}\n";
echo "  Proof      : {$proofFile}\n";
echo "=====================================================\n";

exit($exitCode);
