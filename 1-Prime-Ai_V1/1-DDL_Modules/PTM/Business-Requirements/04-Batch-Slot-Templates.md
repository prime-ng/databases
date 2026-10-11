# Batch Slot Templates (Slot Grid) — Business Requirements

## What This Screen Does

Once a Batch Template is created (which defines the overall time window like "9 AM to 11 AM"), this screen manages the individual time slots within that window. Each slot represents a specific start and end time — for example, 9:00 to 9:10, 9:10 to 9:20, and so on.

This screen is where teachers can see the automatically generated slot grid, mark certain slots as breaks (like tea break or lunch), and customize the order or timing if needed. It is essentially the detailed time grid of a batch template.

---

## When This Screen Is Used

- Immediately after a batch template is created, the system auto-generates the slot grid
- A teacher wants to mark a "Tea Break" in the middle of their schedule (for example, 9:40 to 9:50)
- A teacher wants to see exactly how many slots they have and at what times
- Admin wants to manually customize a particular slot's timing for a special situation

---

## Business Rules and Conditions

**Automatic Slot Generation**
When a batch template is created, the system automatically divides the time window into equal slots. Each slot gets a sequential number (ordinal), a start time, and an end time. The calculation is simple — divide the total window duration by the sum of slot duration and buffer time.

**Sequential and Non-Overlapping**
Slots follow each other in sequence. The end time of one slot equals the start time of the next slot (if buffer is zero). If buffer is set, there is a small gap between slots. No two slots can overlap or have the same start time within the same template.

**Break Slots**
Any slot can be marked as a break. Break slots cannot be booked by parents — they are simply time passers in the schedule. For example, a teacher might mark 9:40 to 9:50 as "Tea Break." Break slots need a label explaining what the break is for.

**Manual Customization**
After auto-generation, teachers can manually customize the grid. They can mark slots as breaks, change the order of slots, or adjust start/end times. However, overlapping timings must be prevented even after manual changes.

**Reset Capability**
If too many manual changes have been made, the slot grid can be reset to its original auto-generated state. This removes all manual customizations and recreates the slots from scratch based on the template's window and duration settings.

---

## Workflow Steps

**Viewing the Slot Grid**
After creating a batch template, the system shows a grid of all generated slots with their ordinal numbers, start and end times, and break status. Break slots are visually distinct from bookable slots.

**Marking a Slot as Break**
Teacher clicks on a slot, marks it as a break, and optionally provides a label like "Lunch Break" or "Staff Meeting." The slot becomes non-bookable.

**Adjusting Slot Timing**
Teacher can manually change a slot's start or end time within the window. The system ensures no overlapping occurs with adjacent slots.

**Resetting to Default**
If the teacher wants to start over, they can reset the grid. All manual changes are discarded, and slots are regenerated based on the original template settings.

---

## Example Scenario

A teacher created a batch template with a 9 AM to 11 AM window, 10-minute slots, and no buffer. The system auto-generates 12 slots from 9:00-9:10 through 10:50-11:00.

The teacher decides to take a tea break at 9:40 AM. They mark slot number 5 (9:40-9:50) as a break with label "Tea Break." Now this slot cannot be booked by any parent. The remaining 11 slots are available for meetings.

Later, the teacher feels there are too many slots and they only want to meet 8 parents. They mark 3 more slots as blocked. The grid now shows 8 bookable slots, 1 break slot, and 3 manually blocked slots.

When this batch template is assigned to a class and published, only the 8 bookable slots will appear for parents to book. The break and blocked slots will not be visible in the parent portal.
