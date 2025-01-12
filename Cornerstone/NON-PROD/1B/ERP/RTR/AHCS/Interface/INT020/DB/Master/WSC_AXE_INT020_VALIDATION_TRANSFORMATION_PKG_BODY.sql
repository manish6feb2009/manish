create or replace PACKAGE BODY wsc_ahcs_lhin_validation_transformation_pkg AS

    err_msg VARCHAR2(100);

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

    PROCEDURE data_validation (
        p_batch_id IN NUMBER
    ) IS

        lv_header_err_msg     VARCHAR2(2000) := NULL;
        lv_line_err_msg       VARCHAR2(2000) := NULL;
        lv_header_err_flag    VARCHAR2(100) := 'false';
        lv_line_err_flag      VARCHAR2(100) := 'false';
        lv_count_sucss        NUMBER := 0;
        retcode               VARCHAR2(50);
        TYPE wsc_header_col_value_type IS
            VARRAY(7) OF VARCHAR2(50); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING HEADER OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        lv_header_col_value   wsc_header_col_value_type := wsc_header_col_value_type('FILE_ID', 'FISCAL_YEAR', 'FISCAL_PERIOD', 'CURRENCY',
        'ASSET_TYPE',
                                                                                  'LEASE_CLASSIFICATION', 'SRC_BATCH_ID');
        TYPE axe_line_col_value_type IS
            VARRAY(10) OF VARCHAR2(50); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING LINE OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        lv_axe_line_col_value axe_line_col_value_type := axe_line_col_value_type('FILE_ID', 'TYPE', 'AMOUNT', 'LEG_ACCOUNT', 'ACCOUNT_DESCRIPTION',
                                                                                'RECORD_ID', 'LEG_BU', 'LEG_LOC', 'LINE_CURRENCY', 'APPLY_DATE');
        TYPE wsc_line_col_value_type IS
            VARRAY(10) OF VARCHAR2(50); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING LINE OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        lv_wsc_line_col_value wsc_line_col_value_type := wsc_line_col_value_type('FILE_ID', 'TYPE', 'AMOUNT', 'LEG_ACCOUNT', 'ACCOUNT_DESCRIPTION',
                                                                                'RECORD_ID', 'LEG_LE', 'LEG_BRANCH', 'LINE_CURRENCY',
                                                                                'APPLY_DATE');


/************ @@@@@ INITIALIZE HEADER AND LINE FLAG TABLE TYPE VARIABLES TO MATCH THE COUNT OF HEADER AND LINE @@@@@ ************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        TYPE wsc_ahcs_lhin_txn_header_type IS
            TABLE OF INTEGER;
        lv_error_lhin_header  wsc_ahcs_lhin_txn_header_type := wsc_ahcs_lhin_txn_header_type('1', '1', '1', '1', '1',
                                                                                           '1', '1', '1', '1', '1',
                                                                                           '1', '1', '1', '1', '1');
        TYPE wsc_ahcs_lhin_txn_line_type IS
            TABLE OF INTEGER;
        lv_error_lhin_line    wsc_ahcs_lhin_txn_line_type := wsc_ahcs_lhin_txn_line_type('1', '1', '1', '1', '1',
                                                                                     '1', '1', '1', '1', '1',
                                                                                     '1', '1', '1', '1', '1'); 


-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from LINE STAGING TABLE THAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_wsc_lhin_line (
            cur_p_hdr_id VARCHAR2
        ) IS
        SELECT
            line_id,
            file_id,
            type,
            amount,
            leg_acct,
            account_description,
            record_id,
            leg_bu,
            leg_loc,
            leg_le,
            leg_branch,
            currency,
            apply_date
        FROM
            wsc_ahcs_lhin_txn_line_t
        WHERE
            header_id = cur_p_hdr_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from HEADER STAGING TABLETHAT MUST BE VALIDATED for data types
---------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_header_id (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            header_id,
            file_id,
            fiscal_year,
            fiscal_period,
            currency,
            asset_type,
            lease_classification,
            src_batch_id
        FROM
            wsc_ahcs_lhin_txn_header_t
        WHERE
            batch_id = cur_p_batch_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/

		------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will do a 3-way match per transaction between total of header , sum of debits at line & sum of credits at line
        -- and identified if there is a mismatch between these.
        -- All header IDs with such mismatches will be fetched for subsequent flagging.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        /******* @@@@@@@@ Modify this cursor to reflect the header and line tables. Also verify the column names are correct @@@@@@@ ********/

        CURSOR cur_header_validation (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            lh.header_id
        FROM
            wsc_ahcs_lhin_txn_header_t lh
        WHERE
                lh.category = 'IFRS'
            AND lh.batch_id = cur_p_batch_id;
		------------------------------------------------------------------------------------------------------------------------------------------------

        TYPE header_validation_type IS
            TABLE OF cur_header_validation%rowtype;
        lv_header_validation  header_validation_type;


		--- @@@@@@@@@@@@@@@@@@@@@@@@   
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will do a similar matching of total debits and credits but will be restricted at line level. 
        -- ONLY debit not matching to credit at transaction level will be detected.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        /******* @@@@@@@@ Modify this cursor to reflect the appropriate line tables. Also verify the column names are correct @@@@@@@ ********/

        CURSOR cur_line_validation (
            cur_p_batch_id NUMBER
        ) IS
        WITH line_cr AS (
            SELECT
                header_id,
                abs(SUM(amount)) sum_data
            FROM
                wsc_ahcs_lhin_txn_line_t
            WHERE
                    db_cr_flag = 'CR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ), line_dr AS (
            SELECT
                header_id,
                abs(SUM(amount)) sum_data
            FROM
                wsc_ahcs_lhin_txn_line_t
            WHERE
                    db_cr_flag = 'DR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        )
        SELECT
            l_cr.header_id
        FROM
            line_cr l_cr,
            line_dr l_dr
        WHERE
                l_cr.header_id = l_dr.header_id
            AND ( l_cr.sum_data <> l_dr.sum_data );

		------------------------------------------------------------------------------------------------------------------------------------------------

        TYPE line_validation_type IS
            TABLE OF cur_line_validation%rowtype;
        lv_line_validation    line_validation_type;
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

        l_system              VARCHAR2(200);
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
        logging_insert('LEASES', p_batch_id, 11, 'Start of validation', NULL,
                      sysdate);
	 --- SKIP LE IF INVALID
      BEGIN	  --- Added for DP-RTR-AHCS-149 on Dec-1-22
		UPDATE wsc_ahcs_int_status_t status
            SET
                status.status = 'SKIPPED',
				status.attribute2='SKIPPED',
                last_updated_date = sysdate
            WHERE
                    status.batch_id = p_batch_id
                AND  EXISTS (
                    SELECT
                        1
                    FROM
                        WSC_AHCS_INT_COM_LOOKUP_T ml,
						wsc_ahcs_lhin_txn_line_t L
                    WHERE 
					ml.source = 'LEASES'
                        AND ml.ATTRIBUTE1 = L.leg_bu
						  AND STATUS.LINE_ID=L.line_id
                );	
        logging_insert('LEASES', p_batch_id, 11.1, 'LE SKIP', NULL,
                      sysdate);				
	  END;			  
					  
        BEGIN
            SELECT
                CASE
                    WHEN file_name LIKE '%NW%'
                         OR file_name LIKE '%RW%' THEN
                        'WESCO'
                    ELSE
                        'ANIXTER'
                END
            INTO l_system
            FROM
                wsc_ahcs_int_control_t c
            WHERE
                c.batch_id = p_batch_id;

            dbms_output.put_line(l_system);
        END;

        BEGIN
            OPEN cur_header_validation(p_batch_id);
            LOOP
                FETCH cur_header_validation
                BULK COLLECT INTO lv_header_validation LIMIT 100;
                EXIT WHEN lv_header_validation.count = 0;
                FORALL i IN 1..lv_header_validation.count
                    UPDATE wsc_ahcs_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = '303|IFRS entries found in header category field.',
                        reextract_required = 'Y',
                        attribute1 = 'H',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        AND header_id = lv_header_validation(i).header_id;

            END LOOP;

            CLOSE cur_header_validation;
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('LEASES', p_batch_id, 11.1, 'Exception while updating Header IFRS Entries error in status table.', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

		------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2. Validate line totals
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
        logging_insert('LEASES', p_batch_id, 12, 'Validate line credit debit amount mismatch.', NULL,
                      sysdate);
        BEGIN
            OPEN cur_line_validation(p_batch_id);
            LOOP
                FETCH cur_line_validation
                BULK COLLECT INTO lv_line_validation LIMIT 100;
                EXIT WHEN lv_line_validation.count = 0;
                FORALL i IN 1..lv_line_validation.count
                    UPDATE wsc_ahcs_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = error_msg || '301|Line DR/CR amount mismatch',
                        reextract_required = 'Y',
                        attribute1 = 'L',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        --AND status = 'NEW'
                        AND header_id = lv_line_validation(i).header_id;

            END LOOP;

            CLOSE cur_line_validation;
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('LEASES', p_batch_id, 12.1, 'Exception while updating line cr db mismatch error to status table.', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- 3. Validate header fields
        --    Identify header fields that fail data type mismatch.
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
        logging_insert('LEASES', p_batch_id, 13, 'Validate header mandatory fields.', NULL,
                      sysdate);
        FOR header_id_f IN cur_header_id(p_batch_id) LOOP
            lv_header_err_flag := 'false';
            lv_header_err_msg := NULL;
            lv_error_lhin_header := wsc_ahcs_lhin_txn_header_type('1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1'); 

/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
/**** @@@ Review/ Change function name to match data type of colum. Also pass the appropriate column name from the cursor @@@@ ******/
/**** @@@ Add more rows if there are more columns to be validated and match it with right function names                       ******/
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
            lv_error_lhin_header(1) := is_varchar2_null(header_id_f.file_id);
            lv_error_lhin_header(2) := is_varchar2_null(header_id_f.fiscal_year);
            lv_error_lhin_header(3) := is_varchar2_null(header_id_f.fiscal_period);
            lv_error_lhin_header(4) := is_varchar2_null(header_id_f.currency);
            lv_error_lhin_header(5) := is_varchar2_null(header_id_f.asset_type);
            lv_error_lhin_header(6) := is_varchar2_null(header_id_f.lease_classification);
            lv_error_lhin_header(7) := is_varchar2_null(header_id_f.src_batch_id);
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
      --    logging_insert (null,p_batch_id,6,'lv_error_poc_header',null,sysdate);
            FOR i IN 1..10 LOOP
                IF lv_error_lhin_header(i) = 0 THEN
                    lv_header_err_msg := lv_header_err_msg
                                         || '300|Missing value of '
                                         || lv_header_col_value(i)
                                         || '. ';
                    lv_header_err_flag := 'true';
                END IF;
--            logging_insert (null,p_batch_id,7,'lv_error_poc_header',lv_header_err_msg,sysdate);
            END LOOP;

            IF lv_header_err_flag = 'true' THEN
                UPDATE wsc_ahcs_int_status_t
                SET
                    status = 'VALIDATION_FAILED',
                    error_msg = error_msg || lv_header_err_msg,
                    reextract_required = 'Y',
                    attribute1 = 'H',
                    attribute2 = 'VALIDATION_FAILED',
                    last_updated_date = sysdate
                WHERE
                        batch_id = p_batch_id
                    --AND status = 'NEW'
                    AND header_id = header_id_f.header_id;

                COMMIT;
                CONTINUE;
            END IF;
       --    logging_insert (null,p_batch_id,8,'lv_header_err_flag end',lv_header_err_flag,sysdate);

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

/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
/**** @@@ Review/ Change function name to match data type of colum. Also pass the appropriate column name from the cursor @@@@ ******/
/**** @@@ Add more rows if there are more columns to be validated and match it with right function names                       ******/
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
    --   logging_insert (null,p_batch_id,9,'lv_line_err_flag',null,sysdate);

            FOR wsc_lhin_line IN cur_wsc_lhin_line(header_id_f.header_id) LOOP
                lv_line_err_flag := 'false';
                lv_line_err_msg := NULL;
                lv_error_lhin_line := wsc_ahcs_lhin_txn_line_type('1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1');

                IF l_system = 'ANIXTER' THEN
                    lv_error_lhin_line(1) := is_varchar2_null(wsc_lhin_line.file_id);
                    lv_error_lhin_line(2) := is_varchar2_null(wsc_lhin_line.type);
                    lv_error_lhin_line(3) := is_number_null(wsc_lhin_line.amount);
                    lv_error_lhin_line(4) := is_varchar2_null(wsc_lhin_line.leg_acct);
                    lv_error_lhin_line(5) := is_varchar2_null(wsc_lhin_line.account_description);
                    lv_error_lhin_line(6) := is_varchar2_null(wsc_lhin_line.record_id);
                    lv_error_lhin_line(7) := is_varchar2_null(wsc_lhin_line.leg_bu);
                    lv_error_lhin_line(8) := is_varchar2_null(wsc_lhin_line.leg_loc);
                    lv_error_lhin_line(9) := is_varchar2_null(wsc_lhin_line.currency);
                    lv_error_lhin_line(10) := is_date_null(wsc_lhin_line.apply_date);
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
         --   logging_insert (null,p_batch_id,10,'lv_error_poc_line',null,sysdate);
                    FOR j IN 1..12 LOOP
                        IF lv_error_lhin_line(j) = 0 THEN
                            lv_line_err_msg := lv_line_err_msg
                                               || '300|Missng value of '
                                               || lv_axe_line_col_value(j)
                                               || '. ';
                            lv_line_err_flag := 'true';
                        END IF;
                    END LOOP;

                ELSE
                    lv_error_lhin_line(1) := is_varchar2_null(wsc_lhin_line.file_id);
                    lv_error_lhin_line(2) := is_varchar2_null(wsc_lhin_line.type);
                    lv_error_lhin_line(3) := is_number_null(wsc_lhin_line.amount);
                    lv_error_lhin_line(4) := is_varchar2_null(wsc_lhin_line.leg_acct);
                    lv_error_lhin_line(5) := is_varchar2_null(wsc_lhin_line.account_description);
                    lv_error_lhin_line(6) := is_varchar2_null(wsc_lhin_line.record_id);
                    lv_error_lhin_line(7) := is_varchar2_null(wsc_lhin_line.leg_le);
                    lv_error_lhin_line(8) := is_varchar2_null(wsc_lhin_line.leg_branch);
                    lv_error_lhin_line(9) := is_varchar2_null(wsc_lhin_line.currency);
                    lv_error_lhin_line(10) := is_date_null(wsc_lhin_line.apply_date);
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
         --   logging_insert (null,p_batch_id,10,'lv_error_poc_line',null,sysdate);
                    FOR j IN 1..12 LOOP
                        IF lv_error_lhin_line(j) = 0 THEN
                            lv_line_err_msg := lv_line_err_msg
                                               || '300|Missng value of '
                                               || lv_wsc_line_col_value(j)
                                               || '. ';
                            lv_line_err_flag := 'true';
                        END IF;
                    END LOOP;

                END IF;
--logging_insert (null,p_batch_id,11,'lv_error_poc_line',null,sysdate);
                IF lv_line_err_flag = 'true' THEN
                    UPDATE wsc_ahcs_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = error_msg || lv_line_err_msg,
                        reextract_required = 'Y',
                        attribute1 = 'L',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        --AND status = 'NEW'
                        AND header_id = header_id_f.header_id
                        AND line_id = wsc_lhin_line.line_id;

                    UPDATE wsc_ahcs_int_status_t
                    SET
                        attribute1 = 'L',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        AND status = 'NEW'
                        AND header_id = header_id_f.header_id;

                END IF;
         --    logging_insert (null,p_batch_id,12,'lv_line_err_flag',lv_line_err_flag,sysdate);
            END LOOP;
 --  logging_insert (null,p_batch_id,120,'end of a header',header_id_f.header_id,sysdate);
        END LOOP;

        COMMIT;
        logging_insert('LEASES', p_batch_id, 14, 'Validating header and line mandatory fields ends.', NULL,
                      sysdate);
        BEGIN
            logging_insert('LEASES', p_batch_id, 15, 'Start updating validation status in status table.', NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'VALIDATION_FAILED',
                error_msg = error_msg || '300|Missing value of FILE_ID',
                reextract_required = 'Y',
                attribute1 = 'L',
                attribute2 = 'VALIDATION_FAILED',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                --AND status = 'NEW'
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
            logging_insert('LEASES', p_batch_id, 16, 'Status field updated in status table.', NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                attribute2 = 'VALIDATION_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND attribute2 IS NULL;

            COMMIT;
            logging_insert('LEASES', p_batch_id, 17, 'Attribute2 field updated in status table.', NULL,
                          sysdate);
            OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_sucss;
            CLOSE cur_count_sucss;
            logging_insert('LEASES', p_batch_id, 18, 'Count Success records', lv_count_sucss,
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
                    wsc_ahcs_lhin_validation_transformation_pkg.leg_coa_transformation(p_batch_id);
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
            logging_insert('LEASES', p_batch_id, 40, 'End of data validation', NULL,
                          sysdate);
            logging_insert('LEASES', p_batch_id, 80, 'Dashboard Start', NULL,
                          sysdate);
            wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
            logging_insert('LEASES', p_batch_id, 81, 'Dashboard End', NULL,
                          sysdate);
        END;

        DELETE FROM wsc_ahcs_lhin_txn_tmp_t
        WHERE
            batch_id = p_batch_id;
COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT020', 'LEASES', sqlerrm);
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
        l_system                  VARCHAR2(30);
        lv_batch_id               NUMBER := p_batch_id;
        retcode                   VARCHAR2(50);
        CURSOR cur_update_trxn_line_err IS
        SELECT
            line.batch_id,
            line.header_id,
            line.line_id,
            line.target_coa
        FROM
            wsc_ahcs_lhin_txn_line_t line,
            wsc_ahcs_int_status_t    status
        WHERE
                line.batch_id = p_batch_id
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
            AND status.batch_id = line.batch_id
            AND status.header_id = line.header_id
            AND status.line_id = line.line_id
            AND status.attribute2 = 'VALIDATION_SUCCESS'; /*ATTRIBUTE2 */

        TYPE update_trxn_line_err_type IS
            TABLE OF cur_update_trxn_line_err%rowtype;
        lv_update_trxn_line_err   update_trxn_line_err_type;
        CURSOR cur_update_trxn_header_err IS
        SELECT DISTINCT
            status.header_id,
            status.batch_id
        FROM
            wsc_ahcs_int_status_t status
        WHERE
                status.batch_id = p_batch_id
            AND status.status = 'TRANSFORM_FAILED';

        TYPE update_trxn_header_err_type IS
            TABLE OF cur_update_trxn_header_err%rowtype;
        lv_update_trxn_header_err update_trxn_header_err_type;
    
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
    --                    wsc_ahcs_lhin_txn_line_t    line,
    --                    wsc_ahcs_int_status_t     status
    ----                    wsc_ahcs_mfap_txn_header_t  header
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
            line.leg_vendor,
            line.leg_acct,
            line.leg_dept,
            line.leg_bu,
            line.leg_le,
            line.leg_branch,
            line.leg_loc
        FROM
            wsc_ahcs_lhin_txn_line_t line
        WHERE
                line.batch_id = p_batch_id
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        /*
        cursor cur_inserting_ccid_table is
            select distinct LEG_COA, TARGET_COA from wsc_ahcs_lhin_txn_line_t
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

        CURSOR cur_get_ledger IS
        WITH main_data AS (
            SELECT
                lgl_entt.ledger_name,
                lgl_entt.legal_entity_name,
                d_lgl_entt.header_id
            FROM
                wsc_gl_legal_entities_t lgl_entt,
                (
                    SELECT DISTINCT
                        line.gl_legal_entity,
                        line.header_id
                    FROM
                        wsc_ahcs_lhin_txn_line_t line,
                        wsc_ahcs_int_status_t    status
                    WHERE
                            line.header_id = status.header_id
                        AND line.batch_id = status.batch_id
                        AND line.line_id = status.line_id
                        AND status.batch_id = p_batch_id
                        AND status.attribute2 = 'VALIDATION_SUCCESS'
                )                       d_lgl_entt
            WHERE
                lgl_entt.flex_segment_value (+) = d_lgl_entt.gl_legal_entity
        )
        SELECT
            *
        FROM
            main_data a
        WHERE
            a.ledger_name IS NOT NULL
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    main_data b
                WHERE
                        a.header_id = b.header_id
                    AND b.ledger_name IS NULL
            );

        TYPE get_ledger_type IS
            TABLE OF cur_get_ledger%rowtype;
        lv_get_ledger             get_ledger_type;
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
    --                wsc_ahcs_lhin_txn_line_t
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
    --                wsc_ahcs_lhin_txn_line_t
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
        lv_coa_mapid              NUMBER;
        lv_src_system             VARCHAR2(100);
        lv_tgt_system             VARCHAR2(100);
        lv_count_succ             NUMBER;
    BEGIN
--        BEGIN
--            SELECT
--                attribute3
--            INTO l_system
--            FROM
--                wsc_ahcs_int_control_t c
--            WHERE
--                c.batch_id = p_batch_id;
--
--            dbms_output.put_line(l_system);
--        END;
        -------------------------------------------------------------------------------------------------------------------------------------------
    --1. Identity the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 19, 'Transformation start', NULL,
                      sysdate);
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_mapid,
            lv_tgt_system,
            lv_src_system;
        CLOSE cur_coa_map_id;
        logging_insert('LEASES', p_batch_id, 20, 'Fetch coa map id, source and target system.', lv_coa_mapid
                                                                                                || lv_tgt_system
                                                                                                || lv_src_system,
                      sysdate);
    
    --        update target_coa in leases line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
    --2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 21, 'Check data in cache table to find ', NULL,
                      sysdate);
        BEGIN
            IF lv_src_system = 'ANIXTER' THEN
                UPDATE wsc_ahcs_lhin_txn_line_t line
                SET
                    target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_bu
                                                                   || '.'
                                                                   || leg_loc
                                                                   || '.'
                                                                   || leg_dept
                                                                   || '.'
                                                                   || leg_acct
                                                                   || '.'
                                                                   || leg_vendor
                                                                   || '.00000', lv_coa_mapid),
                    last_update_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            ELSE
                UPDATE wsc_ahcs_lhin_txn_line_t line
                SET
                    target_coa = wsc_gl_coa_mapping_pkg.ccid_match('.'
                                                                   || lpad(leg_branch, 6, '0')
                                                                   || '.'
                                                                   || leg_acct
                                                                   || '.000.000000.000000.000000.', lv_coa_mapid)
                WHERE
                    batch_id = p_batch_id;

            END IF;
               /*and exists 
                (select 1 from /*wsc_gl_ccid_mapping_t ccid_map,*/
                         --WSC_AHCS_INT_STATUS_T status 
                  --where /*ccid_map.coa_map_id = lv_coa_mapid and line.leg_coa = ccid_map.source_segment
    --				    and */ status.batch_id = line.batch_id
                   /* and status.header_id = line.header_id
                    and status.line_id = line.line_id
                    and status.status = 'VALIDATION_SUCCESS'
                    and status.attribute2 = 'VALIDATION_SUCCESS'
                    AND batch_id = p_batch_id)*/

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('LEASES', p_batch_id, 21.1, 'Error in Check data in cache table to find', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    --        update target_coa and attribute1 'Y' in leases line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 22, 'update target_coa and attribute1', NULL,
                      sysdate);
        BEGIN
         /*   open cur_leg_seg_value(lv_src_system, lv_tgt_system);
            loop
            fetch cur_leg_seg_value bulk collect into lv_leg_seg_value limit 100;
            EXIT WHEN lv_leg_seg_value.COUNT = 0;        
            forall i in 1..lv_leg_seg_value.count
                update wsc_ahcs_lhin_txn_line_t set target_coa = lv_leg_seg_value(i).target_coa,  ATTRIBUTE1 = 'Y', 
                LAST_UPDATE_DATE = sysdate 
                where LEG_COA = lv_leg_seg_value(i).LEG_COA and batch_id = p_batch_id;
            end loop;
    */
            IF lv_src_system = 'ANIXTER' THEN
                UPDATE wsc_ahcs_lhin_txn_line_t tgt_coa
                SET
                    target_coa = replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, tgt_coa.leg_bu, tgt_coa.leg_loc,
                    tgt_coa.leg_dept,
                                                                            tgt_coa.leg_acct, tgt_coa.leg_vendor, '00000', NULL, NULL,
                                                                            NULL, NULL), ' ', ''),
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
                            AND status.header_id = tgt_coa.header_id
                            AND status.line_id = tgt_coa.line_id
                            AND status.attribute2 = 'VALIDATION_SUCCESS'
                    );

                COMMIT;
            ELSE
                UPDATE wsc_ahcs_lhin_txn_line_t tgt_coa
                SET
                    target_coa = replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, NULL, lpad(tgt_coa.leg_branch,
                    6, '0'), tgt_coa.leg_acct, '000', NULL, NULL,
                                                                            NULL, NULL, NULL, NULL), ' ', ''),
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
                            AND status.header_id = tgt_coa.header_id
                            AND status.line_id = tgt_coa.line_id
                            AND status.attribute2 = 'VALIDATION_SUCCESS'
                    );

                COMMIT;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('LEASES', p_batch_id, 22.1, 'Error in update target_coa and attribute1', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    --        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 23, 'insert new target_coa values', NULL,
                      sysdate);
        BEGIN
            IF lv_src_system = 'ANIXTER' THEN
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
                            lv_inserting_ccid_table(i).leg_bu
                            || '.'
                            || lv_inserting_ccid_table(i).leg_loc
                            || '.'
                            || lv_inserting_ccid_table(i).leg_dept
                            || '.'
                            || lv_inserting_ccid_table(i).leg_acct
                            || '.'
                            || lv_inserting_ccid_table(i).leg_vendor
                            || '.00000',
                            lv_inserting_ccid_table(i).target_coa,
                            sysdate,
                            sysdate,
                            'Y',
                            'N',
                            'LEASES',
                            'LEASES',
                            lv_inserting_ccid_table(i).leg_bu,
                            lv_inserting_ccid_table(i).leg_loc,
                            lv_inserting_ccid_table(i).leg_dept,
                            lv_inserting_ccid_table(i).leg_acct,
                            lv_inserting_ccid_table(i).leg_vendor,
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
            ELSE
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
                            '.'
                            || lpad(lv_inserting_ccid_table(i).leg_branch, 6, '0')
                            || '.'
                            || lv_inserting_ccid_table(i).leg_acct
                            || '.000.000000.000000.000000.',
                            lv_inserting_ccid_table(i).target_coa,
                            sysdate,
                            sysdate,
                            'Y',
                            'N',
                            'LEASES',
                            'LEASES',
                            NULL,
                            lpad(lv_inserting_ccid_table(i).leg_branch, 6, '0'),
                            lv_inserting_ccid_table(i).leg_acct,
                            '000',
                            '000000',
                            '000000',
                            '000000',
                            NULL,
                            NULL,
                            NULL
                        );
                --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
                END LOOP;

                CLOSE cur_inserting_ccid_table;
            END IF;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('LEASES', p_batch_id, 23.1, 'error in ccid insert', NULL,
                              sysdate);
        END;

        UPDATE wsc_ahcs_lhin_txn_line_t
        SET
            attribute1 = NULL
        WHERE
            batch_id = p_batch_id;

        COMMIT;
    
    --      update leases line table target segments,  where legal_entity must have their in target_coa
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 24, 'update leases line table target segments', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_lhin_txn_line_t
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
                logging_insert('LEASES', p_batch_id, 24.1, 'Error in update leases line table target segments', sqlerrm,
                              sysdate);
        END;
    
    --        if any target_coa is empty in leases line table will mark it as transform_error in status table
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 25, 'if any target_coa is empty', NULL,
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
                    wsc_ahcs_lhin_txn_line_t line
                WHERE
                        status.batch_id = p_batch_id
                    AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
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
            logging_insert('LEASES', p_batch_id, 26, 'updated attribute2 with TRANSFORM_FAILED status', NULL,
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
    
            /*update WSC_AHCS_INT_STATUS_T a
               set ATTRIBUTE2 = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = sysdate
             where a.batch_id = p_batch_id
               AND exists 
              (select 1 from WSC_AHCS_INT_STATUS_T b 
                where a.batch_id = b.batch_id 
                  and a.header_id = b.header_id 
                  and b.status = 'TRANSFORM_FAILED'
                  and b.batch_id = p_batch_id );
                  logging_insert('LEASES',p_batch_id,19.2,'updated attribute2 with TRANSFORM_FAILED status',null,sysdate);
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
                logging_insert('LEASES', p_batch_id, 26.1, 'Error in if any target_coa is empty', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    --      update ledger_name in leases header table where transform_success		
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 27, 'update ledger_name', NULL,
                      sysdate);
        BEGIN
    --         /*   open cur_get_ledger;
    --            loop
    --            fetch cur_get_ledger bulk collect into lv_get_ledger limit 10;
    --            EXIT WHEN lv_get_ledger.COUNT = 0;        
    --            forall i in 1..lv_get_ledger.count
    --                update wsc_ahcs_mfap_txn_header_t
    --                   set ledger_name = lv_get_ledger(i).ledger_name , LAST_UPDATE_DATE = sysdate
    --                 where batch_id = p_batch_id 
    --				   and header_id = lv_get_ledger(i).header_id
    --                   ;
    --            end loop;*/
    --
            MERGE INTO wsc_ahcs_lhin_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE) */
                              lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t lgl_entt,
                              (
                                  SELECT /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I,batch_status wsc_ahcs_int_status_batch_id_i)  */
                                      line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_lhin_txn_line_t line,
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
                  )
            e ON ( e.header_id = hdr.header_id )
            WHEN MATCHED THEN UPDATE
            SET hdr.ledger_name = e.ledger_name;

            COMMIT;
            logging_insert('LEASES', p_batch_id, 28, 'after IS NOT NULL', NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_lhin_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE) */
                              lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t lgl_entt,
                              (
                                  SELECT /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I,batch_status wsc_ahcs_int_status_batch_id_i)  */
                                      line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_lhin_txn_line_t line,
                                      wsc_ahcs_int_status_t    status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = lv_batch_id
                                      AND status.attribute2 = 'VALIDATION_SUCCESS'
                              )                       d_lgl_entt
                          WHERE
                              lgl_entt.flex_segment_value (+) = d_lgl_entt.gl_legal_entity
                      )
                      SELECT DISTINCT
                          a.ledger_name,
                          a.header_id
                      FROM
                          main_data a
                      WHERE
                          a.ledger_name IS NULL
                  )
            e ON ( e.header_id = hdr.header_id )
            WHEN MATCHED THEN UPDATE
            SET hdr.ledger_name = e.ledger_name;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('LEASES', p_batch_id, 28.1, 'Error in update ledger_name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        BEGIN
        --- update accounted currency in line table with respect to the derived ledger ----
            UPDATE wsc_ahcs_lhin_txn_line_t line
            SET
                accounted_currency = (
                    SELECT
                        currency_code
                    FROM
                        wsc_gl_legal_entities_t gle
                    WHERE
                        line.gl_legal_entity = gle.flex_segment_value
                )
            WHERE
                line.batch_id = p_batch_id;
-- update ledger name into status table----
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_lhin_txn_header_t h
                      WHERE
                          h.batch_id = p_batch_id
                  )
            hdr ON ( sts.batch_id = hdr.batch_id
                     AND sts.header_id = hdr.header_id
                     AND sts.batch_id = p_batch_id
                     AND sts.accounting_status IS NULL )
            WHEN MATCHED THEN UPDATE
            SET sts.ledger_name = hdr.ledger_name;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('LEASES', p_batch_id, 28.2, 'Error in update ACCOUNTED_CURRENCY in LHIN Line Table', sqlerrm,
                              sysdate);
        END;
    
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 7.1. Update status tables after validation where line cr/dr mismatch.
        --    /******* ALL RECORDS MARKED AS VALIDATION FAILED WHEN LINE CR/DR AMOUNT MISMATCH AFTER VALIDATION ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 29, 'Update status tables after validation', NULL,
                      sysdate);
        /*begin
            open cur_line_validation_after_valid(p_batch_id);
            loop
            fetch cur_line_validation_after_valid bulk collect into lv_line_validation_after_valid limit 100;
            EXIT WHEN lv_line_validation_after_valid.COUNT = 0;        
            forall i in 1..lv_line_validation_after_valid.count
                update WSC_AHCS_INT_STATUS_T set STATUS = 'VALIDATION_FAILED', 
                    ERROR_MSG = 'Line DR/CR amount mismatch after validation', 
                    ATTRIBUTE1 = 'L',
                    ATTRIBUTE2='VALIDATION_FAILED', 
                    LAST_UPDATED_DATE = sysdate
                where BATCH_ID = P_BATCH_ID 
                  and HEADER_ID = lv_line_validation_after_valid(i).header_id;
            end loop;
            commit;
        exception
            when others then
                logging_insert('LEASES',p_batch_id,23,'Update status tables after validation',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end; */
    
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 30, 'Update status tables to have status', NULL,
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
                    wsc_ahcs_lhin_txn_header_t hdr
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

        logging_insert('LEASES', p_batch_id, 31, 'end transformation', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT020', 'LEASES', sqlerrm);
    END leg_coa_transformation;

    PROCEDURE leg_coa_transformation_reprocessing (
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
        l_system                  VARCHAR2(30);
        lv_batch_id               NUMBER := p_batch_id;
        lv_group_id               NUMBER; --added for reprocess individual group id process 24th Nov 2022
        retcode                   VARCHAR2(50);
        CURSOR cur_update_trxn_line_err IS
        SELECT
            line.batch_id,
            line.header_id,
            line.line_id,
            line.target_coa
        FROM
            wsc_ahcs_lhin_txn_line_t line,
            wsc_ahcs_int_status_t    status
        WHERE
                line.batch_id = p_batch_id
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
            AND status.batch_id = line.batch_id
            AND status.header_id = line.header_id
            AND status.line_id = line.line_id
            AND status.attribute2 = 'VALIDATION_SUCCESS'; /*ATTRIBUTE2 */

        TYPE update_trxn_line_err_type IS
            TABLE OF cur_update_trxn_line_err%rowtype;
        lv_update_trxn_line_err   update_trxn_line_err_type;
        CURSOR cur_update_trxn_header_err IS
        SELECT DISTINCT
            status.header_id,
            status.batch_id
        FROM
            wsc_ahcs_int_status_t status
        WHERE
                status.batch_id = p_batch_id
            AND status.status = 'TRANSFORM_FAILED';

        TYPE update_trxn_header_err_type IS
            TABLE OF cur_update_trxn_header_err%rowtype;
        lv_update_trxn_header_err update_trxn_header_err_type;
    
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

    
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
        -- for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_inserting_ccid_table IS
        SELECT DISTINCT
            line.leg_coa    leg_coa,
            line.target_coa target_coa,
            line.leg_vendor,
            line.leg_acct,
            line.leg_dept,
            line.leg_bu,
            line.leg_le,
            line.leg_branch,
            line.leg_loc
        FROM
            wsc_ahcs_lhin_txn_line_t line
        WHERE
                line.batch_id = p_batch_id
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */

        TYPE inserting_ccid_table_type IS
            TABLE OF cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table   inserting_ccid_table_type;
    
        ------------------------------------------------------------------------------------------------------------------------------------------------------
        -- The following cursor picks up the distinct ledger/ legal entities that have been transformed successfully with future state COA values.
        -- Ledger name is one of the key defaulting attributes required for processing a journal in AHCS.
        ------------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_get_ledger IS
        WITH main_data AS (
            SELECT
                lgl_entt.ledger_name,
                lgl_entt.legal_entity_name,
                d_lgl_entt.header_id
            FROM
                wsc_gl_legal_entities_t lgl_entt,
                (
                    SELECT DISTINCT
                        line.gl_legal_entity,
                        line.header_id
                    FROM
                        wsc_ahcs_lhin_txn_line_t line,
                        wsc_ahcs_int_status_t    status
                    WHERE
                            line.header_id = status.header_id
                        AND line.batch_id = status.batch_id
                        AND line.line_id = status.line_id
                        AND status.batch_id = p_batch_id
                        AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                )                       d_lgl_entt
            WHERE
                lgl_entt.flex_segment_value (+) = d_lgl_entt.gl_legal_entity
        )
        SELECT
            *
        FROM
            main_data a
        WHERE
            a.ledger_name IS NOT NULL
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    main_data b
                WHERE
                        a.header_id = b.header_id
                    AND b.ledger_name IS NULL
            );

        TYPE get_ledger_type IS
            TABLE OF cur_get_ledger%rowtype;
        lv_get_ledger             get_ledger_type;
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

        CURSOR lhin_grp_data_fetch_cur ( --added for reprocess individual group id process 24th Nov 2022
            p_grp_id NUMBER
        ) IS
        SELECT DISTINCT
            c.batch_id           batch_id,
            c.file_name          file_name,
            a.ledger_name        ledger_name,
            c.source_application source_application,
            'LEASES'             interface_id,
            c.status             status
        FROM
            wsc_ahcs_int_control_t     c,
            wsc_ahcs_lhin_txn_header_t a
        WHERE
                a.batch_id = c.batch_id
            AND a.ledger_name IS NOT NULL
            AND c.status = 'TRANSFORM_SUCCESS'
            AND c.group_id = p_grp_id
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
            );

        TYPE lhin_grp_type IS
            TABLE OF lhin_grp_data_fetch_cur%rowtype;
        lv_lhin_grp_type          lhin_grp_type;
        lv_coa_mapid              NUMBER;
        lv_src_system             VARCHAR2(100);
        lv_tgt_system             VARCHAR2(100);
        lv_count_succ             NUMBER;
    BEGIN
        BEGIN
            SELECT
                attribute3
            INTO l_system
            FROM
                wsc_ahcs_int_control_t c
            WHERE
                c.batch_id = p_batch_id;

            dbms_output.put_line(l_system);
        END;
        -------------------------------------------------------------------------------------------------------------------------------------------
    --1. Identity the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 19, 'Transformation start', NULL,
                      sysdate);
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_mapid,
            lv_tgt_system,
            lv_src_system;
        CLOSE cur_coa_map_id;
        logging_insert('LEASES', p_batch_id, 20, 'Fetch coa map id, source and target system.', lv_coa_mapid
                                                                                                || lv_tgt_system
                                                                                                || lv_src_system,
                      sysdate);

        BEGIN
            UPDATE wsc_ahcs_lhin_txn_line_t line
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
        END;
 
    --        update target_coa in leases line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
    --2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 21, 'Check data in cache table to find ', NULL,
                      sysdate);
        BEGIN
            IF lv_src_system = 'ANIXTER' THEN
                UPDATE wsc_ahcs_lhin_txn_line_t line
                SET
                    target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_bu
                                                                   || '.'
                                                                   || leg_loc
                                                                   || '.'
                                                                   || leg_dept
                                                                   || '.'
                                                                   || leg_acct
                                                                   || '.'
                                                                   || leg_vendor
                                                                   || '.00000', lv_coa_mapid),
                    last_update_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            ELSE
                UPDATE wsc_ahcs_lhin_txn_line_t line
                SET
                    target_coa = wsc_gl_coa_mapping_pkg.ccid_match('.'
                                                                   || lpad(leg_branch, 6, '0')
                                                                   || '.'
                                                                   || leg_acct
                                                                   || '.000.000000.000000.000000.', lv_coa_mapid)
                WHERE
                    batch_id = p_batch_id;

            END IF;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('LEASES', p_batch_id, 21.1, 'Error in Check data in cache table to find', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    --        update target_coa and attribute1 'Y' in leases line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 22, 'update target_coa and attribute1', NULL,
                      sysdate);
        BEGIN
            IF lv_src_system = 'ANIXTER' THEN
                UPDATE wsc_ahcs_lhin_txn_line_t tgt_coa
                SET
                    target_coa = replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, tgt_coa.leg_bu, tgt_coa.leg_loc,
                    tgt_coa.leg_dept,
                                                                            tgt_coa.leg_acct, tgt_coa.leg_vendor, '00000', NULL, NULL,
                                                                            NULL, NULL), ' ', ''),
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
                            AND status.header_id = tgt_coa.header_id
                            AND status.line_id = tgt_coa.line_id
                            AND status.attribute2 = 'TRANSFORM_FAILED'
                    );

                COMMIT;
            ELSE
                UPDATE wsc_ahcs_lhin_txn_line_t tgt_coa
                SET
                    target_coa = replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, NULL, lpad(tgt_coa.leg_branch,
                    6, '0'), tgt_coa.leg_acct, '000', NULL, NULL,
                                                                            NULL, NULL, NULL, NULL), ' ', ''),
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
                            AND status.header_id = tgt_coa.header_id
                            AND status.line_id = tgt_coa.line_id
                            AND status.attribute2 = 'TRANSFORM_FAILED'
                    );

                COMMIT;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('LEASES', p_batch_id, 22.1, 'Error in update target_coa and attribute1', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    --        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 23, 'insert new target_coa values', NULL,
                      sysdate);
        BEGIN
            IF lv_src_system = 'ANIXTER' THEN
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
                            lv_inserting_ccid_table(i).leg_bu
                            || '.'
                            || lv_inserting_ccid_table(i).leg_loc
                            || '.'
                            || lv_inserting_ccid_table(i).leg_dept
                            || '.'
                            || lv_inserting_ccid_table(i).leg_acct
                            || '.'
                            || lv_inserting_ccid_table(i).leg_vendor
                            || '.00000',
                            lv_inserting_ccid_table(i).target_coa,
                            sysdate,
                            sysdate,
                            'Y',
                            'N',
                            'LEASES',
                            'LEASES',
                            lv_inserting_ccid_table(i).leg_bu,
                            lv_inserting_ccid_table(i).leg_loc,
                            lv_inserting_ccid_table(i).leg_dept,
                            lv_inserting_ccid_table(i).leg_acct,
                            lv_inserting_ccid_table(i).leg_vendor,
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
            ELSE
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
                            '.'
                            || lpad(lv_inserting_ccid_table(i).leg_branch, 6, '0')
                            || '.'
                            || lv_inserting_ccid_table(i).leg_acct
                            || '.000.000000.000000.000000.',
                            lv_inserting_ccid_table(i).target_coa,
                            sysdate,
                            sysdate,
                            'Y',
                            'N',
                            'LEASES',
                            'LEASES',
                            NULL,
                            lpad(lv_inserting_ccid_table(i).leg_branch, 6, '0'),
                            lv_inserting_ccid_table(i).leg_acct,
                            '000',
                            '000000',
                            '000000',
                            '000000',
                            NULL,
                            NULL,
                            NULL
                        );
                --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
                END LOOP;

                CLOSE cur_inserting_ccid_table;
            END IF;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('LEASES', p_batch_id, 23.1, 'error in ccid insert', NULL,
                              sysdate);
        END;

        UPDATE wsc_ahcs_lhin_txn_line_t
        SET
            attribute1 = NULL
        WHERE
            batch_id = p_batch_id;

        COMMIT;
    
    --      update leases line table target segments,  where legal_entity must have their in target_coa
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 24, 'update leases line table target segments', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_lhin_txn_line_t
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
                logging_insert('LEASES', p_batch_id, 24.1, 'Error in update leases line table target segments', sqlerrm,
                              sysdate);
        END;
    
    --        if any target_coa is empty in leases line table will mark it as transform_error in status table
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 25, 'if any target_coa is empty', NULL,
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
                    wsc_ahcs_lhin_txn_line_t line
                WHERE
                        status.batch_id = p_batch_id
                    AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
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
            logging_insert('LEASES', p_batch_id, 26, 'updated attribute2 with TRANSFORM_FAILED status', NULL,
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
                logging_insert('LEASES', p_batch_id, 26.1, 'Error in if any target_coa is empty', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
    
    --      update ledger_name in leases header table where transform_success		
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 27, 'update ledger_name', NULL,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_lhin_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE) */
                              lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t lgl_entt,
                              (
                                  SELECT /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I,batch_status wsc_ahcs_int_status_batch_id_i)  */
                                      line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_lhin_txn_line_t line,
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
                  )
            e ON ( e.header_id = hdr.header_id )
            WHEN MATCHED THEN UPDATE
            SET hdr.ledger_name = e.ledger_name;

            COMMIT;
            logging_insert('LEASES', p_batch_id, 28, 'after IS NOT NULL', NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_lhin_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE) */
                              lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t lgl_entt,
                              (
                                  SELECT /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I,batch_status wsc_ahcs_int_status_batch_id_i)  */
                                      line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_lhin_txn_line_t line,
                                      wsc_ahcs_int_status_t    status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = lv_batch_id
                                      AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                              )                       d_lgl_entt
                          WHERE
                              lgl_entt.flex_segment_value (+) = d_lgl_entt.gl_legal_entity
                      )
                      SELECT DISTINCT
                          a.ledger_name,
                          a.header_id
                      FROM
                          main_data a
                      WHERE
                          a.ledger_name IS NULL
                  )
            e ON ( e.header_id = hdr.header_id )
            WHEN MATCHED THEN UPDATE
            SET hdr.ledger_name = e.ledger_name;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('LEASES', p_batch_id, 28.1, 'Error in update ledger_name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        BEGIN
        --update accounted currency in line table with respect to the derived ledger.----
            UPDATE wsc_ahcs_lhin_txn_line_t line
            SET
                accounted_currency = (
                    SELECT
                        currency_code
                    FROM
                        wsc_gl_legal_entities_t gle
                    WHERE
                        line.gl_legal_entity = gle.flex_segment_value
                )
            WHERE
                line.batch_id = p_batch_id;
-- Update ledger name in the status table --
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_lhin_txn_header_t h
                      WHERE
                          h.batch_id = p_batch_id
                  )
            hdr ON ( sts.batch_id = hdr.batch_id
                     AND sts.header_id = hdr.header_id
                     AND sts.batch_id = p_batch_id
                     AND sts.accounting_status IS NULL )
            WHEN MATCHED THEN UPDATE
            SET sts.ledger_name = hdr.ledger_name;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('LEASES', p_batch_id, 28.2, 'Error in update ACCOUNTED_CURRENCY in LHIN Line Table', sqlerrm,
                              sysdate);
        END;
    
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 7.1. Update status tables after validation where line cr/dr mismatch.
        --    /******* ALL RECORDS MARKED AS VALIDATION FAILED WHEN LINE CR/DR AMOUNT MISMATCH AFTER VALIDATION ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 29, 'Update status tables after validation', NULL,
                      sysdate);
    
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('LEASES', p_batch_id, 30, 'Update status tables to have status', NULL,
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
                    wsc_ahcs_lhin_txn_header_t hdr
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

        BEGIN --added for reprocess individual group id process 24th Nov 2022
            lv_group_id := wsc_ahcs_mf_grp_id_seq.nextval;
            UPDATE wsc_ahcs_int_control_t
            SET
                group_id = lv_group_id
            WHERE
                    source_application = 'LEASES'
                AND status = 'TRANSFORM_SUCCESS'
                AND group_id IS NULL
                AND batch_id = p_batch_id;

            COMMIT;
            OPEN lhin_grp_data_fetch_cur(lv_group_id);
            LOOP
                FETCH lhin_grp_data_fetch_cur
                BULK COLLECT INTO lv_lhin_grp_type LIMIT 50;
                EXIT WHEN lv_lhin_grp_type.count = 0;
                FORALL i IN 1..lv_lhin_grp_type.count
                    INSERT INTO wsc_ahcs_int_control_line_t (
                        batch_id,
                        file_name,
                        group_id,
                        ledger_name,
                        source_system,
                        interface_id,
                        status,
                        created_by,
                        creation_date,
                        last_updated_by,
                        last_update_date
                    ) VALUES (
                        lv_lhin_grp_type(i).batch_id,
                        lv_lhin_grp_type(i).file_name,
                        lv_group_id,
                        lv_lhin_grp_type(i).ledger_name,
                        lv_lhin_grp_type(i).source_application,
                        lv_lhin_grp_type(i).interface_id,
                        lv_lhin_grp_type(i).status,
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
                logging_insert('LEASES', p_batch_id, 290.1, 'Error in the reprocess group id block.' || sqlerrm, NULL,
                              sysdate);
        END;

        logging_insert('LEASES', p_batch_id, 303, 'Dashboard Start', NULL,
                      sysdate);
        wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
        logging_insert('LEASES', p_batch_id, 304, 'Dashboard End', NULL,
                      sysdate);
        logging_insert('LEASES', p_batch_id, 31, 'end transformation', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT020', 'LEASES', sqlerrm);
    END leg_coa_transformation_reprocessing;

    PROCEDURE wsc_ahcs_lhin_grp_id_upd_p (
        in_grp_id IN NUMBER
    ) AS

        lv_grp_id        NUMBER := in_grp_id;
        err_msg          VARCHAR2(4000);
        CURSOR lhin_grp_data_fetch_cur (
            p_grp_id NUMBER
        ) IS
        SELECT DISTINCT
            c.batch_id           batch_id,
            c.file_name          file_name,
            a.ledger_name        ledger_name,
            c.source_application source_application,
            'LEASES'             interface_id,
            c.status             status
        FROM
            wsc_ahcs_int_control_t     c,
            wsc_ahcs_lhin_txn_header_t a
        WHERE
                a.batch_id = c.batch_id
            AND a.ledger_name IS NOT NULL
            AND c.status = 'TRANSFORM_SUCCESS'
            AND c.group_id = p_grp_id
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
            );

        TYPE lhin_grp_type IS
            TABLE OF lhin_grp_data_fetch_cur%rowtype;
        lv_lhin_grp_type lhin_grp_type;
    BEGIN
-- Updating Group Id for MF AP Files in control table----

        UPDATE wsc_ahcs_int_control_t
        SET
            group_id = lv_grp_id
        WHERE
                source_application = 'LEASES'
            AND status = 'TRANSFORM_SUCCESS'
            AND group_id IS NULL;

        COMMIT;
        OPEN lhin_grp_data_fetch_cur(lv_grp_id);
        LOOP
            FETCH lhin_grp_data_fetch_cur
            BULK COLLECT INTO lv_lhin_grp_type LIMIT 50;
            EXIT WHEN lv_lhin_grp_type.count = 0;
            FORALL i IN 1..lv_lhin_grp_type.count
                INSERT INTO wsc_ahcs_int_control_line_t (
                    batch_id,
                    file_name,
                    group_id,
                    ledger_name,
                    source_system,
                    interface_id,
                    status,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date
                ) VALUES (
                    lv_lhin_grp_type(i).batch_id,
                    lv_lhin_grp_type(i).file_name,
                    lv_grp_id,
                    lv_lhin_grp_type(i).ledger_name,
                    lv_lhin_grp_type(i).source_application,
                    lv_lhin_grp_type(i).interface_id,
                    lv_lhin_grp_type(i).status,
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
            ) and group_id is null
            AND attribute2 = 'TRANSFORM_SUCCESS'
            AND ( accounting_status = 'IMP_ACC_ERROR'
                  OR accounting_status IS NULL );

        COMMIT;
    END wsc_ahcs_lhin_grp_id_upd_p;

    PROCEDURE wsc_ahcs_lhin_ctrl_line_tbl_led_num_upd (
        p_group_id       IN VARCHAR2,
        p_ledger_grp_num IN VARCHAR2
    ) AS
    BEGIN
        IF ( p_ledger_grp_num = 999 ) THEN
            dbms_output.put_line(p_ledger_grp_num || 'inside IF');
            UPDATE wsc_ahcs_int_control_line_t status
            SET
                status.ledger_grp_num = 999,
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
                        AND ml.sub_ledger = 'LEASES'
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
                        AND ml.sub_ledger = 'LEASES'
                        AND ml.ledger_name = status.ledger_name
                ) );

            COMMIT;
        END IF;
    END wsc_ahcs_lhin_ctrl_line_tbl_led_num_upd;

    PROCEDURE wsc_ahcs_lhin_ctrl_line_ucm_id_upd (
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
                        AND ml.sub_ledger = 'LEASES'
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
                        AND ml.sub_ledger = 'LEASES'
                        AND ml.ledger_name = status.ledger_name
                ) );

            COMMIT;
        END IF;
    END wsc_ahcs_lhin_ctrl_line_ucm_id_upd;

END wsc_ahcs_lhin_validation_transformation_pkg;
/