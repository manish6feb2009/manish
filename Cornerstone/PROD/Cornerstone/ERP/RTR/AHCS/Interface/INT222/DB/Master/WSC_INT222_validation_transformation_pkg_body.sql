create or replace PACKAGE BODY wsc_ahcs_mfinv_validation_transformation_pkg AS

    err_msg VARCHAR2(100);

    PROCEDURE data_validation (
        p_batch_id IN NUMBER
    ) IS 

    -- TODO: Implementation required for PROCEDURE WSC_AHCS_MFINV_VALIDATION_TRANSFORMATION_PKG.data_validation
        lv_header_err_msg    VARCHAR2(2000) := NULL;
        lv_line_err_msg      VARCHAR2(2000) := NULL;
        lv_header_err_flag   VARCHAR2(100) := 'false';
        lv_line_err_flag     VARCHAR2(100) := 'false';
        l_system             VARCHAR2(30);
        lv_count_sucss       NUMBER := 0;
        retcode              NUMBER;
		err_msg              VARCHAR2(2000);

		TYPE wsc_header_col_value_type IS
            VARRAY(70) OF VARCHAR2(200); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING HEADER OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
 lv_header_col_value  wsc_header_col_value_type := wsc_header_col_value_type(
                                                                              'INTERFACE_ID','BUSINESS_UNIT','INVOICE_CURRENCY','HDR_SEQ_NBR' 
																			);   --4 Columns

		TYPE wsc_line_col_value_type IS
            VARRAY(40) OF VARCHAR2(200); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING LINE OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        lv_line_col_value    wsc_line_col_value_type := wsc_line_col_value_type( 
		                                                                        'LINE_SEQ_NUMBER','AMOUNT', 'AMOUNT_IN_CUST_CURR'     
																				); --3 Columns

/************ @@@@@ INITIALIZE HEADER AND LINE FLAG TABLE TYPE VARIABLES TO MATCH THE COUNT OF HEADER AND LINE @@@@@ ************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/

        TYPE wsc_ahcs_mfinv_header_txn_t_type IS
            TABLE OF INTEGER;
        lv_error_mfinv_header wsc_ahcs_mfinv_header_txn_t_type := wsc_ahcs_mfinv_header_txn_t_type('1','1','1','1'
                                                                                               );--4 '1's

        TYPE wsc_ahcs_mfinv_line_txn_t_type IS
            TABLE OF INTEGER;
        lv_error_mfinv_line   wsc_ahcs_mfinv_line_txn_t_type := wsc_ahcs_mfinv_line_txn_t_type('1', '1', '1'
                                                                                              );  --- 3 '1's

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from HEADER STAGING TABLE THAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_header_id (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            header_id,
			interface_id,
			business_unit,
            INVOICE_CURRENCY,   
            hdr_seq_nbr

        FROM
            wsc_ahcs_mfinv_txn_header_t
        WHERE
            batch_id = cur_p_batch_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from LINE STAGING TABLE THAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_wsc_mfinv_line (
            cur_p_hdr_id VARCHAR2
        ) IS
        SELECT
		line_seq_number, 
		AMOUNT,
		AMOUNT_IN_CUST_CURR,
        line_id		
        FROM
            wsc_ahcs_mfinv_txn_line_t
        WHERE
            header_id = cur_p_hdr_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/

------------------------------------------------------------------------------------------------------------------------------------------------
--Following cursor will verify whether GL amount in local currency (debit) is equal or not to GL amount int local currency (credit) and will flag the results.
------------------------------------------------------------------------------------------------------------------------------------------------
     /*   CURSOR cur_line_validation (
            cur_p_batch_id NUMBER
        ) IS
        WITH line_cr AS (
            SELECT
                header_id,
                abs(SUM(AMOUNT)) sum_data
            FROM
                wsc_ahcs_mfinv_txn_line_t
            WHERE
                db_cr_flag = 'CR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ),line_dr AS (
            SELECT
                header_id,
                abs(SUM(AMOUNT)) sum_data
            FROM
                wsc_ahcs_mfinv_txn_line_t
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
            ( l_dr.sum_data <> l_cr.sum_data )
            AND l_dr.header_id = l_cr.header_id; */

			CURSOR cur_line_validation (
            cur_p_batch_id NUMBER
        ) IS
        WITH line_cr AS (
            SELECT
                header_id,
                abs(SUM(AMOUNT)) sum_data
            FROM
                wsc_ahcs_mfinv_txn_line_t
            WHERE
                db_cr_flag = 'CR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ),line_dr AS (
            SELECT
                header_id,
                abs(SUM(AMOUNT)) sum_data
            FROM
                wsc_ahcs_mfinv_txn_line_t
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
        lv_line_validation   line_validation_type;
------------------------------------------------------------------------------------------------------------------------------------------------  


------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will do a 3-way match per transaction between total of header , sum of debits at line & sum of credits at line
        -- and identified if there is a mismatch between these.
        -- All header IDs with such mismatches will be fetched for subsequent flagging.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        /******* @@@@@@@@ Modify this cursor to reflect the header and line tables. Also verify the column names are correct @@@@@@@ ********/

		/*CURSOR cur_invt_header_validation (
            cur_p_batch_id NUMBER
        ) IS
        WITH line_cr AS (
            SELECT
                header_id,
                abs(SUM(amount)) sum_data
            FROM
                wsc_ahcs_mfinv_txn_line_t
            WHERE
                    db_cr_flag IS NULL
			    AND gaap_f <> 'L'		
				--AND amount_type <> 'ISH' OR  amount_type <> 'ISL'
				--AND amount_type NOT IN ('ISH','ISL')
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ), line_dr AS (
            SELECT
                header_id,
                abs(SUM(amount)) sum_data
            FROM
                wsc_ahcs_mfinv_txn_line_t
            WHERE
                    db_cr_flag IS NULL
				AND gaap_f <> 'L'	
				--AND amount_type <> 'ISH' OR  amount_type <> 'ISL'
				--AND amount_type NOT IN ('ISH','ISL')
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id 
        ),
		header_amt AS (
            SELECT
                header_id,
                abs(SUM(amount)) sum_data
            FROM
                wsc_ahcs_mfinv_txn_header_t
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


		------------------------------------------------------------------------------------------------------------------------------------------------

        TYPE invt_header_validation_type IS
            TABLE OF cur_invt_header_validation%rowtype;
        lv_invt_header_validation invt_header_validation_type; */





        CURSOR cur_header_validation (
            cur_p_batch_id NUMBER
        ) IS
        WITH line_cr AS (
            SELECT
                header_id,
                abs(SUM(amount)) sum_data
            FROM
                wsc_ahcs_mfinv_txn_line_t
            WHERE
                    db_cr_flag IS NULL

                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ), line_dr AS (
            SELECT
                header_id,
                abs(SUM(amount)) sum_data
            FROM
                wsc_ahcs_mfinv_txn_line_t
            WHERE
                    db_cr_flag IS NULL

                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id 
        ),
		header_amt AS (
            SELECT
                header_id,
                abs(SUM(amount)) sum_data
            FROM
                wsc_ahcs_mfinv_txn_header_t
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


		------------------------------------------------------------------------------------------------------------------------------------------------

        TYPE header_validation_type IS
            TABLE OF cur_header_validation%rowtype;
        lv_header_validation header_validation_type;



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
    /** Declarations Ends**/

    BEGIN		
	logging_insert('MF INV', p_batch_id, 11, 'MF INV - Data Validation Started', NULL,SYSDATE);

	 /*Store Mainframe Sub System Name In  'l_system' Variable*/
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
        -- 1. Validate header fields
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
    ---------------------------------------------------------------------------------------------------------------------------------------------

     logging_insert('MF INV', p_batch_id, 12, 'MF INV - Validate Header and Line Mandatory Fileds and Data Types Started', NULL,SYSDATE);																				   
    BEGIN
		FOR header_id_f IN cur_header_id(p_batch_id) 
		LOOP
                lv_header_err_flag := 'false';
                lv_header_err_msg := NULL;
                lv_error_mfinv_header := wsc_ahcs_mfinv_header_txn_t_type('1','1','1','1');
	                             lv_error_mfinv_header(1) := is_varchar2_null(header_id_f.interface_id);
	  				             lv_error_mfinv_header(2) := is_varchar2_null(header_id_f.business_unit);
					             lv_error_mfinv_header(3) := is_varchar2_null(header_id_f.INVOICE_CURRENCY);
                                 lv_error_mfinv_header(4) := is_varchar2_null(header_id_f.hdr_seq_nbr);
                FOR i IN 1..4 
				LOOP
                    IF lv_error_mfinv_header(i) = 0 THEN
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
                            last_updated_date = SYSDATE
                        WHERE
                            batch_id = p_batch_id
                            AND status = 'NEW'
                            AND header_id = header_id_f.header_id;
                        COMMIT;

    logging_insert('MF INV', p_batch_id, 12.1, 'Mandatory Fields Validation Failed For Header' || lv_header_err_msg || '_' || header_id_f.header_id,lv_header_err_flag,SYSDATE);
                CONTINUE;               
                END IF;

     ------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2. Validate Mandatory line level fields
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

		FOR wsc_mfinv_line IN cur_wsc_mfinv_line(header_id_f.header_id) 
		LOOP
                    lv_line_err_flag := 'false';
                    lv_line_err_msg := NULL;
                    lv_error_mfinv_line := wsc_ahcs_mfinv_line_txn_t_type('1','1','1');
			        lv_error_mfinv_line(1) := is_number_null(wsc_mfinv_line.line_seq_number); 
		            lv_error_mfinv_line(2) := is_number_null(wsc_mfinv_line.AMOUNT);                
                    lv_error_mfinv_line(3) := is_number_null(wsc_mfinv_line.AMOUNT_IN_CUST_CURR);                          

				    FOR j IN 1..3 LOOP
                        IF lv_error_mfinv_line(j) = 0 THEN
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
                                last_updated_date = SYSDATE
                            WHERE
                                    batch_id = p_batch_id
                                AND status = 'NEW'
                                AND header_id = header_id_f.header_id
                                AND line_id = wsc_mfinv_line.line_id;
                            COMMIT;

        logging_insert('MF INV', p_batch_id, 12.2, 'Error in Mandatory Line Field Validation ', SQLERRM,SYSDATE);            
                        UPDATE wsc_ahcs_int_status_t
                        SET
                            attribute1 = 'L',
                            attribute2 = 'VALIDATION_FAILED',
                            last_updated_date = SYSDATE
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
    err_msg := SUBSTR(SQLERRM, 1, 200);
    logging_insert('MF INV', p_batch_id, 12.3, 'Error in Mandatory Field Validation Header/Line ', SQLERRM,SYSDATE);
	    END;
	logging_insert('MF INV', p_batch_id, 13, 'MF INV - Mandatory Fields Validation for Header and Line Completed', NULL,SYSDATE);

------------------------------------------------------------------------------------------------------------------------------------------------
        -- 3. Validate GL AMOUNT IN LOCAL_CURRENCY
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
    logging_insert('MF INV', p_batch_id, 14, 'MF INV - Amount Validation - Validate Dr/Cr Line Amount Started', NULL,SYSDATE);
	IF l_system IN ('IBIN','IRIN','SPEC') THEN  --- COQI validation removed New User Story : DP-RTR-AHCS-121-10/19/2022
    BEGIN
        OPEN cur_line_validation(p_batch_id);
            LOOP
                FETCH cur_line_validation
                    BULK COLLECT INTO lv_line_validation LIMIT 100;
                    EXIT WHEN lv_line_validation.COUNT = 0;
                    FORALL i IN 1..lv_line_validation.COUNT
                        UPDATE wsc_ahcs_int_status_t
                        SET
                            status = 'VALIDATION_FAILED',
                            error_msg = '301|Line DR/CR Amount Mismatch',
                            reextract_required = 'Y',
                            attribute1 = 'L',
                            attribute2 = 'VALIDATION_FAILED',
                            last_updated_date = SYSDATE
                        WHERE
                                batch_id = p_batch_id
                            AND status = 'NEW'
                            AND header_id = lv_line_validation(i).header_id;
                END LOOP;
                CLOSE cur_line_validation;
                COMMIT;
            EXCEPTION
            WHEN OTHERS THEN
    logging_insert('MF INV', p_batch_id, 14.1, 'Error in Line Amount Validation', SQLERRM,SYSDATE);
    dbms_output.put_line('Error with Query:  ' || SQLERRM);
            ROLLBACK;
            END; 
		END IF;
    logging_insert('MF INV', p_batch_id, 15, 'MF INV - Amount Validation - Validate Dr/Cr Line Amount Completed', NULL,SYSDATE);

	--IF l_system NOT IN ('SPEC','IRIN','DAIN','COQI') THEN

	/* IF l_system = 'INVT' THEN
            BEGIN
                OPEN cur_invt_header_validation(p_batch_id);
                LOOP
                    FETCH cur_invt_header_validation BULK COLLECT INTO lv_invt_header_validation LIMIT 100;
                    EXIT WHEN lv_invt_header_validation.count = 0;
                    FORALL i IN 1..lv_invt_header_validation.count
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
                            AND header_id = lv_invt_header_validation(i).header_id;

                END LOOP;

                CLOSE cur_invt_header_validation;
                COMMIT;
            EXCEPTION
                WHEN OTHERS THEN
                    logging_insert('MF INV', p_batch_id, 201,
                                  'exception in Header Amount mismatch with Line DR/CR Amount',
                                  sqlerrm,
                                  sysdate);
                    dbms_output.put_line('Error with Query:  ' || sqlerrm);
            END;
        END IF; */


	IF l_system IN('IFRT','OFRT','AIIB','INTR') THEN
	 BEGIN
	logging_insert('MF INV', p_batch_id, 16, 'MF INV - Amount Validation - Validate Header and Line Amount Started', NULL,SYSDATE); 
            OPEN cur_header_validation(p_batch_id);
            LOOP
                FETCH cur_header_validation
                BULK COLLECT INTO lv_header_validation LIMIT 100;
                EXIT WHEN lv_header_validation.count = 0;
                FORALL i IN 1..lv_header_validation.count
                    UPDATE wsc_ahcs_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = '302|Header Trxn Amount Mismatch With Line DR/CR Amount',
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
        logging_insert('MF INV', p_batch_id, 16.1, 'Error in Header and Line Amount Mismatch', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
       END;
	END IF;
	logging_insert('MF INV', p_batch_id, 17, 'MF INV - Validation Of Header and Line Amount Completed', NULL,SYSDATE); 

	BEGIN
    logging_insert('MF INV', p_batch_id, 18, 'MF INV - Updating Status Table with Validation Status Started', NULL,SYSDATE);
            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'VALIDATION_FAILED',
                error_msg = 'error in HDR_SEQ_NBR',
                reextract_required = 'Y',
                attribute1 = 'L',
                attribute2 = 'VALIDATION_FAILED',
                last_updated_date = SYSDATE
            WHERE
                    batch_id = p_batch_id
                AND status = 'NEW'
                AND header_id IS NULL;
            COMMIT;

            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'VALIDATION_SUCCESS',
                last_updated_date = SYSDATE
            WHERE
                    batch_id = p_batch_id
                AND status = 'NEW'
                AND error_msg IS NULL;
            COMMIT;

    logging_insert('MF INV', p_batch_id, 19, 'MF INV - Status Updated In Status Table Completed', NULL,SYSDATE);
            UPDATE wsc_ahcs_int_status_t
            SET
                attribute2 = 'VALIDATION_SUCCESS',
                last_updated_date = SYSDATE
            WHERE
                  batch_id = p_batch_id
                  AND attribute2 IS NULL;
            COMMIT;
    logging_insert('MF INV', p_batch_id, 20, 'MF INV - Attribute2 Is Updated In Status Table',NULL,SYSDATE);

			OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_sucss;
            CLOSE cur_count_sucss;
    logging_insert('MF INV', p_batch_id, 21, 'MF INV - Count Of Successful Transactions', lv_count_sucss,SYSDATE);
            IF lv_count_sucss > 0 THEN
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'VALIDATION_SUCCESS',
                    last_updated_date = SYSDATE
                WHERE
                    batch_id = p_batch_id;
                COMMIT;

                           /***Calling Transformation Package***/

    logging_insert('MF INV', p_batch_id,22,'MF INV - Call To Transformation Pkg', NULL,SYSDATE);
            BEGIN
                wsc_ahcs_mfinv_validation_transformation_pkg.leg_coa_transformation(p_batch_id);
            END;    
            ELSE
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'VALIDATION_FAILED',
                    last_updated_date = SYSDATE
                WHERE
                    batch_id = p_batch_id;
			END IF;
			COMMIT;
    logging_insert('MF INV', p_batch_id, 45, 'MF INV - Data_Validation And Transformation Completed', NULL,sysdate);
    logging_insert('MF INV', p_batch_id, 125, 'MF INV - AHCS Dashboard refresh Start', NULL,sysdate);
            wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
    logging_insert('MF INV', p_batch_id, 126, 'MF INV - AHCS Dashboard refresh End', NULL,sysdate);


	END;

	 DELETE from WSC_AHCS_MFINV_TXN_TMP_T where batch_id = p_batch_id   ;  
     logging_insert('MF INV', p_batch_id, 127, 'MF INV - Deleted data from WSC_AHCS_MFINV_TXN_TMP_T for the batch_id', NULL,sysdate);

    END DATA_VALIDATION;
    /**** ENDS DATA VALIDATION PROCEDURE***/

	/**** STARTS TRANSFORMATION PROCEDURE**/
	PROCEDURE leg_coa_transformation (
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

    l_system    VARCHAR2(30);

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
            wsc_ahcs_mfinv_txn_line_t  line,
            wsc_ahcs_int_status_t   status
        WHERE
                line.batch_id = p_batch_id
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
            AND status.batch_id = line.batch_id
            AND status.header_id = line.header_id
            AND status.line_id = line.line_id
            AND status.attribute2 = 'VALIDATION_SUCCESS'; /*ATTRIBUTE2 */

		lv_batch_id   NUMBER := p_batch_id; 

		TYPE update_trxn_line_err_type IS
            TABLE OF cur_update_trxn_line_err%rowtype;
        lv_update_trxn_line_err       update_trxn_line_err_type;


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
                UPPER(coa_map.source_system) = UPPER(ahcs_control.source_system)
            AND UPPER(coa_map.target_system) = UPPER(ahcs_control.target_system)
            AND ahcs_control.batch_id = p_batch_id;


	-------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
        -- for the current batch ID
    -------------------------------------------------------------------------------------------------------------------------------------------

        ---lv_target_coa             VARCHAR2(1000);

	CURSOR cur_leg_seg_value IS     ---- NEWLY ADDED FOR INVT SYSTEM
        SELECT DISTINCT
            line.leg_coa,
            line.leg_bu,
            line.leg_acct,
            line.leg_dept,
            line.leg_loc,
            line.leg_vendor,
            nvl(line.leg_affiliate, '00000') leg_affiliate
        FROM
            wsc_ahcs_mfinv_txn_line_t line
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
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND status.attribute2 = 'VALIDATION_SUCCESS'
            );

        lv_target_coa             VARCHAR2(1000);


    CURSOR cur_inserting_ccid_table IS
        SELECT DISTINCT
            line.leg_coa    leg_coa,
            line.target_coa target_coa,
            line.LEG_BU,
            line.LEG_ACCT,                     
            line.LEG_DEPT,
            line.LEG_LOC,
            line.LEG_VENDOR,           
            line.LEG_AFFILIATE
        FROM
            wsc_ahcs_mfinv_txn_line_t line
        WHERE
            line.batch_id = p_batch_id 
            AND line.attribute1 = 'Y'
            AND SUBSTR(line.target_coa, 1, INSTR(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */

		TYPE inserting_ccid_table_type IS
            TABLE OF cur_inserting_ccid_table%ROWTYPE;
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
                        wsc_ahcs_mfinv_txn_line_t line,
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
        lv_get_ledger       get_ledger_type;

		CURSOR cur_count_sucss (
            cur_p_batch_id NUMBER
        ) IS
        SELECT COUNT(1)
        FROM
            wsc_ahcs_int_status_t
        WHERE
            batch_id = cur_p_batch_id
            AND attribute2 = 'TRANSFORM_SUCCESS';


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

    /*** Variables Declaration***/
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
	--1. Identify the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('MF INV', p_batch_id, 23, 'MF INV - COA Transformation Started', NULL,SYSDATE);
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_mapid,
            lv_tgt_system,
            lv_src_system;
        CLOSE cur_coa_map_id;

   --logging_insert('MF INV', p_batch_id, 24, 'MF INV - Identify The COA Map', lv_coa_mapid|| lv_tgt_system|| lv_src_system,SYSDATE);
   logging_insert('MF INV', p_batch_id, 24, 'MF INV - Identify The COA Map', lv_coa_mapid,SYSDATE);

	/* update target_coa in inv_line table where source_segment is already present in ccid table*/
        -------------------------------------------------------------------------------------------------------------------------------------------
	--2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('MF INV', p_batch_id, 25, 'MF INV - Check Data In Cache Table To Find ', NULL,SYSDATE);
    BEGIN
        IF lv_src_system = 'ANIXTER' THEN
            UPDATE wsc_ahcs_mfinv_txn_line_t line
            SET
                target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa, lv_coa_mapid),
                last_update_date = SYSDATE
            WHERE
                batch_id = p_batch_id;
        ELSE 
            UPDATE wsc_ahcs_mfinv_txn_line_t line
            SET
                target_coa = wsc_gl_coa_mapping_pkg.ccid_match(
                    LEG_BU||'.....'||NVL(LEG_AFFILIATE,'00000'), lv_coa_mapid
                )
            WHERE
                batch_id = p_batch_id;
        END IF;
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
    logging_insert('MF INV', p_batch_id, 25.1, 'Error in Check Data In Cache Table To Find', SQLERRM,SYSDATE);
    dbms_output.put_line('Error with Query:  ' || SQLERRM);
    END;

	/*update target_coa and attribute1 'Y' in inv_line table where distinct leg_coa and target_coa is null*/     
    -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
    -------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('MF INV', p_batch_id, 26, 'MF INV - Update Target_Coa And Attribute1', NULL,SYSDATE);
    BEGIN
	     -- IF ( l_system = 'INVT' ) THEN    
              --  logging_insert('MF INV', p_batch_id, 26.1, 'inside INVT', NULL,
                     --         sysdate);
--        open cur_leg_seg_value;
                FOR lv_leg_seg_value IN cur_leg_seg_value LOOP
                    lv_target_coa := replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, lv_leg_seg_value.leg_bu,
                    lv_leg_seg_value.leg_loc, lv_leg_seg_value.leg_dept,
                                                                               lv_leg_seg_value.leg_acct, lv_leg_seg_value.leg_vendor,
                                                                               nvl(lv_leg_seg_value.leg_affiliate, '00000'), NULL, NULL,
                                                                               NULL, NULL), ' ', '');

                    UPDATE wsc_ahcs_mfinv_txn_line_t line
                    SET
                        target_coa = lv_target_coa,
                        attribute1 = 'Y'
                    WHERE
                            leg_coa = lv_leg_seg_value.leg_coa
                        AND batch_id = p_batch_id
                        AND target_coa IS NULL;

                END LOOP;     ---- NEWLY ADDED CODE
	    /* ELSE

        UPDATE wsc_ahcs_mfinv_txn_line_t tgt_coa
        SET
            target_coa = replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, tgt_coa.LEG_BU, tgt_coa.LEG_LOC,
            tgt_coa.LEG_DEPT, tgt_coa.LEG_ACCT, tgt_coa.LEG_VENDOR, NVL(tgt_coa.LEG_AFFILIATE, '00000'), NULL, NULL, NULL, NULL),' ',''),  
            attribute1 = 'Y'
            WHERE
                batch_id = p_batch_id
                AND target_coa IS NULL
                AND EXISTS (
                    SELECT /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */
                       -- 1
                   /* FROM
                        wsc_ahcs_int_status_t status
                    WHERE
                            status.batch_id = p_batch_id
                        AND status.batch_id = tgt_coa.batch_id
                        AND status.header_id = tgt_coa.header_id
                        AND status.line_id = tgt_coa.line_id
                        AND status.attribute2 = 'VALIDATION_SUCCESS'
                );
			END IF; */
            COMMIT;
        EXCEPTION
        WHEN OTHERS THEN 
    logging_insert('MF INV', p_batch_id, 26.2, 'MF INV - Error in Update Target_Coa And Attribute1', SQLERRM,SYSDATE);
    dbms_output.put_line('Error with Query:  ' || SQLERRM);
    END;

	/*insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use*/
    -------------------------------------------------------------------------------------------------------------------------------------------
    -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
    -------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('MF INV',p_batch_id,27,'MF INV - Insert New Target_Coa Values',NULL,SYSDATE);
    BEGIN
        IF lv_src_system = 'ANIXTER' THEN
            OPEN cur_inserting_ccid_table;
            LOOP
                FETCH cur_inserting_ccid_table
                BULK COLLECT INTO lv_inserting_ccid_table LIMIT 100;
                EXIT WHEN lv_inserting_ccid_table.COUNT = 0;
                FORALL i IN 1..lv_inserting_ccid_table.COUNT
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
                        SYSDATE,
                        SYSDATE,
                        'Y',
                        'N',
                        'ANIXTER INV',
                        'ANIXTER INV',
                        lv_inserting_ccid_table(i).LEG_BU,
                        lv_inserting_ccid_table(i).LEG_LOC,
                        lv_inserting_ccid_table(i).LEG_DEPT,
                        lv_inserting_ccid_table(i).LEG_ACCT,
                        lv_inserting_ccid_table(i).LEG_VENDOR,
                        NVL(lv_inserting_ccid_table(i).LEG_AFFILIATE, '00000'),
                        NULL,
                        NULL,
                        NULL,
                        NULL
                    );
            END LOOP;
            CLOSE cur_inserting_ccid_table;
        ELSE
            OPEN cur_inserting_ccid_table;
            LOOP
                FETCH cur_inserting_ccid_table
                BULK COLLECT INTO lv_inserting_ccid_table LIMIT 100;
                EXIT WHEN lv_inserting_ccid_table.COUNT = 0;
                FORALL i IN 1..lv_inserting_ccid_table.COUNT
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
                        lv_inserting_ccid_table(i).LEG_BU||'.....'||NVL(lv_inserting_ccid_table(i).LEG_AFFILIATE, '00000'),
                        lv_inserting_ccid_table(i).target_coa,
                        SYSDATE,
                        SYSDATE,
                        'Y',
                        'N',
                        'ANIXTER INV',
                        'ANIXTER INV',
                        lv_inserting_ccid_table(i).LEG_BU,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NVL(lv_inserting_ccid_table(i).LEG_AFFILIATE, '00000'),
                        NULL,
                        NULL,
                        NULL,
                        NULL
                    );
            END LOOP;
            CLOSE cur_inserting_ccid_table;
        END IF;         
        COMMIT;
        EXCEPTION
        WHEN OTHERS THEN
    logging_insert('MF INV', p_batch_id, 27.1, 'Error In CCID Insert', SQLERRM, SYSDATE);
	END;

	UPDATE wsc_ahcs_mfinv_txn_line_t
        SET
            attribute1 = NULL
        WHERE
            batch_id = p_batch_id;
    COMMIT;


	/*update inv_line table target segments,  where legal_entity must have their in target_coa*/
    -------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
    -------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('MF INV', p_batch_id, 28, 'MF INV - Update Line Table Target Segments', NULL,SYSDATE);    	

		  BEGIN
            UPDATE wsc_ahcs_mfinv_txn_line_t line
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
    dbms_output.put_line('Error with Query:  ' || SQLERRM);
    logging_insert('MF INV', p_batch_id, 28.1, 'Error in Update inv_line Table Target Segments', SQLERRM,SYSDATE);
    END;

/*if any target_coa is empty in inv_line table will mark it as transform_error in status table*/-------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
-------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('MF INV', p_batch_id, 29, 'MF INV - If Any Target_Coa Is Empty', NULL,SYSDATE);

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
                    wsc_ahcs_mfinv_txn_line_t line
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
                last_updated_date = SYSDATE;
            COMMIT;
    logging_insert('MF INV', p_batch_id, 30, 'MF INV - Updated Attribute2 with TRANSFORM_FAILED Status', NULL,SYSDATE);

            FOR rcur_to_update_status IN cur_to_update_status(p_batch_id) 
			LOOP
                UPDATE wsc_ahcs_int_status_t
                SET
                    attribute2 = 'TRANSFORM_FAILED',
                    last_updated_date = SYSDATE
                WHERE
                        batch_id = rcur_to_update_status.batch_id
                    AND header_id = rcur_to_update_status.header_id;
            END LOOP;  
            COMMIT;
        EXCEPTION
        WHEN OTHERS THEN
    logging_insert('MF INV', p_batch_id, 30.1, 'Error If Any Target_Coa Is Empty', SQLERRM,SYSDATE);
    dbms_output.put_line('Error with Query:  ' || SQLERRM);
    END;

    /*update ledger_name in inv_header table where transform_success*/
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('MF INV', p_batch_id, 31, 'MF INV - Update Ledger_Name', NULL,SYSDATE);

	BEGIN
            MERGE INTO wsc_ahcs_mfinv_txn_header_t hdr
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
                                      wsc_ahcs_mfinv_txn_line_t line,
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
logging_insert('MF INV', p_batch_id, 31.1, 'MF INV - Update Transaction Number with Static_Ledger_Number Started',  NULL,sysdate);
MERGE INTO wsc_ahcs_mfinv_txn_header_t hdr
USING wsc_ahcs_int_mf_ledger_t l ON ( l.ledger_name = hdr.ledger_name
                                      AND l.sub_ledger = 'MF INV'
                                      AND hdr.ledger_name IS NOT NULL
                                      AND hdr.batch_id = p_batch_id )
WHEN MATCHED THEN UPDATE
SET transaction_number = transaction_number
                         || '_'
                         || l.static_ledger_number;

COMMIT;
logging_insert('MF INV', p_batch_id, 31.2, 'MF INV - Update Transaction Number with Static_Ledger_Number Header Table Completed',  NULL,sysdate);
MERGE INTO wsc_ahcs_mfinv_txn_line_t line
USING wsc_ahcs_mfinv_txn_header_t hdr ON ( line.header_id = hdr.header_id
                                          AND line.batch_id = hdr.batch_id
                                           AND hdr.ledger_name IS NOT NULL
                                          AND hdr.batch_id = p_batch_id )
WHEN MATCHED THEN UPDATE
SET line.transaction_number = hdr.transaction_number;
commit;
logging_insert('MF INV', p_batch_id, 31.3, 'MF INV - Update Transaction Number with Static_Ledger_Number Line Table Completed',  NULL,sysdate);
MERGE INTO wsc_ahcs_int_status_t status
            USING wsc_ahcs_mfinv_txn_line_t line ON ( line.header_id = status.header_id
                                                     AND line.batch_id = status.batch_id
                                                     AND line.line_id = status.line_id
                                                     AND status.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET status.attribute3 = line.transaction_number;

            COMMIT;
logging_insert('MF INV', p_batch_id, 31.4,
                          'MF INV - Update Transaction Number with Static_Ledger_Number Status Table Completed',
                          NULL,
                          sysdate);
logging_insert('MF INV', p_batch_id, 31.5, 'MF INV - Update Transaction Number with Static_Ledger_Number Completed',  NULL,sysdate);

	          /*****Calling Multi Ledger Proc*******/
 logging_insert('MF INV', p_batch_id, 31.6, 'MF INV - Call to wsc_ledger_name_derivation prc', NULL,sysdate);

            wsc_ahcs_mfinv_validation_transformation_pkg.wsc_ledger_name_derivation(lv_batch_id);
            COMMIT;	
				

   /* logging_insert('ANIXTER INV', p_batch_id, 30, 'After IS NOT NULL', NULL,SYSDATE);
            MERGE INTO wsc_ahcs_mfinv_txn_header_t hdr
            USING (
                      WITH main_data AS (
                      SELECT 
                              lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t lgl_entt,
                              (
--                                  SELECT 
                                   SELECT
                                      line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_mfinv_txn_line_t line,
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
            COMMIT; */
        EXCEPTION
        WHEN OTHERS THEN
    logging_insert('MF INV', p_batch_id, 39.1, 'Error in Update Ledger_Name', SQLERRM,SYSDATE);
    dbms_output.put_line('Error with Query:  ' || SQLERRM);
    END;

	 logging_insert('MF INV', p_batch_id, 40, 'MF INV - Update Ledger_Name In Status Table Started', NULL,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_mfinv_txn_header_t h
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

        logging_insert('MF INV', p_batch_id, 41, 'MF INV - Update Ledger_Name In Status Table Completed', NULL,
                      sysdate);

		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7.1. Update status tables after validation where line cr/dr mismatch.
        --    /******* ALL RECORDS MARKED AS VALIDATION FAILED WHEN LINE CR/DR AMOUNT MISMATCH AFTER VALIDATION ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF INV', p_batch_id, 42, 'MF INV - Update Status Tables After Validation', NULL,sysdate);
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
                logging_insert('ANIXTER INV',p_batch_id,23,'Update status tables after validation',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end; */


-------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
-------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('MF INV', p_batch_id, 43, 'MF INV - Update Status Tables To have Status', NULL,SYSDATE);
     BEGIN
            UPDATE (
                SELECT
                    sts.attribute2,
                    sts.status,
                    sts.last_updated_date,
                    sts.error_msg
                FROM
                    wsc_ahcs_int_status_t     sts,
                    wsc_ahcs_mfinv_txn_header_t  hdr
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
		
		IF l_system in ('AIIB','INTR','INVT') THEN
		 logging_insert('MF INV', p_batch_id, 42.1, 'MF INV - Call to wsc_ahcs_mfinv_invt_line_copy_p Started', NULL,sysdate);		
			wsc_ahcs_mfinv_validation_transformation_pkg.wsc_ahcs_mfinv_invt_line_copy_p(lv_batch_id);
			COMMIT;
	     logging_insert('MF INV', p_batch_id, 42.7, 'MF INV - Call wsc_ahcs_mfinv_invt_line_copy_p Completed', NULL,sysdate); 
		END IF;

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
                    last_updated_date = SYSDATE
                WHERE
                    batch_id = p_batch_id;
            ELSE
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'TRANSFORM_FAILED',
                    last_updated_date = SYSDATE
                WHERE
                    batch_id = p_batch_id;
            END IF;
            COMMIT;
			
        END;
		
    logging_insert('MF INV', p_batch_id, 44, 'MF INV - COA Transformation Completed', NULL,SYSDATE);
    EXCEPTION
    WHEN OTHERS THEN
        wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT222'|| '_'|| l_system, 'MF_INV', SQLERRM);
		
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

        l_system                  VARCHAR2(30);
		lv_batch_id               NUMBER := p_batch_id; 
        lv_group_id               NUMBER; --added for reprocess individual group id process 24th Nov 2022
		lv_job_count              NUMBER := NULL;
        lv_file_name              VARCHAR2(50);

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
            wsc_ahcs_mfinv_txn_line_t  line,
            wsc_ahcs_int_status_t     status
        WHERE
                line.batch_id = p_batch_id
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
            AND status.batch_id = line.batch_id
            AND status.header_id = line.header_id
            AND status.line_id = line.line_id
            AND status.attribute2 = 'VALIDATION_SUCCESS'; /*ATTRIBUTE2 */

        --lv_batch_id                NUMBER := p_batch_id;
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
                    wsc_ahcs_mfinv_txn_line_t    line,
                    wsc_ahcs_int_status_t     status,
                    wsc_ahcs_mfinv_txn_header_t  header
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
            wsc_ahcs_mfinv_txn_line_t line
        WHERE
                line.batch_id = p_batch_id 
--			   and line.batch_id = header.batch_id
--			   and line.header_id = header.header_id
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        /*
		cursor cur_inserting_ccid_table is
			select distinct LEG_COA, TARGET_COA from WSC_AHCS_MFINV_TXN_LINE_T
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
                        wsc_ahcs_mfinv_txn_line_t  line,
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
                wsc_ahcs_mfinv_txn_line_t
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
                wsc_ahcs_mfinv_txn_line_t
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

		CURSOR mfinv_grp_data_fetch_cur ( --added for reprocess individual group id process 24th Nov 2022
            p_grp_id NUMBER
        ) IS
		---7th may 2023, changing the below query because of the Prod issue during ramp up #INC2618056
       /* SELECT DISTINCT
            c.batch_id           batch_id,
            c.file_name          file_name,
            a.ledger_name        ledger_name,
            c.source_application source_application,
            a.interface_id       interface_id,
            c.status             status
        FROM
            wsc_ahcs_int_control_t     c,
            wsc_ahcs_mfinv_txn_header_t a
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
            AND c.group_id = p_grp_id; */
      
	  SELECT /*+ index(a WSC_AHCS_MFINV_TXN_HEADER_T_PK) */
DISTINCT
        c.batch_id           batch_id,
        c.file_name          file_name,
        a.ledger_name        ledger_name,
        c.source_application source_application,
        a.interface_id       interface_id,
        c.status             status
    FROM
        wsc_ahcs_int_control_t     c,
        wsc_ahcs_mfinv_txn_header_t a,
        wsc_ahcs_int_status_t s
    WHERE
            a.batch_id = c.batch_id
        AND a.ledger_name IS NOT NULL
        AND c.status = 'TRANSFORM_SUCCESS'
        and c.batch_id = s.batch_id
                    and s.batch_id = a.batch_id
                    AND s.header_id = a.header_id
                    AND s.attribute2 = 'TRANSFORM_SUCCESS'
                    AND ( s.accounting_status = 'IMP_ACC_ERROR'
                          OR s.accounting_status IS NULL )
                             AND c.group_id = p_grp_id; 



        TYPE mfinv_grp_type IS
            TABLE OF mfinv_grp_data_fetch_cur%rowtype;
        lv_mfinv_grp_type          mfinv_grp_type;

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
				
			SELECT
                file_name
            INTO lv_file_name
            FROM
                wsc_ahcs_int_control_t c
            WHERE
                c.batch_id = p_batch_id;

            dbms_output.put_line(l_system);
        END;
		
			
		
        -------------------------------------------------------------------------------------------------------------------------------------------
	--1. Identify the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF INV', p_batch_id, 50, 'MF INV - Transformation start for Reprocessing', NULL,
                      sysdate);
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_mapid,
            lv_tgt_system,
            lv_src_system;
        CLOSE cur_coa_map_id;
        logging_insert('MF INV', p_batch_id, 51, 'MF INV - Transformation start for Reprocessing',
                      lv_coa_mapid
                      || lv_tgt_system
                      || lv_src_system,
                      sysdate);

--        update target_coa in inv_line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
	--2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN
            UPDATE wsc_ahcs_mfinv_txn_line_t line
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

				UPDATE wsc_ahcs_mfinv_txn_header_t hdr --- added 12/1/2023
            SET
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
                       -- AND status.line_id = line.line_id
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

        logging_insert('MF INV', p_batch_id, 52, 'MF INV - Check data in cache table to find for Reprocessing', NULL,
                      sysdate);
        BEGIN
            IF lv_src_system = 'ANIXTER' THEN
                UPDATE wsc_ahcs_mfinv_txn_line_t line
                SET
                    target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa, lv_coa_mapid),
                    last_update_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            ELSE
                UPDATE wsc_ahcs_mfinv_txn_line_t line
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
                logging_insert('MF INV', p_batch_id, 52.1, 'Error in Check data in cache table to find for Reprocessing', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

--        update target_coa and attribute1 'Y' in inv_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF INV', p_batch_id, 53, 'MF INV - Update target_coa and attribute1 for Reprocessing', NULL,
                      sysdate);
        BEGIN
--            
            UPDATE wsc_ahcs_mfinv_txn_line_t tgt_coa
            SET
                target_coa = replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, tgt_coa.leg_bu, tgt_coa.leg_loc,
                tgt_coa.leg_dept, tgt_coa.leg_acct, tgt_coa.leg_vendor, nvl(tgt_coa.leg_affiliate,'00000'),
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
                logging_insert('MF INV', p_batch_id, 53.1, 'Error in update target_coa and attribute1 for Reprocessing', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;


--        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF INV', p_batch_id, 54, 'insert new target_coa values', NULL,
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
                            'ANIXTER INV',
                            'ANIXTER INV',
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
                            'ANIXTER INV',
                            'ANIXTER INV',
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
                 END LOOP;
                CLOSE cur_inserting_ccid_table;
            END IF;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('MF INV', p_batch_id, 54.1, 'error in ccid insert for Reprocessing', sqlerrm,
                              sysdate);
        END;

        UPDATE wsc_ahcs_mfinv_txn_line_t
        SET
            attribute1 = NULL
        WHERE
            batch_id = p_batch_id;

        COMMIT;


--      update mfinv_line table target segments,  where legal_entity must have their in target_coa
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF INV', p_batch_id, 55, 'MF INV - Update mfinv_line table target segments for Reprocessing', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_mfinv_txn_line_t line
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
                logging_insert('MF INV', p_batch_id, 55.1, 'Error in update mfinv_line table target segments for Reprocessing', sqlerrm,
                              sysdate);
        END;

--        if any target_coa is empty in inv_line table will mark it as transform_error in status table
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF INV', p_batch_id, 56, 'MF INV - If any target_coa is empty for Reprocessing', NULL,
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
                    wsc_ahcs_mfinv_txn_line_t  line
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
            logging_insert('MF INV', p_batch_id, 56.1, 'MF INV - updated attribute2 with TRANSFORM_FAILED status for Reprocessing', NULL,
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
                logging_insert('MF INV', p_batch_id, 56.2, 'Error in if any target_coa is empty for Reprocessing', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

--      update ledger_name in mfinv_header table where transform_success		
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF INV', p_batch_id, 57, 'update ledger_name', NULL,
                      sysdate);
        BEGIN

            MERGE INTO wsc_ahcs_mfinv_txn_header_t hdr
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
                                      wsc_ahcs_mfinv_txn_line_t  line,
                                      wsc_ahcs_int_status_t     status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = lv_batch_id
                                      AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
									  AND NOT EXISTS ( --- Added on Jan-18-2023
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
    logging_insert('MF INV', p_batch_id, 57.1, 'MF INV - update transaction number with STATIC_LEDGER_NUMBER Started for Reprocessing', NULL,
                          sysdate);           
             UPDATE wsc_ahcs_mfinv_txn_header_t hdr
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
                        AND l.sub_ledger = 'MF INV'
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

            logging_insert('MF INV', p_batch_id, 58, 'MF INV - Update transaction number with STATIC_LEDGER_NUMBER -header table Completed for Reprocessing',
            NULL,
                          sysdate);

             COMMIT;
            UPDATE wsc_ahcs_mfinv_txn_line_t line
            SET
                line.transaction_number = (
                    SELECT
                        hdr.transaction_number
                    FROM
                        wsc_ahcs_mfinv_txn_header_t hdr
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
                logging_insert('MF INV', p_batch_id, 59, 'MF INV - Update Transaction Number with Static_Ledger_Number Line Table- Completed for Reprocessing',
            NULL,
                          sysdate);
             MERGE INTO wsc_ahcs_int_status_t stauts
            USING wsc_ahcs_mfinv_txn_line_t line ON ( stauts.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                                                     AND line.header_id = stauts.header_id
                                                     AND line.batch_id = stauts.batch_id
                                                     AND line.line_id = stauts.line_id
                                                     AND stauts.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET stauts.attribute3 = line.transaction_number;

            COMMIT;
            logging_insert('MF INV', p_batch_id, 60, 'MF INV - Update Transaction Number with Static_Ledger_Number Line Table- Completed for Reprocessing',
            NULL,
                          sysdate);
            logging_insert('MF INV', p_batch_id, 61, 'MF INV - Update Transaction Number with Static_Ledger_Number Completed for Reprocessing', NULL,
                          sysdate);                
--call multi ledger derivation proc
 logging_insert('MF INV', p_batch_id, 62, 'MF INV - Call to wsc_ledger_name_derivation prc for Reprocessing',  NULL,
                      sysdate);
            wsc_ledger_name_derivation(lv_batch_id);
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('MF INV', p_batch_id, 62.1, 'Error in update ledger_name for Reprocessing', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('MF INV', p_batch_id, 63, 'MF INV - Update LEDGER_NAME  in status table Started for Reprocessing', NULL,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_mfinv_txn_header_t h
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

        logging_insert('MF INV', p_batch_id, 64, 'MF INV - Update LEDGER_NAME  in status table Completed for Reprocessing', NULL,
                      sysdate);

		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7.1. Update status tables after validation where line cr/dr mismatch.
        --    /******* ALL RECORDS MARKED AS VALIDATION FAILED WHEN LINE CR/DR AMOUNT MISMATCH AFTER VALIDATION ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF INV', p_batch_id, 21, 'MF INV - Update status tables after validation for Reprocessing', NULL,
                      sysdate);

		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF INV', p_batch_id, 65, 'MF INV - Update status tables to have status for Reprocessing', NULL,
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
                    wsc_ahcs_mfinv_txn_header_t  hdr
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
			
		SELECT
                COUNT(1)
            INTO lv_job_count
            FROM
                sys.dba_scheduler_running_jobs
            WHERE
                job_name LIKE 'MFINV_REPROCESSING_'
                              || lv_file_name
                              || '%';
	
		 IF l_system in ('AIIB','INTR','INVT') AND lv_job_count >= 1 THEN
		 logging_insert('MF INV', p_batch_id, 66, 'MF INV - Call wsc_ahcs_mfinv_invt_line_copy_p Started for Reprocessing', NULL,sysdate);		
			wsc_ahcs_mfinv_validation_transformation_pkg.wsc_ahcs_mfinv_invt_line_copy_p(lv_batch_id);
			COMMIT;
	     logging_insert('MF INV', p_batch_id, 67, 'MF INV - Call wsc_ahcs_mfinv_invt_line_copy_p Completed for Reprocessing', NULL,sysdate);
         END IF;
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
                    group_id = null,
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
                    source_application = 'MF INV'
                AND status = 'TRANSFORM_SUCCESS'
                AND group_id IS NULL
                AND batch_id = p_batch_id;

            logging_insert('MF INV', p_batch_id, 68, 'MF INV - Group Id update in control table ends for Reprocessing' || sqlerrm, NULL,
                          sysdate);
            COMMIT;
            OPEN mfinv_grp_data_fetch_cur(lv_group_id);
            LOOP
                FETCH mfinv_grp_data_fetch_cur
                BULK COLLECT INTO lv_mfinv_grp_type LIMIT 50;
                EXIT WHEN lv_mfinv_grp_type.count = 0;
                FORALL i IN 1..lv_mfinv_grp_type.count
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
                        lv_mfinv_grp_type(i).batch_id,
                        lv_mfinv_grp_type(i).file_name,
                        lv_group_id,
                        lv_mfinv_grp_type(i).ledger_name,
                        lv_mfinv_grp_type(i).source_application,
                        lv_mfinv_grp_type(i).interface_id,
                        lv_mfinv_grp_type(i).status,
                        'FIN_INT',
                        sysdate,
                        'FIN_INT',
                        sysdate
                    );

            END LOOP;

            COMMIT;
            logging_insert('MF INV', p_batch_id, 69, 'MF INV - Control Line insertion for group id Completed for Reprocessing.' || sqlerrm, NULL,
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
            logging_insert('MF INV', p_batch_id, 70, 'MF INV - Group id update in status table Completed for Reprocessing.' || sqlerrm, NULL,
                          sysdate);
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('MF INV', p_batch_id, 70.1, 'Error in the reprocess group id block for Reprocessing.' || sqlerrm, NULL,
                              sysdate);
        END;


        logging_insert('MF INV', p_batch_id, 71, 'MF INV -Dashboard Start for Reprocessing', NULL,
                      sysdate);
        wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
        logging_insert('MF INV', p_batch_id, 72, 'MF INV - Dashboard End for Reprocessing', NULL,
                      sysdate);
        logging_insert('MF INV', p_batch_id, 73, 'MF INV - Transformation Completed for reprocessing', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT222'
                                                    || '_'
                                                    || l_system,
                                                    'MF_INV',
                                                    sqlerrm);
    END leg_coa_transformation_reprocessing;


	 PROCEDURE wsc_ledger_name_derivation (
        p_batch_id IN NUMBER
    ) IS

        lv_batch_id NUMBER := p_batch_id;

/*
        CURSOR cur_error_header IS
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
                    wsc_ahcs_mfinv_txn_line_t
                WHERE
                    attribute5 IS NOT NULL
                    AND batch_id = lv_batch_id
					--and exists (select 1 from wsc_ahcs_int_status_t s where s.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' ) AND BATCH_ID =lv_batch_id AND line.line_id = s.line_id ) --- ADDED NEW
                GROUP BY
                    header_id,
                    attribute5
            )                           line,
            wsc_ahcs_mfinv_txn_header_t  hdr
        WHERE
                line.header_id = hdr.header_id
            AND hdr.batch_id = lv_batch_id
        ORDER BY
            hdr.header_id;
            */
    CURSOR cur_error_header IS
    WITH ln AS (
        SELECT /*+ MATERIALIZE*/
            line.header_id              header_id,
            line.attribute5             attribute5,
            led.static_ledger_number    static_ledger_num,
            line.transaction_number     transaction_num
        FROM
            wsc_ahcs_mfinv_txn_line_t  line,
            wsc_ahcs_int_mf_ledger_t   led
        WHERE
                line.attribute5 = led.ledger_name
            AND led.sub_ledger = 'MF INV'
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
        ln                           l,
        wsc_ahcs_mfinv_txn_header_t  hdr
--            
    WHERE
            l.header_id = hdr.header_id
        AND hdr.batch_id = lv_batch_id;

    BEGIN
        logging_insert('MF INV', p_batch_id, 32, 'MF INV - Inside wsc_ledger_name_derivation Procedure', NULL,
                      sysdate);

        logging_insert('MF INV', p_batch_id, 33, 'MF INV - Update Attr5 In Line Table Started', NULL,
                      sysdate);             
        UPDATE wsc_ahcs_mfinv_txn_line_t line
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
                    wsc_ahcs_mfinv_txn_header_t
                WHERE
                        batch_id = lv_batch_id
                    AND ledger_name IS NULL
          ) 
--    and header_id = lv_header_id;
 AND NOT EXISTS (                ---- added 1/12/2023
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

    logging_insert('MF INV', p_batch_id, 34, 'MF INV - Update Attr5 In Line Table Completed', NULL,sysdate);

    logging_insert('MF INV', p_batch_id, 35, 'MF INV -Insert New Header Id In Header Table Started', NULL,sysdate);             
        FOR i IN cur_error_header LOOP
            INSERT INTO wsc_ahcs_mfinv_txn_header_t (
           BATCH_ID,  ---1  
		   HEADER_ID,  ---2
		   AMOUNT, ---3
		   AMOUNT_IN_CUST_CURR, ---4
		   FX_RATE_ON_INVOICE, ---5
		   TAX_INVC_I, ---6
		   GAAP_AMOUNT, ---7  
		   GAAP_AMOUNT_IN_CUST_CURR, ---8 
		   CASH_FX_RATE, ---9
		   UOM_CONV_FACTOR, ---10 
		   NET_TOTAL, ---11
		   LOC_INV_NET_TOTAL, ---12
		   INVOICE_TOTAL, ---13
		   LOCAL_INV_TOTAL, ---14
		   FX_RATE, ---15
		   CHECK_AMOUNT, ---16
		   ACCRUED_QTY, ---17
		   FISCAL_WEEK_NBR, ---18
		   TOT_LOCAL_AMT, ---19
		   TOT_FOREIGN_AMT, ---20
		   FREIGHT_FACTOR, ---21
		   INVOICE_DATE, ---22
		   INVOICE_DUE_DATE, ---23
		   FREIGHT_INVOICE_DATE, ---24
		   CASH_DATE, ---25
		   CASH_ENTRY_DATE, ---26
		   ACCOUNT_DATE, ---27  
		   BANK_DEPOSIT_DATE, ---28
		   MATCHING_DATE, ---29
		   ADJUSTMENT_DATE, ---30 
		   ACCOUNTING_DATE, ---31 
		   CHECK_DATE, ---32
		   BATCH_DATE, ---33
		   DUE_DATE, ---34
		   VOID_DATE, ---35
		   DOCUMENT_DATE, ---36 
		   RECEIVER_CREATE_DATE, ---37
		   TRANSACTION_DATE, ----38 
		   CONTINENT, ---39  
		   CONT_C, ---40 
		   PO_TYPE, ---41 
		   CHECK_PAYMENT_TYPE, ---42
		   VOID_CODE, ---43
		   CROSS_BORDER_FLAG, ---44
		   BATCH_POSTED_FLAG, ---45
		   INTERFACE_ID, ---46 
		   LOCATION, ---47   
		   INVOICE_TYPE, ---48 
		   CUSTOMER_TYPE, ---49
		   INVOICE_LOC_ISO_CNTRY, ---50
		   INVOICE_LOC_DIV, ---51
		   SHIP_TO_NBR, ---52
		   INVOICE_CURRENCY, ---53 
		   CUSTOMER_CURRENCY, ---54
		   SHIP_TYPE, ---55
		   EXPORT_TYPE, ---56
		   RECORD_ERROR_CODE, ---57
		   CREDIT_TYPE, ---58
		   NON_RA_CREDIT_TYPE, ---59
		   CI_PROFILE_TYPE, ---60
		   AMOUNT_TYPE, ---61
		   CASH_CODE, ---62
		   EMEA_FLAG, ---63
		   CUST_CREDIT_PREF, ---64
		   ITEM_UOM_C, ---65
		   IB30_REASON_C, ---66
		   RECEIVER_LOC, ---67 
		   RA_LOC, ---68
		   FINAL_DEST, ---69
		   JOURNAL_SOURCE_C, ---70
		   KAVA_F, ---71
		   DIVISION, ---72
		   CHECK_STOCK, ---73
		   SALES_LOC, ---74
		   THIRD_PARTY_INTFC_FLAG, ---75
		   VENDOR_PAYMENT_TYPE, ---76
		   VENDOR_CURRENCY_CODE, ---77
		   SPC_INV_CODE, ---78
		   SOURCE_SYSTEM, --- 79 
		   LEG_DIVISION_HDR, --- 80 
		   RECORD_TYPE, ---81 
		   CUSTOMER_NBR, ---82
		   BUSINESS_UNIT, ---83 
		   SHIP_FROM_LOC, ---84
		   FREIGHT_VENDOR_NBR, ---85
		   FREIGHT_INVOICE_NBR, ---86
		   CASH_BATCH_NBR, ---87
		   GL_DIV_HEADQTR_LOC, ---88
		   GL_DIV_HQ_LOC_BU, ---89
		   SHIP_FROM_LOC_BU, ---90
		   PS_AFFILIATE_BU, ---91
		   RECEIVER_NBR, ---92
		   FISCAL_DATE, ---93 
		   VENDOR_NBR, ---94 
		   BATCH_NUMBER, ---95
		   HEAD_OFFICE_LOC, ---96
		   EMPLOYEE_ID, ---97
		   BUSINESS_SEGMENT, ---98
		   UPDATED_USER, ---99
		   USERID, ---100
		   LEG_BU_HDR, --- 101 
		   SALES_ORDER_NBR, ---102
		   CHECK_NBR, ---103
		   VENDOR_ABBREV, ---104 
		   CONCUR_SAE_BATCH_ID, ---105
		   PAYMENT_TERMS, ---106
		   FREIGHT_TERMS, ---107 
		   VENDOR_ABBREV_C, ---108
		   RA_NBR, ---109 
		   SALES_REP, ---110
		   PURCHASE_ORDER_NBR, ---111
		   CATALOG_NBR, ---112  
		   REEL_NBR, ---113 
		   PS_LOCATION, ---114 
		   LOCAL_CURRENCY, ---115 
		   FOREIGN_CURRENCY, ---116 
		   PO_NBR, ---117 
		   PRODUCT_CLASS, ---118 
		   UNIT_OF_MEASURE, ---119 
		   VENDOR_PART_NBR, ---120 
		   RECEIVER_I, ---121 
		   ITEM_I, ---122 
		   TRANS_ID, ---123 
		   INVOICE_I, ---124 
		   RECEIPT_TYPE, ---125
		   COUNTRY_CODE, ---126
		   RA_CUSTOMER_NBR, ---127
		   RA_CUSTOMER_NAME, ---128
		   PURCHASE_CODE, ---129
		   INTERFC_DESC_LOC,---130
		   RECEIVER_NBR_HDR, ---131 
		   PRODUCT_CLASS_HDR, --132 
		   VENDOR_PART_NBR_HDR, --133 
		   GL_TRANSFER, ---134 
		   LEG_TRANS_TYPE, ---135 
		   LEG_LOCATION_HDR, --- 136 
		   INVOICE_NBR, ---137 
		   REFER_INVOICE, ---138
		   VOUCHER_NBR, ---139
		   CASH_CHECK_NBR, ---140
		   FREIGHT_BILL_NBR, ---141
		   FRT_BILL_PRO_REF_NBR, ---142
		   VENDOR_NAME, ---143 
		   PAYMENT_REF_ID, ---144
		   MATCHING_KEY, ---145
		   PAY_FROM_ACCOUNT, ---146
		   INTERFC_DESC_T, ---147
		   INTERFC_DESC_LOC_LANG, ---148
		   HDR_SEQ_NBR, ---149 
		   CUSTOMER_NAME, ---150
		   CASH_LOCKBOX_ID, ---151
		   CUST_PO, ---152
		   FREIGHT_VENDOR_NAME, ---153
		   TRANSACTION_TYPE, --- 154 
		   THIRD_PARTY_INVOICE_ID, ---155
		   CONTRA_REASON, ---156
		   TRANSREF, ---157
		   IB30_MEMO, ---158 
		   TRANSACTION_NUMBER, --- 159 
           LEDGER_NAME,     --- 160  
           FILE_NAME,  --- 161 
		   INTERFACE_DESC_EN, ---162
		   INTERFACE_DESC_FRN, ---163 
		   HEADER_DESC, --- 164 
           HEADER_DESC_LOCAL_LAN, --- 165 
		   CREATION_DATE, ---166
		   LAST_UPDATE_DATE, ---167
		   CREATED_BY, ---168
		   LAST_UPDATED_BY, ---169
		   ATTRIBUTE6, ---170
		   ATTRIBUTE7, ---171
		   ATTRIBUTE8, ---172
		   ATTRIBUTE9, ---173
		   ATTRIBUTE10, ---174
		   ATTRIBUTE11, ---175
		   ATTRIBUTE12, ---176
		   ATTRIBUTE1, ---177
		   ATTRIBUTE2, ---178
		   ATTRIBUTE3, ---179
		   ATTRIBUTE4, ---180
		   ATTRIBUTE5, ---181
		   ACCRUED_QUANTITY_DAI, --- 182
           LEG_DIVISION, --- 183
           TRD_PARTNER_NBR_HDR, --- 184
           TRD_PARTNER_NAME_HDR, --- 185
           INVOCIE_DATE,  --- 186
           HEADER_AMOUNT, --- 187
           LEG_AFFILIATE, --- 188
           UOM_C_HDR, --- 189
           INV_TOTAL, --- 190
           PURCHASE_CODE_HDR, --- 191
           USER_I, --- 192
           REASON_CODE_HDR --- 193
            ) 
			VALUES (
           i.BATCH_ID,  ---1  
		   wsc_mfinv_header_t_s1.NEXTVAL,  ---2
		   i.AMOUNT, ---3
		   i.AMOUNT_IN_CUST_CURR, ---4
		   i.FX_RATE_ON_INVOICE, ---5
		   i.TAX_INVC_I, ---6
		   i.GAAP_AMOUNT, ---7  
		   i.GAAP_AMOUNT_IN_CUST_CURR, ---8 
		   i.CASH_FX_RATE, ---9
		   i.UOM_CONV_FACTOR, ---10 
		   i.NET_TOTAL, ---11
		   i.LOC_INV_NET_TOTAL, ---12
		   i.INVOICE_TOTAL, ---13
		   i.LOCAL_INV_TOTAL, ---14
		   i.FX_RATE, ---15
		   i.CHECK_AMOUNT, ---16
		   i.ACCRUED_QTY, ---17
		   i.FISCAL_WEEK_NBR, ---18
		   i.TOT_LOCAL_AMT, ---19
		   i.TOT_FOREIGN_AMT, ---20
		   i.FREIGHT_FACTOR, ---21
		   i.INVOICE_DATE, ---22
		   i.INVOICE_DUE_DATE, ---23
		   i.FREIGHT_INVOICE_DATE, ---24
		   i.CASH_DATE, ---25
		   i.CASH_ENTRY_DATE, ---26
		   i.ACCOUNT_DATE, ---27  
		   i.BANK_DEPOSIT_DATE, ---28
		   i.MATCHING_DATE, ---29
		   i.ADJUSTMENT_DATE, ---30 
		   i.ACCOUNTING_DATE, ---31 
		   i.CHECK_DATE, ---32
		   i.BATCH_DATE, ---33
		   i.DUE_DATE, ---34
		   i.VOID_DATE, ---35
		   i.DOCUMENT_DATE, ---36 
		   i.RECEIVER_CREATE_DATE, ---37
		   i.TRANSACTION_DATE, ----38 
		   i.CONTINENT, ---39  
		   i.CONT_C, ---40 
		   i.PO_TYPE, ---41 
		   i.CHECK_PAYMENT_TYPE, ---42
		   i.VOID_CODE, ---43
		   i.CROSS_BORDER_FLAG, ---44
		   i.BATCH_POSTED_FLAG, ---45
		   i.INTERFACE_ID, ---46 
		   i.LOCATION, ---47   
		   i.INVOICE_TYPE, ---48 
		   i.CUSTOMER_TYPE, ---49
		   i.INVOICE_LOC_ISO_CNTRY, ---50
		   i.INVOICE_LOC_DIV, ---51
		   i.SHIP_TO_NBR, ---52
		   i.INVOICE_CURRENCY, ---53 
		   i.CUSTOMER_CURRENCY, ---54
		   i.SHIP_TYPE, ---55
		   i.EXPORT_TYPE, ---56
		   i.RECORD_ERROR_CODE, ---57
		   i.CREDIT_TYPE, ---58
		   i.NON_RA_CREDIT_TYPE, ---59
		   i.CI_PROFILE_TYPE, ---60
		   i.AMOUNT_TYPE, ---61
		   i.CASH_CODE, ---62
		   i.EMEA_FLAG, ---63
		   i.CUST_CREDIT_PREF, ---64
		   i.ITEM_UOM_C, ---65
		   i.IB30_REASON_C, ---66
		   i.RECEIVER_LOC, ---67 
		   i.RA_LOC, ---68
		   i.FINAL_DEST, ---69
		   i.JOURNAL_SOURCE_C, ---70
		   i.KAVA_F, ---71
		   i.DIVISION, ---72
		   i.CHECK_STOCK, ---73
		   i.SALES_LOC, ---74
		   i.THIRD_PARTY_INTFC_FLAG, ---75
		   i.VENDOR_PAYMENT_TYPE, ---76
		   i.VENDOR_CURRENCY_CODE, ---77
		   i.SPC_INV_CODE, ---78
		   i.SOURCE_SYSTEM, --- 79 
		   i.LEG_DIVISION_HDR, --- 80 
		   i.RECORD_TYPE, ---81 
		   i.CUSTOMER_NBR, ---82
		   i.BUSINESS_UNIT, ---83 
		   i.SHIP_FROM_LOC, ---84
		   i.FREIGHT_VENDOR_NBR, ---85
		   i.FREIGHT_INVOICE_NBR, ---86
		   i.CASH_BATCH_NBR, ---87
		   i.GL_DIV_HEADQTR_LOC, ---88
		   i.GL_DIV_HQ_LOC_BU, ---89
		   i.SHIP_FROM_LOC_BU, ---90
		   i.PS_AFFILIATE_BU, ---91
		   i.RECEIVER_NBR, ---92
		   i.FISCAL_DATE, ---93 
		   i.VENDOR_NBR, ---94 
		   i.BATCH_NUMBER, ---95
		   i.HEAD_OFFICE_LOC, ---96
		   i.EMPLOYEE_ID, ---97
		   i.BUSINESS_SEGMENT, ---98
		   i.UPDATED_USER, ---99
		   i.USERID, ---100
		   i.LEG_BU_HDR, --- 101 
		   i.SALES_ORDER_NBR, ---102
		   i.CHECK_NBR, ---103
		   i.VENDOR_ABBREV, ---104 
		   i.CONCUR_SAE_BATCH_ID, ---105
		   i.PAYMENT_TERMS, ---106
		   i.FREIGHT_TERMS, ---107 
		   i.VENDOR_ABBREV_C, ---108
		   i.RA_NBR, ---109 
		   i.SALES_REP, ---110
		   i.PURCHASE_ORDER_NBR, ---111
		   i.CATALOG_NBR, ---112  
		   i.REEL_NBR, ---113 
		   i.PS_LOCATION, ---114 
		   i.LOCAL_CURRENCY, ---115 
		   i.FOREIGN_CURRENCY, ---116 
		   i.PO_NBR, ---117 
		   i.PRODUCT_CLASS, ---118 
		   i.UNIT_OF_MEASURE, ---119 
		   i.VENDOR_PART_NBR, ---120 
		   i.RECEIVER_I, ---121 
		   i.ITEM_I, ---122 
		   i.TRANS_ID, ---123 
		   i.INVOICE_I, ---124 
		   i.RECEIPT_TYPE, ---125
		   i.COUNTRY_CODE, ---126
		   i.RA_CUSTOMER_NBR, ---127
		   i.RA_CUSTOMER_NAME, ---128
		   i.PURCHASE_CODE, ---129
		   i.INTERFC_DESC_LOC,---130
		   i.RECEIVER_NBR_HDR, ---131 
		   i.PRODUCT_CLASS_HDR, --132 
		   i.VENDOR_PART_NBR_HDR, --133 
		   i.GL_TRANSFER, ---134 
		   i.LEG_TRANS_TYPE, ---135 
		   i.LEG_LOCATION_HDR, --- 136 
		   i.INVOICE_NBR, ---137 
		   i.REFER_INVOICE, ---138
		   i.VOUCHER_NBR, ---139
		   i.CASH_CHECK_NBR, ---140
		   i.FREIGHT_BILL_NBR, ---141
		   i.FRT_BILL_PRO_REF_NBR, ---142
		   i.VENDOR_NAME, ---143 
		   i.PAYMENT_REF_ID, ---144
		   i.MATCHING_KEY, ---145
		   i.PAY_FROM_ACCOUNT, ---146
		   i.INTERFC_DESC_T, ---147
		   i.INTERFC_DESC_LOC_LANG, ---148
		   i.HDR_SEQ_NBR, ---149 
		   i.CUSTOMER_NAME, ---150
		   i.CASH_LOCKBOX_ID, ---151
		   i.CUST_PO, ---152
		   i.FREIGHT_VENDOR_NAME, ---153
		   i.TRANSACTION_TYPE, --- 154 
		   i.THIRD_PARTY_INVOICE_ID, ---155
		   i.CONTRA_REASON, ---156
		   i.TRANSREF, ---157
		   i.IB30_MEMO, ---158 
		   i.trx_number, --- 159 
           i.LEDGER_NAME,     --- 160  
           i.FILE_NAME,  --- 161 
		   i.INTERFACE_DESC_EN, ---162
		   i.INTERFACE_DESC_FRN, ---163 
		   i.HEADER_DESC, --- 164 
           i.HEADER_DESC_LOCAL_LAN, --- 165 
		   i.CREATION_DATE, ---166
		   i.LAST_UPDATE_DATE, ---167
		   i.CREATED_BY, ---168
		   i.LAST_UPDATED_BY, ---169
		   i.ATTRIBUTE6, ---170
		   i.header_id, ---171 ---- changed on 1/12/2023
		   i.ATTRIBUTE8, ---172
		   i.ATTRIBUTE9, ---173
		   i.ATTRIBUTE10, ---174
		   i.ATTRIBUTE11, ---175
		   i.ATTRIBUTE12, ---176
		   i.ATTRIBUTE1, ---177
		   i.ATTRIBUTE2, ---178
		   i.ATTRIBUTE3, ---179
		   i.ATTRIBUTE4, ---180
		   i.ATTRIBUTE5, ---181
		   i.ACCRUED_QUANTITY_DAI, --- 182
           i.LEG_DIVISION, --- 183
           i.TRD_PARTNER_NBR_HDR, --- 184
           i.TRD_PARTNER_NAME_HDR, --- 185
           i.INVOCIE_DATE,  --- 186
           i.HEADER_AMOUNT, --- 187
           i.LEG_AFFILIATE, --- 188
           i.UOM_C_HDR, --- 189
           i.INV_TOTAL, --- 190
           i.PURCHASE_CODE_HDR, --- 191
           i.USER_I, --- 192
           i.REASON_CODE_HDR --- 193
            );
        END LOOP;

        logging_insert('MF INV', p_batch_id, 36, 'MF INV - Insert New Header Id In Header Table Completed', NULL,
                      sysdate);
        UPDATE wsc_ahcs_mfinv_txn_line_t line
        SET
            line.last_update_date = sysdate,
            header_id = (
                SELECT
                    header_id
                FROM
                    wsc_ahcs_mfinv_txn_header_t hdr
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
                    wsc_ahcs_mfinv_txn_header_t hdr
                WHERE
                        line.attribute5 = hdr.ledger_name
                    AND line.header_id = hdr.attribute7
                    AND line.batch_id = hdr.batch_id
                    AND hdr.batch_id = lv_batch_id
            )
        WHERE
               batch_id = lv_batch_id
            AND attribute5 IS NOT NULL
			and exists (select 1 from wsc_ahcs_int_status_t s 
			where s.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' ) 
			AND BATCH_ID =lv_batch_id AND line.line_id = s.line_id );

        logging_insert('MF INV', p_batch_id, 37, 'MF INV - Updated Header Id In Line Table Completed', NULL,sysdate);
        UPDATE wsc_ahcs_int_status_t sts
        SET
            sts.last_updated_date = sysdate,
            header_id = (
                SELECT
                    header_id
                FROM
                    wsc_ahcs_mfinv_txn_line_t line
                WHERE
                        line.line_id = sts.line_id
                    AND line.batch_id = sts.batch_id
                    AND line.batch_id = lv_batch_id
            ),
            attribute3 = (
                SELECT
                    transaction_number
                FROM
                    wsc_ahcs_mfinv_txn_line_t line
                WHERE
                        line.line_id = sts.line_id
                    AND line.batch_id = sts.batch_id
                    AND line.batch_id = lv_batch_id
            )
        WHERE
            batch_id = lv_batch_id and sts.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' ); --- newly added

        logging_insert('MF INV', p_batch_id, 38, 'MF INV - Updated Header Id In Status Table', NULL,sysdate);

        DELETE FROM wsc_ahcs_mfinv_txn_header_t
        WHERE
            header_id IN (
                SELECT DISTINCT
                    attribute7
                FROM
                    wsc_ahcs_mfinv_txn_header_t
                WHERE
                        batch_id = lv_batch_id
                    AND attribute7 IS NOT NULL
            )
            AND batch_id = lv_batch_id;

        COMMIT;
        logging_insert('MF INV', p_batch_id, 39, 'MF INV - Deleted Old Header Id', NULL,sysdate);
    END;

   PROCEDURE wsc_ahcs_mfinv_grp_id_upd_p (
    in_grp_id IN NUMBER
) AS

    lv_grp_id        NUMBER := in_grp_id;
    err_msg          VARCHAR2(4000);
    CURSOR mfinv_grp_data_fetch_cur (
        p_grp_id NUMBER
    ) IS
    /*SELECT DISTINCT
        c.batch_id           batch_id,
        c.file_name          file_name,
        a.ledger_name        ledger_name,
        c.source_application source_application,
        a.interface_id       interface_id,
        c.status             status
    FROM
        wsc_ahcs_int_control_t     c,
        wsc_ahcs_mfinv_txn_header_t a
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
            )   ---- newly added
		AND c.group_id = p_grp_id; */
		
	---7th May 2023 because of prod issue during ramp, changing to below query	#INC2618056
	
		SELECT /*+ index(a WSC_AHCS_MFINV_TXN_HEADER_T_PK) */
DISTINCT
        c.batch_id           batch_id,
        c.file_name          file_name,
        a.ledger_name        ledger_name,
        c.source_application source_application,
        a.interface_id       interface_id,
        c.status             status
    FROM
        wsc_ahcs_int_control_t     c,
        wsc_ahcs_mfinv_txn_header_t a,
        wsc_ahcs_int_status_t s
    WHERE
            a.batch_id = c.batch_id
        AND a.ledger_name IS NOT NULL
        AND c.status = 'TRANSFORM_SUCCESS'
        and c.batch_id = s.batch_id
                    and s.batch_id = a.batch_id
                    AND s.header_id = a.header_id
                    AND s.attribute2 = 'TRANSFORM_SUCCESS'
                    AND ( s.accounting_status = 'IMP_ACC_ERROR'
                          OR s.accounting_status IS NULL )
                             AND c.group_id = p_grp_id; 

    TYPE mfinv_grp_type IS
        TABLE OF mfinv_grp_data_fetch_cur%rowtype;
    lv_mfinv_grp_type mfinv_grp_type;
BEGIN
-- Updating Group Id for MF INV Files in control table----

    UPDATE wsc_ahcs_int_control_t
    SET
        group_id = lv_grp_id
    WHERE
            source_application = 'MF INV'
        AND status = 'TRANSFORM_SUCCESS'
        AND GROUP_ID IS NULL;
    COMMIT;

    OPEN mfinv_grp_data_fetch_cur(lv_grp_id);
    LOOP
        FETCH mfinv_grp_data_fetch_cur
        BULK COLLECT INTO lv_mfinv_grp_type LIMIT 50;
        EXIT WHEN lv_mfinv_grp_type.count = 0;
        FORALL i IN 1..lv_mfinv_grp_type.count
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
                lv_mfinv_grp_type(i).batch_id,
                lv_mfinv_grp_type(i).file_name,
                lv_grp_id,
                lv_mfinv_grp_type(i).ledger_name,
                lv_mfinv_grp_type(i).source_application,
                lv_mfinv_grp_type(i).interface_id,
                lv_mfinv_grp_type(i).status,
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
            APPLICATION = 'MF INV'
        --AND status = 'TRANSFORM_SUCCESS'
        AND GROUP_ID IS NULL
        AND attribute2 = 'TRANSFORM_SUCCESS'
        AND ( accounting_status IS NULL
                  OR accounting_status = 'IMP_ACC_ERROR' )
        AND BATCH_ID IN ( SELECT  distinct BATCH_ID FROM wsc_ahcs_int_control_line_t WHERE GROUP_ID = lv_grp_id);
    COMMIT;
END wsc_ahcs_mfinv_grp_id_upd_p;


  PROCEDURE wsc_ahcs_mfinv_ctrl_line_tbl_ucm_update (
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
                        AND ml.sub_ledger = 'MF INV'
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
                        AND ml.sub_ledger = 'MF INV'
                        AND ml.ledger_name = status.ledger_name
                ) );

            COMMIT;
        END IF;
    END wsc_ahcs_mfinv_ctrl_line_tbl_ucm_update;


PROCEDURE wsc_ahcs_mfinv_ctrl_line_tbl_ledger_grp_num_update (
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
                        AND ml.sub_ledger = 'MF INV'
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
                        AND ml.sub_ledger = 'MF INV'
                        AND ml.ledger_name = status.ledger_name
                ) );

            COMMIT;
        END IF;
    END wsc_ahcs_mfinv_ctrl_line_tbl_ledger_grp_num_update;

     PROCEDURE leg_coa_transformation_JTI_MFINV (
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

        lv_batch_id                NUMBER := p_batch_id;    
        lv_count_succ              NUMBER;
          retcode                    VARCHAR2(50);
           err_msg                    VARCHAR2(50);

    BEGIN  
        BEGIN   
  logging_insert('JTI_MFINV', p_batch_id, 6, 'start transformation', NULL,sysdate);       
  logging_insert('JTI_MFINV', p_batch_id, 7, 'update ledger_name', NULL,sysdate);
          MERGE INTO wsc_ahcs_mfinv_txn_header_t hdr
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
                                      wsc_ahcs_mfinv_txn_line_t  line,
                                      wsc_ahcs_int_status_t     status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = lv_batch_id
                                      AND status.attribute2 in ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' ) -- change for reprocessing
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

			---------JTI REPROCESS CHANGE UPDATED------
			 UPDATE wsc_ahcs_mfinv_txn_header_t hdr
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
                        AND l.sub_ledger = 'MF INV'
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

            logging_insert('MF INV', p_batch_id, 8, 'update transaction number with STATIC_LEDGER_NUMBER -header table- complete',
            NULL,
                          sysdate);

             COMMIT;
            UPDATE wsc_ahcs_mfinv_txn_line_t line
            SET
                line.transaction_number = (
                    SELECT
                        hdr.transaction_number
                    FROM
                        wsc_ahcs_mfinv_txn_header_t hdr
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
                logging_insert('MF INV', p_batch_id, 9, 'MF INV - Update Transaction Number with Static_Ledger_Number Line Table- Completed',
            NULL,
                          sysdate);
             MERGE INTO wsc_ahcs_int_status_t stauts
            USING wsc_ahcs_mfinv_txn_line_t line ON ( stauts.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                                                     AND line.header_id = stauts.header_id
                                                     AND line.batch_id = stauts.batch_id
                                                     AND line.line_id = stauts.line_id
                                                     AND stauts.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET stauts.attribute3 = line.transaction_number;

            COMMIT;

			logging_insert('MF INV', p_batch_id, 10, 'MF INV - Update Transaction Number with Static_Ledger_Number Line Table- Completed',NULL,sysdate);
            logging_insert('MF INV', p_batch_id, 11, 'MF INV - Update Transaction Number with Static_Ledger_Number Completed', NULL,sysdate);



	          /*****Calling Multi Ledger Proc*******/
    logging_insert('JTI_MFINV', p_batch_id, 12, 'MF INV - Call to wsc_ledger_name_derivation prc', NULL,sysdate);

        wsc_ahcs_mfinv_validation_transformation_pkg.wsc_ledger_name_derivation(lv_batch_id);
        COMMIT;	
        EXCEPTION
        WHEN OTHERS THEN
            logging_insert('JTI_MFINV', p_batch_id, 12.1, 'Error in update ledger_name', sqlerrm,sysdate);
            dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('JTI_MFINV', p_batch_id,13, 'Update LEDGER_NAME  in status table -start', NULL,sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_mfinv_txn_header_t h
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
        logging_insert('JTI_MFINV', p_batch_id, 14, 'Update LEDGER_NAME  in status table -end', NULL,sysdate);

        logging_insert('JTI_MFINV', p_batch_id, 15, 'Update status table to have record-wise status', NULL,sysdate);
        BEGIN
            UPDATE (
                SELECT
                    sts.attribute2,
                    sts.status,
                    sts.last_updated_date,
                    sts.error_msg
                FROM
                    wsc_ahcs_int_status_t       sts,
                    wsc_ahcs_mfinv_txn_header_t  hdr
                WHERE
                        sts.batch_id = p_batch_id
                    AND hdr.header_id = sts.header_id
                    AND hdr.batch_id = sts.batch_id
                    AND hdr.ledger_name IS NULL
                    AND sts.error_msg IS NULL
                    AND sts.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' ) --- change for reprocessing
            )
            SET
                error_msg = 'Ledger derivation failed',
                attribute2 = 'TRANSFORM_FAILED',
                status = 'TRANSFORM_FAILED',
                last_updated_date = sysdate;

        logging_insert('JTI_MFINV', p_batch_id, 16, 'Update status column in status table to have record-wise status', NULL, sysdate);

            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'TRANSFORM_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' ) --- change for reprocessing
              --  AND attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' ) 
                AND error_msg IS NULL;

            COMMIT;

        logging_insert('JTI_MFINV', p_batch_id, 17, 'Update attribute2 column in status table to have record-wise status', NULL, sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                attribute2 = 'TRANSFORM_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' ) --- change for reprocessing
                AND error_msg IS NULL;
            COMMIT;    

            	-------------------------------------------------------------------------------------------------------------------------------------------
			-- 9. Flag the control table to consider this file as TRANSFORMATION COMPLETE. 
			--    /************ THIS WILL SIGNAL OIC TO PICK THIS FILE FOR UCM UPLOAD BY MASTER SCHEDULER ***********************/
			-------------------------------------------------------------------------------------------------------------------------------------------

        logging_insert('JTI_MFINV', p_batch_id, 18, 'Update control table status', NULL, sysdate);

            OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_succ;
            CLOSE cur_count_sucss;

        logging_insert('JTI_MFINV', p_batch_id, 19, 'count success', lv_count_succ,sysdate);
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
        logging_insert('JTI_MFINV', p_batch_id, 20, 'MF INV - Transformation Completed', NULL,sysdate);
        logging_insert('JTI_MFINV', p_batch_id, 21, 'MF INV - AHCS Dashboard Refresh Started', NULL,sysdate);
            wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
        logging_insert('JTI_MFINV', p_batch_id, 22, 'MF INV - AHCS Dashboard Refresh Completed', NULL,sysdate);          
        END;
        logging_insert('JTI_MFINV', p_batch_id, 23, 'MF INV - Transformation after Dashboard Call Completed', NULL,sysdate);
    EXCEPTION
    WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT241'
                                                    || '_'
                                                    || 'MFINV',
                                                    'MF_INV',
                                                    sqlerrm);
    END leg_coa_transformation_JTI_MFINV;

	---------------REPROCESS FOR JTI ADDED DEC-14---------------

    PROCEDURE leg_coa_transformation_jti_mfinv_reprocess (
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
    -- The following cursor will retrieve ALL records from status table which has TRANSFORM_SUCCESS in attribute2.
    ------------------------------------------------------------------------------------------------------------------------------------------------------
        l_system         VARCHAR2(30);
        lv_batch_id      NUMBER := p_batch_id;
        lv_group_id      NUMBER; --added for reprocess individual group id process 14th Dec 2022
        retcode          VARCHAR2(50);
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
------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will fetch all the records with TRANSFORM_FAILED status from status table.
        ----------------------------------------------------------------------------------------------------------------------------------------------
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

        lv_count_succ    NUMBER;
        CURSOR jti_mfinv_grp_data_fetch_cur ( --added for reprocess individual group id process 14th Dec 2022
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
            wsc_ahcs_mfinv_txn_header_t a
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

        TYPE mfinv_grp_type IS
            TABLE OF jti_mfinv_grp_data_fetch_cur%rowtype;
        lv_mfinv_grp_type mfinv_grp_type;
    BEGIN
        BEGIN
            logging_insert('JTI MF INV', p_batch_id, 6, 'Update control table status to validation success.', NULL,
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
	-------------------------------------------------------------------------------------------------------------------------------------------
 -- Update Ledger based on the legal entity in the header table.---
            logging_insert('JTI MF INV', p_batch_id, 7, 'Update ledger name in header table start.', NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_mfinv_txn_header_t hdr
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
                                      wsc_ahcs_mfinv_txn_line_t line,
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
            logging_insert('JTI MF INV', p_batch_id, 8, 'Update Ledger name Ends', sqlerrm,
                          sysdate);
            logging_insert('JTI MF INV', p_batch_id, 8.1, 'Update static number in header table.', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_mfinv_txn_header_t hdr
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
                        AND l.sub_ledger = 'MF INV'
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
                        AND hdr.batch_id = s.batch_id
                );

            logging_insert('MF INV', p_batch_id, 8.2, 'MF INV - Update Transaction Number with Static_Ledger_Number Header Table Completed',
            NULL,
                          sysdate);
--            MERGE INTO wsc_ahcs_mfinv_txn_line_t line
--            USING wsc_ahcs_mfinv_txn_header_t hdr ON ( line.header_id = hdr.header_id
--                                                      AND line.batch_id = hdr.batch_id
--                                                      AND hdr.ledger_name IS NOT NULL
--                                                      AND hdr.batch_id = p_batch_id )
--            WHEN MATCHED THEN UPDATE
--            SET line.transaction_number = hdr.transaction_number;

            COMMIT;
            UPDATE wsc_ahcs_mfinv_txn_line_t line
            SET
                line.transaction_number = (
                    SELECT
                        hdr.transaction_number
                    FROM
                        wsc_ahcs_mfinv_txn_header_t hdr
                    WHERE
                            hdr.header_id = line.header_id
                        AND hdr.batch_id = line.batch_id
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
                        AND line.line_id = s.line_id
                        AND line.batch_id = s.batch_id
                );

            COMMIT;
            logging_insert('MF INV', p_batch_id, 8.3, 'MF INV - Update Transaction Number with Static_Ledger_Number Line Table- Completed',
            NULL,
                          sysdate);
--add status insertion
            MERGE INTO wsc_ahcs_int_status_t stauts
            USING wsc_ahcs_mfinv_txn_line_t line ON ( stauts.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                                                     AND line.header_id = stauts.header_id
                                                     AND line.batch_id = stauts.batch_id
                                                     AND line.line_id = stauts.line_id
                                                     AND stauts.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET stauts.attribute3 = line.transaction_number;

            COMMIT;
            logging_insert('MF INV', p_batch_id, 8.4, 'update transaction number with STATIC_LEDGER_NUMBER -line and status table- complete',
            NULL,
                          sysdate);
            logging_insert('JTI MF INV', p_batch_id, 9, 'Update multi Ledger name check with respect to each header id start', sqlerrm,
                          sysdate);
            wsc_ahcs_mfinv_validation_transformation_pkg.wsc_ledger_name_derivation(lv_batch_id);
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('JTI MF INV', p_batch_id, 9.1, 'Error in update ledger name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('JTI MF INV', p_batch_id, 10, 'Update multi Ledger name check with respect to each header id ends', sqlerrm,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_mfinv_txn_header_t h
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

        logging_insert('JTI MF INV', p_batch_id, 11, 'Ledger updated in status table and status update started.', NULL,
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
                    wsc_ahcs_mfinv_txn_header_t hdr
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
            --    AND attribute2 = 'VALIDATION_SUCCESS'
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
            logging_insert('JTI MF INV', p_batch_id, 12, 'Update status table statuses completed.', NULL,
                          sysdate);
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

        BEGIN --added for reprocess individual group id process 14th Dec 2022
            lv_group_id := wsc_ahcs_mf_grp_id_seq.nextval;
            UPDATE wsc_ahcs_int_control_t
            SET
                group_id = lv_group_id
            WHERE
                    source_application = 'MF INV'
                AND status = 'TRANSFORM_SUCCESS'
                AND group_id IS NULL
                AND batch_id = p_batch_id;

            logging_insert('JTI MF INV', p_batch_id, 13, 'Group Id update in control table ends.' || sqlerrm, NULL,
                          sysdate);
            COMMIT;
            OPEN jti_mfinv_grp_data_fetch_cur(lv_group_id);
            LOOP
                FETCH jti_mfinv_grp_data_fetch_cur
                BULK COLLECT INTO lv_mfinv_grp_type LIMIT 50;
                EXIT WHEN lv_mfinv_grp_type.count = 0;
                FORALL i IN 1..lv_mfinv_grp_type.count
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
                        lv_mfinv_grp_type(i).batch_id,
                        lv_mfinv_grp_type(i).file_name,
                        lv_group_id,
                        lv_mfinv_grp_type(i).ledger_name,
                        lv_mfinv_grp_type(i).source_application,
                        lv_mfinv_grp_type(i).interface_id,
                        lv_mfinv_grp_type(i).status,
                        'FIN_INT',
                        sysdate,
                        'FIN_INT',
                        sysdate
                    );

            END LOOP;

            COMMIT;
            logging_insert('JTI MF INV', p_batch_id, 14, 'Control Line insertion for group id ends.' || sqlerrm, NULL,
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
            logging_insert('JTI MF INV', p_batch_id, 15, 'Group id update in status table ends.' || sqlerrm, NULL,
                          sysdate);
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('JTI MF INV', p_batch_id, 15.1, 'Error in the reprocess group id block.' || sqlerrm, NULL,
                              sysdate);
        END;

        logging_insert('JTI MF INV', p_batch_id, 16, 'Dashboard Start', NULL,
                      sysdate);
        wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
        logging_insert('JTI MF INV', p_batch_id, 17, 'Dashboard End', NULL,
                      sysdate);
        logging_insert('JTI MF INV', p_batch_id, 18, 'end transformation', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT241_MFINV', 'JTI MF INV', sqlerrm);
    END leg_coa_transformation_jti_mfinv_reprocess;
	
	
	/****MFINV INVT LINE COPY PROCEDURE FOR USER STORY RTR-AHCS-198****/
	
PROCEDURE wsc_ahcs_mfinv_invt_line_copy_p (
    p_batch_id IN NUMBER
) AS

   l_mfinv_subsystem VARCHAR2(50):=NULL;

    CURSOR mfinv_invt_line_copy_data_cur (
        p_batch_id NUMBER
    ) IS
     SELECT
	line.BATCH_ID , 
    line.LINE_ID ,  
    line.HEADER_ID ,   
    line.LINE_SEQ_NUMBER,
    line.AMOUNT ,   
line.AMOUNT_IN_CUST_CURR , 
line.UNIT_PRICE , 
line.SHIPPED_QUANTITY ,
line.UOM_CNVRN_FACTOR ,  
line.BILLED_QTY , 
line.AVG_UNIT_COST , 
line.STD_UNIT_COST , 
line.QTY_ON_HAND_BEFORE ,  
line.ADJUSTMENT_QTY ,   
line.QTY_ON_HAND_AFTER ,   
line.CUR_COST_BEFORE , 
line.ADJ_COST_LOCAL ,   
line.ADJ_COST_FOREIGN ,  
line.FX_RATE , 
line.CUR_COST_AFTER ,  
line.GL_AMOUNT_IN_LOC_CURR , 
line.GL_AMNT_IN_FORIEGN_CURR ,
line.QUANTITY , 
line.UOM_CONV_FACTOR , 
line.UNIT_COST , 
line.EXT_COST , 
line.AVG_UNIT_COST_A , 
line.AMT_LOCAL_CURR , 
line.AMT_FOREIGN_CURR , 
line.RECEIVED_QTY , 
line.RECEIVED_UNIT_COST , 
line.PO_UNIT_COST , 
line.TRANSACTION_AMOUNT , 
line.FOREIGN_EX_RATE , 
line.BASE_AMOUNT , 
line.INVOICE_DATE , 
line.RECEIPT_DATE , 
line.LINE_UPDATED_DATE , 
line.MATCHING_DATE , 
line.PC_FLAG , 
line.VENDOR_INDICATOR , 
line.CONTINENT, 
line.DB_CR_FLAG , 
line.INTERFACE_ID , 
line.LINE_TYPE , 
line.AMOUNT_TYPE , 
line.LINE_NBR , 
line.LRD_SHIP_FROM , 
line.UOM_C , 
line.INVOICE_CURRENCY , 
line.CUSTOMER_CURRENCY , 
line.GAAP_F , 
line.GL_DIVISION , 
line.LOCAL_CURRENCY , 
line.FOREIGN_CURRENCY , 
line.PO_LINE_NBR , 
line.LEG_DIVISION , 
line.TRANSACTION_CURR_CD , 
line.BASE_CURR_CD , 
line.TRANSACTION_TYPE , 
line.LOCATION , 
line.MIG_SIG , 
line.BUSINESS_UNIT , 
line.PAYMENT_CODE , 
line.VENDOR_NBR , 
line.RECEIVER_NBR , 
line.UNIT_OF_MEASURE , 
line.GL_ACCOUNT , 
line.GL_DEPT_ID , 
line.ADJUSTMENT_USER_I , 
line.GL_AXE_VENDOR , 
line.GL_PROJECT , 
line.GL_AXE_LOC , 
line.GL_CURRENCY_CD ,
line.PS_AFFILIATE_BU , 
line.CASH_AR50_COMMENTS , 
line.VENDOR_ABBREV_C , 
line.QTY_COST_REASON , 
line.QTY_COST_REASON_CD , 
line.ACCT_DESC , 
line.ACCT_NBR , 
line.LOC_CODE , 
line.DEPT_CODE , 
line.GL_LOCATION , 
line.GL_VENDOR , 
line.BUYER_CODE , 
line.GL_BUSINESS_UNIT , 
line.GL_DEPARTMENT , 
line.GL_VENDOR_NBR_FULL , 
line.AFFILIATE , 
line.ACCOUNTING_DATE , 
line.RECEIVER_LINE_NBR , 
line.VENDOR_PART_NBR , 
line.ERROR_TYPE , 
line.ERROR_CODE , 
line.GL_LEGAL_ENTITY , 
line.GL_ACCT , 
line.GL_OPER_GRP , 
line.GL_DEPT , 
line.GL_SITE , 
line.GL_IC , 
line.GL_PROJECTS , 
line.GL_FUT_1 ,
line.GL_FUT_2 , 
line.SUBLEDGER_NBR , 
line.BATCH_NBR , 
line.ORDER_ID , 
line.INVOICE_NBR , 
line.PRODUCT_CLASS , 
line.PART_NBR ,  
line.VENDOR_ITEM_NBR , 
line.PO_NBR , 
line.MATCHING_KEY , 
line.VENDOR_NAME , 
line.HDR_SEQ_NBR , 
line.ITEM_NBR , 
line.SUBLEDGER_NAME , 
line.LINE_UPDATED_BY , 
line.VENDOR_STK_NBR , 
line.LSI_LINE_DESCR , 
line.CREATION_DATE , 
line.LAST_UPDATE_DATE , 
line.CREATED_BY , 
line.LAST_UPDATED_BY, 
line.LEG_COA,
line.TARGET_COA ,
line.STATEMENT_ID,
line.GL_ALLCON_COMMENTS,
line.ATTRIBUTE6 ,
line.ATTRIBUTE7 ,
line.ATTRIBUTE8 ,
line.ATTRIBUTE9 ,
line.ATTRIBUTE10 ,
line.ATTRIBUTE11 ,
line.ATTRIBUTE12 ,
line.ATTRIBUTE1 ,
line.ATTRIBUTE2 ,
line.ATTRIBUTE3 ,
line.ATTRIBUTE4 ,
line.ATTRIBUTE5 ,
line.DEFAULT_AMOUNT,
line.ACC_AMOUNT,
line.ACC_CURRENCY,
line.DEFAULT_CURRENCY,
line.LEG_LOCATION_LN,
line.LEG_ACCT,
line.LEG_DEPT,
line.LOCATION_LN,
line.LEG_VENDOR,
line.TRD_PARTNER_NAME,
line.REASON_CODE,
line.TRANSACTION_NUMBER,
line.LEG_SEG_1_4,
line.LEG_SEG_5_7,
line.TRD_PARTNER_NBR, 
line.LEG_ACCT_DESC, 
line.LEG_BU, 
line.LEG_LOC, 
line.LEG_AFFILIATE,
line.PS_LOCATION,
line.AXE_VENDOR,
line.LEG_LOC_SR,
line.PRODUCT_CLASS_LN,
line.LEG_BU_LN,
line.LEG_ACCOUNT,
line.LEG_DEPARTMENT, 
line.LEG_AFFILIATE_LN,
line.QUANTITY_DAI,
line.VENDOR_PART_NBR_LN,
line.PO_NBR_LN,
line.LEG_PROJECT,
line.LEG_DIVISION_LN,
line.RECORD_TYPE
        FROM
            wsc_ahcs_mfinv_txn_line_t  line,
            wsc_ahcs_mfinv_txn_header_t  header,
			wsc_ahcs_int_status_t status
        WHERE
                header.batch_id = p_batch_id
            AND header.batch_id = line.batch_id
            AND header.header_id = line.header_id
			AND header.customer_type='IA'
            AND line.amount_type='AVG'
			AND status.attribute2='TRANSFORM_SUCCESS'
			AND status.status='TRANSFORM_SUCCESS'
			AND status.batch_id = line.batch_id
            AND status.header_id = line.header_id
            AND status.line_id = line.line_id
			AND header.interface_id='INVT'
			AND header.batch_id=status.batch_id
			AND header.header_id=status.header_id
            AND status.attribute6 is null
			AND status.accounting_status is null;

    TYPE mfinv_line_copy_type IS
      TABLE OF mfinv_invt_line_copy_data_cur%rowtype;
    lv_mfinv_line_copy_type mfinv_line_copy_type;
	
	----------AIIB AND INTR CURSOR-----------
	CURSOR mfinv_aiib_intr_line_copy_data_cur (
        p_batch_id NUMBER
    ) IS
     SELECT
	line.BATCH_ID , 
line.LINE_ID ,  
line.HEADER_ID ,   
line.LINE_SEQ_NUMBER,
line.AMOUNT ,   
line.AMOUNT_IN_CUST_CURR , 
line.UNIT_PRICE , 
line.SHIPPED_QUANTITY ,
line.UOM_CNVRN_FACTOR ,  
line.BILLED_QTY , 
line.AVG_UNIT_COST , 
line.STD_UNIT_COST , 
line.QTY_ON_HAND_BEFORE ,  
line.ADJUSTMENT_QTY ,   
line.QTY_ON_HAND_AFTER ,   
line.CUR_COST_BEFORE , 
line.ADJ_COST_LOCAL ,   
line.ADJ_COST_FOREIGN ,  
line.FX_RATE , 
line.CUR_COST_AFTER ,  
line.GL_AMOUNT_IN_LOC_CURR , 
line.GL_AMNT_IN_FORIEGN_CURR ,
line.QUANTITY , 
line.UOM_CONV_FACTOR , 
line.UNIT_COST , 
line.EXT_COST , 
line.AVG_UNIT_COST_A , 
line.AMT_LOCAL_CURR , 
line.AMT_FOREIGN_CURR , 
line.RECEIVED_QTY , 
line.RECEIVED_UNIT_COST , 
line.PO_UNIT_COST , 
line.TRANSACTION_AMOUNT , 
line.FOREIGN_EX_RATE , 
line.BASE_AMOUNT , 
line.INVOICE_DATE , 
line.RECEIPT_DATE , 
line.LINE_UPDATED_DATE , 
line.MATCHING_DATE , 
line.PC_FLAG , 
line.VENDOR_INDICATOR , 
line.CONTINENT, 
line.DB_CR_FLAG , 
line.INTERFACE_ID , 
line.LINE_TYPE , 
line.AMOUNT_TYPE , 
line.LINE_NBR , 
line.LRD_SHIP_FROM , 
line.UOM_C , 
line.INVOICE_CURRENCY , 
line.CUSTOMER_CURRENCY , 
line.GAAP_F , 
line.GL_DIVISION , 
line.LOCAL_CURRENCY , 
line.FOREIGN_CURRENCY , 
line.PO_LINE_NBR , 
line.LEG_DIVISION , 
line.TRANSACTION_CURR_CD , 
line.BASE_CURR_CD , 
line.TRANSACTION_TYPE , 
line.LOCATION , 
line.MIG_SIG , 
line.BUSINESS_UNIT , 
line.PAYMENT_CODE , 
line.VENDOR_NBR , 
line.RECEIVER_NBR , 
line.UNIT_OF_MEASURE , 
line.GL_ACCOUNT , 
line.GL_DEPT_ID , 
line.ADJUSTMENT_USER_I , 
line.GL_AXE_VENDOR , 
line.GL_PROJECT , 
line.GL_AXE_LOC , 
line.GL_CURRENCY_CD ,
line.PS_AFFILIATE_BU , 
line.CASH_AR50_COMMENTS , 
line.VENDOR_ABBREV_C , 
line.QTY_COST_REASON , 
line.QTY_COST_REASON_CD , 
line.ACCT_DESC , 
line.ACCT_NBR , 
line.LOC_CODE , 
line.DEPT_CODE , 
line.GL_LOCATION , 
line.GL_VENDOR , 
line.BUYER_CODE , 
line.GL_BUSINESS_UNIT , 
line.GL_DEPARTMENT , 
line.GL_VENDOR_NBR_FULL , 
line.AFFILIATE , 
line.ACCOUNTING_DATE , 
line.RECEIVER_LINE_NBR , 
line.VENDOR_PART_NBR , 
line.ERROR_TYPE , 
line.ERROR_CODE , 
line.GL_LEGAL_ENTITY , 
line.GL_ACCT , 
line.GL_OPER_GRP , 
line.GL_DEPT , 
line.GL_SITE , 
line.GL_IC , 
line.GL_PROJECTS , 
line.GL_FUT_1 ,
line.GL_FUT_2 , 
line.SUBLEDGER_NBR , 
line.BATCH_NBR , 
line.ORDER_ID , 
line.INVOICE_NBR , 
line.PRODUCT_CLASS , 
line.PART_NBR ,  
line.VENDOR_ITEM_NBR , 
line.PO_NBR , 
line.MATCHING_KEY , 
line.VENDOR_NAME , 
line.HDR_SEQ_NBR , 
line.ITEM_NBR , 
line.SUBLEDGER_NAME , 
line.LINE_UPDATED_BY , 
line.VENDOR_STK_NBR , 
line.LSI_LINE_DESCR , 
line.CREATION_DATE , 
line.LAST_UPDATE_DATE , 
line.CREATED_BY , 
line.LAST_UPDATED_BY, 
line.LEG_COA,
line.TARGET_COA ,
line.STATEMENT_ID,
line.GL_ALLCON_COMMENTS,
line.ATTRIBUTE6 ,
line.ATTRIBUTE7 ,
line.ATTRIBUTE8 ,
line.ATTRIBUTE9 ,
line.ATTRIBUTE10 ,
line.ATTRIBUTE11 ,
line.ATTRIBUTE12 ,
line.ATTRIBUTE1 ,
line.ATTRIBUTE2 ,
line.ATTRIBUTE3 ,
line.ATTRIBUTE4 ,
line.ATTRIBUTE5 ,
line.DEFAULT_AMOUNT,
line.ACC_AMOUNT,
line.ACC_CURRENCY,
line.DEFAULT_CURRENCY,
line.LEG_LOCATION_LN,
line.LEG_ACCT,
line.LEG_DEPT,
line.LOCATION_LN,
line.LEG_VENDOR,
line.TRD_PARTNER_NAME,
line.REASON_CODE,
line.TRANSACTION_NUMBER,
line.LEG_SEG_1_4,
line.LEG_SEG_5_7,
line.TRD_PARTNER_NBR, 
line.LEG_ACCT_DESC, 
line.LEG_BU, 
line.LEG_LOC, 
line.LEG_AFFILIATE,
line.PS_LOCATION,
line.AXE_VENDOR,
line.LEG_LOC_SR,
line.PRODUCT_CLASS_LN,
line.LEG_BU_LN,
line.LEG_ACCOUNT,
line.LEG_DEPARTMENT, 
line.LEG_AFFILIATE_LN,
line.QUANTITY_DAI,
line.VENDOR_PART_NBR_LN,
line.PO_NBR_LN,
line.LEG_PROJECT,
line.LEG_DIVISION_LN,
line.RECORD_TYPE,
header.EMEA_FLAG,
header.GL_DIV_HEADQTR_LOC,
header.AMOUNT_IN_CUST_CURR AMT_IN_CUST_CURR,
header.AMOUNT AMT,
header.CUSTOMER_CURRENCY CUST_CURRENCY,
header.INVOICE_CURRENCY INV_CURRENCY
        FROM
            wsc_ahcs_mfinv_txn_line_t  line,
            wsc_ahcs_mfinv_txn_header_t  header,
			wsc_ahcs_int_status_t status
        WHERE
                header.batch_id = p_batch_id
            AND header.batch_id = line.batch_id
            AND header.header_id = line.header_id
			AND status.attribute2='TRANSFORM_SUCCESS'
			AND status.status='TRANSFORM_SUCCESS'
			AND status.batch_id = line.batch_id
            AND status.header_id = line.header_id
            AND status.line_id = line.line_id
			AND line.line_seq_number='1'
			AND header.interface_id in ('AIIB','INTR')
			AND header.batch_id=status.batch_id
			AND header.header_id=status.header_id
            AND status.attribute6 is null
			AND status.accounting_status is null;

    TYPE mfinv_line_copy_type_t IS
      TABLE OF mfinv_aiib_intr_line_copy_data_cur%rowtype;
    lv_mfinv_line_copy_type_t mfinv_line_copy_type_t;
	

BEGIN

--logging_insert('MF INV INVT', p_batch_id, 42.2, 'MF INV - Line Copy Procedure Insertion Started', NULL,
                --      sysdate); 
					  
	
	BEGIN			  
	select attribute3 INTO l_mfinv_subsystem from wsc_ahcs_int_control_t where batch_id=p_batch_id;
	END;
	
IF l_mfinv_subsystem='INVT'
THEN
logging_insert('MF INV INVT', p_batch_id, 42.2, 'MF INV - INVT Line Copy Procedure Insertion Started', NULL,
                      sysdate); 
					  
					  
	OPEN mfinv_invt_line_copy_data_cur(p_batch_id);
    LOOP
        FETCH mfinv_invt_line_copy_data_cur BULK COLLECT INTO lv_mfinv_line_copy_type LIMIT 400;
        EXIT WHEN lv_mfinv_line_copy_type.count = 0;
        FORALL i IN 1..lv_mfinv_line_copy_type.count
		 
		
	----------INSERT FOR INVT-------------	
	INSERT INTO WSC_AHCS_MFINV_TXN_LINE_T
    (	
    BATCH_ID ,   --- 1
	LINE_ID ,   ---2 
	HEADER_ID ,  ---3 
	LINE_SEQ_NUMBER, ---4
	AMOUNT , ---5   
	AMOUNT_IN_CUST_CURR , ---6 
	UNIT_PRICE , ---7
	SHIPPED_QUANTITY , ---8
	UOM_CNVRN_FACTOR , ---9 
	BILLED_QTY , ---10
	AVG_UNIT_COST , ---11
	STD_UNIT_COST , ---12
	QTY_ON_HAND_BEFORE , ---13 
	ADJUSTMENT_QTY ,  ---14 
	QTY_ON_HAND_AFTER ,  ---15 
	CUR_COST_BEFORE , ---16 
	ADJ_COST_LOCAL , ---17   
	ADJ_COST_FOREIGN , ---18 
	FX_RATE , ---19 
	CUR_COST_AFTER , ---20 
	GL_AMOUNT_IN_LOC_CURR , ---21
	GL_AMNT_IN_FORIEGN_CURR , ---22
	QUANTITY , ---23 
	UOM_CONV_FACTOR , ---24
	UNIT_COST , ---25
	EXT_COST , ---26
	AVG_UNIT_COST_A , ---27 
	AMT_LOCAL_CURR , ---28
	AMT_FOREIGN_CURR , ---29
	RECEIVED_QTY , ---30
	RECEIVED_UNIT_COST , ---31
	PO_UNIT_COST , ---32
	TRANSACTION_AMOUNT , ---33
	FOREIGN_EX_RATE , ---34
	BASE_AMOUNT , ---35
	INVOICE_DATE , ---36
	RECEIPT_DATE , ---37
	LINE_UPDATED_DATE , ---38
	MATCHING_DATE , ---39
	PC_FLAG , ---40
	VENDOR_INDICATOR , ---41 
	CONTINENT, ---42
	DB_CR_FLAG , ---43 
	INTERFACE_ID , ---44 
	LINE_TYPE , ---45
	AMOUNT_TYPE , ---46 
	LINE_NBR , ---47
	LRD_SHIP_FROM , ---48
	UOM_C , ---49 
	INVOICE_CURRENCY , ---50
	CUSTOMER_CURRENCY , ---51
	GAAP_F , ---52 
	GL_DIVISION , ---53
	LOCAL_CURRENCY , ---54 
	FOREIGN_CURRENCY , ---55 
	PO_LINE_NBR , ---56
	LEG_DIVISION , ---57               
	TRANSACTION_CURR_CD , ---58
	BASE_CURR_CD , ---59
	TRANSACTION_TYPE , ---60
	LOCATION , ---61 
	MIG_SIG , ---62
	BUSINESS_UNIT , ---63
	PAYMENT_CODE , ---64
	VENDOR_NBR , ---65
	RECEIVER_NBR , ---66
	UNIT_OF_MEASURE , ---67
	GL_ACCOUNT , ---68
	GL_DEPT_ID , ---69
	ADJUSTMENT_USER_I , ---70 
	GL_AXE_VENDOR , ---71
	GL_PROJECT , ---72
	GL_AXE_LOC , ---73
	GL_CURRENCY_CD , ---74
	PS_AFFILIATE_BU , ---75
	CASH_AR50_COMMENTS , ---76
	VENDOR_ABBREV_C , ---77 
	QTY_COST_REASON , ---78 
	QTY_COST_REASON_CD , ---79 
	ACCT_DESC , ---80 
	ACCT_NBR , ---81 
	LOC_CODE , ---82 
	DEPT_CODE , ---83 
	GL_LOCATION , ---84 
	GL_VENDOR , ---85
	BUYER_CODE , ---86 
	GL_BUSINESS_UNIT , ---87
	GL_DEPARTMENT ,  ---88
	GL_VENDOR_NBR_FULL , ---89
	AFFILIATE , ---90
	ACCOUNTING_DATE , ---91
	RECEIVER_LINE_NBR , ---92
	VENDOR_PART_NBR , ---93
	ERROR_TYPE , ---94
	ERROR_CODE , ---95
	GL_LEGAL_ENTITY , ---96 
	GL_ACCT , ---97 
	GL_OPER_GRP , ---98 
	GL_DEPT , ---99 
	GL_SITE , ---100 
	GL_IC , ---101 
	GL_PROJECTS , ---102 
	GL_FUT_1 , ---103 
	GL_FUT_2 , ---104 
	SUBLEDGER_NBR , ---105
	BATCH_NBR , ---106
	ORDER_ID , ---107
	INVOICE_NBR , ---108
	PRODUCT_CLASS , ---109
	PART_NBR ,  ---110
	VENDOR_ITEM_NBR , ---111
	PO_NBR , ---112 
	MATCHING_KEY , ---113
	VENDOR_NAME , ---114
	HDR_SEQ_NBR , ---115 
	ITEM_NBR , ---116 
	SUBLEDGER_NAME , ---117
	LINE_UPDATED_BY , ---118
	VENDOR_STK_NBR , ---119
	LSI_LINE_DESCR , ---120
	CREATION_DATE , ---121
	LAST_UPDATE_DATE , ---122
	CREATED_BY , ---123
	LAST_UPDATED_BY , ---124
	LEG_COA , ---125 
	TARGET_COA , ---126 
	STATEMENT_ID , ---127
	GL_ALLCON_COMMENTS , ---128
	ATTRIBUTE6 , ---129
	ATTRIBUTE7 , ---130
	ATTRIBUTE8 , ---131
	ATTRIBUTE9 , ---132
	ATTRIBUTE10 , ---133
	ATTRIBUTE11 , ---134
	ATTRIBUTE12 , ---135
	ATTRIBUTE1 , ---136 
	ATTRIBUTE2 , ---137
	ATTRIBUTE3 , ---138
	ATTRIBUTE4 , ---139
	ATTRIBUTE5 ,---140
	DEFAULT_AMOUNT, --- 141
    ACC_AMOUNT,  --- 142 
    ACC_CURRENCY,  --- 143
    DEFAULT_CURRENCY,  --- 144 
    LEG_LOCATION_LN,  --- 145 
    LEG_ACCT,  --- 146 
    LEG_DEPT,  --- 147
    LOCATION_LN,  --- 148 
    LEG_VENDOR,  --- 149 
    TRD_PARTNER_NAME,  --- 150
    REASON_CODE,  --- 151
    TRANSACTION_NUMBER, --- 152 
    LEG_SEG_1_4,  --- 153 
    LEG_SEG_5_7,  --- 154 
    TRD_PARTNER_NBR, --- 155 
    LEG_ACCT_DESC,  --- 156 
	LEG_BU, --- 157 
    LEG_LOC, --- 158 
    LEG_AFFILIATE, --159
	PS_LOCATION,  ---160 
    AXE_VENDOR,  ---161
    LEG_LOC_SR,  ---162
    PRODUCT_CLASS_LN,  --163
	LEG_BU_LN, --164
    LEG_ACCOUNT, --165
    LEG_DEPARTMENT, --166
    LEG_AFFILIATE_LN, --167
    QUANTITY_DAI, --168
    VENDOR_PART_NBR_LN, --169
    PO_NBR_LN, --170
    LEG_PROJECT, --171
    LEG_DIVISION_LN, --172
	RECORD_TYPE --- 173
	
	)
    VALUES
   (
    p_batch_id,   ---1 
    wsc_mfinv_line_s1.NEXTVAL, ---2 
    lv_mfinv_line_copy_type(i).HEADER_ID,	---3 
    '-99999',	---4 
    lv_mfinv_line_copy_type(i).AMOUNT,---5  
    lv_mfinv_line_copy_type(i).AMOUNT_IN_CUST_CURR, ---6 
    lv_mfinv_line_copy_type(i).UNIT_PRICE, ---7
    lv_mfinv_line_copy_type(i).SHIPPED_QUANTITY, ---8
    lv_mfinv_line_copy_type(i).UOM_CNVRN_FACTOR, ---9
    lv_mfinv_line_copy_type(i).BILLED_QTY,---10
    lv_mfinv_line_copy_type(i).AVG_UNIT_COST,---11
    lv_mfinv_line_copy_type(i).STD_UNIT_COST,---12
    NULL,---13 
    NULL,---14 
    NULL,---15 
    NULL,---16 
    NULL,---17
    NULL,---18 
    NULL,---19 
    NULL,---20 
    NULL, --- 21
    NULL, --- 22
    NULL, --- 23
    lv_mfinv_line_copy_type(i).UOM_CONV_FACTOR,---24 
    NULL, --- 25
    NULL, --- 26
    NULL, --- 27
    NULL,---28 
    NULL,---29 
    NULL,---30 
    NULL,---31 
    NULL,---32 
    NULL,---33
    NULL,---34
    NULL,---35
    NULL, --- 36
    NULL,---37 
    NULL,---38 
    NULL,---39
    lv_mfinv_line_copy_type(i).PC_FLAG, ---40 
    NULL, ---41
    NULL,
    lv_mfinv_line_copy_type(i).DB_CR_FLAG, ---43 
    lv_mfinv_line_copy_type(i).INTERFACE_ID, ---44 
    lv_mfinv_line_copy_type(i).LINE_TYPE, ---45
    'INT', ---46 
    lv_mfinv_line_copy_type(i).LINE_NBR, ---47
    lv_mfinv_line_copy_type(i).LRD_SHIP_FROM, ---48 
    lv_mfinv_line_copy_type(i).UOM_C, ---49
    lv_mfinv_line_copy_type(i).INVOICE_CURRENCY, ---50
    lv_mfinv_line_copy_type(i).CUSTOMER_CURRENCY, ---51
    lv_mfinv_line_copy_type(i).GAAP_F, ---52 
    lv_mfinv_line_copy_type(i).GL_DIVISION, ---53
    NULL, ---54
    NULL, ---55
    NULL, ---56
    NULL, ---57
    NULL, ---58
    NULL, ---59
    NULL, ---60
    lv_mfinv_line_copy_type(i).LOCATION, ---61 
    lv_mfinv_line_copy_type(i).MIG_SIG, ---62 
    lv_mfinv_line_copy_type(i).BUSINESS_UNIT, ---63 
    lv_mfinv_line_copy_type(i).PAYMENT_CODE, ---64
    lv_mfinv_line_copy_type(i).VENDOR_NBR, ---65
    NULL, ---66
    NULL, ---67 
    lv_mfinv_line_copy_type(i).GL_ACCOUNT, ---68
    lv_mfinv_line_copy_type(i).GL_DEPT_ID, ---69
    NULL, ---70  
    lv_mfinv_line_copy_type(i).GL_AXE_VENDOR, ---71
    lv_mfinv_line_copy_type(i).GL_PROJECT, ---72
    lv_mfinv_line_copy_type(i).LOCATION, ---73
    lv_mfinv_line_copy_type(i).GL_CURRENCY_CD, ---74
    lv_mfinv_line_copy_type(i).PS_AFFILIATE_BU, ---75
    lv_mfinv_line_copy_type(i).CASH_AR50_COMMENTS, ---76
    lv_mfinv_line_copy_type(i).VENDOR_ABBREV_C,---77 
    NULL, ---78 
    NULL, ---79 
    NULL, ---80 
    NULL, ---81 
    NULL, ---82 
    NULL, ---83 
    NULL, ---84
    NULL, ---85 
    NULL, ---86 
    NULL, ---87
    NULL, ---88
    NULL, ---89
    NULL, ---90
    NULL, ---91 
    NULL, ---92 
    NULL, ---93 
    NULL, ---94
    NULL, ---95
    lv_mfinv_line_copy_type(i).GL_LEGAL_ENTITY , ---96 
	lv_mfinv_line_copy_type(i).GL_ACCT , ---97 
	lv_mfinv_line_copy_type(i).GL_OPER_GRP , ---98 
	lv_mfinv_line_copy_type(i).GL_DEPT , ---99 
	lv_mfinv_line_copy_type(i).GL_SITE , ---100 
	lv_mfinv_line_copy_type(i).GL_IC , ---101 
	lv_mfinv_line_copy_type(i).GL_PROJECTS , ---102 
	lv_mfinv_line_copy_type(i).GL_FUT_1 , ---103 
	lv_mfinv_line_copy_type(i).GL_FUT_2 , ---104 
    NULL, ---105
    NULL, ---106
    NULL, ---107
    lv_mfinv_line_copy_type(i).INVOICE_NBR, ---108
    lv_mfinv_line_copy_type(i).PRODUCT_CLASS, ---109 
    NULL, ---110
    NULL, ---111
    lv_mfinv_line_copy_type(i).PO_NBR, ---112
    NULL, ---113
    lv_mfinv_line_copy_type(i).VENDOR_NAME, ---114
    lv_mfinv_line_copy_type(i).HDR_SEQ_NBR, ---115 
    lv_mfinv_line_copy_type(i).ITEM_NBR, ---116 
    NULL, ---117
    NULL, ---118
    lv_mfinv_line_copy_type(i).VENDOR_STK_NBR, ---119
    lv_mfinv_line_copy_type(i).LSI_LINE_DESCR, ---120
    SYSDATE,---121
    SYSDATE, ---122
    'FIN_INT',  ---123
    'FIN_INT',  ---124
    lv_mfinv_line_copy_type(i).LEG_COA,  ---125  
    lv_mfinv_line_copy_type(i).TARGET_COA,  ---126  
    NULL,  ---127
    NULL,  ---128
    NULL,  ---129
    NULL,  ---130
    NULL,  ---131
    NULL,  ---132
    NULL,  ---133
    NULL,  ---134
    NULL,  ---135  
    NULL,  ---136
    NULL,  ---137
    NULL,  ---138
    NULL,  ---139
    NULL,  ---140
    NULL, ---141
    NULL,  ---142
    NULL,  ---143
    NULL,  ---144 
    NULL,  ---145
    lv_mfinv_line_copy_type(i).LEG_ACCT,  ---146 
    lv_mfinv_line_copy_type(i).LEG_DEPT,  ---147 
    NULL,  ---148
    lv_mfinv_line_copy_type(i).LEG_VENDOR,  ---149 
    NULL,  ---150
    NULL,  ---151
	lv_mfinv_line_copy_type(i).TRANSACTION_NUMBER, ---152
    lv_mfinv_line_copy_type(i).LEG_SEG_1_4,  ---153 
	lv_mfinv_line_copy_type(i).LEG_SEG_5_7, --- 154
    NULL,  ---155
    NULL,   ---156
	lv_mfinv_line_copy_type(i).LEG_BU, --- 157 
    lv_mfinv_line_copy_type(i).LEG_LOC, --- 158
    lv_mfinv_line_copy_type(i).LEG_AFFILIATE,  ---159
	NULL,   --160 
	NULL,   --161
	NULL,   -- 162
	NULL,   --163
	NULL,  ---164
    NULL,  ---165
    NULL,  ---166
    NULL,  ---167
    NULL,  ---168
    NULL,  ---169
    NULL,  ---170
    NULL,  ---171
    NULL,  ---172
	lv_mfinv_line_copy_type(i).RECORD_TYPE --- 173
   ); 
   END LOOP;
   CLOSE mfinv_invt_line_copy_data_cur;
   COMMIT;
   logging_insert ('MF INV INVT',p_batch_id,42.3,'MF INV - INVT Line Copy Procedure Insertion Completed',NULL,SYSDATE);
   
   ELSIF l_mfinv_subsystem IN ('AIIB','INTR') THEN
   ----------INSERT FOR AIIB AND INTR-------------
  -- logging_insert('MFINV AIIB/INTR', p_batch_id, 42.2, 'AIIB/INTR Line Copy Procedure Insertion Start', NULL,
               --       sysdate); 
    logging_insert('MF INV', p_batch_id, 42.2, 'MF INV' || ' ' || l_mfinv_subsystem || '-Line Copy Procedure Insertion Started', NULL,
                      sysdate);
   OPEN mfinv_aiib_intr_line_copy_data_cur(p_batch_id);
    LOOP
        FETCH mfinv_aiib_intr_line_copy_data_cur BULK COLLECT INTO lv_mfinv_line_copy_type_t LIMIT 400;
        EXIT WHEN lv_mfinv_line_copy_type_t.count = 0;
        FORALL i IN 1..lv_mfinv_line_copy_type_t.count
	INSERT INTO WSC_AHCS_MFINV_TXN_LINE_T
    (	
    BATCH_ID ,   --- 1
	LINE_ID ,   ---2 
	HEADER_ID ,  ---3 
	LINE_SEQ_NUMBER, ---4
	AMOUNT , ---5   
	AMOUNT_IN_CUST_CURR , ---6       
	UNIT_PRICE , ---7
	SHIPPED_QUANTITY , ---8
	UOM_CNVRN_FACTOR , ---9 
	BILLED_QTY , ---10
	AVG_UNIT_COST , ---11
	STD_UNIT_COST , ---12
	QTY_ON_HAND_BEFORE , ---13 
	ADJUSTMENT_QTY ,  ---14 
	QTY_ON_HAND_AFTER ,  ---15 
	CUR_COST_BEFORE , ---16 
	ADJ_COST_LOCAL , ---17   
	ADJ_COST_FOREIGN , ---18 
	FX_RATE , ---19 
	CUR_COST_AFTER , ---20 
	GL_AMOUNT_IN_LOC_CURR , ---21
	GL_AMNT_IN_FORIEGN_CURR , ---22
	QUANTITY , ---23 
	UOM_CONV_FACTOR , ---24
	UNIT_COST , ---25
	EXT_COST , ---26
	AVG_UNIT_COST_A , ---27 
	AMT_LOCAL_CURR , ---28
	AMT_FOREIGN_CURR , ---29
	RECEIVED_QTY , ---30
	RECEIVED_UNIT_COST , ---31
	PO_UNIT_COST , ---32
	TRANSACTION_AMOUNT , ---33
	FOREIGN_EX_RATE , ---34
	BASE_AMOUNT , ---35
	INVOICE_DATE , ---36
	RECEIPT_DATE , ---37
	LINE_UPDATED_DATE , ---38
	MATCHING_DATE , ---39
	PC_FLAG , ---40
	VENDOR_INDICATOR , ---41 
	CONTINENT, ---42
	DB_CR_FLAG , ---43 
	INTERFACE_ID , ---44 
	LINE_TYPE , ---45
	AMOUNT_TYPE , ---46 
	LINE_NBR , ---47
	LRD_SHIP_FROM , ---48
	UOM_C , ---49 
	INVOICE_CURRENCY , ---50
	CUSTOMER_CURRENCY , ---51
	GAAP_F , ---52 
	GL_DIVISION , ---53
	LOCAL_CURRENCY , ---54 
	FOREIGN_CURRENCY , ---55 
	PO_LINE_NBR , ---56
	LEG_DIVISION , ---57               
	TRANSACTION_CURR_CD , ---58
	BASE_CURR_CD , ---59
	TRANSACTION_TYPE , ---60
	LOCATION , ---61 
	MIG_SIG , ---62
	BUSINESS_UNIT , ---63
	PAYMENT_CODE , ---64
	VENDOR_NBR , ---65
	RECEIVER_NBR , ---66
	UNIT_OF_MEASURE , ---67
	GL_ACCOUNT , ---68
	GL_DEPT_ID , ---69
	ADJUSTMENT_USER_I , ---70 
	GL_AXE_VENDOR , ---71
	GL_PROJECT , ---72
	GL_AXE_LOC , ---73
	GL_CURRENCY_CD , ---74
	PS_AFFILIATE_BU , ---75
	CASH_AR50_COMMENTS , ---76
	VENDOR_ABBREV_C , ---77 
	QTY_COST_REASON , ---78 
	QTY_COST_REASON_CD , ---79 
	ACCT_DESC , ---80 
	ACCT_NBR , ---81 
	LOC_CODE , ---82 
	DEPT_CODE , ---83 
	GL_LOCATION , ---84 
	GL_VENDOR , ---85
	BUYER_CODE , ---86 
	GL_BUSINESS_UNIT , ---87
	GL_DEPARTMENT ,  ---88
	GL_VENDOR_NBR_FULL , ---89
	AFFILIATE , ---90
	ACCOUNTING_DATE , ---91
	RECEIVER_LINE_NBR , ---92
	VENDOR_PART_NBR , ---93
	ERROR_TYPE , ---94
	ERROR_CODE , ---95
	GL_LEGAL_ENTITY , ---96 
	GL_ACCT , ---97 
	GL_OPER_GRP , ---98 
	GL_DEPT , ---99 
	GL_SITE , ---100 
	GL_IC , ---101 
	GL_PROJECTS , ---102 
	GL_FUT_1 , ---103 
	GL_FUT_2 , ---104 
	SUBLEDGER_NBR , ---105
	BATCH_NBR , ---106
	ORDER_ID , ---107
	INVOICE_NBR , ---108
	PRODUCT_CLASS , ---109
	PART_NBR ,  ---110
	VENDOR_ITEM_NBR , ---111
	PO_NBR , ---112 
	MATCHING_KEY , ---113
	VENDOR_NAME , ---114
	HDR_SEQ_NBR , ---115 
	ITEM_NBR , ---116 
	SUBLEDGER_NAME , ---117
	LINE_UPDATED_BY , ---118
	VENDOR_STK_NBR , ---119
	LSI_LINE_DESCR , ---120
	CREATION_DATE , ---121
	LAST_UPDATE_DATE , ---122
	CREATED_BY , ---123
	LAST_UPDATED_BY , ---124
	LEG_COA , ---125 
	TARGET_COA , ---126 
	STATEMENT_ID , ---127
	GL_ALLCON_COMMENTS , ---128
	ATTRIBUTE6 , ---129
	ATTRIBUTE7 , ---130
	ATTRIBUTE8 , ---131
	ATTRIBUTE9 , ---132
	ATTRIBUTE10 , ---133
	ATTRIBUTE11 , ---134
	ATTRIBUTE12 , ---135
	ATTRIBUTE1 , ---136 
	ATTRIBUTE2 , ---137
	ATTRIBUTE3 , ---138
	ATTRIBUTE4 , ---139
	ATTRIBUTE5 ,---140
	DEFAULT_AMOUNT, --- 141
    ACC_AMOUNT,  --- 142 
    ACC_CURRENCY,  --- 143
    DEFAULT_CURRENCY,  --- 144 
    LEG_LOCATION_LN,  --- 145 
    LEG_ACCT,  --- 146 
    LEG_DEPT,  --- 147
    LOCATION_LN,  --- 148 
    LEG_VENDOR,  --- 149 
    TRD_PARTNER_NAME,  --- 150
    REASON_CODE,  --- 151
    TRANSACTION_NUMBER, --- 152 
    LEG_SEG_1_4,  --- 153 
    LEG_SEG_5_7,  --- 154 
    TRD_PARTNER_NBR, --- 155 
    LEG_ACCT_DESC,  --- 156 
	LEG_BU, --- 157 
    LEG_LOC, --- 158 
    LEG_AFFILIATE, --159
	PS_LOCATION,  ---160 
    AXE_VENDOR,  ---161
    LEG_LOC_SR,  ---162
    PRODUCT_CLASS_LN,  --163
	LEG_BU_LN, --164
    LEG_ACCOUNT, --165
    LEG_DEPARTMENT, --166
    LEG_AFFILIATE_LN, --167
    QUANTITY_DAI, --168
    VENDOR_PART_NBR_LN, --169
    PO_NBR_LN, --170
    LEG_PROJECT, --171
    LEG_DIVISION_LN, --172
	RECORD_TYPE --- 173
	
	)
    VALUES
   (
    p_batch_id,   ---1 
    wsc_mfinv_line_s1.NEXTVAL, ---2 
    lv_mfinv_line_copy_type_t(i).HEADER_ID,	---3 
    '-99999',	---4 
    lv_mfinv_line_copy_type_t(i).AMT,---5  
    lv_mfinv_line_copy_type_t(i).AMT_IN_CUST_CURR, ---6 
    lv_mfinv_line_copy_type_t(i).UNIT_PRICE, ---7
    lv_mfinv_line_copy_type_t(i).SHIPPED_QUANTITY, ---8
    lv_mfinv_line_copy_type_t(i).UOM_CNVRN_FACTOR, ---9
    lv_mfinv_line_copy_type_t(i).BILLED_QTY,---10
    lv_mfinv_line_copy_type_t(i).AVG_UNIT_COST,---11
    lv_mfinv_line_copy_type_t(i).STD_UNIT_COST,---12
    NULL,---13 
    NULL,---14 
    NULL,---15 
    NULL,---16 
    NULL,---17
    NULL,---18 
    NULL,---19 
    NULL,---20 
    NULL, --- 21
    NULL, --- 22
    NULL, --- 23
    lv_mfinv_line_copy_type_t(i).UOM_CONV_FACTOR,---24 
    NULL, --- 25
    NULL, --- 26
    NULL, --- 27
    NULL,---28 
    NULL,---29 
    NULL,---30 
    NULL,---31 
    NULL,---32 
    NULL,---33
    NULL,---34
    NULL,---35
    NULL, ---36
    NULL,---37 
    NULL,---38 
    NULL,---39
    lv_mfinv_line_copy_type_t(i).PC_FLAG, ---40 
    NULL, ---41
    NULL,
    lv_mfinv_line_copy_type_t(i).DB_CR_FLAG, ---43 
    lv_mfinv_line_copy_type_t(i).INTERFACE_ID, ---44 
    lv_mfinv_line_copy_type_t(i).LINE_TYPE, ---45
    'ICP', ---46 
    lv_mfinv_line_copy_type_t(i).LINE_NBR, ---47
    lv_mfinv_line_copy_type_t(i).LRD_SHIP_FROM, ---48 
    lv_mfinv_line_copy_type_t(i).UOM_C, ---49
    lv_mfinv_line_copy_type_t(i).INV_CURRENCY, ---50
    lv_mfinv_line_copy_type_t(i).CUST_CURRENCY, ---51
    lv_mfinv_line_copy_type_t(i).GAAP_F, ---52 
    lv_mfinv_line_copy_type_t(i).GL_DIVISION, ---53
    NULL, ---54
    NULL, ---55
    NULL, ---56
    NULL, ---57
    NULL, ---58
    NULL, ---59
    NULL, ---60
    lv_mfinv_line_copy_type_t(i).LOCATION, ---61 
    lv_mfinv_line_copy_type_t(i).MIG_SIG, ---62 
    lv_mfinv_line_copy_type_t(i).BUSINESS_UNIT, ---63 
    lv_mfinv_line_copy_type_t(i).PAYMENT_CODE, ---64
    lv_mfinv_line_copy_type_t(i).VENDOR_NBR, ---65
    NULL, ---66
    NULL, ---67 
    lv_mfinv_line_copy_type_t(i).GL_ACCOUNT, ---68
    lv_mfinv_line_copy_type_t(i).GL_DEPT_ID, ---69
    NULL, ---70  
    lv_mfinv_line_copy_type_t(i).GL_AXE_VENDOR, ---71
    lv_mfinv_line_copy_type_t(i).GL_PROJECT, ---72
    CASE
    WHEN lv_mfinv_line_copy_type_t(i).EMEA_FLAG = 'Y' 
	THEN lv_mfinv_line_copy_type_t(i).LOCATION
	ELSE lv_mfinv_line_copy_type_t(i).GL_DIV_HEADQTR_LOC
	END,--lv_mfinv_line_copy_type_t(i).LOCATION, ---73
    lv_mfinv_line_copy_type_t(i).GL_CURRENCY_CD, ---74
    lv_mfinv_line_copy_type_t(i).PS_AFFILIATE_BU, ---75
    lv_mfinv_line_copy_type_t(i).CASH_AR50_COMMENTS, ---76
    lv_mfinv_line_copy_type_t(i).VENDOR_ABBREV_C,---77 
    NULL, ---78 
    NULL, ---79 
    NULL, ---80 
    NULL, ---81 
    NULL, ---82 
    NULL, ---83 
    NULL, ---84
    NULL, ---85 
    NULL, ---86 
    NULL, ---87
    NULL, ---88
    NULL, ---89
    NULL, ---90
    NULL, ---91 
    NULL, ---92 
    NULL, ---93 
    NULL, ---94
    NULL, ---95
    lv_mfinv_line_copy_type_t(i).GL_LEGAL_ENTITY , ---96 
	lv_mfinv_line_copy_type_t(i).GL_ACCT , ---97 
	lv_mfinv_line_copy_type_t(i).GL_OPER_GRP , ---98 
	lv_mfinv_line_copy_type_t(i).GL_DEPT , ---99 
	lv_mfinv_line_copy_type_t(i).GL_SITE , ---100 
	lv_mfinv_line_copy_type_t(i).GL_IC , ---101 
	lv_mfinv_line_copy_type_t(i).GL_PROJECTS , ---102 
	lv_mfinv_line_copy_type_t(i).GL_FUT_1 , ---103 
	lv_mfinv_line_copy_type_t(i).GL_FUT_2 , ---104 
    NULL, ---105
    NULL, ---106
    NULL, ---107
    lv_mfinv_line_copy_type_t(i).INVOICE_NBR, ---108
    lv_mfinv_line_copy_type_t(i).PRODUCT_CLASS, ---109 
    NULL, ---110
    NULL, ---111
    lv_mfinv_line_copy_type_t(i).PO_NBR, ---112
    NULL, ---113
    lv_mfinv_line_copy_type_t(i).VENDOR_NAME, ---114
    lv_mfinv_line_copy_type_t(i).HDR_SEQ_NBR, ---115 
    lv_mfinv_line_copy_type_t(i).ITEM_NBR, ---116 
    NULL, ---117
    NULL, ---118
    lv_mfinv_line_copy_type_t(i).VENDOR_STK_NBR, ---119
    lv_mfinv_line_copy_type_t(i).LSI_LINE_DESCR, ---120
    SYSDATE,---121
    SYSDATE, ---122
    'FIN_INT',  ---123
    'FIN_INT',  ---124
    lv_mfinv_line_copy_type_t(i).LEG_COA,  ---125  
    lv_mfinv_line_copy_type_t(i).TARGET_COA,  ---126  
    NULL,  ---127
    NULL,  ---128
    NULL,  ---129
    NULL,  ---130
    NULL,  ---131
    NULL,  ---132
    NULL,  ---133
    NULL,  ---134
    NULL,  ---135  
    NULL,  ---136
    NULL,  ---137
    NULL,  ---138
    NULL,  ---139
    NULL,  ---140
    NULL, ---141
    NULL,  ---142
    NULL,  ---143
    NULL,  ---144 
    /*CASE
    WHEN lv_mfinv_line_copy_type_t(i).EMEA_FLAG = 'Y' 
	THEN lv_mfinv_line_copy_type_t(i).LOCATION_LN
	ELSE lv_mfinv_line_copy_type_t(i).GL_DIV_HEADQTR_LOC
	END, */
	lv_mfinv_line_copy_type_t(i).LOCATION_LN,---145 
    lv_mfinv_line_copy_type_t(i).LEG_ACCT,  ---146 
    lv_mfinv_line_copy_type_t(i).LEG_DEPT,  ---147 
    NULL,  ---148
    lv_mfinv_line_copy_type_t(i).LEG_VENDOR,  ---149 
    NULL,  ---150
    NULL,  ---151
	lv_mfinv_line_copy_type_t(i).TRANSACTION_NUMBER, ---152
    lv_mfinv_line_copy_type_t(i).LEG_SEG_1_4,  ---153 
	lv_mfinv_line_copy_type_t(i).LEG_SEG_5_7, --- 154
    NULL,  ---155
    NULL,   ---156
	lv_mfinv_line_copy_type_t(i).LEG_BU, --- 157 
    lv_mfinv_line_copy_type_t(i).LEG_LOC, --- 158
    lv_mfinv_line_copy_type_t(i).LEG_AFFILIATE,  ---159
	NULL,   --160 
	NULL,   --161
	NULL,   -- 162
	NULL,   --163
	NULL,  ---164
    NULL,  ---165
    NULL,  ---166
    NULL,  ---167
    NULL,  ---168
    NULL,  ---169
    NULL,  ---170
    NULL,  ---171
    NULL,  ---172
	lv_mfinv_line_copy_type_t(i).RECORD_TYPE --- 173
   ); 
   END LOOP;
   CLOSE mfinv_aiib_intr_line_copy_data_cur;
   COMMIT;
    --logging_insert ('MF INV AIIB/INTR',p_batch_id,104,'AIIB/INTR Line Copy Procedure Insertion Ends',NULL,SYSDATE);
	logging_insert ('MF INV',p_batch_id,42.3,'MF INV' || ' ' || l_mfinv_subsystem || '-Line Copy Procedure Insertion Completed',NULL,SYSDATE);
 END IF;
   
BEGIN
	--logging_insert('MF INV', p_batch_id, 105, 'MF INV - Inserting Records for Copy Lines In Status Table Started', NULL,SYSDATE);
	logging_insert('MF INV', p_batch_id, 42.4, 'MF INV' || ' ' || l_mfinv_subsystem || '-Inserting Records for Copy Lines In Status Table Started', NULL,SYSDATE);
	INSERT INTO wsc_ahcs_int_status_t (
            header_id,
            line_id,
            application,
            file_name,
            batch_id,
            status, 
            cr_dr_indicator,
            currency,
            value,
            source_coa,
            legacy_header_id,
            legacy_line_number,
            attribute3,
			attribute2, 
            attribute11,
            interface_id,
            created_by,
            created_date,
            last_updated_by,
            last_updated_date,
			ledger_name
        )
            SELECT
                line.header_id,
                line.line_id,
                'MF INV',
                hdr.file_name,
                p_batch_id,
                'TRANSFORM_SUCCESS',
               nvl(line.db_cr_flag,
                    CASE
                        WHEN hdr.interface_id = 'AIIB' and line.amount >= 0 THEN 'CR'
						WHEN hdr.interface_id = 'AIIB' and line.amount < 0 THEN 'DR'
						WHEN line.amount >= 0 THEN 'DR'
						WHEN line.amount < 0  THEN 'CR'
				    END
                 ),-- line.db_cr_flag,
                line.invoice_currency,
                line.amount,
                line.leg_coa,
                line.hdr_seq_nbr,
                line.line_seq_number,
                line.transaction_number,  
                'TRANSFORM_SUCCESS',				
                hdr.account_date,
                line.interface_id,
                'FIN_INT',
                SYSDATE,
                'FIN_INT',
                SYSDATE,
				hdr.ledger_name
            FROM
                WSC_AHCS_MFINV_TXN_LINE_T    line,
                WSC_AHCS_MFINV_TXN_HEADER_T  hdr
            WHERE
                    line.batch_id = p_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id
				and line.line_seq_number='-99999'
				and not exists ( select 1 from wsc_ahcs_int_status_t s where s.header_id=line.header_id and s.batch_id =line.batch_id and 
				s.line_id=line.line_id);
       COMMIT;  
	   -- logging_insert ('MF INV',p_batch_id,106,'MF INV - Inserting Records for Copy Lines In Status Table Completed',NULL,SYSDATE);
	    logging_insert ('MF INV',p_batch_id,42.5,'MF INV' || ' ' || l_mfinv_subsystem || '- Inserting Records for Copy Lines In Status Table Completed',NULL,SYSDATE);
	   EXCEPTION
        --WHEN OTHERS THEN
		WHEN OTHERS THEN
         err_msg := substr(sqlerrm, 1, 200);
        logging_insert('MF INV', p_batch_id, 42.6, 'Error in Cpy Line Procedure', err_msg,sysdate); 
            wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT222'
                                                    || '_'
                                                    || 'MFINV',
                                                    'MF_INV',
                                                    sqlerrm);
	END; 
END wsc_ahcs_mfinv_invt_line_copy_p;


    /*** Functions Declarations***/	
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
END wsc_ahcs_mfinv_validation_transformation_pkg;
/