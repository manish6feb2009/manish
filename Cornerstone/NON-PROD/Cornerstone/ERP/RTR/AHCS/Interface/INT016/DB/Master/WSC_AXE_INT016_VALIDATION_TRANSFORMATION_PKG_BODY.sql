create or replace PACKAGE BODY wsc_ahcs_cncr_validation_transformation_pkg AS

    err_msg VARCHAR2(100);

    PROCEDURE data_validation_p (
        p_batch_id IN NUMBER
    ) IS

        lv_header_err_msg  VARCHAR2(2000) := NULL;
        lv_line_err_msg    VARCHAR2(2000) := NULL;
        lv_header_err_flag VARCHAR2(100) := 'false';
        lv_line_err_flag   VARCHAR2(100) := 'false';
        lv_count_sucss     NUMBER := 0;
        retcode            VARCHAR2(50);
        l_system           VARCHAR2(10);
        TYPE wsc_line_col_value_type IS
            VARRAY(13) OF VARCHAR2(50); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING LINE OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        lv_line_col_value  wsc_line_col_value_type := wsc_line_col_value_type('CONSTANT', 'SRC_BATCH_ID', 'BATCH_DATE', 'EMPLOYEE_ID',
 --       'EMPLOYEE_LAST_NAME',
         'EMPLOYEE_FIRST_NAME',-- 'MIDDLE_INITIAL', 
                                                                            'REPORT_ID', 'REPORT_KEY', 'REIMBURSEMENT_CURRENCY_ALPHA_ISE',
                                                                           -- 'REPORT_SUBMIT_DATE',
                                                                             'REPORT_PAYMENT_PROCESSING_DATE', 
                                                                            --'REPORT_NAME',
                                                                            --'REPORT_TOTAL_APPROVED_AMOUNT', 
                                                                             'REPORT_ORG_UNIT_1',
                                                                            'REPORT_ORG_UNIT_2', 
                                                                            --'REPORT_ENTRY_ID', 'REPORT_ENTRY_EXPENSE_TYPE_NAME',
                                                                           -- 'REPORT_ENTRY_DESCRIPTION', 
                                                                             'REPORT_CUSTOM_15',
                                                                          --  'JOURNAL_ACCOUNT_CODE',
                                                                             'NET_ADJUSTED_RECLAIM_AMOUNT');


/************ @@@@@ INITIALIZE HEADER AND LINE FLAG TABLE TYPE VARIABLES TO MATCH THE COUNT OF HEADER AND LINE @@@@@ ************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/

        TYPE wsc_ahcs_cncr_txn_line_type IS
            TABLE OF INTEGER;
        lv_error_cncr_line wsc_ahcs_cncr_txn_line_type := wsc_ahcs_cncr_txn_line_type('1', '1', '1', '1', '1',
                                                                                     '1', '1', '1', '1', '1',
                                                                                     '1', '1', '1', '1', '1',
                                                                                     '1', '1', '1', '1', '1'); 


-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from LINE STAGING TABLETHAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_wsc_cncr_line (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            *
        FROM
            wsc_ahcs_cncr_txn_line_t
        WHERE
            batch_id = cur_p_batch_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/

        CURSOR cur_count_sucss (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            COUNT(1)
        FROM
            wsc_ahcs_int_status_t
        WHERE
                batch_id = cur_p_batch_id
            AND attribute2 = 'VALIDATION_SUCCESS';

        lv_batch_err_flag  VARCHAR2(10) := 'false';
    BEGIN		
		------------------------------------------------------------------------------------------------------------------------------------------------
        -- 1. Start of validation.
        --    Identify transactions wherein header amount does not match with line credits & debits.
        --    Flag status table as follows:-
        --    a) Overall record status         = VALIDATION_FAILED
        --    b) Re-extract required           = 'Y', implying that the record must be re-extracted.
        --    c) Attribute1                    = 'H', flex attribute,implying this to be a header level failure. 
        --    d) Attribute2                    = VALIDATION FAILED, same as that of the line status.
        --
        --    Note: Irrespective of header or line level failure, the source system will re-extract entire header and lines.
        --          Header & line level flag in ATTRIBUTE1 is ONLY FOR the re-extract notification engine to send that line identifer or
        --          or just the header identifier in the re-extract notification to source. This will optimize and cut down on file size.

        ------------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 14, 'Start of validation', NULL,
                      sysdate);
        BEGIN
            logging_insert('Concur', p_batch_id, 15, 'Validate Line mandatory fields start.', NULL,
                          sysdate);

		------------------------------------------------------------------------------------------------------------------------------------------------
        -- 1. Validate line level fields
        --    Identify line level fields that fail data type mismatch.
        --    Flag status table as follows:-
        --    a) Overall record status         = VALIDATION_FAILED
        --    b) Re-extract required           = 'Y', implying that the record must be re-extracted.
        --    c) Attribute1                    = 'L', flex attribute,implying this to be a line level failure. 
        --    d) Attribute2                    = VALIDATION FAILED, same as that of the line status.
        --
        --    Note: Irrespective of header or line level failure, the source system will re-extract entire header and lines.
        --          Header & line level flag in ATTRIBUTE1 is ONLY FOR the re-extract notification engine to send that line identifer or
        --          or just the header identifier in the re-extract notification to source. This will optimize and cut down on file size.
        ------------------------------------------------------------------------------------------------------------------------------------------------

/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
/**** @@@ Review/ Change function name to match data type of colum. Also pass the appropriate column name from the cursor @@@@ ******/
/**** @@@ Add more rows if there are more columns to be validated and match it with right function names                       ******/
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
    --   logging_insert (null,p_batch_id,9,'lv_line_err_flag',null,sysdate);

            FOR wsc_cncr_line IN cur_wsc_cncr_line(p_batch_id) LOOP
                lv_line_err_flag := 'false';
                lv_line_err_msg := NULL;
                lv_error_cncr_line := wsc_ahcs_cncr_txn_line_type('1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1');

                lv_error_cncr_line(1) := is_varchar2_null(wsc_cncr_line.constant);
                lv_error_cncr_line(2) := is_number_null(wsc_cncr_line.src_batch_id);
                lv_error_cncr_line(3) := is_date_null(wsc_cncr_line.batch_date);
                lv_error_cncr_line(4) := is_varchar2_null(wsc_cncr_line.employee_id);
                  --  lv_error_cncr_line(5) := is_varchar2_null(wsc_cncr_line.employee_last_name);
                lv_error_cncr_line(5) := is_varchar2_null(wsc_cncr_line.employee_first_name);
                  --  lv_error_cncr_line(7) := is_varchar2_null(wsc_cncr_line.middle_initial);
                lv_error_cncr_line(6) := is_varchar2_null(wsc_cncr_line.report_id);
                lv_error_cncr_line(7) := is_varchar2_null(wsc_cncr_line.report_key);
                lv_error_cncr_line(8) := is_varchar2_null(wsc_cncr_line.reimbursement_currency_alpha_ise);
                --    lv_error_cncr_line(11) := is_date_null(wsc_cncr_line.report_submit_date);
                lv_error_cncr_line(9) := is_date_null(wsc_cncr_line.report_payment_processing_date);
                --    lv_error_cncr_line(13) := is_varchar2_null(wsc_cncr_line.report_name);
                --    lv_error_cncr_line(14) := is_number_null(wsc_cncr_line.report_total_approved_amount);
                lv_error_cncr_line(10) := is_varchar2_null(wsc_cncr_line.report_org_unit_1);
                lv_error_cncr_line(11) := is_varchar2_null(wsc_cncr_line.report_org_unit_2);
                  --  lv_error_cncr_line(17) := is_varchar2_null(wsc_cncr_line.report_entry_id);
                 --   lv_error_cncr_line(18) := is_varchar2_null(wsc_cncr_line.report_entry_expense_type_name);
                 --   lv_error_cncr_line(19) := is_varchar2_null(wsc_cncr_line.report_entry_description);
                lv_error_cncr_line(12) := is_varchar2_null(wsc_cncr_line.report_custom_15);
                 --   lv_error_cncr_line(21) := is_number_null(wsc_cncr_line.journal_account_code);
                lv_error_cncr_line(13) := is_number_null(wsc_cncr_line.net_adjusted_reclaim_amt);
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
                FOR j IN 1..13 LOOP
                    IF lv_error_cncr_line(j) = 0 THEN
                        lv_line_err_msg := lv_line_err_msg
                                           || '300|Missng value of '
                                           || lv_line_col_value(j)
                                           || '. ';
                        lv_line_err_flag := 'true';
                        lv_batch_err_flag := 'true';
                    END IF;
                END LOOP;

                IF lv_line_err_flag = 'true' THEN
                    UPDATE wsc_ahcs_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = lv_line_err_msg,
                        reextract_required = 'Y',
                        attribute1 = 'L',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        AND status = 'NEW'
                        AND line_id = wsc_cncr_line.line_id;

                END IF;

            END LOOP;

            COMMIT;
            logging_insert('Concur', p_batch_id, 16, 'Validating line mandatory fields ends.', NULL,
                          sysdate);
            IF lv_batch_err_flag = 'true' THEN
                UPDATE wsc_ahcs_int_status_t
                SET
                    attribute1 = 'L',
                    attribute2 = 'VALIDATION_FAILED',
                    last_updated_date = sysdate
                WHERE
                        batch_id = p_batch_id
                    AND status = 'NEW';

                COMMIT;
            END IF;

            logging_insert('Concur', p_batch_id, 17, 'Updating all the records if a single record is failed mandatory validation,ends.',
            NULL,
                          sysdate);
            BEGIN
                logging_insert('Concur', p_batch_id, 18, 'Start updating validation status in status table.', NULL,
                              sysdate);
                UPDATE wsc_ahcs_int_status_t
                SET
                    status = 'VALIDATION_FAILED',
                    error_msg = '300|Missing value of HEADER_ID',
                    reextract_required = 'Y',
                    attribute1 = 'H',
                    attribute2 = 'VALIDATION_FAILED',
                    last_updated_date = sysdate
                WHERE
                        batch_id = p_batch_id
                    AND status = 'NEW'
                    AND header_id IS NULL;

                COMMIT;
                UPDATE wsc_ahcs_int_status_t
                SET
                    status = 'VALIDATION_SUCCESS',
                    last_updated_date = sysdate
                WHERE
                        batch_id = p_batch_id
                    AND status = 'NEW'
                    AND error_msg IS NULL;

                COMMIT;
                logging_insert('Concur', p_batch_id, 19, 'Status field updated in status table.', NULL,
                              sysdate);
                UPDATE wsc_ahcs_int_status_t
                SET
                    attribute2 = 'VALIDATION_SUCCESS',
                    last_updated_date = sysdate
                WHERE
                        batch_id = p_batch_id
                    AND attribute2 IS NULL;

                COMMIT;
                logging_insert('Concur', p_batch_id, 20, 'Attribute2 field updated in status table.', NULL,
                              sysdate);
                OPEN cur_count_sucss(p_batch_id);
                FETCH cur_count_sucss INTO lv_count_sucss;
                CLOSE cur_count_sucss;
                logging_insert('Concur', p_batch_id, 21, 'Count success records.', lv_count_sucss,
                              sysdate);
                IF lv_count_sucss > 0 THEN
                    UPDATE wsc_ahcs_int_control_t
                    SET
                        status = 'VALIDATION_SUCCESS',
                        last_updated_date = sysdate
                    WHERE
                        batch_id = p_batch_id;

                    COMMIT;
                    BEGIN
                        wsc_ahcs_cncr_validation_transformation_pkg.leg_coa_transformation_p(p_batch_id);
                    END;
                ELSE
                    UPDATE wsc_ahcs_int_control_t
                    SET
                        status = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
                    WHERE
                        batch_id = p_batch_id;

                END IF;

                COMMIT;
                logging_insert('Concur', p_batch_id, 60, 'end data_validation', NULL,
                              sysdate);
                logging_insert('Concur', p_batch_id, 80, 'Dashboard Start', NULL,
                              sysdate);
                wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
                logging_insert('Concur', p_batch_id, 81, 'Dashboard End', NULL,
                              sysdate);
            END;

        END;

        DELETE FROM wsc_ahcs_cncr_txn_tmp_t
        WHERE
            batch_id = p_batch_id;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT016', 'Concur', sqlerrm);
    END data_validation_p;

    PROCEDURE leg_coa_transformation_p (
        p_batch_id IN NUMBER
    ) AS
      -- +====================================================================+
      -- | Name             : transform_staging_data_to_AHCS                  |
      -- | Description      : Transforms data read into the staging tables    |
      -- |                    to AHCS format.                                 |
      -- |                    Following transformation will be applied :-     |
      -- |                    1. Derive future state COA based on legacy COA  |
      -- |                       values in staging tables.                    |
      -- |                    2. Derive the ledger associated with the        |
      -- |                       transaction based on the balancing segment   |
      -- |                                                                    |
      -- |                    Transformation will be performed on the basis   |
      -- |                    of batch_id.                                    |
      -- |                    Every file set (header/line) coming from source |
      -- |                    will be mapped to a unique batch_id             |
      -- |                    This procedure will (based on parameter) will   |
      -- |                    transform all (or reprocess eligible) records   |
      -- |                    from the file.                                  |
      -- +====================================================================+
    
    
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    -- The following cursor will retrieve ALL records from lines table that does not target COA combination derived.
    -- All such columns 
    ------------------------------------------------------------------------------------------------------------------------------------------------------
        lv_batch_id                 NUMBER := p_batch_id;
    
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    -- Derive the COA map ID for a given source/ target system value.
    -- COA Map ID will subsequently be used to derive the COA mapping rules that are assigned to this source / target combination.
    ------------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_coa_map_id IS
        SELECT
            coa_map_id,
            coa_map.target_system,
            coa_map.source_system
        FROM
            wsc_gl_coa_map_t       coa_map,
            wsc_ahcs_int_control_t ahcs_control
        WHERE
                upper(coa_map.source_system) = upper(ahcs_control.source_system)
            AND upper(coa_map.target_system) = upper(ahcs_control.target_system)
            AND ahcs_control.batch_id = p_batch_id;
    
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    -- The following cursor will derive the future state COA combination for the given batch_Id for records that have been successfully validated.
    --
    ------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_leg_seg_value IS
        SELECT DISTINCT
            line.leg_coa,
            line.leg_bu,
            line.leg_acct,
            line.leg_dept,
            line.leg_loc,
            line.leg_vendor,
            nvl(line.leg_affiliate, '00000') leg_affiliate
        FROM
            wsc_ahcs_cncr_txn_line_t line
        WHERE
                batch_id = p_batch_id
            AND target_coa IS NULL
            AND src_system = 'ANIXTER'
            AND substr(transaction_number, - 2) <> '_2'
            AND EXISTS (
                SELECT /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */
                    1
                FROM
                    wsc_ahcs_int_status_t status
                WHERE
                        status.batch_id = p_batch_id
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND status.attribute2 = 'VALIDATION_SUCCESS'
            );

        lv_target_coa               VARCHAR2(1000);
    
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
        -- for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_inserting_ccid_table (
            p_src_sytem IN VARCHAR2
        ) IS
        SELECT DISTINCT
            line.leg_coa    leg_coa,
            line.target_coa target_coa,
            line.leg_bu,
            line.leg_acct,
            line.leg_dept,
            line.leg_loc,
            line.leg_vendor,
            line.leg_affiliate,
            line.leg_wes_acct
        FROM
            wsc_ahcs_cncr_txn_line_t line
        WHERE
                line.batch_id = p_batch_id
            AND substr(line.transaction_number, - 2) <> '_2'
            AND line.src_system = p_src_sytem
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        TYPE inserting_ccid_table_type IS
            TABLE OF cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table     inserting_ccid_table_type;
        CURSOR cur_inserting_ccid_table_wes (
            p_src_sytem IN VARCHAR2
        ) IS
        SELECT DISTINCT
            line.leg_coa    leg_coa,
            line.target_coa target_coa,
            line.leg_bu,
           -- line.leg_acct,
          --  line.leg_dept,
            line.leg_loc,
          --  line.leg_vendor,
          --  line.leg_affiliate,
            line.leg_wes_acct
        FROM
            wsc_ahcs_cncr_txn_line_t line
        WHERE
                line.batch_id = p_batch_id
      --      AND substr(line.transaction_number, - 2) <> '_2'
            AND line.src_system = p_src_sytem
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        TYPE inserting_ccid_table_type_wes IS
            TABLE OF cur_inserting_ccid_table_wes%rowtype;
        lv_inserting_ccid_table_wes inserting_ccid_table_type_wes;
    
        ------------------------------------------------------------------------------------------------------------------------------------------------------
        -- The following cursor picks up the distinct ledger/ legal entities that have been transformed successfully with future state COA values.
        -- Ledger name is one of the key defaulting attributes required for processing a journal in AHCS.
        ------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_count_sucss (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            COUNT(1)
        FROM
            wsc_ahcs_int_status_t
        WHERE
                batch_id = cur_p_batch_id
            AND attribute2 = 'TRANSFORM_SUCCESS';
    
        --- @@@@@@@@@@@@@@@@@@@@@@@@   
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will do a similar matching of total debits and credits but will be restricted at line level. 
        -- ONLY debit not matching to credit at transaction level will be detected after validation.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        /******* @@@@@@@@ Modify this cursor to reflect the appropriate line tables. Also verify the column names are correct @@@@@@@ ********/
    
        ------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_to_update_status (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            b.header_id,
            b.batch_id
        FROM
            wsc_ahcs_int_status_t b
        WHERE
                b.status = 'TRANSFORM_FAILED'
            AND b.batch_id = cur_p_batch_id;

        lv_coa_mapid                NUMBER;
        lv_src_system               VARCHAR2(100);
        lv_tgt_system               VARCHAR2(100);
        lv_count_succ               NUMBER;
    BEGIN
        logging_insert('Concur', p_batch_id, 22, 'Transformation start', NULL,
                      sysdate);
--        logging_insert('Concur', p_batch_id, 23, 'Updating target coa and target seg for wesco offset lines start.', NULL,
--                      sysdate);
--    -- Updating wesco offset line for target segments. --
--        UPDATE wsc_ahcs_cncr_txn_line_t line
--        SET
--            ( target_coa,
--              gl_legal_entity,
--              gl_oper_grp,
--              gl_acct,
--              gl_dept,
--              gl_site,
--              gl_ic,
--              gl_projects,
--              gl_fut_1,
--              gl_fut_2 ) = (
--                SELECT
--                    r.target_coa,
--                    regexp_substr(r.target_coa, '[^.]+', 1, 1),
--                    regexp_substr(r.target_coa, '[^.]+', 1, 2),
--                    regexp_substr(r.target_coa, '[^.]+', 1, 3),
--                    regexp_substr(r.target_coa, '[^.]+', 1, 4),
--                    regexp_substr(r.target_coa, '[^.]+', 1, 5),
--                    regexp_substr(r.target_coa, '[^.]+', 1, 6),
--                    regexp_substr(r.target_coa, '[^.]+', 1, 7),
--                    regexp_substr(r.target_coa, '[^.]+', 1, 8),
--                    regexp_substr(r.target_coa, '[^.]+', 1, 9)
--                FROM
--                    wsc_ahcs_cncr_report_grp_t r
--                WHERE
--                    r.report_grp_id = line.report_custom_15
--            )
--        WHERE
--                substr(transaction_number, - 2) = '_2'
--            AND line.batch_id = p_batch_id
--            AND src_system = 'WESCO';
--
--        COMMIT;
        logging_insert('Concur', p_batch_id, 24, 'updating target segs and target_coa for anixter offset lines start.', NULL,
                      sysdate);
-- Update Anixter Offset Lines --
        UPDATE wsc_ahcs_cncr_txn_line_t line
        SET
            ( gl_legal_entity,
              gl_oper_grp,
              gl_acct,
              gl_dept,
              gl_site,
              gl_ic,
              gl_projects,
              gl_fut_1,
              gl_fut_2 ) = (
                SELECT
                    target_segment,
                    regexp_substr(r.target_coa, '[^.]+', 1, 1),
                    regexp_substr(r.target_coa, '[^.]+', 1, 2),
                    regexp_substr(r.target_coa, '[^.]+', 1, 3),
                    regexp_substr(r.target_coa, '[^.]+', 1, 4),
                    regexp_substr(r.target_coa, '[^.]+', 1, 5),
                    regexp_substr(r.target_coa, '[^.]+', 1, 6),
                    regexp_substr(r.target_coa, '[^.]+', 1, 7),
                    regexp_substr(r.target_coa, '[^.]+', 1, 8)
                FROM
                    wsc_ahcs_cncr_report_grp_t r,
                    (
                        SELECT
                            target_segment
                        FROM
                            wsc_gl_coa_segment_value_t
                        WHERE
                           --     rule_id = 51
                                rule_id = (
                                    SELECT
                                        rule_id
                                    FROM
                                        wsc_gl_coa_mapping_rules_t
                                    WHERE
                                        rule_name = 'Anixter - LE - Based on BU'
                                )
                            AND flag = 'Y'
                            AND source_segment1 = line.leg_bu
                    )
                WHERE
                    r.report_grp_id = 'Anixter Offset'
            )
        WHERE
                substr(transaction_number, - 2) = '_2'
            AND line.batch_id = p_batch_id
            AND src_system = 'ANIXTER';

        UPDATE wsc_ahcs_cncr_txn_line_t
        SET
            target_coa = gl_legal_entity
                         || '.'
                         || gl_oper_grp
                         || '.'
                         || gl_acct
                         || '.'
                         || gl_dept
                         || '.'
                         || gl_site
                         || '.'
                         || gl_ic
                         || '.'
                         || gl_projects
                         || '.'
                         || gl_fut_1
                         || '.'
                         || gl_fut_2
        WHERE
                substr(transaction_number, - 2) = '_2'
            AND batch_id = p_batch_id
            AND src_system = 'ANIXTER';

        logging_insert('Concur', p_batch_id, 25, 'updating anixter offset target seg ends.', NULL,
                      sysdate);
        -------------------------------------------------------------------------------------------------------------------------------------------
    --1. Identify the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        -------------------------------------------------------------------------------------------------------------------------------------------
    --2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 26, 'update leg_wes_acct,leg_coa for wesco lines start.', NULL,
                      sysdate);
        UPDATE wsc_ahcs_cncr_txn_line_t line
        SET
            leg_wes_acct = (
                SELECT
                    target_segment
                FROM
                    wsc_gl_coa_segment_value_t
                WHERE
                        rule_id = (
                            SELECT
                                rule_id
                            FROM
                                wsc_gl_coa_mapping_rules_t
                            WHERE
                                rule_name = 'Peoplesoft - Account - Based on Account'
                        )
                    AND flag = 'Y'
                    AND source_segment1 = line.leg_acct
            ),
            leg_coa = leg_bu
                      || '.'
                      || leg_loc
                      || '.'
                      || (
                SELECT
                    target_segment
                FROM
                    wsc_gl_coa_segment_value_t
                WHERE
                        rule_id = (
                            SELECT
                                rule_id
                            FROM
                                wsc_gl_coa_mapping_rules_t
                            WHERE
                                rule_name = 'Peoplesoft - Account - Based on Account'
                        )
                    AND flag = 'Y'
                    AND source_segment1 = line.leg_acct
            )
                      || '.'
                      || '000.000000.000000.000000.'
        WHERE
                src_system = 'WESCO'
     --       AND substr(transaction_number, - 2) <> '_2'
            AND line.batch_id = p_batch_id;

        logging_insert('Concur', p_batch_id, 27, 'update leg_wes_acct,leg_coa in wesco lines ends.', NULL,
                      sysdate);
        logging_insert('Concur', p_batch_id, 28, 'Check data in cache table to find the target coa ', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_cncr_txn_line_t line
            SET
                target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa, decode(line.src_system, 'WESCO', 1, 2)),
                last_update_date = sysdate
            WHERE
                    batch_id = p_batch_id
--                AND line.src_system = 'WESCO'
--                OR ( line.src_system = 'ANIXTER'
                AND substr(line.transaction_number, - 2) <> '_2';

--            UPDATE wsc_ahcs_cncr_txn_line_t line
--            SET
--                target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa, 2),
--                last_update_date = sysdate
--            WHERE
--                    batch_id = p_batch_id
--                AND line.src_system = 'ANIXTER'
--                AND substr(line.transaction_number, - 2) <> '_2';

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Concur', p_batch_id, 28.1, 'Error in Check data in cache table to find', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    --        update target_coa and attribute1 'Y' in ap_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 29, 'Update target_coa and attribute1 for anixter.', NULL,
                      sysdate);
        BEGIN
            FOR lv_leg_seg_value IN cur_leg_seg_value LOOP
                lv_target_coa := replace(wsc_gl_coa_mapping_pkg.coa_mapping('ANIXTER', 'Oracle ERP Cloud', lv_leg_seg_value.leg_bu, lv_leg_seg_value.
                leg_loc, lv_leg_seg_value.leg_dept,
                                                                           lv_leg_seg_value.leg_acct, lv_leg_seg_value.leg_vendor, nvl(
                                                                           lv_leg_seg_value.leg_affiliate, '00000'), NULL, NULL, NULL,
                                                                           NULL), ' ', '');

                UPDATE wsc_ahcs_cncr_txn_line_t line
                SET
                    target_coa = lv_target_coa,
                    attribute1 = 'Y'
                WHERE
                        leg_coa = lv_leg_seg_value.leg_coa
                    AND batch_id = p_batch_id
                    AND target_coa IS NULL;

            END LOOP;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Concur', p_batch_id, 29.1, 'Error in update target_coa and attribute1', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('Concur', p_batch_id, 30, 'update target_coa,attribute1 for wesco.', NULL,
                      sysdate);
        UPDATE wsc_ahcs_cncr_txn_line_t tgt_coa
        SET
            target_coa = wsc_gl_coa_mapping_pkg.coa_mapping('Oracle EBS', 'Oracle ERP Cloud', tgt_coa.leg_bu, tgt_coa.leg_loc, tgt_coa.
            leg_wes_acct,
                                                            '000', NULL, NULL, NULL, NULL,
                                                            NULL, NULL),
            attribute1 = 'Y'
        WHERE
                batch_id = p_batch_id
            AND target_coa IS NULL
            AND src_system = 'WESCO'
       --     AND substr(transaction_number, - 2) <> '_2'
            AND EXISTS (
                SELECT /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */
                    1
                FROM
                    wsc_ahcs_int_status_t status
                WHERE
                        status.batch_id = p_batch_id
                    AND status.batch_id = tgt_coa.batch_id
                    AND status.header_id = tgt_coa.header_id
                    AND status.line_id = tgt_coa.line_id
                    AND status.attribute2 = 'VALIDATION_SUCCESS'
            );

        COMMIT;
    
    --        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 31, 'Insert new target_coa values of anixter.', NULL,
                      sysdate);
        BEGIN
            OPEN cur_inserting_ccid_table('ANIXTER');
            LOOP
                FETCH cur_inserting_ccid_table
                BULK COLLECT INTO lv_inserting_ccid_table LIMIT 100;
                EXIT WHEN lv_inserting_ccid_table.count = 0;
                FORALL i IN 1..lv_inserting_ccid_table.count
                    INSERT INTO wsc_gl_ccid_mapping_t (
                        ccid_value_id,
                        coa_map_id,
                        source_segment,
                        target_segment,
                        creation_date,
                        last_update_date,
                        enable_flag,
                        ui_flag,
                        created_by,
                        last_updated_by,
                        source_segment1,
                        source_segment2,
                        source_segment3,
                        source_segment4,
                        source_segment5,
                        source_segment6,
                        source_segment7,
                        source_segment8,
                        source_segment9,
                        source_segment10
                    ) VALUES (
                        wsc_gl_ccid_mapping_s.NEXTVAL,
                        2,
                        lv_inserting_ccid_table(i).leg_coa,
                        lv_inserting_ccid_table(i).target_coa,
                        sysdate,
                        sysdate,
                        'Y',
                        'N',
                        'Concur',
                        'Concur',
                        lv_inserting_ccid_table(i).leg_bu,
                        lv_inserting_ccid_table(i).leg_loc,
                        lv_inserting_ccid_table(i).leg_dept,
                        lv_inserting_ccid_table(i).leg_acct,
                        lv_inserting_ccid_table(i).leg_vendor,
                        nvl(lv_inserting_ccid_table(i).leg_affiliate, '00000'),
                        NULL,
                        NULL,
                        NULL,
                        NULL
                    );

            END LOOP;

            CLOSE cur_inserting_ccid_table;
            logging_insert('Concur', p_batch_id, 32, 'Insert new target_coa values in cache of wesco ', NULL,
                          sysdate);
            OPEN cur_inserting_ccid_table_wes('WESCO');
            LOOP
                FETCH cur_inserting_ccid_table_wes
                BULK COLLECT INTO lv_inserting_ccid_table_wes LIMIT 100;
                EXIT WHEN lv_inserting_ccid_table_wes.count = 0;
                FORALL i IN 1..lv_inserting_ccid_table_wes.count
                    INSERT INTO wsc_gl_ccid_mapping_t (
                        ccid_value_id,
                        coa_map_id,
                        source_segment,
                        target_segment,
                        creation_date,
                        last_update_date,
                        enable_flag,
                        ui_flag,
                        created_by,
                        last_updated_by,
                        source_segment1,
                        source_segment2,
                        source_segment3,
                        source_segment4,
                        source_segment5,
                        source_segment6,
                        source_segment7,
                        source_segment8,
                        source_segment9,
                        source_segment10
                    ) VALUES (
                        wsc_gl_ccid_mapping_s.NEXTVAL,
                        1,
                        lv_inserting_ccid_table_wes(i).leg_coa,
                        lv_inserting_ccid_table_wes(i).target_coa,
                        sysdate,
                        sysdate,
                        'Y',
                        'N',
                        'Concur',
                        'Concur',
                        lv_inserting_ccid_table_wes(i).leg_bu,
                        lv_inserting_ccid_table_wes(i).leg_loc,
                 --       lv_inserting_ccid_table(i).leg_dept,
                        lv_inserting_ccid_table_wes(i).leg_wes_acct,
                      --  lv_inserting_ccid_table(i).leg_vendor,
                        '000',
                        '000000',
                        '000000',
                        '000000',
                        NULL,
                        NULL,
                        NULL
                    );

            END LOOP;

            CLOSE cur_inserting_ccid_table_wes;
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Concur', p_batch_id, 32.1, 'Error in ccid table insert.', sqlerrm,
                              sysdate);
        END;

        UPDATE wsc_ahcs_cncr_txn_line_t
        SET
            attribute1 = NULL
        WHERE
            batch_id = p_batch_id;

        COMMIT;
    
    --      update ap_line table target segments,  where legal_entity must have their in target_coa
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 33, 'Update concur line table target segments.', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_cncr_txn_line_t
            SET
                gl_legal_entity = substr(target_coa, 1, instr(target_coa, '.', 1, 1) - 1),
                gl_oper_grp = substr(target_coa, instr(target_coa, '.', 1, 1) + 1, instr(target_coa, '.', 1, 2) - instr(target_coa, '.',
                1, 1) - 1),
                gl_acct = substr(target_coa, instr(target_coa, '.', 1, 2) + 1, instr(target_coa, '.', 1, 3) - instr(target_coa, '.', 1,
                2) - 1),
                gl_dept = substr(target_coa, instr(target_coa, '.', 1, 3) + 1, instr(target_coa, '.', 1, 4) - instr(target_coa, '.', 1,
                3) - 1),
                gl_site = substr(target_coa, instr(target_coa, '.', 1, 4) + 1, instr(target_coa, '.', 1, 5) - instr(target_coa, '.', 1,
                4) - 1),
                gl_ic = substr(target_coa, instr(target_coa, '.', 1, 5) + 1, instr(target_coa, '.', 1, 6) - instr(target_coa, '.', 1,
                5) - 1),
                gl_projects = substr(target_coa, instr(target_coa, '.', 1, 6) + 1, instr(target_coa, '.', 1, 7) - instr(target_coa, '.',
                1, 6) - 1),
                gl_fut_1 = substr(target_coa, instr(target_coa, '.', 1, 7) + 1, instr(target_coa, '.', 1, 8) - instr(target_coa, '.',
                1, 7) - 1),
                gl_fut_2 = substr(target_coa, instr(target_coa, '.', 1, 8) + 1),
                last_update_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND substr(target_coa, 1, instr(target_coa, '.', 1, 1) - 1) IS NOT NULL
--                AND ( src_system = 'WESCO'
--                      OR ( src_system = 'ANIXTER'
                AND substr(transaction_number, - 2) <> '_2';

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
                logging_insert('Concur', p_batch_id, 33.1, 'Error in update concur line table target segments', sqlerrm,
                              sysdate);
        END;

        logging_insert('Concur', p_batch_id, 34, 'Override the gl_acct value for wesco with leg_ps_acct value dervied.', NULL,
                      sysdate);
        UPDATE wsc_ahcs_cncr_txn_line_t line
        SET
            gl_acct = (
                SELECT
                    target_segment
                FROM
                    wsc_gl_coa_segment_value_t
                WHERE
                        rule_id = (
                            SELECT
                                rule_id
                            FROM
                                wsc_gl_coa_mapping_rules_t
                            WHERE
                                rule_name = 'Anixter - Account - Based on Account'
                        )
                    AND flag = 'Y'
                    AND line.leg_acct = source_segment4
            ),
            gl_legal_entity = (
                SELECT
                    target_segment
                FROM
                    wsc_gl_coa_segment_value_t
                WHERE
                        rule_id = (
                            SELECT
                                rule_id
                            FROM
                                wsc_gl_coa_mapping_rules_t
                            WHERE
                                rule_name = 'WESCO - LE - LE Based on Branch'
                        )
                    AND flag = 'Y'
                    AND line.leg_loc = source_segment2
            )
        WHERE
                src_system = 'WESCO'
         --   AND substr(line.transaction_number, - 2) <> '_2'
            AND line.batch_id = p_batch_id;

        COMMIT;
        logging_insert('Concur', p_batch_id, 34.1, 'Updating wesco new target_coa.', NULL,
                      sysdate);
        UPDATE wsc_ahcs_cncr_txn_line_t
        SET
            target_coa = gl_legal_entity
                         || '.'
                         || gl_oper_grp
                         || '.'
                         || gl_acct
                         || '.'
                         || gl_dept
                         || '.'
                         || gl_site
                         || '.'
                         || gl_ic
                         || '.'
                         || gl_projects
                         || '.'
                         || gl_fut_1
                         || '.'
                         || gl_fut_2
        WHERE
                batch_id = p_batch_id
            AND src_system = 'WESCO';

        UPDATE (
            SELECT
                status.attribute2,
                status.attribute1,
                status.status,
                status.error_msg,
                status.last_updated_date,
                line.batch_id  bt_id,
                line.header_id hdr_id,
                line.line_id   ln_id
            FROM
                wsc_ahcs_int_status_t    status,
                wsc_ahcs_cncr_txn_line_t line
            WHERE
                    status.batch_id = p_batch_id
                AND status.batch_id = line.batch_id
                AND status.header_id = line.header_id
                AND status.line_id = line.line_id
                AND status.attribute2 = 'VALIDATION_SUCCESS'
                AND line.src_system = 'WESCO'
                AND line.gl_acct IS NULL
                AND line.target_coa LIKE '%.%'
        --        AND substr(line.transaction_number, - 2) <> '_2'
        )
        SET
            attribute1 = 'L',
            attribute2 = 'TRANSFORM_FAILED',
            status = 'TRANSFORM_FAILED',
            error_msg = error_msg || 'Account not found',
            last_updated_date = sysdate;

        COMMIT;
        UPDATE (
            SELECT
                status.attribute2,
                status.attribute1,
                status.status,
                status.error_msg,
                status.last_updated_date,
                line.batch_id  bt_id,
                line.header_id hdr_id,
                line.line_id   ln_id
            FROM
                wsc_ahcs_int_status_t    status,
                wsc_ahcs_cncr_txn_line_t line
            WHERE
                    status.batch_id = p_batch_id
                AND status.batch_id = line.batch_id
                AND status.header_id = line.header_id
                AND status.line_id = line.line_id
                AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                AND line.src_system = 'WESCO'
                AND line.gl_legal_entity IS NULL
                AND line.target_coa LIKE '%.%'
           --     AND substr(line.transaction_number, - 2) <> '_2'
        )
        SET
            attribute1 = 'L',
            attribute2 = 'TRANSFORM_FAILED',
            status = 'TRANSFORM_FAILED',
            error_msg = error_msg || 'Legal Enitity not found',
            last_updated_date = sysdate;

        COMMIT;
    --        if any target_coa is empty in ap_line table will mark it as transform_error in status table
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 35, 'Wesco overide ends,update status table for empty target_coa.', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    status.attribute2,
                    status.attribute1,
                    status.status,
                    status.error_msg,
                    status.last_updated_date,
                    line.batch_id   bt_id,
                    line.header_id  hdr_id,
                    line.line_id    ln_id,
                    line.target_coa trgt_coa
                FROM
                    wsc_ahcs_int_status_t    status,
                    wsc_ahcs_cncr_txn_line_t line
                WHERE
                        status.batch_id = p_batch_id
                    AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND status.attribute2 = 'VALIDATION_SUCCESS'
--                    AND ( line.src_system = 'WESCO'
--                          OR ( line.src_system = 'ANIXTER'
                    AND substr(line.transaction_number, - 2) <> '_2'
            )
            SET
                attribute1 = 'L',
                attribute2 = 'TRANSFORM_FAILED',
                status = 'TRANSFORM_FAILED',
                error_msg = trgt_coa,
                last_updated_date = sysdate;

            COMMIT;
            logging_insert('Concur', p_batch_id, 36, 'Updated attribute2 with TRANSFORM_FAILED status.', NULL,
                          sysdate);
            FOR rcur_to_update_status IN cur_to_update_status(p_batch_id) LOOP
                UPDATE wsc_ahcs_int_status_t
                SET
                    attribute2 = 'TRANSFORM_FAILED',
                    last_updated_date = sysdate
                WHERE
                        batch_id = rcur_to_update_status.batch_id
                    AND header_id = rcur_to_update_status.header_id;

            END LOOP;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Concur', p_batch_id, 36.1, 'Error in updating if any target_coa is empty', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    --      update ledger_name in ap_header table where transform_success		
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 37, 'update ledger_name start', NULL,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_cncr_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT
                              lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t lgl_entt,
                              (
                                  SELECT
                                      line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_cncr_txn_line_t line,
                                      wsc_ahcs_int_status_t    status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = lv_batch_id
                                      AND status.attribute2 = 'VALIDATION_SUCCESS'
                              )                       d_lgl_entt
                          WHERE
                              lgl_entt.flex_segment_value = d_lgl_entt.gl_legal_entity
                      )
                      SELECT DISTINCT
                          a.ledger_name,
                          a.header_id
                      FROM
                          main_data a
                      WHERE
                          a.ledger_name IS NOT NULL
                          AND a.header_id IN (
                              SELECT
                                  d.header_id
                              FROM
                                  (
                                      SELECT
                                          COUNT(1), b.header_id
                                      FROM
                                          (
                                              SELECT DISTINCT
                                                  a.ledger_name, a.header_id
                                              FROM
                                                  main_data a
                                              WHERE
                                                  a.ledger_name IS NOT NULL
                                          ) b
                                      GROUP BY
                                          b.header_id
                                      HAVING
                                          COUNT(1) = 1
                                  ) d
                          )
                  )
            e ON ( e.header_id = hdr.header_id )
            WHEN MATCHED THEN UPDATE
            SET hdr.ledger_name = e.ledger_name;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Concur', p_batch_id, 37.1, 'Error in update ledger_name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('Concur', p_batch_id, 38, 'Update ledger name in status table start.', sqlerrm,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_cncr_txn_header_t h
                      WHERE
                          h.batch_id = p_batch_id
                  )
            hdr ON ( sts.batch_id = hdr.batch_id
                     AND sts.header_id = hdr.header_id
                     AND sts.batch_id = p_batch_id
                     AND sts.accounting_status IS NULL )
            WHEN MATCHED THEN UPDATE
            SET sts.ledger_name = hdr.ledger_name;

        END;
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 7.1. Update status tables after validation where line cr/dr mismatch.
        --    /******* ALL RECORDS MARKED AS VALIDATION FAILED WHEN LINE CR/DR AMOUNT MISMATCH AFTER VALIDATION ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 39, 'Update ledger name in status table ends.', NULL,
                      sysdate);
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 40, 'Update status table to have status.', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    sts.attribute2,
                    sts.status,
                    sts.last_updated_date,
                    sts.error_msg
                FROM
                    wsc_ahcs_int_status_t      sts,
                    wsc_ahcs_cncr_txn_header_t hdr
                WHERE
                        sts.batch_id = p_batch_id
                    AND hdr.header_id = sts.header_id
                    AND hdr.batch_id = sts.batch_id
                    AND hdr.ledger_name IS NULL
                    AND sts.error_msg IS NULL
                    AND sts.attribute2 = 'VALIDATION_SUCCESS'
            )
            SET
                error_msg = 'Ledger derivation failed',
                attribute2 = 'TRANSFORM_FAILED',
                status = 'TRANSFORM_FAILED',
                last_updated_date = sysdate;

            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'TRANSFORM_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status = 'VALIDATION_SUCCESS'
                AND attribute2 = 'VALIDATION_SUCCESS'
                AND error_msg IS NULL;

            COMMIT;
            UPDATE wsc_ahcs_int_status_t
            SET
                attribute2 = 'TRANSFORM_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND attribute2 = 'VALIDATION_SUCCESS'
                AND error_msg IS NULL;

            COMMIT;
    
            -------------------------------------------------------------------------------------------------------------------------------------------
            -- 9. Flag the control table to consider this file as TRANSFORMATION COMPLETE. 
            --    /************ THIS WILL SIGNAL OIC TO PICK THIS FILE FOR UCM UPLOAD BY MASTER SCHEDULER ***********************/
            -------------------------------------------------------------------------------------------------------------------------------------------

            OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_succ;
            CLOSE cur_count_sucss;
            IF lv_count_succ > 0 THEN
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'TRANSFORM_SUCCESS',
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            ELSE
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'TRANSFORM_FAILED',
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            END IF;

            COMMIT;
        END;

        logging_insert('Concur', p_batch_id, 41, 'end transformation', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT016', 'Concur', sqlerrm);
    END leg_coa_transformation_p;

    PROCEDURE leg_coa_transformation_reprocessing_p (
        p_batch_id IN NUMBER
    ) AS
      -- +====================================================================+
      -- | Name             : transform_staging_data_to_AHCS                  |
      -- | Description      : Transforms data read into the staging tables    |
      -- |                    to AHCS format.                                 |
      -- |                    Following transformation will be applied :-     |
      -- |                    1. Derive future state COA based on legacy COA  |
      -- |                       values in staging tables.                    |
      -- |                    2. Derive the ledger associated with the        |
      -- |                       transaction based on the balancing segment   |
      -- |                                                                    |
      -- |                    Transformation will be performed on the basis   |
      -- |                    of batch_id.                                    |
      -- |                    Every file set (header/line) coming from source |
      -- |                    will be mapped to a unique batch_id             |
      -- |                    This procedure will (based on parameter) will   |
      -- |                    transform all (or reprocess eligible) records   |
      -- |                    from the file.                                  |
      -- +====================================================================+
    
    
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    -- The following cursor will retrieve ALL records from lines table that does not target COA combination derived.
    -- All such columns 
    ------------------------------------------------------------------------------------------------------------------------------------------------------
        lv_batch_id                 NUMBER := p_batch_id;
        retcode                     VARCHAR2(50);
        lv_group_id                 NUMBER; --added for reprocess individual group id process 24th Nov 2022
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    -- Derive the COA map ID for a given source/ target system value.
    -- COA Map ID will subsequently be used to derive the COA mapping rules that are assigned to this source / target combination.
    ------------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_coa_map_id IS
        SELECT
            coa_map_id,
            coa_map.target_system,
            coa_map.source_system
        FROM
            wsc_gl_coa_map_t       coa_map,
            wsc_ahcs_int_control_t ahcs_control
        WHERE
                upper(coa_map.source_system) = upper(ahcs_control.source_system)
            AND upper(coa_map.target_system) = upper(ahcs_control.target_system)
            AND ahcs_control.batch_id = p_batch_id;
    
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    -- The following cursor will derive the future state COA combination for the given batch_Id for records that have been successfully validated.
    --
    ------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_leg_seg_value IS
        SELECT DISTINCT
            line.leg_coa,
            line.leg_bu,
            line.leg_acct,
            line.leg_dept,
            line.leg_loc,
            line.leg_vendor,
            nvl(line.leg_affiliate, '00000') leg_affiliate
        FROM
            wsc_ahcs_cncr_txn_line_t line
        WHERE
                batch_id = p_batch_id
            AND target_coa IS NULL
            AND src_system = 'ANIXTER'
            AND substr(transaction_number, - 2) <> '_2'
            AND EXISTS (
                SELECT /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */
                    1
                FROM
                    wsc_ahcs_int_status_t status
                WHERE
                        status.batch_id = p_batch_id
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
            );

        lv_target_coa               VARCHAR2(1000);
    
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
        -- for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_inserting_ccid_table (
            p_src_sytem IN VARCHAR2
        ) IS
        SELECT DISTINCT
            line.leg_coa    leg_coa,
            line.target_coa target_coa,
            line.leg_bu,
            line.leg_acct,
            line.leg_dept,
            line.leg_loc,
            line.leg_vendor,
            line.leg_affiliate,
            line.leg_wes_acct
        FROM
            wsc_ahcs_cncr_txn_line_t line
        WHERE
                line.batch_id = p_batch_id
            AND substr(line.transaction_number, - 2) <> '_2'
            AND line.src_system = p_src_sytem
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        TYPE inserting_ccid_table_type IS
            TABLE OF cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table     inserting_ccid_table_type;
        CURSOR cur_inserting_ccid_table_wes (
            p_src_sytem IN VARCHAR2
        ) IS
        SELECT DISTINCT
            line.leg_coa    leg_coa,
            line.target_coa target_coa,
            line.leg_bu,
           -- line.leg_acct,
          --  line.leg_dept,
            line.leg_loc,
          --  line.leg_vendor,
          --  line.leg_affiliate,
            line.leg_wes_acct
        FROM
            wsc_ahcs_cncr_txn_line_t line
        WHERE
                line.batch_id = p_batch_id
            --AND substr(line.transaction_number, - 2) <> '_2'
            AND line.src_system = p_src_sytem
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        TYPE inserting_ccid_table_type_wes IS
            TABLE OF cur_inserting_ccid_table_wes%rowtype;
        lv_inserting_ccid_table_wes inserting_ccid_table_type_wes;
    
        ------------------------------------------------------------------------------------------------------------------------------------------------------
        -- The following cursor picks up the distinct ledger/ legal entities that have been transformed successfully with future state COA values.
        -- Ledger name is one of the key defaulting attributes required for processing a journal in AHCS.
        ------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_count_sucss (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            COUNT(1)
        FROM
            wsc_ahcs_int_status_t
        WHERE
                batch_id = cur_p_batch_id
            AND attribute2 = 'TRANSFORM_SUCCESS';
    
        --- @@@@@@@@@@@@@@@@@@@@@@@@   
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will do a similar matching of total debits and credits but will be restricted at line level. 
        -- ONLY debit not matching to credit at transaction level will be detected after validation.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        /******* @@@@@@@@ Modify this cursor to reflect the appropriate line tables. Also verify the column names are correct @@@@@@@ ********/
    
        ------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_to_update_status (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            b.header_id,
            b.batch_id
        FROM
            wsc_ahcs_int_status_t b
        WHERE
                b.status = 'TRANSFORM_FAILED'
            AND b.batch_id = cur_p_batch_id;

        CURSOR cncr_grp_data_fetch_cur ( --added for individual reprocess group id 24th Nov 2022
            p_grp_id NUMBER
        ) IS
        SELECT DISTINCT
            c.batch_id           batch_id,
            c.file_name          file_name,
            a.ledger_name        ledger_name,
            c.source_application source_application,
    --        a.interface_id       interface_id,
            c.status             status
        FROM
            wsc_ahcs_int_control_t     c,
            wsc_ahcs_cncr_txn_header_t a
        WHERE
                a.batch_id = c.batch_id
            AND a.ledger_name IS NOT NULL
            AND c.status = 'TRANSFORM_SUCCESS'
            AND EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t s
                WHERE
                        s.batch_id = a.batch_id
                    AND s.header_id = a.header_id
                    AND s.attribute2 = 'TRANSFORM_SUCCESS'
                    AND ( s.accounting_status = 'IMP_ACC_ERROR'
                          OR s.accounting_status IS NULL )
            )
            AND c.group_id = p_grp_id;

        TYPE cncr_grp_type IS
            TABLE OF cncr_grp_data_fetch_cur%rowtype;
        lv_cncr_grp_type            cncr_grp_type;
        lv_coa_mapid                NUMBER;
        lv_src_system               VARCHAR2(100);
        lv_tgt_system               VARCHAR2(100);
        lv_count_succ               NUMBER;
    BEGIN
        logging_insert('Concur', p_batch_id, 22, 'Transformation start', NULL,
                      sysdate);
        logging_insert('Concur', p_batch_id, 22.5, 'Update target coa and error_msg as null.', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_cncr_txn_line_t line
            SET
                target_coa = NULL,
                last_update_date = sysdate
            WHERE
                EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t status
                    WHERE
                            line.batch_id = p_batch_id
                        AND status.batch_id = line.batch_id
                        AND status.header_id = line.header_id
                        AND status.line_id = line.line_id
                        AND status.attribute2 = 'TRANSFORM_FAILED'
                );

            UPDATE wsc_ahcs_int_status_t status
            SET
                error_msg = NULL,
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status.attribute2 = 'TRANSFORM_FAILED';

            COMMIT;
        END;

        logging_insert('Concur', p_batch_id, 24, 'updating target segments of anixter offset start.', NULL,
                      sysdate);
-- Update Anixter Offset Lines --
        UPDATE wsc_ahcs_cncr_txn_line_t line
        SET
            ( gl_legal_entity,
              gl_oper_grp,
              gl_acct,
              gl_dept,
              gl_site,
              gl_ic,
              gl_projects,
              gl_fut_1,
              gl_fut_2 ) = (
                SELECT
                    target_segment,
                    regexp_substr(r.target_coa, '[^.]+', 1, 1),
                    regexp_substr(r.target_coa, '[^.]+', 1, 2),
                    regexp_substr(r.target_coa, '[^.]+', 1, 3),
                    regexp_substr(r.target_coa, '[^.]+', 1, 4),
                    regexp_substr(r.target_coa, '[^.]+', 1, 5),
                    regexp_substr(r.target_coa, '[^.]+', 1, 6),
                    regexp_substr(r.target_coa, '[^.]+', 1, 7),
                    regexp_substr(r.target_coa, '[^.]+', 1, 8)
                FROM
                    wsc_ahcs_cncr_report_grp_t r,
                    (
                        SELECT
                            target_segment
                        FROM
                            wsc_gl_coa_segment_value_t
                        WHERE
                               -- rule_id = 51
                                rule_id = (
                                    SELECT
                                        rule_id
                                    FROM
                                        wsc_gl_coa_mapping_rules_t
                                    WHERE
                                        rule_name = 'Anixter - LE - Based on BU'
                                )
                            AND flag = 'Y'
                            AND source_segment1 = line.leg_bu
                    )
                WHERE
                    r.report_grp_id = 'Anixter Offset'
            )
        WHERE
                substr(transaction_number, - 2) = '_2'
            AND line.batch_id = p_batch_id
            AND src_system = 'ANIXTER'
            AND EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t status
                WHERE
                        line.batch_id = p_batch_id
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
            );

        UPDATE wsc_ahcs_cncr_txn_line_t line
        SET
            target_coa = gl_legal_entity
                         || '.'
                         || gl_oper_grp
                         || '.'
                         || gl_acct
                         || '.'
                         || gl_dept
                         || '.'
                         || gl_site
                         || '.'
                         || gl_ic
                         || '.'
                         || gl_projects
                         || '.'
                         || gl_fut_1
                         || '.'
                         || gl_fut_2
        WHERE
                substr(transaction_number, - 2) = '_2'
            AND batch_id = p_batch_id
            AND src_system = 'ANIXTER'
            AND EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t status
                WHERE
                        line.batch_id = p_batch_id
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
            );

        logging_insert('Concur', p_batch_id, 25, 'updating anixter offset target seg ends.', NULL,
                      sysdate);
        -------------------------------------------------------------------------------------------------------------------------------------------
    --1. Identify the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        -------------------------------------------------------------------------------------------------------------------------------------------
    --2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 26, 'update leg_wes_acct,leg_coa for wesco lines start.', NULL,
                      sysdate);
        UPDATE wsc_ahcs_cncr_txn_line_t line
        SET
            leg_wes_acct = (
                SELECT
                    target_segment
                FROM
                    wsc_gl_coa_segment_value_t
                WHERE
                       -- rule_id = 68
                        rule_id = (
                            SELECT
                                rule_id
                            FROM
                                wsc_gl_coa_mapping_rules_t
                            WHERE
                                rule_name = 'Peoplesoft - Account - Based on Account'
                        )
                    AND flag = 'Y'
                    AND source_segment1 = line.leg_acct
            ),
            leg_coa = leg_bu
                      || '.'
                      || leg_loc
                      || '.'
                      || (
                SELECT
                    target_segment
                FROM
                    wsc_gl_coa_segment_value_t
                WHERE
                       -- rule_id = 68
                        rule_id = (
                            SELECT
                                rule_id
                            FROM
                                wsc_gl_coa_mapping_rules_t
                            WHERE
                                rule_name = 'Peoplesoft - Account - Based on Account'
                        )
                    AND flag = 'Y'
                    AND source_segment1 = line.leg_acct
            )
                      || '.'
                      || '000.000000.000000.000000.'
        WHERE
                src_system = 'WESCO'
 --           AND substr(transaction_number, - 2) <> '_2'
            AND line.batch_id = p_batch_id
            AND EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t status
                WHERE
                        line.batch_id = p_batch_id
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
            );

        logging_insert('Concur', p_batch_id, 27, 'update leg_wes_acct,leg_coa in wesco lines ends.', NULL,
                      sysdate);
        logging_insert('Concur', p_batch_id, 28, 'Check data in cache table to find the target coa ', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_cncr_txn_line_t line
            SET
                target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa, decode(line.src_system, 'WESCO', 1, 2)),
                last_update_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND substr(line.transaction_number, - 2) <> '_2';

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Concur', p_batch_id, 28.1, 'Error in Check data in cache table to find', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    --        update target_coa and attribute1 'Y' in cncr_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 29, 'Update target_coa and attribute1 for anixter.', NULL,
                      sysdate);
        BEGIN
            FOR lv_leg_seg_value IN cur_leg_seg_value LOOP
                lv_target_coa := replace(wsc_gl_coa_mapping_pkg.coa_mapping('ANIXTER', 'Oracle ERP Cloud', lv_leg_seg_value.leg_bu, lv_leg_seg_value.
                leg_loc, lv_leg_seg_value.leg_dept,
                                                                           lv_leg_seg_value.leg_acct, lv_leg_seg_value.leg_vendor, nvl(
                                                                           lv_leg_seg_value.leg_affiliate, '00000'), NULL, NULL, NULL,
                                                                           NULL), ' ', '');

                UPDATE wsc_ahcs_cncr_txn_line_t line
                SET
                    target_coa = lv_target_coa,
                    attribute1 = 'Y'
                WHERE
                        leg_coa = lv_leg_seg_value.leg_coa
                    AND batch_id = p_batch_id
                    AND target_coa IS NULL;

            END LOOP;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Concur', p_batch_id, 29.1, 'Error in update target_coa and attribute1', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('Concur', p_batch_id, 30, 'update target_coa,attribute1 for wesco.', NULL,
                      sysdate);
        UPDATE wsc_ahcs_cncr_txn_line_t tgt_coa
        SET
            target_coa = wsc_gl_coa_mapping_pkg.coa_mapping('Oracle EBS', 'Oracle ERP Cloud', tgt_coa.leg_bu, tgt_coa.leg_loc, tgt_coa.
            leg_wes_acct,
                                                            '000', NULL, NULL, NULL, NULL,
                                                            NULL, NULL),
            attribute1 = 'Y'
        WHERE
                batch_id = p_batch_id
            AND target_coa IS NULL
            AND src_system = 'WESCO'
     --       AND substr(transaction_number, - 2) <> '_2'
            AND EXISTS (
                SELECT /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */
                    1
                FROM
                    wsc_ahcs_int_status_t status
                WHERE
                        status.batch_id = p_batch_id
                    AND status.batch_id = tgt_coa.batch_id
                    AND status.header_id = tgt_coa.header_id
                    AND status.line_id = tgt_coa.line_id
                    AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
            );

        COMMIT;
    
    --        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 31, 'Insert new target_coa values of anixter.', NULL,
                      sysdate);
        BEGIN
            OPEN cur_inserting_ccid_table('ANIXTER');
            LOOP
                FETCH cur_inserting_ccid_table
                BULK COLLECT INTO lv_inserting_ccid_table LIMIT 100;
                EXIT WHEN lv_inserting_ccid_table.count = 0;
                FORALL i IN 1..lv_inserting_ccid_table.count
                    INSERT INTO wsc_gl_ccid_mapping_t (
                        ccid_value_id,
                        coa_map_id,
                        source_segment,
                        target_segment,
                        creation_date,
                        last_update_date,
                        enable_flag,
                        ui_flag,
                        created_by,
                        last_updated_by,
                        source_segment1,
                        source_segment2,
                        source_segment3,
                        source_segment4,
                        source_segment5,
                        source_segment6,
                        source_segment7,
                        source_segment8,
                        source_segment9,
                        source_segment10
                    ) VALUES (
                        wsc_gl_ccid_mapping_s.NEXTVAL,
                        2,
                        lv_inserting_ccid_table(i).leg_coa,
                        lv_inserting_ccid_table(i).target_coa,
                        sysdate,
                        sysdate,
                        'Y',
                        'N',
                        'Concur',
                        'Concur',
                        lv_inserting_ccid_table(i).leg_bu,
                        lv_inserting_ccid_table(i).leg_loc,
                        lv_inserting_ccid_table(i).leg_dept,
                        lv_inserting_ccid_table(i).leg_acct,
                        lv_inserting_ccid_table(i).leg_vendor,
                        nvl(lv_inserting_ccid_table(i).leg_affiliate, '00000'),
                        NULL,
                        NULL,
                        NULL,
                        NULL
                    );

            END LOOP;

            CLOSE cur_inserting_ccid_table;
            logging_insert('Concur', p_batch_id, 32, 'Insert new target_coa values in cache of wesco ', NULL,
                          sysdate);
            OPEN cur_inserting_ccid_table_wes('WESCO');
            LOOP
                FETCH cur_inserting_ccid_table_wes
                BULK COLLECT INTO lv_inserting_ccid_table_wes LIMIT 100;
                EXIT WHEN lv_inserting_ccid_table_wes.count = 0;
                FORALL i IN 1..lv_inserting_ccid_table_wes.count
                    INSERT INTO wsc_gl_ccid_mapping_t (
                        ccid_value_id,
                        coa_map_id,
                        source_segment,
                        target_segment,
                        creation_date,
                        last_update_date,
                        enable_flag,
                        ui_flag,
                        created_by,
                        last_updated_by,
                        source_segment1,
                        source_segment2,
                        source_segment3,
                        source_segment4,
                        source_segment5,
                        source_segment6,
                        source_segment7,
                        source_segment8,
                        source_segment9,
                        source_segment10
                    ) VALUES (
                        wsc_gl_ccid_mapping_s.NEXTVAL,
                        1,
                        lv_inserting_ccid_table_wes(i).leg_coa,
                        lv_inserting_ccid_table_wes(i).target_coa,
                        sysdate,
                        sysdate,
                        'Y',
                        'N',
                        'Concur',
                        'Concur',
                        lv_inserting_ccid_table_wes(i).leg_bu,
                        lv_inserting_ccid_table_wes(i).leg_loc,
                 --       lv_inserting_ccid_table(i).leg_dept,
                        lv_inserting_ccid_table_wes(i).leg_wes_acct,
                      --  lv_inserting_ccid_table(i).leg_vendor,
                        '000',
                        '000000',
                        '000000',
                        '000000',
                        NULL,
                        NULL,
                        NULL
                    );

            END LOOP;

            CLOSE cur_inserting_ccid_table_wes;
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Concur', p_batch_id, 32.1, 'Error in ccid table insert.', sqlerrm,
                              sysdate);
        END;

        UPDATE wsc_ahcs_cncr_txn_line_t
        SET
            attribute1 = NULL
        WHERE
            batch_id = p_batch_id;

        COMMIT;
    
    --      update ap_line table target segments,  where legal_entity must have their in target_coa
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 33, 'Update concur line table target segments.', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_cncr_txn_line_t
            SET
                gl_legal_entity = substr(target_coa, 1, instr(target_coa, '.', 1, 1) - 1),
                gl_oper_grp = substr(target_coa, instr(target_coa, '.', 1, 1) + 1, instr(target_coa, '.', 1, 2) - instr(target_coa, '.',
                1, 1) - 1),
                gl_acct = substr(target_coa, instr(target_coa, '.', 1, 2) + 1, instr(target_coa, '.', 1, 3) - instr(target_coa, '.', 1,
                2) - 1),
                gl_dept = substr(target_coa, instr(target_coa, '.', 1, 3) + 1, instr(target_coa, '.', 1, 4) - instr(target_coa, '.', 1,
                3) - 1),
                gl_site = substr(target_coa, instr(target_coa, '.', 1, 4) + 1, instr(target_coa, '.', 1, 5) - instr(target_coa, '.', 1,
                4) - 1),
                gl_ic = substr(target_coa, instr(target_coa, '.', 1, 5) + 1, instr(target_coa, '.', 1, 6) - instr(target_coa, '.', 1,
                5) - 1),
                gl_projects = substr(target_coa, instr(target_coa, '.', 1, 6) + 1, instr(target_coa, '.', 1, 7) - instr(target_coa, '.',
                1, 6) - 1),
                gl_fut_1 = substr(target_coa, instr(target_coa, '.', 1, 7) + 1, instr(target_coa, '.', 1, 8) - instr(target_coa, '.',
                1, 7) - 1),
                gl_fut_2 = substr(target_coa, instr(target_coa, '.', 1, 8) + 1),
                last_update_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND substr(target_coa, 1, instr(target_coa, '.', 1, 1) - 1) IS NOT NULL
             --   AND src_system = 'ANIXTER'
                AND substr(transaction_number, - 2) <> '_2';

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
                logging_insert('Concur', p_batch_id, 33.1, 'Error in update concur line table target segments', sqlerrm,
                              sysdate);
        END;

        logging_insert('Concur', p_batch_id, 34, 'Override the gl_acct value for wesco with leg_ps_acct value dervied.', NULL,
                      sysdate);
        UPDATE wsc_ahcs_cncr_txn_line_t line
        SET
            gl_acct = (
                SELECT
                    target_segment
                FROM
                    wsc_gl_coa_segment_value_t
                WHERE
                  --      rule_id = 52
                        rule_id = (
                            SELECT
                                rule_id
                            FROM
                                wsc_gl_coa_mapping_rules_t
                            WHERE
                                rule_name = 'Anixter - Account - Based on Account'
                        )
                    AND flag = 'Y'
                    AND line.leg_acct = source_segment4
            ),
            gl_legal_entity = (
                SELECT
                    target_segment
                FROM
                    wsc_gl_coa_segment_value_t
                WHERE
                      --  rule_id = 40
                        rule_id = (
                            SELECT
                                rule_id
                            FROM
                                wsc_gl_coa_mapping_rules_t
                            WHERE
                                rule_name = 'WESCO - LE - LE Based on Branch'
                        )
                    AND flag = 'Y'
                    AND line.leg_loc = source_segment2
            )
        WHERE
                src_system = 'WESCO'
     --       AND substr(line.transaction_number, - 2) <> '_2'
            AND line.batch_id = p_batch_id
            AND EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t status
                WHERE
                        line.batch_id = p_batch_id
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
            );
        logging_insert('Concur', p_batch_id, 34.1, 'Update new wesco target_coa.', NULL,
                      sysdate);
        UPDATE wsc_ahcs_cncr_txn_line_t line
        SET
            target_coa = gl_legal_entity
                         || '.'
                         || gl_oper_grp
                         || '.'
                         || gl_acct
                         || '.'
                         || gl_dept
                         || '.'
                         || gl_site
                         || '.'
                         || gl_ic
                         || '.'
                         || gl_projects
                         || '.'
                         || gl_fut_1
                         || '.'
                         || gl_fut_2
        WHERE
                line.batch_id = p_batch_id
            AND src_system = 'WESCO'
            AND EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t status
                WHERE
                        line.batch_id = p_batch_id
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
            );

        UPDATE (
            SELECT
                status.attribute2,
                status.attribute1,
                status.status,
                status.error_msg,
                status.last_updated_date,
                line.batch_id  bt_id,
                line.header_id hdr_id,
                line.line_id   ln_id
            FROM
                wsc_ahcs_int_status_t    status,
                wsc_ahcs_cncr_txn_line_t line
            WHERE
                    status.batch_id = p_batch_id
                AND status.batch_id = line.batch_id
                AND status.header_id = line.header_id
                AND status.line_id = line.line_id
                AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                AND line.src_system = 'WESCO'
                AND line.gl_acct IS NULL
                AND line.target_coa LIKE '%.%'
            --    AND substr(line.transaction_number, - 2) <> '_2'
        )
        SET
            attribute1 = 'L',
            attribute2 = 'TRANSFORM_FAILED',
            status = 'TRANSFORM_FAILED',
            error_msg = error_msg || 'Account not found',
            last_updated_date = sysdate;

        COMMIT;
        UPDATE (
            SELECT
                status.attribute2,
                status.attribute1,
                status.status,
                status.error_msg,
                status.last_updated_date,
                line.batch_id  bt_id,
                line.header_id hdr_id,
                line.line_id   ln_id
            FROM
                wsc_ahcs_int_status_t    status,
                wsc_ahcs_cncr_txn_line_t line
            WHERE
                    status.batch_id = p_batch_id
                AND status.batch_id = line.batch_id
                AND status.header_id = line.header_id
                AND status.line_id = line.line_id
                AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                AND line.src_system = 'WESCO'
                AND line.gl_legal_entity IS NULL
                AND line.target_coa LIKE '%.%'
             --   AND substr(line.transaction_number, - 2) <> '_2'
        )
        SET
            attribute1 = 'L',
            attribute2 = 'TRANSFORM_FAILED',
            status = 'TRANSFORM_FAILED',
            error_msg = error_msg || 'Legal Enitity not found',
            last_updated_date = sysdate;

        COMMIT;
--        UPDATE wsc_ahcs_cncr_txn_line_t line
--        SET
--            gl_acct = (
--                SELECT
--                    target_segment
--                FROM
--                    wsc_gl_coa_segment_value_t
--                WHERE
--                        rule_id = 52
--                        and flag = 'Y'
--                    AND line.leg_acct = source_segment4
--            )
--        WHERE
--                src_system = 'WESCO'
--            AND substr(line.transaction_number, - 2) <> '_2'
--            AND line.batch_id = p_batch_id
--            AND EXISTS (
--                SELECT
--                    1
--                FROM
--                    wsc_ahcs_int_status_t status
--                WHERE
--                        line.batch_id = p_batch_id
--                    AND status.batch_id = line.batch_id
--                    AND status.header_id = line.header_id
--                    AND status.line_id = line.line_id
--                    AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
--            );
--    
    --        if any target_coa is empty in ap_line table will mark it as transform_error in status table
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 35, 'Wesco overide ends,update status table for empty target_coa.', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    status.attribute2,
                    status.attribute1,
                    status.status,
                    status.error_msg,
                    status.last_updated_date,
                    line.batch_id   bt_id,
                    line.header_id  hdr_id,
                    line.line_id    ln_id,
                    line.target_coa trgt_coa
                FROM
                    wsc_ahcs_int_status_t    status,
                    wsc_ahcs_cncr_txn_line_t line
                WHERE
                        status.batch_id = p_batch_id
                    AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
         --           AND line.src_system = 'ANIXTER'
                    AND substr(line.transaction_number, - 2) <> '_2'
            )
            SET
                attribute1 = 'L',
                attribute2 = 'TRANSFORM_FAILED',
                status = 'TRANSFORM_FAILED',
                error_msg = trgt_coa,
                last_updated_date = sysdate;

            COMMIT;
            logging_insert('Concur', p_batch_id, 36, 'Updated attribute2 with TRANSFORM_FAILED status.', NULL,
                          sysdate);
            FOR rcur_to_update_status IN cur_to_update_status(p_batch_id) LOOP
                UPDATE wsc_ahcs_int_status_t
                SET
                    attribute2 = 'TRANSFORM_FAILED',
                    last_updated_date = sysdate
                WHERE
                        batch_id = rcur_to_update_status.batch_id
                    AND header_id = rcur_to_update_status.header_id;

            END LOOP;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Concur', p_batch_id, 36.1, 'Error in updating if any target_coa is empty', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    --      update ledger_name in ap_header table where transform_success		
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 37, 'update ledger_name start', NULL,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_cncr_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT
                              lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t lgl_entt,
                              (
                                  SELECT
                                      line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_cncr_txn_line_t line,
                                      wsc_ahcs_int_status_t    status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = lv_batch_id
                                      AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                              )                       d_lgl_entt
                          WHERE
                              lgl_entt.flex_segment_value = d_lgl_entt.gl_legal_entity
                      )
                      SELECT DISTINCT
                          a.ledger_name,
                          a.header_id
                      FROM
                          main_data a
                      WHERE
                          a.ledger_name IS NOT NULL
                          AND a.header_id IN (
                              SELECT
                                  d.header_id
                              FROM
                                  (
                                      SELECT
                                          COUNT(1), b.header_id
                                      FROM
                                          (
                                              SELECT DISTINCT
                                                  a.ledger_name, a.header_id
                                              FROM
                                                  main_data a
                                              WHERE
                                                  a.ledger_name IS NOT NULL
                                          ) b
                                      GROUP BY
                                          b.header_id
                                      HAVING
                                          COUNT(1) = 1
                                  ) d
                          )
                  )
            e ON ( e.header_id = hdr.header_id )
            WHEN MATCHED THEN UPDATE
            SET hdr.ledger_name = e.ledger_name;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Concur', p_batch_id, 37.1, 'Error in update ledger_name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('Concur', p_batch_id, 38, 'Update ledger name in status table start.', sqlerrm,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_cncr_txn_header_t h
                      WHERE
                          h.batch_id = p_batch_id
                  )
            hdr ON ( sts.batch_id = hdr.batch_id
                     AND sts.header_id = hdr.header_id
                     AND sts.batch_id = p_batch_id
                     AND sts.accounting_status IS NULL )
            WHEN MATCHED THEN UPDATE
            SET sts.ledger_name = hdr.ledger_name;

        END;
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 7.1. Update status tables after validation where line cr/dr mismatch.
        --    /******* ALL RECORDS MARKED AS VALIDATION FAILED WHEN LINE CR/DR AMOUNT MISMATCH AFTER VALIDATION ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 39, 'Update ledger name in status table ends.', NULL,
                      sysdate);
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Concur', p_batch_id, 40, 'Update status table to have status.', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    sts.attribute2,
                    sts.status,
                    sts.last_updated_date,
                    sts.error_msg
                FROM
                    wsc_ahcs_int_status_t      sts,
                    wsc_ahcs_cncr_txn_header_t hdr
                WHERE
                        sts.batch_id = p_batch_id
                    AND hdr.header_id = sts.header_id
                    AND hdr.batch_id = sts.batch_id
                    AND hdr.ledger_name IS NULL
                    AND sts.error_msg IS NULL
                    AND sts.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
            )
            SET
                error_msg = 'Ledger derivation failed',
                attribute2 = 'TRANSFORM_FAILED',
                status = 'TRANSFORM_FAILED',
                last_updated_date = sysdate;

            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'TRANSFORM_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
        --        AND attribute2 = 'VALIDATION_SUCCESS'
                AND error_msg IS NULL;

            COMMIT;
            UPDATE wsc_ahcs_int_status_t
            SET
                attribute2 = 'TRANSFORM_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                AND error_msg IS NULL;

            COMMIT;
    
            -------------------------------------------------------------------------------------------------------------------------------------------
            -- 9. Flag the control table to consider this file as TRANSFORMATION COMPLETE. 
            --    /************ THIS WILL SIGNAL OIC TO PICK THIS FILE FOR UCM UPLOAD BY MASTER SCHEDULER ***********************/
            -------------------------------------------------------------------------------------------------------------------------------------------

            OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_succ;
            CLOSE cur_count_sucss;
            IF lv_count_succ > 0 THEN
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'TRANSFORM_SUCCESS',
                    group_id = NULL,
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            ELSE
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'TRANSFORM_FAILED',
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            END IF;

            COMMIT;
        END;

        BEGIN --added fo individual group id reprocess 24th Nov 2022
            lv_group_id := wsc_ahcs_mf_grp_id_seq.nextval;
            UPDATE wsc_ahcs_int_control_t
            SET
                group_id = lv_group_id
            WHERE
                    source_application = 'CONCUR'
                AND status = 'TRANSFORM_SUCCESS'
                AND group_id IS NULL
                AND batch_id = p_batch_id;

            COMMIT;
            OPEN cncr_grp_data_fetch_cur(lv_group_id);
            LOOP
                FETCH cncr_grp_data_fetch_cur
                BULK COLLECT INTO lv_cncr_grp_type LIMIT 50;
                EXIT WHEN lv_cncr_grp_type.count = 0;
                FORALL i IN 1..lv_cncr_grp_type.count
                    INSERT INTO wsc_ahcs_int_control_line_t (
                        batch_id,
                        file_name,
                        group_id,
                        ledger_name,
                        source_system,
   --                 interface_id,
                        status,
                        created_by,
                        creation_date,
                        last_updated_by,
                        last_update_date
                    ) VALUES (
                        lv_cncr_grp_type(i).batch_id,
                        lv_cncr_grp_type(i).file_name,
                        lv_group_id,
                        lv_cncr_grp_type(i).ledger_name,
                        lv_cncr_grp_type(i).source_application,
          --          lv_cncr_grp_type(i).interface_id,
                        lv_cncr_grp_type(i).status,
                        'FIN_INT',
                        sysdate,
                        'FIN_INT',
                        sysdate
                    );

            END LOOP;

            COMMIT;
            UPDATE wsc_ahcs_int_status_t
            SET
                group_id = lv_group_id
            WHERE
--            batch_id IN (
--                SELECT DISTINCT
--                    batch_id
--                FROM
--                    wsc_ahcs_int_control_line_t
--                WHERE
--                    group_id = lv_grp_id
--            )
                group_id IS NULL
                AND batch_id = p_batch_id
                AND attribute2 = 'TRANSFORM_SUCCESS'
                AND ( accounting_status = 'IMP_ACC_ERROR'
                      OR accounting_status IS NULL );

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Concur', p_batch_id, 290.1, 'Error in the reprocess group id block.' || sqlerrm, NULL,
                              sysdate);
        END;

        logging_insert('Concur', p_batch_id, 303, 'Dashboard Start', NULL,
                      sysdate);
        wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
        logging_insert('Concur', p_batch_id, 304, 'Dashboard End', NULL,
                      sysdate);
        logging_insert('Concur', p_batch_id, 41, 'end transformation', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT016', 'Concur', sqlerrm);
    END leg_coa_transformation_reprocessing_p;

    PROCEDURE wsc_ahcs_cncr_grp_id_upd_p (
        in_grp_id IN NUMBER
    ) AS

        lv_grp_id        NUMBER := in_grp_id;
        err_msg          VARCHAR2(4000);
        CURSOR cncr_grp_data_fetch_cur (
            p_grp_id NUMBER
        ) IS
        SELECT DISTINCT
            c.batch_id           batch_id,
            c.file_name          file_name,
            a.ledger_name        ledger_name,
            c.source_application source_application,
    --        a.interface_id       interface_id,
            c.status             status
        FROM
            wsc_ahcs_int_control_t     c,
            wsc_ahcs_cncr_txn_header_t a
        WHERE
                a.batch_id = c.batch_id
            AND a.ledger_name IS NOT NULL
            AND c.status = 'TRANSFORM_SUCCESS'
            AND EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t s
                WHERE
                        s.batch_id = a.batch_id
                    AND s.header_id = a.header_id
                    AND s.attribute2 = 'TRANSFORM_SUCCESS'
                    AND ( s.accounting_status = 'IMP_ACC_ERROR'
                          OR s.accounting_status IS NULL )
            )
            AND c.group_id = p_grp_id;

        TYPE cncr_grp_type IS
            TABLE OF cncr_grp_data_fetch_cur%rowtype;
        lv_cncr_grp_type cncr_grp_type;
    BEGIN
-- Updating Group Id for Concur Files in control table----

        UPDATE wsc_ahcs_int_control_t
        SET
            group_id = lv_grp_id
        WHERE
                source_application = 'CONCUR'
            AND status = 'TRANSFORM_SUCCESS'
            AND group_id IS NULL;

        COMMIT;
        OPEN cncr_grp_data_fetch_cur(lv_grp_id);
        LOOP
            FETCH cncr_grp_data_fetch_cur
            BULK COLLECT INTO lv_cncr_grp_type LIMIT 50;
            EXIT WHEN lv_cncr_grp_type.count = 0;
            FORALL i IN 1..lv_cncr_grp_type.count
                INSERT INTO wsc_ahcs_int_control_line_t (
                    batch_id,
                    file_name,
                    group_id,
                    ledger_name,
                    source_system,
   --                 interface_id,
                    status,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date
                ) VALUES (
                    lv_cncr_grp_type(i).batch_id,
                    lv_cncr_grp_type(i).file_name,
                    lv_grp_id,
                    lv_cncr_grp_type(i).ledger_name,
                    lv_cncr_grp_type(i).source_application,
          --          lv_cncr_grp_type(i).interface_id,
                    lv_cncr_grp_type(i).status,
                    'FIN_INT',
                    sysdate,
                    'FIN_INT',
                    sysdate
                );

        END LOOP;

        COMMIT;
        UPDATE wsc_ahcs_int_status_t
        SET
            group_id = lv_grp_id
        WHERE
            batch_id IN (
                SELECT DISTINCT
                    batch_id
                FROM
                    wsc_ahcs_int_control_line_t
                WHERE
                    group_id = lv_grp_id
            )
            AND group_id IS NULL
            AND attribute2 = 'TRANSFORM_SUCCESS'
            AND ( accounting_status = 'IMP_ACC_ERROR'
                  OR accounting_status IS NULL );

        COMMIT;
    END wsc_ahcs_cncr_grp_id_upd_p;

    PROCEDURE wsc_ahcs_cncr_ctrl_line_tbl_led_num_upd_p (
        p_group_id       IN VARCHAR2,
        p_ledger_grp_num IN VARCHAR2
    ) AS
    BEGIN
        IF ( p_ledger_grp_num = 999 ) THEN
            dbms_output.put_line(p_ledger_grp_num || 'inside IF');
            UPDATE wsc_ahcs_int_control_line_t status
            SET
                status.ledger_grp_num = p_ledger_grp_num,
                last_update_date = sysdate
            WHERE
                    status.group_id = p_group_id
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_mf_ledger_t ml
                    WHERE
                            999 = p_ledger_grp_num
                        AND ml.sub_ledger = 'CONCUR'
                        AND ml.ledger_name = status.ledger_name
                );

            COMMIT;
        ELSE
            dbms_output.put_line(p_ledger_grp_num || ' inside  else ');
            UPDATE wsc_ahcs_int_control_line_t status
            SET
                status.ledger_grp_num = p_ledger_grp_num,
                last_update_date = sysdate
            WHERE
                    status.group_id = p_group_id
                AND ( ledger_name IN (
                    SELECT
                        ledger_name
                    FROM
                        wsc_ahcs_int_mf_ledger_t ml
                    WHERE
                            ml.ledger_grp_num = p_ledger_grp_num
                        AND ml.sub_ledger = 'CONCUR'
                        AND ml.ledger_name = status.ledger_name
                ) );

            COMMIT;
        END IF;
    END wsc_ahcs_cncr_ctrl_line_tbl_led_num_upd_p;

    PROCEDURE wsc_ahcs_cncr_ctrl_line_ucm_id_upd_p (
        p_ucmdoc_id      IN VARCHAR2,
        p_group_id       IN VARCHAR2,
        p_ledger_grp_num IN VARCHAR2
    ) AS
    BEGIN
        IF ( p_ledger_grp_num = 999 ) THEN
            dbms_output.put_line(p_ledger_grp_num || 'inside IF');
            UPDATE wsc_ahcs_int_control_line_t status
            SET
                status.ucm_id = p_ucmdoc_id,
                status.status = 'UCM_UPLOADED',
                last_update_date = sysdate
            WHERE
                    status.group_id = p_group_id
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_mf_ledger_t ml
                    WHERE
                            999 = p_ledger_grp_num
                        AND ml.sub_ledger = 'CONCUR'
                        AND ml.ledger_name = status.ledger_name
                );

            COMMIT;
        ELSE
            dbms_output.put_line(p_ledger_grp_num || ' inside  else ');
            UPDATE wsc_ahcs_int_control_line_t status
            SET
                status.ucm_id = p_ucmdoc_id,
                status.status = 'UCM_UPLOADED',
                last_update_date = sysdate
            WHERE
                    status.group_id = p_group_id
                AND ( ledger_name IN (
                    SELECT
                        ledger_name
                    FROM
                        wsc_ahcs_int_mf_ledger_t ml
                    WHERE
                            ml.ledger_grp_num = p_ledger_grp_num
                        AND ml.sub_ledger = 'CONCUR'
                        AND ml.ledger_name = status.ledger_name
                ) );

            COMMIT;
        END IF;
    END wsc_ahcs_cncr_ctrl_line_ucm_id_upd_p;

    FUNCTION "IS_DATE_NULL" (
        p_string IN DATE
    ) RETURN NUMBER IS
    BEGIN
        IF p_string IS NULL THEN
            RETURN 0;
        ELSE
            RETURN 1;
        END IF;
    END;

    FUNCTION "IS_LONG_NULL" (
        p_string IN LONG
    ) RETURN NUMBER IS
    BEGIN
        IF p_string IS NULL THEN
            RETURN 0;
        ELSE
            RETURN 1;
        END IF;
    END;

    FUNCTION "IS_NUMBER_NULL" (
        p_string IN NUMBER
    ) RETURN NUMBER IS
        p_num NUMBER;
    BEGIN
        p_num := to_number(p_string);
        IF p_string IS NOT NULL THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END;

    FUNCTION "IS_VARCHAR2_NULL" (
        p_string IN VARCHAR2
    ) RETURN NUMBER IS
    BEGIN
        IF p_string IS NULL THEN
            RETURN 0;
        ELSE
            RETURN 1;
        END IF;
    END;

END wsc_ahcs_cncr_validation_transformation_pkg;

/