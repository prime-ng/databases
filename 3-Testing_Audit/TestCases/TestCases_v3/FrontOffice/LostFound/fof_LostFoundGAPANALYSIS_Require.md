# Lost & Found — Gap Analysis & Traceability

> Feature **FrontOffice / LostFound** · 45 test methods · single suite `fof_LostFound_TestCas.php`.

## Coverage Summary (by TC category)
| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive (TC-P) | 19 | 19 | 0 | 0 | 100% |
| Negative (TC-N) | 18 | 18 | 0 | 0 | 100% |
| Dependency (TC-D) | 4 | 4 | 0 | 0 | 100% |
| Known-defect (TC-DEV) | 9 | 9 | 0 | 0 | 100% |
| **Total** | **50** | **50** | **0** | **0** | **100%** |

Targets met: Negative 100%, Positive ≥90% (100%), Dependency ≥90% (100%). Tenancy/security smoke present (90–99 band).

## TC ↔ Method map
Every TC in the TcList §3 maps to ≥1 method; every method (§4 Method Index) maps back to a TC/BC. No orphan methods. See TcList §4 for the 1:1 table.

## Coverage-Score (by requirement Source)
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 6 | 6 | 100% |
| State-Machine (BC-SM) | 5 | 5 | 100% |
| Validation (BC-VAL) | 6 | 6 | 100% |
| DB constraints (BC-DB) | 16 | 16 | 100% |
| Integration/FK (BC-REF/INT) | 3 | 3 | 100% |
| Permissions (BC-AUTH) | 6 | 6 | 100% |

DDL coverage obligations: UNIQUE (item_number) → TC-N05 ✅ (G43); every NOT-NULL-no-default col → TC-N01 ✅ (G44); sized strings item_description/found_location → over-length TC-N02/N03 + max-length TC-P11 ✅ (G45); `test_01` full alignment matrix incl. independent soft-delete ✅ (G46); CRUD via verified `LostFound` model ✅ (G47); auto fields (item_number/status/created_by) tested as auto-behaviour, not inputs ✅ (G48).

## Cross-Reference Defect Scan (layer-vs-layer)
| # | Check | Compare | Finding | ID | Proving test |
|---|-------|---------|---------|----|--------------|
| 1 | Enum case/coverage | DDL status ENUM vs FormRequest `in:` | `Returned_to_Authority` in DDL, omitted from update `in:` + edit Blade + index filter → unreachable | **DEV-LF-005** | `test_..._25` |
| 3 | Gate vs Policy | controller `Gate::authorize` string gates vs Policy | string gates only (no model-bound policy) — module-wide, matches SEC-FOF-001 pattern | note | `test_..._54` |
| 8 | Validation vs FormRequest | screen intent vs `rules()` | `category`, `found_by_name`, `disposal_notes` never validated/captured | **DEV-LF-001/008** | `test_..._41/74` |
| 9 | Error message vs source | claim abort messages | "Item already claimed." / "Item has been disposed." verbatim | ok | `test_..._21/22` |
| 12 | UNIQUE enforcement | DDL UNIQUE vs FormRequest `unique:` | item_number auto-gen; DB UNIQUE enforced, no `unique:` rule needed (auto field) | ok (G48) | `test_..._40` |
| 13 | Required enforcement | DDL NOT NULL vs FormRequest `required` | `found_location` NOT NULL but request `nullable`; `category`/`found_by_name` NOT NULL but absent from rules | **DEV-LF-002/001** | `test_..._30/35/41` |
| 14 | Length enforcement | DDL VARCHAR(n) vs FormRequest `max:` | `item_description` max:150 < col 300; claim() `claimant_name` max:150 > col 100, `claimant_contact` max:20 > col 15 | **DEV-LF-003/004** | `test_..._36/37` |
| 15 | Soft-delete col vs trait | DDL `deleted_at` vs model `SoftDeletes` | both present — consistent (asserted independently) | ok | `test_..._01` |
| 6/7 | Activity/logging vs impl | expected audit trail vs controller | store/update/destroy/toggleStatus emit no log; `item_claimed` naming inconsistent | **DEV-LF-006** | `test_..._14` |
| 7 | State machine vs impl | intended FSM vs update() | update() enforces no transition guard | **DEV-LF-007** | `test_..._24` |
| — | D30 authorize | FormRequest authorize() | returns `true` | **SEC-FOF-003** | `test_..._92` |

## Defect Register (feature-local)
| ID | Sev | Summary | Layer | Proving test | Status |
|----|-----|---------|-------|--------------|--------|
| DEV-LF-001 | P1 | `store()` cannot persist: `category` (ENUM NN, no default) + `found_by_name` (NN) never set; `found_location` (NN) nullable in request → insert fails / 500 | Controller+Request+Blade | `test_..._41`, `_30` | Open (asserts current) |
| DEV-LF-002 | P2 | `found_location` DDL NOT NULL vs FormRequest `nullable` | Request vs DDL | `test_..._35` | Open |
| DEV-LF-003 | P3 | `item_description` FormRequest `max:150` < column VARCHAR(300) (silent rejection 151–300) | Request vs DDL | `test_..._36` | Open |
| DEV-LF-004 | P2 | `claim()` `claimant_name` max:150 / `claimant_contact` max:20 exceed columns (100/15) → 1406 truncation risk | Controller vs DDL | `test_..._37` | Open |
| DEV-LF-005 | P2 | Status ENUM `Returned_to_Authority` unreachable (update `in:` + Blade omit it) | Request/Blade vs DDL | `test_..._25` | Open |
| DEV-LF-006 | P2 | Audit-trail gap: store/update/destroy/toggleStatus log nothing; `item_claimed` casing inconsistent w/ `Restored`/`Deleted` | Controller | `test_..._14` | Open |
| DEV-LF-007 | P3 | `update()` applies no FSM transition guard (only `claim()` does) | Controller | `test_..._24` | Open |
| DEV-LF-008 | P3 | `disposal_notes` column never captured by any form/controller path | Controller/Blade | `test_..._74` | Open |
| SEC-FOF-003 | P1 | `LostFoundRequest::authorize()` returns `true` — no defense-in-depth (module-wide D30) | Request | `test_..._92` | Open |

All DEV tests assert **current** behaviour with a tripwire comment; they flip to failing (prompting a doc update) when the defect is fixed.

## Legend
✅ Full = ≥1 method fully exercises the TC. Tolerant status sets (500-vs-422, 403-vs-302) per Rule Card #41/F37. Cross-module (`sys_media`/`sys_users`) paths guarded with try/catch + `markTestSkipped` (#11/HARD RULE #9).
