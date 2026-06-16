# Event Class Sections — Screen Requirements

## Yeh Screen Kya Karta Hai?

Yeh screen batati hai ki ek PTM event mein kaun-kaun si classes participate kar rahi hain, kis date ko, aur kitne time tak. Admin is screen mein PTM event ke andar specific classes add karta hai aur unke liye alag date/time set karta hai.

---

## Kis Scenario Mein Use Hota Hai?

1. PTM event create karne ke baad admin classes add karna chahta hai
2. 10-A ka PTM 10 May ko hai, aur 10-B ka 11 May ko — to admin alag-alag date set karega
3. Kisi class ka room change karna hai ya virtual link update karna hai
4. Koi class PTM mein participate nahi karegi, to admin use remove karega

---

## Screen Fields

| Field Name | Kya Dalna Hai? | Conditions / Rules |
|---|---|---|
| PTM Event | Kis event ke liye class add kar rahe hain | Required. Dropdown se select karein. |
| Class Section | Kaun si class + section (e.g., 10-A, 10-B, 5-A) | Required. Dropdown. **Ek class+section ek event mein sirf ek baar add ho sakta hai.** |
| Scheduled Date | Is class ka PTM kis din hoga | Required. **Event ki start aur end date ke andar hona chahiye.** |
| Day Start Time | Is class ke liye slots kab se start honge (e.g., 09:00) | Required. **Day End Time se pehle hona chahiye.** |
| Day End Time | Is class ke liye slots kab tak chalenge (e.g., 13:00) | Required. **Day Start Time ke baad hona chahiye.** |
| Meeting Mode | Is class ke liye meeting mode kya rahega (IN_PERSON / ONLINE / HYBRID) | Optional. Agar nahi diya toh event ke default mode se aayega. |
| Room | Kaunsa room use hoga (agar IN_PERSON hai toh) | Optional. Dropdown se select karein. |
| Virtual Link | Zoom/Meet/Teams link (agar ONLINE hai toh) | Optional. Text field. |
| Notes | Extra instructions (e.g., "Main hall use karein") | Optional. Text area. |

---

## Business Rules & Conditions

### 1. Unique Class Per Event
- Ek event mein ek class+section sirf EK baar add ho sakta hai
- Example: 10-A ko PTM-T1 mein do baar add nahi kar sakte
- **Condition**: Unique constraint on (ptm_event_id, class_section_id)

### 2. Date Range Validation
- Class ka scheduled date EVENT ke start aur end date ke BEECH mein hona chahiye
- Example: Event 10 May se 15 May tak hai, toh 10-A ki date 10 May se 15 May ke beech hi ho sakti hai — 20 May nahi

### 3. Time Validation
- Day Start Time < Day End Time (hamesha)
- Example: 09:00 AM se 01:00 PM tak - thik hai. 01:00 PM se 09:00 AM - galat

### 4. Meeting Mode Inheritance
- Agar class ke liye meeting mode nahi diya, toh event ka default meeting mode use hoga
- Agar class ke liye room diya hai aur mode IN_PERSON hai, toh virtual link nahi chahiye
- Agar class ke liye virtual link diya hai aur mode ONLINE hai, toh room nahi chahiye

### 5. Time Period Duration
- Day Start aur End Time ke beech itna time hona chahiye ki minimum slots generate ho sakein
- Example: Slot duration 10 min hai aur buffer 2 min hai toh har slot 12 min ka hai. Agar 09:00 se 11:00 tak time hai toh 10 slots generate honge

---

## CRUD Operations

### Create (Class Add Karna)
1. Admin PTM event select karta hai
2. Dropdown se class-section select karta hai
3. Date, start time, end time set karta hai
4. Optional: room, virtual link, notes
5. Submit karta hai
6. Class event mein add ho jati hai

### List (Classes Dekhna)
- Event ke hisaab se saari classes ki list dikhti hai
- Table mein dikhta hai: Class Name, Date, Time Range, Meeting Mode, Room
- Actions: Edit, Delete

### Edit (Class Edit Karna)
- Date / Time / Room / Virtual Link change kar sakte hain
- Agar koi booking already exist karti hai is assignment ke liye toh date/time change restricted ho sakti hai

### Delete (Class Remove Karna)
- Class event se remove ho jati hai
- **Note**: Agar class ke already assignments hain (batches attached hain), toh unhe pehle handle karna padega

---

## Example Scenario

**PTM Event: Term 1 PTM (10 May - 15 May 2026)**

| Class | Date | Start Time | End Time | Mode | Room |
|---|---|---|---|---|---|
| 10-A | 10 May 2026 | 09:00 AM | 01:00 PM | IN_PERSON | Room 101 |
| 10-B | 11 May 2026 | 09:00 AM | 01:00 PM | IN_PERSON | Room 102 |
| 5-A | 12 May 2026 | 02:00 PM | 05:00 PM | ONLINE | Zoom Link |
| 12-A | 13 May 2026 | 10:00 AM | 02:00 PM | HYBRID | Hall A |

Yahan 10-A apne alag date (10 May) ko PTM karega, 10-B 11 May ko. Har class ka apna time range hai.

---

## Important Note

Agar ek class ka PTM do din chalana hai (e.g., 10-A ko 10th aur 11th dono din), toh uske liye do rows add karni padengi same class ke liye — lekin current design mein unique constraint isko rokta hai. Agar aisa chahiye toh unique constraint hatani padegi.