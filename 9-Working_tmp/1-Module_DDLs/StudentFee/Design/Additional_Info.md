# Additional Information for Developers
---------------------------------------

1. Integration Points with Existing Modules
| Module	            | Integration Type	| Purpose
|-----------------------|-------------------|--------------------------------------------------------------------------------
| Student Module	    | Foreign Key	    | `std_students`.`id` → `fee_student_assignments`.`student_id`
| Academic Module	    | Foreign Key	    | `sch_org_academic_sessions_jnt`.`id` → `fee_structure_master`.`academic_session_id`
|                       |                   | `sch_classes`.`id` → `fee_structure_master`.`class_id`
|                       |                   | `sch_class_section_jnt`.`id` → For class-section validation
| User Module	        | Foreign Key	    | `sys_users`.`id` → All created_by, collected_by, approved_by fields
| Lookup Module	        | Foreign Key	    | `sys_dropdown_table`.`id` → Various category/lookup fields
| Transport Module	    | Data Fetch	    | Transport fee calculation based on route/distance
| Hostel Module	        | Data Fetch	    | Hostel & mess charges based on room type, occupancy

## 2. Cron Jobs / Scheduled Tasks
```php
// Laravel Scheduler Commands
// app/Console/Kernel.php

protected function schedule(Schedule $schedule)
{
    // Daily at 12:01 AM: Generate invoices for upcoming installments (7 days ahead)
    $schedule->command('fee:generate-invoices')->dailyAt('00:01');
    
    // Daily at 12:30 AM: Check due dates and apply fines
    $schedule->command('fee:apply-fines')->dailyAt('00:30');
    
    // Daily at 1:00 AM: Send due reminders (7 days, 3 days, 1 day before)
    $schedule->command('fee:send-reminders')->dailyAt('01:00');
    
    // Daily at 2:00 AM: Check for name removal condition (60+ days overdue)
    $schedule->command('fee:check-name-removal')->dailyAt('02:00');
    
    // Weekly on Monday: Generate default risk prediction report
    $schedule->command('fee:predict-default-risk')->weeklyOn(1, '03:00');
    
    // Monthly on 1st: Generate concession utilization report
    $schedule->command('fee:concession-report')->monthlyOn(1, '04:00');
}
```

## 3. Key Business Logic Rules
```php
// Fine Calculation Logic
function calculateFine($dueDate, $amount, $rules) {
    $daysLate = now()->diffInDays($dueDate);
    $fineAmount = 0;
    
    foreach ($rules as $rule) {
        if ($daysLate >= $rule->from_day && $daysLate <= $rule->to_day) {
            if ($rule->fine_type == 'Percentage') {
                $fineAmount = ($amount * $rule->fine_value / 100);
            } elseif ($rule->fine_type == 'Fixed') {
                $fineAmount = $rule->fine_value;
            } elseif ($rule->fine_type == 'Percentage+Capped') {
                $fineAmount = min(
                    ($amount * $rule->fine_value / 100),
                    $rule->max_fine_amount
                );
            }
            
            // Apply action if needed
            if ($daysLate == $rule->to_day && $rule->action_on_expiry) {
                triggerAction($rule->action_on_expiry, $student);
            }
            
            break;
        }
    }
    
    return $fineAmount;
}

// Sibling Concession Detection
function detectSiblingConcession($studentId) {
    $student = std_students::find($studentId);
    $guardians = $student->guardians;
    
    foreach ($guardians as $guardian) {
        $siblings = $guardian->students()
            ->where('id', '!=', $studentId)
            ->whereHas('currentSession', function($q) {
                $q->where('is_current', 1);
            })
            ->count();
            
        if ($siblings >= 1) { // At least 1 sibling in school
            return true;
        }
    }
    
    return false;
}

```

4. API Endpoints Needed

| Endpoint                              | Method	| Purpose
|---------------------------------------|-----------|---------------------------
| /api/fee/heads	                    | GET/POST	| Fee head CRUD
| /api/fee/groups	                    | GET/POST	| Fee group management
| /api/fee/structures	                | GET/POST	| Fee structure definition
| /api/fee/assign/{studentId}	        | POST	    | Assign fee to student
| /api/fee/bulk-assign	                | POST	    | Bulk fee assignment
| /api/fee/outstanding/{studentId}	    | GET	    | Get outstanding fees
| /api/fee/invoices/{studentId}	        | GET	    | List student invoices
| /api/fee/payment/process	            | POST	    | Process payment
| /api/fee/receipt/{receiptNo}	        | GET	    | Get receipt details
| /api/fee/fines/calculate	            | POST	    | Calculate fines
| /api/fee/reports/{type}	            | GET	    | Generate reports
| /api/fee/scholarships	                | GET/POST	| Scholarship management
| /api/fee/scholarships/apply	        | POST	    | Apply for scholarship


5. Important Considerations
  - Multi-tenancy: All tables are per-tenant (separate DB), so no org_id needed
  - Soft Deletes: Use deleted_at for all master tables
  - Audit Trail: All financial transactions must be immutable (use logs)
  - Concurrency: Use database transactions for payment processing
  - Performance: Index all foreign keys and frequently queried columns
  - Security:
    - Role-based access (Cashier, Accountant, Admin, Principal)
    - Encrypt sensitive payment data
    - PCI compliance for payment gateway integration
    - Reporting: Pre-aggregate summary tables for faster reporting

