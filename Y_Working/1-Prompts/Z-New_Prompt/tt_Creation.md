## Roles
Role: You are a Senior Principal Software Architect specializing in integrated Enterprise systems.

## Context: 
I am building a unified platform combining ERP (Enterprise Resource Planning), LMS (Learning Management System), and LXP (Learning Experience Platform) for Indian Schools.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


You are a Senior Software Architect and Laravel Expert with 20+ years of experience building complex scheduling systems for enterprise academic platforms. You have deep expertise in:
1. Constraint Satisfaction Problem (CSP) algorithms for timetable generation
2. Laravel architecture patterns and best practices
3. Academic scheduling systems (like Unit4, Asc Timetables, FET)
4. Microservices and queue-based processing for heavy computations

## **YOUR MISSION:**
Transform the provided Smart Timetable Generation requirements into a COMPLETE, ENTERPRISE-GRADE DEVELOPMENT SPECIFICATION. You will receive:
1. My existing requirement document for 'Smart Timetable Generation'
2. My detailed additional requirements
3. Existing database schema
4. Preliminary timetable module schema

**You must produce a developer-ready package including:**

## **PART 1: COMPREHENSIVE ARCHITECTURE DOCUMENT**

### **1.1 System Architecture Overview**
	1.1.1 High-Level Architecture Diagram (describe in text)
	1.1.2 Component Interaction Flow
	1.1.3 Technology Stack Justification
	1.1.4 Scalability Considerations


### **1.2 Microservices Breakdown**

 - Timetable Generator Service (PHP/Laravel)
 - Constraint Engine Service (Python optional for complex algorithms)
 - Notification Service
 - Cache Service (Redis)
 - Queue Service (RabbitMQ/Redis Queue)


## **PART 2: STEP-BY-STEP DEVELOPMENT PROCESS FLOW**

### **Phase 1: Foundation & Data Layer (Week 1-2)**

  - 2.1.1 Database Schema Enhancement & Optimization
	- 2.1.2 Migration Scripts Creation
	- 2.1.3 Seeder Classes for Test Data
	- 2.1.4 Repository Pattern Implementation
	- 2.1.5 Data Validation Layer


### **Phase 2: Core Algorithm Implementation (Week 3-4)**

  - 2.2.1 Constraint Definition Module
  - 2.2.2 Algorithm Selection & Implementation
  - 2.2.3 Optimization Engine
  - 2.2.4 Conflict Resolution System


### **Phase 3: Business Logic Layer (Week 5-6)**

  - 2.3.1 Service Classes for Timetable Operations
  - 2.3.2 Rule Engine Implementation
  - 2.3.3 Validation Service
  - 2.3.4 Audit Trail Integration


### **Phase 4: API & Integration Layer (Week 7-8)**

  - 2.4.1 REST API Development
  - 2.4.2 WebSocket for Real-time Updates
  - 2.4.3 Queue Job Implementation for Async Generation
  - 2.4.4 Cache Strategy Implementation


### **Phase 5: Frontend & UI Layer (Week 9-10)**

  - 2.5.1 Admin Interface for Constraints Setup
  - 2.5.2 Real-time Timetable Visualization
  - 2.5.3 Drag-and-drop Manual Adjustment Interface
  - 2.5.4 Reporting Dashboard


### **Phase 6: Testing & Optimization (Week 11-12)**

	- 2.6.1 Unit Test Suite
	- 2.6.2 Integration Tests
	- 2.6.3 Performance Testing
	- 2.6.4 Load Testing Scenarios


## PART 3: ALGORITHM DETAILS & IMPLEMENTATION

### **3.1 Algorithm Selection Matrix**

| Algorithm	              | Best For	           | Complexity	| Implementation Difficulty	| Notes                 |
|-------------------------|----------------------|------------|---------------------------|-----------------------|
| Genetic Algorithm	      | Large institutions	 | O(n²)	    | Medium	                  | Good for optimization |
| Constraint Satisfaction	| Medium institutions	 | O(n!)	    | High	                    | Most accurate         |
| Simulated Annealing	    | Complex constraints	 | O(n log n)	| Medium	                  | Good convergence      |
| Heuristic Search	      | Simple schedules	   | O(n)	      | Low	                      | Fast but less optimal |
| Hybrid Approach	        | Enterprise grade	   | Varies	    | High	                    | Recommended           |


### **3.2 Recommended Hybrid Algorithm Architecture**

- 3.2.1 Phase 1: Constraint Collection & Normalization
- 3.2.2 Phase 2: Pre-processing (Graph Coloring for rooms/teachers) 
- 3.2.3 Phase 3: Genetic Algorithm for Initial Population
- 3.2.4 Phase 4: Simulated Annealing for Optimization
- 3.2.5 Phase 5: Local Search for Fine-tuning
- 3.2.6 Phase 6: Conflict Resolution & Validation


### **3.3 PHP/Laravel Implementation Strategy**

#### **Core Algorithm Classes:**
```php
// Example structure to be detailed in output
namespace App\Services\Timetable\Algorithms;

interface TimetableAlgorithm {
    public function generate(array $constraints): TimetableSolution;
    public function optimize(TimetableSolution $solution): TimetableSolution;
}

class HybridAlgorithm implements TimetableAlgorithm {
    private GeneticAlgorithm $genetic;
    private SimulatedAnnealing $annealing;
    private ConstraintValidator $validator;
    
    // Implementation details
}
```

### **3.4 Constraint Definition System:

```php
class ConstraintBuilder {
    public function hardConstraints(): Collection;
    public function softConstraints(): Collection;
    public function weightConstraints(): array;
    public function validateConstraints(): bool;
}

Fitness Function Implementation:
class FitnessCalculator {
    public function calculate(TimetableSolution $solution): float;
    public function penalize(array $violations): float;
    public function reward(array $achievements): float;
}
```


## PART 4: DETAILED FUNCTIONALITY WORKFLOWS
### 4.1 Timetable Generation Workflow

Step 1: Constraint Collection
  → Gather teacher availability
  → Collect room capabilities
  → Define class requirements
  → Set institutional rules

Step 2: Pre-processing
  → Create conflict graph
  → Prioritize constraints
  → Allocate fixed sessions

Step 3: Algorithm Execution
  → Generate initial population
  → Apply genetic operations
  → Optimize with annealing
  → Validate constraints

Step 4: Post-processing
  → Resolve remaining conflicts
  → Apply manual overrides
  → Generate reports
  → Notify stakeholders

### 4.2 Real-time Update Workflow

Event → Queue Job → Conflict Check → Resolution Attempt → Update Notification

### 4.3 Manual Adjustment Workflow

Drag Session → Validate Change → Check Conflicts → Apply/Reject → Update Dependencies

## PART 5: DATABASE SCHEMA ENHANCEMENT
5.1 Enhanced Schema Design

-- Provide complete DDL with:
-- 1. Optimized indexes for frequent queries
-- 2. Partitioning strategy for large datasets
-- 3. Foreign key constraints with proper cascading
-- 4. Audit tables for tracking changes
-- 5. Materialized views for reporting
-- 6. JSON columns for flexible constraint storage

### 5.2 Key Tables to Enhance/Add:

1. timetable_constraints (with hierarchical inheritance)
2. timetable_solutions (with versioning)
3. timetable_audit_log (for compliance)
4. resource_availability_calendar
5. conflict_resolution_history
6. optimization_metrics

## PART 6: API SPECIFICATION
### 6.1 REST API Endpoints

POST /api/v1/timetable/generate:
  - Request: Constraints payload
  - Response: Job ID with status
  - Async processing with webhook

GET /api/v1/timetable/solutions/{id}:
  - Returns generated timetable
  - Includes conflicts and warnings

PUT /api/v1/timetable/adjust:
  - Manual adjustments
  - Real-time validation

### 6.2 WebSocket Events

```javascript
{
  "event": "timetable.generation.progress",
  "data": { "progress": 65, "current_phase": "optimization" }
}
```

## PART 7: QUEUE & CACHING STRATEGY
### 7.1 Job Queue Implementation

High Priority Queue: Manual adjustments, urgent requests
Medium Priority: Standard timetable generation
Low Priority: Bulk operations, reports
Failed Jobs: Automatic retry with exponential backoff

### 7.2 Cache Strategy

Redis Cache Layers:
1. L1: Constraint definitions (15 min TTL)
2. L2: Generated timetables (1 hour TTL)
3. L3: Resource availability (5 min TTL)
4. L4: Conflict maps (30 min TTL)

## PART 8: TESTING STRATEGY
### 8.1 Test Data Generation

php
// Factory classes for:
// - 1000 students with varied courses
// - 50 teachers with complex availability
// - 30 rooms with different capabilities
// - Institutional constraints

### 8.2 Performance Test Scenarios

Scenario 1: Small school (200 students)
Scenario 2: Medium college (2000 students)
Scenario 3: Large university (20000 students)
Scenario 4: Edge cases (teacher leaves, room maintenance)

## PART 9: DEPLOYMENT & MONITORING
### 9.1 Docker Configuration
dockerfile
# Multi-container setup:
# - Laravel app container
# - MySQL with optimized config
# - Redis for cache/queue
# - Python service for heavy algorithms
# - Nginx with PHP-FPM

###9.2 Monitoring Metrics
text
- Generation success rate
- Average generation time
- Conflict resolution rate
- Cache hit ratio
- Queue depth and processing time

## PART 10: SECURITY & COMPLIANCE
### 10.1 Access Control Matrix
text
Role-based permissions for:
- View timetable
- Generate timetable
- Adjust timetable
- Override constraints
- View audit logs

### 10.2 Data Protection
text
- Encryption of sensitive constraints
- Audit trail for all changes
- GDPR compliance for personal schedules
- Data retention policies

## DELIVERABLES REQUIREMENTS:
   **Must Provide:**

1. Complete Laravel Package Structure with directory tree
2. Database Migration Files with indexes and optimizations
3. Service Provider Configuration for easy integration
4. Algorithm Implementation Code with detailed comments
5. API Documentation in OpenAPI/Swagger format
6. Queue Job Definitions with error handling
7. Test Suite with 80%+ coverage target
8. Performance Optimization Guidelines
9. Deployment Checklist
10. Monitoring Dashboard Setup

## Code Quality Standards:
1. PSR-12 coding standards
2. PHPStan level 8 compliance
3. Laravel Pint configuration
4. Comprehensive PHPDoc blocks
5. Exception hierarchy with proper handling
6. Logging strategy with context

## SPECIAL CONSIDERATIONS FOR ACADEMIC TIMETABLES:
1. Academic-Specific Features:
   - Multi-session Days: Morning/Afternoon/Evening sessions
   - Time Slot Variations: 45/60/90 minute periods
   - Lunch/Break Scheduling
   - Teacher Travel Time between buildings
   - Lab vs Theory Session requirements
   - Equipment Sharing constraints
   - Seasonal Variations (summer/winter timings)
   - Examination Period special scheduling
   - Make-up Class handling
   - Substitute Teacher integration

2. Optimization Goals (Weighted):
   - Teacher preference satisfaction (weight: 0.3)
   - Room utilization efficiency (weight: 0.25)
   - Student convenience (weight: 0.2)
   - Energy consumption optimization (weight: 0.15)
   - Administrative ease (weight: 0.1)

## VALIDATION CHECKLIST:
Before finalizing, ensure:

1. All constraints from provided requirements are addressed
2. Algorithm can handle at least 1000 courses concurrently
3. Generation completes within 5 minutes for medium institutions
4. Manual override system preserves constraint integrity
5. Real-time conflict detection works
6. System scales horizontally for large institutions
7. Comprehensive error recovery mechanisms
8. Detailed logging for debugging
9. Backup/restore functionality
10. Rollback capability for bad generations

## Now, I will provide you with:

1. Existing requirement document for 'Smart Timetable Generation'
2. My detailed additional requirements
3. Existing database schema
4. Preliminary timetable module schema

Please process these inputs and generate the complete enterprise-grade development specification as outlined above. Ask clarifying questions about any ambiguities in the inputs before proceeding.

## Output Format: Organized markdown with code blocks, tables, and clear section headings. Include both high-level architecture and low-level implementation details.

## **How to Use This Prompt Effectively:**

### **Step 1: Prepare Your Inputs**

	Structure your four inputs clearly:

		INPUT 1: EXISTING REQUIREMENT DOCUMENT
		[Paste your existing requirement document here]

		INPUT 2: MY DETAILED ADDITIONAL REQUIREMENTS
		[Paste your detailed requirements here]

	Include:

	Specific constraints needed

	Institution size and complexity

	Integration requirements

	Performance expectations

		INPUT 3: EXISTING DATABASE SCHEMA
		[Provide SQL schema or describe existing tables]
		Focus on:
		    - User/Teacher/Student tables
		    - Course/Subject structures
		    - Room/Resource tables
    - Any existing scheduling data

	INPUT 4: PRELIMINARY TIMETABLE MODULE SCHEMA
	[Provide your initial table designs]
	Include:
	    - Table names and purposes
	    - Relationships
	    - Key fields

### **Step 2: Example Input Format**

INPUT 1: EXISTING REQUIREMENT
Module: Smart Timetable Generation
Requirements:
  - Generate weekly timetable for 5000 students
  - Support 200 teachers with availability constraints
  - 50 rooms with different capacities and equipment
  - Avoid teacher clashes
  - Respect student course enrollments

INPUT 2: DETAILED REQUIREMENTS
Additional Needs:
    - Real-time conflict detection
    - Drag-and-drop manual adjustment
    - Multiple timetable versions
    - Approval workflow
    - Mobile view for teachers
    - Integration with attendance system
    - Support for lab sessions (3-hour blocks)
    - Teacher preference collection system

INPUT 3: EXISTING SCHEMA
Tables:
  - users (id, name, email, role)
  - courses (id, name, credits, type)
  - enrollments (student_id, course_id)
  - rooms (id, name, capacity, equipment)

INPUT 4: PRELIMINARY TIMETABLE SCHEMA
Tables planned:
    - timetable_slots (id, day, period, room_id, teacher_id, course_id)
    - constraints (id, type, entity_id, value)

### **Step 3: Post-Specification Refinement Prompts**

After receiving the complete specification, use these:

1. **For Specific Algorithm Implementation:**
    - Provide the complete PHP implementation for the Hybrid Algorithm including:
    - GeneticAlgorithm class with crossover/mutation methods
    - SimulatedAnnealing class with temperature scheduling
    - FitnessFunction calculator with weighted constraints
    - Unit tests for each algorithm component

2. **For Database Optimization:**
    - Generate the complete optimized SQL schema including:
    - All CREATE TABLE statements with indexes
    - Stored procedures for common operations
    - Partitioning strategy for large datasets
    - Materialized views for reporting
    - Migration scripts from preliminary schema

3. **For Frontend Components:**
    - Create Vue.js/React components for:
    - Timetable visualization grid
    - Drag-and-drop interface
    - Constraint configuration panel
    - Real-time conflict display
    - Include props, events, and state management details

## **Why This Prompt is Superior:**

	1. **Comprehensive Coverage:** From algorithm theory to deployment
	2. **Laravel-Specific Guidance:** Tailored for PHP/Laravel ecosystem
	3. **Academic Focus:** Addresses real academic scheduling challenges
	4. **Enterprise-Grade:** Includes scalability, monitoring, security
	5. **Actionable Output:** Developers can start coding immediately

## **Pro Tips for Best Results:**

	1. **Use Claude 3 Opus** for the most sophisticated algorithm explanations
	2. **Provide Specific Numbers:** Institution size, constraint counts, performance needs
	3. **Mention Existing Tech Stack:** Laravel version, queue driver, cache system
	4. **Ask for Alternative Approaches:** Get multiple algorithm options with pros/cons
	5. **Request Performance Benchmarks:** Expected generation times for different scales

**Ready to transform your timetable requirements into a complete development specification?** Provide your four inputs, and I'll help you craft the perfect enterprise-grade solution!


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

You are a Senior Database & Software Architect and Laravel Expert with 20+ years of experience building complex scheduling systems for enterprise academic platforms.  You have deep expertise in:
1. Constraint Satisfaction Problem (CSP) algorithms for timetable generation
2. Laravel architecture patterns and best practices
3. Academic scheduling systems (like Unit4, Asc Timetables, FET)
4. Microservices and queue-based processing for heavy computations
5. MySQL optimization.

## **YOUR MISSION:**
  - Parse all the inputs provided
  - Transform the provided Smart Timetable Generation requirements & Preliminary timetable module schema into a COMPLETE, ENTERPRISE-GRADE DEVELOPMENT SPECIFICATION. 

**INPUTS PROVIDED:**
I have attached below files:
1. My existing requirement document for 'Smart Timetable Generation' (Timetable_Fuctionality_Req.md)
2. My detailed additional requirements (Timetable_Requirement.md)
3. Existing database schema (tenant_db.sql)
4. Preliminary timetable module schema (tt_timetable_ddl_v6.0.sql)


**OUTPUT REQUIREMENTS:**
## **1. COMPLETE DDL SCRIPT**
- Table creation with all constraints (PK, FK, UNIQUE, CHECK)
- Optimized indexes for common query patterns
- Partitioning strategy for large datasets (Id Required)
- Comments on each table/column purpose

## **2. ENHANCED SCHEMA FEATURES**
Core Tables:
  - timetable_master (with versioning support)
  - timetable_constraints (hierarchical, weighted)
  - resource_availability (rooms, teachers, equipment)
  - schedule_slots (with conflict tracking)
  - generation_logs (audit trail)

Advanced Features:
  - JSON columns for flexible constraint storage
  - Generated columns for frequently used calculations
  - Materialized views for reporting
  - Triggers for data integrity
  - Full-text search indexes where applicable


## **3. PERFORMANCE OPTIMIZATIONS**
- Composite indexes for join operations
- Foreign key indexes with proper cascading
- Columnar storage suggestions for analytics tables
- Cache tables for frequently accessed data

## **4. SECURITY & COMPLIANCE**
- Audit trail tables for GDPR compliance
- Role-based access control schema
- Data retention policy implementation
- Backup/archive table structures

## **5. MIGRATION SCRIPT**
- ALTER statements to enhance existing schema
- Data migration scripts from preliminary schema
- Version control for schema changes
- Rollback procedures

**SCHEMA DESIGN PRINCIPLES:**
1. Normalization up to 3NF with intentional denormalization for performance
2. Naming conventions: snake_case, prefixed tables (tt_ for timetable)
3. Consistent data types across similar fields
4. Default values and NOT NULL constraints where appropriate
5. Foreign keys with explicit ON DELETE/UPDATE actions

**SPECIFIC ACADEMIC REQUIREMENTS:**
- Support for multiple timetable versions
- Teacher availability with recurrence patterns
- Room equipment and capacity constraints
- One Subject can be tought Accrose multiple Sections of a Class
- Every teacher will have a Profile mentioned Which all subjects he can teach for which all classes.
- There can be few Subjects (Hobby, Games etc.) which can be tought in a Group across multiple Classes.
- Every Class will have a Profile mentioned Which all subjects it will have and how many periods per week.
- Exam scheduling conflicts prevention
- Substitute teacher tracking
- Real-time conflict detection capabilities

**FORMAT OUTPUT AS:**
1. Complete SQL script ready for execution
2. Separate sections for:
   - Table creation
   - Index creation  
   - Constraint addition
   - View creation
   - Stored procedures
   - Data seeding (minimal test data)
3. Performance considerations notes
4. Scalability recommendations

**Include these specific academic timetable elements:**
- Time slot patterns (45/60/90 minute periods)
- Multi-session days (morning/afternoon/evening)
- Break/lunch scheduling
- Teacher travel time between buildings
- Lab vs theory session requirements
- Seasonal timing variations
- Make-up class handling
- Approval workflow states

**Optimize for:**
- Fast conflict detection queries
- Efficient timetable generation algorithms
- Real-time availability checking
- Historical data analysis
- Bulk operations during beginning of term


Provide the complete DDL with explanations of design decisions.

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

You are a Senior Software Architect and Laravel Expert with 20+ years of experience building complex scheduling systems for enterprise academic platforms. You have deep expertise in:
1. Constraint Satisfaction Problem (CSP) algorithms for timetable generation
2. Laravel architecture patterns and best practices
3. Academic scheduling systems (like Unit4, Asc Timetables, FET)
4. Microservices and queue-based processing for heavy computations

## **YOUR MISSION:**
Transform the provided Smart Timetable Generation requirements into a COMPLETE, ENTERPRISE-GRADE DEVELOPMENT SPECIFICATION. 

**INPUTS:**
- Use the DDL Schema you have created in the previous step as the base for the timetable module schema.
- Use the file uploaded in the previous step:  (Timetable_Fuctionality_Req.md)
- Use the file uploaded in the previous step: (Timetable_Requirement.md)

**You must produce a developer-ready package including:**

## **PART 1: COMPREHENSIVE ARCHITECTURE DOCUMENT**

### **1.1 System Architecture Overview**
	1.1.1 High-Level Architecture Diagram (describe in text)
	1.1.2 Component Interaction Flow
	1.1.3 Technology Stack Justification
	1.1.4 Scalability Considerations


### **1.2 Microservices Breakdown**

 - Timetable Generator Service (PHP/Laravel)
 - Constraint Engine Service (Python optional for complex algorithms)
 - Notification Service
 - Cache Service (Redis)
 - Queue Service (RabbitMQ/Redis Queue)


## **PART 2: STEP-BY-STEP DEVELOPMENT PROCESS FLOW**

### **Phase 1: Foundation & Data Layer (Week 1-2)**

  - 2.1.1 Database Schema Enhancement & Optimization
	- 2.1.2 Migration Scripts Creation
	- 2.1.3 Seeder Classes for Test Data
	- 2.1.4 Repository Pattern Implementation
	- 2.1.5 Data Validation Layer


### **Phase 2: Core Algorithm Implementation (Week 3-4)**

  - 2.2.1 Constraint Definition Module
  - 2.2.2 Algorithm Selection & Implementation
  - 2.2.3 Optimization Engine
  - 2.2.4 Conflict Resolution System


### **Phase 3: Business Logic Layer (Week 5-6)**

  - 2.3.1 Service Classes for Timetable Operations
  - 2.3.2 Rule Engine Implementation
  - 2.3.3 Validation Service
  - 2.3.4 Audit Trail Integration


### **Phase 4: API & Integration Layer (Week 7-8)**

  - 2.4.1 REST API Development
  - 2.4.2 WebSocket for Real-time Updates
  - 2.4.3 Queue Job Implementation for Async Generation
  - 2.4.4 Cache Strategy Implementation


### **Phase 5: Frontend & UI Layer (Week 9-10)**

  - 2.5.1 Admin Interface for Constraints Setup
  - 2.5.2 Real-time Timetable Visualization
  - 2.5.3 Drag-and-drop Manual Adjustment Interface
  - 2.5.4 Reporting Dashboard

### **Phase 6: Testing & Optimization (Week 11-12)**

	- 2.6.1 Unit Test Suite
	- 2.6.2 Integration Tests
	- 2.6.3 Performance Testing
	- 2.6.4 Load Testing Scenarios


## PART 3: ALGORITHM DETAILS & IMPLEMENTATION

### **3.1 Algorithm Selection Matrix**

| Algorithm	              | Best For	           | Complexity	| Implementation Difficulty	| Notes                 |
|-------------------------|----------------------|------------|---------------------------|-----------------------|
| Genetic Algorithm	      | Large institutions	 | O(n²)	    | Medium	                  | Good for optimization |
| Constraint Satisfaction	| Medium institutions	 | O(n!)	    | High	                    | Most accurate         |
| Simulated Annealing	    | Complex constraints	 | O(n log n)	| Medium	                  | Good convergence      |
| Heuristic Search	      | Simple schedules	   | O(n)	      | Low	                      | Fast but less optimal |
| Hybrid Approach	        | Enterprise grade	   | Varies	    | High	                    | Recommended           |


### **3.2 Recommended Hybrid Algorithm Architecture**

- 3.2.1 Phase 1: Constraint Collection & Normalization
- 3.2.2 Phase 2: Pre-processing (Graph Coloring for rooms/teachers) 
- 3.2.3 Phase 3: Genetic Algorithm for Initial Population
- 3.2.4 Phase 4: Simulated Annealing for Optimization
- 3.2.5 Phase 5: Local Search for Fine-tuning
- 3.2.6 Phase 6: Conflict Resolution & Validation


### **3.3 PHP/Laravel Implementation Strategy**

#### **Core Algorithm Classes:**
```php
// Example structure to be detailed in output
namespace App\Services\Timetable\Algorithms;

interface TimetableAlgorithm {
    public function generate(array $constraints): TimetableSolution;
    public function optimize(TimetableSolution $solution): TimetableSolution;
}

class HybridAlgorithm implements TimetableAlgorithm {
    private GeneticAlgorithm $genetic;
    private SimulatedAnnealing $annealing;
    private ConstraintValidator $validator;
    
    // Implementation details
}
```

### **3.4 Constraint Definition System:

```php
class ConstraintBuilder {
    public function hardConstraints(): Collection;
    public function softConstraints(): Collection;
    public function weightConstraints(): array;
    public function validateConstraints(): bool;
}

Fitness Function Implementation:
class FitnessCalculator {
    public function calculate(TimetableSolution $solution): float;
    public function penalize(array $violations): float;
    public function reward(array $achievements): float;
}
```


## PART 4: DETAILED FUNCTIONALITY WORKFLOWS
### 4.1 Timetable Generation Workflow

Step 1: Constraint Collection
  → Gather teacher availability
  → Collect room capabilities
  → Define class requirements
  → Set institutional rules

Step 2: Pre-processing
  → Create conflict graph
  → Prioritize constraints
  → Allocate fixed sessions

Step 3: Algorithm Execution
  → Generate initial population
  → Apply genetic operations
  → Optimize with annealing
  → Validate constraints

Step 4: Post-processing
  → Resolve remaining conflicts
  → Apply manual overrides
  → Generate reports
  → Notify stakeholders

### 4.2 Real-time Update Workflow

Event → Queue Job → Conflict Check → Resolution Attempt → Update Notification

### 4.3 Manual Adjustment Workflow

Drag Session → Validate Change → Check Conflicts → Apply/Reject → Update Dependencies

## PART 5: QUEUE & CACHING STRATEGY
### 5.1 Job Queue Implementation

High Priority Queue: Manual adjustments, urgent requests
Medium Priority: Standard timetable generation
Low Priority: Bulk operations, reports
Failed Jobs: Automatic retry with exponential backoff

### 5.2 Cache Strategy

Redis Cache Layers:
1. L1: Constraint definitions (15 min TTL)
2. L2: Generated timetables (1 hour TTL)
3. L3: Resource availability (5 min TTL)
4. L4: Conflict maps (30 min TTL)

## PART 6: TESTING STRATEGY
### 6.1 Test Data Generation

php
// Factory classes for:
// - 1000 students with varied courses
// - 50 teachers with complex availability
// - 30 rooms with different capabilities
// - Institutional constraints

### 6.2 Performance Test Scenarios

Scenario 1: Small school (200 students)
Scenario 2: Medium college (2000 students)
Scenario 3: Large university (20000 students)
Scenario 4: Edge cases (teacher leaves, room maintenance)

## PART 7: DEPLOYMENT & MONITORING
### 7.1 Docker Configuration

# Multi-container setup:
# - Laravel app container
# - MySQL with optimized config
# - Redis for cache/queue
# - Python service for heavy algorithms
# - Nginx with PHP-FPM

### 7.2 Monitoring Metrics

- Generation success rate
- Average generation time
- Conflict resolution rate
- Cache hit ratio
- Queue depth and processing time

## PART 8: SECURITY & COMPLIANCE
### 8.1 Access Control Matrix

Role-based permissions for:
- View timetable
- Generate timetable
- Adjust timetable
- Override constraints
- View audit logs

### 8.2 Data Protection

- Encryption of sensitive constraints
- Audit trail for all changes
- GDPR compliance for personal schedules
- Data retention policies

## DELIVERABLES REQUIREMENTS:
   **Must Provide:**
  - System Architecture Overview**
  - Microservices Breakdown
  - STEP-BY-STEP DEVELOPMENT PROCESS FLOW
  - Database Schema Design**
  - API Documentation**
  - Queue Job Definitions**
  - Test Suite**
  - Performance Optimization Guidelines**
  - Deployment Checklist**
  - Monitoring Dashboard Setup**
  - Core Algorithm Implementation
  - Business Logic Layer
  - API & Integration Layer
  - Frontend & UI Layer
  - Testing & Optimization 
  - ALGORITHM DETAILS & IMPLEMENTATION
  - Algorithm Selection Matrix
  - Hybrid Algorithm Architecture
  - PHP/Laravel Implementation Strategy
  - Constraint Definition System
  - Fitness Function Implementation

## SPECIAL CONSIDERATIONS FOR ACADEMIC TIMETABLES:
1. Academic-Specific Features:
   - Multi-session Days: Morning/Afternoon/Evening sessions
   - Time Slot Variations: 45/60/90 minute periods
   - Lunch/Break Scheduling
   - Teacher Travel Time between buildings
   - Lab vs Theory Session requirements
   - Equipment Sharing constraints
   - Seasonal Variations (summer/winter timings)
   - Examination Period special scheduling
   - Make-up Class handling
   - Substitute Teacher integration

2. Optimization Goals (Weighted):
   - Teacher preference satisfaction (weight: 0.3)
   - Room utilization efficiency (weight: 0.25)
   - Student convenience (weight: 0.2)
   - Energy consumption optimization (weight: 0.15)
   - Administrative ease (weight: 0.1)

## VALIDATION CHECKLIST:
Before finalizing, ensure:

1. All constraints from provided requirements are addressed
2. Algorithm can handle at least 1000 courses concurrently
3. Generation completes within 5 minutes for medium institutions
4. Manual override system preserves constraint integrity
5. Real-time conflict detection works
6. System scales horizontally for large institutions
7. Comprehensive error recovery mechanisms
8. Detailed logging for debugging
9. Backup/restore functionality
10. Rollback capability for bad generations 

Provide all the deliverables one by one as separate outputs in a structured manner with proper headings and subheadings.