# Requirements Doc - Automatic Timetable Generation and Teacher Alternate finder

This document outlines the requirements for a web-based version of the ‘Automatic Timetable Generation’ and ‘Teacher Alternate finder’. I have also used information from a opensource timetable generator called FET timetabling application. I want to develop this application using PHP with Laravel and MySQL database. The requirements are based on an evaluation of the official FET manual, a basic guide for screen design, the features listed on the application's website, and the new requirement to manage substitute teachers. I have also added requirements received directly from schools.
To develop a full-featured timetable generation and management module that supports automatic and manual timetable scheduling for schools, incorporating the advanced constraint-based engine similar to FET. 

Below are the functionalities which should be covered in the application -
1. Landing page which should have a dashboard with Menu and Submenu to run all below functionalities of the Application. Below are Menu and Submenu options –
   - Setup
     1. New Timetable
     2. Open Generated Timetable
     3. Mode
        - Single Shift
        - Two Shifts (Morning & Afternoon)
        - Block (Date) Planning (Exam Timetable, Extra Classes etc.)
        - Terms Planning
        - Group Planning
     4. Save / Save as / Autosave Settings
     5. Import & Export in CSV (Text)
        - Subject
        - Activity
        - Teachers
        - Years, Groups & Sub-Groups
        - Rooms and Building
        - Study Format

   - Data
     1. Institution Information - This will have Institution Name, Address and Shifts in Schools etc.
     2. Days & Hours - Here we configure How many days per week school will be open and how many hours per day it will operate, this include Interval and other Breaks also.
     3. Subject
     4. Study Format - (A Sub-Group under Subject like Lecture, Lab etc.) (Study Format  in FET)
     5. Teacher
     6. Students (It will have Sessions, Class, Section and Group under a Section of a Class)
     7. Activities / Sub-Activities
     8. Building & Rooms
     9. Constraints
        - Time Constraints
            + List of Time Constraints
            + Set Break Time
            + Basic Hard Constrains
            - These are the basic compulsory constraints (referring to time allocation) for any timetable
            - Weight (percentage)=100%. The basic time constraints must be avoided : 
                i.	 teachers assigned to more than one activity simultaneously
                ii.	 students assigned to more than one activity simultaneously
                iii. Any Activity can not be assigned in Breaktime (Hard Constraint)
        - Soft Time Constrains
            - These are the soft constraints (referring to time allocation) for any timetable
            - Weight (percentage)=1 to 100%. The soft time constraints try to avoid : 
                i.	 teachers assigned to more than one activity simultaneously
                ii.	 students assigned to more than one activity simultaneously
                iii. Activity can be assign for soft constraints.

        For a particular Teacher
            + A Teacher’s not available Times
            + A teacher does not work 2 consecutive days
            + Max single gaps in selected time slots for a teacher
            + Max & Min days per week for a teacher
            + Max gaps per day & per week for a teacher
            + Max & Minimum hours daily for a teacher
            + Max hours daily in an hourly interval for a teacher
            + A teacher has a pair of mutually exclusive time slots
            + Max span per day for a teacher
            + Min & Max hours daily with a Study Format (Lecture, Lab etc.) for a teacher
            + Max Study Format from a set per day for a teacher
            + Min hours daily for a teacher
            + Max hours continuously for a teacher
            + Max hours continuously with a Study Format for a teacher
            + Min Gap between an ordered pair of Study Format for a teacher
            + A Teacher works in an hourly interval max days per week
            + Min resting hours for a teacher
        For All Teachers
            >	Teacher’s not available Times
            >	Max & Min days per week for all teachers
            >	Max gaps per day & per week for all teacher
            >	All teacher do not work 2 consecutive days
            >	Max single gaps in selected time slots for all teachers
            >	Max & Min hours daily for all teacher
            >	Max hours daily in an hourly interval for all teachers
            >	All teachers have a pair of mutually exclusive time slots
            >	Max span per day for all teachers
            >	Max & Min hours daily with a Study Format for all teacher
            >	Max Study Format from a set per day for all teacher
            >	Max hours continuously for all teachers
            >	Max hours continuously with a Study Format for all teachers
            >	Min gaps between a Study Format for all teachers
            >	Min Gap between an ordered pair of Study Format for all teachers
            >	All Teachers works in an hourly interval max days per week
            >	Min resting hours for all teachers

    2.	Space Constraints
        a.	List of Space Constraints
        b.	Basic Hard Space Constrains
        These are the basic compulsory constraints (referring to rooms allocation) for any timetable Weight (percentage)=100%. The basic space constraints try to avoid:
            i.	rooms assigned to more than one activity simultaneously
            ii.	activities with more students than the capacity of the room
        c.	Soft Space Constrains
            Rooms
                >	A room’s not available Times
                >	A teacher + a room’s not available times
                >	Max Study Format from a set per day & per week for a room
            Teachers
                For a particular Teacher
                    >	A teacher has a home room
                    >	A teacher has a set of home rooms
                    >	Max room changes per day & per week for a teacher.
                    >	Max room changes per day in an hourly interval for a teacher
                    >	Min gaps between room changes for a teacher
                    >	Max building changes per day & per week for a teacher
                    >	Max building changes per day in an hourly interval for a teacher
                    >	Min gaps between building changes for a teacher
                For all Teachers
                    >	Max room changes per day & per week for all teachers
                    >	Max room changes per day in an hourly interval for all teachers
                    >	Min gaps between room changes for all teachers
                    >	Max building changes per day & per week for all teachers
                    >	Max building changes per day in an hourly interval for all teachers
                    >	Min gaps between building changes for all teachers
            Students
                For a particular Student
                    >	A set of students has a home room
                    >	A set of students has a set of home rooms
                    >	Max room changes per day & per week for a students set
                    >	Max room changes per day in an hourly interval for a students set
                    >	Min gaps between room changes for a students set
                    >	Max building changes per day & per week for a students set
                    >	Max building changes per day in an hourly interval for a students set
                    >	Min gaps between building changes for a students set
                For all Students
                    >	Max room changes per day & per week for all students
                    >	Max room changes per day in an hourly interval for all students
                    >	Min gaps between room changes for all students
                    >	Max building changes per day & per week for all students
                    >	Max building changes per day in an hourly interval for all students
                    >	Min gaps between building changes for all students
            Subjects
                >	A Subject has a preferred room
                >	A Subject has a set of preferred rooms
            Study Format
                >	A Study Format has a preferred room
                >	A Study Format has a set of preferred rooms
            Subjects and Study Format
                >	A Subject + an Study Format have a preferred room
                >	A Subject + an Study Format has a set of preferred rooms
            Activities
                >	A Activity has a preferred room
                >	A Activity has a set of preferred rooms
                >	A set of activities are in the same room if they are consecutive
                >	A set of activities occupies max different rooms

c.	History
    i.	Restore State
    ii.	Memory History Settings
    iii.	Disk History Settings
d.	Statistics
    i.	Teacher’s Statistics
    ii.	Subject’s Statistics
    iii.	Student’s Statistics
    iv.	Activities Rooms Statistics
    v.	Teacher Subjects Qualification Statistics
    vi.	Print Advanced Statistics
    vii.	Export Advanced Statistics
    viii.	Help on Statistics
e.	Advanced
    i.	Activity Planning
    ii.	Spread the activity evenly over the week
    iii.	Remove redundant constraint
    iv.	Group activities in the initial order of generation 
f.	Timetable
    •	Generate New
    •	View Teachers
    •	Day Horizontal
    •	Day Vertical
    •	Time Horizontal
    •	View Students
    •	Day Horizontal
    •	Day Vertical
    •	Time Horizontal
    •	View Rooms
    •	Day Horizontal
    •	Day Vertical
    •	Time Horizontal
    •	Show Soft Conflicts
    •	Print
    •	Advance Lock / Unlock
    •	Lock all activities of the current Timetable
    •	Un-Lock all activities of the current Timetable
    •	Lock all activities of a specified day
    •	Un-Lock all activities of a specified day
    •	Lock all activities which ends students day
    •	Un-Lock all activities which ends students day
    •	Lock all activities with a specified Study format
    •	Un-Lock all activities with a specified Study format
    •	Lock all activities selected with an advance filter
    •	Un-Lock all activities selected with an advance filter
    •	Save data & Timetable as
    •	Generate Multiple
g.	Setting
    i.	Language
    ii.	Timetable
        o	Categories of Timetable to be written on Disk
        o	HTML level for generated timetables
        o	Data to print in timetables
        o	Print detailed timetables
        o	Print detailed teacher’s free periods timetable
        o	Mark not available slots with -x- in timetables
        o	Mark break slots with -X- in Timetables
        o	Order subgroups timetables alphabetically
        o	Divide HTML timetables with time axis by days
        o	Duplicate vertical headers at the end
        o	Print activities with same starting time in timetables
        o	Print virtual rooms in Timetables.
    iii.	Confirmations
        o	Confirm activity planning
        o	Confirm spread activities over the week
        o	Confirm remove redundant constraints
        o	Confirm save data and timetable as
        o	Confirm activating / Deactivating activities/constraints
    iv.	Output directory and Files
        o	Select output directory
        o	Overwrite single generation files
    v.	Notification command
    vi.	Advanced
        o	Seed of random number generator
        o	Warn subgroups with the same activities
        o	Warn if using max hours daily with a weight less than 1100%
        o	Enable group activities in the initial order
        o	Warn if using group activities in the initial order
        o	Warn activities not locked in time but locked in a virtual room + real rooms
    vii.	Restore default settings
    viii.	Help on settings
h.	Help
    i.	Instructions
    ii.	Important tips

Below is other information for the Application :
    •	All Frontend, Backend programs for entering Master Data manually i.e 
    •	The algorithm is heuristic.
        o	Input: a set of activities A_1...A_n and the constraints.
        o	Output: a set of times TA_1...TA_n (the time slot of each activity. Rooms are excluded here, for simplicity).
        o	The algorithm must put each activity at a time slot, respecting constraints. Each TA_i is between 0 (T_1) and max_time_slots-1 (T_m).

    •	Constraints:
        o	C1) Basic: a list of pairs of activities which cannot be simultaneous (for instance, A_1 and A_2, because they have the same teacher or the same students);
        o	C2) Lots of other constraints (excluded here, for simplicity).


    •	The timetabling algorithm (which I named "recursive swapping", although it might be related to the algorithm known as "ejection chain" or the more generalized "ejection tree"; it might also be related to the manual timetabling method):
        o	1) Sort the activities, most difficult first. Not critical step, but speeds up the algorithm maybe 10 times or more.
        o	2) Try to place each activity (A_i) in an allowed time slot, following the above order, one at a time.
        o	Search for an available slot (T_j) for A_i, in which this activity can be placed respecting the constraints.
        o	If more slots are available, choose a random one. If none is available, do recursive swapping:
            >	2 a) For each time slot T_j, consider what happens if you put A_i into T_j. There will be a list of other activities which don't agree with this move (for instance, activity A_k is on the same slot T_j and has the same teacher or same students as A_i). Keep a list of conflicting activities for each time slot T_j.
            >	2 b) Choose a slot (T_j) with lowest number of conflicting activities. Say the list of activities in this slot contains 3 activities: A_p, A_q, A_r.
            >	2 c) Place A_i at T_j and make A_p, A_q, A_r unallocated.                
            >	2 d) Recursively try to place A_p, A_q, A_r (if the level of recursion is not too large, say 14, and if the total number of recursive calls counted since step (2) on A_i began is not too large,  say 2*n), as in step (2).
            >	2 e) If successfully placed A_p, A_q, A_r, return with success, otherwise try other time slots (go to step (2 b) and choose the next best time slot).
            >	2 f) If all (or a reasonable number of) time slots were tried unsuccessfully, return without success.
            >	2 g) If we are at level 0, and we had no success in placing A_i, place it like in steps (2 b) and (2 c), but without recursion. We have now 3 - 1 = 2 more activities to place. Go to step (2) (some methods to avoid cycling are used here).

Some more detail about the algorithm:
    •	FET uses a heuristic algorithm, placing the activities in turn, starting with the most difficult ones. If it cannot find a solution it points you to the potential impossible activities, so you can correct errors. The algorithm swaps activities recursively if that is possible in order to make space for a new activity, or, in extreme cases, backtracks and switches order of evaluation. The important code is in src/engine/generate.cpp. The algorithm mimics the operation of a human timetabler, I think.
    •	When placing an activity, I choose the place with lowest number of conflicting activities and recursively replace them. I use a tabu list to avoid cycles.
    •	The maximum depth (level) of recursion is 14.
    •	The maximum number of recursive calls is 2*nInternalActivities (found practically - modified 18 Aug. 2007). I tried with variable number, more precisely the 2*(number of already placed activities+1). I am not sure about the results, it might be better with variable number, but not sure.
    •	The recursion chooses only one variant from depth 5 (modified 15 Aug. 2007) above, then it returns.
    •	How to respect the students gaps (possible in combination with early)? Compute the number of total hours per week for each subgroup, then when generating, the total span of lessons should not exceed the total number of hours per week for the subgroup. The span is computed differently if you have no gaps or if you have no gaps+early
    •	The structure of the solution is an array of times[MAX_ACTIVITIES] and rooms[MAX_ACTIVITIES], I hope you understand why. I begin with unallocated. I sort the activities, most difficult ones first. Sorting is done in generate_pre.cpp. In generate_pre.cpp I also compute various matrices which are faster to use than the internal constraints list. Generation is recursive. Suppose we are at activity no. permutation[added_act] (added_act from 0 to gt.rules.nInternalActivities - permutation[i] keeps the activities in order, most difficult ones first, and this order will possibly change in allocation). We scan each slot and for each slot record the activities which conflict with permutation[added_act]. We then order them, the emptiest slots first. Then, for the first, second, ... last slot: unallocated the activities in this slot, place permutation[added_act] and try to place the remaining activities recursively with the same procedure. The max level of recursion is 14 (humans use 10, but I found that sometimes 14 is better) and the total number of calls for this routine, random_swap(act, level) is 2*nInternalActivities (found practically - might not be the best).
    •	If I cannot place activity permutation[added_act] this way (the 2*nInternalActivities limit is reached), then I choose the best slot, place permutation[added_act] in this slot and pull out the other conflicting activities from this slot and add them to the list of unallocated activities. added_act might decrease this way. Now I keep track of old tried removals and avoid them (they are in the tabu list - with size tabu_size (nInternalActivities*nHoursPerWeek for now)) - to avoid cycles.
    •	The routine random_swap will only search (recursively) the first (best) slot if level>=5. That is, we search at level 0 all slots, at level 1 the same, ..., at level 4 the same, at level 5 only the first (best) slot, at level 6 only the first (best) slot, etc., we reach level 13, then we go back to level 4 and choose the next slot, etc. This is to allow FET more liberty, I think. This trick was found practically to be good. It might not always be good.

    •	Fully automatic generation algorithm, allowing also semi-automatic or manual allocation
    •	Import/export from CSV format
    •	The resulted timetables are exported into HTML, XML and CSV formats
    •	Flexible students structure, organized into sets: years, groups and subgroups. FET allows overlapping years and groups and non-overlapping subgroups. You can even define individual students (as separate sets)
    •	Flexible students structure, organized into sets: Class, Section and subgroups. Allows overlapping Class and Section and non-overlapping subgroups. You can even define individual students (as separate sets)
    •	Each constraint has a weight percentage, from 0.0% to 100.0% (but some special constraints are allowed to have only 100% weight percentage)

•	A large and flexible palette of time constraints:
    •	Break periods
    •	For teacher(s):
        o	Not available periods
        o	Max/min days per week
        o	Max gaps per day/week
        o	Max hours daily/continuously
        o	Max span per day
        o	Min hours daily
        o	Max hours daily/continuously with an Study Format 
        o	Min hours daily with an Study Format 
        o	Min gaps between an ordered pair of Study Format 
        o	Respect working in an hourly interval a max number of days per week
        o	Min resting hours
    •	For students (sets):
        o	Not available periods
        o	Max days per week
        o	Begins early (specify max allowed beginnings at second hour)
        o	Max gaps per day/week
        o	Max hours daily/continuously
        o	Max span per day
        o	Min hours daily
        o	Max hours daily/continuously with an Study Format 
        o	Min hours daily with an Study Format 
        o	Min gaps between an ordered pair of Study Format 
        o	Respect working in an hourly interval a max number of days per week
        o	Min resting hours
    •	For an activity or a set of activities/subactivities:
        o	A single preferred starting time
        o	A set of preferred starting times
        o	A set of preferred time slots
        o	Min/max days between them
        o	End(s) students day
        o	Same starting time/day/hour
        o	Occupy max/min time slots from selection (two complex and flexible constraints, useful in many situations)
        o	Consecutive, ordered (and ordered if same day), grouped (for 2 or 3 (sub)activities)
        o	Not overlapping (also for Study Format )
        o	Max/min simultaneous in selected time slots
        o	Min gaps between a set of (sub)activities
    •	A large and flexible palette of space constraints:
        o	Room not available periods
        o	For teacher(s):
            >	Home room(s)
            >	Max room/building changes per day/week
            >	Min gaps between room/building changes
        o	For students (sets):
            >	Home room(s)
            >	Max room/building changes per day/week
            >	Min gaps between room/building changes
        o	Preferred room(s):
            >	For a subject
            >	For an Study Format 
            >	For a subject and an Study Format 
            >	Individually for a (sub)activity
        o	For a set of activities:
            >	Have the same room if they are consecutive
            >	Occupy a maximum number of different rooms

Database Requirements (MySQL)
The database schema must be designed to store all the data required for timetable generation, including institution details, scheduling parameters, and the various constraints. At high level below are the Tables which will be required but you need to think and add more as required -
    •	institutions: Stores basic information about the school or university.
    •	days_and_hours: Defines the weekly schedule structure.
        o	A related table to store the custom names/times for each period (e.g., "08:05 - 08:50").
    •	subjects: Lists all subjects offered.
    •	activity_tags: Stores optional labels for activities (e.g., 'lecture', 'lab'). We can call it Period_Type
    •	teachers: Stores teacher information.
    •	students: Manages the student population structured by years, groups, and subgroups.
        o	 Self-referencing Foreign Key to link groups to years, and subgroups to groups
    •	buildings: Lists the physical buildings on campus.
    •	rooms: Manages the classrooms and other spaces.
        o	Will connect with buildings table
    •	activities: The core table for all timetabled events.
    •	constraints: A highly flexible table or set of tables to store the numerous time and space constraints. Each constraint must have an associated weight (from 0% to 100%), with 100% indicating a compulsory rule. Examples of constraints include:
        o	Foreign keys linking to the relevant teachers, students, rooms, or activities tables.


Additional requirement from School
==================================
Class 2 to 12
Constraints For Timetable
    1.	Maths of 4T should be allotted from period 6 to 8 since the math’s teacher is busy till 5th period.
    2.	Class Teachers should be given first period.
    3.	Few teachers may have more than 36 periods in a week.
    4.	Major Subjects should fall every day.
    5.	Teacher’s should have atleast one free period in first half (Period-1 to 4) and one free in second half (Period-5 to 8)
    6.	Games, Library, Art, Hobby, Dance, Music Should not be on same day. 
        Maximum   2 minor periods can be in a day in a class.
    7.	Practical period of different optional subjects(Run Parallel) varies:
        Hindi – 0					IP  - 4
        Economics – 0				PHE - 2
        Math’s – 0				Psychology - 2
    8.	Skill subjects: No of Periods varies(Run Parallel)
        Banking - 3
        AI – 4
        Taxation – 4
        Yoga – 4 
        Mass Media – 3 
    9.	Consecutive two periods for:
        >	Hobby (Classes 6 to 9)
        >	Astro (Classes 3 to 8)
        >	Robotics (Classes 6 to 8)
        >	Phy/Chem Practical (Classes 11  and 12)
        >	Bio Practical (Classes 11  and 12)
    10.	Parallel Periods for: 
        >	Hobby 	(Classes 6A,6B,6C)
                        (Classes 7A,7B,7C)
                        (Classes 8A,8B,8C)
                        (Classes 9A,9B,9C)
        >	Skill      (Classes 11 A, 11 B, 11 C , 11 D , 11E)       
        (Classes 12 A, 12B , 12C, 12D, 12E)
        >	Optional Subjects (11 A, B, C, E)  ( 12 B,C,E)
    11.	Hobby period includes more than 10 teachers. All hobby teachers should be allotted timetable accordingly. (Hobby Teachers—Music Teachers, Dance Teachers, Games Teachers, Art Teachers)
    12.	Optional Subject for Class 11,12 includes 7 teachers and Skill Subject includes 6 teachers. 
    13.	Astro should be from Monday to Friday.
    14.	Wonder Brain (comes on Friday in classes 3 to 5)
        So Astro should not fall on Friday in classes 3 to 5.

Resource Allocation ( to avoid clashes in Labs):
-----------------------------------------------
    1.	In Computer Lab:
        For Computer Practical period  [Classes 1 to 8]
    2.	Senior Computer Lab 
        Class 11 and 12  :   IP Practical periods
        Class 9 and 10     :  IT Practical period 
    3.	Robotics Lab:
        Class 4 to 8          :  Robotics period 
        Class 11,12	  : Skill periods of AI 
    4.	Biology/Chemistry Lab
        Class 11A, 11B, 11D -- Physics /Chemistry Practical period 
        Class 12A, 12B, 12D -- Physics /Chemistry Practical period

