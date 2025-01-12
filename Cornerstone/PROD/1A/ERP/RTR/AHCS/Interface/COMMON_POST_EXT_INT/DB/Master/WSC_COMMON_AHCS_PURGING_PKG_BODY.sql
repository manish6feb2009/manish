create or replace PACKAGE body wsc_ahcs_purging_pkg IS
	
    PROCEDURE PURGE_RECORDS ( 
        p_success_days IN NUMBER,
        p_error_days in  number
    ) IS
    lv_days varchar2(100);
    BEGIN
	 
    ---***Insert into Dashboard Audit table
    Begin
    insert into WSC_AHCS_DASHBOARD1_AUDIT_T
    (select * from  wsc_ahcs_dashboard1_v
     minus 
     select * from WSC_AHCS_DASHBOARD1_AUDIT_T);
    END; 


            --**** AP PURGING****  
      DELETE FROM WSC_AHCS_AP_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_AP_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ;     

       DELETE FROM WSC_AHCS_AP_TXN_HEADER_T hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_AP_TXN_HEADER_T hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ; 


		   -- ****AR PURGING****

		DELETE FROM WSC_AHCS_AR_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_AR_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ;     

       DELETE FROM WSC_AHCS_AR_TXN_HEADER_T hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_AR_TXN_HEADER_T hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ; 

       COMMIT;

	   -- ****POC PURGING****

		DELETE FROM WSC_AHCS_POC_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_POC_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ;     

       DELETE FROM WSC_AHCS_POC_TXN_HEADER_T hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_POC_TXN_HEADER_T hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ; 

       COMMIT;

    --- ****FA PURGING****


		DELETE FROM WSC_AHCS_FA_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_FA_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ;     

       DELETE FROM WSC_AHCS_FA_TXN_HEADER_T hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_FA_TXN_HEADER_T hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ; 

       COMMIT;	 

	   --- ****CENTRL PURGING****


		DELETE FROM WSC_AHCS_CENTRAL_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_CENTRAL_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ;     

       DELETE FROM WSC_AHCS_CENTRAL_TXN_HEADER_T hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_CENTRAL_TXN_HEADER_T hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ; 

        DELETE FROM WSC_AHCS_INT_STATUS_T 
        WHERE 
        last_updated_date < SYSDATE - p_success_days
        AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS';

        DELETE FROM WSC_AHCS_INT_STATUS_T 
        WHERE last_updated_date < SYSDATE - p_error_days; 

        DELETE FROM WSC_AHCS_INT_CONTROL_T 
        WHERE last_updated_date < SYSDATE - p_error_days; 

       COMMIT;	 
BEGIN DBMS_STATS.GATHER_SCHEMA_STATS('FININT',DBMS_STATS.AUTO_SAMPLE_SIZE); END;

    EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);


    END PURGE_RECORDS;

PROCEDURE PURGE_RECORDS_ASYNC ( 
        p_success_days IN NUMBER,
        p_error_days in  number
    ) IS

    BEGIN

    dbms_output.put_line('Before post_booking_flow_job');
  dbms_scheduler.create_job (
  job_name   =>  'PURGE_RECORDS',
  job_type   => 'PLSQL_BLOCK',
  job_action => 
    'BEGIN 
       wsc_ahcs_purging_pkg.PURGE_RECORDS('||p_success_days||','||p_error_days ||');
     END;',
  enabled   =>  TRUE,  
  auto_drop =>  TRUE, 
  comments  =>  'Purging Records from AHCS Staging Tables');

    EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
    END PURGE_RECORDS_ASYNC;

end wsc_ahcs_purging_pkg    ;
/