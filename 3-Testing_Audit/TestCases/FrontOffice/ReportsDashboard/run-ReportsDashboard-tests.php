<?php

declare(strict_types=1);

/**
 * Cross-platform runner for the FrontOffice ReportsDashboard Dusk suite.
 *
 * Usage (from anywhere):
 *   php run-ReportsDashboard-tests.php
 *   php run-ReportsDashboard-tests.php --filter=test_TC_R01_dashboard_renders_with_kpis
 *
 * What it does:
 *   1. Locates the prime_testing runner root (env PRIME_TESTING_PATH or ../../ heuristics).
 *   2. Copies this suite into tests/Browser/Modules/FrontOffice/ReportsDashboard so the
 *      Tests\Browser\Modules\FrontOffice\ReportsDashboard namespace autoloads.
 *   3. Invokes php artisan dusk on that single file with any passthrough --filter.
 *
 * PREREQUISITES (see fof_ReportsDashboardValidation_Report.md):
 *   - FrontOffice = true in prime_testing/modules_statuses.json  (else /front-office/* 404s)
 *   - APP_ENV=testing, DUSK_TENANT_URL pointing at a tenant domain, ChromeDriver running.
 */

$suiteFile = 'fof_ReportsDashboard_TestCas.php';
$relTarget = 'tests/Browser/Modules/FrontOffice/ReportsDashboard';

$here = __DIR__;

function findRunnerRoot(string $here): ?string
{
    $env = getenv('PRIME_TESTING_PATH');
    if ($env && is_dir($env) && is_file($env . '/artisan')) {
        return rtrim($env, '/\\');
    }
    // Common local layout: <...>/Herd/prime_testing
    $candidates = [
        $here . '/../../../../../../prime_testing',
        getenv('HOME') . '/Herd/prime_testing',
        '/Users/bkwork/Herd/prime_testing',
    ];
    foreach ($candidates as $c) {
        if ($c && is_dir($c) && is_file($c . '/artisan')) {
            return realpath($c) ?: $c;
        }
    }
    return null;
}

$runner = findRunnerRoot($here);
if ($runner === null) {
    fwrite(STDERR, "[ERROR] Could not locate prime_testing runner root.\n");
    fwrite(STDERR, "        Set PRIME_TESTING_PATH=/path/to/prime_testing and retry.\n");
    exit(2);
}

$src = $here . DIRECTORY_SEPARATOR . $suiteFile;
if (!is_file($src)) {
    fwrite(STDERR, "[ERROR] Suite file not found next to runner: {$src}\n");
    exit(2);
}

$destDir = $runner . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $relTarget);
if (!is_dir($destDir) && !mkdir($destDir, 0777, true) && !is_dir($destDir)) {
    fwrite(STDERR, "[ERROR] Could not create target dir: {$destDir}\n");
    exit(2);
}

$dest = $destDir . DIRECTORY_SEPARATOR . $suiteFile;
if (!copy($src, $dest)) {
    fwrite(STDERR, "[ERROR] Failed to copy suite into runner: {$dest}\n");
    exit(2);
}
fwrite(STDOUT, "[OK] Copied suite to {$dest}\n");

// Passthrough --filter (and any other args) to artisan dusk.
$args = array_slice($argv, 1);
$filterArg = '';
foreach ($args as $a) {
    if (str_starts_with($a, '--filter')) {
        $filterArg = ' ' . escapeshellarg($a);
    }
}

$phpBin = PHP_BINARY ?: 'php';
$duskTarget = escapeshellarg($dest);
$cmd = escapeshellarg($phpBin) . ' artisan dusk ' . $duskTarget . $filterArg;

fwrite(STDOUT, "[RUN] (cwd={$runner}) {$cmd}\n");

$descriptors = [0 => STDIN, 1 => STDOUT, 2 => STDERR];
$proc = proc_open($cmd, $descriptors, $pipes, $runner);
if (!is_resource($proc)) {
    fwrite(STDERR, "[ERROR] Failed to start artisan dusk.\n");
    exit(1);
}
$exit = proc_close($proc);
fwrite(STDOUT, "\n[DONE] artisan dusk exited with code {$exit}\n");
exit($exit);
