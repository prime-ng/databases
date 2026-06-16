# Employee Setup Module — Requirements Documentation
## Complete Professional Guide to Implementation

**Version:** 5.0 (Final - May 2026)  
**Status:** ✅ Ready for Development  
**Location:** `SchoolSetup/1-Sub-Modules/EmployeeSetup/Requirements/`

---

## 📚 Quick Navigation

### 🎯 Start Here
- **[SR-EM-00](./SR-EM-00-Master_Requirements.md)** — Module overview, scope, business rules
- **[SR-EM-INDEX](./SR-EM-INDEX-Complete_Roadmap.md)** — Complete roadmap and feature map

### 👥 Employee Management
- **[SR-EM-02](./SR-EM-02-Employee_Creation_Profile.md)** — Employee creation, profile management
- **[SR-EM-03](./SR-EM-03-Shift_Assignment.md)** — Shift configuration and employee shift assignment
- **[SR-EM-14](./SR-EM-14-Teacher_Profile.md)** *(To be created)* — Teacher-specific profile extension

### 📅 Attendance & Time Management
- **[SR-EM-04](./SR-EM-04-Attendance_Masters.md)** — Attendance types, holiday calendar, annual sessions
- **[SR-EM-09](./SR-EM-09-Holiday_Calendar.md)** *(Detailed version - To be created)* — Holiday master management
- **[SR-EM-12](./SR-EM-12-Employee_Attendance.md)** *(To be created)* — Daily attendance marking

### 🏖️ Leave Management System
- **[SR-EM-06](./SR-EM-06-Leave_Type_Configuration.md)** — Leave type master (CL, SL, EL, ML, PL, LWP)
- **[SR-EM-05](./SR-EM-05-Leave_Configuration.md)** — Role/department-based leave entitlements
- **[SR-EM-07](./SR-EM-07-Leave_Approval_Policies.md)** *(To be created)* — Multi-level approval workflows
- **[SR-EM-08](./SR-EM-08-Leave_Balances_Applications.md)** *(To be created)* — Leave applications and balance tracking
- **[SR-EM-13](./SR-EM-13-Leave_Management.md)** *(To be created)* — Leave management hub (employee & approver views)

### 📈 Employee Lifecycle & Reporting
- **[SR-EM-10](./SR-EM-10-Employee_Lifecycle.md)** *(To be created)* — Transfer, promotion, separation
- **[SR-EM-11](./SR-EM-11-Employee_Reports.md)** *(To be created)* — Reports and analytics

---

## 📋 What's in Each Document?

Every requirement document includes:

### 1. **Screen Overview**
   - Purpose and business objective
   - Key capabilities
   - User roles and permissions

### 2. **Data Model & DDL**
   - Primary table structure
   - Related table references
   - Foreign key relationships

### 3. **UI/UX Design**
   - Screen layouts (ASCII wireframes)
   - Form designs
   - Navigation tabs
   - Field descriptions

### 4. **Input Validation Rules**
   - Per-field validations
   - Cross-field dependencies
   - Error messages and handling

### 5. **Business Logic & Calculations**
   - Automated calculations
   - Default values
   - State transitions
   - Workflows

### 6. **Database Operations**
   - SQL examples for CRUD operations
   - Complex queries
   - Batch operations

### 7. **API Endpoints**
   - RESTful endpoint specifications
   - Request/response structures
   - Error codes

### 8. **Authorization & Permissions**
   - Role-based access control
   - Field-level permissions
   - Permission matrix

### 9. **Error Handling**
   - Common error scenarios
   - Error codes and messages
   - User-friendly guidance

### 10. **Testing Checklist**
   - Unit test scenarios
   - Integration test points
   - Performance testing

---

## 🎬 Getting Started

### For Product Managers
1. Read [SR-EM-00](./SR-EM-00-Master_Requirements.md) for module overview
2. Review [SR-EM-INDEX](./SR-EM-INDEX-Complete_Roadmap.md) for complete feature map
3. Reference individual screen documents for detailed functionality

### For Developers
1. Start with [SR-EM-INDEX](./SR-EM-INDEX-Complete_Roadmap.md) roadmap
2. Review DDL reference: `Employee_setup_ddl_v5.sql`
3. Follow implementation phases in priority order (P0 → P1 → P2)
4. Refer to specific screen document during development

### For QA/Testing
1. Review [SR-EM-INDEX](./SR-EM-INDEX-Complete_Roadmap.md) workflows
2. Extract testing checklists from each screen document
3. Create test cases for validations and business rules
4. Test cross-module integrations

### For DBAs
1. Review [SR-EM-00](./SR-EM-00-Master_Requirements.md) Section 2 (Database Schema Overview)
2. Execute `Employee_setup_ddl_v5.sql` in tenant database
3. Create indexes from performance section of each document
4. Configure backup and recovery procedures

---

## 📊 Implementation Phases

### ✅ Phase 1: Foundation (P0 — Weeks 1-2)
Essential features for core operations:
- Employee creation & profile management
- Shift assignment
- Attendance type configuration
- Leave type master
- Leave policy configuration
- Daily attendance marking
- Basic leave applications and balance tracking

### ⏳ Phase 2: Workflows (P1 — Weeks 3-4)
Enhanced capabilities and automation:
- Multi-level leave approval workflows
- Leave management hub (full workflow)
- Holiday calendar management
- Teacher profile extension
- Email notifications and reminders

### 📅 Phase 3: Advanced (P2 — Weeks 5-6)
Analytics, reporting, and employee lifecycle:
- Employee transfer and promotion
- Separation and exit management
- Comprehensive reporting and analytics
- Payroll integration
- Bulk operations

---

## 🔑 Key Concepts

### Leave Balance Calculation
```
Balance = Opening + Accrued - Consumed - Encashed - CarriedForward
Accrual = Annual_Entitlement (by method: Lump_Sum, Monthly, Quarterly)
```

### Policy Matching (Most-Specific Wins)
```
Match Priority: 
1. Role + Department + Designation + Employment Type (Specific)
2. Role + Department + Designation (Less Specific)
3. Role + Department (Even Less)
4. Role Only (Generic)
5. All (Catch-all Default)

Lower priority number = Higher priority in application
```

### Approval Workflow
```
Level 1 (Manager) → Level 2 (HR) → Level 3 (Principal)
                ↓ (if not approved within N hours)
            AUTO-ESCALATION
                ↓
Approval Mode: ANY_ONE or ALL (unanimous required)
```

### Attendance to Payroll Impact
```
Attendance Type → Payroll Percentage → Salary Impact
Present (100%) → Full day pay
Half-Day (50%) → Half day pay
Absent (0%) → No pay
Holiday (100%) → Full pay (if is_paid=true)
```

---

## 📁 File Structure

```
Requirements/
├── README.md (this file)
├── SR-EM-00-Master_Requirements.md
├── SR-EM-INDEX-Complete_Roadmap.md
│
├── [Completed Documents]
├── SR-EM-02-Employee_Creation_Profile.md
├── SR-EM-03-Shift_Assignment.md
├── SR-EM-04-Attendance_Masters.md
├── SR-EM-05-Leave_Configuration.md
├── SR-EM-06-Leave_Type_Configuration.md
│
├── [To Be Created - SR-EM-07 onwards]
├── SR-EM-07-Leave_Approval_Policies.md
├── SR-EM-08-Leave_Balances_Applications.md
├── SR-EM-09-Holiday_Calendar.md
├── SR-EM-10-Employee_Lifecycle.md
├── SR-EM-11-Employee_Reports.md
├── SR-EM-12-Employee_Attendance.md
├── SR-EM-13-Leave_Management.md
├── SR-EM-14-Teacher_Profile.md
│
└── [Supporting Documents in Parent Directory]
    ├── Employee_setup_ddl_v5.sql
    ├── DataDictionary_EmpSetup.md
    ├── Leave_Management_Flow_Guide.md
    └── Leave_Management_Test_Cases.md
```

---

## 🔗 Cross-Module Dependencies

### EmployeeSetup Depends On:
- **SystemConfig** — User accounts, roles, permissions, dropdowns
- **GlobalMaster** — Countries, states, cities, languages
- **SchoolSetup (Core)** — Organizations, academic sessions, classes, departments

### Other Modules Depend On EmployeeSetup:
- **SmartTimetable** — Teacher assignment, shift validation
- **Transport** — Staff vehicle assignments
- **LmsExam** — Teacher assignments, paper setters
- **Payroll** — Attendance, leaves for salary calculation
- **StudentProfile** — Class teacher assignments

---

## 💾 Database Schema Version

- **Current Version:** 5.0 (Employee_setup_ddl_v5.sql)
- **Table Prefix:** `sch_*` (SchoolSetup module)
- **Tenant Scope:** Database-per-tenant (multi-tenancy via stancl/tenancy)
- **Soft Deletes:** All tables include `deleted_at` field

---

## 🎓 Best Practices & Standards

### Code Style
- Use `declare(strict_types=1);` in all PHP files
- Follow Laravel naming conventions
- Use form requests for validation (not controller)
- Implement authorization checks in every action

### Database
- Always include indexes on foreign keys and frequently queried columns
- Use generated columns where applicable (e.g., `active_flag`)
- Implement proper cascade rules for delete operations
- Add meaningful comments to complex tables

### API Design
- RESTful endpoints with proper HTTP methods
- Pagination for list endpoints (25-50 items per page)
- Consistent error response format
- Proper HTTP status codes (200, 201, 400, 404, 422, 500)

### Testing
- Unit tests for business logic calculations
- Feature tests for API endpoints
- Test authorization at every endpoint
- Use database seeders for consistent test data

---

## ❓ Common Questions

**Q: Can I modify an employee's department?**  
A: Yes, but this should trigger a transfer event (SR-EM-10) to maintain career history.

**Q: What happens when leave type is marked as system type?**  
A: System types cannot be deleted by users and are considered built-in (e.g., CL, SL, EL).

**Q: How are holidays excluded from leave day count?**  
A: Working day calculation in Leave Module queries the holiday calendar and skips those dates.

**Q: Can policies be applied retroactively?**  
A: No, policy changes apply to future accruals only. Past balances remain unchanged.

**Q: What if employee has no matching policy?**  
A: System falls back to leave type defaults (from sch_staff_leave_types).

**Q: Can approval workflows be customized per leave type?**  
A: Yes, policies (SR-EM-07) support role/leave-type specific workflows.

---

## 📞 Support & Documentation References

### DDL & Schema References
- **Master DDL:** `Employee_setup_ddl_v5.sql`
- **Data Dictionary:** `DataDictionary_EmpSetup.md`
- **Leave Flow Guide:** `Leave_Management_Flow_Guide.md`
- **Test Cases:** `Leave_Management_Test_Cases.md`

### Architecture & Standards
- **AGENTS.md** — Development standards and module registry
- **CLAUDE.md** — Project overview and tech stack
- **Rules:** `.claude/rules/` — Coding rules and patterns

---

## ✅ Quality Checklist

Before marking a screen as "done":

- [ ] All validations implemented per requirements
- [ ] Business logic calculations verified
- [ ] Database transactions atomic (DB::transaction wrappers)
- [ ] Authorization checks at every endpoint
- [ ] Error handling with meaningful messages
- [ ] Soft deletes implemented (delete → soft delete)
- [ ] Audit trail (created_by, updated_by, timestamps)
- [ ] Pagination for list views (if > 25 items)
- [ ] API documentation complete
- [ ] Unit & feature tests written
- [ ] Performance tested (indexes, N+1 queries)
- [ ] Cross-module integration tested
- [ ] Notifications triggered where applicable

---

## 📈 Metrics & Monitoring

### Key Performance Indicators
- **Attendance Accuracy:** % of marked attendance vs expected
- **Leave Processing Time:** Avg hours from application to approval
- **Balance Accuracy:** % of correct balance calculations
- **System Uptime:** 99.5% availability target
- **User Adoption:** % of staff using self-service features

### Monitoring Points
- Approval bottlenecks (pending for > 7 days)
- Leave balance discrepancies
- Attendance marking gaps (> 2 days delay)
- Policy matching errors (catch-all fallbacks)

---

## 🚀 Next Steps

1. **Review Documentation:** Read SR-EM-00 and SR-EM-INDEX
2. **Planning Meeting:** Align with team on P0 features and timeline
3. **Database Setup:** Execute Employee_setup_ddl_v5.sql in development
4. **Development:** Start with SR-EM-02 (Employee Creation)
5. **Testing:** Create test cases from each screen document
6. **Deployment:** Follow phased rollout (P0 → P1 → P2)

---

## 📝 Document Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Jan 2026 | Initial schema |
| 2.0 | Feb 2026 | Leave management enhancement |
| 3.0 | Mar 2026 | Approval workflows added |
| 4.0 | Apr 2026 | Comprehensive review |
| **5.0** | **May 2026** | **Final version with complete requirements** |

---

**Last Updated:** May 16, 2026  
**Status:** ✅ Ready for Development  
**Author:** DB Architect & Development Team

---

## 📞 Questions or Clarifications?

Refer to the specific screen document or consult:
- **Project Lead:** Review CLAUDE.md and AGENTS.md
- **Database:** Check DDL file and Data Dictionary
- **Business Rules:** Review SR-EM-INDEX workflows
- **Implementation:** Follow standards in respective screen document

---

**Happy Coding! 🎉**

