# Transport Module - Testing & QA Design (v2)

**Focus:** Validation of Boarding Logic, Device Security, and Notifications.

---

## 1. Test Scenarios (Functional)

### Feature: Student Boarding (Mobile App)

| TC ID | Scenario | Pre-Requisites | Steps | Expected Result |
|---|---|---|---|---|
| **TPT-001** | Student Boards Correct Bus | Trip Started | 1. Open Scanner <br> 2. Scan valid Student QR | App shows Green Tick. Record created in `tpt_student_boarding_log` with event `BOARD`. |
| **TPT-002** | Student Boards Wrong Bus | Trip Started | 1. Open Scanner <br> 2. Scan QR of student not allocated to this route | App shows "Wrong Bus" Alert. Log created with error flag (if supported) or audit log. |
| **TPT-003** | Student Unboards | Trip Active | 1. Select 'Unboard Mode' <br> 2. Scan Student QR | App shows "Unboarded". Record created in log with event `UNBOARD`. |
| **TPT-004** | Duplicate Scan | Already Scanned | 1. Scan same QR again | App shows "Already Boarded" Warning. No duplicate entry in DB. |

### Feature: Device Security

| TC ID | Scenario | Pre-Requisites | Steps | Expected Result |
|---|---|---|---|---|
| **TPT-005** | Login from Unauthorized Device | App Installed | 1. Enter valid User/Pass on new phone | System blocks login. Error: "Device Not Authorized". |
| **TPT-006** | Admin Approves Device | TPT-005 done | 1. Admin goes to Device Settings <br> 2. Approves pending device | Device status becomes Active. |
| **TPT-007** | Login after Approval | TPT-006 done | 1. Retry Login on new phone | Login Successful. |

---

## 2. API Testing (Backend)

### Endpoint: `/api/transport/log-boarding`

**Request Payload:**
```json
{
  "trip_id": 1025,
  "student_qr": "ST-2025-001",
  "event_type": "BOARD",
  "latitude": 12.9716,
  "longitude": 77.5946,
  "timestamp": "2025-12-29 07:15:00",
  "device_uuid": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Validations:**
1.  Check `device_uuid` exists in `tpt_attendance_device` and `is_active=1`.
2.  Check `trip_id` is valid and `status='Ongoing'`.
3.  Check Student is allocated to this route (unless configured to allow ad-hoc).
4.  Verify `tpt_student_boarding_log` insertion.
5.  Verify Notification Trigger (check `tpt_notification_log`).

---

## 3. Performance Testing

*   **Load Test:** Simulate 50 buses scanning simultaneous students (approx 2000 requests/minute) during morning hours (7:00 AM - 8:00 AM).
*   **Latency Goal:** API response < 200ms for scans.

---
**End of QA Design**
