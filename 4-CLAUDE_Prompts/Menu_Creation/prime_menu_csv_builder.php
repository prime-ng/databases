<?php
/**
 * Prime-AI Menu CSV Builder
 * Reads /tmp/prime_menu_raw.json, applies menu hierarchy, outputs final CSV.
 */

$inputJson  = '/tmp/prime_menu_raw.json';
$outputCsv  = '/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/6-Working_with_TEAM/1-Brijesh/Prime_AI_Menu_Audit.csv';

$screens = json_decode(file_get_contents($inputJson), true);

// ─────────────────────────────────────────────────────────────────
// MENU HIERARCHY MAP
// Structure: 'ModuleName' => [
//   'category'  => ...,
//   'main_menu' => ...,
//   'sub_menu'  => ...,   (or per-screen overrides via 'screens' key)
// ]
// ─────────────────────────────────────────────────────────────────
$menuMap = [

    // ── PRIME APP (Central Domain) ────────────────────────────────
    'Prime' => [
        'category'  => 'PG - Subscription & Billing',
        'main_menu' => 'Tenant & Subscription Mgmt.',
        'sub_menu'  => 'N/A',
        'screens'   => [
            'Menu'          => ['PG - Foundational Setup',  'Menu Mgmt.',                   'N/A'],
            'Role'          => ['PG - Core Configuration',  'Roles & Permission (Prime)',    'N/A'],
            'Permission'    => ['PG - Core Configuration',  'Roles & Permission (Prime)',    'N/A'],
            'User'          => ['PG - Core Configuration',  'Roles & Permission (Prime)',    'N/A'],
            'Tenant'        => ['PG - Subscription & Billing', 'Tenant & Subscription Mgmt.', 'N/A'],
            'Plan'          => ['PG - Foundational Setup',  'Sales Plan & Module Mgmt.',     'N/A'],
            'Module'        => ['PG - Foundational Setup',  'Sales Plan & Module Mgmt.',     'N/A'],
            'Board'         => ['PG - Core Configuration',  'Session & Board Setup',         'N/A'],
            'Session'       => ['PG - Core Configuration',  'Session & Board Setup',         'N/A'],
            'Billing'       => ['PG - Subscription & Billing', 'Invoicing',                  'N/A'],
        ],
    ],

    'GlobalMaster' => [
        'category'  => 'PG - Foundational Setup',
        'main_menu' => 'Location Mgmt',
        'sub_menu'  => 'N/A',
        'screens'   => [
            'Country'    => ['PG - Foundational Setup', 'Location Mgmt',               'N/A'],
            'State'      => ['PG - Foundational Setup', 'Location Mgmt',               'N/A'],
            'District'   => ['PG - Foundational Setup', 'Location Mgmt',               'N/A'],
            'City'       => ['PG - Foundational Setup', 'Location Mgmt',               'N/A'],
            'Board'      => ['PG - Core Configuration', 'Session & Board Setup',        'N/A'],
            'Language'   => ['PG - Foundational Setup', 'Language Mgmt.',              'N/A'],
            'Dropdown'   => ['PG - Foundational Setup', 'System Config',               'Dropdown Menu Items'],
            'Module'     => ['PG - Foundational Setup', 'Sales Plan & Module Mgmt.',   'N/A'],
            'Plan'       => ['PG - Foundational Setup', 'Sales Plan & Module Mgmt.',   'N/A'],
        ],
    ],

    'SystemConfig' => [
        'category'  => 'PG - Foundational Setup',
        'main_menu' => 'System Config',
        'sub_menu'  => 'System Settings',
    ],

    'Billing' => [
        'category'  => 'PG - Subscription & Billing',
        'main_menu' => 'Invoicing',
        'sub_menu'  => 'N/A',
    ],

    'Documentation' => [
        'category'  => 'Support & Maintenance',
        'main_menu' => 'Help & Documentation',
        'sub_menu'  => 'N/A',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    // ── TENANT APP ────────────────────────────────────────────────
    'SchoolSetup' => [
        'category'  => 'SCHOOL SETUP',
        'main_menu' => 'Core Config',
        'sub_menu'  => 'N/A',
        'screens'   => [
            'Organization'              => ['SCHOOL SETUP', 'Core Config',              'N/A'],
            'Organization Group'        => ['SCHOOL SETUP', 'Core Config',              'N/A'],
            'Organization Academic'     => ['SCHOOL SETUP', 'Core Config',              'N/A'],
            'Building'                  => ['SCHOOL SETUP', 'Core Config',              'Infra. Setup'],
            'Room'                      => ['SCHOOL SETUP', 'Core Config',              'Infra. Setup'],
            'Room Type'                 => ['SCHOOL SETUP', 'Core Config',              'Infra. Setup'],
            'Infrasetup'                => ['SCHOOL SETUP', 'Core Config',              'Infra. Setup'],
            'Department'                => ['SCHOOL SETUP', 'Core Config',              'Dept / Designation Mgmt.'],
            'Designation'               => ['SCHOOL SETUP', 'Core Config',              'Dept / Designation Mgmt.'],
            'User'                      => ['SCHOOL SETUP', 'Core Config',              'User Mgmt.'],
            'Role'                      => ['SCHOOL SETUP', 'Core Config',              'User Mgmt.'],
            'Permission'                => ['SCHOOL SETUP', 'Core Config',              'User Mgmt.'],
            'Entity Group'              => ['SCHOOL SETUP', 'Core Config',              'Entity Group'],
            'School Class'              => ['ACADEMIC SETUP','Class & Subject Setup',   'Class Mgmt.'],
            'Section'                   => ['ACADEMIC SETUP','Class & Subject Setup',   'Class Mgmt.'],
            'Class Group'               => ['ACADEMIC SETUP','Class & Subject Setup',   'Class Mgmt.'],
            'Class Subject'             => ['ACADEMIC SETUP','Class & Subject Setup',   'Subject Mgmt.'],
            'Subject'                   => ['ACADEMIC SETUP','Class & Subject Setup',   'Subject Mgmt.'],
            'Subject Group'             => ['ACADEMIC SETUP','Class & Subject Setup',   'Subject Mgmt.'],
            'Employee'                  => ['SCHOOL SETUP', 'Staff & Student Creation', 'Staff Mgmt.'],
            'Employee Profile'          => ['SCHOOL SETUP', 'Staff & Student Creation', 'Staff Mgmt.'],
            'Attendance Type'           => ['SCHOOL SETUP', 'Core Config',              'N/A'],
            'Leave Type'                => ['SCHOOL SETUP', 'Core Config',              'N/A'],
            'Leave Config'              => ['SCHOOL SETUP', 'Core Config',              'N/A'],
            'Classification'            => ['SCHOOL SETUP', 'Core Config',              'Classification Mgmt.'],
            'Study Format'              => ['ACADEMIC SETUP','Class & Subject Setup',   'Class Mgmt.'],
        ],
    ],

    'StudentProfile' => [
        'category'  => 'Student Mgmt.',
        'main_menu' => 'Student',
        'sub_menu'  => 'Student Mgmt.',
    ],

    'StudentFee' => [
        'category'  => 'Student Mgmt.',
        'main_menu' => 'Student',
        'sub_menu'  => 'N/A',
        'screens'   => [
            'Fee Head'      => ['Student Mgmt.', 'Student', 'Fee Management'],
            'Fee Invoice'   => ['Student Mgmt.', 'Student', 'Fee Management'],
            'Fee Receipt'   => ['Student Mgmt.', 'Student', 'Fee Management'],
            'Concession'    => ['Student Mgmt.', 'Student', 'Fee Management'],
            'Scholarship'   => ['Student Mgmt.', 'Student', 'Fee Management'],
            'Fine'          => ['Student Mgmt.', 'Student', 'Fee Management'],
            'Fee Assignment'=> ['Student Mgmt.', 'Student', 'Fee Management'],
            'Fee Report'    => ['Student Mgmt.', 'Student', 'Fee Management'],
        ],
    ],

    'Syllabus' => [
        'category'  => 'ACADEMIC SETUP',
        'main_menu' => 'Sylabus',
        'sub_menu'  => 'Performance Config',
        'screens'   => [
            'Lesson'         => ['ACADEMIC SETUP', 'Sylabus', 'Performance Config'],
            'Topic'          => ['ACADEMIC SETUP', 'Sylabus', 'Performance Config'],
            'Competency'     => ['ACADEMIC SETUP', 'Sylabus', 'Performance Config'],
            'Bloom'          => ['ACADEMIC SETUP', 'Sylabus', 'Performance Config'],
            'Cognitive'      => ['ACADEMIC SETUP', 'Sylabus', 'Performance Config'],
            'Study Material' => ['ACADEMIC SETUP', 'Sylabus', 'Performance Config'],
        ],
    ],

    'SyllabusBooks' => [
        'category'  => 'ACADEMIC SETUP',
        'main_menu' => 'Sylabus',
        'sub_menu'  => 'N/A',
        'note'      => 'Not explicitly in RBS — linked to Syllabus module',
    ],

    'QuestionBank' => [
        'category'  => 'ACADEMIC SETUP',
        'main_menu' => 'LMS / Assessment',
        'sub_menu'  => 'Question Bank',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'LmsExam' => [
        'category'  => 'ACADEMIC SETUP',
        'main_menu' => 'LMS / Assessment',
        'sub_menu'  => 'Exam',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'LmsQuiz' => [
        'category'  => 'ACADEMIC SETUP',
        'main_menu' => 'LMS / Assessment',
        'sub_menu'  => 'Quiz',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'LmsHomework' => [
        'category'  => 'ACADEMIC SETUP',
        'main_menu' => 'LMS / Assessment',
        'sub_menu'  => 'Homework',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'LmsQuests' => [
        'category'  => 'ACADEMIC SETUP',
        'main_menu' => 'LMS / Assessment',
        'sub_menu'  => 'Quests',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'Hpc' => [
        'category'  => 'ACADEMIC SETUP',
        'main_menu' => 'LMS / Assessment',
        'sub_menu'  => 'Holistic Progress Card',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'SmartTimetable' => [
        'category'  => 'ACADEMIC SETUP',
        'main_menu' => 'Timetable Management',
        'sub_menu'  => 'Smart Timetable',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'TimetableFoundation' => [
        'category'  => 'ACADEMIC SETUP',
        'main_menu' => 'Timetable Management',
        'sub_menu'  => 'Timetable Foundation',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'StandardTimetable' => [
        'category'  => 'ACADEMIC SETUP',
        'main_menu' => 'Timetable Management',
        'sub_menu'  => 'Standard Timetable',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'Transport' => [
        'category'  => 'Operation Mgmt.',
        'main_menu' => 'Transport Management',
        'sub_menu'  => 'N/A',
        'screens'   => [
            'Vehicle'             => ['Operation Mgmt.', 'Transport Management', 'Vehicle Mgmt.'],
            'Route'               => ['Operation Mgmt.', 'Transport Management', 'Transport masters'],
            'Trip'                => ['Operation Mgmt.', 'Transport Management', 'Trip Management'],
            'Driver'              => ['Operation Mgmt.', 'Transport Management', 'Transport masters'],
            'Pickup'              => ['Operation Mgmt.', 'Transport Management', 'Transport masters'],
            'Allocation'          => ['Operation Mgmt.', 'Transport Management', 'Student Transport Mgmt.'],
            'Inspection'          => ['Operation Mgmt.', 'Transport Management', 'Vehicle Mgmt.'],
            'Attendance'          => ['Operation Mgmt.', 'Transport Management', 'Staff Attendance'],
            'Fuel'                => ['Operation Mgmt.', 'Transport Management', 'Vehicle Mgmt.'],
            'Insurance'           => ['Operation Mgmt.', 'Transport Management', 'Vehicle Mgmt.'],
            'Permit'              => ['Operation Mgmt.', 'Transport Management', 'Vehicle Mgmt.'],
            'Notification'        => ['Operation Mgmt.', 'Transport Management', 'Transport Notification'],
        ],
    ],

    'Library' => [
        'category'  => 'Operation Mgmt.',
        'main_menu' => 'Library Management',
        'sub_menu'  => 'N/A',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'Accounting' => [
        'category'  => 'Operation Mgmt.',
        'main_menu' => 'Finance & Accounting',
        'sub_menu'  => 'N/A',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'Notification' => [
        'category'  => 'FrontDesk',
        'main_menu' => 'Notification',
        'sub_menu'  => 'N/A',
    ],

    'Admission' => [
        'category'  => 'FrontDesk',
        'main_menu' => 'Admission',
        'sub_menu'  => 'Admission Enquiry',
    ],

    'Complaint' => [
        'category'  => 'Support & Maintenance',
        'main_menu' => 'Complaint Mgmt.',
        'sub_menu'  => 'N/A',
    ],

    'Vendor' => [
        'category'  => 'Operation Mgmt.',
        'main_menu' => 'Vendor Management',
        'sub_menu'  => 'N/A',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'Recommendation' => [
        'category'  => 'ACADEMIC SETUP',
        'main_menu' => 'LMS / Assessment',
        'sub_menu'  => 'Recommendation',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'Payment' => [
        'category'  => 'Student Mgmt.',
        'main_menu' => 'Student',
        'sub_menu'  => 'Fee Management',
        'note'      => 'Gateway/utility — not in RBS',
    ],

    'StudentPortal' => [
        'category'  => 'Student Mgmt.',
        'main_menu' => 'Student Portal',
        'sub_menu'  => 'N/A',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'Dashboard' => [
        'category'  => 'FOUNDATIONAL SETUP',
        'main_menu' => 'Dashboard',
        'sub_menu'  => 'N/A',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'HrStaff' => [
        'category'  => 'Operation Mgmt.',
        'main_menu' => 'HR & Staff',
        'sub_menu'  => 'N/A',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'Inventory' => [
        'category'  => 'Operation Mgmt.',
        'main_menu' => 'Inventory',
        'sub_menu'  => 'N/A',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'Cafeteria' => [
        'category'  => 'Operation Mgmt.',
        'main_menu' => 'Cafeteria / Mess',
        'sub_menu'  => 'N/A',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'Certificate' => [
        'category'  => 'FrontDesk',
        'main_menu' => 'Documents & Certificates',
        'sub_menu'  => 'N/A',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'FrontOffice' => [
        'category'  => 'FrontDesk',
        'main_menu' => 'Front Office',
        'sub_menu'  => 'N/A',
        'note'      => 'Not in RBS — needs menu assignment',
    ],

    'EventEngine' => [
        'category'  => 'FOUNDATIONAL SETUP',
        'main_menu' => 'System Configuration',
        'sub_menu'  => 'N/A',
        'note'      => 'System module (~20% done) — not in RBS',
    ],

    'Scheduler' => [
        'category'  => 'FOUNDATIONAL SETUP',
        'main_menu' => 'System Configuration',
        'sub_menu'  => 'N/A',
        'note'      => 'System module — not in RBS',
    ],
];

// ─────────────────────────────────────────────────────────────────
// Build CSV rows
// ─────────────────────────────────────────────────────────────────
$rows   = [];
$sno    = 1;

foreach ($screens as $screen) {
    $module   = $screen['module'];
    $rawTitle = $screen['title'];
    $tabs     = $screen['tabs'];
    $route    = $screen['route'];
    $viewFile = $screen['view_file'];

    // Clean up title — remove Blade expressions
    $title = preg_replace('/\{\{[^}]+\}\}/', '', $rawTitle);
    $title = preg_replace('/\{!![^}]+!!\}/', '', $title);
    $title = trim(preg_replace('/\s+/', ' ', $title));
    if ($title === '' || $title === 'Unknown') {
        $title = ucwords(str_replace(['-','_'], ' ', basename(dirname($viewFile))));
    }

    // Lookup menu for this module
    [$cat, $main, $sub, $note] = resolveMenu($module, $title, $menuMap);

    // Additional notes
    $noteArr = [];
    if ($note) $noteArr[] = $note;
    if (str_contains($route, '.blade.') || str_contains($route, '/')) {
        $noteArr[] = 'Route name inferred — verify';
    }
    if ($title === 'Unknown' || empty($title)) {
        $noteArr[] = 'Title not extracted — verify view';
    }
    if (in_array($title, ['Home Profile Contact', 'Section Management', 'Class Subject'])) {
        if (in_array('Home', $tabs) && in_array('Contact', $tabs)) {
            $noteArr[] = 'Placeholder Bootstrap tabs — verify actual tab names';
        }
    }

    $noteStr = implode('; ', $noteArr);
    $tabList = empty($tabs) ? ['N/A'] : $tabs;

    foreach ($tabList as $tab) {
        $rows[] = [
            $sno++,
            $module,
            $title,
            $tab,
            $cat,
            $main,
            $sub,
            $route,
            $viewFile,
            $noteStr,
        ];
    }
}

// ─────────────────────────────────────────────────────────────────
// Write CSV
// ─────────────────────────────────────────────────────────────────
$fp = fopen($outputCsv, 'w');
fputcsv($fp, ['S.No.', 'Module Name', 'Screen Title', 'Tab Name', 'Category', 'Main Menu', 'Sub-Menu', 'Route Name', 'View File', 'Note']);
foreach ($rows as $row) {
    fputcsv($fp, $row);
}
fclose($fp);

echo "Done! Written " . count($rows) . " rows (+ 1 header) to:\n$outputCsv\n";

// ─────────────────────────────────────────────────────────────────
function resolveMenu(string $module, string $title, array $menuMap): array
{
    $cfg = $menuMap[$module] ?? null;
    if (!$cfg) {
        return ['Needs Assignment', 'Needs Assignment', 'N/A', 'Module not in menu map'];
    }

    $note = $cfg['note'] ?? '';

    // Check screen-level overrides
    if (!empty($cfg['screens'])) {
        foreach ($cfg['screens'] as $keyword => $vals) {
            if (stripos($title, $keyword) !== false) {
                return [$vals[0], $vals[1], $vals[2], $note];
            }
        }
    }

    return [
        $cfg['category'],
        $cfg['main_menu'],
        $cfg['sub_menu'] ?? 'N/A',
        $note,
    ];
}
