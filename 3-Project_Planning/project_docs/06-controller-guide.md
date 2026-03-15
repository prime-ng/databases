# Controller Guide

## Controller Location — Universal Rule

```
Modules/<ModuleName>/app/Http/Controllers/<ControllerName>.php
```

## Namespace Pattern

```php
namespace Modules\<ModuleName>\Http\Controllers;
```

## Base Class

```php
use App\Http\Controllers\Controller;

class LearningOutcomesController extends Controller
```

## Standard CRUD Controller Template

```php
<?php

namespace Modules\Hpc\Http\Controllers;

use App\Http\Controllers\Controller;
use Modules\Hpc\Models\LearningOutcomes;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class LearningOutcomesController extends Controller
{
    public function index()
    {
        Gate::authorize('tenant.learning-outcomes.viewAny');
        $outcomes = LearningOutcomes::where('is_active', true)->paginate(15);
        return view('hpc::learning-outcomes.index', compact('outcomes'));
    }

    public function create()
    {
        Gate::authorize('tenant.learning-outcomes.create');
        return view('hpc::learning-outcomes.create');
    }

    public function store(Request $request)
    {
        Gate::authorize('tenant.learning-outcomes.create');
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'hpc_parameter_id' => 'required|exists:hpc_parameters,id',
        ]);
        $validated['created_by'] = auth()->id();
        LearningOutcomes::create($validated);
        activityLog(null, 'Create', 'Learning Outcome created');
        return redirect()->route('hpc.learning-outcomes.index')
            ->with('success', 'Created successfully.');
    }

    public function show(LearningOutcomes $learningOutcome)
    {
        Gate::authorize('tenant.learning-outcomes.view');
        return view('hpc::learning-outcomes.show', compact('learningOutcome'));
    }

    public function edit(LearningOutcomes $learningOutcome)
    {
        Gate::authorize('tenant.learning-outcomes.update');
        return view('hpc::learning-outcomes.edit', compact('learningOutcome'));
    }

    public function update(Request $request, LearningOutcomes $learningOutcome)
    {
        Gate::authorize('tenant.learning-outcomes.update');
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
        ]);
        $learningOutcome->update($validated);
        activityLog($learningOutcome, 'Update', 'Learning Outcome updated');
        return redirect()->route('hpc.learning-outcomes.index')
            ->with('success', 'Updated successfully.');
    }

    public function destroy(LearningOutcomes $learningOutcome)
    {
        Gate::authorize('tenant.learning-outcomes.delete');
        activityLog($learningOutcome, 'Delete', 'Learning Outcome deleted');
        $learningOutcome->delete(); // soft delete
        return redirect()->route('hpc.learning-outcomes.index')
            ->with('success', 'Deleted successfully.');
    }

    public function trashed()
    {
        Gate::authorize('tenant.learning-outcomes.viewAny');
        $outcomes = LearningOutcomes::onlyTrashed()->paginate(15);
        return view('hpc::learning-outcomes.trashed', compact('outcomes'));
    }

    public function restore($id)
    {
        Gate::authorize('tenant.learning-outcomes.restore');
        LearningOutcomes::withTrashed()->findOrFail($id)->restore();
        return redirect()->route('hpc.learning-outcomes.trashed')
            ->with('success', 'Restored successfully.');
    }

    public function forceDelete($id)
    {
        Gate::authorize('tenant.learning-outcomes.forceDelete');
        LearningOutcomes::withTrashed()->findOrFail($id)->forceDelete();
        return redirect()->route('hpc.learning-outcomes.trashed')
            ->with('success', 'Permanently deleted.');
    }

    public function toggleStatus(LearningOutcomes $learningOutcome)
    {
        Gate::authorize('tenant.learning-outcomes.update');
        $learningOutcome->is_active = !$learningOutcome->is_active;
        $learningOutcome->save();
        return redirect()->back()->with('success', 'Status updated.');
    }
}
```

## View Return Pattern

```php
// Pattern: '<lowercase-modulename>::<folder>.<file>'
return view('hpc::learning-outcomes.index', compact('data'));
return view('schoolsetup::school-class.index', compact('classes'));
return view('smarttimetable::activity.index', compact('activities'));
return view('prime::tenant.index', compact('tenants'));
return view('billing::billing-management.index', compact('invoices'));
```

## Create via Artisan

```bash
php artisan module:make-controller <ControllerName> <ModuleName>
# Example:
php artisan module:make-controller LearningOutcomesController Hpc
# File created at: Modules/Hpc/app/Http/Controllers/LearningOutcomesController.php
```

## Controller Counts per Module

```
SchoolSetup     -> 34 controllers
Transport       -> 31 controllers
SmartTimetable  -> 27 controllers
Library         -> 26 controllers
Prime           -> 22 controllers
GlobalMaster    -> 15 controllers
Hpc             -> 15 controllers
StudentFee      -> 15 controllers
Syllabus        -> 15 controllers
Notification    -> 12 controllers
LmsExam         -> 11 controllers
Recommendation  -> 10 controllers
Complaint       -> 8 controllers
QuestionBank    -> 7 controllers
Vendor          -> 7 controllers
Billing         -> 6 controllers
LmsQuiz         -> 5 controllers
StudentProfile  -> 5 controllers
LmsHomework     -> 5 controllers
SyllabusBooks   -> 4 controllers
Payment         -> 4 controllers
LmsQuests       -> 4 controllers
StudentPortal   -> 3 controllers
Documentation   -> 3 controllers
SystemConfig    -> 3 controllers
Dashboard       -> 1 controller
Scheduler       -> 1 controller
```

## Critical Rules

1. **Gate::authorize()** as FIRST line of every public method
2. Use `$request->validate()` or FormRequest — NEVER `$request->all()`
3. Always call `activityLog()` on create/update/delete
4. Use `->paginate(15)` — NEVER `::all()` or unbounded `::get()`
5. Use `DB::transaction()` for multi-table writes
