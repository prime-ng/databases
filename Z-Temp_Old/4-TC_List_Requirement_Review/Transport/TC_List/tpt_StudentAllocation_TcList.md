# Student Allocation — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Transport (TPT) |
| **Tab Group** | Student Route Fees Mgmt → Student Allocation |
| **Feature** | Student Route Allocation — assign students to transport routes with pickup/drop stops |
| **URL(s)** | `/transport/student-allocation` (index via tab `stdtransport`), `/transport/student-allocation/create`, `/transport/student-allocation/{id}`, `/transport/student-allocation/{id}/edit`, `/transport/student-allocation/trash`, `/transport/student-allocation/{id}/restore`, `/transport/student-allocation/{id}/force-delete`, `/transport/student-allocation-get-sections/{classId}`, `/transport/student-allocation-get-students`, `/transport/student-allocation/validate-file`, `/transport/student-allocation/start-import`, `/transport/student-allocation/export` |
| **Controller** | `Modules\Transport\Http\Controllers\StudentAllocationController` — 14 methods: index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus, export, getSections, getStudents |
| **Model** | `Modules\Transport\Models\TptStudentAllocationJnt` — SoftDeletes, 11 relationships, 10 fillable fields, 3 casts, 1 scope |
| **Validation** | `Modules\Transport\Http\Requests\StudentAllocationRequest` — 8 field rules + prepareForValidation + custom messages |
| **Permissions** | `tenant.student-allocation.*` — not used; actual Policy uses `tenant.transport.*` (viewAny, view, create, update, delete, restore, forceDelete) |
| **Soft Deletes** | Yes (`SoftDeletes` trait on model, `deleted_at` column in migration) |
| **Activity Log** | Events: `Created`, `Updated`, `Trash`, `Restored`, `Force Delete`, `Toggled` |
| **DB Table** | `tpt_student_route_allocation_jnt` — 12 columns (id, student_id, transport_use_type, fare, effective_from, active_status, timestamps, student_session_id, pickup_route_id, pickup_stop_id, drop_route_id, drop_stop_id, deleted_at), 5 FK RESTRICT |
| **Key Features** | Excel import/export, vehicle capacity check, RemoteEntryService integration, AJAX student/section loading, transport_use_type (Pickup/Drop/Both) with conditional UI, auto-fare calculation from stop data |
| **Policy Bug** | Policy checks `tenant.transport.*` permissions but Blade/controller use `tenant.student-allocation.*` — **MISMATCH** |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must have `tenant.transport.*` permissions (Policy) OR `tenant.student-allocation.*` (Blade/controller Gates) — **inconsistent** |
| PC-02 | At least one active Route (`tpt_route`) must exist (FK `fk_sa_pickupRoute` / `fk_sa_dropRoute`, both RESTRICT) |
| PC-03 | At least one PickupPointRoute (`tpt_pickup_points_route_jnt`) with `pickup_drop IN ('Pickup','Both')` AND `is_active=1` must exist |
| PC-04 | At least one Drop point with `pickup_drop IN ('Drop','Both')` AND `is_active=1` must exist |
| PC-05 | Students must have active academic session entries (`std_student_academic_sessions` with `is_current=1`) |
| PC-06 | `DriverRouteVehicleJnt` must have active route–vehicle assignment for the selected route (`is_active=1`) |
| PC-07 | Setting `allow_extra_student_in_vehicale_beyond_capacity` must be configured in `sys_settings` |
| PC-08 | Tab id `stdtransport-pane` registered in std-route-Fees-mgmt index |
| PC-09 | `Tenant\Modules\Accounting\Services\RemoteEntryService` must be available if accounting integration is used |
| PC-10 | `SchoolClass::active()` must return valid classes for cascade dropdown |
| PC-11 | `ClassSection` records must exist linked to `SchoolClass` via `class_id` |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Allocation list loaded via `StudentAllocationQuery()` in `StudentRouteFeesController` | `StudentRouteFeesController.php:48` |
| DL-02 | Table columns: Roll No, Student Name, Class, Route, Type (badge), Pickup, Drop, Status (toggle switch), Action | `student-allocation/index.blade.php:77-91` |
| DL-03 | Status badge via bootstrap: Both=primary, Pickup=info, Drop=warning | `student-allocation/index.blade.php:105-113` |
| DL-04 | Pickup shows `ON LEAVE` fallback, Drop shows `N/A` when type=Pickup | `student-allocation/index.blade.php:116-118` |
| DL-05 | Status toggle via AJAX POST to `toggleStatus()` | `student-allocation/index.blade.php:119-131` |
| DL-06 | Filters: Route, Class, Status (Active/Inactive), Transport Type | `student-allocation/index.blade.php:7-39` |
| DL-07 | Import/Export buttons visible to users with `tenant.student-allocation.import`/`export` permissions | `student-allocation/index.blade.php:50-69` |
| DL-08 | Create form has cascading dropdowns: Class → Section → Student (AJAX) | `student-allocation/js/js.blade.php:150-200` |
| DL-09 | Create form auto-calculates fare from pickup/drop data-attributes | `student-allocation/js/js.blade.php:99-132` |
| DL-10 | Edit form pre-selects current allocation values and loads relations | `StudentAllocationController.php:191-218` |
| DL-11 | Trash page paginated at 20 records | `StudentAllocationController.php:302-304` |
| DL-12 | Index paginated at 10 records | `StudentRouteFeesController.php:48` |
| DL-13 | Filter by route_id checks `pickup_route_id` only (not drop_route_id) | `StudentRouteFeesController.php:470-472` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Both allocation** | transport_use_type=Both, student=valid, pickup_route=valid, pickup_stop=valid, drop_route=valid, drop_stop=valid, fare=500, effective_from=today |
| TD-02 | **Pickup Only allocation** | type=Pickup → drop_route/drop_stop nullified automatically |
| TD-03 | **Drop Only allocation** | type=Drop → pickup_route/pickup_stop nullified automatically |
| TD-04 | **Capacity at limit** | total_students == capacity (or max_capacity if allow_extra) → rejection |
| TD-05 | **Capacity under limit** | total_students < capacity → success |
| TD-06 | **No active vehicle on route** | route exists but no DriverRouteVehicleJnt.is_active=1 → validation error |
| TD-07 | **Student already allocated** | student_session_id already exists → Excel import checks it (but store does NOT) |
| TD-08 | **Past effective date** | effective_from < today → validation error on create only |
| TD-09 | **Student with no academic session** | student_id exists but no `std_student_academic_sessions` record → student_session_id = "" |
| TD-10 | **toggleStatus edge: is_active=0, FILTER_VALIDATE_BOOLEAN** | Input "0" → false; Input "false" → false; Input "" → false; Input "1" → true |
| TD-11 | **Import file: xlsx with mixed errors** | 5 valid rows + 3 error rows → error report generated |
| TD-12 | **Import file: all valid** | All rows pass → file stored, ready for startImport() |
| TD-13 | **Student already allocated (import check gap)** | When checking existing allocation, code uses `$studentSession->student_id` instead of `$studentSession->id` (student_session_id) → **BUG** |
| TD-14 | **Import with 'both_side' type** | Import maps 'both side' → fillable field 'both_side' → but model ENUM only accepts 'Both','Drop','Pickup' → **BUG** |
| TD-15 | **Import with 'pick_up' type** | Import maps 'pick up' → 'pick_up' → but ENUM expects 'Pickup' → **BUG** |
| TD-16 | **Import route_id mapping** | Import uses `'route_id' => $route->id` but fillable does NOT include `route_id` → **BUG** |
| TD-17 | **Import student_session_id mapping** | Import sets `student_session_id => $studentSession->student_id` (wrong — should be session id, not student id) → **BUG** |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| BC ID | Column | Type (Migration) | Constraints |
|-------|--------|------------------|-------------|
| BC-DB-01 | `id` | INT UNSIGNED AUTO_INCREMENT | PK |
| BC-DB-02 | `student_id` | INT UNSIGNED | NOT NULL |
| BC-DB-03 | `transport_use_type` | ENUM('Both','Drop','Pickup') | NOT NULL |
| BC-DB-04 | `fare` | DECIMAL(10,2) | NOT NULL |
| BC-DB-05 | `effective_from` | DATE | NOT NULL |
| BC-DB-06 | `active_status` | BOOLEAN | DEFAULT true |
| BC-DB-07 | `student_session_id` | INT UNSIGNED | FK → `std_student_academic_sessions.id` (`fk_sa_studentSession`) |
| BC-DB-08 | `pickup_route_id` | INT UNSIGNED NULLABLE | FK → `tpt_route.id` (`fk_sa_pickupRoute`) RESTRICT |
| BC-DB-09 | `pickup_stop_id` | INT UNSIGNED NULLABLE | FK → `tpt_pickup_points.id` (`fk_sa_pickup`) RESTRICT |
| BC-DB-10 | `drop_route_id` | INT UNSIGNED NULLABLE | FK → `tpt_route.id` (`fk_sa_dropRoute`) RESTRICT |
| BC-DB-11 | `drop_stop_id` | INT UNSIGNED NULLABLE | FK → `tpt_pickup_points.id` (`fk_sa_drop`) RESTRICT |
| BC-DB-12 | `deleted_at` | TIMESTAMP NULL | Soft delete support |
| BC-DB-13 | `created_at` | TIMESTAMP | `useCurrent()` |
| BC-DB-14 | `updated_at` | TIMESTAMP | `useCurrent()->useCurrentOnUpdate()` |
| BC-DB-15 | All 5 FKs are RESTRICT (no CASCADE) | Prevent deletion of referenced parent records |
| BC-DB-16 | No UNIQUE constraints exist | Same student could be allocated to multiple routes simultaneously |
| BC-DB-17 | No INDEX on `student_session_id` | Potential performance issue with large student allocations |
| BC-DB-18 | ENUM values: 'Both', 'Drop', 'Pickup' (note: not 'Pick_up', 'both_side' etc) | Import maps to wrong case values |

### BC-VAL: Validation Conditions

| BC ID | Field | Rule | Source |
|-------|-------|------|--------|
| BC-VAL-01 | `student_id` | required, exists:std_students,id | `StudentAllocationRequest.php:28-31` |
| BC-VAL-02 | `transport_use_type` | required, in:Pickup,Drop,Both | `StudentAllocationRequest.php:33-36` |
| BC-VAL-03 | `pickup_route_id` | required_if:Pickup,Both, nullable, exists:tpt_route,id | `StudentAllocationRequest.php:39-43` |
| BC-VAL-04 | `pickup_stop_id` | required_if:Pickup,Both, nullable | `StudentAllocationRequest.php:46-49` |
| BC-VAL-05 | `drop_stop_id` | required_if:Drop,Both, nullable | `StudentAllocationRequest.php:52-55` |
| BC-VAL-06 | `drop_route_id` | required_if:Drop,Both, nullable, exists:tpt_route,id | `StudentAllocationRequest.php:58-62` |
| BC-VAL-07 | `fare` | required, numeric, min:0 | `StudentAllocationRequest.php:65-69` |
| BC-VAL-08 | `effective_from` | required, date, after_or_equal:today (create only) | `StudentAllocationRequest.php:72-76,85-86` |
| BC-VAL-09 | `is_active` | nullable, boolean (normalized) | `StudentAllocationRequest.php:78-81,97-99` |
| BC-VAL-10 | Import file | required, mimes:xlsx,csv | `StudentAllocationController.php:352` |
| BC-VAL-11 | Import: duplicate roll in Excel | Check `$excelRolls` array | `StudentAllocationController.php:379-383` |
| BC-VAL-12 | Import: student not in DB | Check `StudentAcademicSession::where('roll_no', $roll)` | `StudentAllocationController.php:385-388` |
| BC-VAL-13 | Import: student already allocated | Check `TptStudentAllocationJnt::where('student_session_id', $studentSession->student_id)->exists()` — **uses student_id not session_id** | `StudentAllocationController.php:390-392` |
| BC-VAL-14 | Import: route code validity | Check `Route::where('code', $routeCode)->exists()` | `StudentAllocationController.php:394-396` |
| BC-VAL-15 | Import: pickup stop code validity | Check `PickupPoint::where('code', $pickupCode)->exists()` | `StudentAllocationController.php:398-400` |
| BC-VAL-16 | Import: drop stop code validity | Check `PickupPoint::where('code', $dropCode)->exists()` | `StudentAllocationController.php:402-404` |
| BC-VAL-17 | Import: status string validation | `in_array(strtolower($statusRaw), ['active', 'inactive'])` | `StudentAllocationController.php:406-408` |
| BC-VAL-18 | Import: fare numeric check | `is_numeric($fareRaw)` | `StudentAllocationController.php:414-416` |
| BC-VAL-19 | Import: effective date required | `$effRaw === ''` → error | `StudentAllocationController.php:410-412` |
| BC-VAL-20 | `pickup_stop_id` / `drop_stop_id` have NO `exists:` validation | Missing FK existence check for pickup/drop stop IDs | `StudentAllocationRequest.php:46-55` |

### BC-AUTH: Authorization Conditions

| BC ID | Permission | Controller Method | Source |
|-------|-----------|-------------------|--------|
| BC-AUTH-01 | `tenant.student-allocation.viewAny` | `index()` — Gate present | `StudentAllocationController.php:36` |
| BC-AUTH-02 | `tenant.student-allocation.create` | `create()` + `store()` — Gate present | `StudentAllocationController.php:55,70` |
| BC-AUTH-03 | `tenant.student-allocation.view` | `show()` — Gate present | `StudentAllocationController.php:182` |
| BC-AUTH-04 | `tenant.student-allocation.update` | `edit()` + `update()` + `toggleStatus()` — Gate present | `StudentAllocationController.php:193,226,513` |
| BC-AUTH-05 | `tenant.student-allocation.delete` | `destroy()` — Gate present | `StudentAllocationController.php:485` |
| BC-AUTH-06 | `tenant.student-allocation.restore` | `trashed()` + `restore()` — Gate present | `StudentAllocationController.php:301,314` |
| BC-AUTH-07 | `tenant.student-allocation.forceDelete` | `forceDelete()` — Gate present | `StudentAllocationController.php:332` |
| BC-AUTH-08 | `tenant.student-allocation.create` (reused) | `validateFile()` — Gate present | `StudentAllocationController.php:350` |
| BC-AUTH-09 | `tenant.student-allocation.export` | `export()` — **NO Gate** — **GAP** | `StudentAllocationController.php:543-549` |
| BC-AUTH-10 | `tenant.student-allocation.viewAny` | `getSections()` — **NO Gate** — **GAP** | `StudentAllocationController.php:552-565` |
| BC-AUTH-11 | `tenant.student-allocation.viewAny` | `getStudents()` — **NO Gate** — **GAP** | `StudentAllocationController.php:567-588` |
| BC-AUTH-12 | **MISMATCH**: Policy uses `tenant.transport.*` | Policy methods check `tenant.transport.create`, `tenant.transport.update`, etc. | `StudentAllocationPolicy.php:12-45` |
| BC-AUTH-13 | **MISMATCH**: Blade/Controller/Request use `tenant.student-allocation.*` | `Gate::authorize('tenant.student-allocation.create')` etc. | Controller/Blade uses `student-allocation.*` |
| BC-AUTH-14 | **Result**: Gates check permission name that Policy does NOT define | `Gate::authorize('tenant.student-allocation.create')` will always FAIL or rely on wildcard | Authorization may be broken |

### BC-BIZ: Business Conditions

| BC ID | Condition | Expected | Source |
|-------|-----------|----------|--------|
| BC-BIZ-01 | Pickup type → drop_route/drop_stop nullified | `$data['drop_route_id'] = null; $data['drop_stop_id'] = null;` | `StudentAllocationController.php:83-85` |
| BC-BIZ-02 | Drop type → pickup_route/pickup_stop nullified | `$data['pickup_route_id'] = null; $data['pickup_stop_id'] = null;` | `StudentAllocationController.php:86-89` |
| BC-BIZ-03 | Capacity check: `total_students < capacity` (or max_capacity if `allow_extra` setting) | Throws ValidationException if exceeded | `StudentAllocationController.php:125-143` |
| BC-BIZ-04 | Active route-vehicle assignment required | `DriverRouteVehicleJnt::where('route_id',...)->where('is_active',1)->first()` | `StudentAllocationController.php:100-109` |
| BC-BIZ-05 | No active vehicle → "No active vehicle assigned to this route" | ValidationException | `StudentAllocationController.php:106-109` |
| BC-BIZ-06 | `destroy()` decrements `total_students` on DriverRouteVehicleJnt | `$drvRoute->decrement('total_students')` | `StudentAllocationController.php:494-496` |
| BC-BIZ-07 | `store()` triggers `RemoteEntryService::processEvent('TRANSPORT','TPT_NEW_REGISTRATION')` | Accounting event created OUTSIDE transaction | `StudentAllocationController.php:159-169` |
| BC-BIZ-08 | `update()` triggers `TPT_PICKUP_CHANGE` if stop changed | Accounting event created | `StudentAllocationController.php:267-278` |
| BC-BIZ-09 | `update()` triggers `TPT_MODE_CHANGE` if route changed | Accounting event created | `StudentAllocationController.php:280-291` |
| BC-BIZ-10 | `destroy()` does NOT set `active_status=false` before soft-delete | Direct `delete()` via transaction | `StudentAllocationController.php:488-499` |
| BC-BIZ-11 | `forceDelete()` uses `onlyTrashed()` (WRONG — should be `withTrashed()`) | Will 404 for non-trashed records | `StudentAllocationController.php:333` — **GAP** |
| BC-BIZ-12 | `toggleStatus()` updates `active_status` column (NOT `is_active` — unique among Transport entities) | Different column name from other controllers | `StudentAllocationController.php:519` |
| BC-BIZ-13 | `active_status` default = true in model `$attributes` | New allocations are active by default | `TptStudentAllocationJnt.php:50-52` |
| BC-BIZ-14 | `student_session_id` auto-set from `StudentAcademicSession::where('student_id', ...)->first()` | Session ID assigned in store and update | `StudentAllocationController.php:79,92,239,252` |
| BC-BIZ-15 | `fare` auto-calculated from stop data-attributes in JS, but user can override manually | Fare field is editable text input | `student-allocation/js/js.blade.php:99-132` |
| BC-BIZ-16 | Excel import two-step flow: `validateFile()` → download error report or store file → `startImport()` | Session-based file handoff | `StudentAllocationController.php:348-478` |
| BC-BIZ-17 | `store()` has NO capacity check on the route vehicle for the drop_route when type=Drop | Only checks `pickup_route_id || drop_route_id` but capacity increment assumes pickup route | `StudentAllocationController.php:98,148` |
| BC-BIZ-18 | `destroy()` only decrements `pickup_route_id` route — ignores drop_route | `where('route_id', $allocation->pickup_route_id)` | `StudentAllocationController.php:490` |
| BC-BIZ-19 | `startImport()` has NO validation or import result reporting | Blind import with no row count feedback | `StudentAllocationController.php:459-478` |
| BC-BIZ-20 | Activity log in `destroy()` happens AFTER transaction commits | `activityLog()` called after `DB::transaction()` closure | `StudentAllocationController.php:502-505` |
| BC-BIZ-21 | `toggleStatus()` uses `filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN)` | null → false, "false" → false, "0" → false, "1" → true, "true" → true | `StudentAllocationController.php:517` |
| BC-BIZ-22 | `show()` uses `findOrFail()` — correct 404 on missing | `TptStudentAllocationJnt::findOrFail($id)` | `StudentAllocationController.php:183` |
| BC-BIZ-23 | `edit()` uses `findOrFail()` — correct 404 on missing | `TptStudentAllocationJnt::findOrFail($id)` | `StudentAllocationController.php:195` |
| BC-BIZ-24 | No `exists:` validation on `pickup_stop_id` / `drop_stop_id` | Only `required_if` + `nullable`, no FK check | `StudentAllocationRequest.php:46-55` |
| BC-BIZ-25 | Import `already allocated` check uses `$studentSession->student_id` (BUG) | Should be `$studentSession->id` (the session PK) | `StudentAllocationController.php:390` |
| BC-BIZ-26 | Import `Save Data` stores `route_id` which is NOT in fillable | Silently ignored — route data lost | `StudentAllocationImport.php:75` |
| BC-BIZ-27 | Import saves `student_session_id` as `$studentSession->student_id` (wrong) | Should be `$studentSession->id` | `StudentAllocationImport.php:73` |
| BC-BIZ-28 | Import type mapping: 'both side' → 'both_side' but ENUM expects 'Both' | Mapped value won't match DB ENUM — **BUG** | `StudentAllocationImport.php:58-69` |
| BC-BIZ-29 | Import type mapping: 'pick up' → 'pick_up' but ENUM expects 'Pickup' | Mapped value won't match DB ENUM — **BUG** | `StudentAllocationImport.php:58-69` |
| BC-BIZ-30 | Import type mapping: 'drop' → 'drop' but ENUM expects 'Drop' | Case wrong — **BUG** | `StudentAllocationImport.php:58-69` |
| BC-BIZ-31 | Import sets `'route_id' => $route->id` but model fillable does NOT include route_id | Route relationship never stored | `StudentAllocationImport.php:75` |
| BC-BIZ-32 | `store()` does NOT check if student already has an allocation for same route | No duplicate check at controller level | `StudentAllocationController.php:68-175` |
| BC-BIZ-33 | `update()` does NOT re-check vehicle capacity when route changes | If route changed, capacity on new route not verified | `StudentAllocationController.php:224-295` |
| BC-BIZ-34 | `update()` does NOT decrement/increment total_students on route change | Vehicle student counts become inaccurate | `StudentAllocationController.php:224-295` |
| BC-BIZ-35 | `destroy()` tries to decrement even if `total_students` is 0 | Guarded by `if ($drvRoute && $drvRoute->total_students > 0)` | `StudentAllocationController.php:494` |
| BC-BIZ-36 | `getSections()` returns sections with mapped names from Section model | `$cs->section->name ?? 'N/A'` | `StudentAllocationController.php:554-564` |
| BC-BIZ-37 | `getStudents()` returns students filtered by class_section_id or class_id | `StudentAcademicSession::where('is_current', 1)` | `StudentAllocationController.php:568-588` |
| BC-BIZ-38 | `edit()` loads `$allocation->studentSessions.classSection` for pre-selection | Eager loads from `student_session_id` | `StudentAllocationController.php:207` |
| BC-BIZ-39 | `store()` capacity check only runs on `$checkRouteId = pickup_route_id ?? drop_route_id` | If both null (no route selected), `$checkRouteId` is null → query fails | `StudentAllocationController.php:98-108` |
| BC-BIZ-40 | `store()` uses $request->all() for mass-assignment | Passes ALL request data directly to `TptStudentAllocationJnt::create()` | `StudentAllocationController.php:81,93` |
| BC-BIZ-41 | `update()` also uses `$request->all()` for mass-assignment | Same pattern as store | `StudentAllocationController.php:241,255` |
| BC-BIZ-42 | `trashed()` loads with eager loading: studentSessions.student, pickupStop, dropStop, route | 4 relationships loaded | `StudentAllocationController.php:302-304` |
| BC-BIZ-43 | `trashed()` paginates at 20 (different from index which paginates at 10) | 20 vs 10 inconsistency | `StudentAllocationController.php:304` |
| BC-BIZ-44 | `index()` simply returns the transport::index view | Actual query is in StudentRouteFeesController | `StudentAllocationController.php:36-38` |
| BC-BIZ-45 | No `is_active=false` before soft-delete in destroy() | Unlike other Transport entities | `StudentAllocationController.php:488-500` |
| BC-BIZ-46 | `RemoteEntryService` events fired OUTSIDE the DB transaction | If event fails, allocation already saved | `StudentAllocationController.php:159-169` |
| BC-BIZ-47 | `restore()` does NOT re-increment `total_students` | No capacity restoration on restore | `StudentAllocationController.php:312-325` |
| BC-BIZ-48 | `restore()` does NOT check current vehicle capacity | Restored allocation may exceed current capacity | `StudentAllocationController.php:312-325` |
| BC-BIZ-49 | Policy uses `tenant.transport.viewAny` but controller Gate uses `tenant.student-allocation.viewAny` | Different permission namespaces — **AUTH MISMATCH** | Policy vs Controller |

### BC-REF: Reference & UI Conditions

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-REF-01 | Tab id `stdtransport-pane`, hidden `tab=stdtransport` | `student-allocation/index.blade.php:1` |
| BC-REF-02 | Status toggle switch with AJAX POST to `toggleStatus()` | `student-allocation/js/js.blade.php:3-30` |
| BC-REF-03 | Cascade: Class select → loads Sections → loads Students | `student-allocation/js/js.blade.php:150-200` |
| BC-REF-04 | Pickup type disables Drop fields, Drop type disables Pickup fields, Both enables both | `student-allocation/js/js.blade.php:66-91` |
| BC-REF-05 | React JS fare auto-calculation: pickupOnly, dropOnly, sameStop, differentStops | `student-allocation/js/js.blade.php:112-132` |
| BC-REF-06 | Hidden inputs for `pickup_route_id` and `drop_route_id` populated from stop select's data-route | `student-allocation/create.blade.php:104-105` |
| BC-REF-07 | `active_status` uses hidden input (value=0) + checkbox (value=1) for proper boolean submission | `student-allocation/create.blade.php:166-170` |
| BC-REF-08 | Import modal triggered via `.openImportModal` data attributes | `student-allocation/index.blade.php:54` |
| BC-REF-09 | Export triggered via `.exportBtn` data attributes | `student-allocation/index.blade.php:63` |
| BC-REF-10 | Pickup points loaded from `PickupPointRoute` junction (not `PickupPoint` directly) | Combines route+point with is_active filter | `StudentAllocationController.php:45-48` |
| BC-REF-11 | Both pickup and drop points show point name and route name | Displayed in select options | Blade template |
| BC-REF-12 | `pickup_stop_id`/`drop_stop_id` selects store route info in data-route attributes | Used to populate hidden route inputs | JS blade |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create Both allocation | student=valid, type=Both, pickup+drop stops, fare=500 | Created + activityLog Created + RemoteEntryService TPT_NEW_REGISTRATION |
| TC-P-02 | Create Pickup Only allocation | type=Pickup → drop fields nullified | Created with drop_route=null, drop_stop=null |
| TC-P-03 | Create Drop Only allocation | type=Drop → pickup fields nullified | Created with pickup_route=null, pickup_stop=null |
| TC-P-04 | Create allocation at capacity limit | total_students < capacity → under limit | Created successfully |
| TC-P-05 | Edit allocation — change stop | Change pickup stop → save | Updated + RemoteEntryService TPT_PICKUP_CHANGE |
| TC-P-06 | Edit allocation — change route | Change route → save | Updated + RemoteEntryService TPT_MODE_CHANGE |
| TC-P-07 | Toggle status ON → OFF | Click status toggle | AJAX response, active_status=0, activityLog Toggled |
| TC-P-08 | Toggle status OFF → ON | Click status toggle again | AJAX response, active_status=1 |
| TC-P-09 | Soft delete allocation | Click delete | deleted_at set, total_students decremented, activityLog Trash |
| TC-P-10 | Restore soft-deleted allocation | Click restore in trash | Restored, activityLog Restored |
| TC-P-11 | Force delete trashed allocation | Click permanent delete | Record removed, activityLog Force Delete |
| TC-P-12 | Export allocations to Excel | Click export button | XLSX file downloaded |
| TC-P-13 | Import valid Excel file | Upload xlsx with valid data | Validate → store file → import → success |
| TC-P-14 | Cascade Class→Section→Student filtering | Select class, then section | Students filtered correctly |
| TC-P-15 | View single allocation details | Click show icon | Details page with all fields displayed |
| TC-P-16 | Edit — change transport_use_type from Pickup to Both | Toggle type dropdown | Drop fields re-enabled, new drop_stop required |
| TC-P-17 | Load create form with valid pickup/drop points | Navigate to create | Both dropdowns populated with active points |
| TC-P-18 | Load edit form for existing allocation | Navigate to edit | Pre-selected values for all fields |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create without student_id | No student selected | Please select a student. |
| TC-N-02 | Create with invalid student_id | student_id=99999 | Selected student is invalid. |
| TC-N-03 | Pickup type without pickup stop | type=Pickup, no stop selected | Pickup stop is required for Pickup/Both types. |
| TC-N-04 | Drop type without drop stop | type=Drop, no stop selected | Drop stop is required for Drop/Both types. |
| TC-N-05 | Negative fare | fare=-100 | Fare cannot be negative. |
| TC-N-06 | Past effective date (create) | effective_from=yesterday | Effective date cannot be in the past. |
| TC-N-07 | Effective date in past allowed on edit | update with past date | Succeeds (rule only applied on POST) |
| TC-N-08 | Capacity exceeded (allow_extra=false) | total_students >= capacity | Vehicle capacity exceeded. |
| TC-N-09 | Capacity exceeded (allow_extra=true) | total_students >= max_capacity | Vehicle maximum capacity exceeded. |
| TC-N-10 | No active vehicle on route | route has no active DriverRouteVehicleJnt | No active vehicle assigned to this route. |
| TC-N-11 | Force delete active (non-trashed) record | Active record | onlyTrashed() → 404 — **GAP** |
| TC-N-12 | Restore non-trashed record | Active record | onlyTrashed() → 404 |
| TC-N-13 | Import: missing student roll | Excel row with empty roll | Student Roll missing |
| TC-N-14 | Import: duplicate roll in Excel | Same roll in 2 rows | Duplicate Student inside Excel |
| TC-N-15 | Import: student already allocated | Existing allocation | Student already allocated |
| TC-N-16 | Import: invalid route code | Route not in DB | Invalid Route Code |
| TC-N-17 | Import: invalid pickup code | Pickup point not in DB | Invalid Pickup Stop Code |
| TC-N-18 | Access without permission | No tenant.transport.* / tenant.student-allocation.* | 403 |
| TC-N-19 | Import: invalid drop stop code | Drop stop not in DB | Invalid Drop Stop Code |
| TC-N-20 | Import: invalid status string | status=unknown | Invalid Status |
| TC-N-21 | Import: non-numeric fare | fare=abc | Invalid Fare Amount |
| TC-N-22 | Import: missing effective_from | empty date | Effective Date is required |
| TC-N-23 | Create with no student_session_id | student_id has no academic session | student_session_id set to empty string |
| TC-N-24 | Create with no vehicle | route has no DriverRouteVehicleJnt at all | No active vehicle assigned to this route. |
| TC-N-25 | Create with null checkRouteId | both pickup_route_id and drop_route_id null | SQL error or wrong results |
| TC-N-26 | toggleStatus with is_active=null | Send null/empty | filter_var(null, FILTER_VALIDATE_BOOLEAN) → false |
| TC-N-27 | store() with invalid pickup_stop_id | pickup_stop_id=99999 | No validation error → FK violation if enforce |
| TC-N-28 | Import file not xlsx/csv | Upload .pdf | The file must be a file of type: xlsx, csv. |
| TC-N-29 | startImport() without prior validation | Direct POST without validateFile | No file found in session. Validate first. |
| TC-N-30 | Create with Both type but missing drop_route | Only pickup_route provided | Drop Route is required for Drop/Both types. |

### TC-D: Data Integrity Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Verify total_students increment on create | store() increments DriverRouteVehicleJnt.total_students | Count +1 |
| TC-D-02 | Verify total_students decrement on delete | destroy() decrements | Count -1 |
| TC-D-03 | Verify pickup/drop nullification | store() nullifies opposite fields based on type | DB has nulls for irrelevant fields |
| TC-D-04 | Verify effective_from change tracking | update() captures old IDs then sends RemoteEntryService only if changed | Conditional events |
| TC-D-05 | Verify active_status default | New allocation without explicit status | active_status=1 (model $attributes) |
| TC-D-06 | Verify FK RESTRICT prevents parent deletion | Delete tpt_route used by allocation | FK violation error |
| TC-D-07 | Verify total_students NOT incremented on update | update() does not touch total_students | No change |
| TC-D-08 | Verify toggleStatus does NOT affect deleted_at | status toggle on active record | deleted_at still NULL |
| TC-D-09 | Verify activityLog entries for each event | Create/Update/Trash/Restore/ForceDelete/Toggle | 6 distinct log entries |
| TC-D-10 | Verify remote events fire only for relevant changes | Stop change → TPT_PICKUP_CHANGE, Route change → TPT_MODE_CHANGE | Conditional |
| TC-D-11 | Verify same student can have multiple allocations (no UNIQUE) | Same student_id in 2 rows | Both created |
| TC-D-12 | Verify transaction rollback on exception in store() | Force exception after allocation create | Allocation rolled back |
| TC-D-13 | Verify session file is removed after import | startImport() consumes session file | Session cleared |
| TC-D-14 | Verify import creates records with correct ENUM values | type=both_side in import → should be Both | Record created with corrected type |
| TC-D-15 | Verify import sets correct student_session_id | Import maps from roll_no | Links to correct session PK |
| TC-D-16 | Verify export matches index query results | Export uses same StudentAllocationQuery | Same data as index |

### TC-CR: Code Review Test Cases

| ID | Test Case | Steps | Expected |
|----|-----------|-------|----------|
| TC-CR-01 | **GAP: forceDelete() uses onlyTrashed()** | Open controller line 333 | `onlyTrashed()` should be `withTrashed()` |
| TC-CR-02 | **GAP: export() missing Gate** | Open controller lines 543-549 | No `Gate::authorize()` — **MISSING** |
| TC-CR-03 | **store() DB transaction** | Open controller lines 74-156 | All operations in `DB::transaction()` |
| TC-CR-04 | **store() sets student_session_id** | Line 79: fetch StudentAcademicSession by student_id | If no session found, student_session_id = "" |
| TC-CR-05 | **Capacity logic: allow_extra setting** | Lines 125-136 | Setting controls capacity vs max_capacity |
| TC-CR-06 | **update() change detection** | Lines 231-234: snapshots old values | Fires RemoteEntryService only on change |
| TC-CR-07 | **Import: validateFile() error report as txt download** | Lines 430-443 | Summary + errors as text file download |
| TC-CR-08 | **Import: session-based file handoff** | Line 447: `session(['import_file' => $savedFile])` | File path in session |
| TC-CR-09 | **toggleStatus() column name** | Line 519: `$allocation->active_status = $status` | Uses `active_status` not `is_active` |
| TC-CR-10 | **toggleStatus() AJAX response** | Lines 527-537 | Returns JSON with success, active_status, message |
| TC-CR-11 | **No is_active=0 before soft delete** | Lines 488-499: destroy() | Does NOT set active_status=false before delete |
| TC-CR-12 | **getStudents() AJAX endpoint** | Lines 567-588 | Returns students filtered by class_section_id or class_id |
| TC-CR-13 | **getSections() AJAX endpoint** | Lines 552-565 | Returns sections for given classId |
| TC-CR-14 | **index() in StudentRouteFeesController** | StudentRouteFeesController.php:48 | Query built by StudentAllocationQuery() with paginate(10) |
| TC-CR-15 | **5 FK RESTRICT constraints** | Migration lines 26-34 | All FKs are RESTRICT — no CASCADE |
| TC-CR-16 | **Import: already-allocated check uses wrong field** | Line 390: `where('student_session_id', $studentSession->student_id)` | Uses student_id not session id — **BUG** |
| TC-CR-17 | **Import: type mapping mismatch with ENUM** | StudentAllocationImport.php lines 58-69 | Values don't match ENUM 'Both'/'Pickup'/'Drop' |
| TC-CR-18 | **Import: route_id not in fillable** | StudentAllocationImport.php:75 | `route_id` not in $fillable — data lost |
| TC-CR-19 | **Import: student_session_id mapped to wrong value** | StudentAllocationImport.php:73 | `$studentSession->student_id` should be `$studentSession->id` |
| TC-CR-20 | **Policy permission mismatch with controller** | StudentAllocationPolicy.php:24 uses `tenant.transport.create` | Controller uses `tenant.student-allocation.create` |
| TC-CR-21 | **No Gate in getSections() / getStudents()** | Lines 552-588 | No authorization check on AJAX endpoints |
| TC-CR-22 | **destroy() only decrements pickup_route** | Line 490: `where('route_id', $allocation->pickup_route_id)` | Does NOT handle drop_route_id |
| TC-CR-23 | **store() RemoteEntryService outside transaction** | Lines 159-169 | Event fires outside DB transaction |
| TC-CR-24 | **restore() doesn't restore total_students** | Lines 312-325 | No vehicle count adjustment on restore |
| TC-CR-25 | **update() doesn't check capacity on route change** | Lines 224-295 | New route's vehicle capacity not verified |
| TC-CR-26 | **update() doesn't adjust total_students on route change** | Lines 224-295 | Old route not decremented, new not incremented |
| TC-CR-27 | **Missing exists: validation for pickup_stop_id / drop_stop_id** | StudentAllocationRequest.php lines 46-55 | No FK existence check for stop IDs |
| TC-CR-28 | **Duplicate check missing in store()** | Controller lines 68-175 | No duplicate student+route check before create |
| TC-CR-29 | **Import: startImport() returns no row count** | Lines 475-477 | Only `{status: completed}` — no inserted/error count |
| TC-CR-30 | **validateFile() uses create permission for import** | Line 350 | Import permission same as create |
---

### TC-BIZ-DEEP: Deep Business/Technical Behavior Entries

### TC-BIZ-DEEP-01: Default attributes from model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TptStudentAllocationJnt.php:50-52 | $attributes = ['active_status' => true] |
| 2 | Create allocation without sending active_status | Defaults to true |
| 3 | Verify $allocation->active_status returns true | Cast to boolean by $casts |

### TC-BIZ-DEEP-02: Model casts behavior

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open casts: fare→decimal:2, effective_from→date, active_status→boolean | 3 casts defined |
| 2 | Create with fare=500 | $model->fare returns 500.00 |
| 3 | Create with active_status=1 | $model->active_status returns true (boolean) |
| 4 | Create with effective_from=2026-07-21 | Returns Carbon instance |

### TC-BIZ-DEEP-03: Fillable fields vs DDL columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open model $fillable lines 22-36 | 10 fillable fields |
| 2 | Open migration lines 14-36 | 12 data columns + id + timestamps + deleted_at |
| 3 | id/created_at/updated_at/deleted_at NOT in fillable | Correct — managed by Eloquent |

### TC-BIZ-DEEP-04: Soft delete trait

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TptStudentAllocationJnt.php:15 | use HasFactory, SoftDeletes; |
| 2 | Migration line 35: $table->softDeletes() | deleted_at TIMESTAMP NULL column |
| 3 | destroy() calls $allocation->delete() line 499 | Sets deleted_at timestamp |

### TC-BIZ-DEEP-05: scopeActive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TptStudentAllocationJnt.php:147-150 | scopeActive returns where('active_status', true) |
| 2 | scopeActive is NOT used in controller or index query | No active-only filtering in list |

### TC-BIZ-DEEP-06: Pickup type nullifies drop fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation with transport_use_type=Pickup | Controller lines 83-85 execute |
| 2 | Verify $data['drop_route_id'] = null | Set correctly |
| 3 | Verify $data['drop_stop_id'] = null | Set correctly |
| 4 | DB check: both drop fields are NULL | Stored correctly |

### TC-BIZ-DEEP-07: Drop type nullifies pickup fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation with transport_use_type=Drop | Controller lines 86-89 execute |
| 2 | Verify $data['pickup_route_id'] = null | Set correctly |
| 3 | Verify $data['pickup_stop_id'] = null | Set correctly |
| 4 | DB check: both pickup fields are NULL | Stored correctly |

### TC-BIZ-DEEP-08: Both type keeps all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation with transport_use_type=Both | Neither if/elseif branch executes |
| 2 | All 4 route/stop fields kept as provided | No nullification |
| 3 | DB check: all 4 fields have values | Stored correctly |

### TC-BIZ-DEEP-09: StudentAcademicSession lookup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | store() line 79: StudentAcademicSession::where('student_id', $request->student_id)->first() | SELECT * FROM std_student_academic_sessions WHERE student_id = ? LIMIT 1 |
| 2 | If session found → student_session_id set to session->id | Correct link |
| 3 | If NOT found → student_session_id = '' (empty string) | String '' stored in INT column → MySQL casts to 0 |

### TC-BIZ-DEEP-10: store() uses $request->all() for mass assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Controller line 81: $data = $request->all() | All request fields captured |
| 2 | Extra fields (e.g. _token, is_active) also in $data | Mass-assignment guarded by $fillable |
| 3 | is_active normalized to boolean by prepareForValidation() | $this->boolean('is_active') |

### TC-BIZ-DEEP-11: Capacity check — allow_extra=false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setting allow_extra_student_in_vehicale_beyond_capacity = false | $allowExtra = false |
| 2 | $capacityLimit = $vehicle->capacity (normal capacity) | e.g. 40 |
| 3 | If $drvRoute->total_students >= $capacityLimit | Throws 'Vehicle capacity exceeded.' |

### TC-BIZ-DEEP-12: Capacity check — allow_extra=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setting = true | $allowExtra = true |
| 2 | $capacityLimit = $vehicle->max_capacity | e.g. 50 |
| 3 | If total_students >= max_capacity | Throws 'Vehicle maximum capacity exceeded.' |

### TC-BIZ-DEEP-13: Capacity check error message distinction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setting false, at capacity → error message | 'Vehicle capacity exceeded.' (no 'maximum') |
| 2 | Setting true, at max capacity → error message | 'Vehicle maximum capacity exceeded.' |

### TC-BIZ-DEEP-14: Increment total_students after capacity check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Capacity check passes | Below limit |
| 2 | Line 148: $drvRoute->increment('total_students') | UPDATE driver_route_vehicle_jnt SET total_students = total_students + 1 |
| 3 | This happens inside DB transaction | Atomic with allocation create |

### TC-BIZ-DEEP-15: Activity log after create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Line 153-155: activityLog($studentAllocation, 'Created', ...) | Activity log entry created |
| 2 | Log message: 'Student Allocation created successfully' | Text saved |
| 3 | activityLog is inside the DB transaction | Will rollback if activity log fails |

### TC-BIZ-DEEP-16: RemoteEntryService fires after transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DB transaction commits | Allocation saved |
| 2 | app(RemoteEntryService::class)->processEvent(...) | Accounting event fires outside transaction |
| 3 | Risk: If RemoteEntryService fails, allocation already committed | Orphan allocation in DB |

### TC-BIZ-DEEP-17: store() redirects to index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | redirect()->route('transport.std-route-Fees-mgmt.index') | Redirect to main transport tab |
| 2 | Flash: flash('created.student_allocation') | Success message displayed |

### TC-BIZ-DEEP-18: show() uses findOrFail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | TptStudentAllocationJnt::findOrFail($id) | SELECT * FROM tpt_student_route_allocation_jnt WHERE id = ? |
| 2 | Record found → passes to view | View rendered |
| 3 | Record NOT found → 404 ModelNotFoundException | Laravel handler |

### TC-BIZ-DEEP-19: edit() loads supplementary data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | TptStudentAllocationJnt::findOrFail($id) | Allocation found |
| 2 | PickupPointRoute for Pickup/Both types | WHERE pickup_drop IN ('Pickup','Both') AND is_active = 1 |
| 3 | PickupPointRoute for Drop/Both types | WHERE pickup_drop IN ('Drop','Both') AND is_active = 1 |
| 4 | load('studentSessions.classSection') | Eager load session + class section |

### TC-BIZ-DEEP-20: update() change detection snapshot

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 4 variables snapshotted before update | $oldPickupStopId, $oldDropStopId, $oldPickupRouteId, $oldDropRouteId |
| 2 | Compares old vs new values after update | Change detection at lines 262-265 |
| 3 | Used to fire accounting events | Conditional RemoteEntryService |

### TC-BIZ-DEEP-21: update() stop change → TPT_PICKUP_CHANGE

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $stopChanged = pickup_stop_id !== old || drop_stop_id !== old | True if any stop changed |
| 2 | If true → RemoteEntryService::processEvent('TRANSPORT','TPT_PICKUP_CHANGE') | Accounting event fired |

### TC-BIZ-DEEP-22: update() route change → TPT_MODE_CHANGE

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $routeChanged = pickup_route_id !== old || drop_route_id !== old | True if any route changed |
| 2 | If true → RemoteEntryService::processEvent('TRANSPORT','TPT_MODE_CHANGE') | Accounting event fired |

### TC-BIZ-DEEP-23: update() activity log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | activityLog($allocation, 'Updated', ['message' => 'Student Allocation updated']) | Log entry created |
| 2 | activityLog fires BEFORE RemoteEntryService in update() | Order: log → accounting events |

### TC-BIZ-DEEP-24: update() redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | redirect()->route('transport.std-route-Fees-mgmt.index') | Redirect to main tab |
| 2 | Flash: flash('updated.student_allocation') | Success message |

### TC-BIZ-DEEP-25: destroy() — find allocation first

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | TptStudentAllocationJnt::findOrFail($id) | Allocation found |
| 2 | Uses findOrFail not withTrashed | Only finds active (non-trashed) records |

### TC-BIZ-DEEP-26: destroy() — decrement total_students

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DriverRouteVehicleJnt::where('route_id', pickup_route_id)->where('is_active',1)->first() | Only checks pickup_route_id |
| 2 | GAP: If Drop type (no pickup_route_id), pickup_route_id is null | Decrement may not work for Drop-only |
| 3 | if ($drvRoute && total_students > 0) → decrement | Guard prevents negative count |

### TC-BIZ-DEEP-27: destroy() — soft delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $allocation->delete() | Sets deleted_at to current timestamp |
| 2 | Does NOT set active_status=false first | Record stays active in trash |
| 3 | Operation inside DB::transaction() | Atomic with decrement |

### TC-BIZ-DEEP-28: destroy() activity log AFTER transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | activityLog($allocation, 'Trash', ['message' => 'Student Allocation moved to trash']) | Called after transaction closure |

### TC-BIZ-DEEP-29: trashed() — list soft-deleted records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | TptStudentAllocationJnt::onlyTrashed()->with([...])->paginate(20) | SELECT * ... WHERE deleted_at IS NOT NULL |
| 2 | Eager loads: studentSessions.student, pickupStop, dropStop, route | 4 relationships |
| 3 | Paginated at 20 records per page | Links rendered |

### TC-BIZ-DEEP-30: restore() uses onlyTrashed() correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | TptStudentAllocationJnt::onlyTrashed()->findOrFail($id) | Only finds trashed records |
| 2 | $allocation->restore() | Sets deleted_at = NULL |
| 3 | Activity log: 'Restored' | Log entry created |

### TC-BIZ-DEEP-31: forceDelete() GAP — onlyTrashed() instead of withTrashed()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | TptStudentAllocationJnt::onlyTrashed()->findOrFail($id) | Only finds trashed records |
| 2 | BUG: Should be withTrashed() to find both active and trashed | onlyTrashed() excludes active records |
| 3 | Force delete on active record → 404 ModelNotFoundException | Authorization fails for active records |

### TC-BIZ-DEEP-32: toggleStatus() — boolean normalization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN) | Normalizes various boolean representations |
| 2 | Input '1', 'true', 'on', 'yes' → true | Boolean true |
| 3 | Input '0', 'false', 'off', 'no', '' → false | Boolean false |
| 4 | No validation rule prevents non-boolean values | filter_var silently converts anything to false |

### TC-BIZ-DEEP-33: toggleStatus() — active_status column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $allocation->active_status = $status | Uses active_status (not is_active) |
| 2 | $allocation->save() | UPDATE tpt_student_route_allocation_jnt SET active_status = ? |

### TC-BIZ-DEEP-34: toggleStatus() — AJAX response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Success: {success: true, active_status: 0/1, message: flash(...)} | JSON success response |
| 2 | Failure: {success: false, message: flash('status_switch_failed...')} | JSON failure response |

### TC-BIZ-DEEP-35: toggleStatus() — activity log with extra data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | activityLog($allocation, 'Toggled', ['message' => ..., 'other' => 'Some other information']) | Log entry with custom 'other' field |
| 2 | Extra 'other' key is unique to this method | Not present in other activityLog calls |

### TC-BIZ-DEEP-36: export() — missing Gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | export() method | Contains NO Gate::authorize() |
| 2 | Returns Excel::download(...) | Excel download |
| 3 | GAP: Any authenticated user can export | No permission check |

### TC-BIZ-DEEP-37: export() delegates to StudentRouteFeesController

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | StudentAllocationExport:collection() instantiates StudentRouteFeesController | Calls StudentAllocationQuery()->get() |
| 2 | Fetches all matching records (no pagination) | ->get() returns Collection |

### TC-BIZ-DEEP-38: export() column mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | map() returns 8 columns | Roll No, Student Name, Class, Route, Pickup, Drop, Type, Status |
| 2 | Uses optional() helper for null-safe access | Graceful fallback for missing relations |

### TC-BIZ-DEEP-39: getSections() AJAX endpoint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | getSections($classId) | No Gate check |
| 2 | Query: ClassSection::where('class_id', $classId)->with('section')->get() | Sections for class |
| 3 | Returns JSON array: [{id, name}] | $cs->section->name ?? 'N/A' |

### TC-BIZ-DEEP-40: getStudents() AJAX endpoint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | getStudents(Request $request) | No Gate check |
| 2 | Base query: StudentAcademicSession::with('student')->where('is_current', 1) | Current academic year students |
| 3 | Filters: class_section_id or class_id | Conditional where clauses |
| 4 | Returns JSON: [{id: student_id, name: 'First Last (RollNo)'}] | Formatted for dropdown |

### TC-BIZ-DEEP-41: validateFile() — permission check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Gate::authorize('tenant.student-allocation.create') | Uses create permission (not import) |
| 2 | No tenant.student-allocation.import permission in code | Blade checks @can('import') but Gate uses create |

### TC-BIZ-DEEP-42: validateFile() — file type validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $request->validate(['file' => 'required|mimes:xlsx,csv']) | Only xlsx and csv accepted |
| 2 | Invalid file type → redirect with errors | Standard Laravel validation error |

### TC-BIZ-DEEP-43: validateFile() — Excel parsing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Excel::toArray(new StudentAllocationReadOnly, $request->file('file'))[0] | Reads Excel into array of rows |
| 2 | StudentAllocationReadOnly implements ToArray, WithHeadingRow | Column headers as keys |
| 3 | Headings: student_roll, route_code, pickup_stop_code, drop_stop_code, status, effective_from, fare_amount | Expected columns |

### TC-BIZ-DEEP-44: validateFile() — duplicate roll detection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | if (in_array($roll, $excelRolls)) → error | 'Duplicate Student inside Excel' |
| 2 | $excelRolls[] = $roll added AFTER check | Next row with same roll will be caught |
| 3 | First occurrence NOT flagged | Only duplicates after first |

### TC-BIZ-DEEP-45: validateFile() — student lookup by roll

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | StudentAcademicSession::where('roll_no', $roll)->first() | Query by roll_no |
| 2 | Not found → 'Student not found in DB' | Error collected |
| 3 | Found → returns session object | Used for subsequent checks |

### TC-BIZ-DEEP-46: validateFile() — already allocated check [BUG]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | where('student_session_id', $studentSession->student_id)->exists() | BUG: Uses student_id not session id |
| 2 | Correct: where('student_session_id', $studentSession->id) | Wrong column value causes incorrect match |
| 3 | Impact: may return false positive or false negative | Inconsistent duplicate detection |

### TC-BIZ-DEEP-47: validateFile() — route code validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Route::where('code', $routeCode)->exists() | Query: SELECT EXISTS(SELECT 1 FROM tpt_route WHERE code = ?) |
| 2 | Not found → 'Invalid Route Code' with actual code | Error includes context |

### TC-BIZ-DEEP-48: validateFile() — pickup/drop code validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PickupPoint::where('code', $pickupCode)->exists() | Validates pickup stop |
| 2 | PickupPoint::where('code', $dropCode)->exists() | Validates drop stop |
| 3 | Both errors include the code value | Context in error report |

### TC-BIZ-DEEP-49: validateFile() — status validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | if (status !== '' && !in_array(strtolower(status), ['active','inactive'])) | Only active or inactive allowed |
| 2 | Empty status → no error (accepts blank) | Default used during import |

### TC-BIZ-DEEP-50: validateFile() — fare/date validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Effective date required if empty | 'Effective Date is required' |
| 2 | Fare numeric check | 'Invalid Fare Amount' if non-numeric |
| 3 | Empty fare is allowed (no error) | Defaults to 0 in import |

### TC-BIZ-DEEP-51: validateFile() — error report generation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | If errors found → generate text report | Summary + each error as 'Row N: message' |
| 2 | Summary: TOTAL, PASSED, FAILED counts | $totalRows - $errorRowsCount = $passedRowsCount |
| 3 | Returned as TXT download | Content-Type: text/plain, Content-Disposition: attachment |

### TC-BIZ-DEEP-52: validateFile() — valid file storage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $request->file('file')->store('imports', 'public') | File stored in storage/app/public/imports/ |
| 2 | session(['import_file' => $savedFile]) | File path saved to session |
| 3 | JSON response with status, file, total, passed, failed | '{status: success, file: ..., total: N, ...}' |

### TC-BIZ-DEEP-53: startImport() — session file retrieval

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $filePath = session('import_file') | Retrieve stored path |
| 2 | No file → 'No file found in session. Validate first.' | JSON error response |

### TC-BIZ-DEEP-54: startImport() — blind import with no feedback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Storage::disk('public')->path($filePath) | Full path resolved |
| 2 | Excel::import(new StudentAllocationImport, $fullPath) | Import executed with no error handling |
| 3 | JSON response {status: 'completed'} | No row counts returned |
| 4 | GAP: No try/catch, no validation re-check | Blind import |

### TC-BIZ-DEEP-55: Import model — route_id fillable mismatch [BUG]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 'route_id' => $route->id (line 74) | route_id is NOT in model $fillable |
| 2 | Since not fillable, IGNORED during mass-assignment | Route NOT stored |
| 3 | Correct field should be pickup_route_id | Data lost due to wrong field name |

### TC-BIZ-DEEP-56: Import model — student_session_id [BUG]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 'student_session_id' => $studentSession->student_id | BUG: student_id is student FK, not session PK |
| 2 | Should be $studentSession->id (the session PK) | Wrong foreign key value stored |

### TC-BIZ-DEEP-57: Import model — type ENUM mismatch [BUG]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 'transport_use_type' => $type (from mapping) | Type: 'both_side', 'pick_up', 'drop' |
| 2 | DB ENUM only accepts: 'Both', 'Drop', 'Pickup' | MISMATCH: lowercase and underscore format |
| 3 | Insert may fail or store incorrectly | MySQL strict mode may reject |

### TC-BIZ-DEEP-58: Import mapping details [BUG]

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 'both side' → 'both_side', 'pick up' → 'pick_up', 'drop' → 'drop' | None match DB ENUM values |
| 2 | Default: $type = 'both_side' | Default also wrong format |
| 3 | All imports set wrong type value | Data integrity issue |

### TC-BIZ-DEEP-59: Import model — status mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $status = (strtolower(trim(status)) == 'active') ? 1 : 0 | 'active' → 1, anything else → 0 |
| 2 | Empty status → 0 (inactive) | Status defaults to inactive |

### TC-BIZ-DEEP-60: Import model — effective date parsing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Carbon::parse($row['effective_from'])->format('Y-m-d') | Parse various date formats |
| 2 | Invalid date → catch sets null | Null stored in DATE column |
| 3 | Empty date → null | NULL effective_from |

### TC-BIZ-DEEP-61: Import model — fare handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $fare = is_numeric(fare_amount) ? fare_amount : 0 | Numeric → use value, else 0 |
| 2 | Empty fare → 0 | Default zero |

### TC-BIZ-DEEP-62: index() renders via StudentRouteFeesController

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | StudentAllocationController::index() returns transport::index view | View delegates to StudentRouteFeesController |
| 2 | StudentAllocationQuery($request)->paginate(10) with withQueryString() | Paginated at 10 |

### TC-BIZ-DEEP-63: Index filter: route_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $query->where('pickup_route_id', $request->route_id) | Only filters by pickup_route_id |
| 2 | Drop-only allocations excluded from filter | Incomplete filtering |

### TC-BIZ-DEEP-64: Index filter: status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | if ($request->status != '') → where('active_status', status) | Empty string → no filter |
| 2 | Both active and inactive shown when no filter | DB boolean match |

### TC-BIZ-DEEP-65: Index filter: class_id via whereHas

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | whereHas('studentSessions.classSection', fn => where('class_id', class_id)) | Subquery filters by class |

### TC-BIZ-DEEP-66: Index filter: transport_use_type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $query->where('transport_use_type', $request->transport_use_type) | Exact match on ENUM value |
| 2 | Value must be 'Both', 'Pickup', or 'Drop' | Case-sensitive |

### TC-BIZ-DEEP-67: Index eager loading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | with(['route:id,name', 'pickupStop:id,name', 'dropStop:id,name', 'studentSessions.student']) | 4 relationships, specific columns |

### TC-BIZ-DEEP-68: Policy permission mismatch — core auth gap

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Policy checks tenant.transport.* | Different namespace entirely |
| 2 | Controller/Blade checks tenant.student-allocation.* | Mismatched permission names |
| 3 | Unless wildcard grants both, gates will fail | Authorization broken for non-admin users |

### TC-BIZ-DEEP-69: create() loads PickupPointRoute (not PickupPoint)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Lines 45-48: PickupPointRoute with pickup_drop IN ('Pickup','Both') | Junction table with related PickupPoint |
| 2 | Lines 50-53: Same for Drop points | Different from other dropdown patterns |

### TC-BIZ-DEEP-70: create() loads Route::all() without active filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 'routes' => Route::all() | ALL routes loaded, including inactive |
| 2 | Inconsistency: PickupPointRoute filtered by is_active, but Route is not | Mixed filtering approach |

### TC-BIZ-DEEP-71: store() capacity first() for route-vehicle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DriverRouteVehicleJnt::with('vehicle')->where('route_id', id)->where('is_active',1)->first() | First active route-vehicle assignment |
| 2 | If multiple active vehicles, only first checked | Only one vehicle considered for capacity |

### TC-BIZ-DEEP-72: store() vehicle null check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $vehicle = $drvRoute->vehicle; if (!$vehicle) | Check if vehicle exists on assignment |
| 2 | No vehicle → 'Vehicle not found.' | ValidationException thrown |

### TC-BIZ-DEEP-73: store() capacity limit from Setting

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setting::where('key', 'allow_extra_student_in_vehicale_beyond_capacity')->value('value') | SELECT value FROM sys_settings WHERE key = ? |
| 2 | filter_var(allowExtra, FILTER_VALIDATE_BOOLEAN) | String → boolean |

### TC-BIZ-DEEP-74: store() capacity comparison

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | if (total_students >= capacityLimit) | Greater-than-or-equal comparison |
| 2 | At exactly capacity → blocked | 'Vehicle capacity exceeded.' |
| 3 | One less → allowed, incremented | Correct boundary behavior |

### TC-BIZ-DEEP-75: update() mass assignment same as store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $data = $request->all() | Same pattern as store |
| 2 | $allocation->update($data) | Mass assignment |
| 3 | If student changes, student_session_id re-fetched at line 239 | Updated correctly |

### TC-BIZ-DEEP-76: update() type nullification same as store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Lines 243-249: Same nullification logic | Pickup → drop null, Drop → pickup null |
| 2 | No validation on route/stop ID changes during type switch | Could lose previously set values |

### TC-BIZ-DEEP-77: toggleStatus() route-model-binding NOT used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | toggleStatus(Request $request, $id) | Manual ID parameter (not route-model-binding) |
| 2 | TptStudentAllocationJnt::findOrFail($id) | Manual lookup |
| 3 | Inconsistent with other controllers using binding | Pattern difference |

### TC-BIZ-DEEP-78: All controller methods use $id parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | show($id), edit($id), update(..., $id), destroy($id), restore($id), forceDelete($id), toggleStatus(..., $id) | All use manual ID |
| 2 | No route-model-binding in any method | Consistent pattern |

### TC-BIZ-DEEP-79: Flash messages use flash() helper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | store: flash('created.student_allocation') | Translation key |
| 2 | update: flash('updated.student_allocation') | Translation key |
| 3 | destroy: flash('trashed.student_allocation') | Translation key |
| 4 | restore: flash('restored.student_allocation') | Translation key |
| 5 | forceDelete: flash('force_deleted.student_allocation') | Translation key |
| 6 | toggle: flash('status_updated...') and flash('status_switch_failed...') | Translation keys |

### TC-BIZ-DEEP-80: 5 FK RESTRICT constraints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | fk_sa_studentSession RESTRICT | Cannot delete std_student_academic_sessions if allocated |
| 2 | fk_sa_pickupRoute RESTRICT | Cannot delete tpt_route if used as pickup |
| 3 | fk_sa_pickup RESTRICT | Cannot delete tpt_pickup_points if used as pickup stop |
| 4 | fk_sa_dropRoute RESTRICT | Cannot delete tpt_route if used as drop route |
| 5 | fk_sa_drop RESTRICT | Cannot delete tpt_pickup_points if used as drop stop |

### TC-BIZ-DEEP-81: StudentAllocationExport uses controller directly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Instantiates StudentRouteFeesController directly | Not via route — anti-pattern |
| 2 | Calls StudentAllocationQuery($this->request)->get() | Query builder → collection |
| 3 | No pagination on export | All matching records exported |

### TC-BIZ-DEEP-82: getStudents() only returns current academic year

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | where('is_current', 1) | Only current year sessions |
| 2 | Previous year students excluded | Correct for current allocations |

### TC-BIZ-DEEP-83: getStudents() filters by class_section_id or class_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | if filled('class_section_id') → exact match | Specific section students |
| 2 | elseif filled('class_id') → whereHas classSection | All students in a class |
| 3 | Neither → ALL current students | No filter applied |

### TC-BIZ-DEEP-84: getStudents() name format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | (first_name ?? '') . ' ' . (last_name ?? '') . ' (' . (roll_no ?? 'No Roll') . ')' | Format: 'First Last (RollNo)' |
| 2 | Missing names → empty string fallback | Graceful fallback |

### TC-BIZ-DEEP-85: View-only entry points

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | index() → transport::index view | Tabbed interface |
| 2 | create() → transport::student-allocation.create | Form with cascading dropdowns |
| 3 | show($id) → transport::student-allocation.show | Read-only detail view |
| 4 | edit($id) → transport::student-allocation.edit | Pre-filled form |
| 5 | trashed() → transport::student-allocation.trash | Deleted records list |

### TC-BIZ-DEEP-86: store() validation order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | StudentAllocationRequest runs first | Rules validated |
| 2 | prepareForValidation() normalizes is_active | Boolean normalization |
| 3 | Gate::authorize() runs | Authorization |
| 4 | DB::transaction() starts | All operations atomic |

### TC-BIZ-DEEP-87: No soft-delete in StudentAllocationController index()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | StudentAllocationController::index() returns view only | Delegates to StudentRouteFeesController |
| 2 | StudentAllocationQuery() no withTrashed() | Excludes soft-deleted records |

### TC-BIZ-DEEP-88: trashed() uses different pagination (20 vs 10)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | trashed(): paginate(20) | 20 per page |
| 2 | Index: paginate(10) | 10 per page |
| 3 | Inconsistent pagination size | 20 vs 10 |

### TC-BIZ-DEEP-89: trashed() eager loads relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | with(['studentSessions.student', 'pickupStop', 'dropStop', 'route']) | 4 relationships loaded |
| 2 | Nested eager load: studentSessions.student | Student name via session |

### TC-BIZ-DEEP-90: store() with null checkRouteId

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $checkRouteId = pickup_route_id ?? drop_route_id | First non-null route ID |
| 2 | If BOTH null → checkRouteId = null | DriverRouteVehicleJnt::where('route_id', null) |
| 3 | No results → 'No active vehicle assigned' | ValidationException thrown |

### TC-BIZ-DEEP-91: update() does not validate DB constraints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student can change in update() | New student_session_id fetched |
| 2 | No duplicate check for new student | Same student can be allocated twice |
| 3 | No capacity check for new route | Route could be over capacity |

### TC-BIZ-DEEP-92: destroy() only decrements pickup_route total_students

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | where('route_id', pickup_route_id) | Only pickup route checked |
| 2 | Drop-only: pickup_route_id is NULL → no match | Decrement not executed for drop-only |
| 3 | Both-type: only pickup decremented, drop ignored | Vehicle counts out of sync |

### TC-BIZ-DEEP-93: No vehicle count update on route change via update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Old route: total_students NOT decremented | Inflated count |
| 2 | New route: total_students NOT incremented | Deflated count |
| 3 | Capacity tracking broken on edit | Counts inaccurate over time |

### TC-BIZ-DEEP-94: Import creates duplicates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | StudentAllocationImport::model() returns new model | Direct creation, no duplicate check |
| 2 | validateFile() attempted check (with bug at line 390) | Buggy check not caught |

### TC-BIZ-DEEP-95: Import does not check vehicle capacity

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No capacity check in model() | Raw inserts without business logic |
| 2 | No DriverRouteVehicleJnt::increment() | Vehicle counts not updated |

### TC-BIZ-DEEP-96: Import default type 'both_side' wrong ENUM

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | $type = 'both_side' default | Does not match ENUM('Both','Drop','Pickup') |
| 2 | MySQL strict mode → data truncated | Error or silent truncation |

### TC-BIZ-DEEP-97: Import route mapped from code only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Route::where('code', $routeCode)->first() | Route found by code |
| 2 | 'route_id' => $route->id (not fillable) | Route info lost |
| 3 | No mapping to pickup_route_id or drop_route_id | Both routes not stored |

### TC-BIZ-DEEP-98: validateFile() already-allocated check bug

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | where('student_session_id', $studentSession->student_id) | BUG: student_id not session PK |
| 2 | student_session_id stores session PK | $studentSession->student_id is wrong value |
| 3 | False negative → thinks not allocated when it is | Data integrity risk |

### TC-BIZ-DEEP-99: validateFile() undefined array key warnings

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access $row['student_roll'], $row['route_code'] etc. | Null coalescing ?? '' on most |
| 2 | Missing Excel column → PHP Warning | Potential undefined array key |

### TC-BIZ-DEEP-100: Complete authorization analysis

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Controller: tenant.student-allocation.* | 10 permission checks |
| 2 | Policy: tenant.transport.* | Completely different namespace |
| 3 | Blade: tenant.student-allocation.* | Same as controller |
| 4 | Request: tenant.student-allocation.create/update | Same mismatch |
| 5 | Result: Authorization likely broken for non-admin users | 403 on every action |

---

### CODE-TRACE: index() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET /transport/student-allocation with ?tab=stdtransport | Request received |
| 2 | StudentAllocationController::index() called | Line 34 |
| 3 | Gate::authorize('tenant.student-allocation.viewAny') | Policy check |
| 4 | return view('transport::index') | Tabbed interface view |
| 5 | **Note**: Controller does NO data query — `view('transport::index')` | Actual data loading delegated to a different controller/service |
| 6 | Tab view likely renders livewire or blade component that queries data | Data shown via separate request |
| 7 | The complex filtering (route_id, status, class_id, transport_use_type) | Handled by StudentRouteFeesController or Query Builder, NOT here |

### CODE-TRACE: create() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET /transport/student-allocation/create | Request received |
| 2 | Query 1: PickupPointRoute with pickup_drop IN ('Pickup','Both'), is_active=1 | Pickup-compatible points |
| 3 | Query 2: PickupPointRoute with pickup_drop IN ('Drop','Both'), is_active=1 | Drop-compatible points |
| 4 | Gate::authorize('tenant.student-allocation.create') | Authorization |
| 5 | View data: students=[], routes=Route::all(), pickupPoints, dropPoints, classes | Form rendered |
| 6 | JS: Class dropdown → AJAX to getSections(classId) | Sections loaded |
| 7 | JS: Section dropdown → AJAX to getStudents(class_section_id) | Students loaded |

### CODE-TRACE: store() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST /transport/student-allocation with form data | Request received |
| 2 | StudentAllocationRequest injected — authorize() checks create | Line 15-16 |
| 3 | prepareForValidation() normalizes is_active | $this->boolean('is_active') |
| 4 | rules() validates: 8 field rules, after_or_equal:today for POST | Validation passes |
| 5 | store() called — Gate double-check at line 70 | Authorized |
| 6 | DB::transaction(function () { | Transaction begins |
| 7 | Query: StudentAcademicSession::where('student_id', id)->first() | SELECT ... LIMIT 1 |
| 8 | $data = $request->all() | All request data |
| 9 | If type=Pickup: drop fields nullified | Lines 83-85 |
| 10 | If type=Drop: pickup fields nullified | Lines 86-89 |
| 11 | $data['student_session_id'] = session->id or '' | Line 92 |
| 12 | TptStudentAllocationJnt::create($data) | INSERT INTO tpt_student_route_allocation_jnt |
| 13 | $checkRouteId = pickup_route_id ?? drop_route_id | First non-null route |
| 14 | Query: DriverRouteVehicleJnt with('vehicle')->where('route_id', id)->where('is_active',1)->first() | Active vehicle check |
| 15 | If no route-vehicle: throw ValidationException | Lines 105-109 |
| 16 | $vehicle = $drvRoute->vehicle | Get vehicle |
| 17 | If no vehicle: throw ValidationException | Lines 116-120 |
| 18 | Query: Setting where key = 'allow_extra_student_in_vehicale_beyond_capacity' | Setting value |
| 19 | $allowExtra = filter_var(..., FILTER_VALIDATE_BOOLEAN) | Boolean normalize |
| 20 | $capacityLimit = $allowExtra ? max_capacity : capacity | Capacity limit |
| 21 | If total_students >= capacityLimit: throw | Capacity check |
| 22 | $drvRoute->increment('total_students') | total_students +1 |
| 23 | activityLog($studentAllocation, 'Created', ...) | Activity log |
| 24 | Transaction commits | End transaction |
| 25 | RemoteEntryService::processEvent('TRANSPORT','TPT_NEW_REGISTRATION',...) | Accounting event (outside transaction) |
| 26 | redirect()->route('transport.std-route-Fees-mgmt.index')->with('success', flash(...)) | Redirect + flash |

### CODE-TRACE: show() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET /transport/student-allocation/{id} | Request received |
| 2 | Gate::authorize('tenant.student-allocation.view') | Authorized |
| 3 | TptStudentAllocationJnt::findOrFail($id) | SELECT * WHERE id = ? |
| 4 | If not found: 404 ModelNotFoundException | Error |
| 5 | return view('transport::student-allocation.show', compact('record')) | Detail view |

### CODE-TRACE: edit() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET /transport/student-allocation/{id}/edit | Request received |
| 2 | Gate::authorize('tenant.student-allocation.update') | Authorized |
| 3 | TptStudentAllocationJnt::findOrFail($id) | Record found |
| 4 | Query: PickupPointRoute for Pickup/Both (is_active=1) | Pickup points |
| 5 | Query: PickupPointRoute for Drop/Both (is_active=1) | Drop points |
| 6 | $allocation->load('studentSessions.classSection') | Eager load |
| 7 | View: allocation, students=Student::all(), routes=Route::all(), pickupPoints, dropPoints, classes, sections | Pre-filled form |

### CODE-TRACE: update() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT /transport/student-allocation/{id} | Request received |
| 2 | StudentAllocationRequest authorize() checks update | Authorized |
| 3 | prepareForValidation() normalizes is_active | Boolean |
| 4 | rules() — NO after_or_equal:today for PUT | Past date allowed |
| 5 | Gate::authorize('tenant.student-allocation.update') | Line 226 |
| 6 | TptStudentAllocationJnt::findOrFail($id) | Found |
| 7 | Snapshot: $oldPickupStopId, $oldDropStopId, $oldPickupRouteId, $oldDropRouteId | Change detection |
| 8 | Query: StudentAcademicSession::where('student_id', id)->first() | Re-fetch session |
| 9 | $data = $request->all(); type nullification | Same as store |
| 10 | $allocation->update($data) | UPDATE SET ... WHERE id = ? |
| 11 | activityLog($allocation, 'Updated', ...) | Log entry |
| 12 | If stopChanged: RemoteEntryService('TRANSPORT','TPT_PICKUP_CHANGE') | Conditional event |
| 13 | If routeChanged: RemoteEntryService('TRANSPORT','TPT_MODE_CHANGE') | Conditional event |
| 14 | redirect()->route('transport.std-route-Fees-mgmt.index')->with('success', flash(...)) | Redirect |

### CODE-TRACE: destroy() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE /transport/student-allocation/{id} | Request |
| 2 | Gate::authorize('tenant.student-allocation.delete') | Authorized |
| 3 | TptStudentAllocationJnt::findOrFail($id) | Active record |
| 4 | DB::transaction(function () { | Transaction |
| 5 | Query: DriverRouteVehicleJnt where route_id=pickup_route_id, is_active=1 | Finds vehicle |
| 6 | GAP: Only pickup_route_id, not drop_route_id | Drop-only may miss |
| 7 | if (drvRoute && total_students > 0) → decrement('total_students') | Count -1 |
| 8 | $allocation->delete() | SET deleted_at = NOW() |
| 9 | Transaction commits | End |
| 10 | activityLog($allocation, 'Trash', ...) AFTER transaction | Log entry |
| 11 | redirect + flash | Success |

### CODE-TRACE: trashed() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET /transport/student-allocation/trash | Request |
| 2 | Gate::authorize('tenant.student-allocation.restore') | Authorized |
| 3 | TptStudentAllocationJnt::onlyTrashed()->with([...])->paginate(20) | SELECT ... WHERE deleted_at IS NOT NULL |
| 4 | return view('transport::student-allocation.trash', compact('data')) | Trash view |

### CODE-TRACE: restore() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET /transport/student-allocation/{id}/restore | Request |
| 2 | Gate::authorize('tenant.student-allocation.restore') | Authorized |
| 3 | TptStudentAllocationJnt::onlyTrashed()->findOrFail($id) | Trashed record found |
| 4 | $allocation->restore() | SET deleted_at = NULL |
| 5 | activityLog($allocation, 'Restored', ...) | Log entry |
| 6 | redirect + flash | Success |

### CODE-TRACE: forceDelete() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE /transport/student-allocation/{id}/force-delete | Request |
| 2 | Gate::authorize('tenant.student-allocation.forceDelete') | Authorized |
| 3 | TptStudentAllocationJnt::onlyTrashed()->findOrFail($id) | BUG: onlyTrashed excludes active records |
| 4 | If trashed: $allocation->forceDelete() | DELETE FROM ... WHERE id = ? |
| 5 | activityLog($allocation, 'Force Delete', ...) | Log entry |
| 6 | redirect + flash | Success |

### CODE-TRACE: toggleStatus() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST /transport/student-allocation/toggleStatus/{id} with is_active | AJAX request |
| 2 | Gate::authorize('tenant.student-allocation.update') | Authorized |
| 3 | TptStudentAllocationJnt::findOrFail($id) | Record found |
| 4 | $status = filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN) | Boolean normalize |
| 5 | $allocation->active_status = $status | Uses active_status column |
| 6 | activityLog($allocation, 'Toggled', ['message' => ..., 'other' => ...]) | Log with extra data |
| 7 | $allocation->save() | UPDATE active_status = ?, updated_at = NOW() |
| 8 | If save succeeds: {success: true, active_status: 0/1, message: ...} | JSON success |
| 9 | If save fails: {success: false, message: ...} | JSON failure |

### CODE-TRACE: export() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET /transport/student-allocation/export with filters | Request |
| 2 | NO Gate::authorize() check | GAP — any user can export |
| 3 | StudentAllocationExport($request) instantiated | Filters passed |
| 4 | Excel::download(..., 'student_allocation.xlsx') | XLSX download |
| 5 | StudentAllocationQuery($this->request)->get() | All matching records |
| 6 | Headers: Roll No, Student Name, Class, Route, Pickup, Drop, Type, Status | 8 columns |

### CODE-TRACE: getSections() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET /transport/student-allocation-get-sections/{classId} | AJAX |
| 2 | NO Gate::authorize() check | GAP |
| 3 | ClassSection::where('class_id', classId)->with('section')->get() | Sections found |
| 4 | Map: [{id, name: section->name ?? 'N/A'}] | JSON response |

### CODE-TRACE: getStudents() full execution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET/POST /transport/student-allocation-get-students with class_section_id or class_id | AJAX |
| 2 | NO Gate::authorize() check | GAP |
| 3 | StudentAcademicSession::with('student')->where('is_current', 1) | Current sessions |
| 4 | If class_section_id: filter by it | Section filter |
| 5 | Elseif class_id: whereHas classSection on class_id | Class filter |
| 6 | Map: [{id: student_id, name: 'First Last (RollNo)'}] | JSON response |

---

## 7. Detailed Test Steps

### TC-P-01: Create Both allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.student-allocation.create` permission | Success |
| 2 | Navigate to `/transport/student-allocation/create` | Create form with Class dropdown, Section dropdown, Student dropdown, table fields |
| 3 | Select Class = "10" from `select[name=class_id]` | Class selected |
| 4 | Select Section = "A" from `select[name=class_section_id]` (AJAX-loaded based on class_id) | Section loaded, students populated |
| 5 | Select Student = "John Doe (101)" from `select[name=student_id]` | Student selected, student_session_id resolved |
| 6 | Select Transport Use Type = "Both" from `select[name=transport_use_type]` | Both Pickup and Drop fields enabled |
| 7 | Select Pickup Stop = "Main Gate (Route A)" from `select[name=pickup_stop_id]` | Hidden `pickup_route_id` populated via data-route |
| 8 | Select Drop Stop = "School Gate (Route B)" from `select[name=drop_stop_id]` | Hidden `drop_route_id` populated |
| 9 | Select Fare Amount = 500 | Auto-calculated or entered |
| 10 | Set Effective From = today's date | date picker |
| 11 | Set Active Status = checked | active_status=1 (checkbox + hidden input=0) |
| 12 | Click Save | POST to `student-allocation.store` |
| 13 | **Verify**: `StudentAllocationRequest::prepareForValidation()` sets `pickup_route_id`/`drop_route_id` from stop selects | Hidden values injected |
| 14 | **Verify**: `DB::beginTransaction()` | Transaction active |
| 15 | **Verify**: `StudentAcademicSession::where('student_id', student_id)->where('is_current', 1)->first()` | student_session_id found |
| 16 | **Verify**: `DriverRouteVehicleJnt::where('route_id', pickup_route_id)->where('is_active', 1)->first()` checks capacity | Vehicle exists with capacity > total_students |
| 17 | **Verify**: `TptStudentAllocationJnt::create()` with all 10 fillable fields + student_session_id | DB row created |
| 18 | **Verify**: `DriverRouteVehicleJnt::where('route_id', pickup_route_id)->increment('total_students')` | Count +1 |
| 19 | **Verify**: `DriverRouteVehicleJnt::where('route_id', drop_route_id)->increment('total_students')` | Count +1 for drop route |
| 20 | **Verify**: `DB::commit()` | Transaction committed |
| 21 | **Verify**: `activityLog()` called with "Created" event | Log entry created |
| 22 | **Verify**: `RemoteEntryService::sendData()` with `TPT_NEW_REGISTRATION` event | Remote event sent |
| 23 | **Verify**: Redirect to index with success flash | "Student Allocation created successfully." |

### TC-P-04: Create allocation at capacity limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure `DriverRouteVehicleJnt` for route has `total_students = capacity - 1` and `allow_extra = false` | One slot remaining |
| 2 | Create allocation on this route | Store path |
| 3 | **Verify**: `$vehicle->total_students < $vehicle->capacity` | true (under limit) |
| 4 | **Verify**: Allocation created | DB row inserted |
| 5 | **Verify**: `$vehicle->increment('total_students')` | Now total_students = capacity |
| 6 | **Verify**: capacity not exceeded | Max capacity = capacity |

### TC-P-07: Toggle status ON to OFF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to allocation list | Row visible with toggle ON |
| 2 | Click the active_status toggle switch | AJAX POST to `/transport/student-allocation/{id}/toggle-status` |
| 3 | **Verify**: `Gate::authorize('tenant.student-allocation.edit')` passes | Authorized |
| 4 | **Verify**: `$request->validate(['is_active' => 'required\|boolean'])` passes | Inline validation |
| 5 | **Verify**: `filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN)` returns false | Toggle was ON, now OFF |
| 6 | **Verify**: `$allocation->active_status = false` | Property set on `active_status` column |
| 7 | **Verify**: `$allocation->save()` | DB updated |
| 8 | **Verify**: `activityLog('Toggled')` called | Log entry |
| 9 | **Verify**: JSON response `{success: true, active_status: 0, message: "Student Allocation Status update"}` | 200 OK |
| 10 | **Verify**: Toggle switch unchecked | UI updated |

### TC-P-09: Soft delete allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Allocation exists with pickup_route_id=R1, drop_route_id=R2, active_status=1, deleted_at=NULL | Active record |
| 2 | Click delete button on allocation row | POST/DELETE to `student-allocation.destroy` |
| 3 | **Verify**: `Gate::authorize('tenant.student-allocation.delete')` passes | Authorized |
| 4 | **Verify**: `$allocation = TptStudentAllocationJnt::findOrFail($id)` | Record found |
| 5 | **Verify**: `DriverRouteVehicleJnt::where('route_id', $allocation->pickup_route_id)->decrement('total_students')` | Pickup route -1 |
| 6 | **Verify**: `DriverRouteVehicleJnt::where('route_id', $allocation->drop_route_id)->decrement('total_students')` | Drop route -1 |
| 7 | **Verify**: No `update(['active_status' => false])` before delete | **GAP**: active_status stays 1 in trash |
| 8 | **Verify**: `$allocation->delete()` | Soft delete, deleted_at set |
| 9 | **Verify**: `activityLog('Trash')` called | Log entry |
| 10 | **Verify**: Redirect with flash "Student Allocation deleted successfully." | Success |

### TC-P-10: Restore soft-deleted allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Allocation exists with deleted_at IS NOT NULL | In trash |
| 2 | Click restore button on trashed allocation | POST to `student-allocation.restore` |
| 3 | **Verify**: `Gate::authorize('tenant.student-allocation.delete')` passes | Authorized |
| 4 | **Verify**: `TptStudentAllocationJnt::onlyTrashed()->findOrFail($id)` | Trashed record found |
| 5 | **Verify**: `$allocation->restore()` | deleted_at = NULL |
| 6 | **Verify**: `activityLog('Restored')` called | Log entry |
| 7 | **Verify**: NO `DriverRouteVehicleJnt::increment('total_students')` | **GAP**: vehicle count not restored |
| 8 | **Verify**: Redirect with flash "Student Allocation restored successfully." | Success |

### TC-P-11: Force delete trashed allocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Allocation exists with deleted_at IS NOT NULL | Trashed |
| 2 | Click permanent delete button | POST to `student-allocation.forceDelete` |
| 3 | **Verify**: `Gate::authorize('tenant.student-allocation.delete')` passes | Authorized |
| 4 | **Verify**: `TptStudentAllocationJnt::onlyTrashed()->findOrFail($id)` | Found (record IS trashed) |
| 5 | **Verify**: `$allocation->forceDelete()` | Record permanently removed |
| 6 | **Verify**: `activityLog('Force Delete')` called | Log entry |
| 7 | **Verify**: Redirect with flash "Student Allocation force deleted successfully." | Success |
| 8 | **Verify**: DB: `SELECT * FROM tpt_student_route_allocation_jnt WHERE id = X` | Empty result |

### TC-P-13: Import valid Excel file

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare XLSX with 2 rows: Roll=101, Route=RT1, Pickup=MP1, Drop=DP1, Both, Fare=500, Status=Active, Date=today | Valid data |
| 2 | Click Import button | Modal opens |
| 3 | Upload XLSX file via file input | File selected |
| 4 | Click Validate | POST to `student-allocation.validateFile` |
| 5 | **Verify**: `Gate::authorize('tenant.student-allocation.create')` passes | Authorized |
| 6 | **Verify**: `$request->hasFile('import_file') && in_array($extension, ['xlsx', 'csv'])` | Valid file type |
| 7 | **Verify**: Each row checked: roll_no exists in DB → links to student_session_id | Valid |
| 8 | **Verify**: Each row checked: route_code exists in `tpt_route` | Valid |
| 9 | **Verify**: Each row checked: pickup_point_code exists in `tpt_pickup_points_route_jnt` | Valid |
| 10 | **Verify**: Each row checked: drop_point_code exists | Valid |
| 11 | **Verify**: Each row checked: student not already allocated | Not duplicate |
| 12 | **Verify**: Summary saved to session: `session(['import_summary' => ...])` | Summary stored |
| 13 | **Verify**: File saved to `public/storage/imports/` | Path stored in session |
| 14 | **Verify**: Text file download with "Total Rows: 2, Valid: 2, Errors: 0" | Summary.txt |
| 15 | Click Import button on modal | POST to `student-allocation.startImport` |
| 16 | **Verify**: Session has `import_file` path | File found |
| 17 | **Verify**: `Excel::import(new StudentAllocationImport, $file)` | Import executed |
| 18 | **Verify**: 2 records created in `tpt_student_route_allocation_jnt` | Rows inserted |
| 19 | **Verify**: Session cleared: `session(['import_file' => null])` | Session cleaned |
| 20 | **Verify**: JSON response `{status: "completed"}` | Success |

### TC-P-15: View single allocation details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.student-allocation.show` permission | Success |
| 2 | Navigate to allocation list | List visible |
| 3 | Click Show icon on row | GET to `student-allocation.show/{id}` |
| 4 | **Verify**: `Gate::authorize('tenant.student-allocation.show')` passes | Authorized |
| 5 | **Verify**: `TptStudentAllocationJnt::with(['student', 'pickupRoute', 'dropRoute', 'pickupStop', 'dropStop'])->findOrFail($id)` | Record with all relations |
| 6 | **Verify**: Student name, Roll No, Class, Section displayed | Student info |
| 7 | **Verify**: Pickup Route + Pickup Stop displayed | Pickup info |
| 8 | **Verify**: Drop Route + Drop Stop displayed | Drop info |
| 9 | **Verify**: Transport Use Type, Fare, Effective From, Status displayed | All fields |
| 10 | **Verify**: Back button navigates to index | Navigation |

### TC-N-01: Create without student_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select Class, Section | Valid selections |
| 3 | Leave Student dropdown empty | student_id = null |
| 4 | Select Both type, Pickup Stop, Drop Stop | Other fields filled |
| 5 | Click Save | Form submission |
| 6 | **Verify**: `StudentAllocationRequest` rule: `student_id` is `required` | Validation fails |
| 7 | **Verify**: Error message: "Please select a student." | Validation error |
| 8 | **Verify**: No DB record created | DB unchanged |

### TC-N-11: Force delete active record — GAP

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create allocation (active, not deleted) | id=X, deleted_at=NULL |
| 2 | Call `forceDelete(X)` via trash action force-delete | Controller `forceDelete()` hit |
| 3 | **Verify**: `Gate::authorize('tenant.student-allocation.delete')` passes | Authorized |
| 4 | **Verify**: `TptStudentAllocationJnt::onlyTrashed()->findOrFail($id)` | `onlyTrashed()` adds WHERE deleted_at IS NOT NULL |
| 5 | Record has deleted_at=NULL → not found | `findOrFail()` throws ModelNotFoundException |
| 6 | **Verify**: 404 response | "No query results" |
| 7 | **Compare** correct pattern: should use `withTrashed()` | Would find active records |
| 8 | **Workaround**: Must soft-delete first, then force-delete | Two-step process |
| 9 | **Impact**: forceDelete unusable on active records | **GAP** |

### TC-N-13: Import — missing student roll

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare XLSX: 1 row with empty Roll No column | Missing data |
| 2 | Upload and click Validate | validateFile called |
| 3 | **Verify**: Row iteration checks `$row['roll_no']` is empty | Condition: `empty($row['roll_no'])` |
| 4 | **Verify**: Error added: "Student Roll missing" | Error row 1 |
| 5 | **Verify**: Summary.txt shows "Errors: 1" | Validation fails |
| 6 | **Verify**: No records imported | DB unchanged |

### TC-N-15: Import — student already allocated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure Roll=101 already has an active allocation | Existing record |
| 2 | Prepare XLSX: Roll=101, Route=RT1 | Same student |
| 3 | Upload and click Validate | validateFile called |
| 4 | **Verify**: `StudentAllocationImport::alreadyAllocatedCheck()` runs query | Line 390 hit |
| 5 | **Verify**: Query uses `where('student_session_id', $studentSession->student_id)` | **BUG**: Uses student_id not session PK |
| 6 | **Verify**: If bug bypasses duplicate check → record created | Duplicate possible |
| 7 | **Verify**: Error added if correctly caught: "Student already allocated" | Validation error |

### TC-N-18: Access without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.student-allocation.*` permissions | Limited user |
| 2 | Navigate to `/transport/student-allocation` | Gate check or middleware |
| 3 | **Verify**: Policy `viewAny()` checks `tenant.student-allocation.index` | Permission denied |
| 4 | **Verify**: 403 Forbidden response | Access denied |
| 5 | **Verify**: Controller's authorize() uses `tenant.student-allocation.index` | **Note**: Policy uses `tenant.transport.*` — mismatch |

### TC-D-01: Verify total_students increment on create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `DriverRouteVehicleJnt` for pickup_route_id: `total_students = N` | Baseline |
| 2 | Check `DriverRouteVehicleJnt` for drop_route_id: `total_students = M` | Baseline |
| 3 | Create Both allocation on these routes | Store executes |
| 4 | **Verify**: `increment('total_students')` on pickup_route_id | N+1 |
| 5 | **Verify**: `increment('total_students')` on drop_route_id | M+1 |
| 6 | **Verify**: Only Pickup routes incremented for Pickup type | +1 only pickup |
| 7 | **Verify**: Only Drop routes incremented for Drop type | +1 only drop |

### TC-D-06: Verify FK RESTRICT prevents parent deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify `tpt_student_route_allocation_jnt` with `pickup_stop_id = X` | Allocation using stop X |
| 2 | Execute `DELETE FROM tpt_pickup_points_route_jnt WHERE id = X` | FK violation |
| 3 | **Verify**: SQL error: "Cannot delete or update a parent row: a foreign key constraint fails" | RESTRICT blocks deletion |
| 4 | **Verify**: Record still exists in `tpt_pickup_points_route_jnt` | Parent preserved |
| 5 | Repeat for `student_id` FK (references `users.id` RESTRICT) | Same behavior |
| 6 | Repeat for `pickup_route_id`, `drop_route_id` FKs | Same behavior |

### TC-D-12: Verify transaction rollback on exception in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create scenario: `TptStudentAllocationJnt::create()` succeeds | Allocation created |
| 2 | Force exception in code after create (e.g. in `increment()` or `activityLog()`) | Exception thrown |
| 3 | **Verify**: `DB::rollBack()` called | Transaction rolled back |
| 4 | **Verify**: `SELECT * FROM tpt_student_route_allocation_jnt ORDER BY id DESC LIMIT 1` | No new record |
| 5 | **Verify**: `DriverRouteVehicleJnt.total_students` unchanged | No orphan increment |

### TC-CR-01: GAP — forceDelete() uses onlyTrashed()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `StudentAllocationController.php:333` | `forceDelete($id)` method |
| 2 | Find the query: `TptStudentAllocationJnt::onlyTrashed()->findOrFail($id)` | Line 335 |
| 3 | **Verify**: `onlyTrashed()` scope adds `WHERE deleted_at IS NOT NULL` | Only trashed records queryable |
| 4 | Call with active record (deleted_at = NULL) | `findOrFail()` throws ModelNotFoundException |
| 5 | Expected: `withTrashed()` instead of `onlyTrashed()` | `withTrashed()` includes non-deleted |
| 6 | **Compare** with `restore()` method (line 312) which correctly uses `onlyTrashed()` | restore() is correct (only restores trashed) |
| 7 | **Fix**: Replace `onlyTrashed()` with `withTrashed()` on line 335 | Correct behavior |
| 8 | **Impact**: forceDelete fails on active records | **GAP** — must soft-delete first |

### TC-CR-16: Import — alreadyAllocatedCheck uses wrong field (BUG)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `StudentAllocationImport.php:390` | `alreadyAllocatedCheck()` method |
| 2 | Find query: `TptStudentAllocationJnt::where('student_session_id', $studentSession->student_id)` | Line 390 |
| 3 | **Verify**: `$studentSession->student_id` is the FK to users table | e.g., value = 42 |
| 4 | **Verify**: `student_session_id` column in `tpt_student_route_allocation_jnt` stores `StudentAcademicSession.id` PK | e.g., value = 101 |
| 5 | **Compare**: Query compares session PK column to student FK value | Mismatch: 42 ≠ 101 |
| 6 | **Correct**: Should be `$studentSession->id` (the PK of StudentAcademicSession) | Fixes the match |
| 7 | **Impact**: Already-allocated check never catches duplicates | **BUG** — always passes |

### TC-CR-17: Import — type mapping mismatch with ENUM (BUG)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `StudentAllocationImport.php:58-69` | `model()` method type mapping |
| 2 | Map logic: `both_side` → `Both`, `pickup_only` → `Pickup`, `drop_only` → `Drop` | Mapping exists |
| 3 | Check DB ENUM definition: `'Both', 'Pickup', 'Drop'` | ENUM values |
| 4 | **Verify**: `type` field stores through accessor/mutator or directly | Direct DB insert |
| 5 | **Verify**: `'Both'` matches ENUM 'Both' | OK |
| 6 | **Verify**: `'Pickup'` matches ENUM 'Pickup' | OK |
| 7 | **Verify**: `'Drop'` matches ENUM 'Drop' | OK |
| 8 | **Extra check**: If mapping is `ucfirst(str_replace('_', ' ', $value))` | Converts "both_side" → "Both Side" |
| 9 | **Verify**: "Both Side" does NOT match ENUM 'Both' | **BUG** if this path is taken |
| 10 | **Impact**: Import silently fails or stores wrong value | **BUG** — possible ENUM violation |

### TC-CR-22: GAP — destroy() only decrements pickup_route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `StudentAllocationController.php:488-499` | `destroy($id)` method |
| 2 | Find decrement logic: `DriverRouteVehicleJnt::where('route_id', $allocation->pickup_route_id)->decrement('total_students')` | Line 490 |
| 3 | **Verify**: Only `pickup_route_id` is decremented | Drop route NOT decremented |
| 4 | Create Both allocation with pickup=R1, drop=R2 | Vehicle counts: pickup=N, drop=M |
| 5 | Delete this allocation | destroy() called |
| 6 | **Verify**: `DriverRouteVehicleJnt` pickup route decremented | N-1 |
| 7 | **Verify**: `DriverRouteVehicleJnt` drop route NOT decremented | Still M (should be M-1) |
| 8 | **Fix**: Add decrement for drop_route_id | Two decrements needed |
| 9 | **Impact**: Vehicle capacity count drifts for drop routes | **GAP** — data inconsistency |

### TC-CR-24: GAP — restore() doesn't restore total_students

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `StudentAllocationController.php:312-325` | `restore($id)` method |
| 2 | Find any increment of `total_students` | NOT found |
| 3 | **Verify**: Method only calls `restore()` and `activityLog()` | No vehicle count adjustment |
| 4 | Create allocation → delete it (pickup=N, drop=M) | Vehicle counts decreased |
| 5 | Restore the allocation | restore() called |
| 6 | **Verify**: `total_students` pickup route | Still N-1 (should be restored to N) |
| 7 | **Verify**: `total_students` drop route | Still M-1 (should be restored to M) |
| 8 | **Compare** with PickupStopsList `restore()` which also lacks count restore | Consistent GAP pattern |
| 9 | **Fix**: Add `increment('total_students')` for both pickup and drop routes | Correct behavior |
| 10 | **Impact**: Vehicle total_students drifts down over delete/restore cycles | **GAP** — data inconsistency |

### TC-CR-23: GAP — store() RemoteEntryService outside transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `StudentAllocationController.php:74-175` | `store()` method |
| 2 | Find `DB::beginTransaction()` at line 76 | Transaction starts |
| 3 | Find `DB::commit()` at line 157 | Transaction commits |
| 4 | Find `RemoteEntryService::sendData()` calls | Lines 159-169 |
| 5 | **Verify**: Remote events fire AFTER `DB::commit()` | Outside transaction |
| 6 | Scenario: DB insert succeeds, commit succeeds, RemoteEntryService throws | Allocation created but remote event lost |
| 7 | Allocation exists in DB | Created without remote sync |
| 8 | **Impact**: Remote system never notified of new registration | **GAP** — no rollback of allocation on remote failure |

### TC-CR-28: GAP — no duplicate check in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `StudentAllocationController.php:68-175` | `store()` method |
| 2 | Search for any duplicate check before create | NOT found |
| 3 | Create allocation for student S1 on route R1 | First record created |
| 4 | Create allocation for same student S1 on same routes | Second record created (no error) |
| 5 | **Verify**: Two identical allocation records exist | No unique constraint |
| 6 | **Verify**: `total_students` incremented twice | Double count |
| 7 | **Fix**: Add `TptStudentAllocationJnt::where('student_session_id', ...)->whereNull('deleted_at')->exists()` check before create | Duplicate prevention |
| 8 | **Impact**: Students can be double-allocated | **GAP** — data inconsistency |

*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: StudentAllocation | Date: 2026-07-21*
