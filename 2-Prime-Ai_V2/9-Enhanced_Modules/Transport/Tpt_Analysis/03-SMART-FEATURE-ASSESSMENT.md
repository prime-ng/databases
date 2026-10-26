# 03 — Is SmartTransport actually "smart"? (2026-10-23)

## Short answer
**Half.** It has strong *advisory* intelligence: it diagnoses problems and computes what-ifs. It has weak *generative* intelligence: it cannot produce a good plan and take it safely to production.
SmartTimetable is a star feature because it **generates** a full solution in the background, lets a human **review and lock** parts of it, **publishes** it, and keeps **snapshots** to roll back. SmartTransport has the first step only partly built and the rest missing.

## Scorecard against the SmartTimetable bar

| Capability | SmartTimetable has | SmartTransport today | Gap |
|---|---|---|---|
| Real solver | Python engine porting FET (constraint solver, repair/tail-repair) | PHP k-means + radial sort, straight-line km | 🔴 large |
| Runs in background | Queued generation + live status polling (cache snapshot, NullSessionHandler on poll) | Inline in the HTTP request, `set_time_limit(180)` | 🔴 |
| Honours constraints | All 10 constraint types reach the engine, hard/soft | Capacity only. No ride-time cap, arrival window, walk distance, vehicle-shift overlap, or "keep this route" lock | 🔴 |
| Locks / partial regenerate | Lock cells, regenerate the rest | None | 🔴 |
| Review → publish | Generate → review → publish | Generate → *stuck in proposal tables* (P0-02) | 🔴 |
| Snapshots / rollback | v5 snapshot plan | `*_history` tables designed, unwritten | 🔴 |
| Manual editing of a proposal | Drag-drop Manual Placement grid | Read-only proposal view | 🟠 |
| Suggestions | 30 rules on the published TT | **68 rules + 26 loss-recovery strategies** | 🟢 ahead |
| Cost / P&L reasoning | Optimisation report (salary-free) | Route and bus P&L, confidence flags, zero-harm guard | 🟢 ahead |
| Explains itself | Rule text | Card text + roster drill-down + map | 🟢 |
| Proves value | Placed / unplaced counts | No "money saved after you applied this" ledger | 🟠 |

## What is genuinely good and should be kept
1. **LossRecoveryAdvisor** is the module's crown jewel. Merge, split, right-size, central hub stop, shift reuse, corridor rebalance and walking-zone policy are exactly the moves a transport manager makes by hand. The zero-harm guard (a proposal must not push another route into loss) is a sophisticated touch.
2. **SuggestionEngine** coverage is broad:
   - **Compliance:** docs, licence, PUC, police verification, helper for pre-primary.
   - **Money:** deficit, fare anomaly, fine waivers, reconciliation, cash overhead.
   - **Fraud:** off-hours mileage pilferage, fuel rate anomaly.
   - **Safety:** incident hotspots, repeated emergency stops.
   - Each rule fails in isolation, so one bad rule does not kill the page.
3. **The proposal data model** (master + proposed copies + history + typed proposal kinds such as `Route_Merge`, `Route_Split` and `Stopage_Merge`) is the right shape for a SmartTimetable-style workflow. The schema is ready; the workflow is not.

## Why it is not a star yet
- **Untrusted numbers:** every km, minute and fare figure is a straight-line estimate, and missing coordinates become Bangalore (P1-03). A school that checks one route on Google Maps will find a 20–40% error and stop trusting every card.
- **No closed loop:** a suggestion card cannot be accepted, assigned, dismissed or snoozed, and the outcome is not measured. Suggestions are recomputed and forgotten every 10 minutes.
- **Generation can't be used:** you can generate a proposal but not approve it, so there is no "wow" moment of watching the school's routes rebuilt and going live.
- **No background engine:** heavy maths in the request limits it to small fleets. The code comment itself worries about "200-300+ routes".
