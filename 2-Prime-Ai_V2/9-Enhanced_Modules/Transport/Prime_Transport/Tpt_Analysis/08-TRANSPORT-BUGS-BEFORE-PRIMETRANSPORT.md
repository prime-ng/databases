# 08 — Bugs in the base Transport module worth fixing before PrimeTransport (2026-10-23)

This was a static read of the code paths PrimeTransport will depend on: trips, stops, allocations, fees and the scheduler.
Each bug was confirmed by reading the code. B2 was also confirmed by running Carbon 3.11.4 (installed version).
**REPORT ONLY: Tarun decided on 2026-10-23 that no code changes are made from this file; it records the issues.** Paths are relative to `prime_ai/Modules/Transport/`.

**Why fix these first:**
- PrimeTransport learns from Transport's data: km and fuel per trip, actual stop times, students per stop, money per route.
- B3, B4, B5, B6 and B7 make that data wrong, and the engine would then optimise on garbage.
- B1 and B2 are serious on their own.

| # | Severity | Bug (simple words) | Where |
|---|---|---|---|
| B1 | 🔴 Critical | Collecting a transport fee can **deactivate the student in the whole ERP** | `FeeCollectionController.php:99-106` |
| B2 | 🔴 High | **Late fines never apply on the web** (delay days come out negative) | `FeeCollectionController.php:73-75` |
| B3 | 🔴 High | Allocation **import picks the wrong student** (matches by roll number only) | `Imports/StudentAllocationImport.php:20`, `StudentAllocationController.php:~446` |
| B4 | 🔴 High | **Web trip start/end saves nothing** (status, times, odometer, fuel) | `resources/views/js/js.blade.php:92-101` vs `TripController.php:~221, ~287` |
| B5 | 🟠 High | Mobile trip start/end writes **odometer/fuel = 0** when blank | `Services/MobileTripService.php:250-251, 314-315` |
| B6 | 🟠 Medium | New allocation is linked to the student's **first** academic year, not the current one | `StudentAllocationController.php:82, 95` |
| B7 | 🟠 Medium | Seat counter (`total_students`) **drifts**, so the "capacity full" check is wrong | `StudentAllocationController.php:151, 551-557`, import |
| B8 | 🟡 Medium | Trip state not enforced (end a trip that never started, mark stops on a finished trip) | `MobileTripService.php` start/end/reach/leave, `TripController::stopAction` |
| B9 | 🟡 Medium | Mobile fee collection always saves **"Paid" + reconciled**, even for a part payment | `Services/MobileStudentFeeService.php:~291-300` |
| B10 | 🟡 Medium | Web "Delayed" check uses the date the stop list was **prepared**, not the trip date | `TripController.php:~236` with `stopDetailsPrepare` |
| B11 | 🟡 Medium | "Bus approaching" is logged for the stop the bus **just left** | `MobileTripService::leaveStop`, `TripController` `leave` |
| B12 | 🟡 Medium | Daily expiry check runs **without a tenant** and only writes a log line | `Console/CheckTransportExpiries.php` |
| — | (already in plan 07 as T3, T6, T7) | Bangalore default coordinates; fake parent notifications; broken `TptTripIncidents` relations; dead `TptFeeCollection` model | see 06 §4 |

---

## B1 — Paying a late fee can switch the student off everywhere 🔴
```php
if ((isset($fineMaster)) && ($fineMaster->student_restricted == 1)) {
    $student = $feeMaster->academicSession->student;
    $student->update(['is_active' => 0]);   // std_students — the whole ERP
}
```
**Example:**
1. Fine rule "31–60 days late, restrict student" exists.
2. Riya's parent pays the October bus fee. The clerk picks that fine rule in the form.
3. Riya's **`std_students.is_active` becomes 0**. She disappears from class attendance, exams, the LMS and the parent app, not just the bus.
4. The check sits **outside** the "is the payment actually late?" test, so it fires even if she paid on time.

**Fix:** never touch `std_students` from Transport. What "restricted" should do is still open.

**Read-only DB check, 2026-10-23.** The only registered local tenant is `xyz_school_00000000000040008000_202627` (test.localhost). Results:

| Check | Result |
|---|---|
| Fine rules with `student_restricted = 1` | **100** (seeded) |
| Fine-detail rows on a restricted rule | 13 rows, 9 students. All created at the same second (2026-10-22 20:36:24), i.e. **by a seeder, not by the fee screen** |
| Those 9 students' `is_active` | all still **1** |
| Students with `is_active = 0` (whole table) | 0 |
| Fee collections with negative `total_delay_days` (B2) | 0 of 80 (all seeded) |

**Conclusion:** no student has been switched off yet in this database. But with 100 restricted rules seeded, the **first web fee collection** that picks one of them will do it. Production/VPS tenants were not checked.

## B2 — Late fines never apply on the web 🔴
`$paymentDate->diffInDays($dueDate)`: in Carbon 3, the result is signed. Tested: payment 20 Oct, due 10 Oct → **-10**.
- `fine_from_days ≤ -10` is never true, so **no fine** is applied.
- `total_delay_days` is saved as **-10**.
- The mobile app computes it the other way round (`due->diffInDays(payment)` = +10) and fines correctly. **The same payment gives a different fine on web vs mobile.**

**Fix:** `$dueDate->diffInDays($paymentDate)`. Separately, review existing rows with negative `total_delay_days`.

## B3 — Allocation import picks the wrong student 🔴
`StudentAcademicSession::where('roll_no', $roll)->first()`.
- Roll numbers repeat in **every class, every section and every year**.

**Example:** the import row "Roll 12, Route R5" is given to whichever student has roll 12 first in the table, probably a class 1-A student from an old year, not the class 7-B student intended.

**More problems in the same import:**
- The validator **rejects a file that has roll 12 twice**, so a real school file (roll 12 in many classes) can't be imported at all.
- For "Both", it puts the **same route** as pickup and drop, but routes are one direction only (`pickup_drop` = Pickup or Drop).
- It never updates the seat counter (B7).
- Rows with any missing value are silently skipped.

**Fix:**
- Match by admission number, or by class + section + roll + **current** session.
- Take separate pickup and drop route codes.
- Report skipped rows instead of silently dropping them.

## B4 — Starting or ending a trip on the web saves nothing 🔴
The page JS sends the popup values as **`remark`**:
```js
data: { id, action, remark: extraData }
```
The controller only saves when **`extra`** is present:
```php
if ($request->filled('extra')) { $trip->update([... 'status' => 'Ongoing' ...]); }
```

**Result:** every trip run from **Trip Management → Stop Status Update**:
- stays **"Scheduled"** forever
- has no start time, end time, odometer or fuel

The dashboard "ongoing/completed trips" counts, the trip reports and fuel efficiency are therefore all wrong.

**Second bug in the same popup:** it pre-fills the time with `new Date().toISOString()`, which is **UTC**. In India the time shows **5½ hours early**. If the clerk doesn't notice, the wrong time gets saved once B4 is fixed.

**Fix:** send `extra`, or read `remark` for these actions. Pre-fill local time.

## B5 — Mobile app writes odometer/fuel = 0 🟠
`'start_odometer_reading' => $request->input('start_odometer', 0)`; the same for end and fuel.
- **Example:** the driver taps "End trip" without typing the odometer. End = 0, start = 45,210, so trip km = **-45,210**.
- There is also no check that end ≥ start.

**Fix:** keep the old value when blank (or require it), and validate `end ≥ start`.

## B6 — New allocation linked to the wrong academic year 🟠
`StudentAcademicSession::where('student_id', …)->first()` takes the **oldest** session row, not `is_current = 1`.
- **Example:** a class-8 student who joined in class 5 gets an allocation tied to the class-5 year. Reports and fee screens filtered by the current year don't show them.
- If the student has no session row at all, `student_session_id` becomes `""`, which causes a DB error and a raw SQL message on screen.

## B7 — Seat counter drifts 🟠
`tpt_driver_route_vehicle_jnt.total_students` is a stored counter:
- **On create:** +1 on the pickup route (or on the drop route for Drop-only).
- **On delete:** −1, but only looked up via `pickup_route_id`, so **Drop-only students are never subtracted**.
- **Never adjusted:** on route change (update), on/off toggle, restore, or import.

**Example:** after one import of 400 students, the counter still says 0, so the "vehicle capacity exceeded" check lets a 40-seat bus take unlimited students.

**Fix:** count live allocations instead of keeping a counter, or recompute the counter in one place.

## B8 — Trip state not enforced 🟡
- "End trip" works on a trip that was never started.
- "Reach" and "Leave" work on a Completed or Cancelled trip.

These produce impossible trip timelines, which corrupt the learned ETAs.

## B9 — Mobile fee: part payment saved as fully paid 🟡
Mobile collection hard-codes `'status' => 'Paid', 'reconciled' => 1`.
**Example:** a parent pays ₹500 of ₹1,450. The app shows "Paid" and reconciled, and the balance is lost.

## B10 — Web "Delayed" uses the wrong date 🟡
Scheduled stop times are saved from `'H:i:s'` through a `datetime` cast, so they get **the date the stop list was prepared**.
- The web `reach` compares `now` with that full datetime.
- If the list was prepared the day before, **every stop is "Delayed"**.
- The mobile path compares time-of-day only and is correct.

## B11 — "Approaching" sent for the wrong stop 🟡
On "Leave stop A", the log says *ApproachingStop* for **stop A**. It should be the **next** stop (B), whose parents need the alert. This only matters once real notifications go out (plan T7), but fix it then.

## B12 — Expiry check: wrong database, no alert 🟡
The daily `transport:check-expiries` never initialises tenancy, so it queries the central DB. Even when it finds something, it only writes to the log.
**Fix:** loop over tenants and send a notification to the transport incharge.

---

## Suggested order
1. **B1** (after your decision on Q1) and **B2**: money and student data, highest harm.
2. **B4, B5, B8, B10**: trip data; PrimeTransport's ETAs and costs depend on it.
3. **B3, B6, B7**: allocation data; PrimeTransport's demand per stop depends on it.
4. **B9, B11, B12**: smaller.

If and when these are fixed: every fix is local to Transport (no schema change, except possibly for B7). Each gets a small feature test, because these are money and trip paths, and each diff is shown for approval before it is applied.
