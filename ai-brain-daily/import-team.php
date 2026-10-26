<?php
/**
 * Imports Shailesh's PDF records into data/team.json.
 *
 * Sources (copied to data/pdf/):
 *   - Team Attendence Record.pdf        -> October 2026 attendance (Shailesh rows only)
 *   - Team Attendence Record (1).pdf    -> October 2026 work tracker (Shailesh rows only)
 *   - Team Attendence Record (2).pdf    -> September 2026 work tracker (Shailesh rows only)
 *   - gurukul prime sheet - Sheet1.pdf  -> personal task log (all rows = Shailesh)
 *
 * Parsing uses pdftotext word coordinates (-bbox-layout), so wrapped cells and
 * tables map to their real columns instead of guessed text positions.
 *
 * Usage: php import-team.php
 */

declare(strict_types=1);

date_default_timezone_set('Asia/Kolkata');

$BRAIN   = __DIR__;
$PDF_DIR = $BRAIN . '/data/pdf';
$PERSON  = 'Shailesh';

if (!is_dir($PDF_DIR)) {
    fwrite(STDERR, "ERROR: missing {$PDF_DIR}\n");
    exit(1);
}

function sh(string $cmd): string
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
    $s = html_entity_decode($s, ENT_QUOTES | ENT_HTML5, 'UTF-8');
    $s = str_replace(["\xC2\xA0", '**', '`'], [' ', '', ''], $s);
    $s = preg_replace('/\s+/', ' ', $s) ?? '';
    return trim($s, " \t\n\r\0\x0B-–—|,;");
}

function maxLen(string $s, int $n = 4000): string
{
    return strlen($s) > $n ? substr($s, 0, $n) . '…' : $s;
}

function normalizeStatus(string $s): string
{
    $l = strtolower(trim($s));
    if ($l === '') return '';
    if (str_contains($l, 'complete') || preg_match('/\bdone\b/', $l)) return 'Done';
    if (str_contains($l, 'progress') || str_contains($l, 'inprogress')) return 'In Progress';
    if (str_contains($l, 'block')) return 'Blocked';
    if (str_contains($l, 'pending') || str_contains($l, 'wait')) return 'Pending';
    return 'Logged';
}

function isStatusWord(string $s): bool
{
    return (bool) preg_match('/^(completed|complete|done|in-?progress|progress|pending|blocked|logged)$/i', $s);
}

function isoDate(string $d): ?string
{
    $d = trim($d);
    foreach (['d-M-Y', 'd-M-y', 'd/m/Y', 'd-m-Y'] as $fmt) {
        $dt = DateTime::createFromFormat('!' . $fmt, $d);
        if ($dt instanceof DateTime) {
            return $dt->format('Y-m-d');
        }
    }
    return null;
}

function pdfPages(string $file): int
{
    $info = sh('pdfinfo ' . escapeshellarg($file));
    if (preg_match('/^Pages:\s+(\d+)/m', $info, $m)) {
        return (int) $m[1];
    }
    return 0;
}

/**
 * Returns page -> visual lines. Each line is a list of [x, y, text].
 */
function pdfLines(string $file): array
{
    $xml = sh('pdftotext -bbox-layout ' . escapeshellarg($file) . ' -');
    $pages = [];
    foreach (explode('<page ', $xml) as $pi => $chunk) {
        if ($pi === 0) continue;
        preg_match_all('/<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="[\d.]+" yMax="[\d.]+">(.*?)<\/word>/s', $chunk, $mm, PREG_SET_ORDER);
        $words = [];
        foreach ($mm as $w) {
            $text = html_entity_decode($w[3], ENT_QUOTES | ENT_HTML5, 'UTF-8');
            if (trim($text) === '') continue;
            $words[] = ['x' => (float) $w[1], 'y' => (float) $w[2], 't' => $text];
        }
        usort($words, fn($a, $b) => [$a['y'], $a['x']] <=> [$b['y'], $b['x']]);

        $lines = [];
        $cur = null;
        foreach ($words as $w) {
            if ($cur === null || abs($w['y'] - $cur['y']) > 3.0) {
                if ($cur !== null) $lines[] = $cur;
                $cur = ['y' => $w['y'], 'words' => [$w]];
            } else {
                $cur['words'][] = $w;
            }
        }
        if ($cur !== null) $lines[] = $cur;
        foreach ($lines as &$ln) {
            usort($ln['words'], fn($a, $b) => $a['x'] <=> $b['x']);
            $ln['text'] = implode(' ', array_column($ln['words'], 't'));
        }
        unset($ln);
        $pages[] = $lines;
    }
    return $pages;
}

function lineWordsIn(array $line, float $min, float $max): array
{
    $out = [];
    foreach ($line['words'] as $w) {
        if ($w['x'] >= $min && $w['x'] < $max) $out[] = $w['t'];
    }
    return $out;
}

/* ---------------------------------------------------------- attendance --- */

function parseAttendance(string $text, string $person): array
{
    $rows = [];
    $statuses = ['Present', 'Holiday', 'Absent', 'Leave', 'Half Day', 'Work From Home'];

    foreach (preg_split('/\R/', $text) as $line) {
        if (!preg_match('/^(\d{2}-[A-Za-z]{3}-\d{4})\s+([A-Za-z]+)\s*(.*)$/', rtrim($line), $m)) {
            continue;
        }
        if (strcasecmp($m[2], $person) !== 0) {
            continue;
        }
        $rest = $m[3];
        $date = isoDate($m[1]);
        if ($date === null) {
            continue;
        }

        $status = '';
        foreach ($statuses as $st) {
            if (preg_match('/\b' . preg_quote($st, '/') . '\b/i', $rest)) {
                $status = $st;
                break;
            }
        }

        preg_match_all('/\b\d{1,2}:\d{2}\s*(?:AM|PM)\b/i', $rest, $tm);
        $times = $tm[0] ?? [];

        $hours = null;
        if (preg_match('/\b(\d{1,2})h\s*(\d{1,2})m\b/i', $rest, $hm)) {
            $hours = (int) $hm[1] + ((int) $hm[2]) / 60;
        }

        $remark = $rest;
        foreach ($statuses as $st) {
            $remark = preg_replace('/\b' . preg_quote($st, '/') . '\b/i', ' ', $remark) ?? $remark;
        }
        $remark = preg_replace('/\b\d{1,2}:\d{2}\s*(?:AM|PM)\b/i', ' ', $remark) ?? $remark;
        $remark = preg_replace('/\b\d{1,2}h\s*\d{1,2}m\b/i', ' ', $remark) ?? $remark;

        $rows[] = [
            'date'    => $date,
            'status'  => $status,
            'in'      => $times[0] ?? null,
            'out'     => $times[1] ?? null,
            'hours'   => $hours === null ? null : round($hours, 2),
            'remark'  => maxLen(clean($remark), 200),
            'anomaly' => $hours !== null && ($hours > 16 || $hours < 1),
        ];
    }
    usort($rows, fn($a, $b) => strcmp($a['date'], $b['date']));
    return $rows;
}

/* --------------------------------------------------------- work tracker --- */

function parseWorkTracker(array $pages, string $person, string $source): array
{
    $lines = [];
    foreach ($pages as $pageLines) {
        foreach ($pageLines as $ln) $lines[] = $ln;
    }

    $taskMin = 150.0;
    $statusX = null;
    $nameX = null;

    foreach ($lines as $ln) {
        $w = $ln['words'];
        if (count($w) < 2) continue;
        if (preg_match('/^\d{1,2}-[A-Za-z]{3}-\d{2,4}$/', $w[0]['t']) && $w[0]['x'] < 80) {
            $nameX = $nameX ?? $w[1]['x'];
            if (isset($w[2]) && $w[2]['x'] > $w[1]['x'] + 30) {
                $taskMin = min($taskMin, $w[2]['x'] - 10);
            }
        }
        foreach ($w as $word) {
            if ($word['x'] > 300 && $word['x'] < 700 && isStatusWord($word['t'])) {
                $statusX = $statusX === null ? $word['x'] : (($statusX + $word['x']) / 2);
            }
        }
    }

    if ($statusX === null) $statusX = 510.0;
    if ($nameX === null) $nameX = 92.0;
    $taskMax = $statusX - 12;

    $rows = [];
    $current = null;
    $flush = function () use (&$current, &$rows) {
        if ($current !== null) {
            $current['description'] = clean($current['description']);
            $current['status'] = normalizeStatus($current['status'] . ' ' . $current['description']);
            $current['time_spent'] = clean($current['time_spent']);
            $current['commits'] = array_values(array_unique($current['commits']));
            if ($current['description'] !== '') $rows[] = $current;
        }
        $current = null;
    };

    foreach ($lines as $ln) {
        $text = $ln['text'];
        if (str_contains($text, 'Monthly Team Work Tracker') || str_contains($text, 'Check-in creates') || str_contains($text, 'Team Member Name')) {
            continue;
        }

        $w = $ln['words'];
        $isRow = count($w) > 1 && $w[0]['x'] < 80 && preg_match('/^\d{1,2}-[A-Za-z]{3}-\d{2,4}$/', $w[0]['t']);

        if ($isRow) {
            $flush();
            $name = clean(implode(' ', lineWordsIn($ln, $nameX - 12, $taskMin - 12)));
            if (strcasecmp($name, $person) !== 0) {
                continue;
            }
            $date = isoDate($w[0]['t']);
            if ($date === null) {
                continue;
            }
            $description = implode(' ', lineWordsIn($ln, $taskMin - 10, $taskMax));
            $status = implode(' ', lineWordsIn($ln, $statusX - 25, $statusX + 60));
            $time = implode(' ', lineWordsIn($ln, $statusX + 60, 745));

            $hashes = [];
            foreach ($w as $word) {
                if (preg_match('/^[0-9a-f]{7,40}$/', $word['t'])) $hashes[] = $word['t'];
            }

            $current = [
                'date'        => $date,
                'month'       => substr($date, 0, 7),
                'person'      => $person,
                'description' => $description,
                'status'      => $status,
                'time_spent'  => $time,
                'remark'      => clean(implode(' ', lineWordsIn($ln, 745, 2000))),
                'commits'     => $hashes,
                'source'      => $source,
            ];
            continue;
        }

        if ($current === null) continue;

        $cont = implode(' ', lineWordsIn($ln, $taskMin - 10, $taskMax));
        if ($cont !== '' && !preg_match('/^\d+$/', $cont)) {
            $current['description'] .= ' ' . $cont;
            if ($current['status'] === '') {
                $current['status'] = implode(' ', lineWordsIn($ln, $statusX - 25, $statusX + 60));
            }
        }
        foreach ($w as $word) {
            if (preg_match('/^[0-9a-f]{7,40}$/', $word['t'])) {
                $current['commits'][] = $word['t'];
            }
        }
        $moreTime = implode(' ', lineWordsIn($ln, $statusX + 60, 745));
        if ($moreTime !== '' && !preg_match('/^[0-9a-f]{7,40}$/', trim($moreTime))) {
            $current['time_spent'] .= ' ' . $moreTime;
        }
    }
    $flush();
    return $rows;
}

/* -------------------------------------------------------------- gurukul --- */

function parseGurukul(array $pages): array
{
    $lines = [];
    foreach ($pages as $pageLines) {
        foreach ($pageLines as $ln) $lines[] = $ln;
    }

    $rows = [];
    $current = null;
    $seen = [];

    $flush = function () use (&$current, &$rows, &$seen) {
        if ($current !== null) {
            $current['category'] = clean($current['category']);
            $current['description'] = clean($current['description']);
            $current['status'] = normalizeStatus($current['status'] . ' ' . $current['description']);
            $blob = strtolower($current['category'] . ' ' . $current['description']);
            $noise = $current['description'] === ''
                || preg_match('/^(lunch|meeting)\b/', strtolower($current['description']))
                || preg_match('/^(lunch|meeting)\b/', strtolower($current['category']))
                || $blob === ''
                || (preg_match('/^[\d:.\s-]+$/', $current['description']) && $current['category'] === '');
            $key = $current['date'] . '|' . strtolower($current['category']) . '|' . substr(strtolower($current['description']), 0, 70);
            if (!$noise && !isset($seen[$key])) {
                $seen[$key] = 1;
                $rows[] = $current;
            }
        }
        $current = null;
    };

    foreach ($lines as $ln) {
        $text = $ln['text'];
        if ($text === '' || str_contains($text, 'Task Category') || str_contains($text, 'Detailed Description') || str_contains($text, 'Week Month')) {
            continue;
        }

        $w = $ln['words'];
        $isRow = count($w) > 0 && $w[0]['x'] < 75 && preg_match('/^\d{2}\/\d{2}\/\d{4}$/', $w[0]['t']);
        if ($isRow) {
            $flush();
            $date = isoDate($w[0]['t']);
            if ($date === null) continue;

            $durationWords = lineWordsIn($ln, 390, 421);
            $duration = '';
            foreach ($durationWords as $dw) {
                if (preg_match('/^\d{1,2}:\d{2}$/', $dw) || preg_match('/^\d+(\.\d+)?$/', $dw)) {
                    $duration = $dw;
                    break;
                }
            }

            $current = [
                'date'         => $date,
                'month'        => substr($date, 0, 7),
                'category'     => implode(' ', lineWordsIn($ln, 96, 168)),
                'description'  => implode(' ', lineWordsIn($ln, 168, 305)),
                'output'       => implode(' ', lineWordsIn($ln, 420, 512)),
                'status'       => implode(' ', lineWordsIn($ln, 512, 590)),
                'duration_raw' => $duration,
                'notes'        => implode(' ', lineWordsIn($ln, 702, 742)),
                'week'         => implode(' ', lineWordsIn($ln, 742, 766)),
                'month_label'  => implode(' ', lineWordsIn($ln, 766, 900)),
                'source'       => 'gurukul',
            ];
            continue;
        }

        if ($current === null) continue;

        $desc = implode(' ', lineWordsIn($ln, 168, 305));
        if ($desc !== '' && !preg_match('/^[\d:.\s-]+$/', $desc)) {
            $current['description'] .= ' ' . $desc;
        }
        if ($current['category'] === '') {
            $cat = implode(' ', lineWordsIn($ln, 96, 168));
            if ($cat !== '' && !preg_match('/^\d+$/', $cat)) $current['category'] = $cat;
        }
        if ($current['status'] === '') {
            $st = implode(' ', lineWordsIn($ln, 512, 590));
            if (isStatusWord(trim($st))) $current['status'] = $st;
        }
    }
    $flush();

    usort($rows, fn($a, $b) => strcmp($a['date'], $b['date']));
    return $rows;
}

/* ----------------------------------------------------------------- main --- */

$files = [
    'attendance' => 'Team Attendence Record.pdf',
    'work_oct'   => 'Team Attendence Record (1).pdf',
    'work_sep'   => 'Team Attendence Record (2).pdf',
    'gurukul'    => 'gurukul prime sheet - Sheet1.pdf',
];

$sources = [];
foreach ($files as $key => $name) {
    $path = $PDF_DIR . '/' . $name;
    if (!is_file($path)) {
        fwrite(STDERR, "ERROR: missing {$path}\n");
        exit(1);
    }
    $sources[$key] = [
        'file'  => 'data/pdf/' . $name,
        'title' => $name,
        'type'  => $key,
        'pages' => pdfPages($path),
    ];
}

$attendance = parseAttendance(sh('pdftotext -layout ' . escapeshellarg($PDF_DIR . '/' . $files['attendance']) . ' -'), $PERSON);
$work = array_merge(
    parseWorkTracker(pdfLines($PDF_DIR . '/' . $files['work_sep']), $PERSON, 'work_sep'),
    parseWorkTracker(pdfLines($PDF_DIR . '/' . $files['work_oct']), $PERSON, 'work_oct')
);
usort($work, fn($a, $b) => [$a['date'], $a['description']] <=> [$b['date'], $b['description']]);
$gurukul = parseGurukul(pdfLines($PDF_DIR . '/' . $files['gurukul']));

$sources['attendance']['records'] = count($attendance);
$sources['work_oct']['records']   = count(array_filter($work, fn($w) => $w['source'] === 'work_oct'));
$sources['work_sep']['records']   = count(array_filter($work, fn($w) => $w['source'] === 'work_sep'));
$sources['gurukul']['records']    = count($gurukul);

$data = [
    'generated_at' => date('Y-m-d H:i:s'),
    'person'       => $PERSON,
    'note'         => 'Only Shailesh rows are imported from the team PDFs.',
    'sources'      => $sources,
    'attendance'   => $attendance,
    'work'         => $work,
    'gurukul'      => $gurukul,
];

if (!is_dir($BRAIN . '/data')) {
    mkdir($BRAIN . '/data', 0755, true);
}
$json = json_encode($data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
file_put_contents($BRAIN . '/data/team.json', $json . "\n");

printf(
    "team.json written: attendance=%d, work=%d (sep=%d, oct=%d), gurukul=%d\n",
    count($attendance),
    count($work),
    $sources['work_sep']['records'],
    $sources['work_oct']['records'],
    count($gurukul)
);
