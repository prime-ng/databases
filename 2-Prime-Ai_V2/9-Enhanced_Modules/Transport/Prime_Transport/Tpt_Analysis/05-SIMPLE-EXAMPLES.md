# 05 — Every issue and suggestion, explained with simple examples (2026-10-23)

Every point in 02, 03 and 04 is explained here as a small story inside **our own app**.

**The example school (made up, used in every example):**
- **Sunrise Public School, Surat** (one tenant in our app).
- **School location:** Adajan, Surat.
- **2 shifts:** Morning (classes 1–12, reaches school 7:30) and Afternoon (pre-primary, reaches 11:30).
- **12 buses:** 8 big buses (40 seats), 4 mini-vans (20 seats). 2 of the big buses are rented.
- **600 students use transport**, through **90 pickup stops**.
- **Staff:** the transport incharge is **Mr. Mehta**, the principal approves big changes, and parents use the parent app.

All rupee and km numbers below are example numbers to show the idea. They are not from a real database.

---

# PART A — Problems in the current code

## P0-01 — One request can delete the whole transport setup

**Where:** `SmartTransport → PickupPointController::autoGenerateAllRoutes`
URL: `POST /smarttransport/pickup-points/auto-generate-routes`

**What happens today:**
Mr. Mehta has the `pickup-point.sync` permission. Suppose this URL gets called: a teammate wires it to a button later, someone replays an old browser request, or a test script hits it. In one go the app:

1. Removes the bus route from **all 600 students** (their `pickup_route_id` and `drop_route_id` become empty).
2. Deletes **every trip ever run**: all of last year's daily trips and stop timings.
3. Deletes **every trip incident**. Example: "Bus GJ-05-AB-1234 had a minor accident on 12 Aug, child hurt" is gone forever.
4. Deletes every route, every stop-to-route link and every driver/bus assignment.
5. Then creates new routes, but **never puts the 600 students back on any route**.

**Next morning:**
- The trip app shows no students on any bus.
- The fee module can't tell which route a student is on.
- The Transport module (not just Smart Transport) is also empty, because **both modules use the same tables**.

**Why it is so serious:** incident records are safety records. If a parent complains or the police ask about the August accident, we have nothing.

**Fix:** delete this endpoint. New routes should only come through the **proposal** path, which is safe because it writes to separate `tpt_proposed_*` tables and touches nothing live.

---

## P0-02 — Route proposals can be created but never used

**What happens today:**
1. Mr. Mehta opens **Smart Transport → Route Auto Generation**, picks "Morning shift, Both", and clicks Generate.
2. The app shows a nice preview: "9 routes, 600 students, 9 buses". He clicks Apply.
3. The plan is saved as **Proposal #14**.
4. Now he wants to say "Principal, please approve this" and then "make it live from 1st November".
   - **There is no button for that.** No review, no approve, no reject, no publish, no undo.
5. Proposal #14 just sits in the database. The real routes stay the same.

**The same thing happens in the Smart Advisor.** Mr. Mehta sees the card "Merge Route 7 into Route 9, save ₹18,000/month" and clicks **Save as proposal**. It is saved, then nothing happens.

**The database was designed for the full flow.** The DDL already has these statuses:
`Auto_Generated → Proposed → In-Review → Approved / Rejected → Restored`
It also has "history" tables to keep the old routes before a change. Nothing writes to them yet.

**Compare with SmartTimetable:** you generate a timetable, review it, publish it, and can roll back. Transport stops after step 1.

---

## P1-01 — Smart Advisor does all the maths while the page loads

**What happens today:**
1. Mr. Mehta clicks **Smart Advisor** at 9:00.
2. The app runs all 68 rules, the cost of every route and the cost of every bus **right then**, while he waits.
3. With 12 buses it takes a few seconds. For a big school group with **250 routes** it can take minutes. The code itself allows up to 180 seconds. Usually the web server gives up earlier, and he sees a **504 Gateway Timeout** page.

**Stale results:**
1. The results are kept for 10 minutes.
2. At 9:02 he fixes the problem, e.g. uploads the new insurance for bus 4.
3. Until 9:10 the card still says "Bus 4 insurance expired".
4. He thinks the upload failed and uploads again.

**Two pages disagree:** the **route-map** page keeps the same results for only 45 seconds, so the two pages can show different numbers at the same moment.

**Fix (the SmartTimetable way):**
- A background job does the maths at night, or when Mr. Mehta clicks "Refresh".
- He sees a progress bar ("Analysing routes… 60%").
- The page then opens instantly from the saved result.
- Saving a vehicle or route marks the result "out of date, refresh".

---

## P1-02 — The route planner guesses distances and orders stops badly

There are five small problems in `RouteProposalPlanner`.

### (a) Straight-line distance × 1.3
**Example:** the stop at Pal Gam is 4 km from school in a straight line. The app calls it 4 × 1.3 = **5.2 km**. But the Tapi river is in between, and the real road goes over the bridge: **9 km**.

Everything built on that number is wrong:
- **Fare:** if the fare is ₹200 per km (example rate), the app computes a fare for 5.2 km when the real trip is 9 km.
- **Time:** the app says the bus takes 5.2 ÷ 25 km/h = **12 minutes**. In 7 AM traffic it really takes 25 minutes.
- **Fuel cost:** too low, so the route looks profitable when it is losing money.

### (b) Fixed 25 km/h for every road, every time
- The ring road at 6:30 AM really runs at 40 km/h. The old city at 1:30 PM runs at 12 km/h.
- The app uses 25 for both, so the stop times it prints for parents are wrong.

### (c) Stops are sorted by "distance from school", not as a route
**Example:** one route has 3 stops, all about 6 km from school.
- **Stop A** (west end of Ring Road, 6.0 km)
- **Stop C** (east end, 5.9 km)
- **Stop B** (in the middle, 5.8 km)

The app sorts pickup stops by distance, farthest first, so the order is **A → C → B**. The bus goes to the west end, drives all the way to the east end, then comes **back** to the middle. A driver would do **A → B → C**.

There is already a better function in the file (`orderStopsByProximity`), but **nothing calls it**.

### (d) The loop can drop stops in big schools
1. The planner tries at most 12 rounds.
2. Each time it finds it needs one more bus, it starts again, and that **uses up a round**.
3. A school with mixed bus sizes may need many restarts.
4. If it runs out of rounds in the middle of a restart, some stops are never put on any route.
5. When Mr. Mehta clicks Apply, he gets "Only 540 of 600 student allocations could be placed", with no explanation.

### (e) Missing real-life rules
- **No maximum ride time:** a class-1 child could get a **75-minute** ride because her stop was put first on a long route.
- **No arrival deadline:** the plan doesn't check that the bus reaches school before 7:30.
- **No shift clash check:** bus 3 can be given a Morning-shift route that ends at 7:30 **and** an Afternoon-shift route that starts at 7:15, i.e. two places at once.
- **No empty run counted:** the pickup cost starts at the first stop and ignores the 8 km the bus drives empty from the parking yard. But the drop cost **does** include the drive back to school. So pickup routes look cheaper than drop routes for no real reason.

---

## P1-03 — A stop without coordinates silently moves to Bangalore

**What happens today:**
1. Mr. Mehta imports 90 stops from Excel. For 3 stops the latitude/longitude cells are empty.
2. The importer does not complain. It quietly fills in **12.9716, 77.5946**, which is the centre of **Bangalore**.

Then:
- The planner thinks those 3 stops are **~1,200 km** from a Surat school.
- Any route that contains them shows a distance of 2,400+ km, a fuel cost of lakhs, and a huge loss.
- The Smart Advisor then says "Route 5 is losing ₹4,00,000/month, **withdraw the route**". That is a wrong and scary suggestion.

The same Bangalore default is used when the app saves a stop without coordinates, and as the "empty line" for a route map.

**Fix:**
- Leave the coordinates empty.
- Show a red badge "Location missing, set on map".
- Let the planner skip such stops with a warning. The planner already does this for empty values.

---

## P1-04 — The daily "expiry check" runs, but against the wrong database and tells nobody

**What happens today:**
1. Every night at midnight, the command `transport:check-expiries` runs, and `smarttransport:check-expiries` runs as well, so there are two copies.
2. It should find "Bus 4 insurance expires in 10 days" and "Driver Ramesh's licence expired yesterday".
3. **It never switches to Sunrise School's database.** It looks in the central database, where there are no buses.
4. Even when it finds something, it only writes a line in the log file. Nobody reads that log.

**Fix:**
- Keep one command.
- Run it for every school, one by one.
- Send a notification to Mr. Mehta and the principal: "3 documents expiring this week".

---

## P1-05 — Maps use a free demo server meant for testing only

**What happens today:**
- The stop page and the cost-analysis map ask `router.project-osrm.org` for road routes, from each user's browser.
- That server is a **free demo**. Its rules say it is not for heavy or commercial use, and it can block us any day without notice.

**Example:** in the week schools reopen, 40 schools' staff open maps together. The demo server starts refusing, and every map shows straight lines or nothing.

**Fix:** run our **own** OSRM on our VPS with the India map (free software, needs a few GB of RAM), or pay for a map API. Call it from our server and save the answers.

---

## P1-06 — Two copies of the same module, already different

**What happens today:**
- SmartTransport was made on 17 Oct by copying all of Transport, 343 files.
- **155 of those files have already changed differently** in the two modules.

**Example:**
1. A bug in the fee collection screen ("receipt total shows wrong amount") is fixed in **Transport** on Monday.
2. A school that uses **Smart Transport → Fee Collection** still has the bug, because it is a different file.
3. Next week someone fixes another bug in Smart Transport only. Now the two diverge further.

The sidebar also shows **"Vehicle Mgmt"** and **"Smart Vehicle Mgmt"** side by side. Mr. Mehta doesn't know which one to use. Both show the same buses, because they read the same tables.

**Fix (suggested):** make Smart Transport an **add-on** on top of Transport.
- **Transport keeps:** vehicles, routes, trips and fees, once.
- **Smart Transport keeps only:** Smart Advisor, Route Auto Generation, proposals and the new smart features.
- **About 300 duplicate files go away.**

---

## P1-07 — Smart Transport can't be sold separately

**What happens today:** Smart Transport's pages check "does this school have the **Transport** module?" They don't check "Smart Transport".
- Every school that bought basic Transport also gets Smart Transport for free.
- Every such school sees both menus.

**Fix:** give it its own module key, so we can sell it as a **premium add-on** (e.g. "Transport ₹X, Smart Transport +₹Y").

---

## P2-01 — Technical error text is shown to users

**Example:** Mr. Mehta clicks Apply on a proposal. Something fails in the database, and he sees:

> Failed to save proposal: SQLSTATE[23000]: Integrity constraint violation: 1452 Cannot add or update a child row: a foreign key constraint fails (`tenant_sunrise`.`tpt_proposed_route`…

- It means nothing to him.
- It leaks our database names and structure.

This pattern appears ~150 times in each module.

**Fix:** show "Could not save the proposal. Please try again or contact support (ref #A12F)" and write the details to the log.

---

## P2-02 — Deleting a user deletes their proposals

**Example:**
1. Mr. Mehta leaves the school. The admin deletes his user account.
2. Because of `ON DELETE CASCADE`, **every proposal he created or reviewed is deleted too**, including the approved one that explains why Route 7 was merged last term.

**Fix:** when the user is deleted, keep the proposal and just leave "created by" empty (`SET NULL`), or block deleting users who own records.

---

## P2-03 — Map points are built by gluing text into SQL

**Example:** the code writes `ST_GeomFromText('POINT(72.79 21.19)')` by putting the numbers straight into the SQL text.
- Today the numbers are mostly checked to be numbers, so it works.
- But if one path ever lets text like `72.79 21.19)'); DROP TABLE…` through, it becomes an SQL injection.

**Fix:** pass the numbers as **bindings** (`?`). Then the database treats them only as values, never as SQL.

---

## P2-04 — Advisor limits are fixed in code

**Examples of fixed numbers:**
- "warn 30 days before expiry"
- "stops closer than 1,000 m can merge"
- "repair bill above ₹1,00,000 in 6 months → consider replacing the bus"

**Why it hurts:**
- A small school with old vans wants the replace warning at ₹40,000.
- A school in a dense city wants stops merged only if closer than 400 m.
- Today they can't change it. Only a developer can.

**Fix:** a "Smart Advisor Settings" tab per school.

---

## P2-05 — No automated tests

**Example:** someone changes the fare formula to fix rounding and accidentally makes every route ₹100 cheaper. Nothing catches it until parents' fee receipts are wrong.

Money calculations (fare, route profit/loss, loss recovery) especially need tests.

**Fix:** start with small tests for fare, route cost and the planner, using a fixed set of stops.

---

## P2-06 — `$request->all()` used for saving

**Example:** a form sends `name`, `capacity` and `vehicle_no`. If someone adds `is_active=1` or `created_by=1` to the request with browser tools, and the model allows it, it gets saved.

**Fix:** save only the fields that passed validation (`$request->validated()`).

---

## P2-07 — Smart Transport's mobile API files are dead

**What happens today:**
- The mobile app talks to **Transport's** API.
- Smart Transport has its own copy of the API files, and **they are never loaded**.

**The risk:** a developer fixes a mobile bug in the Smart Transport copy, and the app never sees the fix.

**Fix:** delete the dead copy.

---

## P2-08 — The DDL file doesn't match the real database

**What is wrong in the file:**
- It is named v2.4 but says **v2.3** inside.
- It points to a table called `usr_users`. In tenant databases the table is `sys_users`.
- Two tables that exist in the migrations are missing from the DDL.

**Example:** a new developer builds a test database from the DDL. It fails on the `usr_users` foreign keys, and they waste a day.

**Fix:** regenerate the DDL from the current migrations.

---

## P3 — Small clean-ups

- **Spelling on screen:** "Stundet Transport Allocation" → "Student…", "Bord Unbord" → "Board / Unboard", "Stopage" → "Stoppage".
- **Debug leftovers:** 18 `console.log` lines in views per module, and one commented `dd($vehicle)`.
- **Old unused file:** `oldcode.html`.

---

# PART B — Suggestions, explained with examples

## ★1 — A real route engine that runs in the background

**Today:** Mr. Mehta clicks Generate and waits. The plan uses straight lines and the zig-zag stop order.

**After:**
1. He clicks **Generate routes for Morning shift** and picks a goal: *fewest buses*.
2. A progress window opens, like the timetable one: "Building road distances… 30% · Best so far: 10 buses, 1,840 km/month · 0 students left".
3. He can close it and come back. The work continues in the background.

**Result, with rules the school sets:**
- No child rides more than **50 minutes**.
- All buses reach school by **7:25**.
- Bus 3 is not used in both shifts at the same time.
- **"Keep Route 2 exactly as it is"** (locked, because parents there are happy).

The engine (Python + Google OR-Tools, the same setup we use for the timetable) finds the best plan within these rules, using **real road distances**.

**Example outcome:** "**10 buses instead of 12**. Longest ride 48 min. Saving **₹62,000/month**."

---

## ★2 — Review, approve, publish, undo

**Today:** proposals get stuck (P0-02).

**After:**
1. Mr. Mehta opens Proposal #14 and sees **two maps side by side**: Current routes and Proposed routes.
2. A summary shows:
   - 47 students change bus; 3 stops move.
   - Total km: 2,300 → 1,840 per month.
   - Cost: ₹4.1 L → ₹3.5 L per month.
   - Longest ride: 62 → 48 min.
   - Routes in loss: 4 → 1.
3. He ticks the routes he agrees with and rejects Route 6 ("that road floods in monsoon").
4. He sends it **for approval**. The principal clicks **Approve, live from 1 Nov**.
5. On 1 Nov the app:
   - saves a copy of the old routes (history)
   - switches to the new routes
   - updates the 47 students' bus
   - sends parents a message: "From 1 Nov, Aarav's bus is Route 4, pickup at Pal Gam stop at 6:52 AM"
6. If something goes wrong on day 1, he clicks **Restore previous routes**, and everything returns to the October setup.

---

## ★3 — Savings ledger: "Smart Transport saved you ₹X"

**Today:** the Advisor shows a card. If Mr. Mehta acts on it, nobody knows whether it worked. The card is recalculated and forgotten every 10 minutes.

**After:** every card is saved with a status.

**Example card:**
> Merge Route 7 into Route 9 — expected saving **₹18,000/month**
> Status: Accepted by Mr. Mehta on 3 Nov · Owner: Mr. Mehta · Due: 15 Nov

**30 days later**, the app checks the real fuel, km and salary bills:
> Route 7+9 merge — expected ₹18,000, **actual ₹16,400 saved** ✔

**Dashboard tile:** "**Smart Transport saved ₹2.3 lakh this term**".
- This is the number the principal shows the management.
- It is also the number that makes the school renew.

Other buttons: **Dismiss** ("not possible, narrow lane") and **Snooze 30 days**, so the same card doesn't nag every day.

---

## ★4 — What-if simulator

**Situation:** the management asks "What if the afternoon shift starts 20 minutes later?"

**Today:** nobody can answer without a week of manual work.

**After:**
1. Mr. Mehta opens **What-if** and clones the current plan into a sandbox.
2. He changes one thing: *Afternoon shift reach time 11:30 → 11:50*.
3. He clicks Run.

**Answer:** "The 4 buses that finish morning drop at 11:20 can now also do the afternoon pickup. **You can return the 2 rented buses. Saving ₹70,000/month.**"

**Other what-ifs he can try:**
- Remove 2 buses. What happens to ride times?
- Replace big Bus 8 with 2 mini-vans for the narrow-lane area.
- Raise the fare by ₹5/km. Which routes become profitable?
- Stop serving students who live under 1 km (walking zone). How much saved?
- A new society with 60 admissions in Vesu. Do we need a new bus?

Each scenario is just a proposal that is never published, so it reuses ★1 and ★2.

> Real-world proof: US school districts save buses this way ("bell-time tiering"). One study showed moving one school's timing could free 4 buses.

---

## ★5 — Learned bus timings + live parent alerts

**Today:** stop times are "distance ÷ 25 km/h", and parents get no live ETA.

**After, step 1 — learn real speeds:**
1. The trip app already records when the bus actually reached each stop (`tpt_trip_stop_detail`).
2. After a month, the app knows that "Adajan → Pal Gam at 6:45 AM takes 9 minutes; at 1:30 PM it takes 17."
3. Printed stop times become accurate.

**After, step 2 — live alerts in the parent app:**
- "Bus is 2 stops away, arriving in ~6 min."
- "Bus running 12 minutes late today (traffic at Udhna Darwaja)."

**After, step 3 — alerts for Mr. Mehta:**
- "Route 3 has left its usual path" (geofence).
- "Route 5 is 15 min behind normal."

**After, step 4 — AIS-140 devices:**
- Indian rules require school buses to carry an approved GPS device with a **panic button**.
- If the conductor presses it, the app creates an incident immediately and calls or messages Mr. Mehta and the principal.

---

## ★6 — Best stop locations (needs student home locations)

**Today:** students are attached only to stops. The app doesn't know where a child actually lives, so it can't say "this stop is in the wrong place".

**After:**
1. Parents drop a pin for their home in the parent app, or the address is converted to a map point.
2. The app suggests stops so that:
   - every child walks **at most 400 m**
   - small children (pre-primary) never need to cross a main road
   - the last drop at night is at a well-lit spot

**Example:** "Replace stops 41, 42 and 43 (each with 2–3 kids) with one stop at Shanti Society gate. Walk ≤ 300 m for all 8 kids. Saves 6 minutes and 2 km per trip."

---

## ★7 — Transport quote at admission time

**Today:** a parent asks the front office "Is there a bus from Vesu, and how much?" The clerk calls Mr. Mehta, who checks Excel.

**After:** in the **Admission** enquiry form, the clerk types the address. The app answers immediately:

> Nearest stop: Vesu Canal Road (350 m walk) · Route 6 · **4 seats free** · Fare **₹1,450/month** · Pickup ~6:58 AM

**Other outcome:** "No stop within 1 km. A new stop is needed (adds ~4 min to Route 6)."

**Bonus:** all enquiries are saved, so in March the app can say "Next year, 70 new students expected in Vesu. Route 6 will be full, plan one more bus."

---

## ★8 — Daily emergency re-plan (like Substitute Management for teachers)

**Situation 1:** at 6:10 AM, Bus 4 won't start.

**Today:** Mr. Mehta makes 10 phone calls.

**After:** the app suggests, ranked:
1. Spare Bus 11 (free, same size). Driver Suresh is on standby.
2. Bus 9 has 14 empty seats and passes within 1 km. Merge Route 4's first 3 stops into it (+8 min).
3. Split the stops between Route 3 and Route 5.

He picks one. Parents of Route 4 get an automatic message with the new bus number.

**Situation 2:** 12 students on Route 7 are absent today (from attendance), and 2 stops have nobody. The bus skips those stops, and the route is 10 minutes shorter today.

---

## ★9 — Safety & compliance score

**One page for the principal and inspectors:**

| Bus | Driver | Overspeed (30 d) | Harsh braking | Incidents | Documents | Female attendant on last-girl-drop routes | Score |
|---|---|---|---|---|---|---|---|
| GJ-05-AB-1234 | Ramesh | 4 | 2 | 0 | ✔ | ✔ | 92 |
| GJ-05-CD-5678 | Vijay | 21 | 9 | 1 | Insurance expires in 6 d | ✘ (girl dropped last at 8:10 PM) | 58 |

**Example alert:** "Route 5: the last student dropped is a girl and no female attendant is assigned. Assign one or change the drop order."

Export as PDF for an RTO or board inspection.

*(Check the exact state or board circular before making the female-attendant rule mandatory.)*

---

## ★10 — Ask questions in plain words (optional, later)

**Mr. Mehta types:** "Why is Route 12 losing money and what should I do?"

**App answers**, using the Advisor's own numbers:
> Route 12 earns ₹38,000 and costs ₹52,000 a month. Main reasons: only 22 of 40 seats used, and 9 km of empty run from the parking yard.
> Best options: (1) Merge with Route 10 (save ₹14,000), (2) Replace with a 20-seat van (save ₹9,000).
> [Create proposal]

---

# PART C — The 5 decisions, in simple words

1. **One module or two copies?**
   - *Example:* if we keep two copies, every fix (like the fee receipt bug) must be done twice.
   - *Suggested:* Transport is the base, and Smart Transport is an add-on on top.
2. **Our own map server or a paid one?**
   - *Own OSRM on the VPS:* free, but needs a few GB of RAM and setup.
   - *Google/Mapbox:* easy, but each distance lookup costs money. A 90-stop school needs ~8,100 pairs for one full table.
3. **Python or PHP for the engine?**
   - The timetable already runs a Python engine. Reusing that setup is faster and gives us Google OR-Tools.
4. **Is Smart Transport a paid add-on?**
   - If yes, it needs its own module key (P1-07).
5. **Can we store where students live?**
   - Needed for ★6 and ★7.
   - Needs parent consent and careful privacy handling (only staff with permission can see home pins).
