create or replace PACKAGE BODY wsc_ahcs_purging_pkg IS

    PROCEDURE purge_records (
        p_success_days IN NUMBER,
        p_error_days   IN NUMBER
    ) IS
        lv_days VARCHAR2(100);
        lv_errm VARCHAR2(4000);
		lv_err_flag VARCHAR2(1):='N'; ----<Added this as part of OC-89>
	----Added Exception 	
    BEGIN
        logging_insert('purge_records', 1, 1, 'insert wsc_ahcs_dashboard1_audit_t', NULL,
                      sysdate);
    ---***Insert into Dashboard Audit table
        BEGIN
            INSERT INTO wsc_ahcs_dashboard1_audit_t (
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
            )
                (
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

            COMMIT;
        END;

		--**** AP PURGING****  
        logging_insert('purge_records', 1, 2, 'wsc_ahcs_ap_txn_line_t_success', NULL,sysdate);

		BEGIN

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

		logging_insert('purge_records', 1, 3, 'wsc_ahcs_ap_txn_line_t_error', NULL,sysdate);

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
        EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:='Purging Error for wsc_ahcs_ap_txn_line_t';
		END;


		logging_insert('purge_records', 1, 4, 'wsc_ahcs_ap_txn_header_t_SUCCESS', NULL,sysdate);

		BEGIN
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

		logging_insert('purge_records', 1, 5, 'wsc_ahcs_ap_txn_header_t_ERROR', NULL,sysdate);

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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_ap_txn_line_t',1,4000);
		END;


		   -- ****AR PURGING****
        logging_insert('purge_records', 1, 6, 'wsc_ahcs_ar_txn_line_t_SUCCESS', NULL,sysdate);
        BEGIN

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
		COMMIT;

		logging_insert('purge_records', 1, 7, 'wsc_ahcs_ar_txn_line_t_ERROR', NULL,sysdate);
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
		COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_ar_txn_line_t',1,4000);
		END;


		logging_insert('purge_records', 1, 8, 'wsc_ahcs_ar_txn_header_t_SUCCESS', NULL,sysdate);
        BEGIN

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
		COMMIT;

		logging_insert('purge_records', 1, 9, 'wsc_ahcs_ar_txn_header_t_ERROR', NULL,sysdate);
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_ar_txn_header_t',1,4000);
		END;

	   -- ****POC PURGING****
        logging_insert('purge_records', 1, 10, ' wsc_ahcs_poc_txn_line_t_SUCCESS', NULL,sysdate);
		BEGIN

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
		COMMIT;

		logging_insert('purge_records', 1, 11, 'wsc_ahcs_poc_txn_line_t_ERROR', NULL,sysdate);

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
		COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_poc_txn_line_t',1,4000);
		END;



        logging_insert('purge_records', 1, 12, 'wsc_ahcs_poc_txn_header_t_SUCCESS', NULL,sysdate);
		BEGIN

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
		COMMIT;

		logging_insert('purge_records', 1, 13, 'wsc_ahcs_poc_txn_header_t_error', NULL,sysdate);

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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_poc_txn_header_t',1,4000);
		END;


    --- ****FA PURGING****

        logging_insert('purge_records', 1, 14, 'wsc_ahcs_fa_txn_line_t_success', NULL,sysdate);
		BEGIN

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
		COMMIT;

		logging_insert('purge_records', 1, 15, 'wsc_ahcs_fa_txn_line_t_error', NULL,sysdate);

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
		commit;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_fa_txn_line_t',1,4000);
		END;


        logging_insert('purge_records', 1, 16, 'wsc_ahcs_fa_txn_header_t_success', NULL,sysdate);
		BEGIN

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
		commit;

		logging_insert('purge_records', 1, 17, 'wsc_ahcs_fa_txn_header_t_error', NULL,sysdate);
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_fa_txn_header_t',1,4000);
		END;



	   --- ****CENTRL PURGING****

        logging_insert('purge_records', 1, 18, 'wsc_ahcs_central_txn_line_t_success', NULL,sysdate);
		BEGIN

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
		commit;

		logging_insert('purge_records', 1, 19, 'wsc_ahcs_central_txn_line_t_error', NULL,sysdate);
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
		commit;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_central_txn_line_t',1,4000);
		END;



        logging_insert('purge_records', 1, 20, 'wsc_ahcs_central_txn_header_t_success', NULL,sysdate);
		BEGIN

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
		commit;

		logging_insert('purge_records', 1, 21, 'wsc_ahcs_central_txn_header_t_error', NULL,sysdate);
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_central_txn_header_t',1,4000);
		END;

		-- MF AR--	
        logging_insert('purge_records', 1, 22, 'wsc_ahcs_mfar_txn_line_t_success', NULL,sysdate);
		BEGIN

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
		commit;

		logging_insert('purge_records', 1, 23, 'wsc_ahcs_mfar_txn_line_t_error', NULL,sysdate);
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
		commit;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_mfar_txn_line_t',1,4000);
		END;


        logging_insert('purge_records', 1, 24, 'wsc_ahcs_mfar_txn_header_t_success', NULL,sysdate);
        BEGIN

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
		commit;

		logging_insert('purge_records', 1, 25, 'wsc_ahcs_mfar_txn_header_t_error', NULL,sysdate);
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_mfar_txn_header_t',1,4000);
		END;



		--MF INV --	
        logging_insert('purge_records', 1, 26, 'wsc_ahcs_mfinv_txn_line_t_success', NULL,sysdate);
		BEGIN

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
		commit;

		logging_insert('purge_records', 1, 27, 'wsc_ahcs_mfinv_txn_line_t_error', NULL,sysdate);
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
		commit;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_mfinv_txn_line_t',1,4000);
		END;



        logging_insert('purge_records', 1, 28, 'wsc_ahcs_mfinv_txn_header_t_success', NULL,sysdate);
		BEGIN

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
		commit;

		logging_insert('purge_records', 1, 29, 'wsc_ahcs_mfinv_txn_header_t_error', NULL,sysdate);
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_mfinv_txn_header_t',1,4000);
		END;


		--Lease Harbor --	
        logging_insert('purge_records', 1, 30, 'wsc_ahcs_lhin_txn_line_t_success', NULL,sysdate);
        BEGIN

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
		commit;

		logging_insert('purge_records', 1, 31, 'wsc_ahcs_lhin_txn_line_t_error', NULL,sysdate);
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
		commit;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_lhin_txn_line_t',1,4000);
		END;


        logging_insert('purge_records', 1, 32, 'wsc_ahcs_lhin_txn_header_t_success', NULL,sysdate);
		BEGIN

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
		COMMit;

		logging_insert('purge_records', 1, 33, 'wsc_ahcs_lhin_txn_header_t_error', NULL,sysdate);

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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_lhin_txn_header_t',1,4000);
		END;


	--Concur --	

		logging_insert('purge_records', 1, 34, 'wsc_ahcs_cncr_txn_line_t_success', NULL,sysdate);
		BEGIN

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
		commit;

		logging_insert('purge_records', 1, 35, 'wsc_ahcs_cncr_txn_line_t_error', NULL,sysdate);
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
		COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_cncr_txn_line_t',1,4000);
		END;

        logging_insert('purge_records', 1, 36, 'wsc_ahcs_cncr_txn_header_t_success', NULL,sysdate);
		BEGIN

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
		commit;

		logging_insert('purge_records', 1, 37, 'wsc_ahcs_cncr_txn_header_t_error', NULL,sysdate);
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_cncr_txn_header_t',1,4000);
		END;


	 --ECLIPSE --	

		logging_insert('purge_records', 1, 38, 'wsc_ahcs_eclipse_txn_line_t_success', NULL,sysdate);
		BEGIN

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
		COMMIT;

		logging_insert('purge_records', 1, 39, 'wsc_ahcs_eclipse_txn_line_t_error', NULL,sysdate);
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
		commit;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_eclipse_txn_line_t',1,4000);
		END;

        logging_insert('purge_records', 1, 40, 'wsc_ahcs_eclipse_txn_header_t_success', NULL,sysdate);
        BEGIN

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
		commit;

		logging_insert('purge_records', 1, 41, 'wsc_ahcs_eclipse_txn_header_t_error', NULL,sysdate);
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_eclipse_txn_header_t',1,4000);
		END;
         --- ****MF AP PURGING****

        logging_insert('purge_records', 1, 42, 'wsc_ahcs_mfap_txn_line_t_success', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_ahcs_mfap_txn_line_t ln
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

		logging_insert('purge_records', 1, 43, 'wsc_ahcs_mfap_txn_line_t_error', NULL,sysdate);
        DELETE FROM wsc_ahcs_mfap_txn_line_t ln
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_mfap_txn_line_t',1,4000);
		END;


        logging_insert('purge_records', 1, 44, 'wsc_ahcs_mfap_txn_header_t_success', NULL,sysdate);
        BEGIN

		DELETE FROM wsc_ahcs_mfap_txn_header_t hdr
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

		logging_insert('purge_records', 1, 45, 'wsc_ahcs_mfap_txn_header_t_error', NULL,sysdate);
        DELETE FROM wsc_ahcs_mfap_txn_header_t hdr
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_mfap_txn_header_t',1,4000);
		END;

			   --- ****CLOUDPAY PURGING****

        logging_insert('purge_records', 1, 46, 'wsc_ahcs_cp_txn_line_t_success', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_ahcs_cp_txn_line_t ln
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

		logging_insert('purge_records', 1, 47, 'wsc_ahcs_cp_txn_line_t_error', NULL,sysdate);
        DELETE FROM wsc_ahcs_cp_txn_line_t ln
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_cp_txn_line_t',1,4000);
		END;


        logging_insert('purge_records', 1, 48, 'wsc_ahcs_cp_txn_header_t_success', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_ahcs_cp_txn_header_t hdr
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

		logging_insert('purge_records', 1, 49, 'wsc_ahcs_cp_txn_header_t_error', NULL,sysdate);
        DELETE FROM wsc_ahcs_cp_txn_header_t hdr
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_cp_txn_header_t',1,4000);
		END;

   --- ****TW PURGING****

        logging_insert('purge_records', 1, 50, 'wsc_ahcs_tw_txn_line_t_success', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_ahcs_tw_txn_line_t ln
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

		logging_insert('purge_records', 1, 51, 'wsc_ahcs_tw_txn_line_t_error', NULL,sysdate);
        DELETE FROM wsc_ahcs_tw_txn_line_t ln
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_tw_txn_line_t',1,4000);
		END;


        logging_insert('purge_records', 1, 52, 'wsc_ahcs_tw_txn_header_t_success', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_ahcs_tw_txn_header_t hdr
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

        DELETE FROM wsc_ahcs_tw_txn_header_t hdr
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_tw_txn_header_t',1,4000);
		END;

	 --- ****PSFA PURGING****

        logging_insert('purge_records', 1, 53, 'wsc_ahcs_psfa_txn_line_t', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_ahcs_psfa_txn_line_t ln
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

        DELETE FROM wsc_ahcs_psfa_txn_line_t ln
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
		commit;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_psfa_txn_line_t',1,4000);
		END;

        logging_insert('purge_records', 1, 54, 'wsc_ahcs_psfa_txn_header_t', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_ahcs_psfa_txn_header_t hdr
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

        DELETE FROM wsc_ahcs_psfa_txn_header_t hdr
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_psfa_txn_header_t',1,4000);
		END;


 --- ****SXE PURGING****

        logging_insert('purge_records', 1, 56, 'wsc_ahcs_sxe_txn_line_t', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_ahcs_sxe_txn_line_t ln
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

        DELETE FROM wsc_ahcs_sxe_txn_line_t ln
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_sxe_txn_line_t',1,4000);
		END;


        logging_insert('purge_records', 1, 57, 'wsc_ahcs_sxe_txn_header_t', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_ahcs_sxe_txn_header_t hdr
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

        DELETE FROM wsc_ahcs_sxe_txn_header_t hdr
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

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_sxe_txn_header_t',1,4000);
		END;

--- ****LSI tables PURGING Added as part of OC-131 --
	----changes start here----

        logging_insert('purge_records', 1, 58, 'wsc_ahcs_lsi_ap_ar_t', NULL,sysdate);

        BEGIN																		----------<Added >
            DELETE FROM wsc_ahcs_lsi_ap_ar_t apar
            WHERE
                batch_id IN (
                    SELECT
                        batch_id
                    FROM
                        wsc_ahcs_lsi_control_t lsi
                    WHERE
                            lsi.ahcs_import_status = 'SUCCESS'
                        AND lsi.batch_id = apar.batch_id
                        AND lsi.ahcs_final_count = TO_NUMBER(substr(lsi.matched_count,
                                                                    instr(lsi.matched_count, '/', 1, 1) + 1))
                        AND lsi.last_updated_date < sysdate - p_success_days
                );

            COMMIT;



        DELETE FROM wsc_ahcs_lsi_ap_ar_t apar
        WHERE
            batch_id IN (
                SELECT
                    batch_id
                FROM
                    wsc_ahcs_lsi_control_t lsi
                WHERE
                        lsi.batch_id = apar.batch_id
                    AND ( lsi.ahcs_import_status = 'ERROR'
                          OR lsi.ahcs_import_status = 'WARNING' )
                    AND lsi.ahcs_final_count = TO_NUMBER(substr(lsi.matched_count,
                                                                instr(lsi.matched_count, '/', 1, 1) + 1))
                    AND lsi.last_updated_date < sysdate - p_error_days
            );

        COMMIT;
		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_lsi_ap_ar_t',1,4000);      
        END;			  


		logging_insert('purge_records', 1, 59, 'wsc_ahcs_lsi_ap_t', NULL,sysdate);
		begin 

        DELETE FROM wsc_ahcs_lsi_ap_t ap
        WHERE
            batch_id IN (
                SELECT
                    batch_id
                FROM
                    wsc_ahcs_lsi_control_t lsi
                WHERE
                        lsi.ahcs_import_status = 'SUCCESS'
                    AND lsi.batch_id = ap.batch_id
                    AND lsi.ahcs_final_count = TO_NUMBER(substr(lsi.matched_count,
                                                                instr(lsi.matched_count, '/', 1, 1) + 1))
                    AND lsi.last_updated_date < sysdate - p_success_days
            );

        COMMIT;
        DELETE FROM wsc_ahcs_lsi_ap_t ap
        WHERE
            batch_id IN (
                SELECT
                    batch_id
                FROM
                    wsc_ahcs_lsi_control_t lsi
                WHERE
                        lsi.batch_id = ap.batch_id
                    AND ( lsi.ahcs_import_status = 'ERROR'
                          OR lsi.ahcs_import_status = 'WARNING' )
                    AND lsi.ahcs_final_count = TO_NUMBER(substr(lsi.matched_count,
                                                                instr(lsi.matched_count, '/', 1, 1) + 1))
                    AND lsi.last_updated_date < sysdate - p_error_days
            );

        COMMIT;
        EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_lsi_ap_t',1,4000);      
        END;


		logging_insert('purge_records', 1, 60, 'wsc_ahcs_lsi_ar_t', NULL,sysdate);
		BEGIN
        DELETE FROM wsc_ahcs_lsi_ar_t ar
        WHERE
            batch_id IN (
                SELECT
                    batch_id
                FROM
                    wsc_ahcs_lsi_control_t lsi
                WHERE
                        lsi.ahcs_import_status = 'SUCCESS'
                    AND lsi.batch_id = ar.batch_id
                    AND lsi.ahcs_final_count = TO_NUMBER(substr(lsi.matched_count,
                                                                instr(lsi.matched_count, '/', 1, 1) + 1))
                    AND lsi.last_updated_date < sysdate - p_success_days
            );

        COMMIT;
        DELETE FROM wsc_ahcs_lsi_ar_t ar
        WHERE
            batch_id IN (
                SELECT
                    batch_id
                FROM
                    wsc_ahcs_lsi_control_t lsi
                WHERE
                        lsi.batch_id = ar.batch_id
                    AND ( lsi.ahcs_import_status = 'ERROR'
                          OR lsi.ahcs_import_status = 'WARNING' )
                    AND lsi.ahcs_final_count = TO_NUMBER(substr(lsi.matched_count,
                                                                instr(lsi.matched_count, '/', 1, 1) + 1))
                    AND lsi.last_updated_date < sysdate - p_error_days
            );

        COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_lsi_ar_t',1,4000);      
        END;


        logging_insert('purge_records', 1, 61, 'WSC_AHCS_LSI_NETTING_ENTRY_HEADERS_T', NULL,sysdate);
		BEGIN
        DELETE FROM wsc_ahcs_lsi_netting_entry_headers_t net
        WHERE
            batch_id IN (
                SELECT
                    batch_id
                FROM
                    wsc_ahcs_lsi_control_t lsi
                WHERE
                        lsi.ahcs_import_status = 'SUCCESS'
                    AND lsi.batch_id = net.batch_id
                    AND lsi.ahcs_final_count = TO_NUMBER(substr(lsi.matched_count,
                                                                instr(lsi.matched_count, '/', 1, 1) + 1))
                    AND lsi.last_updated_date < sysdate - p_success_days
            );

        COMMIT;
        DELETE FROM wsc_ahcs_lsi_netting_entry_headers_t net
        WHERE
            batch_id IN (
                SELECT
                    batch_id
                FROM
                    wsc_ahcs_lsi_control_t lsi
                WHERE
                        lsi.batch_id = net.batch_id
                    AND ( lsi.ahcs_import_status = 'WARNING'
                          OR lsi.ahcs_import_status = 'ERROR' )
                    AND lsi.ahcs_final_count = TO_NUMBER(substr(lsi.matched_count,
                                                                instr(lsi.matched_count, '/', 1, 1) + 1))
                    AND lsi.last_updated_date < sysdate - p_error_days
            );

        COMMIT;
		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_lsi_netting_entry_headers_t',1,4000);      
        END;


        logging_insert('purge_records', 1, 62, 'WSC_AHCS_LSI_NETTING_ENTRY_T', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_ahcs_lsi_netting_entry_t net
        WHERE
            batch_id IN (
                SELECT
                    batch_id
                FROM
                    wsc_ahcs_lsi_control_t lsi
                WHERE
                        lsi.ahcs_import_status = 'SUCCESS'
                    AND lsi.batch_id = net.batch_id
                    AND lsi.ahcs_final_count = TO_NUMBER(substr(lsi.matched_count,
                                                                instr(lsi.matched_count, '/', 1, 1) + 1))
                    AND lsi.last_updated_date < sysdate - p_success_days
            );

        COMMIT;

		DELETE FROM wsc_ahcs_lsi_netting_entry_t net
        WHERE
            batch_id IN (
                SELECT
                    batch_id
                FROM
                    wsc_ahcs_lsi_control_t lsi
                WHERE
                        lsi.batch_id = net.batch_id
                    AND ( lsi.ahcs_import_status = 'ERROR'
                          OR lsi.ahcs_import_status = 'WARNING' )
                    AND lsi.ahcs_final_count = TO_NUMBER(substr(lsi.matched_count,
                                                                instr(lsi.matched_count, '/', 1, 1) + 1))
                    AND lsi.last_updated_date < sysdate - p_error_days
            );

        COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_lsi_netting_entry_t',1,4000);      
        END;

        logging_insert('purge_records', 1, 63, 'WSC_AHCS_LSI_INVOICE_FOR_CM_H_T', NULL,sysdate);
		BEGIN
        DELETE FROM wsc_ahcs_lsi_invoice_for_cm_h_t net
        WHERE
            batch_id IN (
                SELECT
                    batch_id
                FROM
                    wsc_ahcs_lsi_control_t lsi
                WHERE
                        lsi.ahcs_import_status = 'SUCCESS'
                    AND lsi.batch_id = net.batch_id
                    AND lsi.ahcs_final_count = TO_NUMBER(substr(lsi.matched_count,
                                                                instr(lsi.matched_count, '/', 1, 1) + 1))
                    AND lsi.last_updated_date < sysdate - p_success_days
            );

        COMMIT;

        DELETE FROM wsc_ahcs_lsi_invoice_for_cm_h_t net
        WHERE
            batch_id IN (
                SELECT
                    batch_id
                FROM
                    wsc_ahcs_lsi_control_t lsi
                WHERE
                        lsi.batch_id = net.batch_id
                    AND ( lsi.ahcs_import_status = 'ERROR'
                          OR lsi.ahcs_import_status = 'WARNING' )
                    AND to_char(lsi.ahcs_final_count) = TO_NUMBER(substr(lsi.matched_count,
                                                                         instr(lsi.matched_count, '/', 1, 1) + 1))
                    AND lsi.last_updated_date < sysdate - p_error_days
            );

        COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_lsi_invoice_for_cm_h_t',1,4000);      
        END;

		logging_insert('purge_records', 1, 64, 'WSC_AHCS_LSI_INVOICE_FOR_CM_L_T', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_ahcs_lsi_invoice_for_cm_l_t net
        WHERE
            batch_id IN (
                SELECT
                    batch_id
                FROM
                    wsc_ahcs_lsi_control_t lsi
                WHERE
                        lsi.ahcs_import_status = 'SUCCESS'
                    AND lsi.batch_id = net.batch_id
                    AND lsi.ahcs_final_count = TO_NUMBER(substr(lsi.matched_count,
                                                                instr(lsi.matched_count, '/', 1, 1) + 1))
                    AND lsi.last_updated_date < sysdate - p_success_days
            );

        COMMIT;

        DELETE FROM wsc_ahcs_lsi_invoice_for_cm_l_t net
        WHERE
            batch_id IN (
                SELECT
                    batch_id
                FROM
                    wsc_ahcs_lsi_control_t lsi
                WHERE
                        lsi.batch_id = net.batch_id
                    AND ( lsi.ahcs_import_status = 'ERROR'
                          OR lsi.ahcs_import_status = 'WARNING' )
                    AND lsi.ahcs_final_count = TO_NUMBER(substr(lsi.matched_count,
                                                                instr(lsi.matched_count, '/', 1, 1) + 1))
                    AND lsi.last_updated_date < sysdate - p_error_days
            );

        COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_lsi_invoice_for_cm_l_t',1,4000);      
        END;


		logging_insert('purge_records', 1, 65, 'WSC_AHCS_LSI_JOURNAL_T', NULL,sysdate);
        BEGIN

		DELETE FROM wsc_ahcs_lsi_journal_t net
        WHERE
            batch_id IN (
                SELECT
                    batch_id
                FROM
                    wsc_ahcs_lsi_control_t lsi
                WHERE
                        lsi.ahcs_import_status = 'SUCCESS'
                    AND lsi.batch_id = net.batch_id
                    AND lsi.ahcs_final_count = TO_NUMBER(substr(lsi.matched_count,
                                                                instr(lsi.matched_count, '/', 1, 1) + 1))
                    AND lsi.last_updated_date < sysdate - p_success_days
            );

        COMMIT;

        DELETE FROM wsc_ahcs_lsi_journal_t net
        WHERE
            batch_id IN (
                SELECT
                    batch_id
                FROM
                    wsc_ahcs_lsi_control_t lsi
                WHERE
                        lsi.batch_id = net.batch_id
                    AND ( lsi.ahcs_import_status = 'ERROR'
                          OR lsi.ahcs_import_status = 'WARNING' )
                    AND lsi.ahcs_final_count = TO_NUMBER(substr(lsi.matched_count,
                                                                instr(lsi.matched_count, '/', 1, 1) + 1))
                    AND lsi.last_updated_date < sysdate - p_error_days
            );

        COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_lsi_journal_t',1,4000);      
        END;


		logging_insert('purge_records', 1, 66, 'WSC_AHCS_LSI_EXCHANGE_RATE_T', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_ahcs_lsi_exchange_rate_t
        WHERE
            to_char(TO_DATE(conversion_date, 'YYYY-MM-DD'),
                    'DD-MON-YY') < sysdate - p_success_days;

        COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_lsi_exchange_rate_t',1,4000);      
        END;

--- ****LSI tables PURGING Added as part of OC-131 --
	----changes end here----


--- ****INTER INTRA COMPANY PURGING Added as a part of OC-132--
	----changes starts here----

        logging_insert('purge_records', 1, 67, 'wsc_inter_ic_mapping_t', NULL, sysdate);
		BEGIN

        DELETE FROM wsc_inter_ic_mapping_t ic
        WHERE
            EXISTS (
                SELECT
                    batch_id
                FROM
                    wsc_inter_intra_company_file_hdr_t
                WHERE
                    ic_import_status = 'SUCCEEDED'
             )
             AND ic.last_update_date < sysdate - p_success_days;


        COMMIT;

        DELETE FROM wsc_inter_ic_mapping_t icm
        WHERE
            EXISTS (
                SELECT
                    batch_id
                FROM
                    wsc_inter_intra_company_file_hdr_t
                WHERE
                    ic_import_status = 'WARNING'
                    OR ic_import_status = 'ERROR'
             )
			AND icm.last_update_date < sysdate - p_error_days;


        COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_inter_ic_mapping_t',1,4000);      
        END;


		logging_insert('purge_records', 1, 68, 'wsc_inter_intra_company_file_hdr_t', NULL, sysdate);
        BEGIN

		DELETE FROM wsc_inter_intra_company_file_hdr_t
        WHERE
            ( ic_import_status = 'SUCCEEDED'
              AND gl_import_status LIKE '%SUCCEEDED%'
              AND gl_import_status NOT LIKE '%WARNING%' )
            OR ( gl_import_status LIKE '%SUCCEEDED%'
                 AND gl_import_status NOT LIKE '%WARNING%'
                 AND ic_import_status IS NULL )
            OR ( ic_import_status = 'SUCCEEDED'
                 AND gl_import_status IS NULL )
            AND last_update_date < sysdate - p_success_days;

        COMMIT;

        DELETE FROM wsc_inter_intra_company_file_hdr_t
        WHERE
            ( ic_import_status = 'WARNING'
              AND gl_import_status LIKE '%WARNING%' )
            OR ( gl_import_status LIKE '%WARNING%'
                 AND ic_import_status IS NULL )
            OR ( ic_import_status = 'WARNING'
                 AND gl_import_status IS NULL )
            AND last_update_date < sysdate - p_error_days;

        COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_inter_intra_company_file_hdr_t',1,4000);      
        END;



        logging_insert('purge_records', 1, 69, 'wsc_inter_intra_company_file_line_t', NULL, sysdate);
		BEGIN

        DELETE FROM wsc_inter_intra_company_file_line_t
        WHERE
            EXISTS (
                SELECT
                    batch_id
                FROM
                    wsc_inter_intra_company_file_hdr_t
                WHERE
                    ( ic_import_status = 'SUCCEEDED'
                      AND gl_import_status LIKE '%SUCCEEDED%'
                      AND gl_import_status NOT LIKE '%WARNING%' )
                    OR ( gl_import_status LIKE '%SUCCEEDED%'
                         AND gl_import_status NOT LIKE '%WARNING%'
                         AND ic_import_status IS NULL )
                    OR ( ic_import_status = 'SUCCEEDED'
                         AND gl_import_status IS NULL )
            )
            AND last_update_date < sysdate - p_success_days;

        COMMIT;

		DELETE FROM wsc_inter_intra_company_file_line_t
        WHERE
            EXISTS (
                SELECT
                    batch_id
                FROM
                    wsc_inter_intra_company_file_hdr_t
                WHERE
                    ( ic_import_status = 'WARNING'
                      AND gl_import_status LIKE '%WARNING%' )
                    OR ( gl_import_status LIKE '%WARNING%'
                         AND ic_import_status IS NULL )
                    OR ( ic_import_status = 'WARNING'
                         AND gl_import_status IS NULL )
            )
            AND last_update_date < sysdate - p_error_days;

        COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_inter_intra_company_file_line_t',1,4000);      
        END;


		logging_insert('purge_records', 1, 70, 'wsc_intra_gl_mapping_t', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_intra_gl_mapping_t gl
        WHERE
            EXISTS (
                SELECT
					batch_id
                FROM
                    wsc_inter_intra_company_file_hdr_t
                WHERE
                    gl_import_status LIKE '%SUCCEEDED%'
                    AND gl_import_status NOT LIKE '%WARNING%'
                )
            AND gl.last_update_date < sysdate - p_success_days;


        COMMIT;

		DELETE FROM wsc_intra_gl_mapping_t glm
        WHERE
            EXISTS (
                SELECT
					batch_id
                FROM
					wsc_inter_intra_company_file_hdr_t
                WHERE
                    gl_import_status LIKE '%WARNING%'
                    OR gl_import_status LIKE '%ERROR%'
                )
               AND glm.last_update_date < sysdate - p_error_days;


        COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_intra_gl_mapping_t',1,4000);      
        END;



	--- ****INTER INTRA COMPANY PURGING Added as a part of OC-132--
	----changes ends here----


	----****Common LSI control table added as a part of OC-131 ----
	---- Changes starts here----
        logging_insert('purge_records', 1, 71, ' wsc_ahcs_int_status_t', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_ahcs_lsi_control_t lsit
        WHERE
                lsit.ahcs_import_status = 'SUCCESS'
            AND lsit.last_updated_date < sysdate - p_success_days;

        COMMIT;

		DELETE FROM wsc_ahcs_lsi_control_t lt
        WHERE
            lt.ahcs_import_status = 'ERROR'
            OR lt.ahcs_import_status = 'WARNING'
            AND last_updated_date < sysdate - p_error_days;

        COMMIT; 


		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_lsi_control_t',1,4000);      
        END;

	----Common LSI control table added as a part of OC-131 ----
	---- Changes ends here----


	---common tables purging---
        logging_insert('purge_records', 1, 72, ' wsc_ahcs_int_status_t', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_ahcs_int_status_t
        WHERE
                last_updated_date < sysdate - p_success_days
            AND accounting_status = 'CRE_ACC_SUCCESS';

        COMMIT;


        DELETE FROM wsc_ahcs_int_status_t
        WHERE
            last_updated_date < sysdate - p_error_days;

        COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_int_status_t',1,4000);      
        END;

		logging_insert('purge_records', 1, 73, ' wsc_ahcs_int_control_t', NULL,sysdate);
        BEGIN

		DELETE FROM wsc_ahcs_int_control_t
        WHERE
            last_updated_date < sysdate - p_error_days;

        COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_int_control_t',1,4000);      
        END;

		logging_insert('purge_records', 1, 74, 'wsc_ahcs_int_logging_t', NULL,sysdate);
		BEGIN

        DELETE FROM wsc_ahcs_int_logging_t
        WHERE
            creation_date < sysdate - p_error_days;

        COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_int_logging_t',1,4000);      
        END;

		--control_line table 

        logging_insert('purge_records', 1, 75, ' wsc_ahcs_int_control_line_t', NULL,sysdate);
        BEGIN

		DELETE FROM wsc_ahcs_int_control_line_t
        WHERE
            last_update_date < sysdate - p_error_days;

        COMMIT;

		EXCEPTION
			WHEN OTHERS THEN
				lv_err_flag:='Y';
				lv_errm:=substr(lv_errm ||',wsc_ahcs_int_control_line_t',1,4000);      
        END;



        logging_insert('purge_records', 1, 76, ' gather_schema_stats', NULL,sysdate);
        BEGIN
            dbms_stats.gather_schema_stats('FININT', dbms_stats.auto_sample_size);
        END;

        logging_insert('purge_records', 1, 77, 'gather_schema_stats end', NULL,sysdate);


	----Added below statements as a part of OC-89 ----------		  
        IF lv_err_flag = 'Y' THEN
            wsc_ahcs_int_error_logging.error_logging('-9999', 'INT_PURGE_001', 'PURGE_PROCESS', SUBSTR(lv_errm,1,4000));  
            wsc_ahcs_int_error_logging. ERROR_LOGGING_PURGING_NOTIFICATION ('','INT_PURGE_001','PURGE_PROCESS',SUBSTR(lv_errm,1,4000));
	    END IF;

    EXCEPTION
        WHEN OTHERS THEN
			dbms_output.put_line(sqlerrm);
            lv_errm := sqlerrm;
            logging_insert('purge_records', 1, 79, lv_errm, NULL,sysdate);
		    wsc_ahcs_int_error_logging. ERROR_LOGGING_PURGING_NOTIFICATION ('','INT_PURGE_001','PURGE_PROCESS',SQLERRM);

    END purge_records;

    PROCEDURE purge_records_async (
        p_success_days IN NUMBER,
        p_error_days   IN NUMBER
    ) IS
    BEGIN
        dbms_output.put_line('Before post_booking_flow_job');
        dbms_scheduler.create_job(job_name => 'PURGE_RECORDS' || to_char(sysdate, 'DDMMYYYYHH24MISS'), job_type => 'PLSQL_BLOCK', job_action => 'BEGIN 
       wsc_ahcs_purging_pkg.PURGE_RECORDS('
                                                                                                                                || p_success_days
                                                                                                                                || ','
                                                                                                                                || p_error_days
                                                                                                                                || ');
     END;', enabled => TRUE, auto_drop => TRUE,
                                 comments => 'Purging Records from AHCS Staging Tables');

    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(sqlerrm);
    END purge_records_async;

END wsc_ahcs_purging_pkg;
/