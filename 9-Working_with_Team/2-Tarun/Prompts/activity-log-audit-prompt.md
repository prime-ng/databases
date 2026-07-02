# Activity Log Audit — Claude AI Prompt

## Task

Scan every controller in the Prime AI application and determine whether the `activityLog()` helper function has been called inside each **mutating method**. Every controller method that creates, updates, deletes, restores, or toggles data **must** include an `activityLog()` call.

---

## Scan Scope

### Controllers to scan

All files matching: `Modules/*/app/Http/Controllers/*Controller.php`

Total: ~730 controllers across ~44 modules.

### Mutating methods to check in each controller

| Method | Must have `activityLog()`? | Typical event name |
|--------|---------------------------|-------------------|
| `store()` | Yes — log creation | `'Stored'` |
| `update()` | Yes — log changes | `'Updated'` |
| `destroy()` / `delete()` | Yes — log deletion | `'Trashed'` |
| `restore()` | Yes — log restoration | `'Restored'` |
| `forceDelete()` | Yes — log permanent delete | `'Deleted'` |
| `toggleStatus()` | Yes — log status change | `'Toggled'` or `'StatusUpdated'` |
| `bulkDelete()` / `bulkUpdate()` / `import()` / `export()` | Yes — log bulk operations | `'BulkDeleted'`, `'Imported'`, etc. |
| Any custom mutating method | Yes — if it modifies data | Context-appropriate |

### Methods that do NOT need activityLog

- `index()` — read-only listing
- `create()` — shows a form
- `edit()` — shows a form
- `show()` — read-only detail view
- Any other read-only or form-display method

---

## Reference: Correct implementation

### CityController (full implementation — all methods covered)

File: `Modules/GlobalMaster/app/Http/Controllers/CityController.php`

```php
// store()
public function store(CityRequest $request)
{
    $city = City::create($request->all());
    activityLog($city, 'Stored', ['message' => 'A new city was created.', 'other' => 'some other information']);
    return redirect()->to(...)->with('success', flash('created.city'));
}

// update() — logs before/after changes
public function update(CityRequest $request, City $city)
{
    $original = $city->getOriginal();
    $city->update($request->all());
    $changes = $city->getChanges();
    $changedAttributes = [];
    foreach ($changes as $field => $newValue) {
        if ($field === 'updated_at') continue;
        $changedAttributes[$field] = ['old' => $original[$field] ?? null, 'new' => $newValue];
    }
    if (!empty($changedAttributes)) {
        activityLog($city, 'Updated', [
            'message' => 'A new city was updated.',
            'changes' => $changedAttributes,
            'performed_by' => Auth::user()->name,
        ]);
    } else {
        activityLog($city, 'Updated', [
            'message' => 'A new city was updated. No attributes changed.',
            'performed_by' => Auth::user()->name,
        ]);
    }
    return redirect()->to(...)->with('success', flash('updated.city'));
}

// destroy()
public function destroy(string $id)
{
    $city = City::findOrFail($id);
    $city->is_active = false;
    $city->save();
    $city->delete();
    activityLog($city, 'Trashed', ['message' => 'A new city was deactivated and deleted.']);
    return redirect()->to(...)->with('success', flash('trashed.city'));
}

// restore()
public function restore($id)
{
    $city = City::withTrashed()->findOrFail($id);
    $city->restore();
    activityLog($city, 'Restored', ['message' => 'A new city was restored.']);
    return redirect()->route(...)->with('success', flash('restored.city'));
}

// forceDelete()
public function forceDelete($id)
{
    $city = City::withTrashed()->findOrFail($id);
    $city->forceDelete();
    activityLog($city, 'Deleted', ['message' => 'A new city was permanently deleted.']);
    return redirect()->route(...)->with('success', flash('force_deleted.city'));
}

// toggleStatus()
public function toggleStatus(Request $request, City $city)
{
    $city->is_active = $request->input('is_active');
    $city->save();
    activityLog($city, 'Toggled', ['message' => 'A new city status was updated.']);
    return response()->json(['success' => true, ...]);
}
```

### DistrictController (same pattern)

File: `Modules/GlobalMaster/app/Http/Controllers/DistrictController.php`

Follows the identical pattern as CityController above — `activityLog()` in `store()`, `update()`, `destroy()`, `restore()`, `forceDelete()`, and `toggleStatus()`.

---

## Output Format

For each module, produce a report table:

### Module: `<ModuleName>`

| Controller | store | update | destroy | restore | forceDelete | toggleStatus | Other mutating methods |
|------------|-------|--------|---------|---------|-------------|--------------|------------------------|
| FooController | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | bulkDelete: ❌ |
| BarController | ❌ | ❌ | ❌ | N/A | N/A | ❌ | — |
| BazController | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | — |

**Legend:** ✅ = has activityLog, ❌ = missing, N/A = method does not exist

### Summary per module
- Total controllers:
- Fully compliant (all methods covered):
- Partially compliant:
- Missing entirely:
- Total missing `activityLog()` calls:

---

## Rules

1. **Do NOT modify any files.** This is a read-only audit.
2. For controllers that extend a base controller with shared CRUD, check the child controller first — if it overrides the method, it needs activityLog. If it inherits without override, note it.
3. Ignore `index()`, `create()`, `edit()`, `show()` — these are read-only.
4. If a controller has a custom method name for a mutating operation (e.g. `approveApplication`, `markAsPaid`, `cancelOrder`), flag it as "Other" and check if it has activityLog.
5. Note any controllers where activityLog is partially present (some methods have it, some don't).
6. Provide the full file path for every controller flagged as missing activityLog.

---

## Current Stats (for reference)

- Total controllers: ~730
- Controllers with at least one activityLog call: ~365
- Controllers with zero activityLog calls: ~365

---

## Priority

This audit is for a multi-tenant K-12 school ERP/LMS/LXP platform. Every data mutation must be traceable for compliance, debugging, and security auditing. Missing activityLog calls are a security/compliance gap.
