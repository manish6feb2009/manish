create or replace PACKAGE BODY wsc_cres_pkg AS

    PROCEDURE wsc_cres_insert_data_temp_p (
        p_wsc_cres_stg IN wsc_mfar_tmp_t_type_table
    ) AS
    BEGIN
        FORALL i IN 1..p_wsc_cres_stg.count
            INSERT INTO wsc_ahcs_cres_txn_tmp_t (
                batch_id,
                rice_id,
                data_string
            ) VALUES (
                p_wsc_cres_stg(i).batch_id,
                p_wsc_cres_stg(i).rice_id,
                REPLACE(p_wsc_cres_stg(i).data_string,'"',' ')
            );

    END wsc_cres_insert_data_temp_p;

    PROCEDURE wsc_process_mfap_temp_to_header_line_p (
        p_batch_id_t       NUMBER,
        p_batch_id         NUMBER,
        p_application_name IN VARCHAR2,
        p_file_name        IN VARCHAR2,
        p_error_flag       OUT VARCHAR2
    ) IS

        err_msg                  VARCHAR2(4000);
        v_stage                  VARCHAR2(200);
        l_system                 VARCHAR2(10);
---- MF AP HEADER CURSORS ------
        CURSOR cres_stg_hdr_ap_data_cur (
            p_batch_id NUMBER
        ) IS
        SELECT
            *
        FROM
            wsc_ahcs_cres_txn_tmp_t
        WHERE
                batch_id = p_batch_id_t
            AND TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 1, NULL,
                                   1)) = 'H'
            AND ( TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 17, NULL,
                                     1)) = '2'
                  OR TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 17, NULL,
                                        1)) = '0' );
---- MF AP LINE CURSORS ------
        CURSOR cres_stg_line_ap_data_cur (
            p_batch_id NUMBER
        ) IS
        SELECT
            *
        FROM
            wsc_ahcs_cres_txn_tmp_t
        WHERE
                batch_id = p_batch_id_t
            AND TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 1, NULL,
                                   1)) = 'D'
            AND ( TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 29, NULL,
                                     1)) = '2'
                  OR TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 29, NULL,
                                        1)) = '0' );
                                        
--- MF AP LINE CURSOR VARIABLES---
        TYPE cres_stg_hdr_ap_type IS
            TABLE OF cres_stg_hdr_ap_data_cur%rowtype;
        lv_cres_stg_ap_hdr_type  cres_stg_hdr_ap_type;
        TYPE cres_stg_line_ap_type IS
            TABLE OF cres_stg_line_ap_data_cur%rowtype;
        lv_cres_stg_ap_line_type cres_stg_line_ap_type;
    BEGIN
    --initialise p_error_flag with 0
        p_error_flag := '0';
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

        dbms_output.put_line('MF AP Header insertion begin');
        logging_insert('Cresus_MF AP', p_batch_id, 2, 'STAGE TABLE DATA TO HEADER TABLE DATA - START', NULL,
                      sysdate);
        OPEN cres_stg_hdr_ap_data_cur(p_batch_id);
        LOOP
            FETCH cres_stg_hdr_ap_data_cur
            BULK COLLECT INTO lv_cres_stg_ap_hdr_type LIMIT 4000;
            EXIT WHEN lv_cres_stg_ap_hdr_type.count = 0;
            FORALL i IN 1..lv_cres_stg_ap_hdr_type.count
                INSERT INTO wsc_ahcs_mfap_txn_header_t (
                    header_id,
                    batch_id,
                    transaction_type,
                    transaction_date,
                    transaction_number,
                    record_type,
                    hdr_seq_nbr,
                    interface_id,
                    statement_id,
                    business_unit,
                    transref,
                    account_currency,
                    statement_amount,
                    continent,
                    statement_date,
                    statement_descr,
                    statement_upd_by,
                    statement_upd_date,
                    accounting_date,
                    posting_period,
                    posting_year,
                    attribute6,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date
                ) VALUES (
                    wsc_mfap_header_t_s1.NEXTVAL,
                    p_batch_id,
                    TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL,
                                               1)), 'mm/dd/yyyy'),
                    substr(TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                              1)), 1, 3) 
                    || TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                          1)) ,
                    TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL,
                                       1)),
                    to_number(TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL,
                                                 1))),
                    TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL, 1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL,
                                               1)), 'mm/dd/yyyy'),
                    TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL,
                                               1)), 'mm/dd/yyyy'),
--                    to_char(to_date(TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL,
                                               1)), 'mm/dd/yyyy'),
                    TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL,
                                       1)),
                    p_batch_id_t,
                    'FIN_INT',
                    sysdate,
                    'FIN_INT',
                    sysdate
                );

        END LOOP;

        logging_insert('Cresus_MF AP', p_batch_id, 3, 'STAGE TABLE DATA TO HEADER TABLE DATA - END', NULL,
                      sysdate);
        COMMIT;
        dbms_output.put_line('MF AP line insertion Begin');
        logging_insert('Cresus_MF AP', p_batch_id, 4, 'STAGE TABLE DATA TO LINE TABLE DATA - START', NULL,
                      sysdate);
        OPEN cres_stg_line_ap_data_cur(p_batch_id);
        LOOP
            FETCH cres_stg_line_ap_data_cur
            BULK COLLECT INTO lv_cres_stg_ap_line_type LIMIT 4000;
            EXIT WHEN lv_cres_stg_ap_line_type.count = 0;
            FORALL i IN 1..lv_cres_stg_ap_line_type.count
                INSERT INTO wsc_ahcs_mfap_txn_line_t (
                    line_id,
                    batch_id,
                    transaction_number,
                    record_type,
                    hdr_seq_nbr,
                    interface_id,
                    statement_id,
                    line_seq_number,
                    leg_bu,
                    leg_acct, -- to store leg_account value for cresus
                    gl_account_nbr,
                    leg_loc,
                    leg_dept,
                    leg_vendor,
                    vendor,
                    leg_affiliate,
                    transaction_curr_cd,
                    transaction_amount,
                    foreign_ex_rate,
                    base_curr_cd,
                    base_amount,
                    axe_division_cd,
                    subledger_nbr,
                    subledger_name,
                    batch_nbr,
                    invoice_nbr,
                    invoice_date,
                    gl_allcon_comments,
                    updated_by,
                    updated_date,
                    matching_key,
                    matching_date,
                    line_type,
                    transaction_type,
                    order_id,
                    db_cr_flag,
                    leg_coa,
                    leg_seg_1_4,
                    leg_seg_5_7,
                    attribute3, --STATEMT_ID_SR
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date
                ) VALUES (
                    wsc_mfap_line_s1.NEXTVAL,
                    p_batch_id,
                    substr(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                              1)), 1, 3)
                    || TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                          1)) ,  --transaction_number
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                       1)),  --interface_id
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL,
                                       1)), --statement_id
                    to_number(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL,
                                                 1))),  --line_seq_number
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL,
                                       1)), --LEG_BU
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL,
                                       1)),  --GL_ACCOUNT_NBR value storing in LEG_ACCT
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL,
                                       1)),  --GL_ACCOUNT_NBR
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL,
                                       1)),  --LEG_LOC
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL,
                                       1)), --LEG_DEPT
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL,
                                       1)),  --VENDOR value storing in LEG_VENDOR
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL,
                                       1)),  --VENDOR 
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL,
                                       1)),  --LEG_AFFILIATE
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL,
                                       1)),  --transaction_curr_cd
                    to_number(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL,
                                                 1))),  --transaction_amount
                    to_number(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL,
                                                 1))),  --foreign_ex_rate
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL,
                                       1)),  --base_curr_cd
                    to_number(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL,
                                                 1))),  --base_amount
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL,
                                               1)), 'mm/dd/yyyy'),
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL,
                                               1)), 'mm/dd/yyyy'),
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL, 1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL,
                                               1)), 'mm/dd/yyyy'),
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 29, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 30, NULL,
                                       1)),
                        CASE
                            WHEN to_number(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL,
                                                              1))) >= 0 THEN
                                'DR'
                            WHEN to_number(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL,
                                                              1))) < 0  THEN
                                'CR'
                        END,
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL,
                                       1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL,
                                          1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL,
                                          1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL,
                                          1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL,
                                          1))
                    || '.'
                    || nvl(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL,
                                              1)), '00000'),
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL,
                                       1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL,
                                          1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL,
                                          1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL,
                                          1)),
                    TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL,
                                       1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL,
                                          1)),
                 replace(substr(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL,
                                       1)), 14, 8), '-')
                    || substr(TRIM(regexp_substr(lv_cres_stg_ap_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL,
                                       1)), 22),
                    'FIN_INT',
                    sysdate,
                    'FIN_INT',
                    sysdate
                );

        END LOOP;

        COMMIT;
        logging_insert('Cresus_MF AP', p_batch_id, 5, 'STAGE TABLE DATA TO LINE TABLE DATA - END', NULL,
                      sysdate);
--update header_id from mfap header table to line table----

        logging_insert('Cresus_MF AP', p_batch_id, 6, 'Updating MF AP Line table with header id starts', NULL,
                      sysdate);
        UPDATE wsc_ahcs_mfap_txn_line_t line
        SET
            header_id = (
                SELECT /*+ index(hdr WSC_AHCS_MFAP_TXN_HEADER_HDR_SEQ_NBR_I) */
                    hdr.header_id
                FROM
                    wsc_ahcs_mfap_txn_header_t hdr
                WHERE
                        line.hdr_seq_nbr = hdr.hdr_seq_nbr
                    AND line.batch_id = hdr.batch_id
            )
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        logging_insert('Cresus_MF AP', p_batch_id, 7, 'Updating MF AP Line table with header id ends', NULL,
                      sysdate);
        logging_insert('Cresus_MF AP', p_batch_id, 8, 'Inserting records in status table starts', NULL,
                      sysdate);
--inserting the records in status table---
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
            attribute11,
            interface_id,
            created_by,
            created_date,
            last_updated_by,
            last_updated_date
        )
            SELECT
                line.header_id,
                line.line_id,
                p_application_name,
                p_file_name,
                p_batch_id,
                'NEW',
                line.db_cr_flag,
                line.base_curr_cd,
                line.base_amount,
                line.leg_coa,
                line.hdr_seq_nbr,
                line.line_seq_number,
                line.transaction_number,
                hdr.accounting_date,
                line.interface_id,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
                wsc_ahcs_mfap_txn_line_t   line,
                wsc_ahcs_mfap_txn_header_t hdr
            WHERE
                    line.batch_id = p_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id;

        COMMIT;
        logging_insert('Cresus_MF AP', p_batch_id, 9, 'Inserting records in status table ends', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            p_error_flag := '1';
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('Cresus_MF AP', p_batch_id, 9.1, 'Error While updating Line table with Header ID/inserting data in status table',
            sqlerrm,
                          sysdate);
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT240'
                                                                 || '_'
                                                                 || l_system, 'MF AP', err_msg);

    END wsc_process_mfap_temp_to_header_line_p;

    PROCEDURE wsc_process_mfar_temp_to_header_line_p (
        p_batch_id_t       IN NUMBER,
        p_batch_id         IN NUMBER,
        p_application_name IN VARCHAR2,
        p_file_name        IN VARCHAR2,
        p_error_flag       OUT VARCHAR2
    ) IS

        err_msg                  VARCHAR2(4000);
        v_stage                  VARCHAR2(200);
        l_system                 VARCHAR2(10);
        CURSOR cres_stg_hdr_ar_data_cur (
            p_batch_id NUMBER
        ) IS
        SELECT
            *
        FROM
            wsc_ahcs_cres_txn_tmp_t
        WHERE
                batch_id = p_batch_id_t
            AND TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 1, NULL,
                                   1)) = 'H'
            AND TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 17, NULL,
                                   1)) = '1';

        CURSOR cres_stg_line_ar_data_cur (
            p_batch_id NUMBER
        ) IS
        SELECT
            *
        FROM
            wsc_ahcs_cres_txn_tmp_t
        WHERE
                batch_id = p_batch_id_t
            AND TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 1, NULL,
                                   1)) = 'D'
            AND TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 29, NULL,
                                   1)) = '1';

        TYPE cres_stg_hdr_ar_type IS
            TABLE OF cres_stg_hdr_ar_data_cur%rowtype;
        TYPE cres_stg_line_ar_type IS
            TABLE OF cres_stg_line_ar_data_cur%rowtype;
        lv_cres_stg_ar_hdr_type  cres_stg_hdr_ar_type;
        lv_cres_stg_ar_line_type cres_stg_line_ar_type;
    BEGIN
        logging_insert('Cresus_MF AR', p_batch_id, 2, 'Data split insertion from mfar stage to mfar hdr begins', NULL,
                      sysdate);
        p_error_flag := '0';
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

        dbms_output.put_line('AR Header insertion Begin');
        OPEN cres_stg_hdr_ar_data_cur(p_batch_id);
        LOOP
            FETCH cres_stg_hdr_ar_data_cur
            BULK COLLECT INTO lv_cres_stg_ar_hdr_type LIMIT 4000;
            EXIT WHEN lv_cres_stg_ar_hdr_type.count = 0;
            FORALL i IN 1..lv_cres_stg_ar_hdr_type.count
                INSERT INTO wsc_ahcs_mfar_txn_header_t (
                    header_id,
                    batch_id,
                    transaction_type,
                    transaction_date,
                    transaction_number,
                    record_type,
                    hdr_seq_nbr,
                    interface_id,
                    statement_id,
                    business_unit,
                    trans_ref,
                    invoice_currency,
                    statement_amount,
                    continent,
                    statement_date,
                    interface_desc_en,
                    statement_upd_by,
                    statement_upd_date,
                    account_date,
                    posting_period,
                    posting_year,
                    attribute6,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date
                ) VALUES (
                    wsc_mfar_header_s1.NEXTVAL,
                    p_batch_id,
                    TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL,
                                               1)), 'mm/dd/yyyy'),
                    substr(TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                              1)), 1, 3)
                    || TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                          1))  ,
                    TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL,
                                       1)), 
                    TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL,
                                       1)),
                    to_number(TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL,
                                                 1))),
                    TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL,
                                               1)), 'mm/dd/yyyy'),
                    TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL,
                                               1)), 'mm/dd/yyyy'),                                    
--                    to_char(to_date(TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL,
                                               1)), 'mm/dd/yyyy'),
                    TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL,
                                       1)),
                    p_batch_id_t,
                    'FIN_INT',
                    sysdate,
                    'FIN_INT',
                    sysdate
                );

        END LOOP;

        COMMIT;
        logging_insert('Cresus_MF AR', p_batch_id, 3, 'Data split insertion from mfar stage to mfar hdr ends and line begins', NULL,
                      sysdate);
-- AR LINE TABLE INSERTION FROM CRESUS---
        dbms_output.put_line('AR line insertion begin');
        OPEN cres_stg_line_ar_data_cur(p_batch_id);
        LOOP
            FETCH cres_stg_line_ar_data_cur
            BULK COLLECT INTO lv_cres_stg_ar_line_type LIMIT 4000;
            EXIT WHEN lv_cres_stg_ar_line_type.count = 0;
            FORALL i IN 1..lv_cres_stg_ar_line_type.count
                INSERT INTO wsc_ahcs_mfar_txn_line_t (
                    line_id,
                    batch_id,
                    transaction_number,
                    record_type,
                    hdr_seq_nbr,
                    interface_id,
                    statement_id,
                    line_seq_number,
                    leg_bu,
                    leg_acct,
                    leg_loc,
                    leg_dept,
                    leg_vendor,
                    leg_affiliate,
                    transaction_curr_cd,
                    transaction_amount,
                    foreign_ex_rate,
                    base_curr_cd,
                    base_amount,
                    leg_division,
                    subledger_nbr,
                    subledger_name,
                    batch_nbr,
                    invoice_nbr,
                    invoice_date,
                    gl_allcon_comments,
                    line_updated_by,
                    line_updated_date,
                    matching_key,
                    matching_date,
                    line_type,
                    transaction_type,
                    order_id,
                    db_cr_flag,
                    leg_coa,
                    leg_seg_1_4,
                    leg_seg_5_7,
                    leg_loc_sr,
                    attribute3,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date
                ) VALUES (
                    wsc_mfar_line_s1.NEXTVAL,
                    p_batch_id,
                    substr(TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                              1)), 1, 3)
                    || TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                          1)) ,
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL,
                                       1)),
                    to_number(TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL,
                                                 1))),
                    to_number(TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL,
                                                 1))),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL,
                                       1)),
                    to_number(TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL,
                                                 1))),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL,
                                               1)), 'mm/dd/yyyy'),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL,
                                               1)), 'mm/dd/yyyy'),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL,
                                               1)), 'mm/dd/yyyy'),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 29, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 30, NULL,
                                       1)),
                        CASE
                            WHEN to_number(TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL,
                                                              1))) >= 0 THEN
                                'DR'
                            WHEN to_number(TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL,
                                                              1))) < 0  THEN
                                'CR'
                        END,
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL,
                                       1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL,
                                          1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL,
                                          1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL,
                                          1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL,
                                          1))
                    || '.'
                    || nvl(TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL,
                                              1)), '00000'),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL,
                                       1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL,
                                          1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL,
                                          1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL,
                                          1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL,
                                       1))
                    || '.'
                    || TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL,
                                          1)),
                    TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL,
                                              1)),
                    replace(substr(TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL,
                                                      1)), 14, 8), '-')
                    || substr(TRIM(regexp_substr(lv_cres_stg_ar_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL,
                                                 1)), 22),
                    'FIN_INT',
                    sysdate,
                    'FIN_INT',
                    sysdate
                );

        END LOOP;

        COMMIT;
        logging_insert('Cresus_MF AR', p_batch_id, 4, 'Data split insertion from mfar stage to mfar line ends', NULL,
                      sysdate);
        logging_insert('Cresus_MF AR', p_batch_id, 5, 'status table insert and header to line field insertion begins', NULL,
                      sysdate); 
--update header_id from mfar header table to line table----
        logging_insert('Cresus_MF AR', p_batch_id, 6, 'Update mfar line table fields from header table begins', NULL,
                      sysdate);
        UPDATE wsc_ahcs_mfar_txn_line_t line
        SET
            header_id = (
                SELECT /*+ index(hdr WSC_AHCS_MFAR_TXN_HEADER_HDR_SEQ_NBR_I) */
                    hdr.header_id
                FROM
                    wsc_ahcs_mfar_txn_header_t hdr
                WHERE
                        line.hdr_seq_nbr = hdr.hdr_seq_nbr
                    AND line.batch_id = hdr.batch_id
            )
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        logging_insert('Cresus_MF AR', p_batch_id, 7, 'Update mfar line table fields from header table ends', NULL,
                      sysdate);
        logging_insert('Cresus_MF AR', p_batch_id, 8, 'Inserting records in status table begins', NULL,
                      sysdate);
--inserting the records in status table---
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
            attribute11,
            interface_id,
            created_by,
            created_date,
            last_updated_by,
            last_updated_date
        )
            SELECT
                line.header_id,
                line.line_id,
                p_application_name,
                p_file_name,
                p_batch_id,
                'NEW',
                line.db_cr_flag,
                line.base_curr_cd,
                line.base_amount,
                line.leg_coa,
                line.hdr_seq_nbr,
                line.line_seq_number,
                line.transaction_number,
                hdr.account_date,
                line.interface_id,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
                wsc_ahcs_mfar_txn_line_t   line,
                wsc_ahcs_mfar_txn_header_t hdr
            WHERE
                    line.batch_id = p_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id;

        COMMIT;
        logging_insert('Cresus_MF AR', p_batch_id, 9, 'Inserting records in status table ends', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            p_error_flag := '1';
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('Cresus_MF AR', p_batch_id, 9.1, 'Error While updating Line table with Header ID/inserting data in status table',
            sqlerrm,
                          sysdate);
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT240'
                                                                 || '_'
                                                                 || l_system, 'MF AR', err_msg);

    END wsc_process_mfar_temp_to_header_line_p;

    PROCEDURE wsc_mfap_async_process_update_validate_transform_p (
        p_batch_id_t       NUMBER,
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    ) IS
        err_msg VARCHAR2(4000);
    BEGIN
        logging_insert('Cresus_MF AP', p_batch_id, 1, 'Starts ASYNC DB Scheduler job for Cresus_MF AP', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        dbms_scheduler.create_job(job_name => 'INVOKE_WSC_PROCESS_MFAP_TEMP_TO_HEADER_LINE_P' || p_batch_id, job_type => 'PLSQL_BLOCK',
        job_action => '
                                 DECLARE
                                    p_error_flag VARCHAR2(2);
                                 BEGIN                                
         WSC_CRES_PKG.wsc_process_mfap_temp_to_header_line_p('
                                                                                                                                      ||
                                                                                                                                      p_batch_id_t
                                                                                                                                      ||
                                                                                                                                      ','
                                                                                                                                      ||
                                                                                                                                      p_batch_id
                                                                                                                                      ||
                                                                                                                                      ','''
                                                                                                                                      ||
                                                                                                                                      p_application_name
                                                                                                                                      ||
                                                                                                                                      ''','''
                                                                                                                                      ||
                                                                                                                                      p_file_name
                                                                                                                                      ||
                                                                                                                                      ''',
                                                p_error_flag
                                                );
        if p_error_flag = '
                                                                                                                                      ||
                                                                                                                                      '''0'''
                                                                                                                                      ||
                                                                                                                                      ' then                                   
         wsc_ahcs_mfap_validation_transformation_pkg.cresus_data_validation('
                                                                                                                                      ||
                                                                                                                                      p_batch_id
                                                                                                                                      ||
                                                                                                                                      ');
                                               
          end if;                                   
       END;', enabled => true, auto_drop => true,
                                 comments => 'Async steps to split the data from temp table and insert into header and line tables. Also, update line table, insert into WSC_AHCS_INT_STATUS_T and call Validation and Transformation procedure');

        logging_insert('Cresus_MF AP', p_batch_id, 10, 'End Async', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('Cresus_MF AP', p_batch_id, 1.1, 'Error in Async DB Proc', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            COMMIT;
    END wsc_mfap_async_process_update_validate_transform_p;

    PROCEDURE wsc_mfar_async_process_update_validate_transform_p (
        p_batch_id_t       NUMBER,
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    ) IS
        err_msg VARCHAR2(4000);
    BEGIN
        logging_insert('Cresus_MF AR', p_batch_id, 1, 'Async Begins', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        dbms_scheduler.create_job(job_name => 'INVOKE_WSC_PROCESS_MFAR_TEMP_TO_HEADER_LINE_P' || p_batch_id, job_type => 'PLSQL_BLOCK',
        job_action => '
                                 DECLARE
                                    p_error_flag VARCHAR2(2);
                                 BEGIN                                
         WSC_CRES_PKG.wsc_process_mfar_temp_to_header_line_p('
                                                                                                                                      ||
                                                                                                                                      p_batch_id_t
                                                                                                                                      ||
                                                                                                                                      ','
                                                                                                                                      ||
                                                                                                                                      p_batch_id
                                                                                                                                      ||
                                                                                                                                      ','''
                                                                                                                                      ||
                                                                                                                                      p_application_name
                                                                                                                                      ||
                                                                                                                                      ''','''
                                                                                                                                      ||
                                                                                                                                      p_file_name
                                                                                                                                      ||
                                                                                                                                      ''',
                                                p_error_flag
                                                );
        if p_error_flag = '
                                                                                                                                      ||
                                                                                                                                      '''0'''
                                                                                                                                      ||
                                                                                                                                      ' then                                   
         wsc_ahcs_mfar_validation_transformation_pkg.cresus_data_validation('
                                                                                                                                      ||
                                                                                                                                      p_batch_id
                                                                                                                                      ||
                                                                                                                                      ');
                                               
          end if;                                   
       END;', enabled => true, auto_drop => true,
                                 comments => 'Async steps to split the data from temp table and insert into header and line tables. Also, update line table, insert into WSC_AHCS_INT_STATUS_T and call Validation and Transformation procedure');

    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('Cresus_MF AR', p_batch_id, 1.1, 'Error in Async DB Proc', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            COMMIT;
    END wsc_mfar_async_process_update_validate_transform_p;

END wsc_cres_pkg;
/