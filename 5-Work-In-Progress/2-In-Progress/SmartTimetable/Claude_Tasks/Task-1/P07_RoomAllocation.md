# P07 — Room Allocation

**Phase:** 5 | **Priority:** P1 | **Effort:** 3 days
**Skill:** Backend + Frontend | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** P01 (bug fixes)
**Reference:** `2026Mar10_ActivityConstraints_Integration_Plan.md` Section 6

---

## Pre-Requisites

Read these files before starting:
1. `Modules/SmartTimetable/app/Services/RoomAllocationPass.php` — existing skeleton
2. `Modules/SmartTimetable/app/Services/RoomAvailabilityService.php` — existing service
3. `Modules/SmartTimetable/app/Models/Activity.php` — check room-related fields: `required_room_type_id`, `preferred_room_ids`, `required_room_id`
4. `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` — `generateWithFET()` method
5. `Modules/SmartTimetable/app/Services/Storage/TimetableStorageService.php` — understand storage format

---

## Task 5.1 — Implement RoomAllocationPass service (4 hrs)

**File:** `Modules/SmartTimetable/app/Services/RoomAllocationPass.php`

Read the existing skeleton first. Implement the following logic:

```php
<?php

namespace Modules\SmartTimetable\Services;

use Modules\SmartTimetable\Models\Activity;
use Modules\SchoolSetup\Models\Room;
use Illuminate\Support\Collection;

class RoomAllocationPass
{
    protected array $roomOccupied = []; // dayId_periodIndex => [roomId => true]
    protected array $allocationReport = [
        'assigned' => 0,
        'unassigned' => 0,
        'conflicts' => [],
    ];

    /**
     * Allocate rooms to placed activities.
     *
     * @param Collection $entries TimetableCell entries (with activity, day_id, period_index)
     * @param Collection $rooms Available rooms
     * @return array ['entries' => updated entries, 'report' => allocation report]
     */
    public function allocate(Collection $entries, Collection $rooms): array
    {
        // Sort by priority: activities with specific room requirements first
        $sorted = $entries->sortBy(function ($entry) {
            if ($entry->activity->required_room_id) return 0;      // Fixed room
            if ($entry->activity->required_room_type_id) return 1;  // Type required
            if ($entry->activity->preferred_room_ids) return 2;     // Has preferences
            return 3;                                                 // No preference
        });

        foreach ($sorted as $entry) {
            $room = $this->findBestRoom($entry, $rooms);
            if ($room) {
                $entry->room_id = $room->id;
                $slotKey = "{$entry->day_id}_{$entry->period_index}";

                // Mark room as occupied for all periods of multi-period activity
                $duration = $entry->activity->duration ?? 1;
                for ($i = 0; $i < $duration; $i++) {
                    $key = "{$entry->day_id}_" . ($entry->period_index + $i);
                    $this->roomOccupied[$key][$room->id] = true;
                }

                $this->allocationReport['assigned']++;
            } else {
                $this->allocationReport['unassigned']++;
                $this->allocationReport['conflicts'][] = [
                    'activity_id' => $entry->activity_id,
                    'activity_name' => $entry->activity->name ?? 'Unknown',
                    'day_id' => $entry->day_id,
                    'period_index' => $entry->period_index,
                    'reason' => 'No suitable room found',
                ];
            }
        }

        return [
            'entries' => $entries,
            'report' => $this->allocationReport,
        ];
    }

    protected function findBestRoom($entry, Collection $rooms): ?Room
    {
        $activity = $entry->activity;
        $slotKey = "{$entry->day_id}_{$entry->period_index}";

        // 1. Fixed room assignment
        if ($activity->required_room_id) {
            $room = $rooms->firstWhere('id', $activity->required_room_id);
            if ($room && !$this->isRoomOccupied($room->id, $entry->day_id, $entry->period_index, $activity->duration ?? 1)) {
                return $room;
            }
            return null; // Fixed room not available
        }

        // 2. Filter by room type
        $candidates = $rooms;
        if ($activity->required_room_type_id) {
            $candidates = $candidates->where('room_type_id', $activity->required_room_type_id);
        }

        // 3. Filter out occupied rooms
        $candidates = $candidates->filter(function ($room) use ($entry, $activity) {
            return !$this->isRoomOccupied($room->id, $entry->day_id, $entry->period_index, $activity->duration ?? 1);
        });

        if ($candidates->isEmpty()) return null;

        // 4. Score candidates
        $preferredIds = $activity->preferred_room_ids
            ? (is_array($activity->preferred_room_ids) ? $activity->preferred_room_ids : json_decode($activity->preferred_room_ids, true))
            : [];

        if (!empty($preferredIds)) {
            $preferred = $candidates->whereIn('id', $preferredIds)->first();
            if ($preferred) return $preferred;
        }

        // 5. Fallback: first available
        return $candidates->first();
    }

    protected function isRoomOccupied(int $roomId, int $dayId, int $periodIndex, int $duration): bool
    {
        for ($i = 0; $i < $duration; $i++) {
            $key = "{$dayId}_" . ($periodIndex + $i);
            if (isset($this->roomOccupied[$key][$roomId])) {
                return true;
            }
        }
        return false;
    }

    public function getReport(): array
    {
        return $this->allocationReport;
    }
}
```

---

## Task 5.2 — Wire RoomAllocationPass into generateWithFET() (30 min)

**File:** `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php`
**Method:** `generateWithFET()`

**Change:** After solver produces entries but BEFORE storage, call RoomAllocationPass:

```php
// After: $entries = $solver->solve();
// Before: TimetableStorageService::storeGeneratedTimetable($entries);

// Room allocation
$rooms = Room::where('is_active', true)->get();
$roomAllocator = new RoomAllocationPass();
$result = $roomAllocator->allocate(collect($entries), $rooms);
$entries = $result['entries'];
$roomReport = $result['report'];

// Store room allocation report in session for display
session(['room_allocation_report' => $roomReport]);

if ($roomReport['unassigned'] > 0) {
    \Log::warning("Room allocation: {$roomReport['unassigned']} activities without rooms", $roomReport['conflicts']);
}

// Then proceed to storage
```

Add import: `use Modules\SmartTimetable\Services\RoomAllocationPass;`

---

## Task 5.3 — Show room assignments in timetable views (1 day)

**Skill: Frontend**

**Files:** Timetable preview/display Blade views in `Modules/SmartTimetable/resources/views/`

Find the timetable grid views (likely in `generate-timetable/`, `timetable/`, or partials).

**Change:** In each cell that displays subject/teacher, also display the room name:

```blade
{{-- Existing cell content --}}
<div class="tt-cell">
    <span class="subject">{{ $cell->activity->subject->name ?? '' }}</span>
    <span class="teacher">{{ $cell->activity->teacher->short_name ?? '' }}</span>
    @if($cell->room)
        <span class="room text-muted small">{{ $cell->room->name }}</span>
    @endif
</div>
```

Add CSS for room display:
```css
.tt-cell .room {
    font-size: 0.75em;
    color: #6c757d;
    display: block;
}
```

Also show the room allocation report on the preview/results page:
```blade
@if(session('room_allocation_report'))
    @php $roomReport = session('room_allocation_report'); @endphp
    <div class="alert alert-info">
        <strong>Room Allocation:</strong>
        {{ $roomReport['assigned'] }} assigned,
        {{ $roomReport['unassigned'] }} unassigned
        @if($roomReport['unassigned'] > 0)
            <ul class="mt-1 mb-0">
                @foreach($roomReport['conflicts'] as $conflict)
                    <li>{{ $conflict['activity_name'] }} — {{ $conflict['reason'] }}</li>
                @endforeach
            </ul>
        @endif
    </div>
@endif
```

---

## Task 5.4 — Room conflict detection (4 hrs)

**File:** `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php`
**Location:** In the post-generation verification section (where parallel violations are already checked)

**Change:** Add room double-booking detection alongside the existing parallel violation check:

```php
// After parallel violation check, add:
$roomConflicts = [];
$roomSlots = []; // dayId_periodIndex => roomId

foreach ($storedCells as $cell) {
    if (!$cell->room_id) continue;

    $duration = $cell->activity->duration ?? 1;
    for ($i = 0; $i < $duration; $i++) {
        $key = "{$cell->day_id}_" . ($cell->period_index + $i);

        if (isset($roomSlots[$key]) && $roomSlots[$key] === $cell->room_id) {
            $roomConflicts[] = [
                'room_id' => $cell->room_id,
                'room_name' => $cell->room->name ?? 'Unknown',
                'day_id' => $cell->day_id,
                'period_index' => $cell->period_index + $i,
                'conflicting_activities' => [$cell->activity_id],
            ];
        }
        $roomSlots[$key] = $cell->room_id;
    }
}

if (!empty($roomConflicts)) {
    session(['room_conflicts' => $roomConflicts]);
    \Log::warning('Room double-booking detected', ['conflicts' => $roomConflicts]);
}
```

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/` — all files pass
2. Run: `/test SmartTimetable` — all tests pass
3. Verify RoomAllocationPass is importable: `php artisan tinker --execute="new Modules\SmartTimetable\Services\RoomAllocationPass();"`
4. Update AI Brain:
   - `known-issues.md` → Mark GAP-3 (room allocation) as RESOLVED
   - `progress.md` → Phase 5 done
