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


1. Dropdown Need
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Dropdown Need                                                                                                                         │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ *Database Type : [ Prime   ▼ ] *Tabel Name : [ tpt_vehicle                   ▼ ] *Coloumn : [ vehicle_type                         ▼] |
│ Tenant Creation Allowed : [ Yes ▼ ]   IS System : [ No  ▼ ]   Is Active : [ Yes ▼ ]                    [Search] [Add] [Edit] [Delete] │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Category           | Main Menu             | Sub Menu            | Tab.                 | Column                |  Is  |Tenant |Active│
│ Name               | Name                  | Name                | Name                 | Name                  |System|Allowed|Active│
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Operation          | Transport             | Transport Masters   | Vehicle              | Vehicle Type          |  1   |  0    |  1   │
│ Core Config        | School Setup          | Dropdown Table      | Dropdown Need        | submission_type_id    |  1   |  0    |  1   │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Dropdown Need                                                                                                                         │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ *Database Type : [ Prime   ▼ ] *Tabel Name : [ tpt_vehicle                   ▼ ] *Coloumn : [ vehicle_type                         ▼] |
│                                                                                                        [Search] [Add] [Edit] [Delete] │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤

│ Tenant Creation Allowed : [ Yes ▼ ]   IS System : [ No  ▼ ]   Is Active : [ Yes ▼ ]  
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Category           | Main Menu             | Sub Menu            | Tab.                 | Column                |  Is  |Tenant |Active│
│ Name               | Name                  | Name                | Name                 | Name                  |System|Allowed|Active│
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Operation          | Transport             | Transport Masters   | Vehicle              | Vehicle Type          |  1   |  0    |  1   │
│ Core Config        | School Setup          | Dropdown Table      | Dropdown Need        | submission_type_id    |  1   |  0    |  1   │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘




    `is_system` TINYINT(1) DEFAULT 1,     -- If true, this Dropdown can be created by Tenant
    `tenant_creation_allowed` TINYINT(1) DEFAULT 0,  -- If true, this Dropdown can be created by Tenant
    `compulsory` TINYINT(1) DEFAULT 1,    -- If true, this Dropdown is compulsory for Application fuctioning
    `is_active` TINYINT(1) DEFAULT 1,     -- If true, this Dropdown is active



3. Dropdown List
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Dropdown List                                                                                                   │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                 │
│ *Category : [ Category ▼        ]    *Main Menu : [ Main Menu ▼        ]     Sub Menu : [ Sub Menu ▼]           |
│  Tab Name : [ Sub Sub Menu ▼    ]    *Coloumn   : [ Coloumn ▼          ][Search] [Add] [Edit] [Delete]          │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Order | Dropdown Options Name                | Type         |Additional Info.                                   │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 2     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 3     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 4     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 5     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 6     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 7     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 8     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 9     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 10    | Dropdown Options Name                | Type         |Additional Info.                                   │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


4. Create Dropdown
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  CREATE DROPDOWN                                                                                                │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                                 │
│ *Category : [ Category ▼        ]    *Main Menu : [ Main Menu ▼        ]     Sub Menu : [ Sub Menu ▼]           |
│  Tab Name : [ Sub Sub Menu ▼    ]    *Coloumn   : [ Coloumn ▼          ]                                        │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Order | Dropdown Options Name                | Type         |Additional Info.                                   │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 2     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 3     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 4     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 5     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 6     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 7     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 8     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 9     | Dropdown Options Name                | Type         |Additional Info.                                   │
│ 10    | Dropdown Options Name                | Type         |Additional Info.                                   │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                                                                   [Save] 
