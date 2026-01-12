# Complaint Module - ASCII UI Mockups

## 1. Parent/Student Submission Form (Mobile View)

```text
+------------------------------------------+
|  < Back        Submit Complaint          |
+------------------------------------------+
|  [ Category Select                 v ]   |
|   (o) Transport  ( ) Academic            |
|   ( ) Safety     ( ) Facility            |
+------------------------------------------+
|  IF TRANSPORT SELECTED:                  |
|  [ Select Student (e.g. Rahul)     v ]   |
|  [ Bus Route No (Route 12)         v ]   |
+------------------------------------------+
|  SEVERITY:                               |
|  [ Low ]  [ Medium ]  [ High ]  [ ! ]    |
+------------------------------------------+
|  TITLE:                                  |
|  [ Bus delayed by 1 hour everyday    ]   |
+------------------------------------------+
|  DESCRIPTION:                            |
|  [ For the last 3 days, the bus has... ] |
|  [                                     ] |
|  [                                     ] |
+------------------------------------------+
|  EVIDENCE:                               |
|  [ (+) Upload Photo/Video            ]   |
|  * IMG_2023.jpg [x]                      |
+------------------------------------------+
|  [x] Keep me Anonymous                   |
+------------------------------------------+
|          [ SUBMIT COMPLAINT ]            |
+------------------------------------------+
```

## 2. Principal/Management Admin Tracking Board (Web View)

```text
+----------------------------------------------------------------------------------+
| PRIME GURUKUL ERP | Complaints | Reports | Settings            [Admin User v]    |
+----------------------------------------------------------------------------------+
| DASHBOARD > TICKET BOARD                                                         |
|                                                                                  |
| [ Search Ticket ID/Name... ]  [ Filter: All Dates v ] [ Active SLA Only [x] ]    |
|                                                                                  |
| +------------------+  +------------------+  +------------------+  +------------+ |
| | OPEN (12)        |  | IN-PROGRESS (5)  |  | ESCALATED (3)    |  | RESOLVED   | |
| +------------------+  +------------------+  +------------------+  +------------+ |
| | #CMP-1002 [High] |  | #CMP-0998 [Med]  |  | #CMP-0045 [Crit] |  | #CMP-0888  | |
| | Transport: Rash  |  | Acad: Wrong Grd  |  | Safety: Bullying |  | Fac: Fan   | |
| | Driving          |  | Assign: Mr. A    |  | Assign: Principal|  | Repaired   | |
| | [Risk: 90%]      |  | Due: 2 hrs       |  | OVERDUE: 4 Hrs   |  | [Closed]   | |
| | > Assign   > View|  | > View           |  | > ACTION REQ     |  |            | |
| +------------------+  +------------------+  +------------------+  +------------+ |
| | #CMP-1004 [Low]  |  |                  |  |                  |  |            | |
| | Canteen: Food    |  |                  |  |                  |  |            | |
| | [Risk: 10%]      |  |                  |  |                  |  |            | |
| +------------------+  +------------------+  +------------------+  +------------+ |
|                                                                                  |
+----------------------------------------------------------------------------------+
```

## 3. Resolution/Communication Thread (Detail View)

```text
+----------------------------------------------------------------------------------+
| < Back to List      #CMP-1002: Rash Driving on Route 12        [ High Severity ] |
+----------------------------------------------------------------------------------+
| LEFT PANEL (Info)   | CENTER PANEL (Timeline)               | RIGHT PANEL (Act)|
|                     |                                       |                  |
| Status: In-Progress | [System] Ticket Created.              | [ ASSIGN ]       |
| Created: 2 hrs ago  | 10:00 AM                              | [ CHANGE STATUS ]|
| Complainant: Parent |                                       | [ RESOLVE ]      |
| (Mrs. Sharma)       | [Admin Warning] AI Detected potential | [ ESCALATE ]     |
| Target: Driver Ram  | Safety Violation. Risk High.          |                  |
|                     |                                       | ---------------- |
| SLA: 4 hrs left     | [Transport Mgr] (Internal Note)       | Medical Check?   |
|                     | I have checked the GPS logs. Speed    | ( ) Alcohol      |
| AI Insight:         | was 65kmph in 40 zone.                | ( ) Drug         |
| Sentiment: Angry    | 11:30 AM                              | [ ADD CHECK ]    |
| Risk: High          |                                       |                  |
|                     | [Transport Mgr] (Public Reply)        | Attachments:     |
|                     | Dear Parent, we are investigating...  | [ gps_log.pdf ]  |
|                     | 11:35 AM                              |                  |
|                     |                                       |                  |
|                     | [ Reply here...                     ] |                  |
|                     | [ (o) Public  ( ) Internal Note     ] |                  |
|                     | [ SEND ]                              |                  |
+---------------------+---------------------------------------+------------------+
```
