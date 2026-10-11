# Batch Slot Templates (Slot Grid) — Screen Requirements

## Yeh Screen Kya Karta Hai?

Batch Template ka actual time-grid define karta hai. Agar Batch Template ek "container" hai (e.g., 9-11 AM, 10 min slots), toh Batch Slot Templates us container ke andar ke individual time slots hain (e.g., 9:00-9:10, 9:10-9:20, etc.).

Yeh slots normally auto-generate hote hain jab Batch Template create hota hai, lekin teacher chahe toh manually bhi customize kar sakta hai — kisi slot ko break mark kar sakta hai, ya koi extra slot add kar sakta hai.

---

## Kis Scenario Mein Use Hota Hai?

1. Batch template create hua toh automatically iske slot grid bhi generate ho jate hain
2. Teacher chahta hai beech mein "Tea Break" ka slot daale (9:40-9:50)
3. Teacher chahta hai kisi particular slot ko hata de (buffer ke liye)
4. Admin manually koi specific slot ka time change karna chahta hai

---

## Screen Fields

| Field Name | Kya Dalna Hai? | Conditions / Rules |
|---|---|---|
| Batch Template | Kis template ke liye slots define kar rahe hain | Required. FK to Batch Template. |
| Ordinal Number | Slot ka number (1, 2, 3...) | Required. **Ek template mein unique.** |
| Slot Start Time | Slot kab shuru hoga (e.g., 09:00) | Required. **Ek template mein unique start time.** |
| Slot End Time | Slot kab khatam hoga (e.g., 09:10) | Required. **Slot End > Slot Start.** |
| Is Break? | Kya yeh slot break hai? | Default: No (0). Yes (1) karne par yeh slot book nahi ho sakta. |
| Break Label | Break ka naam (e.g., "Tea Break", "Lunch") | Required sirf jab Is Break = Yes ho. |

---

## Business Rules & Conditions

### 1. Auto-Generation Logic
Jab bhi koi Batch Template create hota hai, system automatically calculate karta hai:
```
Window = Window End - Window Start
Har slot ka time = Slot Duration + Buffer
Total Slots = Window / (Slot Duration + Buffer)
```

Example: Window 9-11 AM (120 min), Slot Duration 10 min, Buffer 0
- Slot 1: 09:00-09:10
- Slot 2: 09:10-09:20
- Slot 3: 09:20-09:30
... and so on till slot 12: 10:50-11:00

### 2. Manual Customization
Auto-generate hone ke baad teacher manually bhi change kar sakta hai:
- **Break Add**: Kisi bhi slot ko "Break" mark kar sakta hai
- **Time Adjust**: Kisi slot ka start ya end time change kar sakta hai (lekin overlapping nahi honi chahiye)

### 3. Unique Constraints
- **Ordinal Unique**: Ek template mein do slots ka ordinal number same nahi ho sakta (1, 2, 3...)
- **Start Time Unique**: Ek template mein do slots ka start time same nahi ho sakta

### 4. Break Slots
- Jo slot BREAK mark hai, wo kabhi BOOK nahi ho sakta
- Jab actual slots generate honge (ptm_slots), break slots ko BLOCKED mark kiya jayega
- Break ke liye koi capacity nahi hoti

### 5. Consecutive Timings
- Slot 1 ka end time = Slot 2 ka start time (agar buffer 0 hai)
- Agar buffer 2 min hai, toh Slot 1 end 09:10, Slot 2 start 09:12

### 6. Overlap Prevention
- Do slots overlap nahi kar sakte
- System ensure karega ki Slot N ka end time <= Slot N+1 ka start time

---

## Auto-Generation Example

**Batch Template**: Morning 9-11 AM, 10 min slots, 0 buffer

Automatically ye slots generate honge:

| # | Start | End | Break? | Label |
|---|---|---|---|---|
| 1 | 09:00 | 09:10 | No | — |
| 2 | 09:10 | 09:20 | No | — |
| 3 | 09:20 | 09:30 | No | — |
| 4 | 09:30 | 09:40 | No | — |
| 5 | 09:40 | 09:50 | No | — |
| 6 | 09:50 | 10:00 | No | — |
| 7 | 10:00 | 10:10 | No | — |
| 8 | 10:10 | 10:20 | No | — |
| 9 | 10:20 | 10:30 | No | — |
| 10 | 10:30 | 10:40 | No | — |
| 11 | 10:40 | 10:50 | No | — |
| 12 | 10:50 | 11:00 | No | — |

### Manual Edit — Break Add

Teacher ne slot #5 (09:40-09:50) ko break mark kar diya:

| # | Start | End | Break? | Label |
|---|---|---|---|---|
| 5 | 09:40 | 09:50 | **Yes** | "Tea Break" |

Ab parent ke liye slot 5 book nahi ho payega.

---

## CRUD Operations

### Auto-Generate (Create)
Jab batch template create hota hai, tabhi iske slots bhi auto-generate ho jate hain. User ko alag se kuch nahi karna padta.

### View (Slots Dekhna)
- Batch template ke hisaab se saare slots ki list dikhti hai
- Grid view mein: Ordinal, Start Time, End Time, Break Status
- Break slots alag color ya icon se dikhaye jayein

### Edit (Customize Karna)
- Kisi bhi slot ko Break mark kar sakte hain
- Break ka label de sakte hain
- Ordinal change kar sakte hain (slot order badalne ke liye)

### Reset (Reset to Default)
- Template ke slots ko wapas auto-generated state mein reset kar sakte hain (manually kiye gaye changes hata dega)

---

## Kya Dhyan Mein Rakhna Hai?

1. Break slots generate nahi hote — wo sirf time pass karne ke liye hain
2. Buffer time alag se add hota hai — wo bhi effectively break hi hai
3. Jab assignment publish hoga tabhi ye slots actual ptm_slots mein convert honge
4. Har change ke baad expected_total_slots update hona chahiye