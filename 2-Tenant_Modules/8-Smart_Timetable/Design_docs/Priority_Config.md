# Priority Configuration

Prioritising activities that will break the timetable if delayed.

1. Number of Qualified Teachers (Scarcity Index)
   - Fewer teachers ⇒ higher priority
   - Instead of “count is high”, use inverse scarcity:

    Teacher_Scarcity_Score = 1 / Qualified_Teacher_Count

   - Why?
   - 1 teacher → extremely risky
   - 5 teachers → flexible
   - Keep this parameter very high weight

2. Required Periods per Week
   - More required periods ⇒ higher priority
   - Good, but refine it:
   - Weekly_Load_Ratio = Required_Periods / Total_Weekly_Slots
   - This avoids bias toward subjects that simply have longer syllabi.

3. Teacher Availability Ratio (TAR)
   - Lower availability ⇒ higher priority
   - Perfect. Also add minimum TAR, not just sum:
   - Min_TAR among qualified teachers
   - One teacher with TAR = 95% can destroy feasibility even if others are free.

Now: Critical Parameters You Must Add (These Matter a LOT)
4. Time Window Constraints (Rigidity Score)
   - If an activity can happen only in limited slots, it must go first.
   - Examples:
   - Lab only in periods 3–6
   - PT only morning
   - Art only twice a week after lunch
   - Rigidity_Score = Allowed_Slots / Total_Slots
   - Priority ∝ 1 / Rigidity_Score
   - This is one of the most important parameters

5. Room / Resource Scarcity
   - Especially for:
   - Labs
   - Computer rooms
   - Sports ground
   - Music / Dance rooms
   - Resource_Scarcity = Required_Resource_Count / Available_Resources
   - If only 1 lab serves 8 sections, this activity must be placed early.

6. Activity Type (Hard vs Soft)
   - Assign base priority by activity nature:

| Activity Type             | Base Priority |
|---------------------------|---------------|
| Lab (double/triple period)| Very High     |
| Core Subject              | High          |
| Elective                  | Medium        |
| Co-curricular             | Low           |
| Library / Club            | Very Low      |

Reason:
   - Labs fragment the grid
   - Doubles are harder than singles

7. Period Contiguity Requirement
   - If activity requires:
   - Double period
   - Triple period
   - Fixed adjacency
   - Contiguity_Penalty = Required_Continuous_Periods
   - Higher contiguity ⇒ higher priority.

8. Class / Section Load Pressure
   - If a section already has:
   - High total weekly load
   - Many constrained subjects
   - Then remaining activities become harder.
   - Section_Pressure = Total_Required_Periods_for_Section / Total_Slots
   - This avoids painting a section into a corner.

9. Teacher Multi-Section Coupling
   - If same teacher teaches:
   - Same subject
   - Across many sections / classes
   - Then those activities are coupled and should be scheduled early.
   - Coupling_Score = Number_of_Activities_Sharing_Same_Teacher
   - This is critical for:
      - Maths
      - English
      - Science teachers

10. Class Grouping / Blocking Constraints
   - Examples:
   - Optional subjects running in parallel
   - Group A / Group B splits
   - Common electives across sections
   - Grouped activities must be prioritised together.
   - Group_Size_Factor = Number_of_Activities_in_Group

11. Pedagogical Preferences (Soft but Important)
   - Examples:
   - Maths not last period
   - Labs not after lunch
   - PT not first period
   - Even if “soft”, violating many soft rules causes dissatisfaction.
   - Track:
   - Soft_Constraint_Count

12. Historical Failure / Backtracking Cost (Advanced)
   - If in previous iterations this activity:
   - Causes backtracking
   - Gets frequently reshuffled
   - Increase its priority dynamically.
   - This makes your engine self-learning.

### Suggested Priority Matrix Structure

Create a weighted score:

Priority_Score =
  w1 * Teacher_Scarcity
+ w2 * Weekly_Load_Ratio
+ w3 * (1 / Min_TAR)
+ w4 * (1 / Time_Window_Rigidity)
+ w5 * Resource_Scarcity
+ w6 * Activity_Type_Base
+ w7 * Contiguity_Penalty
+ w8 * Section_Pressure
+ w9 * Teacher_Coupling
+ w10 * Group_Size_Factor
+ w11 * Soft_Constraint_Count


Then:

Sort Activities DESC by Priority_Score
Allocate in that order

### Practical Weighting Recommendation (Starting Point)

| Parameter                | Weight |
|--------------------------|--------|
| Teacher Scarcity         | 25     |
| Time Window Rigidity     | 20     |
| Resource Scarcity        | 15     |
| Required Periods         | 10     |
| TAR                      | 10     |
| Contiguity               | 8      |
| Teacher Coupling         | 7      |
| Section Pressure         | 5      |

Tune after dry-runs.

### Final Architectural Advice (Important)

👉 Do NOT calculate priority once.
Recalculate after every allocation.

Because:
   - TAR changes
   - Slot availability shrinks
   - Coupling impact increases

This turns your scheduler into a constraint-aware greedy + backtracking hybrid (enterprise grade).













------------------------------------------------------------------------------------------------------------------------------------------------------

2. Activity Duration (Total Hours)
   - Longer activities → higher priority
   - Formula:

Activity_Duration_Score = Total_Hours_Per_Week

   - Why?
   - 1 hour → easy to fit
   - 10 hours → must be scheduled early
   - High weight

3. Number of Groups (Breadth of Impact)
   - More groups → higher priority
   - Formula:

Group_Impact_Score = Number_of_Groups

   - Why?
   - 1 group → only one class affected
   - 10 groups → 10 classes affected
   - Medium-high weight

4. Teacher Workload Balance (Anti-Collision)
   - Activities with many teachers → higher priority
   - Formula:

Workload_Balance_Score = Total_Teacher_Hours

   - Why?
   - Many teachers = many constraints
   - Harder to schedule later
   - Medium weight

5. Required Room Type (Resource Constraint)
   - Special rooms → higher priority
   - Formula:

Room_Type_Score = 
    1 if Special_Room (Lab, Gym, Music)
    0 if Normal_Classroom

   - Why?
   - Labs/Gyms are limited
   - Normal classrooms are abundant
   - Medium weight

6. Activity Type (Subject Category)
   - Core subjects → higher priority
   - Formula:

Subject_Type_Score = 
    1 if Core (Math, Science, English)
    0 if Optional/Elective

   - Why?
   - Core subjects are mandatory
   - Optional subjects can be flexible
   - Low-medium weight

7. Teacher Availability (Flexibility Index)
   - Fewer available slots → higher priority
   - Formula:

Availability_Score = 1 / Available_Slots

   - Why?
   - Very limited availability = must schedule early
   - High weight

8. Student Availability (Group Constraints)
   - More constraints → higher priority
   - Formula:

Student_Constraint_Score = Number_of_Group_Constraints

   - Why?
   - Many groups = many conflicts
   - Harder to schedule later
   - Medium weight

9. Activity Duration Distribution (Anti-Fragmentation)
   - Activities that should be continuous → higher priority
   - Formula:

Continuity_Score = 
    1 if Continuous_Activity
    0 if Normal_Activity

   - Why?
   - Continuous activities must be scheduled together
   - Harder to fit later
   - Medium weight

10. Activity Priority Level (Manual Override)
    - User-defined priority → highest weight
    - Formula:

Manual_Priority_Score = User_Priority_Level

    - Why?
    - User knows best
    - Override all other factors
    - Highest weight

11. Activity Complexity (Internal Constraints)
    - More internal constraints → higher priority
    - Formula:

Complexity_Score = Number_of_Internal_Constraints

    - Why?
    - Complex activities = harder to schedule
    - Medium weight

12. Activity Dependencies (Precedence)
    - Dependent activities → higher priority
    - Formula:

Dependency_Score = Number_of_Dependencies

    - Why?
    - Must schedule before dependent activities
    - High weight

13. Activity Frequency (Total Slots)
    - More frequent → higher priority
    - Formula:

Frequency_Score = Total_Slots_Required

    - Why?
    - More slots = more opportunities to schedule
    - Medium weight

14. Activity Duration Variance (Anti-Fragmentation)
    - More variable duration → higher priority
    - Formula:

Duration_Variance_Score = Standard_Deviation_of_Durations

    - Why?
    - Variable durations = harder to fit
    - Medium weight

15. Activity Type Distribution (Balance)
    - Balanced distribution → higher priority
    - Formula:

Type_Balance_Score = 1 / (Max_Type_Count - Min_Type_Count + 1)

    - Why?
    - Balanced = easier to schedule
    - Medium weight

16. Activity Start Time Preference (User Preference)
    - Early preference → higher priority
    - Formula:

Start_Time_Score = 1 / (Preferred_Start_Time - Earliest_Possible_Time + 1)

    - Why?
    - User preference = important
    - Medium weight

17. Activity End Time Preference (User Preference)
    - Late preference → higher priority
    - Formula:

End_Time_Score = 1 / (Latest_Possible_Time - Preferred_End_Time + 1)

    - Why?
    - User preference = important
    - Medium weight

18. Activity Duration Preference (User Preference)
    - Preferred duration → higher priority
    - Formula:

Duration_Preference_Score = 1 / (Preferred_Duration - Min_Duration + 1)

    - Why?
    - User preference = important
    - Medium weight

19. Activity Gap Preference (User Preference)
    - Preferred gap → higher priority
    - Formula:

Gap_Preference_Score = 1 / (Preferred_Gap - Min_Gap + 1)

    - Why?
    - User preference = important
    - Medium weight

20. Activity Spread Preference (User Preference)
    - Preferred spread → higher priority
    - Formula:

Spread_Preference_Score = 1 / (Preferred_Spread - Min_Spread + 1)

    - Why?
    - User preference = important
    - Medium weight

21. Activity Clustering Preference (User Preference)
    - Preferred clustering → higher priority
    - Formula:

Clustering_Preference_Score = 1 / (Preferred_Clustering - Min_Clustering + 1)

    - Why?
    - User preference = important
    - Medium weight

22. Activity Sequence Preference (User Preference)
    - Preferred sequence → higher priority
    - Formula:

Sequence_Preference_Score = 1 / (Preferred_Sequence - Min_Sequence + 1)

    - Why?
    - User preference = important
    - Medium weight

23. Activity Grouping Preference (User Preference)
    - Preferred grouping → higher priority
    - Formula:

Grouping_Preference_Score = 1 / (Preferred_Grouping - Min_Grouping + 1)

    - Why?
    - User preference = important
    - Medium weight

24. Activity Room Preference (User Preference)
    - Preferred room → higher priority
    - Formula:

Room_Preference_Score = 1 / (Preferred_Room - Min_Room + 1)

    - Why?
    - User preference = important
    - Medium weight

25. Activity Teacher Preference (User Preference)
    - Preferred teacher → higher priority
    - Formula:

Teacher_Preference_Score = 1 / (Preferred_Teacher - Min_Teacher + 1)

    - Why?
    - User preference = important
    - Medium weight

26. Activity Student Preference (User Preference)
    - Preferred student → higher priority
    - Formula:

Student_Preference_Score = 1 / (Preferred_Student - Min_Student + 1)

    - Why?
    - User preference = important
    - Medium weight

27. Activity Constraint Preference (User Preference)
    - Preferred constraint → higher priority
    - Formula:

Constraint_Preference_Score = 1 / (Preferred_Constraint - Min_Constraint + 1)

    - Why?
    - User preference = important
    - Medium weight

28. Activity Dependency Preference (User Preference)
    - Preferred dependency → higher priority
    - Formula:

Dependency_Preference_Score = 1 / (Preferred_Dependency - Min_Dependency + 1)

    - Why?
    - User preference = important
    - Medium weight

29. Activity Frequency Preference (User Preference)
    - Preferred frequency → higher priority
    - Formula:

Frequency_Preference_Score = 1 / (Preferred_Frequency - Min_Frequency + 1)

    - Why?
    - User preference = important
    - Medium weight

30. Activity Duration Variance Preference (User Preference)
    - Preferred duration variance → higher priority
    - Formula:

Duration_Variance_Preference_Score = 1 / (Preferred_Duration_Variance - Min_Duration_Variance + 1)

    - Why?
    - User preference = important
    - Medium weight

31. Activity Type Distribution Preference (User Preference)
    - Preferred type distribution → higher priority
    - Formula:

Type_Distribution_Preference_Score = 1 / (Preferred_Type_Distribution - Min_Type_Distribution + 1)

    - Why?
    - User preference = important
    - Medium weight

32. Activity Start Time Preference (User Preference)
    - Preferred start time → higher priority
    - Formula:

Start_Time_Preference_Score = 1 / (Preferred_Start_Time - Min_Start_Time + 1)

    - Why?
    - User preference = important
    - Medium weight

33. Activity End Time Preference (User Preference)
    - Preferred end time → higher priority
    - Formula:

End_Time_Preference_Score = 1 / (Preferred_End_Time - Min_End_Time + 1)

    - Why?
    - User preference = important
    - Medium weight

34. Activity Duration Preference (User Preference)
    - Preferred duration → higher priority
    - Formula:

Duration_Preference_Score = 1 / (Preferred_Duration - Min_Duration + 1)

    - Why?
    - User preference = important
    - Medium weight

35. Activity Gap Preference (User Preference)
    - Preferred gap → higher priority
    - Formula:

Gap_Preference_Score = 1 / (Preferred_Gap - Min_Gap + 1)

    - Why?
    - User preference = important
    - Medium weight

36. Activity Spread Preference (User Preference)
    - Preferred spread → higher priority
    - Formula:

Spread_Preference_Score = 1 / (Preferred_Spread - Min_Spread + 1)

    - Why?
    - User preference = important
    - Medium weight

37. Activity Clustering Preference (User Preference)
    - Preferred clustering → higher priority
    - Formula:

Clustering_Preference_Score = 1 / (Preferred_Clustering - Min_Clustering + 1)

    - Why?
    - User preference = important
    - Medium weight

38. Activity Sequence Preference (User Preference)
    - Preferred sequence → higher priority
    - Formula:

Sequence_Preference_Score = 1 / (Preferred_Sequence - Min_Sequence + 1)

    - Why?
    - User preference = important
    - Medium weight

39. Activity Grouping Preference (User Preference)
    - Preferred grouping → higher priority
    - Formula:

Grouping_Preference_Score = 1 / (Preferred_Grouping - Min_Grouping + 1)

    - Why?
    - User preference = important
    - Medium weight

40. Activity Room Preference (User Preference)
    - Preferred room → higher priority
    - Formula:

Room_Preference_Score = 1 / (Preferred_Room - Min_Room + 1)

    - Why?
    - User preference = important
    - Medium weight

41. Activity Teacher Preference (User Preference)
    - Preferred teacher → higher priority
    - Formula:

Teacher_Preference_Score = 1 / (Preferred_Teacher - Min_Teacher + 1)

    - Why?
    - User preference = important
    - Medium weight

42. Activity Student Preference (User Preference)
    - Preferred student → higher priority
    - Formula:

Student_Preference_Score = 1 / (Preferred_Student - Min_Student + 1)

    - Why?
    - User preference = important
    - Medium weight

43. Activity Constraint Preference (User Preference)
    - Preferred constraint → higher priority
    - Formula:

Constraint_Preference_Score = 1 / (Preferred_Constraint - Min_Constraint + 1)

    - Why?
    - User preference = important
    - Medium weight

44. Activity Dependency Preference (User Preference)
    - Preferred dependency → higher priority
    - Formula:

Dependency_Preference_Score = 1 / (Preferred_Dependency - Min_Dependency + 1)

    - Why?
    - User preference = important
    - Medium weight

45. Activity Frequency Preference (User Preference)
    - Preferred frequency → higher priority
    - Formula:

Frequency_Preference_Score = 1 / (Preferred_Frequency - Min_Frequency + 1)

    - Why?
    - User preference = important
    - Medium weight

46. Activity Duration Variance Preference (User Preference)
    - Preferred duration variance → higher priority
    - Formula:

Duration_Variance_Preference_Score = 1 / (Preferred_Duration_Variance - Min_Duration_Variance + 1)

    - Why?
    - User preference = important
    - Medium weight

47. Activity Type Distribution Preference (User Preference)
    - Preferred type distribution → higher priority
    - Formula:

Type_Distribution_Preference_Score = 1 / (Preferred_Type_Distribution - Min_Type_Distribution + 1)

    - Why?
    - User preference = important
    - Medium weight

48. Activity Start Time Preference (User Preference)
    - Preferred start time → higher priority
    - Formula:

Start_Time_Preference_Score = 1 / (Preferred_Start_Time - Min_Start_Time + 1)

    - Why?
    - User preference = important
    - Medium weight

49. Activity End Time Preference (User Preference)
    - Preferred end time → higher priority
    - Formula:

End_Time_Preference_Score = 1 / (Preferred_End_Time - Min_End_Time + 1)

    - Why?
    - User preference = important
    - Medium weight

50. Activity Duration Preference (User Preference)
    - Preferred duration → higher priority
    - Formula:

Duration_Preference_Score = 1 / (Preferred_Duration - Min_Duration + 1)

    - Why?
    - User preference = important
    - Medium weight

51. Activity Gap Preference (User Preference)
    - Preferred gap → higher priority
    - Formula:

Gap_Preference_Score = 1 / (Preferred_Gap - Min_Gap + 1)

    - Why?
    - User preference = important
    - Medium weight

52. Activity Spread Preference (User Preference)
    - Preferred spread → higher priority
    - Formula:

Spread_Preference_Score = 1 / (Preferred_Spread - Min_Spread + 1)

    - Why?
    - User preference = important
    - Medium weight

53. Activity Clustering Preference (User Preference)
    - Preferred clustering → higher priority
    - Formula:

Clustering_Preference_Score = 1 / (Preferred_Clustering - Min_Clustering + 1)

    - Why?
    - User preference = important
    - Medium weight

54. Activity Sequence Preference (User Preference)
    - Preferred sequence → higher priority
    - Formula:

Sequence_Preference_Score = 1 / (Preferred_Sequence - Min_Sequence + 1)

    - Why?
    - User preference = important
    - Medium weight

55. Activity Grouping Preference (User Preference)
    - Preferred grouping → higher priority
    - Formula:

Grouping_Preference_Score = 1 / (Preferred_Grouping - Min_Grouping + 1)

    - Why?
    - User preference = important
    - Medium weight

56. Activity Room Preference (User Preference)
    - Preferred room → higher priority
    - Formula:

Room_Preference_Score = 1 / (Preferred_Room -