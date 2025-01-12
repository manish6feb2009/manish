create or replace PACKAGE BODY WSC_AHCS_REPROCESSING_PKG AS 
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PACKAGE             WSC_GL_AL_VALIDATION_TRANSFORMATION_PKG AS
------------------------------------------------------------------------------------------
-- COPYRIGHT (C) Wesco Inc.
--
-- Protected as an unpublished work.  All Rights Reserved.
--
-- The computer program listings, specifications, and documentation herein
-- are the property of Wesco Incorporated and shall not be
-- reproduced, copied, disclosed, or used in whole or in part for any
-- reason without the express written permission of Wesco Incorporated.
--
-- DESCRIPTION:
-- This package contains supporting procedures required for validation & transformation of data
-- staged into the staging tables that hosts data provided from the source sub-ledger applications and
-- destined for AHCS.
-- 
--
-- FILE LOCATION AND VERSION
-- $Header: WSC_GL_AL_VALIDATION_TRANSFORMATION_PKG.pkg
--
-- PRE-REQUISITES
-- The package makes an implicit call to an external packaged function, wsc_gl_coa_mapping_pkg.coa_mapping for 
-- deriving the COA segment values in the future state COA structure on the basis of legacy COA structure.
-- This package wsc_gl_coa_mapping_pkg must be compiled before installing this package.
--
-- The following staging tables must be created before 
-- 1. WSC_AHCS_AP_TXN_LINE_T
-- 2. WSC_AHCS_INT_STATUS_T 
-- 3. WSC_AHCS_INT_CONTROL_T
-- 4. wsc_gl_legal_entities_t
-- 5. wsc_gl_ccid_mapping_t
--

--
-- PROCEDURE/ FUNCTION LIST:
--
--     Procedure validate
--     Procedure transform
--     Procedure is_date

--
-- MODIFICATION HISTORY :
--
-- Name                              Date      Ver   Description
-- =================              ===========  ===   ====================================
-- Deloitte Consulting            24-JULY-2021  1.0   Created
--
----------------------------------------------------------------------------------------


   PROCEDURE reprocessing_async(P_FILE_NAME IN VARCHAR2) IS
   
   cursor cur_get_file_details is
   select batch_id,source_application 
     from wsc_ahcs_int_control_t 
    where file_name= p_file_name;
    
    lv_batch_id NUMBER;
    lv_src_application VARCHAR2(100);
   
   BEGIN
   
        open cur_get_file_details;
        fetch cur_get_file_details into lv_batch_id,lv_src_application;
        close cur_get_file_details;
logging_insert(null,lv_batch_id,21,'file derived',null,sysdate);
   IF upper(lv_src_application) like 'EBS%AP%' THEN   
   logging_insert(null,lv_batch_id,22,'before scheduler job call',null,sysdate);
        dbms_scheduler.create_job (
      job_name   =>  'AP_REPROCESSING_'||p_file_name||'_'||to_char(sysdate,'DD_MON_YYYY_HH24SS'),
      job_type   => 'PLSQL_BLOCK',
      job_action => 
        'BEGIN 
           WSC_AHCS_AP_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('||lv_batch_id||');
         END;',
      enabled   =>  TRUE,  
      auto_drop =>  TRUE, 
      comments  =>  'AP_REPROCESSING ');
      logging_insert(null,lv_batch_id,23,'after scheduler job call',null,sysdate);
   ELSIF upper(lv_src_application) like 'EBS%AR%' THEN   
        dbms_scheduler.create_job (
      job_name   =>  'AR_REPROCESSING_'||p_file_name||'_'||to_char(sysdate,'DD_MON_YYYY_HH24SS'),
      job_type   => 'PLSQL_BLOCK',
      job_action => 
        'BEGIN 
           WSC_AHCS_AR_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('||lv_batch_id||');
         END;',
      enabled   =>  TRUE,  
      auto_drop =>  TRUE, 
      comments  =>  'AR_REPROCESSING ');
   ELSIF upper(lv_src_application) like 'EBS%FA%' THEN   
        dbms_scheduler.create_job (
      job_name   =>  'FA_REPROCESSING_'||p_file_name||'_'||to_char(sysdate,'DD_MON_YYYY_HH24SS'),
      job_type   => 'PLSQL_BLOCK',
      job_action => 
        'BEGIN 
           WSC_AHCS_FA_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('||lv_batch_id||');
         END;',
      enabled   =>  TRUE,  
      auto_drop =>  TRUE, 
      comments  =>  'FA_REPROCESSING ');
   ELSIF upper(lv_src_application) like 'ERP%POC%' THEN   
        dbms_scheduler.create_job (
      job_name   =>  'POC_REPROCESSING_'||p_file_name||'_'||to_char(sysdate,'DD_MON_YYYY_HH24SS'),
      job_type   => 'PLSQL_BLOCK',
      job_action => 
        'BEGIN 
           WSC_AHCS_POC_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('||lv_batch_id||');
         END;',
      enabled   =>  TRUE,  
      auto_drop =>  TRUE, 
      comments  =>  'POC_REPROCESSING ');   
      
      ELSIF upper(lv_src_application) like 'CENTRAL%INV%' THEN   
        dbms_scheduler.create_job (
      job_name   =>  'CENTRAL_REPROCESSING_'||p_file_name||'_'||to_char(sysdate,'DD_MON_YYYY_HH24SS'),
      job_type   => 'PLSQL_BLOCK',
      job_action => 
        'BEGIN 
		   WSC_AHCS_CENTRAL_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('||lv_batch_id||');
         END;',
      enabled   =>  TRUE,  
      auto_drop =>  TRUE, 
      comments  =>  'CENTRAL_REPROCESSING');
   
   ELSIF upper(lv_src_application) like 'SALES%COM%' THEN   
        dbms_scheduler.create_job (
      job_name   =>  'SALES_REPROCESSING_'||p_file_name||'_'||to_char(sysdate,'DD_MON_YYYY_HH24SS'),
      job_type   => 'PLSQL_BLOCK',
      job_action => 
        'BEGIN 
		   WSC_AHCS_CENTRAL_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('||lv_batch_id||');
         END;',
      enabled   =>  TRUE,  
      auto_drop =>  TRUE, 
      comments  =>  'CENTRAL_REPROCESSING');
      
      
   END IF;
   
   
   END reprocessing_async;

END WSC_AHCS_REPROCESSING_PKG;
/