# Syllabus Settings — Business Requirements

## What This Screen Does

The Syllabus Settings screen provides the centralized configuration control for the entire Syllabus Planning module. It allows administrators to define the structural behavior of how teaching estimation, homework release, quiz release, and quest release operate across the syllabus hierarchy.

These settings act as the behavioral switches that determine at which depth of the topic hierarchy—Lesson, Topic, Sub-Topic, Mini-Topic, Micro-Topic, or Nano-Topic—various automated actions are triggered. Changing a single setting here cascades across the Lesson Sequencing display, the Topic Release Control filters, and the background cron-driven release engine.

---

## When This Screen Is Used

- System Initialization during the initial setup of the Syllabus module to define the default planning depth
- Policy Change when the school decides to shift from Topic-level planning to Mini-Topic-level planning for greater precision
- Release Strategy Adjustment when the administration decides that homework should be released at the Sub-Topic level while quizzes should release at the Topic level
- Academic Year Setup at the beginning of each year to review and adjust settings based on lessons learned from the previous year

## Default Data Load

This screen displays within the Syllabus Planning tab group. When the user navigates to Syllabus → Planning, SyllabusController@planning() applies default filters (class_section_id=1, subject_id=5, academic_session_id=7) and loads tab-specific data. Shared dropdowns include Class, Section, Class-Section, Subject, and Academic Session.

---

---

## Key Fields at a Glance

**Configuration Variables**
A sidebar list displays all available settings with their current values rendered as badges. Each entry shows the setting name, a truncated description, and the currently selected value formatted as a human-readable label. The active setting is highlighted with an accent color and left border indicator.

**Syllabus Teaching Estimation Level**
This setting defines the depth at which teachers will provide period estimation during Lesson Sequencing. The available options are Lesson, Topic, Sub-Topic, and Mini-Topic. The selected value determines which columns are visible in the Lesson Sequencing table and which topic levels appear in the filtered data.

**Homework Release Level**
This setting defines the syllabus hierarchy level at which homework assignments will be automatically released to students. Options include all levels from Lesson up to Nano-Topic. The selected value is used by the Topic Release Control tab and the background cron job to filter which schedules are eligible for homework auto-release.

**Quiz Release Level**
This setting defines the syllabus hierarchy level at which quizzes will be automatically released to students. Options include all levels from Lesson up to Nano-Topic. The selected value is used by the Topic Release Control tab and the background cron job to filter which schedules are eligible for quiz auto-release.

**Quest Release Level**
This setting defines the syllabus hierarchy level at which learning Quests will be automatically released to students. Options include all levels from Lesson up to Nano-Topic. The selected value is used by the Topic Release Control tab and the background cron job to filter which schedules are eligible for quest auto-release.

---

## How This Screen Works — Logic Flow (Non-Technical)

This screen has a single save action but the system performs multiple checks and transformations in sequence. Below is exactly what happens when a setting is changed and saved.

### Step 1: Load Existing Settings (Page Load)

When the Settings tab opens, the system asks:

**"What are the current values for all syllabus settings?"**

The system queries the configuration table for four specific keys:

```
Query: SchConfig WHERE key IN (
    'syllabus_teaching_estimation_level_for_lesson_planning',
    'homework_released_on_syllabus_level',
    'quiz_released_on_syllabus_level',
    'quest_released_on_syllabus_level'
)

Result: { key: value } pairs, e.g.:
    syllabus_teaching_estimation_level_for_lesson_planning → "Topic"
    homework_released_on_syllabus_level → "Sub-Topic"
    quiz_released_on_syllabus_level → "Topic"
    quest_released_on_syllabus_level → "Mini-Topic"
```

These values are plucked into a simple key-value collection. If a setting has never been configured, its key will be missing from the collection. The system handles missing keys gracefully in downstream screens by applying defaults.

The values are displayed in the sidebar with their original formatting (Title-Case with hyphens). They are also normalized to lowercase-with-underscores for internal use:
```
"Topic"     → "topic"
"Sub-Topic" → "sub_topic"
"Mini-Topic" → "mini_topic"
```

---

### Step 2: User Selects a Setting and Changes the Value

When the user clicks on a setting in the sidebar, the right panel shows the current value in a dropdown. The user picks a new value and clicks **Save Changes**. This triggers the full save chain:

```
INPUT from the form:
    key:     "homework_released_on_syllabus_level"
    value:   "mini_topic" (snake_case from the dropdown option value)
    description: "Free text description (optional)"
```

---

### Step 3: Validation — Permission and Format Check

The system runs four sequential validations:

```
CHECK 1: Permission
    Does the user have "tenant.lesson.update" permission?
    → If NO → Return 403 Forbidden
    → If YES → Continue

CHECK 2: Is the key valid?
    Is the submitted key one of the four allowed keys?
    Allowed: syllabus_teaching_estimation_level_for_lesson_planning,
             homework_released_on_syllabus_level,
             quiz_released_on_syllabus_level,
             quest_released_on_syllabus_level
    → If NO → Return validation error
    → If YES → Continue

CHECK 3: Is the value valid for this key?
    For "syllabus_teaching_estimation_level":
        Allowed values: lesson, topic, sub_topic, mini_topic
        (Only 4 levels — nano and micro are not teaching estimation levels)
    
    For the three release level keys (homework, quiz, quest):
        Allowed values: lesson, topic, sub_topic, mini_topic, micro_topic, nano_topic
        (All 6 levels are available for release settings)

    → If value NOT in allowed list → Return error: "Invalid option selected for this setting."
    → If value IS in allowed list → Continue
```

---

### Step 4: Format the Value for Storage

Before saving, the system transforms the raw value to a standardized display format:

```
Input  (from dropdown): "mini_topic"   (snake_case)
Step 1: str_replace('-', '_', input)   → "mini_topic"  (normalize to underscore)
Step 2: ucwords(... , '_')             → "Mini_Topic"  (Title Case with underscore separator)
Step 3: str_replace('_', '-', ...)     → "Mini-Topic"  (Title Case with hyphen separator)

Output (stored in DB): "Mini-Topic"

More examples:
    "sub_topic"    → "Sub-Topic"
    "nano_topic"   → "Nano-Topic"
    "lesson"       → "Lesson"
```

**Why the format normalization matters:** The stored value "Mini-Topic" is human-readable in the database and can be displayed directly. But when the system needs to compare it internally, it converts back to "mini_topic" (lowercase, underscore) for consistent matching. This round-trip conversion prevents mismatches due to case or separator differences.

---

### Step 5: Uniqueness Validation Across Release Levels (Critical Check)

This is the most important validation. The three release level settings (Homework, Quiz, Quest) must each be set to a different hierarchy level. The system prevents two release types from using the same level:

```
IF the key being saved is a release level key (homework/quiz/quest):
    Read ALL three release level values from the database
    (includes the new value being saved)

    For each of the three keys:
        Skip the current key (the one being edited)
        For the other two keys:
            Get the stored value OR default to "Topic" if not set
            Normalize: lowercase, replace hyphens with underscores
            
            Compare: Does the other key's value match the new value?
            → If YES → Return error:
                "The level 'Mini-Topic' is already assigned to Homework Release Level.
                 Homework, Quiz, and Quest release levels must be unique."
            → If NO → Continue checking
```

**Real Example:**
```
Current state in database:
    homework_released_on_syllabus_level → "Topic"
    quiz_released_on_syllabus_level     → "Sub-Topic"
    quest_released_on_syllabus_level    → (not set, defaults to "Topic")

User tries to set: homework_released_on_syllabus_level = "Sub-Topic"

System checks:
    Compare new value "Sub-Topic" with quiz value "Sub-Topic" → MATCH!
    → ❌ Reject: "The level 'Sub-Topic' is already assigned to Quiz Release Level."
```

**Why this rule exists:** If homework and quiz both release at the "Sub-Topic" level, the cron job would try to process the same schedule twice for different purposes. The uniqueness constraint prevents this overlap and ensures each release type targets a distinct set of topics.

---

### Step 6: Load Metadata and Save

After all validations pass, the system prepares the full record for saving:

```
STEP 6a: Read metadata from an existing configuration record
    Find any existing record for "syllabus_teaching_estimation_level_for_lesson_planning"
    Extract: module_id, module_code, ordinal from that record
    (These values are used as defaults for new settings)
    
    If no existing record found → defaults: module_id=20, module_code='SLB', ordinal=3

STEP 6b: Look up the metadata for this specific key
    Each key has predefined metadata:
        - module_id, module_code (from step 6a)
        - key_name (human-readable, e.g., "Homework Released Level")
        - value_type: "STRING"
        - description: from the submitted form OR the predefined default
        - tenant_can_modify: 1
        - mandatory: 1
        - used_by_app: 1
        - is_active: 1
        - ordinal (varies per key: 3 for Teaching Estimation, 4 for Homework, 5 for Quiz, 6 for Quest)

STEP 6c: Update or Create the record
    SQL: UPDATE sch_configs SET value = "Mini-Topic", ... WHERE key = "homework_released_on_syllabus_level"
    If record does not exist: INSERT INTO sch_configs (key, value, ...)

STEP 6d: Log the activity
    Create audit log entry: "Updated syllabus setting homework_released_on_syllabus_level to Mini-Topic"
```

The `updateOrCreate` method ensures that re-saving an existing setting updates it, while first-time saves create a new record. This handles both initialization and modification scenarios.

---

### Step 7: Post-Save Page Reload

After saving, the system sends back a success response:

```
Response: { success: true, message: "Setting updated successfully." }

On the browser side:
    1. Show a success toast notification
    2. Wait 1.2 seconds (1200ms delay)
    3. Reload the entire page
```

**Why the reload is necessary:** All four settings affect how other tabs query and display data. The Lesson Sequencing tab reads the estimation level to filter rows. The Topic Release Control tab reads the release levels to determine depth. Simply updating the sidebar badge is not enough—other tabs need fresh data from the server with the new configuration applied.

---

## Business Rules and Conditions

**Uniqueness Across Release Levels**
The three release level settings—Homework, Quiz, and Quest—must each be set to a different syllabus level. The system enforces this uniqueness constraint at the application level. If a user tries to set Quiz Release Level to the same value as Homework Release Level, the system rejects the change with a validation error. This prevents conflicts in the automated release engine where a single schedule could be targeted by multiple release rules.

**Cascading Display Impact**
Changing the Syllabus Teaching Estimation Level immediately affects the Lesson Sequencing tab. When the value is changed, the Lesson Sequencing table must be reloaded to show rows at the new depth level. The system does not automatically refresh the view; the user must navigate to the Lesson Sequencing tab and re-apply their filters to see the updated data.

**Tenant-Specific Storage**
Each setting is stored as a key-value pair in the system configuration table, scoped to the individual school tenant. Changes made in one school do not affect any other school in the multi-tenant environment. The setting values are cached to avoid repeated database lookups during page loads.

**Format Standardization**
All setting values are stored in a standardized format. The system automatically converts underscored snake_case input values to Title-Case with hyphens before persisting. For example, the value mini_topic is stored as Mini-Topic. When read back, the system normalizes the stored value back to snake_case for internal comparison and filtering logic.

**Post-Save Reload Requirement**
After saving any setting, the system displays a success notification and automatically reloads the page after a short delay. This ensures all tabs refresh their data with the new configuration. The reload is mandatory because the settings affect query filters that are evaluated during page load.

**Allowed Values Per Key**
The Syllabus Teaching Estimation Level accepts only 4 values (Lesson, Topic, Sub-Topic, Mini-Topic) because teaching estimation at Micro or Nano level would be too granular for practical period planning. The three release level keys accept all 6 values (Lesson through Nano-Topic) because content release can benefit from finer granularity.

---

## Conditions at a Glance — Decision Table

| Feature | Condition | If True | If False |
|---------|-----------|---------|----------|
| Permission | User has "lesson.update"? | Continue save | Return 403 |
| Key validity | Key is one of 4 allowed? | Continue save | Return validation error |
| Value validity | Value in allowed list for this key? | Continue save | Return "Invalid option" error |
| Release level? | Key is homework/quiz/quest? | Run uniqueness check | Skip uniqueness check |
| Uniqueness | Other release level has same value? | ❌ Reject with error | ✅ Allow save |
| DB record exists? | Config exists for this key? | UPDATE existing | INSERT new |
| Metadata exists? | Teaching Estimation record exists? | Use its module_id/code | Defaults: 20, 'SLB' |
| Format conversion | Input is snake_case? | Convert to Title-Case w/ hyphens | Save as-is |
| Post-save | Save was successful? | Reload page after 1.2s | Show error, no reload |

---

## Workflow Steps

**Changing the Planning Depth Level**
The Academic Director opens the Syllabus Settings tab. The sidebar shows four configuration variables with their current values. The Director selects Syllabus Teaching Estimation Level from the list. The right panel displays the setting name, description text area, and a dropdown with the available options. The Director changes the value from Topic to Mini-Topic. They click Save Changes. The system validates the input, updates the configuration, shows a success toast notification, and reloads the page after 1.2 seconds.

---

## Example Scenario

At the start of the new academic year, the Principal reviews the previous year's Planning Accuracy report. The report reveals that Topic-level planning was too broad, causing wide variances in teacher pacing. The Principal decides to switch to Mini-Topic-level planning for all subjects. The Academic Director opens the Syllabus Settings tab and changes Syllabus Teaching Estimation Level to Mini-Topic. They also decide that homework should be released at the Sub-Topic level, quizzes at the Topic level, and quests at the Mini-Topic level. They set each of the three release level settings to different values successfully. After saving, they navigate to Lesson Sequencing and see that the table now displays rows at the Mini-Topic depth, allowing teachers to estimate periods for much smaller teaching units.

---

## Related Screens

- **Lesson Sequencing** — Display depth and filtering are controlled by the Syllabus Teaching Estimation Level setting
- **Topic Release Control** — Release type filtering uses the Homework, Quiz, and Quest Release Level settings to determine which rows to show
- **ReleaseLmsResources Cron** — The background cron job reads these settings to determine which schedules to process for automated resource release

---

## Requirements

- The system MUST display four config keys in a sidebar on the `syllabus_settings` tab of `planning.index`: `syllabus_teaching_estimation_level_for_lesson_planning`, `homework_released_on_syllabus_level`, `quiz_released_on_syllabus_level`, `quest_released_on_syllabus_level`
- Each setting's value MUST be read from `SchConfig::whereIn('key', $configKeys)->pluck('value', 'key')` in `SyllabusController@planning()` (line 167)
- The form is rendered client-side via JavaScript in `resources/views/lesson-management/partials/syllabus-settings/index.blade.php` — a sidebar list with edit form on the right
- Save via `POST /planning/save-setting` (route: `planning.saveSetting`) handled by `SyllabusController@saveSetting()` (line 1729)
- **Permission:** `Gate::authorize('tenant.lesson.update')` — no dedicated policy, uses Gate directly
- **Model:** `SchConfig` (`Modules\SchoolSetup\Models\SchConfig`) — NOT a Syllabus model
- **Validation:** Inline `$request->validate()` — no FormRequest class
- **Allowed values per key:**
  - Teaching estimation level: `lesson`, `topic`, `sub_topic`, `mini_topic` (4 values only)
  - Release levels (homework, quiz, quest): `lesson`, `topic`, `sub_topic`, `mini_topic`, `micro_topic`, `nano_topic` (6 values)
- **Uniqueness constraint:** The three release levels must each be different — checked by reading all existing `SchConfig` values for those keys and comparing normalized values
- **Value normalization:** `str_replace('_', '-', ucwords(str_replace('-', '_', $rawValue), '_'))` converts `sub_topic` → `Sub-Topic` for storage
- **Post-save:** Client JS shows success toast, waits 1200ms, then `location.reload()` to refresh all dependent tabs
- **Metadata defaults:** If no existing config record exists, uses `module_id=20`, `module_code='SLB'`, `ordinal=3` for new settings
- **Key validation:** Only the 4 known keys pass the `in:` rule — any other key returns 500
- **Activity logging:** `activityLog(null, 'Updated', ['message' => "Updated syllabus setting {key} to {value}", 'module' => 'Syllabus'])`

---

## Who Can Access This Screen

| Role | Access Level | Permission | Notes |
|------|-------------|------------|-------|
| Administrator | Full Access | `tenant.lesson.update` | Can view and modify all syllabus settings |
| Academic Director | Full Access | `tenant.lesson.update` | Can change planning depth and release level strategies |
| HOD / Academic Coordinator | Read-Only | `tenant.lesson.viewAny` | Can view current settings in sidebar but cannot modify |
| Teacher | Read-Only | `tenant.lesson.viewAny` | Can view settings reference |
| Principal / Director | Read-Only | `tenant.lesson.viewAny` | Can review settings configuration |
| System Admin | Full Access | `tenant.lesson.update` | Can manage all settings including metadata overrides |

---

## Validate Before Save (Multiple Conditions)

The `SyllabusController@saveSetting()` performs this chain:

```
CHECK 1: Gate Authorization
    Gate::authorize('tenant.lesson.update')
    → If NO → 403 Forbidden
    → If YES → Continue

CHECK 2: Request Validation
    $request->validate([
        'key' => 'required|string|in:syllabus_teaching_estimation_level_for_lesson_planning,homework_released_on_syllabus_level,quiz_released_on_syllabus_level,quest_released_on_syllabus_level',
        'value' => 'required|string',
        'description' => 'nullable|string|max:500',
    ])
    → If key not in list → 500: validation error for 'key'
    → If pass → Continue

CHECK 3: Value Validity Per Key
    $allowedValues = ['lesson', 'topic', 'sub_topic', 'mini_topic'];
    If key !== 'syllabus_teaching_estimation_level_for_lesson_planning':
        $allowedValues = array_merge($allowedValues, ['micro_topic', 'nano_topic'])
    If strtolower($rawValue) NOT in $allowedValues:
        → Return 500: "Invalid option selected for this setting."
    → If valid → Continue

CHECK 4: Format Normalization
    $value = str_replace('_', '-', ucwords(str_replace('-', '_', $rawValue), '_'))
    Example: 'sub_topic' → 'Sub-Topic', 'mini_topic' → 'Mini-Topic'
    → This $value is what gets stored

CHECK 5: Uniqueness Across Release Levels
    If key is one of the three release level keys:
        $dbConfigs = SchConfig::whereIn('key', $releaseLevelKeys)->pluck('value', 'key')
        For each OTHER release level key:
            $otherValue = $dbConfigs[$otherKey] ?? 'Topic'
            $normalizedOther = strtolower(str_replace('-', '_', $otherValue))
            $normalizedNew = strtolower(str_replace('-', '_', $value))
            If normalizedOther === normalizedNew:
                → Return 500: "Validation Error: The level '{value}' is already assigned to {otherLabel}."
    If key is teaching estimation level → Skip uniqueness check

CHECK 6: Metadata Resolution & Save
    $existingConfig = SchConfig::where('key', 'syllabus_teaching_estimation_level_for_lesson_planning')->first()
    $moduleId = $existingConfig?->module_id ?? 20
    $moduleCode = $existingConfig?->module_code ?? 'SLB'
    $ordinal = $existingConfig?->ordinal ?? 3
    Build $attributes array from settings metadata schema (key_name, value_type, description, etc.)
    SchConfig::updateOrCreate(['key' => $key], $attributes)
    activityLog(...)
    → Return JSON: { success: true, message: "Setting updated successfully." }
```

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status | Trigger |
|----------|--------------|-------------|---------|
| Missing permission | `AuthorizationException` → 403 | 403 | User without `tenant.lesson.update` |
| Invalid key | "The selected key is invalid." (Laravel validation) | 500 | Key not in the `in:` list of 4 allowed keys |
| Invalid value for key | "Invalid option selected for this setting." | 500 | Value not in allowed list for this key type |
| Duplicate release level | "Validation Error: The level 'Sub-Topic' is already assigned to Quiz Release Level. Homework, Quiz, and Quest release levels must be unique." | 500 | Release level uniqueness constraint violated |
| Database save failure | QueryException caught by framework → 500 | 500 | `updateOrCreate` fails |
| Missing description | No error — description is nullable| N/A | Description field is optional |

---

## Success Scenarios

**Scenario 1: Changing Syllabus Teaching Estimation Level**
Academic Director selects `syllabus_teaching_estimation_level_for_lesson_planning`, changes dropdown from `topic` to `mini_topic`, clicks Save Changes. `saveSetting()` validates key (in list), validates value (`mini_topic` in allowed list), normalizes to `Mini-Topic`, skips uniqueness check (not a release key), resolves metadata from existing config (module_id=20, module_code='SLB'), calls `SchConfig::updateOrCreate()`. Response: `{ success: true, message: "Setting updated successfully." }`. Client shows toast, waits 1.2s, calls `location.reload()`.

**Scenario 2: Setting All Three Release Levels**
Director sets Homework=`sub_topic`, Quiz=`topic`, Quest=`mini_topic`. Each save passes uniqueness check (all different). `SchConfig` stores each as `Sub-Topic`, `Topic`, `Mini-Topic`. Topic Release Control tab now shows three different depth levels per release type.

**Scenario 3: First-Time Initialization**
No `SchConfig` records exist. Director saves all four keys. `$existingConfig` is null, so fallback `module_id=20`, `module_code='SLB'`, `ordinal=3` are used. Each `updateOrCreate` inserts a new record with default metadata.

---

## Failure Scenarios

**Scenario 1: Duplicate Release Level Rejected**
Current DB: homework=`Topic`, quiz=`Sub-Topic`, quest not set (defaults to `Topic`). Director tries to set quest to `topic`. Check 5 normalizes both to `topic`, finds homework already has `Topic`. Response: `{ success: false, message: "Validation Error: The level 'Topic' is already assigned to Homework Release Level. Homework, Quiz, and Quest release levels must be unique." }`.

**Scenario 2: Invalid Value for Teaching Estimation**
Director tries to set `syllabus_teaching_estimation_level_for_lesson_planning` to `nano_topic`. Check 3: `$allowedValues = ['lesson','topic','sub_topic','mini_topic']` (key is teaching estimation key, so `micro_topic` and `nano_topic` are NOT merged). `nano_topic` not in list. Response: `{ success: false, message: "Invalid option selected for this setting." }`.

**Scenario 3: Unauthorized User**
Teacher without `tenant.lesson.update` clicks Save Changes. `Gate::authorize('tenant.lesson.update')` throws `AuthorizationException`. Laravel returns 403. The save never reaches validation.

---

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `sch_configs` | Database Table | Primary storage; stores key-value pairs with metadata: `module_id`, `module_code`, `key_name`, `value`, `value_type`, `description`, `ordinal`, `tenant_can_modify`, `mandatory`, `used_by_app`, `is_active` |
| `SchConfig` Model | Eloquent Model | `Modules\SchoolSetup\Models\SchConfig` — NOT a Syllabus module model |
| `SyllabusController@saveSetting()` | Controller | Handles save at `POST /planning/save-setting` (route: `planning.saveSetting`, line 1729) |
| `SyllabusController@planning()` | Controller | Reads all 4 config values via `SchConfig::whereIn('key', ...)->pluck()` (line 167) |
| `tenant.lesson.update` | Permission | Gate authorization for save operations |
| View | Blade Template | `resources/views/lesson-management/partials/syllabus-settings/index.blade.php` |
| No Policy | N/A | No dedicated policy — uses `Gate::authorize('tenant.lesson.update')` directly |
| No FormRequest | N/A | Uses inline `$request->validate()` with `in:` rule on key |
