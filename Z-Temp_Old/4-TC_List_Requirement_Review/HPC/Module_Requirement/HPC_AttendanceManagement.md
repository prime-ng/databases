# HPC Attendance Management - Full Guide

## What Is This Feature?

This feature lets the school set up how many days the school was open each month. Once that is done, the computer automatically figures out each student's attendance percentage. No one has to do any math by hand. The attendance numbers show up on every student's progress card on Page 1.

Think of it like a teacher taking attendance in a notebook every morning. At the end of each month, the teacher counts how many days the student was present. Then the teacher divides that number by how many days the school was open that month. That gives the attendance percentage. This computer feature does all of that counting and dividing automatically.

## Who Uses This Feature?

Only school administrators use this. A school administrator is someone who works in the school office and handles records. Teachers do not use this part. Teachers only see the results.

## The School Year Is Different

The school year in India runs from April to March. It does NOT start in January like the normal calendar year. So Month 1 is April. Month 2 is May. Month 3 is June. Month 4 is July. Month 5 is August. Month 6 is September. Month 7 is October. Month 8 is November. Month 9 is December. Month 10 is January. Month 11 is February. Month 12 is March.

This is very important. All 12 months follow this Indian school year order. If someone tries to put January first, that would be wrong.

---

## PART 1: Working Days Configuration

### What Is This Screen?

The admin sees a simple screen. There are 12 empty boxes on the screen. Each box has a month name written above it. The boxes are in order: April first, then May, then June, and so on until March at the end.

### What the Admin Does

The admin types a number into each box. That number is how many days the school was open that month. Not all months have the same number of days. Some months have holidays. Some months have exams. Some months have summer vacation.

Here is an example of what the admin might type:

April: 22 working days
The school was open for 22 days in April. This does not count weekends. This does not count holidays. Only the days when students actually came to school.

May: 20 working days
May had 20 days when school was open.

June: 0 working days
June is summer vacation. The school is completely closed. The admin types 0.

July: 23 working days
July had 23 days when school was open.

August: 22 working days
August had 22 working days.

September: 21 working days
September had 21 working days.

October: 18 working days
October had holidays like Diwali. So fewer working days.

November: 22 working days
November had 22 working days.

December: 20 working days
December had winter break. So 20 working days.

January: 22 working days
January had 22 working days.

February: 19 working days
February is a short month. So 19 working days.

March: 23 working days
March had 23 working days before the school year ends.

### What Happens When the Admin Clicks Save

After the admin types all 12 numbers, the admin clicks a button that says Save. The computer stores these numbers in its memory. From now on, every time the computer needs to calculate attendance, it uses these numbers.

### What Happens If the Admin Changes a Number Later

Sometimes the school calendar changes. Maybe there was an unexpected holiday. Maybe the school closed for a day because of heavy rain. The admin can go back to the screen and change any month's number.

Here is what happens when the admin changes a number:

Suppose the admin originally typed 22 for April. Then later the admin remembers there was a school holiday on April 15 that was not counted. The admin changes April from 22 to 21.

The computer automatically recalculates every single student's attendance percentage for April. Every student's percentage goes up or down depending on their attendance record. The admin does NOT have to do anything else. The computer handles all the math.

This is very helpful because it saves hours of work. Imagine a school with 500 students. Recalculating attendance for 500 students by hand would take a whole day. The computer does it in a few seconds.

### Why Is This Important?

Schools sometimes change their calendars. Maybe the government declares a sudden holiday. Maybe the school closes because of a festival. Maybe there is a staff training day. All of these change the number of working days.

If the admin could not change the numbers, the attendance percentages would be wrong. Students would show incorrect attendance. Parents would complain. The school records would be inaccurate.

This feature lets the admin fix the numbers at any time. The attendance percentages stay correct all year long.

---

## PART 2: Attendance Summary View

### What Is This Screen?

The admin can also see a summary screen. This screen shows all students in the school and their attendance numbers. It is like a big list or a big table.

### What the Admin Sees on This Screen

The screen shows a list of every student in the school. Next to each student's name, the admin sees:

The student's name. For example: Priya Sharma.

Next to the name, the admin sees 12 numbers. One number for each month from April to March. Each number is how many days that student was present in that month.

For example, next to Priya Sharma the admin might see:
April: 20 days present
May: 18 days present
June: 0 days present (school was closed)
July: 22 days present
And so on for all 12 months.

At the end of the row, the admin sees a total. The total is the sum of all present days across the whole year. For example, if Priya was present 230 days out of 252 total working days, the total shows 230.

Next to the total, the admin sees the attendance percentage. This is calculated by the computer. The formula is: Total Present Days divided by Total Working Days, multiplied by 100.

For example: 230 divided by 252 equals 0.9127. Multiply by 100 equals 91.27 percent. The computer rounds this to 91 percent.

The admin might also see absence reasons if someone typed them in. For example, if Priya was absent in June because of a family trip, the reason might say "Family trip" next to that month.

### Who Can See This Screen?

Only the admin can see this summary screen. Teachers cannot see every student in the school. Teachers can only see their own students. The admin sees everything because the admin runs the whole school.

### Why Does This Screen Exist?

The admin needs to generate reports for the school management. The school management might want to know:

How many students have attendance above 90 percent?
Which classes have the best attendance?
Which students are absent too often?

The admin can answer all these questions using the summary screen without bothering any teacher.

---

## PART 3: How Attendance Looks on the Teacher's Card

### What Is the Teacher Card?

Every student has a progress card. The teacher fills in this card with grades, comments, and attendance. The first page of every card always shows attendance. This is the same for all grade levels: Foundation, Preparatory, Middle, and Secondary.

### What the Attendance Table Looks Like

When the teacher opens a student's card, the computer shows a table. The table has 12 columns, one for each month. The months go from April to March in order.

Here is a complete example of what the teacher sees on the screen. This example uses a student named Aarav Patel from Class 5-A.

| MONTHS         | APR | MAY | JUN | JUL | AUG | SEP | OCT | NOV | DEC | JAN | FEB | MAR |
|----------------|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| Working Days   | 22  | 20  | 0   | 23  | 22  | 21  | 18  | 22  | 20  | 22  | 19  | 23  |
| Present Days   | 20  | 18  | 0   | 21  | 20  | 19  | 16  | 20  | 18  | 20  | 17  | 21  |
| Percentage     | 91% | 90% | -   | 91% | 91% | 90% | 89% | 91% | 90% | 91% | 89% | 91% |
| Reason         |     |     | Summer Vac |     |     |     | Diwali |     | Winter Break |     |     |     |

### Explaining Each Row in the Table

The table has four rows. Let us look at each row one by one.

#### Row 1: Working Days

This row comes from the admin's configuration. The admin typed these numbers into the 12 boxes. Every student in the school uses the same working days numbers. They are the same for everyone.

The teacher CANNOT change these numbers. They are locked. If the teacher tries to click on them, nothing happens. The numbers are grey and cannot be edited.

In the example above, April shows 22 working days. That means the school was open 22 days in April. June shows 0 working days because the school was closed for summer vacation.

#### Row 2: Present Days

This row comes from each student's individual attendance records. Every day a teacher takes attendance. If the student is in school that day, the computer marks them present. If the student is absent, the computer marks them absent.

The computer adds up all the present days for each month automatically. The teacher does not type these numbers. They are already filled in by the computer.

In the example above, Aarav was present 20 days out of 22 in April. He was present 18 days out of 20 in May. He was present 0 days in June because the school was closed. He was present 21 days out of 23 in July.

These numbers are different for every student. One student might have 20 present days in April. Another student might have 22 present days in April. It depends on the student's own attendance record.

#### Row 3: Percentage

This row is calculated by the computer automatically. The computer divides Present Days by Working Days and multiplies by 100.

For April: 20 divided by 22 equals 0.909. Times 100 equals 90.9. The computer rounds to 91 percent.

For May: 18 divided by 20 equals 0.9. Times 100 equals 90 percent.

For June: Working Days is 0. You cannot divide by zero. So the computer shows a dash (-) or says N/A. This means Not Applicable.

For July: 21 divided by 23 equals 0.913. Times 100 equals 91.3. The computer rounds to 91 percent.

The percentage row is grey. The teacher cannot edit it. It is calculated automatically every time.

#### Row 4: Reason

This row is optional. The teacher can type a short note explaining why the student was absent in a particular month.

In the example above, the teacher typed "Summer Vac" in June because the school was closed. The teacher typed "Diwali" in October because the student was absent for the Diwali festival. The teacher typed "Winter Break" in December because the school had winter holidays.

The teacher can leave this row empty if there is no special reason to explain.

### What Is at the Bottom of the Table?

Below the 12 months, there is usually a row that shows totals for the whole year. This row shows:

Total Working Days: This is the sum of all 12 months. In the example above: 22 + 20 + 0 + 23 + 22 + 21 + 18 + 22 + 20 + 22 + 19 + 23 = 232 total working days for the year.

Total Present Days: This is the sum of all present days. In the example: 20 + 18 + 0 + 21 + 20 + 19 + 16 + 20 + 18 + 20 + 17 + 21 = 210 total present days for the year.

Overall Percentage: Total Present divided by Total Working Days. 210 divided by 232 equals 0.905. Times 100 equals 90.5 percent. The computer rounds to 91 percent.

### Can the Teacher Add Extra Rows?

Yes. The attendance table is flexible. The teacher can add extra rows. For example, the teacher might want a row for "Half Days" or a row for "Late Arrivals." The teacher clicks a button that says "Add Row." A new blank row appears. The teacher can type whatever they want in that row.

The teacher can also remove rows. Maybe the "Reason" row is not needed. The teacher clicks a button to remove that row. The row disappears.

### Can the Teacher Add Extra Month Columns?

Yes. The standard table shows April through March. But some schools use a different calendar. The teacher can add a column for an extra month. The teacher clicks a button that says "+" (plus). A new column appears on the right side.

The teacher can also remove a column. The teacher clicks a button that says "-" (minus). The last column on the right disappears.

### How Does the Dynamic Table Work on the Inside?

The table is not a fixed picture. It is a flexible grid. The computer builds the table based on settings that the admin chooses in a different part of the system called Template Management. If the admin says the attendance section should be a table, the computer shows a spreadsheet-like grid. The teacher can edit the grid like they would edit a spreadsheet on a computer.

---

## PART 4: When Does the Computer Calculate Attendance?

The computer calculates attendance at two different times. Both times are very important.

### Time 1: When the Teacher Opens the Card

When the teacher clicks on a student's name to open their progress card, the computer reads the latest working days numbers. Then the computer reads the student's attendance records. Then the computer fills in the table and calculates the percentages.

This happens every time the teacher opens the card. Even if the teacher opened the same card yesterday and opens it again today, the computer recalculates everything fresh. This ensures the teacher always sees the newest data.

### Time 2: When the Teacher Generates a PDF

When the teacher decides to make a PDF of the card (to print it or email it), the computer calculates attendance again. Even if the teacher already looked at the card on the screen, the computer does the math once more just for the PDF.

### Why Calculate Twice?

Here is a real example of why this is important.

Mrs. Sharma is a teacher. On Monday, she opens Aarav's card. The computer calculates attendance. Aarav has 20 present days in April. Everything looks correct. Mrs. Sharma closes the card.

On Tuesday, Aarav is absent from school. The attendance system records this absence.

On Wednesday, Aarav is absent again.

On Friday, Mrs. Sharma opens Aarav's card again to generate a PDF for parents. The computer recalculates attendance. Now Aarav has only 18 present days in April (because he missed Tuesday and Wednesday). The percentage changes from 91 percent to 82 percent.

If the computer did not recalculate at PDF time, the PDF would show the old, wrong number. The parents would see incorrect attendance. They would be confused or angry.

By calculating twice, the computer always puts the most up-to-date numbers on the PDF.

### Can the Teacher Force a Recalculation?

The teacher does not need to force anything. The computer does it automatically every time. The teacher just needs to open the card or click Generate PDF. Everything else happens by itself.

---

## PART 5: Step-by-Step Example for a New School Year

Let us walk through an entire example from start to finish. This will help you understand how the feature works in real life.

### Step 1: School Year Begins

It is April 1. The new school year is starting. The admin, Mr. Kumar, needs to set up the attendance configuration.

### Step 2: Admin Opens the Attendance Screen

Mr. Kumar logs in to the computer system. He finds the Attendance Configuration screen. He sees 12 empty boxes.

### Step 3: Admin Types Working Days

Mr. Kumar looks at the school calendar. He sees that April has 22 working days (no weekends, no holidays). He types 22 in the April box.

He continues for all 12 months:
May: 20 working days
June: 0 working days (summer vacation in his state)
July: 23 working days
August: 22 working days
September: 21 working days
October: 18 working days (Diwali holidays)
November: 22 working days
December: 20 working days (winter break)
January: 22 working days
February: 19 working days
March: 23 working days

### Step 4: Admin Clicks Save

Mr. Kumar clicks the Save button. The computer stores all 12 numbers. A green message appears: "Attendance configuration saved successfully."

### Step 5: Teacher Opens a Student Card

Later that day, Mrs. Sharma (a class teacher) opens Aarav's card. The computer reads the working days numbers that Mr. Kumar saved. The computer reads Aarav's attendance records from the school's attendance system. The computer builds the attendance table.

Mrs. Sharma sees that Aarav has been present 20 days out of 22 in April. The percentage shows 91 percent. Mrs. Sharma is happy with the result.

### Step 6: Admin Realizes a Mistake

In May, Mr. Kumar realizes he made a mistake. The school had a staff training day on May 10 that he forgot about. The school was closed that day. So May should have 19 working days, not 20.

Mr. Kumar goes back to the Attendance Configuration screen. He changes May from 20 to 19.

### Step 7: Computer Recalculates Everything

The moment Mr. Kumar clicks Save, the computer recalculates every student's May attendance percentage. Aarav's May working days drop from 20 to 19. But Aarav was present on May 10 (the training day was for teachers only, students stayed home). Actually wait - if the school was closed, students could not attend. So Aarav's present days might also drop.

The computer handles all of this. Every student's percentage is recalculated. No one has to do anything.

### Step 8: Teacher Generates PDF

At the end of the term, Mrs. Sharma generates PDFs for all her students. Each PDF has accurate attendance numbers. Parents receive the cards and see correct information.

---

## PART 6: Important Rules to Remember

Here are the most important things to remember about this feature.

### Rule 1: April to March

The school year is April to March, not January to December. All 12 boxes follow this order. Do not try to put January first.

### Rule 2: Recalculated Every Time

Attendance is recalculated every single time the card is opened or a PDF is generated. The numbers are never old or stale. They are always fresh and up to date.

### Rule 3: Working Days Is School-Wide

The working days numbers apply to all students equally. You cannot set different working days for different students. If you need different calendars for different classes, that would need a different feature.

### Rule 4: Zero Working Days

If a month has zero working days (like June for summer vacation), that month shows no attendance data. The percentage shows a dash (-) or N/A. The present days also show zero or are blank.

### Rule 5: Present Days Come from Attendance Records

The present days numbers come from each student's individual attendance record. The working days configuration only provides the total possible days. The actual attendance data comes from the daily attendance that teachers take.

### Rule 6: Admin Only

Only the admin can change the working days numbers. Teachers cannot change them. Teachers can only view the results on the student cards.

---

## PART 7: Technical Notes for Developers

This section is for people who build or maintain the software. Regular users can skip this part.

### Database Tables

The working days configuration is stored in a database table. Each school year has one row with 12 columns (one per month) or 12 rows (one per month). The system reads this configuration whenever attendance needs to be calculated.

The attendance data (present days per student per month) comes from the school's existing attendance system or from a dedicated HPC attendance table.

### Calculation Logic

The calculation is: Percentage = (PresentDays / WorkingDays) * 100

If WorkingDays is 0, the percentage is set to null or shown as N/A.

The calculation runs inside a function that is called:
1. When the teacher opens the card (controller loads the data)
2. When the PDF is generated (before the PDF is rendered)

### Performance Considerations

For a school with 1000 students, recalculating all attendance percentages takes very little time (usually less than a second). The calculation is simple math. The main work is reading the data from the database, not doing the math.

If recalculating becomes slow (for very large schools with many years of data), the system might need to cache the results. But for most schools, caching is not necessary.

### Known Issues

There are no known issues with the attendance calculation itself. The calculation is straightforward and works correctly.

The only potential issue is if the attendance data source changes. If the school changes its attendance system, the HPC system needs to be updated to read from the new source.

---

## Summary

The Attendance Management feature does three things:
1. Lets the admin set working days for each month
2. Shows a summary of all students' attendance
3. Shows a detailed attendance table on each student's card

Everything is calculated automatically. No one has to do math by hand. The numbers update automatically whenever anything changes. This saves hours of work and ensures accuracy.
