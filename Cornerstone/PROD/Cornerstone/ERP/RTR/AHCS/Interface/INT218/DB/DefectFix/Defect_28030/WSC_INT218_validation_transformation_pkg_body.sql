--------------------------------------------------------
--  File created - Friday-March-17-2023   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body WSC_AHCS_MFAP_VALIDATION_TRANSFORMATION_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "FININT"."WSC_AHCS_MFAP_VALIDATION_TRANSFORMATION_PKG" AS

    PROCEDURE data_validation (
        p_batch_id IN NUMBER
    ) IS 

    -- TODO: Implementation required for PROCEDURE WSC_AHCS_MFAP_VALIDATION_TRANSFORMATION_PKG.data_validation
        lv_header_err_msg     VARCHAR2(2000) := NULL;
        lv_line_err_msg       VARCHAR2(2000) := NULL;
        lv_header_err_flag    VARCHAR2(100) := 'false';
        lv_line_err_flag      VARCHAR2(100) := 'false';
        l_system              VARCHAR2(30);
        lv_count_sucss        NUMBER := 0;
        retcode               NUMBER;
        TYPE wsc_header_col_value_type IS
            VARRAY(70) OF VARCHAR2(200); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING HEADER OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        lv_header_col_value   wsc_header_col_value_type := wsc_header_col_value_type('HDR_SEQ_NBR', 'INTERFACE_ID', 'VENDOR_NBR', 'INVOICE_NBR',
                                                                                  'INVOICE_DATE',
                                                                                  'CONTINENT',
                                                                                  'BUSINESS_UNIT',
                                                                                  'DIVISION',
                                                                                  'LOCATION',
                                                                                  'VENDOR_NAME',
                                                                                  'ACCOUNTING_DATE'); 
                                                                                    --11 fields
        TYPE wsc_line_col_value_type IS
            VARRAY(40) OF VARCHAR2(200); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING LINE OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        lv_line_col_value     wsc_line_col_value_type := wsc_line_col_value_type('HDR_SEQ_NBR', 'INVOICE_DATE', 'LINE_SEQ_NUMBER', 'DB_CR_FLAG',
                                                                            'LEG_LOC',
                                                                            'GL_AMOUNT_IN_LOC_CURR',
                                                                            'GL_AMNT_IN_FORIEGN_CURR',
                                                                            'LOCAL_CURRENCY',
                                                                            'FOREIGN_CURRENCY',
                                                                            'FX_RATE');   
                                                                               
                                                                               --10 fields

/************ @@@@@ INITIALIZE HEADER AND LINE FLAG TABLE TYPE VARIABLES TO MATCH THE COUNT OF HEADER AND LINE @@@@@ ************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        TYPE wsc_ahcs_mfap_header_txn_t_type IS
            TABLE OF INTEGER;
        lv_error_mfap_header  wsc_ahcs_mfap_header_txn_t_type := wsc_ahcs_mfap_header_txn_t_type('1', '1', '1', '1', '1',
                                                                                               '1',
                                                                                               '1',
                                                                                               '1',
                                                                                               '1',
                                                                                               '1',
                                                                                               '1',
                                                                                               '1',
                                                                                               '1',
                                                                                               '1',
                                                                                               '1');
                                                                                               --15 '1's
        TYPE wsc_ahcs_mfap_line_txn_t_type IS
            TABLE OF INTEGER;
        lv_error_mfap_line    wsc_ahcs_mfap_line_txn_t_type := wsc_ahcs_mfap_line_txn_t_type('1', '1', '1', '1', '1',
                                                                                         '1',
                                                                                         '1',
                                                                                         '1',
                                                                                         '1',
                                                                                         '1',
                                                                                         '1',
                                                                                         '1',
                                                                                         '1',
                                                                                         '1',
                                                                                         '1'); 
                                                                                         --15 '1's
			
-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from LINE STAGING TABLE THAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_wsc_mfap_line (
            cur_p_hdr_id VARCHAR2
        ) IS
        SELECT
            hdr_seq_nbr,
            invoice_date,
            line_seq_number,
            db_cr_flag,
            leg_loc,
            gl_amount_in_loc_curr,
            gl_amnt_in_foriegn_curr,
            local_currency,
            foreign_currency,
            fx_rate,
            line_id
        FROM
            wsc_ahcs_mfap_txn_line_t
        WHERE
            header_id = cur_p_hdr_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from HEADER STAGING TABLE THAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_header_id (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            header_id,
            hdr_seq_nbr,
            interface_id,
            vendor_nbr,
            invoice_nbr,
            invoice_date,
            continent,
            business_unit,
            division,
            location,
            vendor_name,
            accounting_date
        FROM
            wsc_ahcs_mfap_txn_header_t
        WHERE
            batch_id = cur_p_batch_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/

------------------------------------------------------------------------------------------------------------------------------------------------
--Following cursor will verify whether LOCAL_INV_TOTAL at header level is equal or not to GL amount in local currency(credit)and(debit) at line level and will flag the results.
------------------------------------------------------------------------------------------------------------------------------------------------
 CURSOR cur_header_validation (
            cur_p_batch_id NUMBER
        ) IS
        WITH line_amt AS (
           SELECT
                header_id,
            (   SUM( case  when db_cr_flag = 'DR' then gl_amount_in_loc_curr
                      else  0 
                      end )  
                      -
              SUM( case  when db_cr_flag = 'CR' then gl_amount_in_loc_curr
                      else  0 
                      end )    )    sum_line_amt  
     
            FROM
                wsc_ahcs_mfap_txn_line_t
            WHERE
                 batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ), header_amt AS (
            SELECT
                header_id,
                SUM(local_inv_total) sum_data
            FROM
                wsc_ahcs_mfap_txn_header_t
            WHERE
                batch_id = cur_p_batch_id
            GROUP BY
                header_id
        )
        SELECT
            h_amt.header_id AS header_id
        FROM
            line_amt     l_cr,

            header_amt  h_amt
        WHERE
                l_cr.header_id = h_amt.header_id
            AND l_cr.sum_line_amt <> h_amt.sum_data  ;
            
        
    -- 24 Jan, 2023, US: DP-RTR-AHCS-186,  updated the validation logic above to Header Amount= Sum of Debit - Sum of Credit"
       ------------------------------------------------------------------------------------------------------------------------------------------------           
        TYPE header_validation_type IS
            TABLE OF cur_header_validation%rowtype;
        lv_header_validation  header_validation_type;
      
------------------------------------------------------------------------------------------------------------------------------------------------
--Following cursor will verify whether GL amount in local currency (debit) is equal or not to GL amount int local currency (credit) and will flag the results.
------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_line_validation (
            cur_p_batch_id NUMBER
        ) IS
        WITH line_cr AS (
            SELECT
                header_id,
                abs(SUM(gl_amount_in_loc_curr)) sum_data
            FROM
                wsc_ahcs_mfap_txn_line_t
            WHERE
                    db_cr_flag = 'CR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ), line_dr AS (
            SELECT
                header_id,
                abs(SUM(gl_amount_in_loc_curr)) sum_data
            FROM
                wsc_ahcs_mfap_txn_line_t
            WHERE
                    db_cr_flag = 'DR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        )
        SELECT
            nvl(cr_hdr, dr_hdr) header_id
        FROM
            (
                SELECT
                    l_cr.header_id    cr_hdr,
                    l_dr.header_id    dr_hdr,
                    l_cr.sum_data     cr_sum,
                    l_dr.sum_data     dr_sum
                FROM
                    line_cr  l_cr,
                    line_dr  l_dr
                WHERE
                        nvl(l_dr.sum_data, 0) <> nvl(l_cr.sum_data, 0)
                    AND l_dr.header_id (+) = l_cr.header_id
                UNION
                SELECT
                    l_cr.header_id    cr_hdr,
                    l_dr.header_id    dr_hdr,
                    l_cr.sum_data     cr_sum,
                    l_dr.sum_data     dr_sum
                FROM
                    line_cr  l_cr,
                    line_dr  l_dr
                WHERE
                        nvl(l_dr.sum_data, 0) <> nvl(l_cr.sum_data, 0)
                    AND l_dr.header_id = l_cr.header_id (+)
            );
            
            
--        WITH line_cr AS (
--            SELECT
--                header_id,
--                abs(SUM(gl_amount_in_loc_curr)) sum_data
--            FROM
--                wsc_ahcs_mfap_txn_line_t
--            WHERE
--                    db_cr_flag = 'CR'
--                AND batch_id = cur_p_batch_id
--            GROUP BY
--                header_id
--        ), line_dr AS (
--            SELECT
--                header_id,
--                abs(SUM(gl_amount_in_loc_curr)) sum_data
--            FROM
--                wsc_ahcs_mfap_txn_line_t
--            WHERE
--                    db_cr_flag = 'DR'
--                AND batch_id = cur_p_batch_id
--            GROUP BY
--                header_id
--        )
--        SELECT
--            l_cr.header_id
--        FROM
--            line_cr l_cr,
--            line_dr l_dr
--        WHERE
--            ( l_dr.sum_data <> l_cr.sum_data )
--            AND l_dr.header_id = l_cr.header_id;


------------------------------------------------------------------------------------------------------------------------------------------------          
        TYPE line_validation_type IS
            TABLE OF cur_line_validation%rowtype;
        lv_line_validation    line_validation_type;
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

        err_msg               VARCHAR2(2000);
    BEGIN		
 
    ---store mainframe sub system name name in  'l_system' variable--- 
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
        
		------------------------------------------------------------------------------------------------------------------------------------------------
        -- 1. Start of validation -
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
        logging_insert('MF AP', p_batch_id, 101,
                      'Start of validation - Header LOCAL_INV_TOTAL mismatch with Line DR/CR Amount',
                      NULL,
                      sysdate); 
        
   -- as CAIN only have either debit or credit line in source file
        IF l_system = 'CAIN' THEN
            BEGIN
                OPEN cur_header_validation(p_batch_id);
                LOOP
                    FETCH cur_header_validation BULK COLLECT INTO lv_header_validation LIMIT 100;
                    EXIT WHEN lv_header_validation.count = 0;
                    FORALL i IN 1..lv_header_validation.count
                        UPDATE wsc_ahcs_int_status_t
                        SET
                            status = 'VALIDATION_FAILED',
                            error_msg = '302|Header amount mismatch with Line DR/CR Amount',
                            reextract_required = 'Y',
                            attribute1 = 'H',
                            attribute2 = 'VALIDATION_FAILED',
                            last_updated_date = sysdate
                        WHERE
                                batch_id = p_batch_id
                            AND status = 'NEW'
                            AND header_id = lv_header_validation(i).header_id;

                END LOOP;

                CLOSE cur_header_validation;
                COMMIT;
            EXCEPTION
                WHEN OTHERS THEN
                    logging_insert('MF AP', p_batch_id, 201,
                                  'exception in Header LOCAL_INV_TOTAL mismatch with Line DR/CR Amount',
                                  sqlerrm,
                                  sysdate);
                    dbms_output.put_line('Error with Query:  ' || sqlerrm);
            END;
        END IF;

        logging_insert('MF AP', p_batch_id, 102, 'End of validation - Header LOCAL_INV_TOTAL mismatch with Line DR/CR Amount',
                      NULL,
                      sysdate);
    ------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2. Validate GL AMOUNT IN LOCAL_CURRENCY
        --  Identify transactions wherein GL AMOUNT IN LOCAL_CURRENCY(DEBIT) does not match with GL AMOUNT IN LOCAL_CURRENCY(CREDIT) .
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
        logging_insert('MF AP', p_batch_id, 103, 'Start of validation - Validate GL_AMOUNT IN LOCAL_CURRENCY', NULL,
                      sysdate);
        IF l_system <> 'CAIN' THEN
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
                            AND header_id = lv_line_validation(i).header_id;

                END LOOP;

                CLOSE cur_line_validation;
                COMMIT;
            EXCEPTION
                WHEN OTHERS THEN
                    logging_insert('MF AP', p_batch_id, 203, 'exception in GL AMOUNT IN LOCAL_CURRENCY validation', sqlerrm,
                                  sysdate);
                    dbms_output.put_line('Error with Query:  ' || sqlerrm);
                    ROLLBACK;
            END;

            logging_insert('MF AP', p_batch_id, 104, 'End of validation - Validate GL_AMOUNT IN LOCAL_CURRENCY', NULL,
                          sysdate);
        END IF;       
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
        logging_insert('MF AP', p_batch_id, 105, 'Validate header and line fields data type start', NULL,
                      sysdate);
        BEGIN
            FOR header_id_f IN cur_header_id(p_batch_id) LOOP
                lv_header_err_flag := 'false';
                lv_header_err_msg := NULL;
                lv_error_mfap_header := wsc_ahcs_mfap_header_txn_t_type('1', '1', '1', '1', '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1');

                lv_error_mfap_header(1) := is_varchar2_null(header_id_f.hdr_seq_nbr);
                lv_error_mfap_header(2) := is_varchar2_null(header_id_f.interface_id);
                lv_error_mfap_header(3) := is_varchar2_null(header_id_f.vendor_nbr);
                lv_error_mfap_header(4) := is_varchar2_null(header_id_f.invoice_nbr);
                lv_error_mfap_header(5) := is_date_null(header_id_f.invoice_date);
                lv_error_mfap_header(6) := is_varchar2_null(header_id_f.continent);
                lv_error_mfap_header(7) := is_varchar2_null(header_id_f.business_unit);
                lv_error_mfap_header(8) := is_varchar2_null(header_id_f.division);
                lv_error_mfap_header(9) := is_varchar2_null(header_id_f.location);
                lv_error_mfap_header(10) := is_varchar2_null(header_id_f.vendor_name);
                lv_error_mfap_header(11) := is_date_null(header_id_f.accounting_date);
                FOR i IN 1..11 LOOP
--                    dbms_output.put_line(lv_error_mfap_header(i));
                    IF lv_error_mfap_header(i) = 0 THEN
                        lv_header_err_msg := lv_header_err_msg
                                             || '300|Missing Value of '
                                             || lv_header_col_value(i)
                                             || '. ';
                        lv_header_err_flag := 'true';
                    END IF;
                END LOOP;

                IF lv_header_err_flag = 'true' THEN
                    UPDATE wsc_ahcs_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = lv_header_err_msg,
                        reextract_required = 'Y',
                        attribute1 = 'H',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        AND status = 'NEW'
                        AND header_id = header_id_f.header_id;

                    COMMIT;
                        
                       -- logging_insert('MF AP', p_batch_id, 204, 'mandatory field validation failed for header' || header_id_f.header_id,lv_header_err_flag,sysdate);
                    CONTINUE;
                END IF;

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

                FOR wsc_mfap_line IN cur_wsc_mfap_line(header_id_f.header_id) LOOP
                    lv_line_err_flag := 'false';
                    lv_line_err_msg := NULL;
                    lv_error_mfap_line := wsc_ahcs_mfap_line_txn_t_type('1', '1', '1', '1', '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1');
                  -- March 13, 2023 corrected the sequence of variables here in UAT2 as per defect CTPFS-28030                                             
                    lv_error_mfap_line(1) := is_varchar2_null(wsc_mfap_line.hdr_seq_nbr);
                    lv_error_mfap_line(2) := is_date_null(wsc_mfap_line.invoice_date);
                    lv_error_mfap_line(3) := is_number_null(wsc_mfap_line.line_seq_number);
                    lv_error_mfap_line(4) := is_varchar2_null(wsc_mfap_line.db_cr_flag);
                    lv_error_mfap_line(5) := is_varchar2_null(wsc_mfap_line.leg_loc);
                    lv_error_mfap_line(6) := is_number_null(wsc_mfap_line.gl_amount_in_loc_curr);
                    lv_error_mfap_line(7) := is_number_null(wsc_mfap_line.gl_amnt_in_foriegn_curr);
                    lv_error_mfap_line(8) := is_varchar2_null(wsc_mfap_line.local_currency);
                    lv_error_mfap_line(9) := is_varchar2_null(wsc_mfap_line.foreign_currency);
                    lv_error_mfap_line(10) := is_number_null(wsc_mfap_line.fx_rate);
                   
                    FOR j IN 1..10 LOOP
                        IF lv_error_mfap_line(j) = 0 THEN
                            lv_line_err_msg := lv_line_err_msg
                                               || '300|Missing Value of '
                                               || lv_line_col_value(j)
                                               || '. ';
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
                            AND header_id = header_id_f.header_id
                            AND line_id = wsc_mfap_line.line_id;

                        COMMIT;
                        UPDATE wsc_ahcs_int_status_t
                        SET
                            attribute1 = 'L',
                            attribute2 = 'VALIDATION_FAILED',
                            last_updated_date = sysdate
                        WHERE
                                batch_id = p_batch_id
                            AND status = 'NEW'
                            AND header_id = header_id_f.header_id;

                        COMMIT;
                    END IF;

                END LOOP;

            END LOOP;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                err_msg := substr(sqlerrm, 1, 200);
                logging_insert('MF AP', p_batch_id, 207, 'Error in mandatory field validation', sqlerrm,
                              sysdate);
        END;

        logging_insert('MF AP', p_batch_id, 106, 'end mandatory validation', NULL,
                      sysdate);
        BEGIN
            logging_insert('MF AP', p_batch_id, 107, 'start updating STATUS TABLE with validation status', NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'VALIDATION_FAILED',
                error_msg = 'error in HDR_SEQ_NBR',
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
            logging_insert('MF AP', p_batch_id, 108, 'status updated in STATUS TABLE', NULL,
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
            logging_insert('MF AP', p_batch_id, 109, 'attribute 2 updated in STATUS TABLE', NULL,
                          sysdate);
            OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_sucss;
            CLOSE cur_count_sucss;
            logging_insert('MF AP', p_batch_id, 110, 'count success', lv_count_sucss,
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
                logging_insert('MF AP', p_batch_id, 111, 'call transformation pkg ', NULL,
                              sysdate);
                BEGIN
                    wsc_ahcs_mfap_validation_transformation_pkg.leg_coa_transformation(p_batch_id);
                END;
            ELSE
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'VALIDATION_FAILED',
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;
--                    AND status = 'NEW';

            END IF;

            COMMIT;
            logging_insert('MF AP', p_batch_id, 124, 'end data_validation and transformation', NULL,
                          sysdate);
            logging_insert('MF AP', p_batch_id, 125, 'AHCS Dashboard refresh Start', NULL,
                          sysdate);
            wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
            logging_insert('MF AP', p_batch_id, 126, 'AHCS Dashboard refresh End', NULL,
                          sysdate);
            DELETE FROM wsc_ahcs_mfap_txn_tmp_t
            WHERE
                batch_id = p_batch_id;

            logging_insert('MF AP', p_batch_id, 127, 'deleted data from WSC_AHCS_MFAP_TXN_TMP_T for this batch_id', NULL,
                          sysdate);
        END;

    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT218'
                                                    || '_'
                                                    || l_system,
                                                    'MF AP',
                                                    sqlerrm);
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
        l_system                   VARCHAR2(30);
        CURSOR cur_update_trxn_line_err IS
        SELECT
            line.batch_id,
            line.header_id,
            line.line_id,
            line.target_coa
        FROM
            wsc_ahcs_mfap_txn_line_t  line,
            wsc_ahcs_int_status_t     status
        WHERE
                line.batch_id = p_batch_id
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
            AND status.batch_id = line.batch_id
            AND status.header_id = line.header_id
            AND status.line_id = line.line_id
            AND status.attribute2 = 'VALIDATION_SUCCESS'; /*ATTRIBUTE2 */

        lv_batch_id                NUMBER := p_batch_id;
        TYPE update_trxn_line_err_type IS
            TABLE OF cur_update_trxn_line_err%rowtype;
        lv_update_trxn_line_err    update_trxn_line_err_type;
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
        lv_update_trxn_header_err  update_trxn_header_err_type;

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
            wsc_gl_coa_map_t        coa_map,
            wsc_ahcs_int_control_t  ahcs_control
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
--                    line.LEG_BU,
--                    line.LEG_ACCT,
--                    line.LEG_DEPT,
--                    line.LEG_LOC,   /*** Fetches distinct legacy combination values ***/
--                    line.LEG_VENDOR,
--                    line.LEG_AFFILIATE
--                FROM
--                    wsc_ahcs_mfap_txn_line_t    line,
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
            line.leg_coa       leg_coa,
            line.target_coa    target_coa,
            line.leg_bu,
            line.leg_acct,
            line.leg_dept,
            line.leg_loc,
            line.leg_vendor,
            line.leg_affiliate
--            line.leg_seg7,
--            substr(line.leg_coa, instr(line.leg_coa, '.', 1, 7) + 1)                      AS ledger_name
        FROM
            wsc_ahcs_mfap_txn_line_t line
--              , wsc_ahcs_mfap_txn_header_t header
        WHERE
                line.batch_id = p_batch_id 
--			   and line.batch_id = header.batch_id
--			   and line.header_id = header.header_id
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        /*
		cursor cur_inserting_ccid_table is
			select distinct LEG_COA, TARGET_COA from wsc_ahcs_mfap_txn_line_t
			 where batch_id = p_batch_id 
			   and attribute1 = 'Y'   
			   and substr(target_coa,1,instr(target_coa,'.',1,1)-1) is not null;  
	    */

        TYPE inserting_ccid_table_type IS
            TABLE OF cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table    inserting_ccid_table_type;

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
                wsc_gl_legal_entities_t  lgl_entt,
                (
                    SELECT DISTINCT
                        line.gl_legal_entity,
                        line.header_id
                    FROM
                        wsc_ahcs_mfap_txn_line_t  line,
                        wsc_ahcs_int_status_t     status
                    WHERE
                            line.header_id = status.header_id
                        AND line.batch_id = status.batch_id
                        AND line.line_id = status.line_id
                        AND status.batch_id = p_batch_id
                        AND status.attribute2 = 'VALIDATION_SUCCESS'
                )                        d_lgl_entt
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
        lv_get_ledger              get_ledger_type;
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
--                wsc_ahcs_mfap_txn_line_t
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
--                wsc_ahcs_mfap_txn_line_t
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
        lv_coa_mapid               NUMBER;
        lv_src_system              VARCHAR2(100);
        lv_tgt_system              VARCHAR2(100);
        lv_count_succ              NUMBER;
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
	--1. Identify the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 112, 'Transformation start', NULL,
                      sysdate);
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_mapid,
            lv_tgt_system,
            lv_src_system;
        CLOSE cur_coa_map_id;
        logging_insert('ANIXTER AP', p_batch_id, 113, 'Identify the COA map',
                      lv_coa_mapid
                      || lv_tgt_system
                      || lv_src_system,
                      sysdate);

--        update target_coa in ap_line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
	--2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 114, 'Check data in cache table to find ', NULL,
                      sysdate);
        BEGIN
            IF lv_src_system = 'ANIXTER' THEN
                UPDATE wsc_ahcs_mfap_txn_line_t line
                SET
                    target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa, lv_coa_mapid),
                    last_update_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            ELSE
                UPDATE wsc_ahcs_mfap_txn_line_t line
                SET
                    target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_bu
                                                                   || '.....'
                                                                   || nvl(leg_affiliate, '00000'),
                                                                   lv_coa_mapid)
                WHERE
                    batch_id = p_batch_id;

            END IF;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('ANIXTER AP', p_batch_id, 208, 'Error in Check data in cache table to find', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

--        update target_coa and attribute1 'Y' in ap_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 115, 'update target_coa and attribute1', NULL,
                      sysdate);
        BEGIN
         /*   open cur_leg_seg_value(lv_src_system, lv_tgt_system);
            loop
            fetch cur_leg_seg_value bulk collect into lv_leg_seg_value limit 100;
            EXIT WHEN lv_leg_seg_value.COUNT = 0;        
            forall i in 1..lv_leg_seg_value.count
                update wsc_ahcs_mfap_txn_line_t set target_coa = lv_leg_seg_value(i).target_coa,  ATTRIBUTE1 = 'Y', 
                LAST_UPDATE_DATE = sysdate 
                where LEG_COA = lv_leg_seg_value(i).LEG_COA and batch_id = p_batch_id;
            end loop;
*/

            UPDATE wsc_ahcs_mfap_txn_line_t tgt_coa
            SET
                target_coa = replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, tgt_coa.leg_bu, tgt_coa.leg_loc,
                tgt_coa.leg_dept,
                                                                        tgt_coa.leg_acct,
                                                                        tgt_coa.leg_vendor,
                                                                        nvl(tgt_coa.leg_affiliate, '00000'),
                                                                        NULL,
                                                                        NULL,
                                                                        NULL,
                                                                        NULL),
                                     ' ',
                                     ''),
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
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('ANIXTER AP', p_batch_id, 209, 'Error in update target_coa and attribute1', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

--        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 116, 'insert new target_coa values', NULL,
                      sysdate);
        BEGIN
            IF lv_src_system = 'ANIXTER' THEN
                OPEN cur_inserting_ccid_table;
                LOOP
                    FETCH cur_inserting_ccid_table BULK COLLECT INTO lv_inserting_ccid_table LIMIT 100;
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
                            'ANIXTER AP',
                            'ANIXTER AP',
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
                --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
                END LOOP;

                CLOSE cur_inserting_ccid_table;
            ELSE
                OPEN cur_inserting_ccid_table;
                LOOP
                    FETCH cur_inserting_ccid_table BULK COLLECT INTO lv_inserting_ccid_table LIMIT 100;
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
                            || '.....'
                            || nvl(lv_inserting_ccid_table(i).leg_affiliate, '00000'),
                            lv_inserting_ccid_table(i).target_coa,
                            sysdate,
                            sysdate,
                            'Y',
                            'N',
                            'ANIXTER AP',
                            'ANIXTER AP',
                            lv_inserting_ccid_table(i).leg_bu,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            nvl(lv_inserting_ccid_table(i).leg_affiliate, '00000'),
                            NULL,
                            NULL,
                            NULL,
                            NULL
                        );
                --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
                END LOOP;

                CLOSE cur_inserting_ccid_table;
            END IF;
--            UPDATE wsc_ahcs_mfap_txn_line_t
--            SET
--                attribute1 = NULL
--            WHERE
--                batch_id = p_batch_id;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('ANIXTER AP', p_batch_id, 116, 'error in ccid insert', sqlerrm,
                              sysdate);
        END;

        UPDATE wsc_ahcs_mfap_txn_line_t
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
        logging_insert('ANIXTER AP', p_batch_id, 117, 'update mfap_line table target segments', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_mfap_txn_line_t
            SET
                gl_legal_entity = substr(target_coa, 1, instr(target_coa, '.', 1, 1) - 1),
                gl_oper_grp = substr(target_coa, instr(target_coa, '.', 1, 1) + 1, instr(target_coa, '.', 1, 2) - instr(target_coa,
                '.', 1, 1) - 1),
                gl_acct = substr(target_coa, instr(target_coa, '.', 1, 2) + 1, instr(target_coa, '.', 1, 3) - instr(target_coa, '.',
                1, 2) - 1),
                gl_dept = substr(target_coa, instr(target_coa, '.', 1, 3) + 1, instr(target_coa, '.', 1, 4) - instr(target_coa, '.',
                1, 3) - 1),
                gl_site = substr(target_coa, instr(target_coa, '.', 1, 4) + 1, instr(target_coa, '.', 1, 5) - instr(target_coa, '.',
                1, 4) - 1),
                gl_ic = substr(target_coa, instr(target_coa, '.', 1, 5) + 1, instr(target_coa, '.', 1, 6) - instr(target_coa, '.',
                1, 5) - 1),
                gl_projects = substr(target_coa, instr(target_coa, '.', 1, 6) + 1, instr(target_coa, '.', 1, 7) - instr(target_coa,
                '.', 1, 6) - 1),
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
                logging_insert('ANIXTER AP', p_batch_id, 210, 'Error in update ap_line table target segments', sqlerrm,
                              sysdate);
        END;

--        if any target_coa is empty in ap_line table will mark it as transform_error in status table
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 118, 'if any target_coa is empty', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    status.attribute2,
                    status.attribute1,
                    status.status,
                    status.error_msg,
                    status.last_updated_date,
                    line.batch_id      bt_id,
                    line.header_id     hdr_id,
                    line.line_id       ln_id,
                    line.target_coa    trgt_coa
                FROM
                    wsc_ahcs_int_status_t     status,
                    wsc_ahcs_mfap_txn_line_t  line
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
            logging_insert('ANIXTER AP', p_batch_id, 119, 'updated attribute2 with TRANSFORM_FAILED status', NULL,
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
                  logging_insert('ANIXTER AP',p_batch_id,19.2,'updated attribute2 with TRANSFORM_FAILED status',null,sysdate);
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
                logging_insert('ANIXTER AP', p_batch_id, 211, 'Error in if any target_coa is empty', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

--      update ledger_name in ap_header table where transform_success		
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 120, 'update ledger_name', NULL,
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

                 
--update wsc_ahcs_mfap_txn_header_t hdr set hdr.ledger_name=(SELECT  /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I) */ 
--                                      
--                                      lgl_entt.ledger_name gl_led_name
--                                  FROM
--                                      wsc_ahcs_mfap_txn_line_t line,
--                                      wsc_ahcs_int_status_t    status,
--                                      wsc_gl_legal_entities_t lgl_entt
--                                  WHERE
--                                          line.header_id = status.header_id
--                                      AND line.batch_id = status.batch_id
--                                      AND line.line_id = status.line_id
--                                      AND status.batch_id = lv_batch_id
--                                      AND status.attribute2 = 'VALIDATION_SUCCESS'
--                                      and status.header_id = hdr.header_id
--                                      and line.header_id = hdr.header_id
--                                      and lgl_entt.flex_segment_value = line.gl_legal_entity
----                                      and hdr.header_id = 52789
--                                      and rownum =1)
--                                      where hdr.batch_id = lv_batch_id
--                                      ;
            MERGE INTO wsc_ahcs_mfap_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT
                              lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t  lgl_entt,
                              (
                                  SELECT
                                      line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_mfap_txn_line_t  line,
                                      wsc_ahcs_int_status_t     status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = lv_batch_id
                                      AND status.attribute2 = 'VALIDATION_SUCCESS'
                              )                        d_lgl_entt
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

            COMMIT;
            logging_insert('ANIXTER AP', p_batch_id, 120.1, 'update transaction number with STATIC_LEDGER_NUMBER -starts',
                          NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_mfap_txn_header_t hdr
            USING wsc_ahcs_int_mf_ledger_t l ON ( l.ledger_name = hdr.ledger_name
                                                  AND l.sub_ledger = 'MF AP'
                                                  AND hdr.ledger_name IS NOT NULL
                                                  AND hdr.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET transaction_number = transaction_number
                                     || '_'
                                     || l.static_ledger_number;

            COMMIT;
            logging_insert('ANIXTER AP', p_batch_id, 120.2,
                          'update transaction number with STATIC_LEDGER_NUMBER -header table- complete',
                          NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_mfap_txn_line_t line
            USING wsc_ahcs_mfap_txn_header_t hdr ON ( line.header_id = hdr.header_id
                                                      AND line.batch_id = hdr.batch_id
                                                      AND hdr.ledger_name IS NOT NULL
                                                      AND hdr.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET line.transaction_number = hdr.transaction_number;

            COMMIT;
            logging_insert('ANIXTER AP', p_batch_id, 120.3,
                          'update transaction number with STATIC_LEDGER_NUMBER -line table- complete',
                          NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_int_status_t status
            USING wsc_ahcs_mfap_txn_line_t line ON ( line.header_id = status.header_id
                                                     AND line.batch_id = status.batch_id
                                                     AND line.line_id = status.line_id
                                                     AND status.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET status.attribute3 = line.transaction_number;

            COMMIT;
            logging_insert('ANIXTER AP', p_batch_id, 120.4,
                          'update transaction number with STATIC_LEDGER_NUMBER -status table- complete',
                          NULL,
                          sysdate);
            logging_insert('ANIXTER AP', p_batch_id, 120.5, 'update transaction number with STATIC_LEDGER_NUMBER -ends', NULL,
                          sysdate);
            
--call multi ledger proc
            logging_insert('ANIXTER AP', p_batch_id, 120.6, 'call wsc_ledger_name_derivation', NULL,
                          sysdate);
            wsc_ledger_name_derivation(lv_batch_id);
            COMMIT;
 --logging_insert('ANIXTER AP', p_batch_id, 120.1, 'after IS NOT NULL', NULL, sysdate);
         /*   MERGE INTO wsc_ahcs_mfap_txn_header_t hdr
            USING (
                      WITH main_data AS (
                      SELECT /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE) */ 
--                          SELECT 
                             /* lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t lgl_entt,
                              (
--                                  SELECT 
                                   SELECT /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I,batch_status wsc_ahcs_int_status_batch_id_i)  */
                                 /*     line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_mfap_txn_line_t line,
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
                                                  a.ledger_name IS NULL
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
            SET hdr.ledger_name = e.ledger_name;   */

          --  COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('ANIXTER AP', p_batch_id, 212, 'Error in update ledger_name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('ANIXTER AP', p_batch_id, 121.1, 'Update LEDGER_NAME  in status table -start', NULL,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_mfap_txn_header_t h
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
        END;

        logging_insert('ANIXTER AP', p_batch_id, 121.2, 'Update LEDGER_NAME  in status table -end', NULL,
                      sysdate);
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7.1. Update status tables after validation where line cr/dr mismatch.
        --    /******* ALL RECORDS MARKED AS VALIDATION FAILED WHEN LINE CR/DR AMOUNT MISMATCH AFTER VALIDATION ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 121, 'Update status tables after validation', NULL,
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
                logging_insert('ANIXTER AP',p_batch_id,23,'Update status tables after validation',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end; */

		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 122, 'Update status tables to have status', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    sts.attribute2,
                    sts.status,
                    sts.last_updated_date,
                    sts.error_msg
                FROM
                    wsc_ahcs_int_status_t       sts,
                    wsc_ahcs_mfap_txn_header_t  hdr
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

        logging_insert('ANIXTER AP', p_batch_id, 123, 'end transformation', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT218'
                                                    || '_'
                                                    || l_system,
                                                    'ANIXTER_AP',
                                                    sqlerrm);
    END leg_coa_transformation;

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

        l_system                   VARCHAR2(30);
		lv_group_id               NUMBER; --added for reprocess individual group id process 24th Nov 2022
   ------------------------------------------------------------------------------------------------------------------------------------------------------
   -- The following cursor will retrieve ALL records from lines table that does not target COA combination derived.
   -- All such columns 
   ------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_update_trxn_line_err IS
        SELECT
            line.batch_id,
            line.header_id,
            line.line_id,
            line.target_coa
        FROM
            wsc_ahcs_mfap_txn_line_t  line,
            wsc_ahcs_int_status_t     status
        WHERE
                line.batch_id = p_batch_id
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
            AND status.batch_id = line.batch_id
            AND status.header_id = line.header_id
            AND status.line_id = line.line_id
            AND status.attribute2 = 'VALIDATION_SUCCESS'; /*ATTRIBUTE2 */

        lv_batch_id                NUMBER := p_batch_id;
        TYPE update_trxn_line_err_type IS
            TABLE OF cur_update_trxn_line_err%rowtype;
        lv_update_trxn_line_err    update_trxn_line_err_type;
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
        lv_update_trxn_header_err  update_trxn_header_err_type;

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
            wsc_gl_coa_map_t        coa_map,
            wsc_ahcs_int_control_t  ahcs_control
        WHERE
                upper(coa_map.source_system) = upper(ahcs_control.source_system)
            AND upper(coa_map.target_system) = upper(ahcs_control.target_system)
            AND ahcs_control.batch_id = p_batch_id;

   ------------------------------------------------------------------------------------------------------------------------------------------------------
   -- The following cursor will derive the future state COA combination for the given batch_Id for records that have been successfully validated.
   --
   ------------------------------------------------------------------------------------------------------------------------------------------------------

     /*   CURSOR cur_leg_seg_value (
            cur_p_src_system  VARCHAR2,
            cur_p_tgt_system  VARCHAR2
        ) IS
        SELECT
            tgt_coa.leg_coa,
			----------------------------------------------------------------------------------------------------------------------------
			/**********  The following package call will derive the future state COA combination for legacy COA combination ***********/
			--

         /*   wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system, cur_p_tgt_system, tgt_coa.leg_seg1, tgt_coa.leg_seg2,
                                               tgt_coa.leg_seg3,
                                               tgt_coa.leg_seg4,
                                               tgt_coa.leg_seg5,
                                               tgt_coa.leg_seg6,
                                               tgt_coa.leg_seg7,
                                               tgt_coa.leg_led_name,
                                               NULL,
                                               NULL) target_coa 
			--
			-- End of function call to derive target COA.
			----------------------------------------------------------------------------------------------------------------------------                	  

        FROM
            (
                SELECT DISTINCT
                    line.leg_coa,
                    line.leg_seg1,
                    line.leg_seg2,
                    line.leg_seg3,   /*** Fetches distinct legacy combination values ***/
              /*      line.leg_seg4,
                    line.leg_seg5,
                    line.leg_seg6,
                    line.leg_seg7,
                    header.leg_led_name
                FROM
                    wsc_ahcs_mfap_txn_line_t    line,
                    wsc_ahcs_int_status_t     status,
                    wsc_ahcs_mfap_txn_header_t  header
                WHERE
                        status.batch_id = p_batch_id
                    AND line.target_coa IS NULL
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND header.batch_id = status.batch_id
                    AND header.header_id = status.header_id
                    AND header.header_id = line.header_id
                    AND header.batch_id = line.batch_id
                    AND status.attribute2 = 'TRANSFORM_FAILED'  /*** Check if the record has been successfully validated through validate procedure ***/
      /*     ) tgt_coa;

        TYPE leg_seg_value_type IS
            TABLE OF cur_leg_seg_value%rowtype;
        lv_leg_seg_value                leg_seg_value_type;  */

		-------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
        -- for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_inserting_ccid_table IS
        SELECT DISTINCT
            line.leg_coa       leg_coa,
            line.target_coa    target_coa,
            line.leg_bu,
            line.leg_acct,
            line.leg_dept,
            line.leg_loc,
            line.leg_vendor,
            line.leg_affiliate
            --line.leg_seg7,
            --substr(line.leg_coa, instr(line.leg_coa, '.', 1, 7) + 1)                      AS ledger_name
        FROM
            wsc_ahcs_mfap_txn_line_t line
--              , WSC_AHCS_MFAP_TXN_HEADER_T header
        WHERE
                line.batch_id = p_batch_id 
--			   and line.batch_id = header.batch_id
--			   and line.header_id = header.header_id
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        /*
		cursor cur_inserting_ccid_table is
			select distinct LEG_COA, TARGET_COA from WSC_AHCS_MFAP_TXN_LINE_T
			 where batch_id = p_batch_id 
			   and attribute1 = 'Y'   
			   and substr(target_coa,1,instr(target_coa,'.',1,1)-1) is not null;  
	    */

        TYPE inserting_ccid_table_type IS
            TABLE OF cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table    inserting_ccid_table_type;

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
                wsc_gl_legal_entities_t  lgl_entt,
                (
                    SELECT DISTINCT
                        line.gl_legal_entity,
                        line.header_id
                    FROM
                        wsc_ahcs_mfap_txn_line_t  line,
                        wsc_ahcs_int_status_t     status
                    WHERE
                            line.header_id = status.header_id
                        AND line.batch_id = status.batch_id
                        AND line.line_id = status.line_id
                        AND status.batch_id = p_batch_id
                        AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                )                        d_lgl_entt
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
        lv_get_ledger              get_ledger_type;
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

      /*  CURSOR cur_line_validation_after_valid (
            cur_p_batch_id NUMBER
        ) IS
        WITH line_cr AS (
            SELECT
                header_id,
                gl_legal_entity,
                SUM(acc_amt) * - 1 sum_data
            FROM
                wsc_ahcs_mfap_txn_line_t
            WHERE
                    dr_cr_flag = 'CR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id,
                gl_legal_entity
        ), line_dr AS (
            SELECT
                header_id,
                gl_legal_entity,
                SUM(acc_amt) sum_data
            FROM
                wsc_ahcs_mfap_txn_line_t
            WHERE
                    dr_cr_flag = 'DR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id,
                gl_legal_entity
        )
        SELECT
            l_cr.header_id
        FROM
            line_cr  l_cr,
            line_dr  l_dr
        WHERE
                l_cr.header_id = l_dr.header_id
            AND l_dr.gl_legal_entity = l_cr.gl_legal_entity
            AND ( l_dr.sum_data <> l_cr.sum_data );
 */
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
			
		CURSOR mfap_grp_data_fetch_cur ( --added for reprocess individual group id process 24th Nov 2022
            p_grp_id NUMBER
        ) IS
        SELECT DISTINCT
            c.batch_id           batch_id,
            c.file_name          file_name,
            a.ledger_name        ledger_name,
            c.source_application source_application,
            a.interface_id       interface_id,
            c.status             status
        FROM
            wsc_ahcs_int_control_t     c,
            wsc_ahcs_mfap_txn_header_t a
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

        TYPE mfap_grp_type IS
            TABLE OF mfap_grp_data_fetch_cur%rowtype;
        lv_mfap_grp_type          mfap_grp_type;


       -- TYPE line_validation_after_valid_type IS
          --  TABLE OF cur_line_validation_after_valid%rowtype;
       -- lv_line_validation_after_valid  line_validation_after_valid_type;
        lv_coa_mapid               NUMBER;
        lv_src_system              VARCHAR2(100);
        lv_tgt_system              VARCHAR2(100);
        lv_count_succ              NUMBER;
        retcode                    VARCHAR2(50);
        err_msg                    VARCHAR2(50);
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
	--1. Identify the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 14, 'Transformation start', NULL,
                      sysdate);
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_mapid,
            lv_tgt_system,
            lv_src_system;
        CLOSE cur_coa_map_id;
        logging_insert('ANIXTER AP', p_batch_id, 14, 'Transformation start',
                      lv_coa_mapid
                      || lv_tgt_system
                      || lv_src_system,
                      sysdate);

--        update target_coa in ap_line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
	--2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN
            UPDATE wsc_ahcs_mfap_txn_line_t line
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
            UPDATE wsc_ahcs_mfap_txn_header_t hdr
            SET
               -- target_coa = NULL,
                ledger_name = NULL,
                last_update_date = sysdate
            WHERE
                EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t status
                    WHERE
                            hdr.batch_id = p_batch_id
--                        AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
                        AND status.batch_id = hdr.batch_id
                        AND status.header_id = hdr.header_id
                    --    AND status.line_id = line.line_id
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

        logging_insert('ANIXTER AP', p_batch_id, 13, 'Check data in cache table to find ', NULL,
                      sysdate);
        BEGIN
            IF lv_src_system = 'ANIXTER' THEN
                UPDATE wsc_ahcs_mfap_txn_line_t line
                SET
                    target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa, lv_coa_mapid),
                    last_update_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            ELSE
                UPDATE wsc_ahcs_mfap_txn_line_t line
                SET
                    target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_bu
                                                                   || '.....'
                                                                   || nvl(leg_affiliate, '00000'),
                                                                   lv_coa_mapid)
                WHERE
                    batch_id = p_batch_id;

            END IF;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('ANIXTER AP', p_batch_id, 208, 'Error in Check data in cache table to find', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
               /* EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t status
                    WHERE
                            line.batch_id = p_batch_id
                        AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
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

        BEGIN
            UPDATE wsc_ahcs_ap_txn_line_t line
            SET
                target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa, lv_coa_mapid),
                last_update_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND EXISTS (
                    SELECT
                        1
                    FROM --wsc_gl_ccid_mapping_t ccid_map,
                        wsc_ahcs_int_status_t status
                    WHERE /*ccid_map.coa_map_id = lv_coa_mapid and line.leg_coa = ccid_map.source_segment
				    and*/ /*status.batch_id = line.batch_id
                        AND status.header_id = line.header_id
                        AND status.line_id = line.line_id
                        AND status.attribute2 = 'TRANSFORM_FAILED'
                );

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBS AP', p_batch_id, 22, 'Error in Check data in cache table to find', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
*/
--        update target_coa and attribute1 'Y' in ap_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 17, 'update target_coa and attribute1', NULL,
                      sysdate);
        BEGIN
--            OPEN cur_leg_seg_value(lv_src_system, lv_tgt_system);
--            LOOP
--                FETCH cur_leg_seg_value BULK COLLECT INTO lv_leg_seg_value LIMIT 100;
--                EXIT WHEN lv_leg_seg_value.count = 0;
--                FORALL i IN 1..lv_leg_seg_value.count
--                    UPDATE wsc_ahcs_ap_txn_line_t
--                    SET
--                        target_coa = lv_leg_seg_value(i).target_coa,
--                        attribute1 = 'Y',
--                        last_update_date = sysdate
--                    WHERE
--                            leg_coa = lv_leg_seg_value(i).leg_coa
--                        AND batch_id = p_batch_id;
--
--            END LOOP;
--
--            CLOSE cur_leg_seg_value;
            UPDATE wsc_ahcs_mfap_txn_line_t tgt_coa
            SET
                target_coa = replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, tgt_coa.leg_bu, tgt_coa.leg_loc,
                tgt_coa.leg_dept,
                                                                        tgt_coa.leg_acct,
                                                                        tgt_coa.leg_vendor,
                                                                        nvl(tgt_coa.leg_affiliate, '00000'),
                                                                        NULL,
                                                                        NULL,
                                                                        NULL,
                                                                        NULL),
                                     ' ',
                                     ''),
                attribute1 = 'Y'
            WHERE
                    batch_id = p_batch_id
                AND target_coa IS NULL
                AND EXISTS (
                    SELECT /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */  1
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
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('ANIXTER AP', p_batch_id, 24, 'Error in update target_coa and attribute1', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;


--        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 16, 'insert new target_coa values', NULL,
                      sysdate);
        BEGIN
            IF lv_src_system = 'ANIXTER' THEN
                OPEN cur_inserting_ccid_table;
                LOOP
                    FETCH cur_inserting_ccid_table BULK COLLECT INTO lv_inserting_ccid_table LIMIT 100;
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
                            'ANIXTER AP',
                            'ANIXTER AP',
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
                 --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
                END LOOP;

                CLOSE cur_inserting_ccid_table;
            ELSE
                OPEN cur_inserting_ccid_table;
                LOOP
                    FETCH cur_inserting_ccid_table BULK COLLECT INTO lv_inserting_ccid_table LIMIT 100;
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
                            || '.....'
                            || nvl(lv_inserting_ccid_table(i).leg_affiliate, '00000'),
                            lv_inserting_ccid_table(i).target_coa,
                            sysdate,
                            sysdate,
                            'Y',
                            'N',
                            'ANIXTER AP',
                            'ANIXTER AP',
                            lv_inserting_ccid_table(i).leg_bu,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            nvl(lv_inserting_ccid_table(i).leg_affiliate, '00000'),
                            NULL,
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
                logging_insert('ANIXTER AP', p_batch_id, 116, 'error in ccid insert', sqlerrm,
                              sysdate);
        END;

        UPDATE wsc_ahcs_mfap_txn_line_t
        SET
            attribute1 = NULL
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        

--      update mfap_line table target segments,  where legal_entity must have their in target_coa
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 18, 'update mfap_line table target segments', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_mfap_txn_line_t line
            SET
                gl_legal_entity = substr(target_coa, 1, instr(target_coa, '.', 1, 1) - 1),
                gl_oper_grp = substr(target_coa, instr(target_coa, '.', 1, 1) + 1, instr(target_coa, '.', 1, 2) - instr(target_coa,
                '.', 1, 1) - 1),
                gl_acct = substr(target_coa, instr(target_coa, '.', 1, 2) + 1, instr(target_coa, '.', 1, 3) - instr(target_coa, '.',
                1, 2) - 1),
                gl_dept = substr(target_coa, instr(target_coa, '.', 1, 3) + 1, instr(target_coa, '.', 1, 4) - instr(target_coa, '.',
                1, 3) - 1),
                gl_site = substr(target_coa, instr(target_coa, '.', 1, 4) + 1, instr(target_coa, '.', 1, 5) - instr(target_coa, '.',
                1, 4) - 1),
                gl_ic = substr(target_coa, instr(target_coa, '.', 1, 5) + 1, instr(target_coa, '.', 1, 6) - instr(target_coa, '.',
                1, 5) - 1),
                gl_projects = substr(target_coa, instr(target_coa, '.', 1, 6) + 1, instr(target_coa, '.', 1, 7) - instr(target_coa,
                '.', 1, 6) - 1),
                gl_fut_1 = substr(target_coa, instr(target_coa, '.', 1, 7) + 1, instr(target_coa, '.', 1, 8) - instr(target_coa, '.',
                1, 7) - 1),
                gl_fut_2 = substr(target_coa, instr(target_coa, '.', 1, 8) + 1),
                last_update_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND substr(target_coa, 1, instr(target_coa, '.', 1, 1) - 1) IS NOT NULL
               /* AND EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t sts
                    WHERE
                            sts.header_id = line.header_id
                        AND sts.line_id = line.line_id
                        AND sts.batch_id = line.batch_id
                        AND sts.attribute2 = 'TRANSFORM_FAILED'
                )*/;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
                logging_insert('ANIXTER AP', p_batch_id, 27, 'Error in update mfap_line table target segments', sqlerrm,
                              sysdate);
        END;

--        if any target_coa is empty in ap_line table will mark it as transform_error in status table
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 19, 'if any target_coa is empty', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    status.attribute2,
                    status.attribute1,
                    status.status,
                    status.error_msg,
                    status.last_updated_date,
                    line.batch_id      bt_id,
                    line.header_id     hdr_id,
                    line.line_id       ln_id,
                    line.target_coa    trgt_coa
                FROM
                    wsc_ahcs_int_status_t     status,
                    wsc_ahcs_mfap_txn_line_t  line
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
            logging_insert('ANIXTER AP', p_batch_id, 19.1, 'updated attribute2 with TRANSFORM_FAILED status', NULL,
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
             where exists 
              (select 1 from WSC_AHCS_INT_STATUS_T b 
                where a.batch_id = b.batch_id 
				  and a.header_id = b.header_id 
				  and status = 'TRANSFORM_FAILED'
                  and b.batch_id = p_batch_id ); 
            logging_insert('EBS AP',p_batch_id,19.2,'updated attribute2 with TRANSFORM_FAILED status',null,sysdate);
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
                logging_insert('ANIXTER AP', p_batch_id, 21, 'Error in if any target_coa is empty', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

--      update ledger_name in mfap_header table where transform_success		
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 20, 'update ledger_name', NULL,
                      sysdate);
        BEGIN
        /*    open cur_get_ledger;
            loop
            fetch cur_get_ledger bulk collect into lv_get_ledger limit 100;
            EXIT WHEN lv_get_ledger.COUNT = 0;        
            forall i in 1..lv_get_ledger.count
                update WSC_AHCS_AP_TXN_HEADER_T
                   set ledger_name = lv_get_ledger(i).ledger_name , LAST_UPDATE_DATE = sysdate
                 where batch_id = p_batch_id 
				   and header_id = lv_get_ledger(i).header_id
                   ;
            end loop;  */
            MERGE INTO wsc_ahcs_mfap_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT
                              lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t  lgl_entt,
                              (
                                  SELECT
                                      line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_mfap_txn_line_t  line,
                                      wsc_ahcs_int_status_t     status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = lv_batch_id
                                      AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                                      AND NOT EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t s1
                WHERE
                        s1.batch_id = line.batch_id
                    AND s1.header_id = line.header_id
                    AND s1.error_msg IS NOT NULL
            )
                              )                        d_lgl_entt
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

            COMMIT;
 logging_insert('ANIXTER AP', p_batch_id, 21.1, 'update transaction number with STATIC_LEDGER_NUMBER -starts', NULL,
                          sysdate);           
             UPDATE wsc_ahcs_mfap_txn_header_t hdr
            SET
                transaction_number = transaction_number
                                     || '_'
                                     || (
                    SELECT
                        static_ledger_number
                    FROM
                        wsc_ahcs_int_mf_ledger_t l
                    WHERE
                            l.ledger_name = hdr.ledger_name
                        AND l.sub_ledger = 'MF AP'
                )
            WHERE
                hdr.ledger_name IS NOT NULL
                AND hdr.batch_id = p_batch_id
                AND EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t s
                    WHERE
                        s.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                        AND batch_id = lv_batch_id
                        AND hdr.header_id = s.header_id
                        and hdr.batch_id=s.batch_id
                );

            logging_insert('ANIXTER AP', p_batch_id, 21.2, 'update transaction number with STATIC_LEDGER_NUMBER -header table- complete',
            NULL,
                          sysdate);
                          
             COMMIT;
            UPDATE wsc_ahcs_mfap_txn_line_t line
            SET
                line.transaction_number = (
                    SELECT
                        hdr.transaction_number
                    FROM
                        wsc_ahcs_mfap_txn_header_t hdr
                    WHERE
                        hdr.header_id = line.header_id and
                        hdr.batch_id=line.batch_id
                )
            WHERE
                    line.batch_id = p_batch_id
                AND EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t s
                    WHERE
                        s.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                        AND s.batch_id = lv_batch_id
                        AND line.header_id = s.header_id
                        and line.line_id=s.line_id
                        and line.batch_id=s.batch_id
                );
                commit;  
                logging_insert('ANIXTER AP', p_batch_id, 21.2, 'update transaction number with STATIC_LEDGER_NUMBER -line table- complete',
            NULL,
                          sysdate);
             MERGE INTO wsc_ahcs_int_status_t stauts
            USING wsc_ahcs_mfap_txn_line_t line ON ( stauts.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                                                     AND line.header_id = stauts.header_id
                                                     AND line.batch_id = stauts.batch_id
                                                     AND line.line_id = stauts.line_id
                                                     AND stauts.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET stauts.attribute3 = line.transaction_number;

            COMMIT;
            logging_insert('ANIXTER AP', p_batch_id, 21.3, 'update transaction number with STATIC_LEDGER_NUMBER -status table- complete',
            NULL,
                          sysdate);
            logging_insert('ANIXTER AP', p_batch_id, 21.4, 'update transaction number with STATIC_LEDGER_NUMBER -ends', NULL,
                          sysdate);             
--call multi ledger derivation proc
            logging_insert('ANIXTER AP', p_batch_id, 21.5, 'call wsc_ledger_name_derivation', NULL,
                          sysdate);
            wsc_ledger_name_derivation(lv_batch_id);
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('ANIXTER AP', p_batch_id, 22, 'Error in update ledger_name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('ANIXTER AP', p_batch_id, 121.1, 'Update LEDGER_NAME  in status table -start', NULL,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_mfap_txn_header_t h
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
        END;

        logging_insert('ANIXTER AP', p_batch_id, 121.2, 'Update LEDGER_NAME  in status table -end', NULL,
                      sysdate);
            
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7.1. Update status tables after validation where line cr/dr mismatch.
        --    /******* ALL RECORDS MARKED AS VALIDATION FAILED WHEN LINE CR/DR AMOUNT MISMATCH AFTER VALIDATION ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 21, 'Update status tables after validation', NULL,
                      sysdate);
	/*	begin
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
                logging_insert('ANIXTER AP',p_batch_id,33,'Update status tables after validation',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;
*/
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('ANIXTER AP', p_batch_id, 22, 'Update status tables to have status', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    sts.attribute2,
                    sts.status,
                    sts.last_updated_date,
                    sts.error_msg
                FROM
                    wsc_ahcs_int_status_t       sts,
                    wsc_ahcs_mfap_txn_header_t  hdr
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
                    source_application = 'MF AP'
                AND status = 'TRANSFORM_SUCCESS'
                AND group_id IS NULL
                AND batch_id = p_batch_id;

            logging_insert('MF AP', p_batch_id, 290, 'Group Id update in control table ends.' || sqlerrm, NULL,
                          sysdate);
            COMMIT;
            OPEN mfap_grp_data_fetch_cur(lv_group_id);
            LOOP
                FETCH mfap_grp_data_fetch_cur
                BULK COLLECT INTO lv_mfap_grp_type LIMIT 50;
                EXIT WHEN lv_mfap_grp_type.count = 0;
                FORALL i IN 1..lv_mfap_grp_type.count
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
                        lv_mfap_grp_type(i).batch_id,
                        lv_mfap_grp_type(i).file_name,
                        lv_group_id,
                        lv_mfap_grp_type(i).ledger_name,
                        lv_mfap_grp_type(i).source_application,
                        lv_mfap_grp_type(i).interface_id,
                        lv_mfap_grp_type(i).status,
                        'FIN_INT',
                        sysdate,
                        'FIN_INT',
                        sysdate
                    );

            END LOOP;

            COMMIT;
            logging_insert('MF AP', p_batch_id, 291, 'Control Line insertion for group id ends.' || sqlerrm, NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                group_id = lv_group_id
            WHERE
            -- batch_id IN (
                -- SELECT DISTINCT
                    -- batch_id
                -- FROM
                    -- wsc_ahcs_int_control_line_t
                -- WHERE
                    -- group_id = lv_grp_id
            -- )
                group_id IS NULL
                AND batch_id = p_batch_id
                AND attribute2 = 'TRANSFORM_SUCCESS'
                AND ( accounting_status = 'IMP_ACC_ERROR'
                      OR accounting_status IS NULL );

            COMMIT;
            logging_insert('MF AP', p_batch_id, 292, 'Group id update in status table ends.' || sqlerrm, NULL,
                          sysdate);
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('MF AP', p_batch_id, 290.1, 'Error in the reprocess group id block.' || sqlerrm, NULL,
                              sysdate);
        END;


        logging_insert('ANIXTER AP', p_batch_id, 303, 'Dashboard Start', NULL,
                      sysdate);
        wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
        logging_insert('ANIXTER AP', p_batch_id, 304, 'Dashboard End', NULL,
                      sysdate);
        logging_insert('ANIXTER AP', p_batch_id, 23, 'end transformation', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT218'
                                                    || '_'
                                                    || l_system,
                                                    'ANIXTER_AP',
                                                    sqlerrm);
    END leg_coa_transformation_reprocessing;

    PROCEDURE cresus_data_validation (
        p_batch_id IN NUMBER
    ) IS

        lv_header_err_msg     VARCHAR2(2000) := NULL;
        lv_line_err_msg       VARCHAR2(2000) := NULL;
        lv_header_err_flag    VARCHAR2(100) := 'false';
        lv_line_err_flag      VARCHAR2(100) := 'false';
        l_system              VARCHAR2(30);
        cresus_tmp_batch_id   NUMBER;
        lv_count_sucss        NUMBER := 0;
        retcode               NUMBER;
        TYPE wsc_header_col_value_type IS
            VARRAY(10) OF VARCHAR2(200); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING HEADER OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        lv_header_col_value   wsc_header_col_value_type := wsc_header_col_value_type('HDR_SEQ_NBR', 'INTERFACE_ID', 'BUSINESS_UNIT',
        'ACCOUNTING_DATE');
        -- 4 fields
        TYPE wsc_line_col_value_type IS
            VARRAY(26) OF VARCHAR2(200); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING LINE OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        lv_line_col_value     wsc_line_col_value_type := wsc_line_col_value_type('LINE_SEQ_NUMBER', 'STATEMENT_ID', 'TRANSACTION_CURR_CD',
                                                                            'TRANSACTION_AMOUNT',
                                                                            'BASE_CURR_CD',
                                                                            'BASE_AMOUNT');
    
          -- 6 fields
/************ @@@@@ INITIALIZE HEADER AND LINE FLAG TABLE TYPE VARIABLES TO MATCH THE COUNT OF HEADER AND LINE @@@@@ ************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        TYPE wsc_ahcs_mfap_header_txn_t_type IS
            TABLE OF INTEGER;
        lv_error_mfap_header  wsc_ahcs_mfap_header_txn_t_type := wsc_ahcs_mfap_header_txn_t_type('1', '1', '1', '1', '1',
                                                                                               '1',
                                                                                               '1',
                                                                                               '1',
                                                                                               '1',
                                                                                               '1');
                                                                                               -- 8 '1's
        TYPE wsc_ahcs_mfap_line_txn_t_type IS
            TABLE OF INTEGER;
        lv_error_mfap_line    wsc_ahcs_mfap_line_txn_t_type := wsc_ahcs_mfap_line_txn_t_type('1', '1', '1', '1',
                                                                                         '1',
                                                                                         '1',
                                                                                         '1',
                                                                                         '1',
                                                                                         '1',
                                                                                         '1',
                                                                                         '1',
                                                                                         '1');
                                                                                         --12 '1's
	
-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from LINE STAGING TABLE THAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_wsc_mfap_line (
            cur_p_hdr_id VARCHAR2
        ) IS
        SELECT
            line_seq_number,
            statement_id,
            transaction_curr_cd,
            transaction_amount,
            base_curr_cd,
            base_amount,
            line_id
        FROM
            wsc_ahcs_mfap_txn_line_t
        WHERE
            header_id = cur_p_hdr_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from HEADER STAGING TABLE THAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_header_id (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            header_id,
            hdr_seq_nbr,
            interface_id,
            business_unit,
            accounting_date
        FROM
            wsc_ahcs_mfap_txn_header_t
        WHERE
            batch_id = cur_p_batch_id;  
            /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/
------------------------------------------------------------------------------------------------------------------------------------------------
--Following cursor will verify whether STATEMENT_AMOUNT at header level is equal or not to BASE_AMOUNT(credit)and(debit) at line level and will flag the results.
------------------------------------------------------------------------------------------------------------------------------------------------

       /* CURSOR cur_header_validation (
            cur_p_batch_id NUMBER
        ) IS
        WITH line_cr AS (
            SELECT
                header_id,
                abs(SUM(base_amount)) sum_data
            FROM
                wsc_ahcs_mfap_txn_line_t
            WHERE
                    db_cr_flag = 'CR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ), line_dr AS (
            SELECT
                header_id,
                abs(SUM(base_amount)) sum_data
            FROM
                wsc_ahcs_mfap_txn_line_t
            WHERE
                    db_cr_flag = 'DR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ), header_amt AS (
            SELECT
                header_id,
                abs(SUM(statement_amount)) sum_data
            FROM
                wsc_ahcs_mfap_txn_header_t
            WHERE
                batch_id = cur_p_batch_id
            GROUP BY
                header_id
        )
        SELECT
            l_cr.header_id
        FROM
            line_cr    l_cr,
            line_dr    l_dr,
            header_amt h_amt
        WHERE
                l_cr.header_id = h_amt.header_id
            AND l_dr.header_id = h_amt.header_id
            AND ( l_dr.sum_data <> h_amt.sum_data
                  OR l_cr.sum_data <> h_amt.sum_data )
            AND l_dr.header_id = l_cr.header_id;
        */
    
 ------------------------------------------------------------------------------------------------------------------------------------------------           
   /*     TYPE header_validation_type IS
            TABLE OF cur_header_validation%rowtype;
        lv_header_validation header_validation_type;
*/
------------------------------------------------------------------------------------------------------------------------------------------------
--Following cursor will verify whether Base amount (debit) is equal or not to Base amount (credit) and will flag the results.
------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_line_validation (
            cur_p_batch_id NUMBER
        ) IS
        WITH line_cr AS (
            SELECT
                header_id,
                abs(SUM(base_amount)) sum_data
            FROM
                wsc_ahcs_mfap_txn_line_t
            WHERE
                    db_cr_flag = 'CR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ), line_dr AS (
            SELECT
                header_id,
                abs(SUM(base_amount)) sum_data
            FROM
                wsc_ahcs_mfap_txn_line_t
            WHERE
                    db_cr_flag = 'DR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        )
        SELECT
            nvl(cr_hdr, dr_hdr) header_id
        FROM
            (
                SELECT
                    l_cr.header_id    cr_hdr,
                    l_dr.header_id    dr_hdr,
                    l_cr.sum_data     cr_sum,
                    l_dr.sum_data     dr_sum
                FROM
                    line_cr  l_cr,
                    line_dr  l_dr
                WHERE
                        nvl(l_dr.sum_data, 0) <> nvl(l_cr.sum_data, 0)
                    AND l_dr.header_id (+) = l_cr.header_id
                UNION
                SELECT
                    l_cr.header_id    cr_hdr,
                    l_dr.header_id    dr_hdr,
                    l_cr.sum_data     cr_sum,
                    l_dr.sum_data     dr_sum
                FROM
                    line_cr  l_cr,
                    line_dr  l_dr
                WHERE
                        nvl(l_dr.sum_data, 0) <> nvl(l_cr.sum_data, 0)
                    AND l_dr.header_id = l_cr.header_id (+)
            );

------------------------------------------------------------------------------------------------------------------------------------------------          
        TYPE line_validation_type IS
            TABLE OF cur_line_validation%rowtype;
        lv_line_validation    line_validation_type;
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

        err_msg               VARCHAR2(2000);
    BEGIN
  
  ---store mainframe sub system name name in  'l_system' variable--- 
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
 --- store cresus original batch id from temp table       
   BEGIN
    SELECT DISTINCT
        attribute6
    INTO cresus_tmp_batch_id
    FROM
        wsc_ahcs_mfap_txn_header_t h
    WHERE
        h.batch_id = p_batch_id;

  END;
------------------------------------------------------------------------------------------------------------------------------------------------
        -- 1. Start of validation -
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
  /*      logging_insert('Cresus_MF AP', p_batch_id, 101, 'Start of validation - Header STATEMENT_AMOUNT mismatch with Line DR/CR Amount', NULL,sysdate);
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
                        error_msg = '302|Header amount mismatch with Line DR/CR Amount',
                        reextract_required = 'Y',
                        attribute1 = 'H',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id --AND STATUS='NEW'
                        AND header_id = lv_header_validation(i).header_id;

            END LOOP;

            CLOSE cur_header_validation;
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Cresus_MF AP', p_batch_id, 201, 'exception in Header STATEMENT_AMOUNT mismatch with Line DR/CR Amount',
                sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('Cresus_MF AP', p_batch_id, 102, 'End of validation - Header STATEMENT_AMOUNT mismatch with Line DR/CR Amount', NULL,sysdate);
     
     */
 ------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2. Validate BASE_AMOUNT
        --  Identify transactions wherein BASE_AMOUNT(DEBIT) does not match with BASE_AMOUNT(CREDIT) .
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
        logging_insert('Cresus_MF AP', p_batch_id, 103, 'Start of validation - Validate BASE_AMOUNT', NULL,
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
                        AND header_id = lv_line_validation(i).header_id;

            END LOOP;

            CLOSE cur_line_validation;
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Cresus_MF AP', p_batch_id, 203, 'exception in BASE_AMOUNT validation', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
                ROLLBACK;
        END;

        logging_insert('Cresus_MF AP', p_batch_id, 104, 'End of validation - Validate BASE_AMOUNT', NULL,
                      sysdate);
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
        logging_insert('Cresus_MF AP', p_batch_id, 105, 'Validate header and line fields data type start', NULL,
                      sysdate);
        BEGIN
            FOR header_id_f IN cur_header_id(p_batch_id) LOOP
                lv_header_err_flag := 'false';
                lv_header_err_msg := NULL;
                lv_error_mfap_header := wsc_ahcs_mfap_header_txn_t_type('1', '1', '1', '1', '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1');

                lv_error_mfap_header(1) := is_varchar2_null(header_id_f.hdr_seq_nbr);
                lv_error_mfap_header(2) := is_varchar2_null(header_id_f.interface_id);
                lv_error_mfap_header(3) := is_varchar2_null(header_id_f.business_unit);
                lv_error_mfap_header(4) := is_date_null(header_id_f.accounting_date);
                FOR i IN 1..4 LOOP
--                    dbms_output.put_line(lv_error_mfap_header(i));
                    IF lv_error_mfap_header(i) = 0 THEN
                        lv_header_err_msg := lv_header_err_msg
                                             || '300|Missing value of '
                                             || lv_header_col_value(i)
                                             || '. ';
                        lv_header_err_flag := 'true';
                    END IF;
                END LOOP;

                IF lv_header_err_flag = 'true' THEN
                    UPDATE wsc_ahcs_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = substr((error_msg
                                            || ','
                                            || lv_header_err_msg),
                                           1,
                                           200),
                        reextract_required = 'Y',
                        attribute1 = 'H',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        AND status = 'NEW'
                        AND header_id = header_id_f.header_id;

                    COMMIT;
                    logging_insert('Cresus_MF AP', p_batch_id, 204, 'mandatory field Validation failed for header' || header_id_f.
                    header_id,
                                  lv_header_err_flag,
                                  sysdate);

                    CONTINUE;
                END IF;
                        


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

                FOR wsc_mfap_line IN cur_wsc_mfap_line(header_id_f.header_id) LOOP
                    lv_line_err_flag := 'false';
                    lv_line_err_msg := NULL;
                    lv_error_mfap_line := wsc_ahcs_mfap_line_txn_t_type('1', '1', '1', '1', '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1',
                                                                       '1');

                    lv_error_mfap_line(1) := is_number_null(wsc_mfap_line.line_seq_number);
                    lv_error_mfap_line(2) := is_varchar2_null(wsc_mfap_line.statement_id);
                    lv_error_mfap_line(3) := is_varchar2_null(wsc_mfap_line.transaction_curr_cd);
                    lv_error_mfap_line(4) := is_number_null(wsc_mfap_line.transaction_amount);
                    lv_error_mfap_line(5) := is_varchar2_null(wsc_mfap_line.base_curr_cd);
                    lv_error_mfap_line(6) := is_number_null(wsc_mfap_line.base_amount);
                    FOR j IN 1..6 LOOP
                        IF lv_error_mfap_line(j) = 0 THEN
                            lv_line_err_msg := lv_line_err_msg
                                               || '300|Missing Value of '
                                               || lv_line_col_value(j)
                                               || '. ';
                            lv_line_err_flag := 'true';
                        END IF;
                    END LOOP;

                    IF lv_line_err_flag = 'true' THEN
                        UPDATE wsc_ahcs_int_status_t
                        SET
                            status = 'VALIDATION_FAILED',
                            --error_msg = lv_line_err_msg,
                            --error_msg = substr(lv_line_err_msg,1,200),
                            error_msg = substr((error_msg
                                                || ','
                                                || lv_line_err_msg),
                                               1,
                                               200),
                            reextract_required = 'Y',
                            attribute1 = 'L',
                            attribute2 = 'VALIDATION_FAILED',
                            last_updated_date = sysdate
                        WHERE
                                batch_id = p_batch_id
                            AND status = 'NEW'
                            AND header_id = header_id_f.header_id
                            AND line_id = wsc_mfap_line.line_id;

                        COMMIT;
--logging_insert('Cresus_MF AP', p_batch_id, 205, 'Updated Line ID'|| wsc_mfap_line.line_id|| ' for Header ID'|| header_id_f.header_id,lv_line_err_flag,sysdate);

                        UPDATE wsc_ahcs_int_status_t
                        SET
                            attribute1 = 'L',
                            attribute2 = 'VALIDATION_FAILED',
                            last_updated_date = sysdate
                        WHERE
                                batch_id = p_batch_id
                            AND status = 'NEW'
                            AND header_id = header_id_f.header_id;

                        COMMIT;
                        --logging_insert('Cresus_MF AP', p_batch_id, 206, 'Updated Header ID' || header_id_f.header_id, lv_line_err_flag, sysdate);

                    END IF;

                END LOOP;

            END LOOP;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line(sqlerrm);
                err_msg := substr(sqlerrm, 1, 200);
                logging_insert('Cresus_MF AP', p_batch_id, 207, 'Error in mandatory field validation', err_msg,
                              sysdate);
                dbms_output.put_line(err_msg);
        END;

        logging_insert('Cresus_MF AP', p_batch_id, 106, 'end mandatory validation', NULL,
                      sysdate);
        BEGIN
            logging_insert('Cresus_MF AP', p_batch_id, 107, 'start updating STATUS TABLE with validation status', NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'VALIDATION_FAILED',
                error_msg = 'error in HDR_SEQ_NBR',
                reextract_required = 'Y',
                attribute1 = 'L',
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
            logging_insert('Cresus_MF AP', p_batch_id, 108, 'status updated in STATUS TABLE', NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                attribute2 = 'VALIDATION_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
              --  AND status = 'NEW'
                AND attribute2 IS NULL;

            COMMIT;
            logging_insert('Cresus_MF AP', p_batch_id, 109, 'attribute 2 updated in STATUS TABLE', NULL,
                          sysdate);
            OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_sucss;
            CLOSE cur_count_sucss;
            logging_insert('Cresus_MF AP', p_batch_id, 110, 'count success', lv_count_sucss,
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
                logging_insert('Cresus_MF AP', p_batch_id, 111, 'call transformation pkg ', NULL,
                              sysdate);
                BEGIN
                    wsc_ahcs_mfap_validation_transformation_pkg.leg_coa_transformation(p_batch_id);
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
            logging_insert('Cresus_MF AP', p_batch_id, 124, 'end data_validation and transformation', NULL,
                          sysdate);
            logging_insert('Cresus_MF AP', p_batch_id, 125, 'AHCS Dashboard refresh Start', NULL,
                          sysdate);
            wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
            logging_insert('Cresus_MF AP', p_batch_id, 126, 'AHCS Dashboard refresh End', NULL,
                          sysdate);
                          
    --delete data from temp table for this batch id                      
            DELETE FROM wsc_ahcs_cres_txn_tmp_t
            WHERE
                batch_id = cresus_tmp_batch_id;

            logging_insert('Cresus_MF AP', p_batch_id, 127, 'deleted data from WSC_AHCS_MFAP_TXN_TMP_T for this batch_id',
                          NULL,
                          sysdate);
        END;

    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT240'
                                                    || '_'
                                                    || l_system,
                                                    'MF AP',
                                                    sqlerrm);
    END cresus_data_validation;

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

    PROCEDURE wsc_ledger_name_derivation (
        p_batch_id IN NUMBER
    ) IS

        lv_batch_id NUMBER := p_batch_id;
--    lv_header_id number := 71331;

       /* CURSOR cur_error_header IS
        SELECT
            ROW_NUMBER()
            OVER(PARTITION BY hdr.header_id
                 ORDER BY hdr.header_id
            )                  row_number_data,
            hdr.*,
            line.attribute5    new_ledger_name
        FROM
            (
                SELECT
                    header_id,
                    attribute5
                FROM
                    wsc_ahcs_mfap_txn_line_t line
                WHERE
                    attribute5 IS NOT NULL
                    AND batch_id = lv_batch_id
                     and exists (select 1 from wsc_ahcs_int_status_t s where s.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' ) AND BATCH_ID =lv_batch_id AND line.line_id = s.line_id )
                GROUP BY
                    header_id,
                    attribute5
            )                           line,
            wsc_ahcs_mfap_txn_header_t  hdr
        WHERE
                line.header_id = hdr.header_id
            AND hdr.batch_id = lv_batch_id
        ORDER BY
            hdr.header_id; */


        CURSOR cur_error_header IS
        WITH ln AS (
            SELECT /*+ MATERIALIZE*/
                line.header_id              header_id,
                line.attribute5             attribute5,
                led.static_ledger_number    static_ledger_num,
                line.transaction_number     transaction_num
            FROM
                wsc_ahcs_mfap_txn_line_t  line,
                wsc_ahcs_int_mf_ledger_t  led
            WHERE
                    line.attribute5 = led.ledger_name
                AND led.sub_ledger = 'MF AP'
                AND attribute5 IS NOT NULL
                AND batch_id = lv_batch_id
                AND EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t s
                    WHERE
                        s.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                        AND batch_id = lv_batch_id
                        AND line.line_id = s.line_id
                )
            GROUP BY
                header_id,
                attribute5,
                static_ledger_number,
                transaction_number
        )
        SELECT
            transaction_num
            || '_'
            || static_ledger_num    trx_number,
            hdr.*,
            l.attribute5           new_ledger_name
        FROM
            ln                          l,
            wsc_ahcs_mfap_txn_header_t  hdr
--            
        WHERE
                l.header_id = hdr.header_id
            AND hdr.batch_id = lv_batch_id;

            
--            CURSOR cur_error_header IS
--            SELECT
-- hdr.transaction_number||'_'||STATIC_LEDGER_NUM    trx_number,
--            hdr.*,
--            line.attribute5    new_ledger_name
--        FROM
--            (
--                SELECT
--                    line.header_id     header_id,
--                    line.attribute5    attribute5
--                    ,
--                    led.STATIC_LEDGER_NUMBER   STATIC_LEDGER_NUM
----                    ,
----                    line.transaction_number    transaction_num
--                FROM
--                    wsc_ahcs_mfap_txn_line_t line, wsc_ahcs_int_mf_ledger_t led
--                WHERE
--                line.attribute5 = led.ledger_name
--                and led.sub_ledger = 'MF AP'
--                and
--                    attribute5 IS NOT NULL
--                    AND batch_id = lv_batch_id
--                     and exists (select 1 from wsc_ahcs_int_status_t s where s.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' ) 
--                     AND BATCH_ID =lv_batch_id AND line.line_id = s.line_id )
--                GROUP BY
--                    header_id,
--                    attribute5
--                    ,
--                    STATIC_LEDGER_NUMBER
----                    ,
----                    transaction_number
--            )                           line,
--            wsc_ahcs_mfap_txn_header_t  hdr
----            ,
----              (select led.STATIC_LEDGER_NUMBER   STATIC_LEDGER_NUM from 
----              wsc_ahcs_mfap_txn_line_t line, wsc_ahcs_int_mf_ledger_t led
----              where line.attribute5 = led.ledger_name
----                and led.sub_ledger = 'MF AP'
----                and attribute5 IS NOT NULL
----                AND batch_id = lv_batch_id)
--              
--        WHERE
--                line.header_id = hdr.header_id
--            AND hdr.batch_id = lv_batch_id
--        ORDER BY
--            hdr.header_id;

    BEGIN
        logging_insert('MF AP', p_batch_id, 301, 'inside wsc_ledger_name_derivation', NULL,
                      sysdate);
        logging_insert('MF AP', p_batch_id, 302, 'update attr5 in Line table- start', NULL,
                      sysdate);
        UPDATE wsc_ahcs_mfap_txn_line_t line
        SET
            attribute5 = (
                SELECT
                    ledger_name
                FROM
                    wsc_gl_legal_entities_t data
                WHERE
                    line.gl_legal_entity = data.flex_segment_value
            )
        WHERE
            header_id IN (
                SELECT
                    header_id
                FROM
                    wsc_ahcs_mfap_txn_header_t
                WHERE
                        batch_id = lv_batch_id
                    AND ledger_name IS NULL
            ) 
--    and header_id = lv_header_id;
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t s1
                WHERE
                        s1.batch_id = line.batch_id
                    AND s1.header_id = line.header_id
                    AND s1.error_msg IS NOT NULL
            )
            AND EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t s
                WHERE
                    s.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                    AND batch_id = lv_batch_id
                    AND line.line_id = s.line_id
            );

        logging_insert('MF AP', p_batch_id, 303, 'update attr5 in Line table- end', NULL,
                      sysdate);
        logging_insert('MF AP', p_batch_id, 304, 'insert new header id in header table-start', NULL,
                      sysdate);
        FOR i IN cur_error_header LOOP
            INSERT INTO wsc_ahcs_mfap_txn_header_t (
                batch_id,
                header_id,
                hdr_seq_nbr,
                interface_id,
                vendor_nbr,
                invoice_nbr,
                invoice_date,
                continent,
                business_unit,
                division,
                location,
                net_total,
                loc_inv_net_total,
                invoice_total,
                local_inv_total,
                refer_invoice,
                purchase_order_nbr,
                po_type,
                invoice_type,
                fx_rate,
                check_nbr,
                check_amount,
                check_date,
                check_stock,
                check_payment_type,
                vendor_payment_type,
                void_code,
                cross_border_flag,
                batch_number,
                batch_date,
                batch_posted_flag,
                pay_from_account,
                transref,
                third_party_intfc_flag,
                payment_ref_id,
                head_office_loc,
                sales_loc,
                third_party_invoice_id,
                vendor_currency_code,
                employee_id,
                vendor_name,
                accounting_date,
                business_segment,
                interfc_desc_t,
                interfc_desc_loc_lang,
                due_date,
                vendor_abbrev,
                frt_bill_pro_ref_nbr,
                spc_inv_code,
                void_date,
                matching_key,
                matching_date,
                updated_user,
                userid,
                contra_reason,
                accrued_qty,
                document_date,
                freight_terms,
                voucher_nbr,
                fiscal_date,
                concur_sae_batch_id,
                fiscal_week_nbr,
                gaap_amount,
                gaap_amount_in_cust_curr,
                journal_source_c,
                error_type,
                error_code,
                transaction_date,
                transaction_number,
                ledger_name,
                file_name,
                transaction_type,
                account_currency,
                statement_amount,
                statement_descr,
                statement_id,
                statement_upd_date,
                statement_upd_by,
                statement_date,
                posting_year,
                posting_period,
                creation_date,
                created_by,
                last_update_date,
                last_updated_by,
                attribute1,
                attribute2,
                attribute3,
                attribute4,
                attribute5,
                attribute6,
                attribute7,
                attribute8,
                attribute9,
                attribute10,
                attribute11,
                attribute12,
                record_type
            ) VALUES (
                i.batch_id,
                wsc_mfap_header_t_s1.NEXTVAL,
                i.hdr_seq_nbr,
                i.interface_id,
                i.vendor_nbr,
                i.invoice_nbr,
                i.invoice_date,
                i.continent,
                i.business_unit,
                i.division,
                i.location,
                i.net_total,
                i.loc_inv_net_total,
                i.invoice_total,
                i.local_inv_total,
                i.refer_invoice,
                i.purchase_order_nbr,
                i.po_type,
                i.invoice_type,
                i.fx_rate,
                i.check_nbr,
                i.check_amount,
                i.check_date,
                i.check_stock,
                i.check_payment_type,
                i.vendor_payment_type,
                i.void_code,
                i.cross_border_flag,
                i.batch_number,
                i.batch_date,
                i.batch_posted_flag,
                i.pay_from_account,
                i.transref,
                i.third_party_intfc_flag,
                i.payment_ref_id,
                i.head_office_loc,
                i.sales_loc,
                i.third_party_invoice_id,
                i.vendor_currency_code,
                i.employee_id,
                i.vendor_name,
                i.accounting_date,
                i.business_segment,
                i.interfc_desc_t,
                i.interfc_desc_loc_lang,
                i.due_date,
                i.vendor_abbrev,
                i.frt_bill_pro_ref_nbr,
                i.spc_inv_code,
                i.void_date,
                i.matching_key,
                i.matching_date,
                i.updated_user,
                i.userid,
                i.contra_reason,
                i.accrued_qty,
                i.document_date,
                i.freight_terms,
                i.voucher_nbr,
                i.fiscal_date,
                i.concur_sae_batch_id,
                i.fiscal_week_nbr,
                i.gaap_amount,
                i.gaap_amount_in_cust_curr,
                i.journal_source_c,
                i.error_type,
                i.error_code,
                i.transaction_date,
                i.trx_number,
                i.new_ledger_name,
                i.file_name,
                i.transaction_type,
                i.account_currency,
                i.statement_amount,
                i.statement_descr,
                i.statement_id,
                i.statement_upd_date,
                i.statement_upd_by,
                i.statement_date,
                i.posting_year,
                i.posting_period,
                sysdate,
                i.created_by,
                sysdate,
                i.last_updated_by,
                i.attribute1,
                i.attribute2,
                i.attribute3,
                i.attribute4,
                i.attribute5,
                i.attribute6,
                i.header_id,
                i.attribute8,
                i.attribute9,
                i.attribute10,
                i.attribute11,
                i.attribute12,
                i.record_type
            );

        END LOOP;

        logging_insert('MF AP', p_batch_id, 305, 'insert new header id in header table-end', NULL,
                      sysdate);
        UPDATE wsc_ahcs_mfap_txn_line_t line
        SET
            line.last_update_date = sysdate,
            header_id = (
                SELECT
                    header_id
                FROM
                    wsc_ahcs_mfap_txn_header_t hdr
                WHERE
                        line.attribute5 = hdr.ledger_name
                    AND line.header_id = hdr.attribute7
                    AND line.batch_id = hdr.batch_id
                    AND hdr.batch_id = lv_batch_id
            ),
            transaction_number = (
                SELECT
                    transaction_number
                FROM
                    wsc_ahcs_mfap_txn_header_t hdr
                WHERE
                        line.attribute5 = hdr.ledger_name
                    AND line.header_id = hdr.attribute7
                    AND line.batch_id = hdr.batch_id
                    AND hdr.batch_id = lv_batch_id
            )
        WHERE
                batch_id = lv_batch_id
            AND attribute5 IS NOT NULL
            AND EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_status_t s
                WHERE
                    s.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                    AND batch_id = lv_batch_id
                    AND line.line_id = s.line_id
            );

        logging_insert('MF AP', p_batch_id, 306, 'updated header id in Line table', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_status_t sts
        SET
            sts.last_updated_date = sysdate,
            header_id = (
                SELECT
                    header_id
                FROM
                    wsc_ahcs_mfap_txn_line_t line
                WHERE
                        line.line_id = sts.line_id
                    AND line.batch_id = sts.batch_id
                    AND line.batch_id = lv_batch_id
            ),
            attribute3 = (
                SELECT
                    transaction_number
                FROM
                    wsc_ahcs_mfap_txn_line_t line
                WHERE
                        line.line_id = sts.line_id
                    AND line.batch_id = sts.batch_id
                    AND line.batch_id = lv_batch_id
            )
        WHERE
                batch_id = lv_batch_id
            AND sts.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' );

        logging_insert('MF AP', p_batch_id, 307, 'updated header id in status table', NULL,
                      sysdate);
        DELETE FROM wsc_ahcs_mfap_txn_header_t
        WHERE
            header_id IN (
                SELECT DISTINCT
                    attribute7
                FROM
                    wsc_ahcs_mfap_txn_header_t
                WHERE
                        batch_id = lv_batch_id
                    AND attribute7 IS NOT NULL
            )
            AND batch_id = lv_batch_id;

        COMMIT;
        logging_insert('MF AP', p_batch_id, 308, 'deleted old header id', NULL,
                      sysdate);
    END;

    PROCEDURE wsc_ahcs_mfap_grp_id_upd_p (
        in_grp_id IN NUMBER
    ) AS

        lv_grp_id         NUMBER := in_grp_id;
        err_msg           VARCHAR2(4000);
        CURSOR mfap_grp_data_fetch_cur (
            p_grp_id NUMBER
        ) IS
        SELECT DISTINCT
            c.batch_id              batch_id,
            c.file_name             file_name,
            a.ledger_name           ledger_name,
            c.source_application    source_application,
            a.interface_id          interface_id,
            c.status                status
        FROM
            wsc_ahcs_int_control_t      c,
            wsc_ahcs_mfap_txn_header_t  a
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

        TYPE mfap_grp_type IS
            TABLE OF mfap_grp_data_fetch_cur%rowtype;
        lv_mfap_grp_type  mfap_grp_type;
    BEGIN
-- Updating Group Id for MF AP Files in control table----

        UPDATE wsc_ahcs_int_control_t
        SET
            group_id = lv_grp_id
        WHERE
                source_application = 'MF AP'
            AND status = 'TRANSFORM_SUCCESS'
            AND group_id IS NULL;

        COMMIT;
        OPEN mfap_grp_data_fetch_cur(lv_grp_id);
        LOOP
            FETCH mfap_grp_data_fetch_cur BULK COLLECT INTO lv_mfap_grp_type LIMIT 50;
            EXIT WHEN lv_mfap_grp_type.count = 0;
            FORALL i IN 1..lv_mfap_grp_type.count
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
                    lv_mfap_grp_type(i).batch_id,
                    lv_mfap_grp_type(i).file_name,
                    lv_grp_id,
                    lv_mfap_grp_type(i).ledger_name,
                    lv_mfap_grp_type(i).source_application,
                    lv_mfap_grp_type(i).interface_id,
                    lv_mfap_grp_type(i).status,
                    'FIN_INT',
                    sysdate,
                    'FIN_INT',
                    sysdate
                );

        END LOOP;

        COMMIT;
 
 --UPDATE GROUP_ID IN STATUS TABLE   
        UPDATE wsc_ahcs_int_status_t
        SET
            group_id = lv_grp_id
        WHERE
                application = 'MF AP'
        --AND status = 'TRANSFORM_SUCCESS'
            AND group_id IS NULL
            AND attribute2 = 'TRANSFORM_SUCCESS'
            AND ( accounting_status IS NULL
                  OR accounting_status = 'IMP_ACC_ERROR' )
            AND batch_id IN (
                SELECT DISTINCT
                    batch_id
                FROM
                    wsc_ahcs_int_control_line_t
                WHERE
                    group_id = lv_grp_id
            );

        COMMIT;
    END wsc_ahcs_mfap_grp_id_upd_p;

    PROCEDURE wsc_ahcs_mfap_ctrl_line_tbl_ucm_update (
        p_ucmdoc_id       IN  VARCHAR2,
        p_group_id        IN  VARCHAR2,
        p_ledger_grp_num  IN  VARCHAR2
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
                        AND ml.sub_ledger = 'MF AP'
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
                        AND ml.sub_ledger = 'MF AP'
                        AND ml.ledger_name = status.ledger_name
                ) );

            COMMIT;
        END IF;
    END wsc_ahcs_mfap_ctrl_line_tbl_ucm_update;

    PROCEDURE wsc_ahcs_mfap_ctrl_line_tbl_ledger_grp_num_update (
        p_group_id        IN  VARCHAR2,
        p_ledger_grp_num  IN  VARCHAR2
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
                        AND ml.sub_ledger = 'MF AP'
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
                        AND ml.sub_ledger = 'MF AP'
                        AND ml.ledger_name = status.ledger_name
                ) );

            COMMIT;
        END IF;
    END wsc_ahcs_mfap_ctrl_line_tbl_ledger_grp_num_update;

    PROCEDURE leg_coa_transformation_jti_mfap (
        p_batch_id IN NUMBER
    ) AS
            
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

        lv_batch_id    NUMBER := p_batch_id;
        lv_count_succ  NUMBER;
        retcode        VARCHAR2(50);
        err_msg        VARCHAR2(50);
        
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
            
    BEGIN
        BEGIN
            logging_insert('JTI MF AP', p_batch_id, 6, 'start transformation', NULL,
                          sysdate);
            logging_insert('JTI MF AP', p_batch_id, 7, 'update ledger_name', NULL,
                          sysdate);
                          
          UPDATE wsc_ahcs_int_control_t
            SET
                status = 'VALIDATION_SUCCESS'
            WHERE
                batch_id = p_batch_id;
                
            MERGE INTO wsc_ahcs_mfap_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT
                              lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t  lgl_entt,
                              (
                                  SELECT
                                      line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_mfap_txn_line_t  line,
                                      wsc_ahcs_int_status_t     status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = lv_batch_id
                                      AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                              )                        d_lgl_entt
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

            COMMIT;
 logging_insert('JTI MF AP', p_batch_id, 7.1, 'update transaction number with STATIC_LEDGER_NUMBER -starts', NULL,sysdate);           
             UPDATE wsc_ahcs_mfap_txn_header_t hdr
            SET
                transaction_number = transaction_number
                                     || '_'
                                     || (
                    SELECT
                        static_ledger_number
                    FROM
                        wsc_ahcs_int_mf_ledger_t l
                    WHERE
                            l.ledger_name = hdr.ledger_name
                        AND l.sub_ledger = 'MF AP'
                )
            WHERE
                hdr.ledger_name IS NOT NULL
                AND hdr.batch_id = p_batch_id
                AND EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t s
                    WHERE
                        s.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                        AND batch_id = lv_batch_id
                        AND hdr.header_id = s.header_id
                        and hdr.batch_id=s.batch_id
                );

 logging_insert('ANIXTER AP', p_batch_id, 7.2, 'update transaction number with STATIC_LEDGER_NUMBER -header table- complete',NULL, sysdate);
                          
             COMMIT;
            UPDATE wsc_ahcs_mfap_txn_line_t line
            SET
                line.transaction_number = (
                    SELECT
                        hdr.transaction_number
                    FROM
                        wsc_ahcs_mfap_txn_header_t hdr
                    WHERE
                        hdr.header_id = line.header_id and
                        hdr.batch_id=line.batch_id
                )
            WHERE
                    line.batch_id = p_batch_id
                AND EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t s
                    WHERE
                        s.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                        AND s.batch_id = lv_batch_id
                        AND line.header_id = s.header_id
                        and line.line_id=s.line_id
                        and line.batch_id=s.batch_id
                );
                commit;  
logging_insert('ANIXTER AP', p_batch_id, 21.2, 'update transaction number with STATIC_LEDGER_NUMBER -line table- complete', NULL,sysdate);

             MERGE INTO wsc_ahcs_int_status_t stauts
            USING wsc_ahcs_mfap_txn_line_t line ON ( stauts.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                                                     AND line.header_id = stauts.header_id
                                                     AND line.batch_id = stauts.batch_id
                                                     AND line.line_id = stauts.line_id
                                                     AND stauts.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET stauts.attribute3 = line.transaction_number;

            COMMIT;
logging_insert('ANIXTER AP', p_batch_id, 7.3, 'update transaction number with STATIC_LEDGER_NUMBER -status table- complete',NULL,sysdate);
logging_insert('ANIXTER AP', p_batch_id, 7.4, 'update transaction number with STATIC_LEDGER_NUMBER -ends', NULL,sysdate);                    
--call multi ledger proc
logging_insert('ANIXTER AP', p_batch_id, 8, 'call wsc_ledger_name_derivation', NULL, sysdate);
            wsc_ledger_name_derivation(lv_batch_id);
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('ANIXTER AP', p_batch_id, 212, 'Error in update ledger_name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('ANIXTER AP', p_batch_id, 9, 'Update LEDGER_NAME  in status table -start', NULL,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_mfap_txn_header_t h
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
        END;

        logging_insert('ANIXTER AP', p_batch_id, 10, 'Update LEDGER_NAME  in status table -end', NULL,
                      sysdate);
        logging_insert('ANIXTER AP', p_batch_id, 11, 'Update status table to have record-wise status', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    sts.attribute2,
                    sts.status,
                    sts.last_updated_date,
                    sts.error_msg
                FROM
                    wsc_ahcs_int_status_t       sts,
                    wsc_ahcs_mfap_txn_header_t  hdr
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

            logging_insert('JTI MF AP', p_batch_id, 12, 'Update status column in status table to have record-wise status',
                          NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'TRANSFORM_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                --AND attribute2 = 'VALIDATION_SUCCESS'
                AND error_msg IS NULL;

            COMMIT;
            logging_insert('JTI AP', p_batch_id, 13, 'Update attribute2 column in status table to have record-wise status',
                          NULL,
                          sysdate);
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

            logging_insert('JTI MF AP', p_batch_id, 14, 'Update control table status', NULL,
                          sysdate);
            OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_succ;
            CLOSE cur_count_sucss;
            logging_insert('JTI AP', p_batch_id, 14.1, 'count success', lv_count_succ,
                          sysdate);
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
            logging_insert('JTI MF AP', p_batch_id, 15, 'end  transformation', NULL,
                          sysdate);
            logging_insert('JTI MF AP', p_batch_id, 16, 'AHCS Dashboard refresh Start', NULL,
                          sysdate);
            wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
            logging_insert('JTI MF AP', p_batch_id, 17, 'AHCS Dashboard refresh End', NULL,
                          sysdate);
        END;

        logging_insert('JTI MF AP', p_batch_id, 18, 'end transformation after dashboard call', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT241'
                                                    || '_'
                                                    || 'MFAP',
                                                    'ANIXTER_AP',
                                                    sqlerrm);
    END leg_coa_transformation_jti_mfap;


    PROCEDURE leg_coa_transformation_jti_mfap_reprocessing (
        p_batch_id IN NUMBER
    ) AS
            
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

        lv_batch_id    NUMBER := p_batch_id;
        lv_group_id      NUMBER; --added for reprocess individual group id process 12th Dec 2022
        lv_count_succ  NUMBER;
        retcode        VARCHAR2(50);
        err_msg        VARCHAR2(50);
        
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
        
     CURSOR jti_mfap_grp_data_fetch_cur ( --added for reprocess individual group id process 12th Dec 2022
            p_grp_id NUMBER
        ) IS
        SELECT DISTINCT
            c.batch_id           batch_id,
            c.file_name          file_name,
            a.ledger_name        ledger_name,
            c.source_application source_application,
            a.interface_id       interface_id,
            c.status             status
        FROM
            wsc_ahcs_int_control_t     c,
            wsc_ahcs_mfap_txn_header_t a
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

        TYPE mfap_grp_type IS
            TABLE OF jti_mfap_grp_data_fetch_cur%rowtype;
        lv_mfap_grp_type mfap_grp_type;   
            
    BEGIN
        BEGIN
            logging_insert('JTI MF AP', p_batch_id, 6, 'start transformation', NULL,
                          sysdate);
            logging_insert('JTI MF AP', p_batch_id, 7, 'update ledger_name', NULL,
                          sysdate);
                          
          UPDATE wsc_ahcs_int_control_t
            SET
                status = 'VALIDATION_SUCCESS'
            WHERE
                batch_id = p_batch_id;
                
           UPDATE wsc_ahcs_int_status_t status
            SET
                error_msg = NULL,
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status.attribute2 = 'TRANSFORM_FAILED';

            COMMIT;
  -- Update Ledger based on the legal entity in the header table.---              
            MERGE INTO wsc_ahcs_mfap_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT
                              lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t  lgl_entt,
                              (
                                  SELECT
                                      line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_mfap_txn_line_t  line,
                                      wsc_ahcs_int_status_t     status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = lv_batch_id
                                      AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                              )                        d_lgl_entt
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

            COMMIT;
 logging_insert('JTI MF AP', p_batch_id, 7.1, 'update transaction number with STATIC_LEDGER_NUMBER -starts', NULL,sysdate);           
             UPDATE wsc_ahcs_mfap_txn_header_t hdr
            SET
                transaction_number = transaction_number
                                     || '_'
                                     || (
                    SELECT
                        static_ledger_number
                    FROM
                        wsc_ahcs_int_mf_ledger_t l
                    WHERE
                            l.ledger_name = hdr.ledger_name
                        AND l.sub_ledger = 'MF AP'
                )
            WHERE
                hdr.ledger_name IS NOT NULL
                AND hdr.batch_id = p_batch_id
                AND EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t s
                    WHERE
                        s.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                        AND batch_id = lv_batch_id
                        AND hdr.header_id = s.header_id
                        and hdr.batch_id=s.batch_id
                );

 logging_insert('ANIXTER AP', p_batch_id, 7.2, 'update transaction number with STATIC_LEDGER_NUMBER -header table- complete',NULL, sysdate);
                          
             COMMIT;
            UPDATE wsc_ahcs_mfap_txn_line_t line
            SET
                line.transaction_number = (
                    SELECT
                        hdr.transaction_number
                    FROM
                        wsc_ahcs_mfap_txn_header_t hdr
                    WHERE
                        hdr.header_id = line.header_id and
                        hdr.batch_id=line.batch_id
                )
            WHERE
                    line.batch_id = p_batch_id
                AND EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t s
                    WHERE
                        s.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                        AND s.batch_id = lv_batch_id
                        AND line.header_id = s.header_id
                        and line.line_id=s.line_id
                        and line.batch_id=s.batch_id
                );
                commit;  
logging_insert('ANIXTER AP', p_batch_id, 21.2, 'update transaction number with STATIC_LEDGER_NUMBER -line table- complete', NULL,sysdate);

             MERGE INTO wsc_ahcs_int_status_t stauts
            USING wsc_ahcs_mfap_txn_line_t line ON ( stauts.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                                                     AND line.header_id = stauts.header_id
                                                     AND line.batch_id = stauts.batch_id
                                                     AND line.line_id = stauts.line_id
                                                     AND stauts.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET stauts.attribute3 = line.transaction_number;

            COMMIT;
logging_insert('ANIXTER AP', p_batch_id, 7.3, 'update transaction number with STATIC_LEDGER_NUMBER -status table- complete',NULL,sysdate);
logging_insert('ANIXTER AP', p_batch_id, 7.4, 'update transaction number with STATIC_LEDGER_NUMBER -ends', NULL,sysdate);                    
--call multi ledger proc
logging_insert('ANIXTER AP', p_batch_id, 8, 'call wsc_ledger_name_derivation', NULL, sysdate);
            wsc_ledger_name_derivation(lv_batch_id);
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('ANIXTER AP', p_batch_id, 212, 'Error in update ledger_name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('ANIXTER AP', p_batch_id, 9, 'Update LEDGER_NAME  in status table -start', NULL,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_mfap_txn_header_t h
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
        END;

        logging_insert('ANIXTER AP', p_batch_id, 10, 'Update LEDGER_NAME  in status table -end', NULL,
                      sysdate);
        logging_insert('ANIXTER AP', p_batch_id, 11, 'Update status table to have record-wise status', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    sts.attribute2,
                    sts.status,
                    sts.last_updated_date,
                    sts.error_msg
                FROM
                    wsc_ahcs_int_status_t       sts,
                    wsc_ahcs_mfap_txn_header_t  hdr
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

            logging_insert('JTI MF AP', p_batch_id, 12, 'Update status column in status table to have record-wise status',
                          NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'TRANSFORM_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                --AND attribute2 = 'VALIDATION_SUCCESS'
                AND error_msg IS NULL;

            COMMIT;
            logging_insert('JTI AP', p_batch_id, 13, 'Update attribute2 column in status table to have record-wise status',
                          NULL,
                          sysdate);
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

            logging_insert('JTI MF AP', p_batch_id, 14, 'Update control table status', NULL,
                          sysdate);
            OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_succ;
            CLOSE cur_count_sucss;
            logging_insert('JTI AP', p_batch_id, 14.1, 'count success', lv_count_succ,
                          sysdate);
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
            
             BEGIN --added for reprocess individual group id process 12th Dec 2022
            lv_group_id := wsc_ahcs_mf_grp_id_seq.nextval;
            
            UPDATE wsc_ahcs_int_control_t
            SET
                group_id = lv_group_id
            WHERE
                    source_application = 'MF AP'
                AND status = 'TRANSFORM_SUCCESS'
                AND group_id IS NULL
                AND batch_id = p_batch_id;

            logging_insert('JTI MF AP', p_batch_id, 15, 'Group Id update in control table ends.' || sqlerrm, NULL,
                          sysdate);
            COMMIT;
            OPEN jti_mfap_grp_data_fetch_cur(lv_group_id);
            LOOP
                FETCH jti_mfap_grp_data_fetch_cur
                BULK COLLECT INTO lv_mfap_grp_type LIMIT 50;
                EXIT WHEN lv_mfap_grp_type.count = 0;
                FORALL i IN 1..lv_mfap_grp_type.count
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
                        lv_mfap_grp_type(i).batch_id,
                        lv_mfap_grp_type(i).file_name,
                        lv_group_id,
                        lv_mfap_grp_type(i).ledger_name,
                        lv_mfap_grp_type(i).source_application,
                        lv_mfap_grp_type(i).interface_id,
                        lv_mfap_grp_type(i).status,
                        'FIN_INT',
                        sysdate,
                        'FIN_INT',
                        sysdate
                    );

            END LOOP;

            COMMIT;
            logging_insert('JTI MF AP', p_batch_id, 16, 'Control Line insertion for group id ends.' || sqlerrm, NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                group_id = lv_group_id
            WHERE
            -- batch_id IN (
                -- SELECT DISTINCT
                    -- batch_id
                -- FROM
                    -- wsc_ahcs_int_control_line_t
                -- WHERE
                    -- group_id = lv_grp_id
            -- )
                group_id IS NULL
                AND batch_id = p_batch_id
                AND attribute2 = 'TRANSFORM_SUCCESS'
                AND ( accounting_status = 'IMP_ACC_ERROR'
                      OR accounting_status IS NULL );

            COMMIT;
            logging_insert('JTI MF AP', p_batch_id, 17, 'Group id update in status table ends.' || sqlerrm, NULL,
                          sysdate);
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('JTI MF AP', p_batch_id, 17.1, 'Error in the reprocess group id block.' || sqlerrm, NULL,
                              sysdate);
        END;

      
            logging_insert('JTI MF AP', p_batch_id, 15, 'end  transformation', NULL,
                          sysdate);
            logging_insert('JTI MF AP', p_batch_id, 16, 'AHCS Dashboard refresh Start', NULL,
                          sysdate);
            wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
            logging_insert('JTI MF AP', p_batch_id, 17, 'AHCS Dashboard refresh End', NULL,
                          sysdate);
        

        logging_insert('JTI MF AP', p_batch_id, 18, 'end transformation after dashboard call', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT241'
                                                    || '_'
                                                    || 'MFAP',
                                                    'ANIXTER_AP',
                                                    sqlerrm);
    END leg_coa_transformation_jti_mfap_reprocessing;
END wsc_ahcs_mfap_validation_transformation_pkg;

/
