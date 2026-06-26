# PROMPT to Enhance DDL Schema
==============================

## What needs to be check ed in DDL Schema
------------------------------------------
- INDEX key should start with "idx_{Module_Short_Name}_Short_Table_Name_Index_Columns" e.g. (INDEX `idx_subject_book` (`class_id`, `subject_id`, `book_id`),)
- UNIQUE key should start with "uq_{Module_Short_Name}_Short_Table_Name_Index_Columns" 
    e.g. for Table : `lib_book_author_jnt` -> (UNIQUE KEY `uq_lib_bookAuthor_author_authorOrder` (`book_id`, `author_id`, `author_order`),)
- Always keep all Key_name length within 60 Characters. If in anycase it is going beyond then use Short name for Table & Fields 
    e.g. for Table : `acc_ledger_mappings` -> (UNIQUE KEY `uq_acc_lm_ledger_module_type_sourceId` (`ledger_id`, `source_module`, `source_type`, `source_id`),) 
    OR for table : lib_account_entry_config -> (UNIQUE KEY `uq_lib_aec_fineType_SlabConf_accGrp_ledger` (`fine_type_id`, `fine_slab_config_id`, `account_group_id`, `ledger_id`),)
- FOREIGN KEY should start with "fk_{Module_Short_Name}_Short Table Name_Index_Columns" 
    e.g. CONSTRAINT `fk_acc_lm_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers` (`id`) ON DELETE RESTRICT
- If Table name OR Field name has multipal Words joined using "_" then make a Single Word by removing "_" e.g. :
    Convert table name (`lib_fine_slab_config`) -> (`lib_fineSlabConfig`). As `lib` is Module Short Name, using it as `lib` and then combining rest Table Name as `fineSlabConfig`
    Convert Field name (`membership_type_id`) -> (`membershipTypeId`) OR if we need to reduce size then we can use (`membershipType`) also.
