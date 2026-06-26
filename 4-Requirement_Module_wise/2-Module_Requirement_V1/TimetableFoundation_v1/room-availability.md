# TimetableFoundation — Room Availability

## What It Does
Manages room (classroom, lab, hall) availability for timetable scheduling. Defines per-room availability ratios, marks specific unavailable slots, and tracks per-period room occupancy. Ensures rooms are not double-booked during generation.

## Tenant Admin Context
Administrators define which rooms are available for scheduling, their capacity, and any periods when rooms are unavailable (e.g., Computer Lab reserved for exams on certain days). Room types (regular classroom, science lab, computer lab, music room, sports hall) determine which activities can use which rooms.

## Database Tables Read / Written

| Table | Fields Used |
|---|---|
| `tt_room_availabilities` | `id`, `room_id`, `academic_term_id`, `is_available`, `availability_ratio` |
| `tt_room_availability_details` | `id`, `room_availability_id`, `day_of_week`, `period_ord`, `is_available` |
| `tt_slot_requirements` | `id`, `activity_id`, `room_type_id`, `preferred_room_id`, `periods_required` |

## Business Rules
1. **Availability ratio**: A room with 100% ratio is fully available. Lower ratios indicate shared rooms (e.g., a lab shared between two departments has 50% availability for each).
2. **Per-slot unavailability**: Specific day+period combinations can be blocked (e.g., Computer Lab unavailable during exam weeks).
3. **Room type matching**: Activities requiring special rooms (lab, music, sports) are matched to rooms of compatible types via `slot_requirements`.
4. **Preferred rooms**: Activities can specify a preferred room ID. The solver tries to place the activity there but may use alternatives.
5. **Double-booking prevention**: The solver's room allocation pass ensures no room is double-booked across any time slot.

## Process Flow: Room Availability Lifecycle
### Setup
1. Admin navigates to Room Availability → selects room + academic term.
2. Sets availability ratio and blocks specific slots.
3. System saves availability records.

### Slot Requirement Setup
1. Admin links activities to required room types.
2. Optionally specifies a preferred room.
3. Sets periods required with room.

### Solver Usage
1. During generation, the solver's `RoomAllocationPass` processes all activities with room requirements.
2. Available slots per room are matched against activity room requirements.
3. Double-bookings are prevented at the solver level.

## CRUD Operations
- **Create/Read/Update/Delete**: Room availability, availability details, slot requirements
- **Batch**: Generate availability from room master, copy across terms

## Permissions
- **Admin**: Full CRUD on room availability
