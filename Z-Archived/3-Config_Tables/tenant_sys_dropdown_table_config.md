## Transport Module

---
### Vehicle Type ###

**Entry in 'sys_dropdown_needs' table**
db_type : tenant_db  
table_name : tpt_vehicle  
column_name : vehicle_type  

**Entry in 'sys_dropdown_table' table**
Key : "tpt_vehicle.vehicle_type"  
Values : ('BUS','VAN','CAR') (3 records)  
Type : String  

---


### Fuel Type ###

**Entry in 'sys_dropdown_needs' table**
db_type : tenant_db  
table_name : tpt_vehicle  
column_name : fuel_type  

**Entry in 'sys_dropdown_table' table**
Key : "tpt_vehicle.fuel_type"  
Values : ('Diesel','Petrol','CNG','Electric') (4 records)  
Type : String  

---

### Ownership Type ###

**Entry in 'sys_dropdown_needs' table**
db_type : tenant_db  
table_name : tpt_vehicle  
column_name : ownership_type  

**Entry in 'sys_dropdown_table' table**
Key : "tpt_vehicle.ownership_type"  
Values : ('Owned','Leased','Rented') (3 records)  
Type : String  

---
### ID Type ###

**Entry in 'sys_dropdown_needs' table**
db_type : tenant_db  
table_name : tpt_personnel  
column_name : id_type  

**Entry in 'sys_dropdown_table' table**
Key : "tpt_personnel.id_type"  
Values : ('Aadhaar','Passport','DriverLicense') (3 records)  
Type : String  

---

### Severity Level ###

**Entry in 'sys_dropdown_needs' table**
db_type : tenant_db  
table_name : cmp_complaint_categories  
column_name : severity_level  

**Entry in 'sys_dropdown_table' table**
Key : "cmp_complaint_categories.severity_level"  
Values : ('1','2','3','4','5','6','7','8','9','10') (10 records)  
Type : Integer  
Additional_info : Key-lebel, Value('Low', Minor', 'Moderate', 'Substantial', 'Significant', 'Severe', 'Major', 'Acute', 'Emergency', 'Critical')

**Severity_Level-Detail**
------------------------------------------------------------------------------------------------------------------------------------
| Level	| Label	      | Description								      | Real-World Example
|-------|-------------|-----------------------------------------------|-------------------------------------------------------------
| 1	    | Low	      | Cosmetic or minor; no loss of function.       | A typo on a webpage or a slight color mismatch.
| 2	    | Minor	      | Small annoyance; easy workaround exists.      | A "Help" button that takes two clicks instead of one.
| 3	    | Moderate	  | Standard issue; affects individual workflow.  | A specific non-essential feature is loading slowly.
| 4	    | Substantial | Noticeable performance degradation.           | An app is sluggish for all users, but still working.
| 5	    | Significant | Core feature is buggy or intermittent.        | Users can't upload files on the first try; requires retries.
| 6	    | Severe      | Major feature is completely broken for some.  | 25% of users cannot log in at all.
| 7	    | Major       | Large-scale disruption; productivity stopped. | A primary database is offline; most work has ceased.
| 8	    | Acute       | High-risk; potential for data loss or breach. | Sensitive data is being exposed or corrupted in real-time.
| 9	    | Emergency   | Near-total failure; immediate intervention.   | All external services are down; customers are complaining.
| 10	| Critical    | Total systemic collapse; existential threat.  | Complete system blackout or massive security wipe-out.

---

### Priority Score ###

**Entry in 'sys_dropdown_needs' table**
db_type : tenant_db
table_name : cmp_complaint_categories
column_name : priority_score

**sys_dropdown_table e.g. 1=Critical, 2=Urgent 3=High, 4=Medium, 5=Low**

Key - "cmp_complaint_categories.priority_score"
Values - ('1','2','3','4','5') (5 records)
Type - Integer
Additional_info - Key-lebel, Value('Critical', 'Urgent', 'High', 'Medium', 'Low')

---
---

Key : 
Values : 
