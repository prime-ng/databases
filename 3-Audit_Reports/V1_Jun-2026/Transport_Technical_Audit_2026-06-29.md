## Technical Audit — Transport (TPT) — 2026-06-29

### Executive Summary
Mode A (12-layer, read-only) of the live `Modules/Transport` tree — the platform's largest module (30 controllers incl. a 1,984-line Mobile controller, 35 models, **0 service classes**, 0 jobs, 0 events, ~47 policies). The headline P0 is a live `dd($e)` in a bulk trip-update catch block (`TripController.php:587`) that halts the request and dumps a stack trace. Driver Aadhaar/licence numbers remain stored unencrypted (SEC-TPT-005, legal exposure under the Aadhaar Act / DPDP), a hardcoded Google Maps API key ships to the browser from three views, and Transport is among the modules with no `EnsureTenantHasModule` subscription gate (platform TEN-RTG-001). Verifying against live code corrected several stale "known" items: the `tested.` gate typo is **fixed**, capacity enforcement **is implemented**, allocation is **transactional**, and the migrations have **0 enums** (not the baseline's 19). **Health: 38/100 (P0 cap applied).**

### Audit Mode(s) Run
- **Mode A** — full 12-layer scan, verified against live code (not the 2026-06-25 knowledge snapshot).
- An FRD now exists (`TPT_FRD_2026-06-29.md`) — a Mode B/C pass is the recommended follow-up; this report cross-references its BRs where relevant.

### Health Score
P0 present (`dd($e)` live catch) → weighted index ~46 but **capped at 40**; with the PII-at-rest exposure the effective score is **38/100**.

---

### P0 Findings

```
[BUG-TPT-011] Severity: P0 | dd($e) in live bulk trip-update catch block (NEW)
- Location: Modules/Transport/app/Http/Controllers/TripController.php:587
- Evidence:
        TptTrip::where('id', $trip->id)->update($updateData);   // bulk time update
        ...
      return back()->with('success', "{$updatedCount} trip(s) updated successfully!");
    } catch (\Exception $e) {
        dd($e);                 // <-- halts request, dumps stack trace to the browser
    }
- Why it's a risk: any exception in the bulk trip-time update dies with a full stack dump (paths,
    SQL, env fragments) instead of a handled error — information disclosure + broken UX on a write path.
- Fix: replace with logged handling + a user-facing redirect-back-with-error (as the module's other
    catches do).
- Confidence: High. Downgrades to P1 only because the action is an admin-only bulk update (still a
    live dd in a catch → P0 per the platform rule).
- Systemic? : same class as the (now-fixed) Complaint/Library dd findings.
```

```
[SEC-TPT-005] Severity: P0 (re-confirmed open) | Driver Aadhaar/PAN/licence stored unencrypted
- Location: Modules/Transport/app/Models/DriverHelper.php  ($fillable id_no:31, license_no:36; $casts:59-72)
- Evidence:
    protected $fillable = [ ... 'id_no', ... 'license_no', ... ];
    protected $casts = [ 'license_valid_upto'=>'date', 'driving_exp_months'=>'integer',
                         'police_verification_done'=>'boolean', ... ];   // NO 'id_no'=>'encrypted'
- Why it's a risk: tpt_personnel.id_no holds Aadhaar/PAN/Passport numbers in plaintext. Storage of
    Aadhaar without encryption is unlawful (Aadhaar Act 2016 / UIDAI); DPDP Act 2023 classes it sensitive.
- Fix: cast 'id_no' and 'license_no' to 'encrypted'; add an id_no_hash (SHA-256) column for exact-match
    search; encrypt the device push token too. Display masked (last 4).
- Confidence: High
- Systemic? : same class as SEC-FOF-004 (FrontOffice Aadhaar) — cross-module PII pattern.
```

### P1 Findings

```
[FE-TPT-001] Severity: P1 | Hardcoded Google Maps API key shipped to the browser (committed secret) (NEW)
- Location: resources/views/pickup_point/create.blade.php:165 ; edit.blade.php:171 ; pickup_point.blade.php:94
- Evidence:
    <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyA5wiiyExnsmv3Drg_dRs4oTyU8Ww7iihQ&libraries=places">
- Why it's a risk: a live API key is committed to source and shipped to every visitor's browser in 3
    views → key theft / quota abuse / billing fraud.
- Fix: move the key to config, restrict it (HTTP-referrer + API restrictions) in the Google console, and
    rotate the exposed key.
- Confidence: High
- Systemic? : Layer 11.2 / 12.1 (committed source secret).
```

```
[SEC-TPT-004] Severity: P1 (re-confirmed open) | updateLastSeen() has no authorization and force-enables the device
- Location: Modules/Transport/app/Http/Controllers/AttendanceDeviceController.php (updateLastSeen, ~:261)
- Evidence:
    public function updateLastSeen(Request $request, $deviceUuid) {
        $device = AttendanceDevice::where('device_uuid', $deviceUuid)->first();
        if ($device) { $device->update(['pg_last_seen_at'=>now(), 'is_active'=>true]); ... }  // no Gate::authorize
- Why it's a risk: a state-changing write with no authorization; worse, it unconditionally sets
    is_active=true, so a deactivated device re-enables itself on any ping. (Every other method in this
    controller is correctly gated — see snapshot correction below.)
- Fix: gate it (or authenticate the device), and do not flip is_active on a heartbeat.
- Confidence: High (method ungated). Route exposure (public vs auth-group) should be confirmed.
- Systemic? : Layer 5.1.
```

```
[VAL-TPT-001] Severity: P1 | All 19 FormRequests authorize() return true (D30)
- Location: Modules/Transport/app/Http/Requests/*.php (19 of 19)
- Evidence: each authorize() { return true; }
- Why it's a risk: the request layer performs no authorization; defense-in-depth relies entirely on
    controller Gate calls (which are mostly present, but updateLastSeen and others slip through).
- Fix: return Gate::allows('tenant.{resource}.{action}') matching each route.
- Confidence: High
- Systemic? : D30 (platform norm; Transport at 19/19).
```

```
[PERF-TPT-001] Severity: P1 | God controllers + eager tab loading + unbounded ::all()
- Location: Mobile/MobileTransportController.php (1,984), TransportReportController.php (1,054),
    TripController.php (800); tab controllers load all sub-resource data per request; ::all() in
    PickupPointRouteController(2), VehicleMgmtController(4), StudentAllocationController(3), StaffMgmtController(1)
- Why it's a risk: >1000-line controllers + single-request tab loads + unbounded fetches → slow pages
    and untestable logic (compounded by 0 service classes for 30 controllers).
- Fix: extract services (TransportAllocation/Trip/Fee/Attendance), lazy-load tabs via AJAX, paginate/bound
    the ::all() lookups.
- Confidence: High
- Systemic? : Layer 4.4 + 9.3.
```

### P2 Findings

```
[MIG-TPT-001] Severity: P2 | Trip/fee status columns are free-text VARCHAR, not dropdown FKs (three-way gap)
- Location: migration create_tpt_trip_table.php:24  $table->string('status',20)->default('Scheduled');
    model TptTrip 'status' plain fillable, no cast; FSM (BR-TPT-005) compares string literals.
    Same for tpt_student_fee_detail/collection status + payment_mode (DB-10..13).
- Why it's a risk: the trip lifecycle FSM relies on free-text equality (typo-fragile, no referential
    integrity); D29 intent (dropdown FK) unmet. Also DB-03: tpt_trip has no is_active column.
- Fix: convert status/payment_mode to *_id FK → sys_dropdown_table; add is_active to tpt_trip.
- Confidence: High
- Systemic? : D29-adjacent (VARCHAR status instead of dropdown FK).
```

```
[DEAD-TPT-002] Severity: P3->P2 | Orphan controller backup committed
- Location: Modules/Transport/app/Http/Controllers/TransportController.php-old
- Why it's a risk: dead code in source; prior audits flagged a dead route reference to it. P2 if any
    route still references it, else P3.
- Fix: delete the file; confirm no route references it.
- Confidence: High
```

### P3 Findings
- DDL casing bugs `tpt_fine_master.Remark`, `tpt_vehicle_service_request.Vehicle_status` (DB-15/17).
- View directory naming inconsistency (`daily-vehicle-Inspection/`).

---

## STEP 1 Reading-Discipline Output (D-pattern)

### Three-Way Schema Reconciliation (DDL ↔ migration ↔ model)
| Subject | DDL spec | Live migration | Model / code | Verdict |
|---------|----------|----------------|--------------|---------|
| `tpt_trip.status` | "should be dropdown FK" (DB-10) | `string('status',20)` plain VARCHAR | `TptTrip` plain fillable; FSM compares literals | All three agree on a weak design → MIG-TPT-001; trip FSM is typo-fragile. |
| `tpt_trip.is_active` | expected (DB-03) | absent | model casts `is_active`→bool | migration missing the column the model casts → latent. |
| `tpt_personnel.id_no` | PII, must encrypt (NFR-TPT-01) | column present | `$casts` has **no** `encrypted` | model vs requirement → SEC-TPT-005 (P0). |
| D36 generated columns | none in TPT DDL | — | — | **Clean** — Transport has no GENERATED columns, so the D36 degradation does not apply here. |

### Module-Knowledge Snapshot Corrections (hints vs live code)
Knowledge file dated 2026-06-25; live tree 2026-06-29 differs — **four "known" P0/gap items are stale:**
- **`tested.` gate typo (SEC-TPT-003/010) → FIXED.** `AttendanceDeviceController` now uses `tenant.attendance-device.*` on all 10 gated methods. The "100% of device requests 403" blocker no longer exists.
- **"Route capacity enforcement missing" → IMPLEMENTED.** `StudentAllocationController:125-141` reads the `allow_extra_student_in_vehicale_beyond_capacity` setting and blocks at `total_students >= capacity/max_capacity` (BR-TPT-001 100% block present; explicit 90% warning not evident).
- **Allocation atomicity (BR-TPT-009) → PRESENT.** store and toggle paths are wrapped in `DB::transaction` (`StudentAllocationController:74,488`).
- **D29 "tpt 19 enums" (baseline) → 0 enums.** TPT migrations use `string()` columns, not `->enum()`; the D29 manifestation here is free-text VARCHAR status (MIG-TPT-001), not ENUM.
- Still-true from the snapshot: **0 service classes** (confirmed — no `app/Services/`), Aadhaar plaintext (SEC-TPT-005), `dd($e)` at TripController:587, no `EnsureTenantHasModule` (TEN-RTG-001).

---

### Layer Health Summary
| Layer | Status | Key finding |
|-------|--------|-------------|
| 1 DDL Schema | 🟡 | VARCHAR status (DB-10..13), casing bugs; D36 N/A |
| 2 Migration↔Model↔DDL | 🟡 | tpt_trip is_active missing; status not FK |
| 3 ORM | 🟢 | casts present (except the PII encryption gap, reported under 5) |
| 4 Code Quality | 🔴 | 1,984-line god controller; 0 services; `.php-old` orphan |
| 5 Authorization | 🔴 | updateLastSeen ungated (SEC-TPT-004); 19/19 FormRequests true |
| 6 Multi-Tenancy | 🟡 | RSP tenancy present; **no EnsureTenantHasModule** (TEN-RTG-001); no initialize() leaks |
| 7 Validation/Mass-assign | 🟡 | 0 `$request->all()` (good); D30 across all requests |
| 8 Data Integrity/Tx | 🟢 | allocation transactional; lockForUpdate on driver assign; capacity enforced |
| 9 Performance | 🟡 | eager tab loads, unbounded ::all() |
| 10 Queue/Job | ⚪ | no jobs/events (compliance/licence-expiry scheduled jobs not built — REQ-TPT-019 gap) |
| 11 Frontend/Output | 🔴 | committed Google Maps key in 3 views (FE-TPT-001) |
| 12 Deployment | 🟡 | committed key; otherwise no module route closures |

### vs Platform Baseline
- D30: 19/19 FormRequests `true` — at the platform norm.
- `$request->all()`: **0** sinks — better than baseline.
- `EnsureTenantHasModule`: Transport is among the 25/26 module groups missing it (TEN-RTG-001 / SEC-PLATFORM-001).
- Committed Maps key — same class as the baseline's Transport pickup_point example (re-confirmed live, now coded FE-TPT-001).

### Recommended Fix Order
1. **BUG-TPT-011** (P0) — remove the `dd($e)` at TripController:587.
2. **SEC-TPT-005** (P0/legal) — encrypt `id_no`/`license_no` + device token; add hashed search column.
3. **FE-TPT-001** (P1) — rotate + restrict + config-move the Maps key.
4. **SEC-TPT-004** (P1) — gate `updateLastSeen` and stop force-enabling devices.
5. **TEN-RTG-001** (P1, platform) — add `EnsureTenantHasModule:TPT` to the transport route group.
6. **VAL-TPT-001 / PERF-TPT-001 / MIG-TPT-001** — FormRequest authorize(), service-layer extraction + tab lazy-load, status→dropdown FK.

---
*Read-only audit. Handoffs: P0/P1 → Developer; status→FK + is_active → DB Architect; Mode B/C against `TPT_FRD_2026-06-29.md` → Technical Auditor; 0-test coverage → Testing Architect.*
