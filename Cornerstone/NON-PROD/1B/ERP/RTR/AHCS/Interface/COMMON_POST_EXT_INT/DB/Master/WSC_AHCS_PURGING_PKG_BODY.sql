create or replace PACKAGE BODY wsc_ahcs_purging_pkg IS

    PROCEDURE purge_records (
        p_success_days IN NUMBER,
        p_error_days   IN NUMBER
    ) IS
        lv_days VARCHAR2(100);
        lv_errm VARCHAR2(1000);
    BEGIN

logging_insert('purge_records', 1, 1, 'insert wsc_ahcs_dashboard1_audit_t', NULL,sysdate);
    ---***Insert into Dashboard Audit table
        BEGIN
            INSERT INTO wsc_ahcs_dashboard1_audit_t (application,
    source_system,
    file_name,
    file_processing_date,
    batch_id,
    staged_records,
    staged_amount,
    processed_records,
    processed_amount,
    error_reextract_records,
    error_reextract_amount,
    error_reprocess_records,
    error_reprocess_amount,
    skipped_records,
    skipped_amount)
                ( SELECT
    application,
    source_system,
    file_name,
    file_processing_date,
    batch_id,
    staged_records,
    staged_amount,
    processed_records,
    processed_amount,
    error_reextract_records,
    error_reextract_amount,
    error_reprocess_records,
    error_reprocess_amount,
    skipped_records,
    skipped_amount
FROM
    wsc_ahcs_dashboard1_v
MINUS
SELECT
    application,
    source_system,
    file_name,
    file_processing_date,
    batch_id,
    staged_records,
    staged_amount,
    processed_records,
    processed_amount,
    error_reextract_records,
    error_reextract_amount,
    error_reprocess_records,
    error_reprocess_amount,
    skipped_records,
    skipped_amount
FROM
    wsc_ahcs_dashboard1_audit_t
                );
commit;
        END; 
logging_insert('purge_records', 1, 2, ' wsc_ahcs_ap_txn_line_t', NULL,sysdate);


            --**** AP PURGING****  
        DELETE FROM wsc_ahcs_ap_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        COMMIT;
        DELETE FROM wsc_ahcs_ap_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );

        COMMIT;

logging_insert('purge_records', 1, 3, ' wsc_ahcs_ap_txn_header_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_ap_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        COMMIT;
        DELETE FROM wsc_ahcs_ap_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_error_days
            ); 


        COMMIT;
		   -- ****AR PURGING****
logging_insert('purge_records', 1, 4, ' wsc_ahcs_ar_txn_line_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_ar_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_ar_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );
logging_insert('purge_records', 1, 5, ' wsc_ahcs_ar_txn_header_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_ar_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_ar_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );

        COMMIT;

	   -- ****POC PURGING****
logging_insert('purge_records', 1, 6, ' wsc_ahcs_poc_txn_line_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_poc_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_poc_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );
logging_insert('purge_records', 1, 7, ' wsc_ahcs_poc_txn_header_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_poc_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_poc_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );

        COMMIT;

    --- ****FA PURGING****

logging_insert('purge_records', 1, 8, ' wsc_ahcs_fa_txn_line_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_fa_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_fa_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );

logging_insert('purge_records', 1, 9, ' wsc_ahcs_fa_txn_header_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_fa_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_fa_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );

        COMMIT;	 

	   --- ****CENTRL PURGING****

logging_insert('purge_records', 1, 10, ' wsc_ahcs_central_txn_line_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_central_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_central_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );
logging_insert('purge_records', 1, 11, ' wsc_ahcs_central_txn_header_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_central_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_central_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_error_days
            ); 
  COMMIT;	
-- MF AR--	
logging_insert('purge_records', 1, 12, ' wsc_ahcs_mfar_txn_line_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_mfar_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_mfar_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );

logging_insert('purge_records', 1, 13, ' wsc_ahcs_mfar_txn_header_t', NULL,sysdate);
        DELETE FROM wsc_ahcs_mfar_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_mfar_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );

        COMMIT;	 
--MF INV --	
logging_insert('purge_records', 1, 14, ' wsc_ahcs_mfinv_txn_line_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_mfinv_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_mfinv_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );

logging_insert('purge_records', 1, 15, ' wsc_ahcs_mfinv_txn_header_t', NULL,sysdate);
        DELETE FROM wsc_ahcs_mfinv_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_mfinv_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );

        COMMIT;	 
--Lease Harbor --	
logging_insert('purge_records', 1, 16, ' wsc_ahcs_lhin_txn_line_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_lhin_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_lhin_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );
logging_insert('purge_records', 1, 17, ' wsc_ahcs_lhin_txn_header_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_lhin_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_lhin_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );

        COMMIT;
--Concur --	
logging_insert('purge_records', 1, 18, ' wsc_ahcs_cncr_txn_line_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_cncr_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_cncr_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );

logging_insert('purge_records', 1, 19, ' wsc_ahcs_cncr_txn_header_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_cncr_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_cncr_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );

        COMMIT;
	 --ECLIPSE --	

logging_insert('purge_records', 1, 20, ' wsc_ahcs_eclipse_txn_line_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_eclipse_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_eclipse_txn_line_t ln
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = ln.batch_id
                    AND sts.header_id = ln.header_id
                    AND sts.line_id = ln.line_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );
logging_insert('purge_records', 1, 21, ' wsc_ahcs_eclipse_txn_header_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_eclipse_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_success_days
                    AND accounting_status = 'CRE_ACC_SUCCESS'
            );

        DELETE FROM wsc_ahcs_eclipse_txn_header_t hdr
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t sts
                WHERE
                        sts.batch_id = hdr.batch_id
                    AND sts.header_id = hdr.header_id
                    AND sts.last_updated_date < sysdate - p_error_days
            );

        COMMIT;
        
         --- ****MF AP PURGING****

logging_insert('purge_records', 1, 22, ' WSC_AHCS_MFAP_TXN_LINE_T', NULL,sysdate);

		DELETE FROM WSC_AHCS_MFAP_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_MFAP_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ;     
logging_insert('purge_records', 1, 23, ' WSC_AHCS_MFAP_TXN_HEADER_T', NULL,sysdate);

       DELETE FROM WSC_AHCS_MFAP_TXN_HEADER_T  hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_MFAP_TXN_HEADER_T  hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ; 
			  
			 COMMIT;  
			 
			   --- ****CLOUDPAY PURGING****

logging_insert('purge_records', 1, 24, ' WSC_AHCS_CP_TXN_LINE_T', NULL,sysdate);

		DELETE FROM WSC_AHCS_CP_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_CP_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ;     

logging_insert('purge_records', 1, 25, ' WSC_AHCS_CP_TXN_HEADER_T', NULL,sysdate);
       DELETE FROM WSC_AHCS_CP_TXN_HEADER_T  hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_CP_TXN_HEADER_T  hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ; 
			  
			 COMMIT;  
   --- ****TW PURGING****

logging_insert('purge_records', 1, 26, ' WSC_AHCS_TW_TXN_LINE_T', NULL,sysdate);

		DELETE FROM WSC_AHCS_TW_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_TW_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ;     
logging_insert('purge_records', 1, 27, ' WSC_AHCS_TW_TXN_HEADER_T', NULL,sysdate);

       DELETE FROM WSC_AHCS_TW_TXN_HEADER_T  hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_TW_TXN_HEADER_T  hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ; 
			  
			 COMMIT;  
			 
			 
	 --- ****PSFA PURGING****

logging_insert('purge_records', 1, 28, ' WSC_AHCS_PSFA_TXN_LINE_T', NULL,sysdate);

		DELETE FROM WSC_AHCS_PSFA_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_PSFA_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ;     
logging_insert('purge_records', 1, 29, ' WSC_AHCS_PSFA_TXN_HEADER_T', NULL,sysdate);

       DELETE FROM WSC_AHCS_PSFA_TXN_HEADER_T  hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_PSFA_TXN_HEADER_T  hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ; 
			  
			 COMMIT; 		 


 --- ****SXE PURGING****

logging_insert('purge_records', 1, 30, ' WSC_AHCS_SXE_TXN_LINE_T', NULL,sysdate);

		DELETE FROM WSC_AHCS_SXE_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_SXE_TXN_LINE_T ln
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = ln.batch_id
              and sts.header_id = ln.header_id
              and sts.line_id = ln.line_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ;     
logging_insert('purge_records', 1, 31, ' WSC_AHCS_SXE_TXN_HEADER_T', NULL,sysdate);

       DELETE FROM WSC_AHCS_SXE_TXN_HEADER_T  hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_success_days
              AND ACCOUNTING_STATUS = 'CRE_ACC_SUCCESS') ; 

       DELETE FROM WSC_AHCS_SXE_TXN_HEADER_T  hdr
        WHERE EXISTS 
          (select 1 from WSC_AHCS_INT_STATUS_T sts 
            where sts.batch_id = hdr.batch_id
              and sts.header_id = hdr.header_id
              and sts.last_updated_date < SYSDATE - p_error_days
              ) ; 
			  
			 COMMIT; 
             ---common tables purging---
logging_insert('purge_records', 1, 32, ' wsc_ahcs_int_status_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_int_status_t
        WHERE
                last_updated_date < sysdate - p_success_days
            AND accounting_status = 'CRE_ACC_SUCCESS';
logging_insert('purge_records', 1, 33, ' wsc_ahcs_int_status_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_int_status_t
        WHERE
            last_updated_date < sysdate - p_error_days;

logging_insert('purge_records', 1, 34, ' wsc_ahcs_int_control_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_int_control_t
        WHERE
            last_updated_date < sysdate - p_error_days;
--control_line table ?
        COMMIT;
logging_insert('purge_records', 1, 35, ' wsc_ahcs_int_logging_t', NULL,sysdate);
        
        DELETE FROM wsc_ahcs_int_logging_t
        WHERE
            CREATION_DATE < sysdate - p_error_days;
logging_insert('purge_records', 1, 36, ' wsc_ahcs_int_control_line_t', NULL,sysdate);

        DELETE FROM wsc_ahcs_int_control_line_t
        WHERE
            LAST_UPDATE_DATE < sysdate - p_error_days;
        
        commit;
logging_insert('purge_records', 1, 37, ' gather_schema_stats', NULL,sysdate);
        
        BEGIN
            dbms_stats.gather_schema_stats('FININT', dbms_stats.auto_sample_size);
        END;

logging_insert('purge_records', 1, 38, ' gather_schema_stats end', NULL,sysdate);

    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(sqlerrm);
            lv_errm := sqlerrm;
            logging_insert('purge_records', 1, 40, lv_errm, NULL,sysdate);

    END purge_records;

    PROCEDURE purge_records_async (
        p_success_days IN NUMBER,
        p_error_days   IN NUMBER
    ) IS
    BEGIN
        dbms_output.put_line('Before post_booking_flow_job');
        dbms_scheduler.create_job(job_name => 'PURGE_RECORDS'||to_char(sysdate,'DDMMYYYYHH24MISS'), job_type => 'PLSQL_BLOCK', job_action => 'BEGIN 
       wsc_ahcs_purging_pkg.PURGE_RECORDS('
                                                                                                        || p_success_days
                                                                                                        || ','
                                                                                                        || p_error_days
                                                                                                        || ');
     END;', enabled => true, auto_drop => true,
                                 comments => 'Purging Records from AHCS Staging Tables');

    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(sqlerrm);
    END purge_records_async;

END wsc_ahcs_purging_pkg;
/