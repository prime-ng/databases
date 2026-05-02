I want you to act as a Enterprise Architect. Read all below files to get a in-depth understand of "SmartTmetable" Module. Here is the detail of files you need to read :

- Read AI-Brain from "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain" to get all the path info.
- Also fetch the understanding about the entire application inclduing "SmartTmetable" from Ai_Brain.
- Read all the files from "/Users/bkwork/Herd/prime_ai/Modules/SmartTimetable", which is main folder of "SmartTmetable" Module
- Read all the files from "/Users/bkwork/Herd/prime_ai/Modules/TimetableFoundation", , which is main folder for all dependent functionalities of "SmartTmetable" Module
- Read file "Timetable_Algorithm_Guide.md", "Timetable_Process_Detail_v1.md" & "Timetable_Process_Detail_v2.md" from folder "/Users/bkwork/WorkFolder/3-Local_Workspace/1-Working/Z-Timetable/Algo_Detail/". These are Claude generated files of how Timetable Generator Works but the information it provides is very generic whereas I am looking for a output which will be generic but includes some technical detail also. for exampal :
in Step - 2 "Timetable_Process_Detail_v1" says -

        ## Step 2 — The System Gathers All the Ingredients

        Before cooking, you need ingredients. The system loads:

        | What it loads | Real-world example |
        |---|---|
        | **Classes** | Class 5-A, Class 6-B, Class 10-Science |
        | **Activities (subjects)** | Math (5 times/week), English (4 times/week), PT (2 times/week) |
        | **Teachers** | Mrs. Sharma teaches Math, Mr. Khan teaches Science |
        | **Rooms** | Room 101, Lab-1, Music Room |
        | **School days** | Mon–Sat (Sunday off) |
        | **Period grid** | 8 periods per day, with lunch after period 4 |
        | **Class teaching windows** | Toddlers only have classes from 9 AM to 12 PM. Class 10 has the full day. |
        | **Daily targets** | Class 5-A should have 6–7 classes per day, not 12 in one day |

        **Example:** Toddlers go home early, so the system knows: "Don't put a class for them in the 5th period — they're already on the bus home."

Whereas I am expecting as below -

    ## Step 2 — The System Gathers All the required information to Generate Timetable, for that it will Load all below tables into memory:
     - sch_classes
     - sch_sections
     - sch_subjects
     - sch_subject_study_format_jnt
     - sch_class_groups_jnt
     - sch_subject_groups
     - sch_subject_group_subject_jnt
     - sch_rooms_type
     - sch_rooms
     - sch_teacher_profile
     - sch_teacher_capabilities



Timetable_Process_Detail_v2.md


------------------------------------------------------------------------------------------------------
I want you to act as a Enterprise Architect. 

Read all below files to get a in-depth understand of "SmartTmetable" Module. Here is the detail of files you need to read :

- Read AI-Brain from "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain" to get all the path info.
- Also fetch the understanding about the entire application inclduing "SmartTmetable" from Ai_Brain.
- Read all the files from "/Users/bkwork/Herd/prime_ai/Modules/SmartTimetable", which is main folder of "SmartTmetable" Module
- Read all the files from "/Users/bkwork/Herd/prime_ai/Modules/TimetableFoundation", , which is main folder for all dependent functionalities of "SmartTmetable" Module
- Read file "Timetable_Algorithm_Guide.md", "Timetable_Process_Detail_v1.md" & "Timetable_Process_Detail_v2.md" from folder "/Users/bkwork/WorkFolder/3-Local_Workspace/1-Working/Z-Timetable/Algo_Detail/". These are Claude generated files of how Timetable Generator Works.  Once you are done with the complete information about "SmartTimetable" Module, let me know. I have qeries to understand it in detail.

------------------------------------------------------------------------------------------------------

I want to refine the Algorithm especially the sequence of the parameter being used to priorities the allocation. Few quesries are below which will help me to understand the current parameter sqence being used in algo, which will ultimatly help me to refine the Algo. Answer the below queries and also provide any additional information which can help me to understand the internal machanism of the algorithm :
- What all Parameters are there which can be used to prioritise the placement of a teacher+Period to a Activity (Class+section+Subject+Study_Format)?
- What all Parameters are there which can be used to prioritise the placement of the Room to a Activity (Class+section+Subject+Study_Format)?
- What should be the Formula to calculate all the parameter which will be used to Prioritise Placements? If any will be provided by School (End User) then mark it as "User provided"
- What should be the Priority Sequence of all those Parameters to get perfect Placement of Teacher+Period & Rooms? Save the output into a file "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/Algo_Refinement/Algo_parameter_detail.md"





======================================================================================================
Queries / Checkpoint for Tarun
======================================================================================================
- Are we using `academic sessions` from Primedb?



------------------------------------------------------------------------------------------------------
Now when I have understood the Algorithm in detail what all Parameters it is using to priorities the Activities. I found many discripencies :
- Few Parameter which are being used to priorties Teacher (which activity we should place Teacher on first), actually should not be used for prioritising placement.
- Few Parameter has ben given higher weightage, however those are less important when we calculate prioritisation
- etc.

Now I want to know what is the best way to communicate all those discripencies, so that you can provide me a refined enhancement plan? Should I write all those discripencies in a saperarate .md file if yes then what should be format of that document(.md file)? Write the Template in folder "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/tt_SmartTimetable/Algo_Refinement"


In process to enhance the Algo, what is the best way to raise the Points to refine the Application: 
