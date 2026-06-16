Storage Architecture Recommendation                                                                                                                                                         
                                                                                                                                                                                              
  First: What goes in .env vs sch_config                                                                                                                                                      
                                                                                                                                                                                              
  ┌─────────────────────────────────────────┬────────────┬─────────────────────────────────────────────────────┐                                                                              
  │                 Concern                 │  Location  │                         Why                         │                                                                              
  ├─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────┤                                                                             
  │ Server URL, credentials, bucket, driver │ .env       │ Infrastructure — changes per environment (dev/prod) │                                                                              
  ├─────────────────────────────────────────┼────────────┼─────────────────────────────────────────────────────┤                                                                              
  │ Folder path template (the structure)    │ sch_config │ Business rule — can be customized per school        │
  └─────────────────────────────────────────┴────────────┴─────────────────────────────────────────────────────┘

  The app code combines both: env('LMS_STORAGE_URL') + '/' + tenant()->id + '/' + config_template_with_ids_substituted

  ---
  Folder Hierarchy Decision

  Your options ranked:

  Option A: {session} → {student} → {class_section} → {assessment}
  Option B: {student} → {session} → {class_section} → {assessment}
  Option C (Recommended): {module} → {session} → {class_section} → {assessment} → {student}

  Why Option C wins:

  The dominant real-world access patterns are:

  ┌─────────┬────────────────────────────────────────────────────┬─────────────────────────────────────┐
  │   Who   │                    What they do                    │     Best hierarchy serves this      │
  ├─────────┼────────────────────────────────────────────────────┼─────────────────────────────────────┤
  │ Teacher │ "Show all submissions for Quest 12 from Class 9-A" │ Assessment → Student (C)            │
  ├─────────┼────────────────────────────────────────────────────┼─────────────────────────────────────┤
  │ Teacher │ "Archive last year's files"                        │ Session (C)                         │
  ├─────────┼────────────────────────────────────────────────────┼─────────────────────────────────────┤
  │ Student │ "Show my Quest submissions"                        │ Can search by student_id within (C) │
  ├─────────┼────────────────────────────────────────────────────┼─────────────────────────────────────┤
  │ Admin   │ "Clean up Quest 12 after year ends"                │ Module/Session/Assessment (C)       │
  └─────────┴────────────────────────────────────────────────────┴─────────────────────────────────────┘

  Option B (student first) optimises for student portfolio — a secondary use case. Option C serves the primary use case (teacher reviewing an entire class's submissions for one assessment)
  with a single LIST call on the storage server.

  Recommended full path:

  {STORAGE_URL}/{tenant_uuid}/{module}/{session_code}/{class_section_id}/{assessment_id}/{student_id}/{uploader}/

  Real examples:

  # Quest answer (student uploads)
  /abc-uuid/lms-quest/2025-26/101/42/789/student/answer_q1.jpg

  # Quest checked copy (teacher uploads with remarks)
  /abc-uuid/lms-quest/2025-26/101/42/789/teacher/checked_q1.pdf

  # Exam Online (student answer image)
  /abc-uuid/lms-exam-online/2025-26/101/18/789/student/answer_page.jpg

  # Exam Offline (entire answer sheet — 20 pages as PDF or numbered JPGs)
  /abc-uuid/lms-exam-offline/2025-26/101/18/789/student/sheet_p01.jpg
  /abc-uuid/lms-exam-offline/2025-26/101/18/789/student/sheet_p02.jpg
  /abc-uuid/lms-exam-offline/2025-26/101/18/789/teacher/marked_sheet.pdf

  # Homework (daily)
  /abc-uuid/lms-homework/2025-26/101/hw-55/789/student/homework_20260112.pdf

  Why student_id NOT sas_id:
  - student_id is stable across years — same student's files are traceable across 2024-25 and 2025-26
  - sas_id is opaque and changes each year (a new row is created per year)                                                                                                                    
  - Session context is already captured by session_code in the path above it — no need to encode it again in sas_id
                                                                                                                                                                                              
  Why session_code (e.g., 2025-26) NOT session_id (integer):                                                                                                                                  
  - Human-readable when browsing the storage bucket directly                                                                                                                                  
  - Stable across DB migrations                                                                                                                                                               
  - Year-end archival: simply move/compress the 2025-26/ prefix
                                                                                                                                                                                              
  ---                                                       
  sch_config Key Names and Seed Data

  INSERT INTO `sch_config`
    (`module_id`, `ordinal`, `key`, `key_name`, `value`, `value_type`, `description`,
     `additional_info`, `tenant_can_modify`, `mandatory`, `used_by_app`, `is_active`)
  VALUES

  -- LMS Quest
  (LMS_MODULE_ID, 200,
   'lms_quest_upload_path',
   'LMS Quest — Upload Folder Path',
   'lms-quest/{session_code}/{class_section_id}/{quest_id}/{student_id}/{uploader}',
   'STRING',
   'Folder path template for LMS Quest answer uploads. Placeholders: {session_code}, {class_section_id}, {quest_id}, {student_id}, {uploader} (student|teacher).',
   '{"placeholders": ["session_code","class_section_id","quest_id","student_id","uploader"], "uploader_values": ["student","teacher"]}',
   0, 1, 1, 1),

  -- LMS Exam — Online
  (LMS_MODULE_ID, 201,
   'lms_exam_online_upload_path',
   'LMS Exam Online — Upload Folder Path',
   'lms-exam-online/{session_code}/{class_section_id}/{exam_id}/{student_id}/{uploader}',
   'STRING',
   'Folder path template for LMS Online Exam answer image uploads. Placeholders: {session_code}, {class_section_id}, {exam_id}, {student_id}, {uploader} (student|teacher).',
   '{"placeholders": ["session_code","class_section_id","exam_id","student_id","uploader"], "uploader_values": ["student","teacher"]}',
   0, 1, 1, 1),

  -- LMS Exam — Offline (Answer Sheets)
  (LMS_MODULE_ID, 202,
   'lms_exam_offline_upload_path',
   'LMS Exam Offline — Upload Folder Path',
   'lms-exam-offline/{session_code}/{class_section_id}/{exam_id}/{student_id}/{uploader}',
   'STRING',
   'Folder path template for LMS Offline Exam answer sheet uploads (15-20 pages per student). Placeholders: {session_code}, {class_section_id}, {exam_id}, {student_id}, {uploader}
  (student|teacher).',
   '{"placeholders": ["session_code","class_section_id","exam_id","student_id","uploader"], "uploader_values": ["student","teacher"], "note": "Offline exam: multiple JPG pages (sheet_p01.jpg
   … sheet_p20.jpg) OR single PDF. Teacher upload is the marked/annotated version."}',
   0, 1, 1, 1),

  -- LMS Homework
  (LMS_MODULE_ID, 203,
   'lms_homework_upload_path',
   'LMS Homework — Upload Folder Path',
   'lms-homework/{session_code}/{class_section_id}/{homework_id}/{student_id}/{uploader}',
   'STRING',
   'Folder path template for LMS Homework uploads. Placeholders: {session_code}, {class_section_id}, {homework_id}, {student_id}, {uploader} (student|teacher).',
   '{"placeholders": ["session_code","class_section_id","homework_id","student_id","uploader"], "uploader_values": ["student","teacher"]}',
   0, 1, 1, 1);

  ---
  .env Variables to Add

  # LMS Cloud Storage Server
  LMS_STORAGE_DRIVER=s3                          # s3 | gcs | sftp | local
  LMS_STORAGE_ENDPOINT=https://s3.ap-south-1.amazonaws.com
  LMS_STORAGE_BUCKET=prime-ai-lms
  LMS_STORAGE_REGION=ap-south-1
  LMS_STORAGE_ACCESS_KEY=your-access-key
  LMS_STORAGE_SECRET_KEY=your-secret-key
  LMS_STORAGE_URL=https://cdn.your-storage.com   # Public CDN URL for serving files

  ---
  How App Code Uses It

  // Helper in a StoragePathService
  public function buildLmsPath(string $configKey, array $params, string $uploader = 'student'): string
  {                                                                                                                                                                                           
      $template = SchConfig::getValue($configKey);
      // e.g. 'lms-quest/{session_code}/{class_section_id}/{quest_id}/{student_id}/{uploader}'                                                                                                
                                                            
      $path = str_replace(                                                                                                                                                                    
          array_map(fn($k) => "{{$k}}", array_keys($params)),
          array_values($params),                                                                                                                                                              
          $template
      );                                                                                                                                                                                      
                                                            
      // Prepend tenant UUID for isolation                                                                                                                                                    
      return tenant()->id . '/' . $path . '/';
  }                                                                                                                                                                                           
                                                            
  // Usage                                                                                                                                                                                    
  $folderPath = $storageService->buildLmsPath('lms_quest_upload_path', [
      'session_code'     => '2025-26',
      'class_section_id' => 101,
      'quest_id'         => 42,
      'student_id'       => 789,
      'uploader'         => 'student',                                                                                                                                                        
  ]);
  // → abc-uuid/lms-quest/2025-26/101/42/789/student/                                                                                                                                         
                                                            
  Storage::disk('lms')->put($folderPath . $filename, $fileStream);

  ---
  Summary Table

  ┌──────────────────────────────┬──────────────────┬──────────────────────────────────────────────────────────────────────────────────────┐
  │          Config Key          │      Module      │                                    Path Template                                     │
  ├──────────────────────────────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────┤
  │ lms_quest_upload_path        │ LMS Quest        │ lms-quest/{session_code}/{class_section_id}/{quest_id}/{student_id}/{uploader}       │
  ├──────────────────────────────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────┤
  │ lms_exam_online_upload_path  │ LMS Exam Online  │ lms-exam-online/{session_code}/{class_section_id}/{exam_id}/{student_id}/{uploader}  │                                                  
  ├──────────────────────────────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────┤                                                  
  │ lms_exam_offline_upload_path │ LMS Exam Offline │ lms-exam-offline/{session_code}/{class_section_id}/{exam_id}/{student_id}/{uploader} │                                                  
  ├──────────────────────────────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────┤                                                  
  │ lms_homework_upload_path     │ LMS Homework     │ lms-homework/{session_code}/{class_section_id}/{homework_id}/{student_id}/{uploader} │
  └──────────────────────────────┴──────────────────┴──────────────────────────────────────────────────────────────────────────────────────┘                                                  
                                                            
  {uploader} = student (original submission) or teacher (reviewed/annotated copy). This separation is critical — never mix them in the same folder.
  