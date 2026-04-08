<?php
/**
 * Prime-AI Menu Extractor v2
 * Improved tab extraction — handles both span-wrapped and inline-text tab labels.
 */

$modulesDir = '/Users/bkwork/Herd/prime_ai/Modules';
$outputJson = '/tmp/prime_menu_raw.json';

$modules = array_filter(glob($modulesDir . '/*'), 'is_dir');
sort($modules);

$results = [];

foreach ($modules as $modulePath) {
    $moduleName = basename($modulePath);
    $viewsDir   = $modulePath . '/resources/views';

    if (!is_dir($viewsDir)) {
        echo "  [SKIP] $moduleName — no views dir\n";
        continue;
    }

    $routeLookup = buildRouteLookup($modulePath . '/routes/web.php');

    $iterator = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($viewsDir, FilesystemIterator::SKIP_DOTS)
    );

    $count = 0;
    foreach ($iterator as $file) {
        if ($file->getExtension() !== 'php') continue;
        if (!str_ends_with($file->getFilename(), '.blade.php')) continue;

        $content  = file_get_contents($file->getPathname());
        $relPath  = ltrim(str_replace($viewsDir, '', $file->getPathname()), '/');

        if (!isMainScreen($content)) continue;

        // Skip obvious non-screen files
        if (preg_match('#/(pdf|print|email|mail|components|partials|_partials|shared|layouts|layout)/#i', $relPath)) continue;
        if (str_starts_with(basename($relPath, '.blade.php'), '_')) continue;

        $title    = extractTitle($content, $relPath);
        $tabs     = extractTabs($content);
        $route    = extractRouteName($content, $routeLookup, $moduleName, $relPath);
        $viewFile = 'Modules/' . $moduleName . '/resources/views/' . $relPath;

        $results[] = [
            'module'    => $moduleName,
            'title'     => $title,
            'tabs'      => $tabs,
            'route'     => $route,
            'view_file' => $viewFile,
        ];
        $count++;
    }
    echo "  [$moduleName] → $count screens\n";
}

file_put_contents($outputJson, json_encode($results, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
echo "\nTotal screens: " . count($results);
$tabRows = array_sum(array_map(fn($r) => max(1, count($r['tabs'])), $results));
echo " | Total CSV rows (incl. tabs): $tabRows\n";
echo "Written to: $outputJson\n";


// ─────────────────────────────────────────────────────────────────
function isMainScreen(string $content): bool
{
    return str_contains($content, 'x-backend.layouts.app')
        || str_contains($content, 'x-frontend.layout.app')
        || str_contains($content, "@extends('backend")
        || str_contains($content, "@extends('frontend");
}

function extractTitle(string $content, string $relPath): string
{
    // Pattern 1a — breadcrum title="..." same line
    if (preg_match('/breadcrum\s[^>]*title="([^"]+)"/', $content, $m)) return trim($m[1]);
    // Pattern 1b — breadcrum, title= on nearby line (multiline)
    if (preg_match('/breadcrum[\s\S]{0,120}?title="([^"]+)"/U', $content, $m)) return trim($m[1]);
    // Pattern 2 — <div class="page-title">...</div>
    if (preg_match('/<div[^>]*class="page-title"[^>]*>\s*([^<{]{3,80})\s*</m', $content, $m)) return trim($m[1]);
    // Pattern 3 — card.header title="..."
    if (preg_match('/card\.header\s[^>]*title="([^"]+)"/', $content, $m)) return trim($m[1]);
    // Pattern 4 — <h1>/<h2>
    if (preg_match('/<h[12][^>]*>\s*([^<{]{3,80})\s*<\/h[12]>/m', $content, $m)) {
        $t = trim(strip_tags($m[1]));
        if (strlen($t) >= 3) return $t;
    }
    // Fallback from path
    $parts  = explode('/', $relPath);
    $file   = str_replace(['.blade.php','-','_'], [' ',' ',' '], end($parts));
    $folder = count($parts) > 1 ? str_replace(['-','_'],' ',$parts[count($parts)-2]) : '';
    return ucwords(trim($folder . ' ' . $file)) ?: 'Unknown';
}

function extractTabs(string $content): array
{
    $tabs = [];

    // --- APPROACH 1: Span-wrapped labels (most common in this codebase) ---
    // <button ... data-bs-toggle="tab" ...><i...></i><span ...>Label</span></button>
    if (preg_match_all(
        '/data-bs-toggle="tab"[\s\S]{0,600}<span[^>]*>([\s\S]{0,80}?)<\/span>/U',
        $content, $m
    )) {
        foreach ($m[1] as $raw) {
            $label = cleanTabLabel($raw);
            if ($label !== '') $tabs[] = $label;
        }
    }

    // --- APPROACH 2: Inline text in button (no span) ---
    // <button ... data-bs-toggle="tab" ... data-bs-target="#xxx" ...>Label</button>
    if (empty($tabs)) {
        // Extract each nav-link button block then get text after last attribute >
        preg_match_all(
            '/<button[^>]*data-bs-toggle="tab"[^>]*>([\s\S]{0,200}?)<\/button>/U',
            $content, $m
        );
        foreach ($m[1] as $inner) {
            // Remove icon tags, get remaining text
            $text = preg_replace('/<i[^>]*><\/i>/', '', $inner);
            $text = preg_replace('/<[^>]+>/', '', $text); // strip all tags
            $label = cleanTabLabel($text);
            if ($label !== '') $tabs[] = $label;
        }
    }

    // --- APPROACH 3: Bootstrap 4 data-toggle="tab" ---
    if (empty($tabs)) {
        preg_match_all(
            '/<button[^>]*data-toggle="tab"[^>]*>([\s\S]{0,200}?)<\/button>/U',
            $content, $m
        );
        foreach ($m[1] as $inner) {
            $text  = preg_replace('/<i[^>]*><\/i>/', '', $inner);
            $text  = preg_replace('/<[^>]+>/', '', $text);
            $label = cleanTabLabel($text);
            if ($label !== '') $tabs[] = $label;
        }
    }

    // --- APPROACH 4: Anchor-style tabs  <a href="#tab-xxx">Label</a> ---
    if (empty($tabs) && preg_match_all(
        '/<a[^>]*href="#[^"]*"[^>]*class="nav-link[^"]*"[^>]*>([\s\S]{0,120}?)<\/a>/U',
        $content, $m
    )) {
        foreach ($m[1] as $inner) {
            $text  = preg_replace('/<[^>]+>/', '', $inner);
            $label = cleanTabLabel($text);
            if ($label !== '') $tabs[] = $label;
        }
    }

    return array_values(array_unique(array_filter($tabs)));
}

function cleanTabLabel(string $raw): string
{
    // Remove Blade expressions
    $label = preg_replace('/\{\{[^}]+\}\}/', '', $raw);
    $label = preg_replace('/\{!![^}]+!!\}/', '', $label);
    // Strip HTML tags
    $label = strip_tags($label);
    // Collapse whitespace
    $label = trim(preg_replace('/\s+/', ' ', $label));
    // Reject if too short, too long, or looks like code/path
    if (strlen($label) < 3 || strlen($label) > 60) return '';
    if (str_contains($label, '{') || str_contains($label, '}')) return '';
    if (str_contains($label, '$') || str_contains($label, '->')) return '';
    if (str_contains($label, '/') && strlen($label) < 10) return ''; // avoid path fragments
    return $label;
}

function buildRouteLookup(string $routeFile): array
{
    if (!file_exists($routeFile)) return [];
    $content = file_get_contents($routeFile);
    $map = [];
    if (preg_match_all("/Route::resource\(\s*'([^']+)'/", $content, $m))
        foreach ($m[1] as $r) $map[$r] = $r;
    if (preg_match_all("/->name\(\s*'([^']+)'\s*\)/", $content, $m)) {
        foreach ($m[1] as $name) {
            $parts = explode('.', $name);
            if (count($parts) >= 2)
                $map[end($parts)] = implode('.', array_slice($parts, 0, -1));
        }
    }
    return $map;
}

function extractRouteName(string $content, array $lookup, string $moduleName, string $relPath): string
{
    if (preg_match("/route\(\s*'([^']+\.index)'/", $content, $m)) return $m[1];
    if (preg_match("/route\(\s*'([a-z][^']+)'/", $content, $m)) {
        $c = $m[1];
        if (!preg_match('/login|logout|password|register|verify|sanctum/', $c)) {
            $parts = explode('.', $c);
            $last  = end($parts);
            if (in_array($last, ['show','edit','create','store','update','destroy'])) {
                return implode('.', array_slice($parts, 0, -1)) . '.index';
            }
            return $c;
        }
    }
    $pathParts = explode('/', $relPath);
    $fileName  = str_replace('.blade.php', '', end($pathParts));
    $folder    = count($pathParts) > 1 ? $pathParts[count($pathParts)-2] : '';
    $prefix    = moduleToPrefix($moduleName);
    if (!empty($folder) && $folder !== 'views' && $folder !== $moduleName) {
        if (isset($lookup[$folder])) return $lookup[$folder] . '.' . $fileName;
        return $prefix . '.' . $folder . '.' . $fileName;
    }
    return $prefix . '.' . $fileName;
}

function moduleToPrefix(string $n): string
{
    $map = [
        'Prime'=>'prime','GlobalMaster'=>'global-master','SystemConfig'=>'system-config',
        'Billing'=>'billing','Documentation'=>'documentation','SchoolSetup'=>'school-setup',
        'SmartTimetable'=>'smart-timetable','TimetableFoundation'=>'timetable-foundation',
        'Transport'=>'transport','Hpc'=>'hpc','Library'=>'library',
        'StudentProfile'=>'student','StudentFee'=>'student-fee','Syllabus'=>'syllabus',
        'QuestionBank'=>'question-bank','LmsExam'=>'exam','LmsQuiz'=>'quiz',
        'LmsHomework'=>'homework','LmsQuests'=>'quests','Notification'=>'notification',
        'Complaint'=>'complaint','Vendor'=>'vendor','Payment'=>'payment',
        'Recommendation'=>'recommendation','SyllabusBooks'=>'syllabus-books',
        'Accounting'=>'accounting','StandardTimetable'=>'standard-timetable',
        'StudentPortal'=>'student-portal','Dashboard'=>'dashboard',
        'Scheduler'=>'scheduler','EventEngine'=>'event-engine','Admission'=>'admission',
        'Cafeteria'=>'cafeteria','Certificate'=>'certificate','FrontOffice'=>'front-office',
        'HrStaff'=>'hr-staff','Inventory'=>'inventory',
    ];
    return $map[$n] ?? strtolower(preg_replace('/(?<!^)[A-Z]/', '-$0', $n));
}
