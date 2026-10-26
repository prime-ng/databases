<?php
/**
 * AI Brain activity builder.
 *
 * Reads:
 *   - Git history of the CURRENT branch only (HEAD) in ../prime_ai
 *   - live/YYYY-MM-DD/<agent>.md journals
 *   - daily/YYYY-MM-DD.md reports
 *
 * Writes:
 *   - data.js  (window.BRAIN_DATA = {...})
 *
 * Usage:  php build.php
 */

declare(strict_types=1);

date_default_timezone_set('Asia/Kolkata');

$BRAIN = __DIR__;
$REPO  = dirname($BRAIN) . '/prime_ai';

if (!is_dir($REPO . '/.git')) {
    fwrite(STDERR, "ERROR: git repo not found at {$REPO}\n");
    exit(1);
}

function run(string $cmd): string
{
    $out = shell_exec($cmd);
    if ($out === null) {
        fwrite(STDERR, "ERROR: command failed: {$cmd}\n");
        exit(1);
    }
    return $out;
}

function clean(string $s): string
{
    return trim(str_replace(['`', '**'], '', $s));
}

function utf8Clean(mixed $value): mixed
{
    if (is_array($value)) {
        foreach ($value as $k => $v) {
            $value[$k] = utf8Clean($v);
        }
        return $value;
    }
    if (!is_string($value)) {
        return $value;
    }
    if (function_exists('mb_scrub')) {
        return mb_scrub($value, 'UTF-8');
    }
    return iconv('UTF-8', 'UTF-8//IGNORE', $value) ?: '';
}

/* ---------------------------------------------------------------- Git --- */

$fmt = '@@@%H%x1f%h%x1f%ad%x1f%an%x1f%s%x1f%P';
$cmd = 'git -C ' . escapeshellarg($REPO)
    . ' log HEAD --date=format-local:%Y-%m-%d__%H:%M'
    . ' --pretty=format:' . escapeshellarg($fmt)
    . ' --raw --numstat';

$raw = run($cmd);

$commits = [];
$current = null;
$statusByPath = [];
$numstatByPath = [];

$flush = function () use (&$current, &$statusByPath, &$numstatByPath, &$commits) {
    if ($current === null) {
        return;
    }
    $files = [];
    foreach ($numstatByPath as $path => $ns) {
        $files[] = [
            'path'   => $path,
            'status' => $statusByPath[$path] ?? $ns['status'],
            'add'    => $ns['add'],
            'del'    => $ns['del'],
        ];
    }
    foreach ($statusByPath as $path => $st) {
        if (!isset($numstatByPath[$path])) {
            $files[] = ['path' => $path, 'status' => $st, 'add' => null, 'del' => null];
        }
    }
    usort($files, fn($a, $b) => strcmp($a['path'], $b['path']));
    $current['files'] = $files;
    $commits[] = $current;
    $current = null;
    $statusByPath = [];
    $numstatByPath = [];
};

foreach (explode("\n", $raw) as $line) {
    if ($line === '') {
        continue;
    }
    if (str_starts_with($line, '@@@')) {
        $flush();
        $p = explode("\x1f", substr($line, 3));
        [$hash, $short, $dt, $author, $subject] = array_pad($p, 5, '');
        $parents = trim($p[5] ?? '');
        [$date, $time] = array_pad(explode('__', $dt, 2), 2, '');
        $current = [
            'hash'    => $hash,
            'short'   => $short,
            'date'    => $date,
            'time'    => $time,
            'author'  => $author,
            'subject' => $subject,
            'merge'   => count(preg_split('/\s+/', $parents, -1, PREG_SPLIT_NO_EMPTY)) > 1,
            'files'   => [],
        ];
        continue;
    }
    if ($current === null) {
        continue;
    }
    if ($line[0] === ':') {
        $parts = explode("\t", $line);
        if (count($parts) >= 2) {
            $meta = $parts[0];
            $status = 'M';
            if (preg_match('/\s([A-Z])[0-9]*$/', $meta, $m)) {
                $status = $m[1];
            }
            $path = $parts[1];
            if (isset($parts[2]) && $parts[2] !== '') {
                // Rename: numstat carries the compact "old => new" path; skip here.
                continue;
            }
            $statusByPath[$path] = $status;
        }
        continue;
    }
    if (preg_match('/^(\d+|-)\t(\d+|-)\t(.+)$/', $line, $m)) {
        $add = $m[1] === '-' ? null : (int) $m[1];
        $del = $m[2] === '-' ? null : (int) $m[2];
        $path = $m[3];
        $status = 'M';
        if (preg_match('/^(.*)\{([^{}]*) => ([^{}]*)\}(.*)$/', $path, $rm)) {
            $path = $rm[1] . $rm[3] . $rm[4];
            $status = 'R';
        } elseif (str_contains($path, ' => ')) {
            [$old, $new] = explode(' => ', $path, 2);
            $path = $new;
            $status = 'R';
        } elseif ($add !== null && $del !== null) {
            if ($add > 0 && $del === 0) {
                $status = 'A';
            } elseif ($add === 0 && $del > 0) {
                $status = 'D';
            }
        }
        $numstatByPath[$path] = ['add' => $add, 'del' => $del, 'status' => $status];
    }
}
$flush();

/* ------------------------------------------------------- Commit bodies --- */

$bodies = [];
$bodyRaw = run(
    'git -C ' . escapeshellarg($REPO)
    . ' log HEAD --pretty=format:' . escapeshellarg('%H%x1f%b%x1e')
);
foreach (explode("\x1e", $bodyRaw) as $record) {
    $record = ltrim($record, "\n");
    if ($record === '') {
        continue;
    }
    $parts = explode("\x1f", $record, 2);
    $hash = trim($parts[0]);
    $body = trim($parts[1] ?? '');
    if ($hash !== '') {
        $bodies[$hash] = strlen($body) > 4000 ? substr($body, 0, 4000) . '…' : $body;
    }
}
foreach ($commits as &$c) {
    $c['body'] = $bodies[$c['hash']] ?? '';
}
unset($c);

/* ------------------------------------------------------------ Journals --- */

function parseJournalBlock(string $body, string $date, string $source): array
{
    $fields = [];
    $files = [];
    $lines = preg_split('/\R/', $body);

    $developer = '';
    $module = '';

    foreach ($lines as $line) {
        $line = rtrim($line);
        if ($line === '') {
            continue;
        }

        if (preg_match('/^-\s+\*\*Developer folder:\*\*\s*([^·]+?)(?:\s*·\s*\*\*Module:\*\*\s*(.+))?$/u', $line, $m)) {
            $developer = clean($m[1]);
            if (!empty($m[2])) {
                $module = clean($m[2]);
            }
            continue;
        }

        if (preg_match('/^-\s+\*\*(.+?):\*\*\s*(.*)$/u', $line, $m)) {
            $fields[strtolower(trim($m[1]))] = trim($m[2]);
            continue;
        }

        if (str_starts_with(trim($line), '|')) {
            $cells = array_map('trim', explode('|', trim($line)));
            if (count($cells) < 2) {
                continue;
            }
            if ($cells[0] === '') {
                array_shift($cells);
            }
            if ($cells[count($cells) - 1] === '') {
                array_pop($cells);
            }
            if (count($cells) < 4) {
                continue;
            }
            if (preg_match('/^:?-{2,}/', $cells[0]) || stripos($cells[0], 'file') === 0) {
                continue;
            }
            $files[] = [
                'path'   => clean($cells[0]),
                'status' => clean($cells[1]),
                'what'   => clean($cells[2]),
                'why'    => clean($cells[3]),
            ];
        }
    }

    if (!empty($fields['module'])) {
        $module = clean($fields['module']);
    }
    if (!empty($fields['developer folder'])) {
        $developer = clean($fields['developer folder']);
    }

    return [
        'date'      => $date,
        'time'      => '',
        'title'     => '',
        'agent'     => '',
        'developer' => $developer,
        'module'    => $module,
        'request'   => clean($fields['request'] ?? ''),
        'files'     => $files,
        'commands'  => clean($fields['commands / verification'] ?? ($fields['commands'] ?? '')),
        'commit'    => clean($fields['commit'] ?? ''),
        'notes'     => clean($fields['notes / risks'] ?? ''),
        'next'      => clean($fields['next step'] ?? ''),
        'source'    => $source,
    ];
}

$tasks = [];
$liveFiles = glob($BRAIN . '/live/*/*.md') ?: [];
sort($liveFiles);
foreach ($liveFiles as $file) {
    $date = basename(dirname($file));
    $agent = pathinfo($file, PATHINFO_FILENAME);
    $content = file_get_contents($file) ?: '';
    if (preg_match('/^#\s+Agent:\s*(.+)$/m', $content, $am)) {
        $agent = trim($am[1]);
    }
    $chunks = preg_split('/^##\s+(.+)$/m', $content, -1, PREG_SPLIT_DELIM_CAPTURE);
    for ($i = 1; $i < count($chunks); $i += 2) {
        $heading = trim($chunks[$i]);
        $body = $chunks[$i + 1] ?? '';
        if (!preg_match('/^(\d{1,2}:\d{2})\s*[—–-]\s*(.+)$/u', $heading, $hm)) {
            continue;
        }
        $task = parseJournalBlock($body, $date, 'live/' . $date . '/' . basename($file));
        $task['time'] = $hm[1];
        $task['title'] = clean($hm[2]);
        $task['agent'] = $agent;
        $tasks[] = $task;
    }
}
usort($tasks, fn($a, $b) => [$a['date'], $a['time']] <=> [$b['date'], $b['time']]);

/* ------------------------------------------------------------- Reports --- */

$reports = [];
foreach (glob($BRAIN . '/daily/*.md') ?: [] as $file) {
    $date = pathinfo($file, PATHINFO_FILENAME);
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
        continue;
    }
    $content = file_get_contents($file) ?: '';
    $title = $date;
    if (preg_match('/^#\s+(.+)$/m', $content, $m)) {
        $title = trim($m[1]);
    }
    $reports[] = [
        'date'       => $date,
        'title'      => $title,
        'file'       => 'daily/' . basename($file),
        'backfilled' => stripos($content, 'backfilled') !== false,
    ];
}
usort($reports, fn($a, $b) => strcmp($a['date'], $b['date']));

$modules = [];
foreach (glob($BRAIN . '/modules/*.md') ?: [] as $file) {
    $name = pathinfo($file, PATHINFO_FILENAME);
    if ($name === '00-INDEX') {
        continue;
    }
    $modules[] = ['name' => $name, 'file' => 'modules/' . basename($file)];
}
usort($modules, fn($a, $b) => strcmp($a['name'], $b['name']));

$team = null;
$teamFile = $BRAIN . '/data/team.json';
if (is_file($teamFile)) {
    $team = json_decode(file_get_contents($teamFile) ?: '', true);
}
if (!is_array($team)) {
    $team = ['person' => '', 'sources' => [], 'attendance' => [], 'work' => [], 'gurukul' => []];
}

/* --------------------------------------------------------- Aggregates --- */

function moduleOfPath(string $p): string
{
    if (str_starts_with($p, 'Modules/')) {
        $a = explode('/', $p);
        return $a[1] ?? 'Modules';
    }
    if (str_starts_with($p, 'final-audit-reports/')) {
        $a = explode('/', $p);
        return $a[2] ?? 'Audit reports';
    }
    $map = [
        'database/' => 'Database', 'app/' => 'App', 'config/' => 'Config',
        'routes/' => 'Routes', 'resources/' => 'Resources', 'bootstrap/' => 'Bootstrap',
        'public/' => 'Public', 'tests/' => 'Tests', 'storage/' => 'Storage',
    ];
    foreach ($map as $prefix => $name) {
        if (str_starts_with($p, $prefix)) return $name;
    }
    return explode('/', $p)[0] ?: 'Other';
}

$daily = [];
$monthly = [];
$authors = [];
$moduleFiles = [];
$moduleCommits = [];
$totals = ['commits' => 0, 'files' => 0, 'add' => 0, 'del' => 0];

foreach ($commits as $c) {
    $date = $c['date'];
    $month = substr($date, 0, 7);
    $add = 0;
    $del = 0;
    foreach ($c['files'] as $f) {
        $add += $f['add'] ?? 0;
        $del += $f['del'] ?? 0;
    }
    $fc = count($c['files']);

    foreach ([[&$daily, $date], [&$monthly, $month]] as &$ref) {
        $bucket = &$ref[0];
        $key = $ref[1];
        if (!isset($bucket[$key])) {
            $bucket[$key] = ['date' => $key, 'commits' => 0, 'files' => 0, 'add' => 0, 'del' => 0];
        }
        $bucket[$key]['commits']++;
        $bucket[$key]['files'] += $fc;
        $bucket[$key]['add'] += $add;
        $bucket[$key]['del'] += $del;
        unset($bucket);
    }
    unset($ref);

    $author = $c['author'];
    if (!isset($authors[$author])) {
        $authors[$author] = ['name' => $author, 'commits' => 0, 'files' => 0, 'add' => 0, 'del' => 0];
    }
    $authors[$author]['commits']++;
    $authors[$author]['files'] += $fc;
    $authors[$author]['add'] += $add;
    $authors[$author]['del'] += $del;

    $mods = [];
    foreach ($c['files'] as $f) {
        $mod = moduleOfPath($f['path']);
        $mods[$mod] = 1;
        $moduleFiles[$mod] = ($moduleFiles[$mod] ?? 0) + 1;
    }
    foreach (array_keys($mods) as $mod) {
        $moduleCommits[$mod] = ($moduleCommits[$mod] ?? 0) + 1;
    }

    $totals['commits']++;
    $totals['files'] += $fc;
    $totals['add'] += $add;
    $totals['del'] += $del;
}

ksort($daily);
ksort($monthly);
$authors = array_values($authors);
usort($authors, fn($a, $b) => $b['commits'] <=> $a['commits']);
$modRows = [];
foreach ($moduleFiles as $name => $files) {
    $modRows[] = ['name' => $name, 'files' => $files, 'commits' => $moduleCommits[$name] ?? 0];
}
usort($modRows, fn($a, $b) => $b['files'] <=> $a['files']);

/* Compact per-commit rows for client-side chart filtering. */

$authorNames = array_map(fn($a) => $a['name'], $authors);
$moduleNames = array_map(fn($m) => $m['name'], $modRows);
$authorIdx = array_flip($authorNames);
$moduleIdx = array_flip($moduleNames);
$repoRows = [];
foreach ($commits as $c) {
    $add = 0;
    $del = 0;
    $mods = [];
    foreach ($c['files'] as $f) {
        $add += $f['add'] ?? 0;
        $del += $f['del'] ?? 0;
        $mi = $moduleIdx[moduleOfPath($f['path'])] ?? null;
        if ($mi !== null && !in_array($mi, $mods, true)) {
            $mods[] = $mi;
        }
    }
    $repoRows[] = [
        $c['date'],
        $authorIdx[$c['author']] ?? 0,
        $mods,
        $add,
        $del,
        count($c['files']),
        (int) substr($c['time'], 0, 2),
    ];
}

$taskByAgent = [];
$taskByModule = [];
$taskByMonth = [];
$taskDaily = [];
foreach ($tasks as $t) {
    $taskByAgent[$t['agent']] = ($taskByAgent[$t['agent']] ?? 0) + 1;
    $mod = $t['module'] ?: 'Unspecified';
    $taskByModule[$mod] = ($taskByModule[$mod] ?? 0) + 1;
    $month = substr($t['date'], 0, 7);
    $taskByMonth[$month] = ($taskByMonth[$month] ?? 0) + 1;
    $taskDaily[$t['date']] = ($taskDaily[$t['date']] ?? 0) + 1;
}
arsort($taskByAgent);
arsort($taskByModule);
ksort($taskByMonth);
ksort($taskDaily);

/* --------------------------------------------------------------- Build --- */

$branch = trim(run('git -C ' . escapeshellarg($REPO) . ' branch --show-current'));

$data = [
    'generated_at' => date('Y-m-d H:i:s'),
    'repo'         => $REPO,
    'branch'       => $branch,
    'commits'      => $commits,
    'tasks'        => $tasks,
    'reports'      => $reports,
    'modules'      => $modules,
    'team'         => $team,
];

$data = utf8Clean($data);
$json = json_encode($data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
if ($json === false) {
    fwrite(STDERR, "ERROR: json_encode failed: " . json_last_error_msg() . "\n");
    exit(1);
}

$out = $BRAIN . '/data.js';
file_put_contents($out, 'window.BRAIN_DATA = ' . $json . ";\n");

$charts = [
    'generated_at' => $data['generated_at'],
    'branch'       => $branch,
    'git'          => [
        'totals'  => $totals,
        'daily'   => array_values($daily),
        'monthly' => array_values($monthly),
        'authors' => $authors,
        'modules' => array_slice($modRows, 0, 25),
    ],
    'repo'         => [
        'authors' => $authorNames,
        'modules' => $moduleNames,
        'rows'    => $repoRows,
    ],
    'tasks'        => [
        'total'     => count($tasks),
        'by_agent'  => $taskByAgent,
        'by_module' => $taskByModule,
        'by_month'  => $taskByMonth,
        'daily'     => $taskDaily,
    ],
    'team'         => $team,
];

$charts = utf8Clean($charts);
$chartsJson = json_encode($charts, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
if ($chartsJson === false) {
    fwrite(STDERR, "ERROR: charts json_encode failed: " . json_last_error_msg() . "\n");
    exit(1);
}
$chartsOut = $BRAIN . '/charts-data.js';
file_put_contents($chartsOut, 'window.CHARTS_DATA = ' . $chartsJson . ";\n");

$files = array_sum(array_map(fn($c) => count($c['files']), $commits));
printf(
    "data.js written: %d commits, %d task entries, %d reports, %d file rows (%.1f MB) on %s\n",
    count($commits),
    count($tasks),
    count($reports),
    $files,
    filesize($out) / 1048576,
    $branch
);
printf(
    "charts-data.js written: %d daily buckets, %d authors, %d modules, %d chart rows, team work=%d gurukul=%d (%.0f KB)\n",
    count($daily),
    count($authors),
    count($modRows),
    count($repoRows),
    count($team['work'] ?? []),
    count($team['gurukul'] ?? []),
    filesize($chartsOut) / 1024
);
