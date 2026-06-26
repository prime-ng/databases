# Recommendation Rules — Requirement Document

## 1. Screen Purpose & Overview

The **Recommendation Rules** screen is the configuration terminal for automated and manual student remediation. 

Teachers use this screen to define target score bounds (e.g., Score between 0% and 40% on an assessment) that automatically trigger the assignment of remedial materials or bundles. Rules link triggers, evaluations, conditions, and action content (materials or bundles) into a unified process flow.

---

## 2. Common Business Use Cases

1. **Automated Remediation Trigger**: Configuring a rule named `Algebra Remedial Rule` to automatically recommend `Algebra Basics Pack` if a student scores between 0% and 45% on a weekly math quiz.
2. **High Performer Enrichment**: Configuring a rule named `Physics Enrichment Rule` to manually or automatically recommend `Advanced Mechanics Readings` for scores above 85%.
3. **Automated vs. Moderated Modes**: Defining a rule with the mode set to manual approval so the teacher must verify the recommendation before it is dispatched to the student's portal.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `rec_recommendation_rules`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `name` | `varchar(150)` | No | N/A | Descriptive label for the rule. |
| `is_automated` | `boolean` | No | `1` (True) | If true, rule triggers automatically. Checked on create. |
| `trigger_event_id` | `bigint` | No | N/A | Foreign key referencing `rec_trigger_events.id`. |
| `class_id` | `bigint` | Yes | `NULL` | Foreign key referencing `sch_classes.id`. |
| `subject_id` | `bigint` | Yes | `NULL` | Foreign key referencing `sch_subjects.id`. |
| `topic_id` | `bigint` | Yes | `NULL` | Foreign key referencing `slb_topics.id`. |
| `performance_category_id`| `bigint` | Yes | `NULL` | Foreign key referencing `slb_performance_categories.id`. |
| `min_score_pct` | `decimal(5,2)`| Yes | `NULL` | Lower score boundary percentage. Must be $\ge 0$ and $\le 100$. |
| `max_score_pct` | `decimal(5,2)`| Yes | `NULL` | Upper score boundary percentage. Must be $\ge 0$ and $\le 100$. |
| `assessment_type_id` | `bigint` | Yes | `NULL` | Foreign key referencing `rec_assessment_types.id`. |
| `recommendation_mode_id`| `bigint` | No | N/A | Foreign key referencing `rec_recommendation_modes.id`. |
| `target_material_id` | `bigint` | Yes | `NULL` | Material to recommend (`rec_recommendation_materials.id`). |
| `target_bundle_id` | `bigint` | Yes | `NULL` | Bundle to recommend (`rec_material_bundles.id`). |
| `dynamic_material_type_id`| `bigint`| Yes | `NULL` | Format filter for dynamic resolution (`rec_dynamic_material_types.id`). |
| `dynamic_purpose_id` | `bigint` | Yes | `NULL` | Purpose filter for dynamic resolution (`rec_dynamic_purposes.id`). |
| `priority` | `integer` | No | `10` | Precedence order for rule evaluations. |
| `is_active` | `boolean` | No | `1` (True) | Operational status. Inactive rules do not trigger. |
| `created_at` | `timestamp` | Yes | `NULL` | Creation timestamp. |
| `updated_at` | `timestamp` | Yes | `NULL` | Last updated timestamp. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Rule Name** | Text Input | Yes | Must be a string. Max length: 150 characters. | None |
| **Trigger Event** | Dropdown | Yes | Must exist in `rec_trigger_events.id`. | None |
| **Recommendation Mode** | Dropdown | Yes | Must exist in `rec_recommendation_modes.id`. | None |
| **Min Score Pct** | Number Input | No | Decimal. Min: 0, Max: 100. | None |
| **Max Score Pct** | Number Input | No | Decimal. Min: 0, Max: 100. | None |
| **Class** | Dropdown | No | Must exist in `sch_classes.id`. | None |
| **Subject** | Dropdown | No | Must exist in `sch_subjects.id`. | None |
| **Topic** | Dropdown | No | Must exist in `slb_topics.id`. | None |
| **Performance Category** | Dropdown | No | Must exist in `slb_performance_categories.id`. | None |
| **Assessment Type** | Dropdown | No | Must exist in `rec_assessment_types.id`. | None |
| **Target Material** | Dropdown | No | Must exist in `rec_recommendation_materials.id`. | None |
| **Target Bundle** | Dropdown | No | Must exist in `rec_material_bundles.id`. | None |
| **Dynamic Material Type** | Dropdown | No | Must exist in `rec_dynamic_material_types.id`. | None |
| **Dynamic Purpose** | Dropdown | No | Must exist in `rec_dynamic_purposes.id`. | None |
| **Priority** | Number Input | No | Integer between 1 and 100. | `10` |
| **Automated** | Checkbox | Yes | Boolean. Required on create and update. | Checked (True) |
| **Active Status** | Checkbox | Yes | Boolean. Required on create and update. | Checked (True) |

---

## 5. Business Logic & Validation Policies

1. **Required Boolean Checkboxes**: Both `is_automated` and `is_active` are required booleans during creation and updates. If the checkboxes are unchecked in the HTML form, their inputs are missing from the request body, which fails validation. The developer must ensure the controller processes them cleanly or handle checkbox absences.
2. **Deactivation Cascade**: Before soft-deleting a rule, the controller sets `is_active = false` automatically.
3. **AJAX Status Toggling**: The toggle endpoint expects `is_active` in the request body as `is_active` (`0` or `1`). Toggling uses gate `tenant.recommendation-rule.update`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as a Teacher.
* Navigate to `/recommendation/rec-material` and click the **Rules** tab.

### Scenario A: Happy Path Create
1. Click the **"Add Rule"** button.
2. Enter Rule Name: `Remedial Math Rule`.
3. Select Trigger Event: `ON_ASSESSMENT_RESULT`.
4. Select Recommendation Mode: `SPECIFIC_BUNDLE`.
5. Enter Min Score: `0`, Max Score: `40`.
6. Select Class: `Class 9`, Subject: `Mathematics`.
7. Select Target Bundle: `Algebra Basics Pack`.
8. Ensure **"Automated"** and **"Active"** checkboxes are checked.
9. Click **"Create Rule"** (Submit button).
10. **Expected Result**:
    * Page redirects back to `/recommendation/rec-material`.
    * Success flash message appears: *"Recommendation Rule saved successfully."*
    * The new rule appears in the listing table.
    * Database check: Query `rec_recommendation_rules` and confirm all values match.

### Scenario B: Validation Failures
1. Click **"Add Rule"**.
2. Leave **Rule Name** empty.
3. Select Min Score: `-10` (out of bounds).
4. Click **"Create Rule"**.
5. **Expected Result**: Validation fails. Error messages are displayed:
    * *"The name field is required."*
    * *"The min score pct must be at least 0."*

### Scenario C: AJAX Status Toggling
1. In the Rules listing grid under `/recommendation/rec-material`, locate `Remedial Math Rule`.
2. Click the status switch in its row.
3. **Expected Result**:
    * AJAX request is sent to `/recommendation/recommendation-rules/{id}/toggle-status` sending `is_active = 0`.
    * Toast notification confirms success.
    * Database check: Confirm `is_active` has flipped to `0`.

### Scenario D: Soft Delete & Recovery
1. Locate your rule in the listing grid.
2. Click **"Delete"** and confirm the SweetAlert2 dialog.
3. **Expected Result**:
    * Rule is removed from the active grid.
    * Database check: Confirm `deleted_at` timestamp is written and `is_active` set to `0`.
4. Navigate to `/recommendation/recommendation-rules/trash/view`, verify it appears in the trash list, click **"Restore"** to recover it, and check that it reappears in the main listing.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/recommendation/rec-material`
* **Target Tab ID**: `#rec-rules-pane` (Rules Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/recommendation/recommendation-rules/create')
            ->type('name', 'Remedial Math Rule')
            ->select('trigger_event_id', '1') // Hook trigger event ID
            ->select('recommendation_mode_id', '1') // Delivery mode ID
            ->type('min_score_pct', '0')
            ->type('max_score_pct', '45')
            ->check('is_automated')
            ->check('is_active')
            ->press('Create Rule')
            ->assertPathIs('/recommendation/rec-material')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/recommendation/recommendation-rules/create')
            ->type('name', '') // Clear name
            ->type('min_score_pct', '-5') // Invalid min score
            ->press('Create Rule')
            ->assertSee('required')
            ->assertSee('must be at least 0')
            ->assertPathIsNot('/recommendation/rec-material');
});
```
