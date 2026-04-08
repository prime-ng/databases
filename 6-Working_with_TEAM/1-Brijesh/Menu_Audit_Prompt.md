# Prime-AI Menu Audit — Complete Generation Prompt

## Objective
Generate a complete Menu Audit CSV file (`Prime_AI_Menu_Audit.csv`) covering all 37 modules of
the Prime-AI application. This file maps every developed screen and its tabs to the application
menu hierarchy so gaps can be identified and menus aligned.

## Output Location
Save the **final enriched CSV** to:
```
/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Working_with_TEAM/1-Brijesh/Prime_AI_Menu_Audit.csv
```

---

## Required Columns (one row per Tab, N/A if no tabs)

| Column | Description |
|--------|-------------|
| S.No. | Serial number (auto-increment, 1-based) |
| Module Name | Module folder name from `Modules/` directory |
| Screen Title | Page title extracted from view breadcrumb or page-title div |
| Tab Name | Tab label from nav-link button text. Use `N/A` if no tabs exist |
| Category | Level-1 menu hierarchy from RBS (e.g., `SCHOOL SETUP`) |
| Main Menu | Level-2 menu hierarchy from RBS (e.g., `Core Config`) |
| Sub-Menu | Level-3 menu hierarchy from RBS (e.g., `Dept / Designation Mgmt.`). Use `N/A` if no sub-menu |
| Route Name | Laravel route name (extracted from view or inferred from path) |
| View File | Complete relative path starting from `Modules/` |
| Note | Issues: "Not in RBS", "Route unknown", "Partial/stub screen", etc. |

---

## Key Paths

```
Laravel Repo:   /Users/bkwork/Herd/prime_ai
Modules Dir:    /Users/bkwork/Herd/prime_ai/Modules
RBS File:       /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md
Output Dir:     /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Working_with_TEAM/1-Brijesh/
```

---

## All 37 Modules to Process

```
Central-Scoped (Prime App):
  Prime, GlobalMaster, SystemConfig, Billing, Documentation

Tenant-Scoped (School App):
  SchoolSetup, SmartTimetable, TimetableFoundation, Transport, Hpc,
  Library, StudentProfile, StudentFee, Syllabus, QuestionBank,
  LmsExam, LmsQuiz, LmsHomework, LmsQuests, Notification,
  Complaint, Vendor, Payment, Recommendation, SyllabusBooks,
  Accounting, StandardTimetable, StudentPortal, Dashboard,
  Scheduler, EventEngine, Admission, Cafeteria, Certificate,
  FrontOffice, HrStaff, Inventory
```

---

## Step 1 — Write and Execute the PHP Extractor Script

Create the file `/tmp/prime_menu_extractor.php` with the content below, then run:
```bash
php /tmp/prime_menu_extractor.php
```

This produces `/tmp/prime_menu_raw.json` — a structured list of all main screens and their tabs.

```php
<?php
/**
 * Prime-AI Menu Extractor
 * Scans all module blade views, extracts screen titles, tabs, view paths, and route names.
 * Output: /tmp/prime_menu_raw.json
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
        continue;
    }

    // Build route-name lookup from this module's web.php
    $routeLookup = buildRouteLookup($modulePath . '/routes/web.php');

    $iterator = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($viewsDir, FilesystemIterator::SKIP_DOTS)
    );

    foreach ($iterator as $file) {
        if ($file->getExtension() !== 'php') continue;
        if (!str_ends_with($file->getFilename(), '.blade.php')) continue;

        $content  = file_get_contents($file->getPathname());
        $relPath  = ltrim(str_replace($viewsDir, '', $file->getPathname()), '/');

        // Skip files that are partials / sub-includes (no layout declaration)
        if (!isMainScreen($content)) continue;

        $title    = extractTitle($content, $relPath);
        $tabs     = extractTabs($content);
        $route    = extractRouteName($content, $routeLookup, $moduleName, $relPath);
        $viewFile = 'Modules/' . $moduleName . '/resources/views/' . $relPath;

        $results[] = [
            'module'     => $moduleName,
            'title'      => $title,
            'tabs'       => $tabs,   // [] = no tabs, else array of tab label strings
            'route'      => $route,
            'view_file'  => $viewFile,
        ];
    }
}

file_put_contents($outputJson, json_encode($results, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
echo "Done. Wrote " . count($results) . " screens to $outputJson\n";

// ─────────────────────────────────────────────────────────────────
// Helper: isMainScreen — true if this blade file extends a layout
// ─────────────────────────────────────────────────────────────────
function isMainScreen(string $content): bool
{
    return str_contains($content, 'x-backend.layouts.app')
        || str_contains($content, 'x-frontend.layout.app')
        || str_contains($content, "@extends('backend")
        || str_contains($content, "@extends('frontend")
        || str_contains($content, 'x-backend.layouts')
        || str_contains($content, 'x-frontend.layouts');
}

// ─────────────────────────────────────────────────────────────────
// Helper: extractTitle — pulls the human-readable page/screen title
// ─────────────────────────────────────────────────────────────────
function extractTitle(string $content, string $relPath): string
{
    // Pattern 1 — <x-backend.components.breadcrum title="..." ...>
    if (preg_match('/breadcrum\s[^>]*title="([^"]+)"/', $content, $m)) {
        return trim($m[1]);
    }
    // Pattern 1b — breadcrum on multi-line (title= on next line)
    if (preg_match('/breadcrum[\s\S]{0,50}?\n\s*title="([^"]+)"/', $content, $m)) {
        return trim($m[1]);
    }
    // Pattern 2 — <div class="page-title">Title</div>  (StudentPortal / frontend)
    if (preg_match('/<div class="page-title">([^<]+)<\/div>/', $content, $m)) {
        return trim($m[1]);
    }
    // Pattern 3 — <x-backend.card.header title="..." ...>
    if (preg_match('/card\.header\s[^>]*title="([^"]+)"/', $content, $m)) {
        return trim($m[1]);
    }
    // Pattern 4 — <h1>, <h2>, <h3> tag
    if (preg_match('/<h[123][^>]*>([^<]+)<\/h[123]>/', $content, $m)) {
        $t = trim($m[1]);
        if (strlen($t) > 3 && strlen($t) < 80) return $t;
    }
    // Fallback — derive from file path  e.g. vehicle/index → Vehicle Index
    $parts = explode('/', $relPath);
    $file  = str_replace(['.blade.php', '-', '_'], [' ', ' ', ' '], end($parts));
    $folder = count($parts) > 1 ? str_replace(['-', '_'], ' ', $parts[count($parts)-2]) : '';
    return trim(ucwords($folder . ' ' . $file));
}

// ─────────────────────────────────────────────────────────────────
// Helper: extractTabs — returns array of tab label strings
//   Looks for Bootstrap tabs:  data-bs-toggle="tab" + <span>Label</span>
// ─────────────────────────────────────────────────────────────────
function extractTabs(string $content): array
{
    $tabs = [];

    // Approach 1 — <button ... data-bs-toggle="tab" ...> ... <span ...>Label</span>
    // Extract the nav-tabs / nav-pills UL block first to avoid false positives
    if (preg_match_all(
        '/data-bs-toggle="tab"[\s\S]{1,400}?<span[^>]*>([\s\S]{1,60}?)<\/span>/U',
        $content,
        $m
    )) {
        foreach ($m[1] as $raw) {
            $label = trim(strip_tags($raw));
            if ($label !== '' && strlen($label) <= 60) {
                $tabs[] = $label;
            }
        }
    }

    // Approach 2 — older Bootstrap 4 style: data-toggle="tab"
    if (empty($tabs) && preg_match_all(
        '/data-toggle="tab"[\s\S]{1,400}?<span[^>]*>([\s\S]{1,60}?)<\/span>/U',
        $content,
        $m
    )) {
        foreach ($m[1] as $raw) {
            $label = trim(strip_tags($raw));
            if ($label !== '' && strlen($label) <= 60) {
                $tabs[] = $label;
            }
        }
    }

    // Approach 3 — href="#tab-xxx" anchor style  (some older views)
    if (empty($tabs) && preg_match_all(
        '/href="#[^"]+"\s[^>]*>([^<]{2,50})<\/a>/',
        $content,
        $m
    )) {
        foreach ($m[1] as $raw) {
            $label = trim($raw);
            if ($label !== '') $tabs[] = $label;
        }
    }

    return array_values(array_unique($tabs));
}

// ─────────────────────────────────────────────────────────────────
// Helper: buildRouteLookup — reads web.php to build a map of
//   resource/view-folder → route-name-prefix
// ─────────────────────────────────────────────────────────────────
function buildRouteLookup(string $routeFile): array
{
    if (!file_exists($routeFile)) return [];

    $content = file_get_contents($routeFile);
    $map     = [];

    // Route::resource('vehicle', VehicleController::class) → vehicle
    if (preg_match_all("/Route::resource\(\s*'([^']+)'/", $content, $m)) {
        foreach ($m[1] as $resource) {
            $map[$resource] = $resource;
        }
    }

    // Route::get('/some-path', ...)->name('prefix.action')
    if (preg_match_all("/->name\('([^']+)'\)/", $content, $m)) {
        foreach ($m[1] as $name) {
            $parts = explode('.', $name);
            if (count($parts) >= 2) {
                // store e.g. 'vehicle' => 'transport.vehicle'
                $map[$parts[count($parts)-2]] = implode('.', array_slice($parts, 0, -1));
            }
        }
    }

    return $map;
}

// ─────────────────────────────────────────────────────────────────
// Helper: extractRouteName
// ─────────────────────────────────────────────────────────────────
function extractRouteName(string $content, array $lookup, string $moduleName, string $relPath): string
{
    // Try to find an explicit route() call pointing to .index
    if (preg_match("/route\(\s*'([^']+\.index)'/", $content, $m)) {
        return $m[1];
    }
    // Any route() call
    if (preg_match("/route\(\s*'([^']+)'/", $content, $m)) {
        $candidate = $m[1];
        // Filter out auth/utility routes
        if (!str_contains($candidate, 'login') && !str_contains($candidate, 'logout')) {
            // Return prefix (remove last segment if it's show/edit/create)
            $parts = explode('.', $candidate);
            $last  = end($parts);
            if (in_array($last, ['show', 'edit', 'create', 'store', 'update', 'destroy'])) {
                return implode('.', array_slice($parts, 0, -1)) . '.index';
            }
            return $candidate;
        }
    }

    // Infer from view path
    $pathParts = explode('/', $relPath);
    $fileName  = str_replace('.blade.php', '', end($pathParts));
    $folder    = count($pathParts) > 1 ? $pathParts[count($pathParts)-2] : '';

    // Convert module name to kebab prefix  SchoolSetup → school-setup
    $prefix = moduleToPrefix($moduleName);

    if (!empty($folder) && $folder !== 'views') {
        // Check lookup
        if (isset($lookup[$folder])) {
            return $lookup[$folder] . '.' . $fileName;
        }
        return $prefix . '.' . $folder . '.' . $fileName;
    }
    return $prefix . '.' . $fileName;
}

// ─────────────────────────────────────────────────────────────────
// Helper: moduleToPrefix  SchoolSetup → school-setup
// ─────────────────────────────────────────────────────────────────
function moduleToPrefix(string $moduleName): string
{
    $map = [
        'Prime'               => 'prime',
        'GlobalMaster'        => 'global-master',
        'SystemConfig'        => 'system-config',
        'Billing'             => 'billing',
        'Documentation'       => 'documentation',
        'SchoolSetup'         => 'school-setup',
        'SmartTimetable'      => 'smart-timetable',
        'TimetableFoundation' => 'timetable-foundation',
        'Transport'           => 'transport',
        'Hpc'                 => 'hpc',
        'Library'             => 'library',
        'StudentProfile'      => 'student',
        'StudentFee'          => 'student-fee',
        'Syllabus'            => 'syllabus',
        'QuestionBank'        => 'question-bank',
        'LmsExam'             => 'exam',
        'LmsQuiz'             => 'quiz',
        'LmsHomework'         => 'homework',
        'LmsQuests'           => 'quests',
        'Notification'        => 'notification',
        'Complaint'           => 'complaint',
        'Vendor'              => 'vendor',
        'Payment'             => 'payment',
        'Recommendation'      => 'recommendation',
        'SyllabusBooks'       => 'syllabus-books',
        'Accounting'          => 'accounting',
        'StandardTimetable'   => 'standard-timetable',
        'StudentPortal'       => 'student-portal',
        'Dashboard'           => 'dashboard',
        'Scheduler'           => 'scheduler',
        'EventEngine'         => 'event-engine',
        'Admission'           => 'admission',
        'Cafeteria'           => 'cafeteria',
        'Certificate'         => 'certificate',
        'FrontOffice'         => 'front-office',
        'HrStaff'             => 'hr-staff',
        'Inventory'           => 'inventory',
    ];
    return $map[$moduleName] ?? strtolower(preg_replace('/(?<!^)[A-Z]/', '-$0', $moduleName));
}
```

---

## Step 2 — Read the Raw JSON and the RBS

After running the script you will have `/tmp/prime_menu_raw.json`.

Now read the RBS Menu Mapping file to build the menu hierarchy lookup:
```
/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/3-Project_Planning/1-RBS/PrimeAI_RBS_Menu_Mapping_v2.0.md
```

### RBS Structure Reference

The RBS is structured as:
```
## Category                    ← Category column
### Main Menu                  ← Main Menu column
#### Sub-Menu (optional)       ← Sub-Menu column
##### Screen / Tab Title       ← matches Screen Title / Tab Name
```

**Part 1 — Prime App (Central Domain) — Category values:**
- `PG - Foundational Setup`
- `PG - Core Configuration`
- `PG - Subscription & Billing`

**Part 2 — Tenant App — Category values:**
- `FOUNDATIONAL SETUP`
- `SCHOOL SETUP`
- `ACADEMIC SETUP`
- `Student Mgmt.`
- `Operation Mgmt.`
- `FrontDesk`
- `Support & Maintenance`

### Module → Category Quick Map (for LMS / newer modules not yet in RBS)

Use the following as guidance when a screen is not found in the RBS:

| Module | Expected Category | Expected Main Menu |
|--------|------------------|--------------------|
| Prime, GlobalMaster, Billing, SystemConfig | `PG - Foundational Setup` / `PG - Core Configuration` / `PG - Subscription & Billing` | (per RBS) |
| SchoolSetup → organization, role-permission, employee | `SCHOOL SETUP` | `Core Config` / `Staff & Student Creation` |
| StudentProfile | `Student Mgmt.` | `Student` |
| StudentFee | `Student Mgmt.` | `Student` |
| Syllabus, QuestionBank | `ACADEMIC SETUP` | `Sylabus` |
| LmsExam, LmsQuiz, LmsHomework, LmsQuests, Hpc | `ACADEMIC SETUP` | `LMS / Assessment` *(not yet in RBS — mark Note)* |
| Transport | `Operation Mgmt.` | `Transport Management` |
| Library | `Operation Mgmt.` | `Library Management` *(not yet in RBS — mark Note)* |
| Notification | `FrontDesk` | `Notification` |
| Admission | `FrontDesk` | `Admission` |
| Complaint | `Support & Maintenance` | `Complaint Mgmt.` |
| Accounting | `Operation Mgmt.` | `Finance & Accounting` *(not yet in RBS — mark Note)* |
| SmartTimetable, TimetableFoundation, StandardTimetable | `ACADEMIC SETUP` | `Timetable Management` *(not yet in RBS — mark Note)* |
| StudentPortal | `Student Mgmt.` | `Student Portal` *(not yet in RBS — mark Note)* |
| HrStaff | `Operation Mgmt.` | `HR & Staff` *(not yet in RBS — mark Note)* |
| Inventory | `Operation Mgmt.` | `Inventory` *(not yet in RBS — mark Note)* |
| Recommendation | `ACADEMIC SETUP` | `Recommendation` *(not yet in RBS — mark Note)* |
| Cafeteria | `Operation Mgmt.` | `Cafeteria / Mess` *(not yet in RBS — mark Note)* |
| Certificate | `FrontDesk` | `Documents & Certificates` *(not yet in RBS — mark Note)* |
| FrontOffice | `FrontDesk` | `Front Office` *(not yet in RBS — mark Note)* |
| Vendor | `Operation Mgmt.` | `Vendor Management` *(not yet in RBS — mark Note)* |
| Dashboard, Scheduler, EventEngine, Payment, SyllabusBooks, Documentation | (system/utility — mark as `System / Utility`) | |

---

## Step 3 — Build and Write the Final CSV

For each item in `/tmp/prime_menu_raw.json`:

1. **If `tabs` is empty** → write one row with `Tab Name = N/A`
2. **If `tabs` has entries** → write one row per tab (same screen title, different tab name)
3. **Lookup Category / Main Menu / Sub-Menu** using:
   - First: search the RBS `##### Screen Title` headings
   - Second: use the Module → Category quick map above
   - If still not found: `Category = Needs Assignment`, `Main Menu = Needs Assignment`, `Sub-Menu = N/A`, `Note = Not in RBS`
4. **Route Name**: use value from JSON; if it ends with `.index` or `.show` it's fine. If it looks wrong, mark Note as `"Route name inferred — verify"`
5. **S.No.**: sequential starting from 1

Write the final CSV to:
```
/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Working_with_TEAM/1-Brijesh/Prime_AI_Menu_Audit.csv
```

Use PHP's `fputcsv()` or Python's `csv.writer` to write the file properly (handles commas/quotes in values).

---

## Step 4 — Validation Checks (add to Note column)

After generating, scan through the rows and add Notes for:

| Condition | Note to Add |
|-----------|-------------|
| Screen title = "Unknown" or is a file path | `"Title not extracted — verify view"` |
| Route name contains `.blade.` or is clearly a file path | `"Route name inferred — verify"` |
| Category = "Needs Assignment" | `"Not in RBS — needs menu assignment"` |
| View file is in a folder named `components/`, `partials/`, `_`, `shared/` | Skip row (these are partials, not screens) — remove from output |
| Module has views but zero screens extracted | Add a row with `Screen Title = "No screens found"`, `Note = "Check module views"` |

---

## Expected Output Size

Based on the module audit (2,253 blade files across 37 modules):
- Estimated main screen files: ~400–500
- Estimated rows with tabs: ~150–200 extra rows
- Total expected CSV rows: **500–700 rows** (including header)

---

## Notes on Specific Modules

- **SmartTimetable** has 177 views — many are generation/analytics sub-views. Screens include:
  `Activity`, `Period Set`, `Constraint`, `Teacher Availability`, `School Day`, `Generation Status`,
  `Analytics Dashboard`, `Teacher Workload`, `Room Utilization`, `Violations`, `Refinement`, `Substitution`
- **Hpc** has 242 views — includes 4 PDF templates (skip those), HPC config, evaluation, attendance, reports
- **StudentPortal** uses `<x-frontend.layout.app>` (not backend layout). Screens are student-facing.
  Screen titles use `<div class="page-title">` pattern.
- **SchoolSetup** has 220 views — heavily tabbed in `employee/show.blade.php` (5 tabs) and
  `student/show.blade.php` equivalent
- **Transport** has 151 views — tabbed screens in vehicle, driver, route show pages
- **Accounting** has 110 views — tabbed voucher entry, ledger, journal views
- **TimetableFoundation** has 158 views — period-sets, day-types, configurations, academic-terms

---

## Output File Format

```csv
S.No.,Module Name,Screen Title,Tab Name,Category,Main Menu,Sub-Menu,Route Name,View File,Note
1,SchoolSetup,Organization Management,N/A,SCHOOL SETUP,Core Config,N/A,school-setup.organization.index,Modules/SchoolSetup/resources/views/organization/index.blade.php,
2,SchoolSetup,Employee Details,Personal,SCHOOL SETUP,Staff & Student Creation,Staff Mgmt.,school-setup.employee.show,Modules/SchoolSetup/resources/views/employee/show.blade.php,
3,SchoolSetup,Employee Details,Professional,SCHOOL SETUP,Staff & Student Creation,Staff Mgmt.,school-setup.employee.show,Modules/SchoolSetup/resources/views/employee/show.blade.php,
...
```
