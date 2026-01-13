# Transport Module - Design Document (v2)

**Document Version:** 2.0
**Module:** Transport Management System

## 1. Executive Summary

The Transport Management System (v2) is a comprehensive module designed to manage the entire lifecycle of school transport operations. It handles vehicle inventory, route planning, student allocation, fee collection, daily trip execution, real-time tracking, and safety compliance.

v2 introduces enhanced safety features including **Student Boarding/Unboarding Tracking**, **Device Management for Drivers**, and a centralized **Notification Log** for parent communication.

## 2. System Architecture

The module is built on a **Laravel + MySQL** architecture with a Multi-Tenant database strategy.

### 2.1 Logical Layers
1.  **Master Layer**: Vehicles, Personnel, Shifts.
2.  **Planning Layer**: Routes, Stops, Schedules.
3.  **Operational Layer**: Trips, Incidents, Boarding Logs.
4.  **Finance Layer**: Fees, Fines, Collections.
5.  **Audit Layer**: Activity Logs, Vehicle Maintenance.

### 2.2 Integration Points
*   **Student Module (`std_students`)**: For linking transport allocation.
*   **User Module (`sys_users`)**: For authentication of drivers and managers.
*   **Media Module (`sys_media`)**: For storing vehicle documents and personnel IDs.
*   **Global DB (`sys_dropdown_table`)**: For standardized reference data (Vehicle Types, Fuel Types).
*   **Notification Service**: Integration with SMS/FCM/Email gateways (logged in `tpt_notification_log`).

## 3. Key Functional Modules

### 3.1 Fleet Management
*   Vehicle detailed profiling (Insurance, Fitness, Pollution).
*   Document upload integration (`is_uploaded` flags).
*   Ownership tracking (Owned vs Leased).

### 3.2 Route Planning
*   Supports Pickup, Drop, or Round-trip configurations.
*   Spatial data support (`LINESTRING` for routes, `POINT` for stops) for map visualization.
*   Dynamic stop ordering (`ordinal`).

### 3.3 Daily Operations
*   **Trip Management**: Scheduling and execution of trips.
*   **Boarding/Unboarding**: Mobile-app based scanning (QR/RFID) creates entries in `tpt_student_boarding_log` with `event_type`.
*   **Incidents**: Reporting of breakdowns, delays, or behavioral issues.

### 3.4 Safety & Compliance
*   **Device Binding**: Drivers must use registered devices (`tpt_attendance_device`) identified by UUID.
*   **Real-time Alerts**: System logs all safety alerts in `tpt_notification_log`.
*   **Maintenance**: Workflow for vehicle inspection, service request, and approval.

## 4. Security & Permissions

*   **Role-Based Access**:
    *   **Transport Admin**: Full Access.
    *   **Driver/Helper**: Limited App Access (Trips, Boarding).
    *   **Parent**: Read-only (Child Location, Notifications).
*   **Device Security**: Drivers cannot login from unauthorized devices (enforced via `device_uuid` unique constraint).

## 5. Technical Specifications

*   **Database Engine**: InnoDB (MySQL 8.x)
*   **Charset**: utf8mb4_unicode_ci
*   **Geo-Spatial**: Uses MySQL Spatial Types (`POINT`, `LINESTRING`, `SPATIAL INDEX`).
*   **Timezone**: UTC stored, Localized presentation.

## 6. Future Roadmap (v3)
*   Live GPS Hardware Integration (TCP/IP Listener).
*   AI-based Route Optimization.
*   Predictive Maintenance Analytics.

---
**End of Design Document**
