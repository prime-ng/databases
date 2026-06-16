# Batch Templates — Screen Requirements

## Yeh Screen Kya Karta Hai?

Batch Template wo reusable time table hota hai jo teacher ya admin create karta hai. Isme define hota hai ki kitne minute ka slot hoga, kitna buffer hoga, kitne students ek slot mein aa sakte hain, aur total window kitne time ki hai.

Ek baar template create karne ke baad use multiple classes mein apply kar sakte hain. Jaise "Morning 9-11 AM, 12 Students × 10 min" template ek baar banao aur 10-A, 10-B, 10-C sabme apply karo.

---

## Kis Scenario Mein Use Hota Hai?

1. Teacher apne time slots ka ek template banana chahta hai
2. "Primary classes ke liye 15 min ka slot" - ek template bana ke saari primary classes mein apply karna hai
3. Admin chahta hai ki secondary classes ke liye 10 min ka slot ho aur primary ke liye 15 min
4. Ek class ke students zyada hain to group slot (2-3 students ek saath) banana hai

---

## Screen Fields

| Field Name | Kya Dalna Hai? | Conditions / Rules |
|---|---|---|
| Template Code | Unique short code (e.g., BATCH_2H_12STU) | Required. **Duplicate nahi ho sakta.** |
| Template Name | Template ka naam (e.g., "Morning 9-11 AM, 12 students × 10 min") | Required. Max 100 characters. |
| Owner Teacher | Kaun sa teacher is template ka owner hai | Required. Default: current logged in teacher. |
| Window Start Time | Batch kab se shuru hoga (e.g., 09:00) | Required. **Window End Time se pehle hona chahiye.** |
| Window End Time | Batch kab tak chalega (e.g., 11:00) | Required. **Window Start Time ke baad hona chahiye.** |
| Slot Duration (Min) | Har meeting kitne minute ki hogi (e.g., 10, 15) | Required. |
| Buffer Time (Min) | Do slots ke beech kitna gap hoga | Optional. Default: 0. |
| Max Participants per Slot | Ek slot mein kitne students book kar sakte hain | Optional. Default: 1. 1 = 1-on-1 meeting, 2+ = group meeting. |
| Expected Total Slots | Total kitne slots generate honge | Auto-calculated. Dekhne ke liye hai. |
| Description | Koi extra info | Optional. Text area. |

---

## Business Rules & Conditions

### 1. Time Window Validation
- **Window Start Time** < **Window End Time** (hamesha)
- Example: 09:00 AM se 11:00 AM - thik. 11:00 AM se 09:00 AM - galat

### 2. Unique Template Code
- Ek school (tenant) ke andar duplicate template code nahi ho sakta
- Example: "BATCH_2H_12STU" already hai toh doosra same code nahi bana sakte

### 3. Total Slots Calculation
Auto-calculate hoga:
```
Total Slots = (Window End Time - Window Start Time) / (Slot Duration + Buffer)
```
Example: 09:00 se 11:00 (120 min), slot 10 min, buffer 0 min = 120/10 = 12 slots

### 4. One Teacher Multiple Templates
- Ek teacher ke multiple templates ho sakte hain
- Example: Ek teacher ke paas "Morning 9-11 AM" aur "Afternoon 2-4 PM" dono templates ho sakte hain

### 5. Template Reusability
- Ek template multiple classes mein apply ho sakta hai
- Example: "Morning 9-11 AM" template 10-A, 10-B aur 10-C, teeno mein apply ho sakta hai

### 6. Fallback Support
- Agar template mein Buffer ya Max Participants set nahi hai, toh Event level ke defaults use hote hain

---

## Example Scenarios

### Example 1: Standard Secondary Template
- **Code**: BATCH_SEC_10M
- **Name**: "Secondary 10-min slots 9-11 AM"
- **Window**: 09:00 to 11:00 (2 hours)
- **Slot Duration**: 10 minutes
- **Buffer**: 0 minutes
- **Max Participants**: 1 (1-on-1)
- **Total Slots**: 12 slots

**Matlab**: 9 AM se 11 AM tak 12 students ke saath 10-10 minute ki meetings.

### Example 2: Primary Template with Break
- **Code**: BATCH_PRIM_15M
- **Name**: "Primary 15-min slots 9-12 PM"
- **Window**: 09:00 to 12:00 (3 hours)
- **Slot Duration**: 15 minutes
- **Buffer**: 2 minutes
- **Max Participants**: 1
- **Total Slots**: 10 slots (180 min / 17 min ≈ 10)

**Matlab**: 9 AM se 12 PM tak 10 students ke saath 15 min ki meetings, 2 min buffer.

### Example 3: Group Slot Template
- **Code**: BATCH_GRP_3
- **Name**: "Group slots - 3 students per slot"
- **Window**: 09:00 to 10:00
- **Slot Duration**: 20 minutes
- **Buffer**: 0 minutes
- **Max Participants**: 3 (group)
- **Total Slots**: 3 slots

**Matlab**: 9-10 AM tak 3 time slots, har slot mein 3 students ek saath baat kar sakte hain.

---

## CRUD Operations

### Create (Naya Template Banana)
1. Teacher/Admin form kholta hai
2. Code, name, window time, slot duration, buffer, capacity bharta hai
3. Submit karta hai
4. Template create ho jata hai
5. Ab ise assignments mein use kar sakte hain

### List (Templates Dekhna)
- Teacher ke hisaab se templates ki list dikhti hai
- Dikhta hai: Code, Name, Window Time, Duration, Total Slots
- Actions: View, Edit, Delete, Use in Assignment

### Edit (Template Edit Karna)
- Details change kar sakte hain
- **Note**: Agar template already kisi assignment mein use ho raha hai, toh change karne se future assignments affect honge

### Delete
- Soft delete
- Agar template kisi active assignment mein hai toh delete nahi kar sakte (pehle assignment handle karo)

---

## Kya Dhyan Mein Rakhna Hai?

1. Buffer time zyada rakhoge toh total slots kam honge
2. Agar slot capacity 1 se zyada hai toh wo group slot hai — ek slot mein multiple students baat kar sakte hain
3. Template reusable hai — ek baar banao, multiple classes mein apply karo
4. Template level pe kuch bhi nahi diya toh event level ke defaults use hote hain