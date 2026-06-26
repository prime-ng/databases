# Services — Transport Tab Requirements

## 1. Functional Overview
Displays transport route allocations, driver and vehicle details, and boarding history.

---

## 2. Directory Layout & Parameters

### A. Allocated Route Details
- Displays assigned pickup and drop routes, shifts, pickup stop, and drop stop.

### B. Vehicle & Crew details
- Displays assigned vehicle registration number, helper name, driver name, and driver contact number.

### C. Boarding Logs Table
- Displays transport boarding logs of the last 30 days.
- **Columns**: Trip Date, Boarding Stop Time, Unboarding Stop Time, and Status (Boarded, Unboarded).

---

## 3. Database References
- **Models**:
  - `Modules\Transport\Models\TptStudentAllocationJnt`
  - `Modules\Transport\Models\DriverRouteVehicleJnt`
  - `Modules\Transport\Models\StudentBoardingLog`
- **Tables**:
  - `tpt_student_allocations_jnt`
  - `tpt_driver_route_vehicle_jnt`
  - `tpt_boarding_logs`
