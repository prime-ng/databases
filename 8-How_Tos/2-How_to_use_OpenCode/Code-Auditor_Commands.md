# Command to use with Agent - Code_Auditor to generate a detailed Audit-Report for any Module
=============================================================================================

## Detail Command for Audit
-------------------------------------------------------------------------------------------------------------

cd /Users/bkwork/Herd/prime_testing && opencode run --standalone \
  --agent code-auditor \
  --model opencode-go/deepseek-v4.1-flash \
  "Code Auditor, Audit, <Module_Name>, <Developer_Name>"

Example — audit the BehaviouralAssessment module for tarun

---

cd /Users/bkwork/Herd/prime_testing && opencode run --standalone \
  --agent code-auditor \
  --model opencode-go/deepseek-v4.1-flash \
  "Code Auditor, Audit, <Module_Name>, <Developer_Name>"


---------------------------------------------------------------------------------------



## Command to Generate Audit Report for any Particuler Module of a Particuler Developer
---------------------------------------------------------------------------------------
Below command will Generate 2 Reports for every Controller in the Module ()

cd /Users/bkwork/Herd/prime_testing && opencode run --standalone --agent code-auditor --model opencode-go/deepseek-v4.1-flash "Code Auditor, Audit, FrontOffice, gaurav"


```

audit the LmsHomework module for shailesh. 
Do not assume anything, ask questions if you need any info.


OR

"Code Auditor, Audit, SyllabusBooks, gaurav"


Code Auditor, Audit,  BehaviouralAssessment, tarun
Code Auditor, Status, BehaviouralAssessment, tarun

---
audit the SchoolSetup module for shailesh. DO NOT Recreate files for the controllers which has been created already and create Audit only for pending Controllers. DO NOT change anything in prime_ai_dev repository.

```

=============================================================================================================================================================

audit the LmsQuiz module for shailesh by executing below command 
(cd /Users/bkwork/Herd/prime_testing && opencode run --standalone --agent code-auditor --model opencode-go/deepseek-v4.1-flash "Code Auditor, Audit, LmsQuiz, shailesh")
Do not assume anything, ask questions if you need any info.

audit the Recommendation module for gaurav by executing below command 
(cd /Users/bkwork/Herd/prime_testing && opencode run --standalone --agent code-auditor --model opencode-go/deepseek-v4.1-flash "Code Auditor, Audit, Recommendation, gaurav")
Do not assume anything, ask questions if you need any info.

=============================================================================================================================================================
### Module Already Processed by Team
------------------------------------
#### Tarun


#### Shailesh



#### Gaurav



### Modules Processed By Me:
----------------------------
audit the Syllabus module for shailesh. Do not assume anything, ask questions if you need any info.


