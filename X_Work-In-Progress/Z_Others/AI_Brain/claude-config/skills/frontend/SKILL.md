---
name: frontend
description: Build and modify Blade views, components, Alpine.js interactions, and AdminLTE pages
user_invocable: true
---

# /frontend — Frontend Development

Create and modify Blade views, components, and frontend interactions for the Prime-AI platform.

## Usage
- `/frontend page ModuleName PageName` — Create a new Blade page (index/create/edit/show)
- `/frontend component ComponentName` — Create a new Blade component
- `/frontend form ModuleName ModelName` — Generate a CRUD form (create + edit) using existing Blade components
- `/frontend table ModuleName ModelName` — Generate an index page with data table
- `/frontend modal ModalName` — Create a reusable modal component
- `/frontend chart ChartType` — Add an ApexCharts chart (bar, line, pie, area, donut)
- `/frontend audit ModuleName` — Audit views for consistency, accessibility, and security

## Tech Stack (MUST follow)

| Layer | Technology | Notes |
|-------|-----------|-------|
| Templates | Laravel Blade | Server-rendered, no SPA |
| Interactivity | Alpine.js 3.x | `x-data`, `x-show`, `x-on`, `x-model` |
| Admin Theme | AdminLTE 4 | All backend pages extend AdminLTE layout |
| CSS (primary) | Tailwind CSS 3.x | Utility-first for custom components |
| CSS (framework) | Bootstrap 5.3 | Used by AdminLTE, available globally |
| Icons | Font Awesome 6.x, Bootstrap Icons, Feather Icons | FA is primary |
| AJAX | jQuery $.ajax / Axios | jQuery for legacy, Axios for new code |
| Dropdowns | Select2 4.x | Enhanced select elements |
| Charts | ApexCharts 3.x | Dashboard charts and analytics |
| Calendar | FullCalendar 6.x | Timetable and scheduling views |
| Maps | JSVectorMap | Geographic visualizations |
| Editor | Summernote | WYSIWYG rich text |
| Scrollbar | OverlayScrollbars | Custom scrollbar styling |

## Directory Structure

```
resources/views/
├── layouts/                    # Master layouts
├── backend/v1/                 # Admin pages (per module)
│   └── {module-name}/          # e.g., smart-timetable/
│       ├── index.blade.php
│       ├── create.blade.php
│       ├── edit.blade.php
│       └── show.blade.php
├── frontend/v1/                # Public-facing pages
├── prime/v1/                   # Tenant management pages
├── auth/                       # Login, register, password
└── components/
    ├── backend/                # Admin components
    │   ├── form/               # 40+ form controls
    │   │   ├── input-text.blade.php
    │   │   ├── select-dropdown.blade.php
    │   │   ├── checkbox.blade.php
    │   │   ├── date-picker.blade.php
    │   │   └── ...
    │   ├── table/              # Table actions, status switches
    │   ├── card/               # Card layouts
    │   ├── layouts/            # Layout scaffolds
    │   ├── components/         # Breadcrumbs, modals, menus, dropdowns
    │   └── partials/           # head, footer-scripts, sidebar
    ├── frontend/               # Public-facing components
    └── prime/                  # Tenant-specific components
```

## Steps

### For `/frontend page`

1. Determine the module and page type (index / create / edit / show)
2. Read existing views in `resources/views/backend/v1/{module}/` to match patterns
3. Read the relevant Blade components in `resources/views/components/backend/`
4. Read the controller to understand what data is passed to the view
5. Create the Blade file following these conventions:
   - Extend the correct layout: `@extends('backend.v1.layouts.app')` or similar
   - Use `@section('content')` for page content
   - Use `@push('styles')` for page-specific CSS
   - Use `@push('scripts')` for page-specific JS
   - Use existing Blade components (`<x-backend.form.input-text>`, `<x-backend.table.action-button>`, etc.)
   - Wrap interactive sections with Alpine.js `x-data`

### For `/frontend component`

1. Read existing components in `resources/views/components/backend/` for patterns
2. Create the component Blade file with:
   - `@props` directive for component parameters
   - Default values for optional props
   - Tailwind/Bootstrap classes matching existing components
   - Alpine.js for any interactivity

### For `/frontend form`

1. Read the model's `$fillable` fields and `$casts`
2. Read the FormRequest validation rules (Store + Update)
3. Read existing Blade form components in `resources/views/components/backend/form/`
4. Generate create.blade.php and edit.blade.php using:
   - `<x-backend.form.input-text>` for string/text fields
   - `<x-backend.form.select-dropdown>` for foreign keys and enums
   - `<x-backend.form.checkbox>` for boolean fields
   - `<x-backend.form.date-picker>` for date/datetime fields
   - `<x-backend.form.textarea>` for text/longText columns
   - Proper `@csrf` and `@method('PUT')` for edit forms
   - `old()` helper for form re-population
   - `@error()` directive for validation errors

### For `/frontend table`

1. Read the controller's index method to understand data passed
2. Read existing index pages for table patterns
3. Generate index.blade.php with:
   - Data table with sortable columns
   - Action buttons (view, edit, delete) using existing components
   - Status toggle switches for `is_active` fields
   - Pagination
   - Search/filter section
   - Delete confirmation modal

### For `/frontend chart`

1. Determine chart type and data source
2. Generate the chart using ApexCharts pattern:
   ```html
   <div id="{chart-id}" x-data="{ chart: null }" x-init="
       chart = new ApexCharts($el, {
           chart: { type: '{type}', height: 350 },
           series: [{...}],
           xaxis: {...}
       });
       chart.render();
   "></div>
   ```

### For `/frontend audit`

1. Read all Blade files in the module's view directory
2. Check for:
   - **Security:** `{!! !!}` without sanitization, missing `@csrf`, inline JS with user data
   - **Consistency:** Using raw HTML instead of existing Blade components
   - **Accessibility:** Missing `aria-label`, `alt` attributes, form labels
   - **Performance:** Large inline scripts, unoptimized images, missing lazy loading
   - **Alpine.js:** Proper `x-data` scoping, no jQuery where Alpine suffices
   - **Deprecated patterns:** Direct Bootstrap class usage where Tailwind component exists
3. Return structured report

## Rules (MUST follow)

### Component Reuse
- **ALWAYS** check `resources/views/components/backend/form/` before creating form elements
- **NEVER** write raw `<input>`, `<select>`, `<textarea>` — use existing Blade components
- If a needed component doesn't exist, create it in the component library first, then use it

### Security
- **ALWAYS** use `{{ }}` (escaped) — never `{!! !!}` unless rendering trusted HTML (e.g., Summernote output)
- **ALWAYS** include `@csrf` on every form
- **ALWAYS** include `@method('PUT')` or `@method('DELETE')` for non-POST forms
- **NEVER** output raw user input in inline JavaScript — use `data-*` attributes or Alpine.js `x-data`

### Interactivity
- **Prefer Alpine.js** for new interactive features (show/hide, toggles, tabs, dropdowns)
- **Use jQuery** only when integrating with Select2, FullCalendar, or existing jQuery plugins
- **Use Axios** (not jQuery $.ajax) for new AJAX requests
- **Avoid** mixing Alpine.js and jQuery on the same element

### Layout
- Backend pages: extend AdminLTE layout, use AdminLTE card/box structure
- Use `@push('styles')` and `@push('scripts')` — never inline in content section
- Views go in `resources/views/backend/v1/{module-name}/` (kebab-case module name)

### Naming
- View files: `kebab-case.blade.php` (e.g., `constraint-group.blade.php`)
- Component names: `kebab-case` (e.g., `<x-backend.form.input-text>`)
- Alpine data: camelCase variables (e.g., `x-data="{ isOpen: false }"`)
- CSS classes: Tailwind utilities first, Bootstrap for AdminLTE integration

## Output Format
```
## Created/Modified Files
- resources/views/backend/v1/{module}/{file}.blade.php — {description}

## Components Used
- <x-backend.form.input-text> — for {fields}
- <x-backend.form.select-dropdown> — for {fields}

## Notes
- {any decisions made, Alpine.js patterns used, etc.}
```
