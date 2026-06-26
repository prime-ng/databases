# Events — Screen Requirements

## Yeh Screen Kya Karta Hai?

Yeh screen PTM event create aur configure karne ke liye hai. School ka Admin ya Principal is screen se naya PTM event bana sakta hai, existing event edit kar sakta hai aur event ki basic settings set kar sakta hai.

Is screen ke through pura PTM scheduling ka base setup hota hai — jis event ke under classes, teachers, slots aur bookings manage hote hain.

---

## Kis Scenario Mein Use Hota Hai?

1. School ko "Term 1 PTM" ke liye event banana hai
2. School chahta hai "Annual PTM" ya "Mid-Term PTM" ke liye alag event ho
3. Admin kisi existing event ki date ya settings change karna chahta hai
4. School chahta hai booking window ki timing set kare

---

## Screen Fields

| Field Name | Kya Dalna Hai? | Conditions / Rules |
|---|---|---|
| Event Code | Unique short code (e.g., PTM-T1-2526) | Required. Automatically suggested ya manually. **Duplicate nahi ho sakta.** |
| Event Title | PTM event ka naam (e.g., "Term 1 PTM 2025-26") | Required. Max 255 characters. |
| Academic Session | Kis academic session ke liye hai (e.g., 2025-2026) | Required. Dropdown se select karein. |
| Academic Term | Kis term ke liye hai (Term 1, Mid-Term, Annual) | Optional. Dropdown se select karein. |
| Description | Koi extra information jo staff/parents ko dikhe | Optional. Text area. |
| Event Start Date | PTM shuru hone ki date | Required. |
| Event End Date | PTM khatam hone ki date | Required. **End date >= Start date hona chahiye.** |
| Default Meeting Mode | Meeting kaise hogi? (IN_PERSON, ONLINE, HYBRID) | Required. Default: IN_PERSON. Class level pe override kar sakte hain. |
| Booking Window Start | Parents kab se book kar sakte hain | Required. Date + Time. |
| Booking Window End | Parents kab tak book kar sakte hain | Required. Date + Time. **Booking end > Booking start hona chahiye.** |
| Cancellation Lead Time (Hrs) | Meeting se kitne ghante pehle tak cancel kar sakte hain | Required. Default: 24 hours. |
| Allow Reschedule | Kya parent cancel karke doosra slot le sakta hai? | Boolean. Default: Yes (1). |
| Default Slot Duration (Min) | Har meeting kitne minute ki hogi | Required. Default: 10 minutes. |
| Default Buffer Time (Min) | Do slots ke beech kitna gap hoga | Required. Default: 0 minutes. |
| Max Participants per Slot | Ek slot mein kitne log book kar sakte hain | Required. Default: 1 (1-on-1). 1 se zyada = group slot. |
| Notify on Book | Booking confirm hone par parent ko SMS/Email jayega? | Boolean. Default: Yes (1). |
| Notify on Cancel | Cancel hone par parent ko notification jayega? | Boolean. Default: Yes (1). |
| Is Active | Kya event active hai ya nahi? | Boolean. Default: Yes. Agar No kiya toh parents ko event nahi dikhega. |

---

## Business Rules & Conditions

### 1. Date Validations
- **Event End Date** >= **Event Start Date** (hamesha)
- **Booking Window End** > **Booking Window Start** (hamesha)
- Booking window normally event start se pehle ya event start ke din tak rehni chahiye

### 2. Unique Code Constraint
- Ek school ke andar duplicate Event Code nahi ho sakta
- Example: Agar "PTM-T1-2526" already hai, toh doosra same code nahi bana sakte

### 3. Global Settings Fallback
- Event level pe jo defaults set kiye hain (duration, buffer, capacity) wo tab use hote hain jab batch ya assignment level pe override nahi kiya gaya ho

### 4. Booking Status (Dynamic)
Event ki list mein live status dikhega based on current time:
- **Upcoming**: Booking start abhi nahi hui hai
- **Open**: Booking window chal rahi hai (parents book kar sakte hain)
- **Closed**: Booking window khatam ho gayi hai

### 5. Analytical Counts
Event list mein ye calculations dikhengi:
- **Total Classes Added** = Kitni classes is event mein registered hain
- **Total Slots** = Event ke under kitne total slots bane hain
- **Booked Slots** = Kitne slots book ho chuke hain
- **Booking %** = (Booked Slots / Total Slots) × 100

---

## CRUD Operations

### Create (Naya Event Banana)
- Admin event creation form kholta hai
- Saare required fields bharta hai
- Submit karta hai toh event create ho jata hai
- Success message aata hai

### List (Event Ki List Dekhna)
- Saare active events ki list dikhti hai
- Filters available: Academic Session, Status, Date Range
- Har row mein Actions (View, Edit, Status Toggle) available hain
- Booking percentage aur classes count bhi show hote hain

### View (Event Details Dekhna)
- Event ki saari details dikhti hain
- Is event mein join ki gayi classes ki list dikhti hai
- Analytical summary (bookings, slots etc.) dikhta hai

### Edit (Event Edit Karna)
- Form pre-filled hota hai
- Dates wagera change kar sakte hain
- **Note**: Agar booking window start ho gayi hai, toh kuch field edit restricted ho sakti hain

### Delete
- Event soft delete ho jata hai (delete hua bhi show hota hai)
- Event delete karne se uske under ki assignments/slots/bookings bhi cascade hote hain

---

## Example Scenario

**School XYZ** Term 1 PTM create karna chahta hai:

1. Code: PTM-T1-2526
2. Title: "Term 1 Parent-Teacher Meet 2025-26"
3. Session: 2025-2026
4. Term: Term 1
5. Event Dates: 10 May 2026 to 15 May 2026
6. Meeting Mode: IN_PERSON
7. Booking Window: 1 May 2026 (9:00 AM) to 9 May 2026 (11:59 PM)
8. Cancellation: 24 hours pehle tak
9. Slot Duration: 10 minutes
10. Buffer: 2 minutes
11. Max Participants: 1 (1-on-1 meetings)
12. Notifications: On

Event create hua. Ab admin is event mein classes add karega, teachers ko batches assign karega, aur parents book kar payenge.