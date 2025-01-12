create or replace PACKAGE BODY wsc_ahcs_cp_validation_transformation_pkg AS

    PROCEDURE data_validation (
        p_batch_id IN NUMBER
    ) IS 

    -- TODO: Implementation required for PROCEDURE WSC_AHCS_CP_VALIDATION_TRANSFORMATION_PKG.data_validation
        lv_header_err_msg   VARCHAR2(2000) := NULL;
        lv_line_err_msg     VARCHAR2(2000) := NULL;
        lv_header_err_flag  VARCHAR2(100) := 'false';
        lv_line_err_flag    VARCHAR2(100) := 'false';
      
        lv_count_sucss      NUMBER := 0;
        retcode             NUMBER;
                                                                                 
 -------------------------------------------------------------------------------------------------------------------------------------------------------       
        TYPE wsc_line_col_value_type IS
            VARRAY(10) OF VARCHAR2(200); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING LINE OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/

        lv_line_col_value   wsc_line_col_value_type := wsc_line_col_value_type('PAY_CODE', 'PAY_CODE_DESC', 'COMPANY_NUM', 'GL_CODE',
        'COST_CENTER_NAME','DR', 'CR');
        
        TYPE wsc_ahcs_cp_line_txn_t_type IS
            TABLE OF INTEGER;
        lv_error_cp_line    wsc_ahcs_cp_line_txn_t_type := wsc_ahcs_cp_line_txn_t_type('1', '1', '1', '1', '1',
                                                                                   '1',
                                                                                   '1',
                                                                                   '1',
                                                                                   '1',
                                                                                   '1'); 
 -------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from LINE STAGING TABLE THAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_wsc_cp_line (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            pay_code,
            pay_code_desc,
            company_num,
            gl_code,
            cost_center_name,
            dr,
            cr,
            line_id
        FROM
            wsc_ahcs_cp_txn_line_t
        WHERE
            batch_id = cur_p_batch_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/

------------------------------------------------------------------------------------------------------------------------------------------------
--Following cursor will verify whether debit is equal or not to credit and will flag the results.
------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_line_validation (
            cur_p_batch_id NUMBER
        ) IS
        WITH line_cr AS (
            SELECT
                LEG_BU,
                abs(SUM(cr)) sum_data
            FROM
                wsc_ahcs_cp_txn_line_t
            WHERE
                batch_id = cur_p_batch_id
            GROUP BY
                LEG_BU
        ), line_dr AS (
            SELECT
                LEG_BU,
                abs(SUM(dr)) sum_data
            FROM
                wsc_ahcs_cp_txn_line_t
            WHERE
                batch_id = cur_p_batch_id
            GROUP BY
                LEG_BU
        )
        SELECT
            l_cr.LEG_BU
        FROM
            line_cr  l_cr,
            line_dr  l_dr
        WHERE
            ( l_dr.sum_data <> l_cr.sum_data )
            AND l_dr.LEG_BU = l_cr.LEG_BU;

------------------------------------------------------------------------------------------------------------------------------------------------

        TYPE line_validation_type IS
            TABLE OF cur_line_validation%rowtype;
        lv_line_validation  line_validation_type;
------------------------------------------------------------------------------------------------------------------------------------------------   		
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

        err_msg             VARCHAR2(2000);
    BEGIN
        logging_insert('CLOUDPAY', p_batch_id, 6, 'Start of validation', NULL,
                      sysdate);
    ------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2. Validate DEBIT-CREDIT
        --  Identify transactions wherein DEBIT does not match with CREDIT .
        --    Identify transactions wherein debits does not match credits.
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
        logging_insert('CLOUDPAY', p_batch_id, 103, 'Start of validation - Validate DEBIT-CREDIT', NULL,
                      sysdate);
        BEGIN
            OPEN cur_line_validation(p_batch_id);
            LOOP
                FETCH cur_line_validation BULK COLLECT INTO lv_line_validation LIMIT 100;
                EXIT WHEN lv_line_validation.count = 0;
                FORALL i IN 1..lv_line_validation.count
                    UPDATE wsc_ahcs_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = '301|Line DR/CR amount mismatch',
                        reextract_required = 'Y',
                        attribute1 = 'L',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        AND status = 'NEW'
                        AND ATTRIBUTE4 = lv_line_validation(i).LEG_BU;

            END LOOP;

            CLOSE cur_line_validation;
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('CLOUDPAY', p_batch_id, 203, 'exception in DEBIT-CREDIT validation', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
                ROLLBACK;
        END;

        logging_insert('CLOUDPAY', p_batch_id, 104, 'End of validation - Validate DEBIT-CREDIT', NULL,
                      sysdate);
------------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Validate line level fields
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

        logging_insert('CLOUDPAY', p_batch_id, 105, 'Validate line fields data type start', NULL,
                      sysdate);
        BEGIN
            FOR wsc_cp_line IN cur_wsc_cp_line(p_batch_id) LOOP
                lv_line_err_flag := 'false';
                lv_line_err_msg := NULL;
                lv_error_cp_line := wsc_ahcs_cp_line_txn_t_type('1', '1', '1', '1', '1',
                                                               '1',
                                                               '1',
                                                               '1');

                lv_error_cp_line(1) := is_varchar2_null(wsc_cp_line.pay_code);
                lv_error_cp_line(2) := is_varchar2_null(wsc_cp_line.pay_code_desc);
                lv_error_cp_line(3) := is_varchar2_null(wsc_cp_line.company_num);
                lv_error_cp_line(4) := is_varchar2_null(wsc_cp_line.gl_code);
                lv_error_cp_line(5) := is_varchar2_null(wsc_cp_line.cost_center_name);
                lv_error_cp_line(6) := is_number_null(wsc_cp_line.dr);
                lv_error_cp_line(7) := is_number_null(wsc_cp_line.cr);
              /*  logging_insert('CLOUDPAY', p_batch_id, 205,
                                  'Updated Line ID'
                                  || lv_error_cp_line(1)
                                  || lv_error_cp_line(2)
                                  || lv_error_cp_line(3)
                                  || lv_error_cp_line(4)
                                  || lv_error_cp_line(5)
                                  || lv_error_cp_line(6)
                                  || lv_error_cp_line(7)
                                  ,
                                  null,
                                  sysdate);*/
                FOR i IN 1..7 LOOP
                    IF lv_error_cp_line(i) = 0 THEN
                        lv_line_err_msg := lv_line_err_msg
                                           || '300|Missing Value of '
                                           || lv_line_col_value(i)
                                           || '. ';
logging_insert('CLOUDPAY', p_batch_id, 205,
                                  'Updated Line ID'
                                  || lv_line_err_msg,
                                  null,
                                  sysdate);                                           
                        lv_line_err_flag := 'true';
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
                    -- AND header_id = header_id_f.header_id
                        AND line_id = wsc_cp_line.line_id;

                    COMMIT;
                    logging_insert('CLOUDPAY', p_batch_id, 205,
                                  'Updated Line ID'
                                  || wsc_cp_line.line_id,
                                 -- || 'for Header ID',
                                --  || header_id_f.header_id,
                                  lv_line_err_flag,
                                  sysdate);

--                    UPDATE wsc_ahcs_int_status_t
--                    SET
--                        attribute1 = 'L',
--                        attribute2 = 'VALIDATION_FAILED',
--                        last_updated_date = sysdate
--                    WHERE
--                            batch_id = p_batch_id
--                        AND status = 'NEW';
                      --  AND header_id = header_id_f.header_id;

                    COMMIT;
                    logging_insert('CLOUDPAY', p_batch_id, 206, 'Updated Header ID', lv_line_err_flag,
                                  sysdate);

                END IF;

            END LOOP;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                err_msg := substr(sqlerrm, 1, 200);
                logging_insert('CLOUDPAY', p_batch_id, 207, 'Error in mandatory field validation', sqlerrm,
                              sysdate);
        END;

        logging_insert('CLOUDPAY', p_batch_id, 106, 'end mandatory validation', NULL,
                      sysdate);
        BEGIN
            logging_insert('CLOUDPAY', p_batch_id, 107, 'start updating STATUS TABLE with validation status', NULL,
                          sysdate);
         /*   UPDATE wsc_ahcs_int_status_t
            SET
                status = 'VALIDATION_FAILED',
                error_msg = 'error in TRANSACTION_NUMBER', ---TO ASK
                reextract_required = 'Y',
                attribute1 = 'L',
                attribute2 = 'VALIDATION_FAILED',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status = 'NEW';
                AND header_id IS NULL;

            COMMIT; */
            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'VALIDATION_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status = 'NEW'
                AND error_msg IS NULL;

            COMMIT;
            logging_insert('CLOUDPAY', p_batch_id, 108, 'status updated in STATUS TABLE', NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                attribute2 = 'VALIDATION_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
--                AND status = 'NEW'
                AND attribute2 IS NULL;

            COMMIT;
            logging_insert('CLOUDPAY', p_batch_id, 109, 'attribute 2 updated in STATUS TABLE', NULL,
                          sysdate);
            OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_sucss;
            CLOSE cur_count_sucss;
            logging_insert('CLOUDPAY', p_batch_id, 110, 'count success', lv_count_sucss,
                          sysdate);
            IF lv_count_sucss > 0 THEN
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'VALIDATION_SUCCESS',
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;

                COMMIT;
             --call transformation package
                logging_insert('CLOUDPAY', p_batch_id, 111, 'call transformation pkg ', NULL,
                              sysdate);
                BEGIN
                    wsc_ahcs_cp_validation_transformation_pkg.leg_coa_transformation(p_batch_id);
                END;
            ELSE
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'VALIDATION_FAILED',
                    last_updated_date = sysdate
                WHERE
                        batch_id = p_batch_id
                    AND status = 'NEW';

            END IF;

            COMMIT;
            logging_insert('CLOUDPAY', p_batch_id, 124, 'end data_validation and transformation', NULL,
                          sysdate);
            logging_insert('CLOUDPAY', p_batch_id, 125, 'AHCS Dashboard refresh Start', NULL,
                          sysdate);
            wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
            logging_insert('CLOUDPAY', p_batch_id, 126, 'AHCS Dashboard refresh End', NULL,
                          sysdate);
        END;

    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT018', 'CLOUDPAY', sqlerrm);
  END data_validation;



    PROCEDURE leg_coa_transformation (
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
       
--        CURSOR cur_update_trxn_line_err IS
--        SELECT
--            line.batch_id,
--            --line.header_id,
--            line.line_id,
--            line.target_coa
--        FROM
--            wsc_ahcs_CP_txn_line_t line,
--            wsc_ahcs_int_status_t    status
--		
--        WHERE
--                line.batch_id = p_batch_id
--            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
--            AND status.batch_id = line.batch_id
--            --AND status.header_id = line.header_id
--            AND status.line_id = line.line_id
--            AND status.attribute2 = 'VALIDATION_SUCCESS'; /*ATTRIBUTE2 */
--
--        TYPE update_trxn_line_err_type IS
--            TABLE OF cur_update_trxn_line_err%rowtype;
--        lv_update_trxn_line_err   update_trxn_line_err_type;
        
        
--        CURSOR cur_update_trxn_header_err IS
--        SELECT DISTINCT
--            status.header_id,
--            status.batch_id
--        FROM
--            wsc_ahcs_int_status_t status
--        WHERE
--                status.batch_id = p_batch_id
--            AND status.status = 'TRANSFORM_FAILED';
--
--        TYPE update_trxn_header_err_type IS
--            TABLE OF cur_update_trxn_header_err%rowtype;
--        lv_update_trxn_header_err update_trxn_header_err_type;
    
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    -- Derive the COA map ID for a given source/ target system value.
    -- COA Map ID will subsequently be used to derive the COA mapping rules that are assigned to this source / target combination.
    ------------------------------------------------------------------------------------------------------------------------------------------------------
lv_batch_id   NUMBER := p_batch_id; 

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
    
    --        CURSOR cur_leg_seg_value (
    --            cur_p_src_system  VARCHAR2,
    --            cur_p_tgt_system  VARCHAR2
    --        ) IS
    --        SELECT
    --            tgt_coa.leg_coa,
    --			----------------------------------------------------------------------------------------------------------------------------
    --			/**********  The following package call will derive the future state COA combination for legacy COA combination ***********/
    --			--
    --
    --            wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system, cur_p_tgt_system, tgt_coa.leg_seg1, tgt_coa.leg_seg2,
    --                                               tgt_coa.leg_seg3,
    --                                               tgt_coa.leg_seg4,
    --                                               tgt_coa.leg_seg5,
    --                                               tgt_coa.leg_seg6,
    --                                               tgt_coa.leg_seg7,
    --                                               tgt_coa.leg_led_name,
    --                                               NULL,
    --                                               NULL) target_coa 
    --			--
    --			-- End of function call to derive target COA.
    --			----------------------------------------------------------------------------------------------------------------------------                	  
    --
    --        FROM
    --            (
    --                SELECT DISTINCT
    --                    line.GL_BUSINESS_UNIT,
    --                    line.GL_ACCOUNT,
    --                    line.GL_DEPARTMENT,
    --                    line.GL_LOCATION,   /*** Fetches distinct legacy combination values ***/
    --                    line.GL_VENDOR_NBR_FULL,
    --                    line.AFFILIATE
    --                FROM
    --                    wsc_ahcs_CP_txn_line_t    line,
    --                    wsc_ahcs_int_status_t     status
    ----                    wsc_ahcs_CP_txn_header_t  header
    --                WHERE
    --                        status.batch_id = p_batch_id
    --                    AND line.target_coa IS NULL
    --                    AND status.batch_id = line.batch_id
    --                    AND status.header_id = line.header_id
    --                    AND status.line_id = line.line_id
    --                    AND header.batch_id = status.batch_id
    --                    AND header.header_id = status.header_id
    --                    AND header.header_id = line.header_id
    --                    AND header.batch_id = line.batch_id
    --                    AND status.attribute2 = 'VALIDATION_SUCCESS'  /*** Check if the record has been successfully validated through validate procedure ***/
    --            ) tgt_coa;
    --
    --        TYPE leg_seg_value_type IS
    --            TABLE OF cur_leg_seg_value%rowtype;
    --        lv_leg_seg_value                leg_seg_value_type;
    
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
        -- for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_inserting_ccid_table IS
        SELECT DISTINCT
            line.leg_coa    leg_coa,
            line.target_coa target_coa,
            line.LEG_BU,
            line.LEG_ACCT,
            line.LEG_DEPT,
            line.LEG_LOC,
            '0000',
            '00000'
    --            line.leg_seg7,
    --            substr(line.leg_coa, instr(line.leg_coa, '.', 1, 7) + 1)                      AS ledger_name
        FROM
            wsc_ahcs_CP_txn_line_t line
    --              , wsc_ahcs_CP_txn_header_t header
        WHERE
                line.batch_id = p_batch_id 
    --			   and line.batch_id = header.batch_id
    --			   and line.header_id = header.header_id
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        /*
        cursor cur_inserting_ccid_table is
            select distinct LEG_COA, TARGET_COA from wsc_ahcs_CP_txn_line_t
             where batch_id = p_batch_id 
               and attribute1 = 'Y'   
               and substr(target_coa,1,instr(target_coa,'.',1,1)-1) is not null;  
        */

        TYPE inserting_ccid_table_type IS
            TABLE OF cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table   inserting_ccid_table_type;
    
        ------------------------------------------------------------------------------------------------------------------------------------------------------
        -- The following cursor picks up the distinct ledger/ legal entities that have been transformed successfully with future state COA values.
        -- Ledger name is one of the key defaulting attributes required for processing a journal in AHCS.
        ------------------------------------------------------------------------------------------------------------------------------------------------------

--        CURSOR cur_get_ledger IS
--        WITH main_data AS (
--            SELECT
--                lgl_entt.ledger_name,
--                lgl_entt.legal_entity_name,
--                d_lgl_entt.header_id
--            FROM
--                wsc_gl_legal_entities_t lgl_entt,
--                (
--                    SELECT DISTINCT
--                        line.gl_legal_entity,
--                        line.header_id
--                    FROM
--                        wsc_ahcs_CP_txn_line_t line,
--                        wsc_ahcs_int_status_t    status
--                    WHERE
--                            line.header_id = status.header_id
--                        AND line.batch_id = status.batch_id
--                        AND line.line_id = status.line_id
--                        AND status.batch_id = p_batch_id
--                        AND status.attribute2 = 'VALIDATION_SUCCESS'
--                )                       d_lgl_entt
--            WHERE
--                lgl_entt.flex_segment_value (+) = d_lgl_entt.gl_legal_entity
--        )
--        SELECT
--            *
--        FROM
--            main_data a
--        WHERE
--            a.ledger_name IS NOT NULL
--            AND NOT EXISTS (
--                SELECT
--                    1
--                FROM
--                    main_data b
--                WHERE
--                        a.header_id = b.header_id
--                    AND b.ledger_name IS NULL
--            );
--
--        TYPE get_ledger_type IS
--            TABLE OF cur_get_ledger%rowtype;
--        lv_get_ledger             get_ledger_type;


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
    
    --        CURSOR cur_line_validation_after_valid (
    --            cur_p_batch_id NUMBER
    --        ) IS
    --        WITH line_cr AS (
    --            SELECT
    --                header_id,
    --                gl_legal_entity,
    --                SUM(acc_amt) * - 1 sum_data
    --            FROM
    --                wsc_ahcs_CP_txn_line_t
    --            WHERE
    --                    dr_cr_flag = 'CR'
    --                AND batch_id = cur_p_batch_id
    --            GROUP BY
    --                header_id,
    --                gl_legal_entity
    --        ), line_dr AS (
    --            SELECT
    --                header_id,
    --                gl_legal_entity,
    --                SUM(acc_amt) sum_data
    --            FROM
    --                wsc_ahcs_CP_txn_line_t
    --            WHERE
    --                    dr_cr_flag = 'DR'
    --                AND batch_id = cur_p_batch_id
    --            GROUP BY
    --                header_id,
    --                gl_legal_entity
    --        )
    --        SELECT
    --            l_cr.header_id
    --        FROM
    --            line_cr  l_cr,
    --            line_dr  l_dr
    --        WHERE
    --                l_cr.header_id = l_dr.header_id
    --            AND l_dr.gl_legal_entity = l_cr.gl_legal_entity
    --            AND ( l_dr.sum_data <> l_cr.sum_data );
    
        ------------------------------------------------------------------------------------------------------------------------------------------------

--        CURSOR cur_to_update_status (
--            cur_p_batch_id NUMBER
--        ) IS
--        SELECT
--            b.header_id,
--            b.batch_id
--        FROM
--            wsc_ahcs_int_status_t b
--        WHERE
--                b.status = 'TRANSFORM_FAILED'
--            AND b.batch_id = cur_p_batch_id;
    
    --        TYPE line_validation_after_valid_type IS
    --            TABLE OF cur_line_validation_after_valid%rowtype;
    --        lv_line_validation_after_valid  line_validation_after_valid_type;
        lv_coa_mapid              NUMBER;
        lv_src_system             VARCHAR2(100);
        lv_tgt_system             VARCHAR2(100);
        lv_count_succ             NUMBER;
    BEGIN
        
        -------------------------------------------------------------------------------------------------------------------------------------------
    --1. Identity the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('CLOUDPAY', p_batch_id, 15, 'Transformation start', NULL,
                      sysdate);
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_mapid,
            lv_tgt_system,
            lv_src_system;
        CLOSE cur_coa_map_id;
        logging_insert('CLOUDPAY', p_batch_id, 15, 'Transformation start', lv_coa_mapid
                                                                             || lv_tgt_system
                                                                             || lv_src_system,
                      sysdate);
    
    --        update target_coa in cp_line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
    --2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('CLOUDPAY', p_batch_id, 13, 'Check data in cache table to find ', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_CP_txn_line_t line
            SET
                target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa, lv_coa_mapid),
                last_update_date = sysdate
            WHERE
                batch_id = p_batch_id
               /*and exists 
                (select 1 from /*wsc_gl_ccid_mapping_t ccid_map,*/
                         --WSC_AHCS_INT_STATUS_T status 
                  --where /*ccid_map.coa_map_id = lv_coa_mapid and line.leg_coa = ccid_map.source_segment
    --				    and */ status.batch_id = line.batch_id
                   /* and status.header_id = line.header_id
                    and status.line_id = line.line_id
                    and status.status = 'VALIDATION_SUCCESS'
                    and status.attribute2 = 'VALIDATION_SUCCESS'
                    AND batch_id = p_batch_id)*/;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('CLOUDPAY', p_batch_id, 22, 'Error in Check data in cache table to find', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    --        update target_coa and attribute1 'Y' in cp_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('CLOUDPAY', p_batch_id, 17, 'update target_coa and attribute1', NULL,
                      sysdate);
        BEGIN
         /*   open cur_leg_seg_value(lv_src_system, lv_tgt_system);
            loop
            fetch cur_leg_seg_value bulk collect into lv_leg_seg_value limit 100;
            EXIT WHEN lv_leg_seg_value.COUNT = 0;        
            forall i in 1..lv_leg_seg_value.count
                update wsc_ahcs_CP_txn_line_t set target_coa = lv_leg_seg_value(i).target_coa,  ATTRIBUTE1 = 'Y', 
                LAST_UPDATE_DATE = sysdate 
                where LEG_COA = lv_leg_seg_value(i).LEG_COA and batch_id = p_batch_id;
            end loop;
    */

            UPDATE wsc_ahcs_CP_txn_line_t tgt_coa
            SET
                target_coa = replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, tgt_coa.LEG_BU, tgt_coa.LEG_LOC,
                tgt_coa.LEG_DEPT,tgt_coa.LEG_ACCT, null, '00000', NULL, NULL, NULL, NULL), ' ',''),
                attribute1 = 'Y'
            WHERE
                    batch_id = p_batch_id
                AND target_coa IS NULL
                AND EXISTS (
                    SELECT /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */
                        1
                    FROM
                        wsc_ahcs_int_status_t status
                    WHERE
                            status.batch_id = p_batch_id
                        AND status.batch_id = tgt_coa.batch_id
--                        AND status.header_id = tgt_coa.header_id
                        AND status.line_id = tgt_coa.line_id
                        AND status.attribute2 = 'VALIDATION_SUCCESS'
                );

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('CLOUDPAY', p_batch_id, 19, 'Error in update target_coa and attribute1', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    --        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('CLOUDPAY', p_batch_id, 16, 'insert new target_coa values', NULL,
                      sysdate);
        BEGIN
            OPEN cur_inserting_ccid_table;
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
                        lv_coa_mapid,
                        lv_inserting_ccid_table(i).leg_coa,
                        lv_inserting_ccid_table(i).target_coa,
                        sysdate,
                        sysdate,
                        'Y',
                        'N',
                        'CLOUDPAY',
                        'CLOUDPAY',
                        lv_inserting_ccid_table(i).LEG_BU,
                        lv_inserting_ccid_table(i).LEG_LOC,
                        lv_inserting_ccid_table(i).LEG_DEPT,
                        lv_inserting_ccid_table(i).LEG_ACCT,
                        null,
                        '00000',
                        NULL,
                        NULL,
                        NULL,
                        NULL
                    );
                
                --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
            END LOOP;

            CLOSE cur_inserting_ccid_table;
            UPDATE wsc_ahcs_cp_txn_line_t
            SET
                attribute1 = NULL
            WHERE
                batch_id = p_batch_id;

            COMMIT;
             EXCEPTION WHEN OTHERS THEN
                logging_insert('CLOUDPAY', p_batch_id, 16, 'error ', sqlerrm,
                      sysdate);
        END;
    
    --      update cp_line table target segments,  where legal_entity must have their in target_coa
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('CLOUDPAY', p_batch_id, 18, 'update cp_line table target segments', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_CP_txn_line_t
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
                AND substr(target_coa, 1, instr(target_coa, '.', 1, 1) - 1) IS NOT NULL;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
                logging_insert('CLOUDPAY', p_batch_id, 27, 'Error in update cp_line table target segments', sqlerrm,
                              sysdate);
        END;
    
    --        if any target_coa is empty in cp_line table will mark it as transform_error in status table
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('CLOUDPAY', p_batch_id, 19, 'if any target_coa is empty', NULL,
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
                    wsc_ahcs_CP_txn_line_t line
                WHERE
                        status.batch_id = p_batch_id
                    AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
                    AND status.batch_id = line.batch_id
--                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND status.attribute2 = 'VALIDATION_SUCCESS'
            )
            SET
                attribute1 = 'L',
                attribute2 = 'TRANSFORM_FAILED',
                status = 'TRANSFORM_FAILED',
                error_msg = trgt_coa,
                last_updated_date = sysdate;

            COMMIT;
            logging_insert('CLOUDPAY', p_batch_id, 19.1, 'updated attribute2 with TRANSFORM_FAILED status', NULL,
                          sysdate);
--            FOR rcur_to_update_status IN cur_to_update_status(p_batch_id) LOOP
--                UPDATE wsc_ahcs_int_status_t
--                SET
--                    attribute2 = 'TRANSFORM_FAILED',
--                    last_updated_date = sysdate
--                WHERE
--                        batch_id = rcur_to_update_status.batch_id
--                    AND header_id = rcur_to_update_status.header_id;
--
--            END LOOP;  
    
            /*update WSC_AHCS_INT_STATUS_T a
               set ATTRIBUTE2 = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = sysdate
             where a.batch_id = p_batch_id
               AND exists 
              (select 1 from WSC_AHCS_INT_STATUS_T b 
                where a.batch_id = b.batch_id 
                  and a.header_id = b.header_id 
                  and b.status = 'TRANSFORM_FAILED'
                  and b.batch_id = p_batch_id );
                  logging_insert('CP',p_batch_id,19.2,'updated attribute2 with TRANSFORM_FAILED status',null,sysdate);
                  /*merge into WSC_AHCS_INT_STATUS_T a
                    using (select b.header_id,b.batch_id
                            from WSC_AHCS_INT_STATUS_T b 
                        where b.status = 'TRANSFORM_FAILED'
                          and b.batch_id = p_batch_id) b
                          on (a.batch_id = b.batch_id 
                          and a.header_id = b.header_id 
                          and a.batch_id = p_batch_id)
                        when matched then
                        update set a.ATTRIBUTE2 = 'TRANSFORM_FAILED', a.LAST_UPDATED_DATE = sysdate;*/
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('CLOUDPAY', p_batch_id, 29, 'Error in if any target_coa is empty', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    

        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('CLOUDPAY', p_batch_id, 22, 'Update status tables to have status', NULL,
                      sysdate);
        BEGIN
               

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
--                UPDATE wsc_ahcs_int_control_t
--                SET
--                    status = 'TRANSFORM_SUCCESS',
--                    last_updated_date = sysdate
--                WHERE
--                    batch_id = p_batch_id;
--COMMIT;
                BEGIN
                    wsc_ahcs_cp_validation_transformation_pkg.after_transformation(p_batch_id);
                END;
                
--            ELSE
--                UPDATE wsc_ahcs_int_control_t
--                SET
--                    status = 'TRANSFORM_FAILED',
--                    last_updated_date = sysdate
--                WHERE
--                    batch_id = p_batch_id;

            END IF;

            COMMIT;
        END;

        logging_insert('CLOUDPAY', p_batch_id, 23, 'end transformation', NULL,
                      sysdate);
                                           
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT018', 'CLOUDPAY', sqlerrm); 
            
    END leg_coa_transformation;

    

PROCEDURE after_transformation(
        p_batch_id IN NUMBER
    ) AS
    
    lv_batch_id   NUMBER := p_batch_id; 
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
    lv_count_succ number;
    BEGIN
  logging_insert('CLOUDPAY', p_batch_id, 127, 'start after_transformation PROCEDURE', NULL,sysdate);
 --update line table with TRANSACTION_NUMBER
 
 update wsc_ahcs_cp_txn_line_t
 set TRANSACTION_NUMBER= CONCAT(GL_LEGAL_ENTITY, SUBSTR(ATTRIBUTE8,4,16)) 
 where batch_id = p_batch_id and (LEG_BU = 00807 or  LEG_BU = 00824);
  
 commit;  
   logging_insert('CLOUDPAY', p_batch_id, 128, 'updated line table with TRANSACTION_NUMBER', NULL,sysdate);
   
   
--insert records into header table 1st time for this batch_id
logging_insert('CLOUDPAY', p_batch_id, 129, 'Start- insert records into header table', NULL,sysdate);
insert into wsc_ahcs_cp_txn_header_t (
BATCH_ID,
HEADER_ID,
--TRANSACTION_TYPE,
TRANSACTION_DATE,
TRANSACTION_NUMBER,
FILE_NAME,
CREATION_DATE,
CREATED_BY,
LAST_UPDATE_DATE,
LAST_UPDATED_BY
)
(select p_batch_id, wsc_cp_header_t_s1.NEXTVAL, ACCOUNTING_DATE, TRANSACTION_NUMBER , attribute8 , sysdate, 'FIN_INT',
  sysdate,
 'FIN_INT' from ( select  DISTINCT
line.ACCOUNTING_DATE,
line.TRANSACTION_NUMBER,
line.attribute8
 from wsc_ahcs_cp_txn_line_t line
 where  line.batch_id = p_batch_id ));
 
 commit;
 logging_insert('CLOUDPAY', p_batch_id, 130, 'End- insert records into header table', NULL,sysdate);

 --update line table with header id.
  logging_insert('CLOUDPAY', p_batch_id, 131, 'Start- Update header_id in Line table', NULL,sysdate);
  
  merge into wsc_ahcs_cp_txn_line_t line using wsc_ahcs_cp_txn_header_t hdr on ( line.TRANSACTION_NUMBER = hdr.TRANSACTION_NUMBER) when matched then
update set line.header_id = hdr.header_id where  line.batch_id = hdr.batch_id and  line.batch_id = p_batch_id;

        COMMIT;
    logging_insert('CLOUDPAY', p_batch_id, 132, 'End- Update header_id in Line table', NULL,sysdate);   
    
--update status table with header_id and  transaction number
 merge into wsc_ahcs_int_status_t status using wsc_ahcs_cp_txn_line_t line on ( line.line_id = status.line_id) when matched then
update  set status.header_id  = line.header_id, status.ATTRIBUTE3 = line.TRANSACTION_NUMBER where  line.batch_id = status.batch_id and  line.batch_id = p_batch_id;
 
    logging_insert('CLOUDPAY', p_batch_id, 133, 'end - Status table is updated with header_id and TRANSACTION_NUMBER', NULL,sysdate);     

--UPDATE LEDGER_NAME IN HEADER TABLE
 logging_insert('CLOUDPAY', p_batch_id, 134, 'start - ledger derivation', NULL,sysdate);
 begin
     MERGE INTO wsc_ahcs_cp_txn_header_t hdr
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
                                      wsc_ahcs_cp_txn_line_t line,
                                      wsc_ahcs_int_status_t    status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = lv_batch_id
                                      AND status.attribute2 = 'TRANSFORM_SUCCESS'
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
                                          COUNT(1),
                                          b.header_id
                                      FROM
                                          (
                                              SELECT DISTINCT
                                                  a.ledger_name,
                                                  a.header_id
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
            commit;

 logging_insert('cloudpay', p_batch_id, 134.1, 'after IS NOT NULL', NULL,
                      sysdate);

          -- MERGE INTO wsc_ahcs_CP_txn_header_t hdr
            -- USING (
                      -- WITH main_data AS (
                          -- SELECT /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE) */ 
-- --                          SELECT 
                              -- lgl_entt.ledger_name,
                              -- lgl_entt.legal_entity_name,
                              -- d_lgl_entt.header_id
                          -- FROM
                              -- wsc_gl_legal_entities_t lgl_entt,
                              -- (
  -- --                                SELECT 
                                   -- SELECT /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I,batch_status wsc_ahcs_int_status_batch_id_i)  */
                                      -- line.gl_legal_entity,
                                      -- line.header_id
                                  -- FROM
                                      -- wsc_ahcs_cp_txn_line_t line,
                                      -- wsc_ahcs_int_status_t    status
                                  -- WHERE
                                          -- line.header_id = status.header_id
                                      -- AND line.batch_id = status.batch_id
                                      -- AND line.line_id = status.line_id
                                      -- AND status.batch_id = lv_batch_id
                                      -- AND status.attribute2 = 'TRANSFORM_SUCCESS'
                              -- )                       d_lgl_entt
                          -- WHERE
                              -- lgl_entt.flex_segment_value (+) = d_lgl_entt.gl_legal_entity
                      -- )
                      -- SELECT DISTINCT
                          -- a.ledger_name,
                          -- a.header_id
                      -- FROM
                          -- main_data a
                      -- WHERE
                          -- a.ledger_name IS NULL
                  -- )
            -- e ON ( e.header_id = hdr.header_id )
            -- WHEN MATCHED THEN UPDATE
            -- SET hdr.ledger_name = e.ledger_name;


            -- COMMIT;  
            EXCEPTION
            WHEN OTHERS THEN
                logging_insert('CLOUDPAY', p_batch_id, 134, 'Error in update ledger_name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
            logging_insert('CLOUDPAY', p_batch_id, 135, 'end - ledger derivation', NULL,sysdate);
            
       --update status table after ledger_name derivation     
       logging_insert('CLOUDPAY', p_batch_id, 136, 'start - update status table after ledger_name derivation', NULL,sysdate);
             UPDATE (
                    SELECT
                        sts.attribute2,
                        sts.status,
                        sts.last_updated_date,
                        sts.error_msg
                    FROM
                        wsc_ahcs_int_status_t     sts,
                        wsc_ahcs_CP_txn_header_t  hdr
                    WHERE
                            sts.batch_id = p_batch_id
                        AND hdr.header_id = sts.header_id
                        AND hdr.batch_id = sts.batch_id
                        AND hdr.ledger_name IS NULL
                        AND sts.error_msg IS NULL
                        AND sts.attribute2 = 'TRANSFORM_SUCCESS'
                )
                SET
                    error_msg = 'Ledger derivation failed',
                    attribute2 = 'TRANSFORM_FAILED',
                    status = 'TRANSFORM_FAILED',
                    last_updated_date = sysdate;
            COMMIT;
             
             logging_insert('CLOUDPAY', p_batch_id, 137, 'end - update status table after ledger_name derivation', NULL,sysdate);       

 BEGIN
               

            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'TRANSFORM_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
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

end;

logging_insert('CLOUDPAY', p_batch_id, 138, 'start - update control table with transformation status', NULL,sysdate);

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
                COMMIT;
            ELSE
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'TRANSFORM_FAILED',
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            END IF;

            COMMIT;
            logging_insert('CLOUDPAY', p_batch_id, 139, 'end - update control table with transformation status', NULL,sysdate);
            logging_insert('CLOUDPAY', p_batch_id, 140, 'end- after_transformation proc', NULL,sysdate);
END after_transformation;

 PROCEDURE leg_coa_transformation_reprocessing (
        p_batch_id IN NUMBER
    ) IS
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
       
--        CURSOR cur_update_trxn_line_err IS
--        SELECT
--            line.batch_id,
--            --line.header_id,
--            line.line_id,
--            line.target_coa
--        FROM
--            wsc_ahcs_CP_txn_line_t line,
--            wsc_ahcs_int_status_t    status
--		
--        WHERE
--                line.batch_id = p_batch_id
--            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
--            AND status.batch_id = line.batch_id
--            --AND status.header_id = line.header_id
--            AND status.line_id = line.line_id
--            AND status.attribute2 = 'VALIDATION_SUCCESS'; /*ATTRIBUTE2 */
--
--        TYPE update_trxn_line_err_type IS
--            TABLE OF cur_update_trxn_line_err%rowtype;
--        lv_update_trxn_line_err   update_trxn_line_err_type;
        
        
--        CURSOR cur_update_trxn_header_err IS
--        SELECT DISTINCT
--            status.header_id,
--            status.batch_id
--        FROM
--            wsc_ahcs_int_status_t status
--        WHERE
--                status.batch_id = p_batch_id
--            AND status.status = 'TRANSFORM_FAILED';
--
--        TYPE update_trxn_header_err_type IS
--            TABLE OF cur_update_trxn_header_err%rowtype;
--        lv_update_trxn_header_err update_trxn_header_err_type;
    
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    -- Derive the COA map ID for a given source/ target system value.
    -- COA Map ID will subsequently be used to derive the COA mapping rules that are assigned to this source / target combination.
    ------------------------------------------------------------------------------------------------------------------------------------------------------
lv_batch_id   NUMBER := p_batch_id; 

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
    
    --        CURSOR cur_leg_seg_value (
    --            cur_p_src_system  VARCHAR2,
    --            cur_p_tgt_system  VARCHAR2
    --        ) IS
    --        SELECT
    --            tgt_coa.leg_coa,
    --			----------------------------------------------------------------------------------------------------------------------------
    --			/**********  The following package call will derive the future state COA combination for legacy COA combination ***********/
    --			--
    --
    --            wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system, cur_p_tgt_system, tgt_coa.leg_seg1, tgt_coa.leg_seg2,
    --                                               tgt_coa.leg_seg3,
    --                                               tgt_coa.leg_seg4,
    --                                               tgt_coa.leg_seg5,
    --                                               tgt_coa.leg_seg6,
    --                                               tgt_coa.leg_seg7,
    --                                               tgt_coa.leg_led_name,
    --                                               NULL,
    --                                               NULL) target_coa 
    --			--
    --			-- End of function call to derive target COA.
    --			----------------------------------------------------------------------------------------------------------------------------                	  
    --
    --        FROM
    --            (
    --                SELECT DISTINCT
    --                    line.GL_BUSINESS_UNIT,
    --                    line.GL_ACCOUNT,
    --                    line.GL_DEPARTMENT,
    --                    line.GL_LOCATION,   /*** Fetches distinct legacy combination values ***/
    --                    line.GL_VENDOR_NBR_FULL,
    --                    line.AFFILIATE
    --                FROM
    --                    wsc_ahcs_CP_txn_line_t    line,
    --                    wsc_ahcs_int_status_t     status
    ----                    wsc_ahcs_CP_txn_header_t  header
    --                WHERE
    --                        status.batch_id = p_batch_id
    --                    AND line.target_coa IS NULL
    --                    AND status.batch_id = line.batch_id
    --                    AND status.header_id = line.header_id
    --                    AND status.line_id = line.line_id
    --                    AND header.batch_id = status.batch_id
    --                    AND header.header_id = status.header_id
    --                    AND header.header_id = line.header_id
    --                    AND header.batch_id = line.batch_id
    --                    AND status.attribute2 = 'VALIDATION_SUCCESS'  /*** Check if the record has been successfully validated through validate procedure ***/
    --            ) tgt_coa;
    --
    --        TYPE leg_seg_value_type IS
    --            TABLE OF cur_leg_seg_value%rowtype;
    --        lv_leg_seg_value                leg_seg_value_type;
    
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
        -- for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_inserting_ccid_table IS
        SELECT DISTINCT
            line.leg_coa    leg_coa,
            line.target_coa target_coa,
            line.LEG_BU,
            line.LEG_ACCT,
            line.LEG_DEPT,
            line.LEG_LOC,
            '0000',
            '00000'
    --            line.leg_seg7,
    --            substr(line.leg_coa, instr(line.leg_coa, '.', 1, 7) + 1)                      AS ledger_name
        FROM
            wsc_ahcs_CP_txn_line_t line
    --              , wsc_ahcs_CP_txn_header_t header
        WHERE
                line.batch_id = p_batch_id 
    --			   and line.batch_id = header.batch_id
    --			   and line.header_id = header.header_id
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        /*
        cursor cur_inserting_ccid_table is
            select distinct LEG_COA, TARGET_COA from wsc_ahcs_CP_txn_line_t
             where batch_id = p_batch_id 
               and attribute1 = 'Y'   
               and substr(target_coa,1,instr(target_coa,'.',1,1)-1) is not null;  
        */

        TYPE inserting_ccid_table_type IS
            TABLE OF cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table   inserting_ccid_table_type;
    
        ------------------------------------------------------------------------------------------------------------------------------------------------------
        -- The following cursor picks up the distinct ledger/ legal entities that have been transformed successfully with future state COA values.
        -- Ledger name is one of the key defaulting attributes required for processing a journal in AHCS.
        ------------------------------------------------------------------------------------------------------------------------------------------------------

--        CURSOR cur_get_ledger IS
--        WITH main_data AS (
--            SELECT
--                lgl_entt.ledger_name,
--                lgl_entt.legal_entity_name,
--                d_lgl_entt.header_id
--            FROM
--                wsc_gl_legal_entities_t lgl_entt,
--                (
--                    SELECT DISTINCT
--                        line.gl_legal_entity,
--                        line.header_id
--                    FROM
--                        wsc_ahcs_CP_txn_line_t line,
--                        wsc_ahcs_int_status_t    status
--                    WHERE
--                            line.header_id = status.header_id
--                        AND line.batch_id = status.batch_id
--                        AND line.line_id = status.line_id
--                        AND status.batch_id = p_batch_id
--                        AND status.attribute2 = 'VALIDATION_SUCCESS'
--                )                       d_lgl_entt
--            WHERE
--                lgl_entt.flex_segment_value (+) = d_lgl_entt.gl_legal_entity
--        )
--        SELECT
--            *
--        FROM
--            main_data a
--        WHERE
--            a.ledger_name IS NOT NULL
--            AND NOT EXISTS (
--                SELECT
--                    1
--                FROM
--                    main_data b
--                WHERE
--                        a.header_id = b.header_id
--                    AND b.ledger_name IS NULL
--            );
--
--        TYPE get_ledger_type IS
--            TABLE OF cur_get_ledger%rowtype;
--        lv_get_ledger             get_ledger_type;


        CURSOR cur_count_sucss (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            COUNT(1)
        FROM
            wsc_ahcs_int_status_t
        WHERE
                batch_id = cur_p_batch_id
            AND attribute2 = 'TRANSFORM_SUCCESS'
            AND ( accounting_status IS NULL
                  OR accounting_status = 'IMP_ACC_ERROR' );
    
        --- @@@@@@@@@@@@@@@@@@@@@@@@   
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will do a similar matching of total debits and credits but will be restricted at line level. 
        -- ONLY debit not matching to credit at transaction level will be detected after validation.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        /******* @@@@@@@@ Modify this cursor to reflect the appropriate line tables. Also verify the column names are correct @@@@@@@ ********/
    
    --        CURSOR cur_line_validation_after_valid (
    --            cur_p_batch_id NUMBER
    --        ) IS
    --        WITH line_cr AS (
    --            SELECT
    --                header_id,
    --                gl_legal_entity,
    --                SUM(acc_amt) * - 1 sum_data
    --            FROM
    --                wsc_ahcs_CP_txn_line_t
    --            WHERE
    --                    dr_cr_flag = 'CR'
    --                AND batch_id = cur_p_batch_id
    --            GROUP BY
    --                header_id,
    --                gl_legal_entity
    --        ), line_dr AS (
    --            SELECT
    --                header_id,
    --                gl_legal_entity,
    --                SUM(acc_amt) sum_data
    --            FROM
    --                wsc_ahcs_CP_txn_line_t
    --            WHERE
    --                    dr_cr_flag = 'DR'
    --                AND batch_id = cur_p_batch_id
    --            GROUP BY
    --                header_id,
    --                gl_legal_entity
    --        )
    --        SELECT
    --            l_cr.header_id
    --        FROM
    --            line_cr  l_cr,
    --            line_dr  l_dr
    --        WHERE
    --                l_cr.header_id = l_dr.header_id
    --            AND l_dr.gl_legal_entity = l_cr.gl_legal_entity
    --            AND ( l_dr.sum_data <> l_cr.sum_data );
    
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
    
    --        TYPE line_validation_after_valid_type IS
    --            TABLE OF cur_line_validation_after_valid%rowtype;
    --        lv_line_validation_after_valid  line_validation_after_valid_type;
        lv_coa_mapid                    NUMBER;
        lv_src_system                   VARCHAR2(100);
        lv_tgt_system                   VARCHAR2(100);
        lv_count_succ                   NUMBER;
        retcode                         VARCHAR2(50);
        err_msg                         VARCHAR2(50);
    BEGIN
        
        -------------------------------------------------------------------------------------------------------------------------------------------
    --1. Identity the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('CLOUDPAY', p_batch_id, 15, 'REPROCESSING Transformation start', NULL,
                      sysdate);
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_mapid,
            lv_tgt_system,
            lv_src_system;
        CLOSE cur_coa_map_id;
        logging_insert('CLOUDPAY', p_batch_id, 15, 'Transformation start', lv_coa_mapid
                                                                             || lv_tgt_system
                                                                             || lv_src_system,
                      sysdate);
    
    --        update target_coa in cp_line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
    --2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('CLOUDPAY', p_batch_id, 13, 'Check data in cache table to find ', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_CP_txn_line_t line
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
--                        AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
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
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('CLOUDPAY', p_batch_id, 22, 'Error in Check data in cache table to find', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    --        update target_coa and attribute1 'Y' in cp_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('CLOUDPAY', p_batch_id, 17, 'update target_coa and attribute1', NULL,
                      sysdate);
        BEGIN
         /*   open cur_leg_seg_value(lv_src_system, lv_tgt_system);
            loop
            fetch cur_leg_seg_value bulk collect into lv_leg_seg_value limit 100;
            EXIT WHEN lv_leg_seg_value.COUNT = 0;        
            forall i in 1..lv_leg_seg_value.count
                update wsc_ahcs_CP_txn_line_t set target_coa = lv_leg_seg_value(i).target_coa,  ATTRIBUTE1 = 'Y', 
                LAST_UPDATE_DATE = sysdate 
                where LEG_COA = lv_leg_seg_value(i).LEG_COA and batch_id = p_batch_id;
            end loop;
    */

            UPDATE wsc_ahcs_CP_txn_line_t tgt_coa
            SET
                target_coa = replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, tgt_coa.LEG_BU, tgt_coa.LEG_LOC,
                tgt_coa.LEG_DEPT,tgt_coa.LEG_ACCT, null, '00000', NULL, NULL, NULL, NULL), ' ',''),
                attribute1 = 'Y'
            WHERE
                    batch_id = p_batch_id
                AND target_coa IS NULL
                AND EXISTS (
                    SELECT /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */
                        1
                    FROM
                        wsc_ahcs_int_status_t status
                    WHERE
                            status.batch_id = p_batch_id
                        AND status.batch_id = tgt_coa.batch_id
--                        AND status.header_id = tgt_coa.header_id
                        AND status.line_id = tgt_coa.line_id
                        AND status.attribute2 = 'TRANSFORM_FAILED'
                );

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('CLOUDPAY', p_batch_id, 19, 'Error in update target_coa and attribute1', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    --        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('CLOUDPAY', p_batch_id, 16, 'insert new target_coa values', NULL,
                      sysdate);
        BEGIN
            OPEN cur_inserting_ccid_table;
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
                        lv_coa_mapid,
                        lv_inserting_ccid_table(i).leg_coa,
                        lv_inserting_ccid_table(i).target_coa,
                        sysdate,
                        sysdate,
                        'Y',
                        'N',
                        'CLOUDPAY',
                        'CLOUDPAY',
                        lv_inserting_ccid_table(i).LEG_BU,
                        lv_inserting_ccid_table(i).LEG_LOC,
                        lv_inserting_ccid_table(i).LEG_DEPT,
                        lv_inserting_ccid_table(i).LEG_ACCT,
                        null,
                        '00000',
                        NULL,
                        NULL,
                        NULL,
                        NULL
                    );
                
                --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
            END LOOP;

            CLOSE cur_inserting_ccid_table;
            UPDATE wsc_ahcs_cp_txn_line_t
            SET
                attribute1 = NULL
            WHERE
                batch_id = p_batch_id;

            COMMIT;
             EXCEPTION WHEN OTHERS THEN
                logging_insert('CLOUDPAY', p_batch_id, 16, 'error ', sqlerrm,
                      sysdate);
        END;
    
    --      update cp_line table target segments,  where legal_entity must have their in target_coa
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('CLOUDPAY', p_batch_id, 18, 'update cp_line table target segments', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_CP_txn_line_t
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
                AND substr(target_coa, 1, instr(target_coa, '.', 1, 1) - 1) IS NOT NULL;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
                logging_insert('CLOUDPAY', p_batch_id, 27, 'Error in update cp_line table target segments', sqlerrm,
                              sysdate);
        END;
    
    --        if any target_coa is empty in cp_line table will mark it as transform_error in status table
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('CLOUDPAY', p_batch_id, 19, 'if any target_coa is empty', NULL,
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
                    wsc_ahcs_CP_txn_line_t line
                WHERE
                        status.batch_id = p_batch_id
                    AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
                    AND status.batch_id = line.batch_id
--                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
            )
            SET
                attribute1 = 'L',
                attribute2 = 'TRANSFORM_FAILED',
                status = 'TRANSFORM_FAILED',
                error_msg = trgt_coa,
                last_updated_date = sysdate;

            COMMIT;
            logging_insert('CLOUDPAY', p_batch_id, 19.1, 'updated attribute2 with TRANSFORM_FAILED status', NULL,
                          sysdate);
--            FOR rcur_to_update_status IN cur_to_update_status(p_batch_id) LOOP
--                UPDATE wsc_ahcs_int_status_t
--                SET
--                    attribute2 = 'TRANSFORM_FAILED',
--                    last_updated_date = sysdate
--                WHERE
--                        batch_id = rcur_to_update_status.batch_id
--                    AND header_id = rcur_to_update_status.header_id;
--
--            END LOOP;  
    
            /*update WSC_AHCS_INT_STATUS_T a
               set ATTRIBUTE2 = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = sysdate
             where a.batch_id = p_batch_id
               AND exists 
              (select 1 from WSC_AHCS_INT_STATUS_T b 
                where a.batch_id = b.batch_id 
                  and a.header_id = b.header_id 
                  and b.status = 'TRANSFORM_FAILED'
                  and b.batch_id = p_batch_id );
                  logging_insert('CP',p_batch_id,19.2,'updated attribute2 with TRANSFORM_FAILED status',null,sysdate);
                  /*merge into WSC_AHCS_INT_STATUS_T a
                    using (select b.header_id,b.batch_id
                            from WSC_AHCS_INT_STATUS_T b 
                        where b.status = 'TRANSFORM_FAILED'
                          and b.batch_id = p_batch_id) b
                          on (a.batch_id = b.batch_id 
                          and a.header_id = b.header_id 
                          and a.batch_id = p_batch_id)
                        when matched then
                        update set a.ATTRIBUTE2 = 'TRANSFORM_FAILED', a.LAST_UPDATED_DATE = sysdate;*/
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('CLOUDPAY', p_batch_id, 29, 'Error in if any target_coa is empty', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    

        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('CLOUDPAY', p_batch_id, 22, 'Update status tables to have status', NULL,
                      sysdate);
        BEGIN
               

            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'TRANSFORM_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
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
--                UPDATE wsc_ahcs_int_control_t
--                SET
--                    status = 'TRANSFORM_SUCCESS',
--                    last_updated_date = sysdate
--                WHERE
--                    batch_id = p_batch_id;
--COMMIT;
                BEGIN
                    wsc_ahcs_cp_validation_transformation_pkg.after_transformation(p_batch_id);
                END;
                
--            ELSE
--                UPDATE wsc_ahcs_int_control_t
--                SET
--                    status = 'TRANSFORM_FAILED',
--                    last_updated_date = sysdate
--                WHERE
--                    batch_id = p_batch_id;

            END IF;

            COMMIT;
        END;

        logging_insert('CLOUDPAY', p_batch_id, 23, 'end REPRCOESSING transformation', NULL,
                      sysdate);

 logging_insert('CLOUDPAY', p_batch_id, 125, 'AHCS Dashboard refresh Start', NULL,sysdate);
            wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
  logging_insert('CLOUDPAY', p_batch_id, 126, 'AHCS Dashboard refresh End', NULL,sysdate);
                                           
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT018', 'CLOUDPAY', sqlerrm); 
            
    END leg_coa_transformation_reprocessing;


   FUNCTION is_date_null (
        p_string IN VARCHAR2
    ) RETURN NUMBER IS
    BEGIN
        IF p_string IS NULL THEN
            RETURN 0;
        ELSE
            RETURN 1;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END is_date_null;

    FUNCTION is_long_null (
        p_string IN LONG
    ) RETURN NUMBER IS
    BEGIN
        IF p_string IS NULL THEN
            RETURN 0;
        ELSE
            RETURN 1;
        END IF;
    END is_long_null;

    FUNCTION is_number_null (
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
    END is_number_null;

    FUNCTION is_varchar2_null (
        p_string IN VARCHAR2
    ) RETURN NUMBER IS
    BEGIN
        IF p_string IS NULL THEN
            RETURN 0;
        ELSE
            RETURN 1;
        END IF;
    END is_varchar2_null;

END wsc_ahcs_cp_validation_transformation_pkg;
/