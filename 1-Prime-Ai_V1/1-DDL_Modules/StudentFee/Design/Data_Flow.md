# Data Flow and Integration Points
----------------------------------

| Process Step | Data Source | Data Required | Manual Entry | Target Table |
|----------------------|--------------------------------|--------------------------|-----------------------------|--------------------------------------|

### Fee Structure Creation				
| Create Fee Heads     |   -                            | Head details             | Name, Type, Amount          | fee_head_master
| Create Fee Groups    |   -                            | Group details            | Group name, heads selection | fee_group_master, fee_group_heads_jnt
| Define Fee Structure | sch_classes,                   | Class, Session, Category | Structure name, amounts     | fee_structure_master, 
|                      | sch_org_academic_sessions_jnt, |
|                      | sys_dropdown_table             |

### fee_structure_details
| Define Installments  |  -                             | Due dates, percentages   | Installment details         | fee_installments
| Define Fine Rules    |  -                             | Fine tiers               | Rule parameters             | fee_fine_rules

### Fee Assignment				
|Fetch Students        |std_students, std_student_academic_sessions|Student ID, Current Class	-	Used for filtering
|Auto-assign Fee       |fee_structure_master|Fee structure for class	-	fee_student_assignments
|Apply Concession      |std_student_guardian_jnt (for sibling check)|Student, Guardian	Concession type, approval	fee_student_concessions

### Payment Collection				
|View Outstanding      |fee_invoices|Invoice data	-	Display only
|Process Payment       |-	Payment details	Amount, mode, reference	fee_transactions, fee_transaction_details
|Generate Receipt      |fee_transactions|Transaction data	-	fee_receipts

### Fine Management				
|Calculate Fine        |fee_invoices, fee_fine_rules|Due dates, rules	-	fee_fine_transactions
|Waive Fine            |-	-	Waiver reason	fee_fine_transactions (update)
|Name Removal          |fee_invoices, std_student_academic_sessions|Overdue data	-	fee_name_removal_log
