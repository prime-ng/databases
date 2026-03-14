# Dropdown Table Design



┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  PRIME ERP  |  Core Configuration                                                                                      [User Profile] │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                            Breadcrumb: ....>...>..... │
│┌─Tabs────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐│
││ [Dropdown Need] [Dropdown Menu(PG)] [Dropdown List] [Create Dropdown] [Create Dropdown(PG)] [Dropdown Need & Table Mapping]         ││
│└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘│
│                                                                                                                                       │
│                                                                                                                                       │
│                                                                                                                                       │
│                                                                                                                                       │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘




Dropdown List (If user belongs to PrimeGurukul)
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  Dropdown List                                                                                                                              │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│ *Category : [ Category                 ▼ ]  *Main Menu : [ Main Menu                    ▼ ] Sub Menu : [ Sub Menu                       ▼ ] │
│ *Category    : [ Category             ▼ ] *Main Menu  : [ Main Menu                     ▼ ] Sub Menu : [ Sub Menu                       ▼ ] │
│ Tab Name     : [ Sub Sub Menu         ▼ ] *Coloumn    : [ Coloumn                       ▼ ]                  [Search] [Add] [Edit] [Delete] │
│ Dropdown Key : cmp_complaints.target_user_type_id                                                                                           │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Order | Dropdown Options Name                | Type         |Additional Info.                                                               │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 2     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 3     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 4     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 5     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 6     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 7     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 8     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 9     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 10    | Dropdown Options Name                | Type         |Additional Info.                                                               │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ 

Dropdown List (If user belongs to Tenant)
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Dropdown List                                                                                                                               │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│ *Category    : [ Category             ▼ ] *Main Menu  : [ Main Menu                     ▼ ] Sub Menu : [ Sub Menu                       ▼ ] │
│ Tab Name     : [ Sub Sub Menu         ▼ ] *Coloumn    : [ Coloumn                       ▼ ]      [Search]                           [Edit]  │
│ Dropdown Key : cmp_complaints.target_user_type_id                                                                                           │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Order | Dropdown Options Name                | Type         |Additional Info.                                                               │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 2     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 3     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 4     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 5     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 6     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 7     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 8     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 9     | Dropdown Options Name                | Type         |Additional Info.                                                               │
│ 10    | Dropdown Options Name                | Type         |Additional Info.                                                               │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘




4. Edit Dropdown (If user belongs to Tenant)
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  CREATE DROPDOWN                                                                                                                            │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                                             │
│ *Category : [ Category                 ▼ ]  *Main Menu : [ Main Menu                    ▼ ] Sub Menu : [ Sub Menu                       ▼ ] │
│  Tab Name : [ Sub Sub Menu             ▼ ]    *Coloumn   : [ Coloumn                    ▼ ]       [Search]                          [Edit]  │
│  Dropdown Key : cmp_complaints.target_user_type_id                                                                                          │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤ 
│ Order | Dropdown Value               | Type         |Additional Info.                                                                       │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1     | Student                      | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 2     | Staff                        | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 3     | Group                        | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 4     | Department                   | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 5     | Designation                  | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 6     | Facility                     | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 7     | Vehicle                      | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 8     | Event                        | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 9     | Vendor                       | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 10    | Other                        | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                                                                                                       [Save] 


5. Add / Edit Dropdown (PG)
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  CREATE DROPDOWN                                                                                                                            │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ *DB Type     : [ Prime          ▼ ]       *Tabel Name : [ tpt_vehicle                 ▼ ] *Coloumn : [ vehicle_type                     ▼ ] │
│ *Category    : [ Category             ▼ ] *Main Menu  : [ Main Menu                   ▼ ] Sub Menu : [ Sub Menu                         ▼ ] │
│ Tab Name     : [ Sub Sub Menu         ▼ ] *Coloumn    : [ Coloumn                     ▼ ]                    [Search] [Add] [Edit] [Delete] │
│ Dropdown Key : cmp_complaints.target_user_type_id                                                                                           │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Order | Dropdown Value               | Type         |Additional Info.                                                                       │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1     | Student                      | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 2     | Staff                        | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 3     | Group                        | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 4     | Department                   | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 5     | Designation                  | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 6     | Facility                     | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 7     | Vehicle                      | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 8     | Event                        | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 9     | Vendor                       | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 10    | Other                        | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                                                                                                       [Save] 

6. Dropdown Need & Table Mapping (Only for PG Users)
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  CREATE DROPDOWN                                                                                                                            │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ **New Dropdown Need For :**                                                                                                                 │
│ *DB Type     : [ Prime          ▼ ]       *Tabel Name : [ tpt_vehicle                 ▼ ] *Coloumn  : [ vehicle_type                    ▼ ] │
│ *Category    : [ Category             ▼ ] *Main Menu  : [ Main Menu                   ▼ ] Sub Menu  : [ Sub Menu                        ▼ ] │
│ Tab Name     : [ Sub Sub Menu         ▼ ] *Coloumn    : [ Coloumn                     ▼ ]                                          [Search] │
│---------------------------------------------------------------------------------------------------------------------------------------------│
│ Tenant Creation Allowed: [ Yes ▼ ]    IS System: [ No  ▼ ]    Is Active: [ Yes ▼ ]    Dropdown Key : cmp_complaints.target_user_type_id     │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ **New Dropdown Need For :**                                                                                                                 │
│ *DB Type     : [ Prime          ▼ ]       *Tabel Name : [ tpt_vehicle                 ▼ ] *Coloumn : [ vehicle_type                     ▼ ] │
│ *Category    : [ Category             ▼ ] *Main Menu  : [ Main Menu                   ▼ ] Sub Menu : [ Sub Menu                         ▼ ] │
│ Tab Name     : [ Sub Sub Menu         ▼ ] *Coloumn    : [ Coloumn                     ▼ ]                                          [Search] │
│ Dropdown Key : cmp_complaints.target_user_type_id                                                                                           │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1     | Student                      | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 2     | Staff                        | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 3     | Group                        | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 4     | Department                   | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 5     | Designation                  | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 6     | Facility                     | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 7     | Vehicle                      | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 8     | Event                        | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 9     | Vendor                       | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
│ 10    | Other                        | BIGINT       | {"table_name": "cmp_complaints", "column_name": "target_user_type_id"}                │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                                                                                                  [Map & Save]
