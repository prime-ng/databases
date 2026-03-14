<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TimetableController;

/*
|--------------------------------------------------------------------------
| Timetable Module API Routes
|--------------------------------------------------------------------------
|
| These routes are for the Timetable Generator functionality.
| All routes are prefixed with 'api/timetable' and require authentication.
|
*/

// Generation Management Routes
Route::prefix('generation')->group(function () {

    // Start a new timetable generation
    Route::post('/start', [TimetableController::class, 'startGeneration'])
        ->name('timetable.generation.start');

    // Execute generation (typically called by background job)
    Route::post('/{runId}/execute', [TimetableController::class, 'executeGeneration'])
        ->name('timetable.generation.execute');

    // Get generation status
    Route::get('/{runId}/status', [TimetableController::class, 'getGenerationStatus'])
        ->name('timetable.generation.status');

    // List generation runs with filtering
    Route::get('/', [TimetableController::class, 'getGenerationRuns'])
        ->name('timetable.generation.list');

    // Cancel a generation run
    Route::post('/{runId}/cancel', [TimetableController::class, 'cancelGeneration'])
        ->name('timetable.generation.cancel');

    // Delete a generation run
    Route::delete('/{runId}', [TimetableController::class, 'deleteGeneration'])
        ->name('timetable.generation.delete');
});

// Timetable Data Routes
Route::prefix('data')->group(function () {

    // Get generated timetable for a specific run
    Route::get('/generation/{runId}', [TimetableController::class, 'getGeneratedTimetable'])
        ->name('timetable.data.generation');

    // Get timetable for a specific class
    Route::get('/class/{classId}', [TimetableController::class, 'getClassTimetable'])
        ->name('timetable.data.class');

    // Get timetable for a specific teacher
    Route::get('/teacher/{teacherId}', [TimetableController::class, 'getTeacherTimetable'])
        ->name('timetable.data.teacher');
});

// Statistics and Analytics Routes
Route::prefix('stats')->group(function () {

    // Get timetable statistics
    Route::get('/', [TimetableController::class, 'getTimetableStats'])
        ->name('timetable.stats.general');
});

// Constraint Management Routes (if needed for dynamic constraints)
Route::prefix('constraints')->group(function () {

    // These would be implemented if we need to manage constraints via API
    // Route::get('/', [ConstraintController::class, 'index']);
    // Route::post('/', [ConstraintController::class, 'store']);
    // Route::put('/{id}', [ConstraintController::class, 'update']);
    // Route::delete('/{id}', [ConstraintController::class, 'delete']);
});

// Utility Routes for Development/Testing
if (app()->environment('local')) {
    Route::prefix('dev')->group(function () {

        // Clear all timetable data for a generation run (development only)
        Route::delete('/generation/{runId}/clear', function ($runId) {
            $cells = \App\Models\TimetableCell::where('generation_run_id', $runId)->get();
            foreach ($cells as $cell) {
                $cell->teachers()->delete();
                $cell->delete();
            }

            \App\Models\GenerationRun::find($runId)->update([
                'status' => 'CLEARED',
                'finished_at' => now()
            ]);

            return response()->json(['success' => true, 'message' => 'Generation data cleared']);
        })->name('timetable.dev.clear');
    });
}