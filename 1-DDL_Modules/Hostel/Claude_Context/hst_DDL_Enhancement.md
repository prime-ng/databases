# Hostel DDL Enhancement

### Prompt
I wanted you to perform below tasks in sequence :
  - First save the the last session in folder "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/.ai-contexts" using Prompt "old_db/4-CLAUDE_Prompts/0-Important_Prompts/Save_Context.md".                                       
  - Clear the Session                                                                                                                                                                                                      
  - Read and Understand Hostel Module DDL schema from "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Hostel/DDL/HST_DDL_v2.sql".
  - After evaluating the Module in detail, find out gaps and possible enhancements and then create a New Enhnced DDL Schema for Hostel Module.
  - Save the enhanced DDL file as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/Hostel/DDL/HST_DDL_v3.sql"
  - Provide complet detail of Enhancements & New Addtiong in the DDL file.



 ⏵⏵ accept edits on (shift+tab to cycle) · esc to interrupt                                                                                                                                            ⧉ In HST_DDL_v2.sql
  ├─────────────┼──────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Audit       │ hst_notification_log     │ Every parent/student/warden notification logged: channel (email/SMS/push/WhatsApp/portal), status (queued → delivered → read), retries, vendor message ID. Drives delivery   │
  │             │                          │ audit and SLA reports.                                                                                                                                                       │
  └─────────────┴──────────────────────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  Field additions to v2 tables (all nullable, all additive)

  ┌─────────────────────┬───────────────────────────────────────────────────────────────────────────────────────────┐
  │        Table        │                                        New fields                                         │
  ├─────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ hst_hostels         │ email, total_floors, principal_warden_id, gender_strict_enforce                           │
  ├─────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ hst_floors          │ block_code                                                                                │
  ├─────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ hst_rooms           │ block_code, windows_facing, accessibility_features_json, status now includes 'reserved'   │
  ├─────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ hst_beds            │ bed_type, notes, status now includes 'reserved'                                           │
  ├─────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ hst_room_inventory  │ photo_media_id (visual evidence of damage)                                                │
  ├─────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ hst_allotments      │ transfer_from_allotment_id, vacation_reason, vacated_by, is_emergency                     │
  ├─────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ hst_visitor_log     │ visitor_photo_media_id, signed_register_media_id                                          │
  ├─────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ hst_movement_log    │ is_overnight, parent_consent_received, consent_media_id                                   │
  ├─────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ hst_incidents       │ incident_type_id (FK to new master); old VARCHAR kept for back-compat                     │
  ├─────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ hst_complaints      │ acknowledged_at, satisfaction_score                                                       │
  ├─────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ hst_sick_bay_log    │ medical_consent_received                                                                  │
  ├─────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ hst_mess_attendance │ shift_id (multi-shift mess support)                                                       │
  ├─────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ hst_leave_passes    │ guardian_name, guardian_relation, is_overnight, parent_consent_received, consent_media_id │
  └─────────────────────┴───────────────────────────────────────────────────────────────────────────────────────────┘

  New indexes (7) for dashboard / SLA / overdue queries

  - hst_rooms.idx_hst_room_status — vacancy dashboard.
  - hst_beds.idx_hst_bed_status — bed allocation reports.
  - hst_allotments.idx_hst_allot_date and idx_hst_allot_transfer_from.
  - hst_movement_log.idx_hst_ml_expected_return — overdue dashboard.
  - hst_complaints.idx_hst_cmp_status_sla — open-and-overdue SLA dashboard.
  - hst_leave_passes.idx_hst_lp_dates and idx_hst_lp_status — calendar views.                                                                                                                                                
  - hst_sick_bay_log.idx_hst_sb_hospital_ref — referral dashboard.                                                                                                                                                           
  - hst_incidents.idx_hst_inc_type_id — drives the new master FK.                                                                                                                                                            
                                                                                                                                                                                                                             
  What I deliberately did NOT change (would break v2 callers)                                                                                                                                                                
                                                                                                                                                                                                                             
  - No table renames.                                                                                                                                                                                                        
  - No column type changes (e.g., incident_type VARCHAR stays — incident_type_id was added alongside).                                                                                                                     
  - No constraint relaxation (every existing UNIQUE / FK preserved).                                                                                                                                                         
  - No removal of qualifications_json-style JSON columns (deferred to v4 normalisation pass).                                                                                                                                
                                                                                                                                                                                                                             
  Deferred to v4 (in-file deferred section)                                                                                                                                                                                  
                                                                                                                                                                                                                             
  1. Drop hst_incidents.incident_type VARCHAR once all callers migrated to incident_type_id.                                                                                                                                 
  2. Normalize facilities_json and amenities_json to first-class master + junction tables.                                                                                                                                 
  3. Cross-link hst_special_diets to HPC medical records.                                                                                                                                                                    
  4. hst_visitor_blacklist (gate-bar table).                                                                                                                                                                                 
  5. Coordinate vendor/contractor coverage with the vnd_* module owner.                                                                                                                                                      
  6. Encryption-at-rest for visitor ID proof.                                                                                                                                                                                
  7. Partition hst_audit_log and hst_notification_log by month (both are append-heavy).                                                                                                                                      
                                                                                                                                                                                                                             
  Lint suggestion before deploying                                                                                                                                                                                           
                                                                                                                                                                                                                           
  Run mysql --batch < HST_DDL_v3.sql against an empty DB to verify all 36 CREATEs succeed in dependency order. External tables expected to exist beforehand: sys_users, sys_media, std_students, sch_academic_term. Layer    
  ordering inside the file is preserved from v2 and the 15 new tables are placed in their correct dependency layer.     