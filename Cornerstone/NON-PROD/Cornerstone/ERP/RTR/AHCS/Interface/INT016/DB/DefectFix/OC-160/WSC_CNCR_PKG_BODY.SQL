create or replace PACKAGE BODY wsc_cncr_pkg AS

    PROCEDURE wsc_cncr_insert_data_temp_p (
        in_wsc_concur_stage IN wsc_cncr_tmp_t_type_table
    ) AS
    BEGIN
        FORALL i IN 1..in_wsc_concur_stage.count
            INSERT INTO wsc_ahcs_cncr_txn_tmp_t (
                batch_id,
                rice_id,
                data_string
            ) VALUES (
                in_wsc_concur_stage(i).batch_id,
                in_wsc_concur_stage(i).rice_id,
                in_wsc_concur_stage(i).data_string
            );

    END wsc_cncr_insert_data_temp_p;

    PROCEDURE wsc_process_cncr_temp_to_header_line_p (
        p_batch_id         IN NUMBER,
        p_application_name IN VARCHAR2,
        p_file_name        IN VARCHAR2,
        p_error_flag       OUT VARCHAR2
    ) IS

        err_msg                     VARCHAR2(4000);
        v_stage                     VARCHAR2(200);
        l_system                    VARCHAR2(200);
        lv_offset_acct              VARCHAR2(50);
        CURSOR cncr_stg_hdr_data_cur (
            p_batch_id NUMBER
        ) IS
        SELECT DISTINCT
            a.transaction_number             transaction_number,
            a.src_batch_id                   src_batch_id,
            a.report_payment_processing_date report_payment_date,
            a.report_group_id_code           report_group_id
        FROM
            wsc_ahcs_cncr_txn_line_t a
 --           wsc_ahcs_cncr_txn_line_t b
        WHERE
--                b.report_group_id_code = a.report_org_unit_1
--            AND a.batch_id = b.batch_id
            a.batch_id = p_batch_id;

        CURSOR cncr_stg_line_data_cur (
            p_batch_id NUMBER
        ) IS
        SELECT
            *
        FROM
            wsc_ahcs_cncr_txn_tmp_t
        WHERE
                batch_id = p_batch_id
            AND regexp_substr(data_string, '([^|]*)(\||$)', 1, 1, NULL,
                              1) = 'DETAIL'
            AND ( regexp_substr(data_string, '([^|]*)(\||$)', 1, 35, NULL,
                                1) NOT IN (SELECT MEANING   -- Added this SELECT Clause for OC-160 changes on 09/07 -- Deloitte AMS
											FROM wsc_ahcs_cncr_lookup_t lookup 
											WHERE lookup.lookup_type = 'WSC_CONCR_LE_LOOKUP'
											AND lookup.ENABLED = 'Y'
											AND TRUNC(SYSDATE) BETWEEN TRUNC(lookup.EFFECTIVE_START_DATE) AND TRUNC(NVL(lookup.EFFECTIVE_END_DATE,SYSDATE))
											)
                  OR regexp_substr(data_string, '([^|]*)(\||$)', 1, 35, NULL,
                                   1) IS NULL );

        CURSOR cncr_stg_hdr_split_data_cur (
            p_batch_id NUMBER
        ) IS
        SELECT DISTINCT
            y.transaction_number,
            y.src_batch_id,
       --     y.batch_date,
            y.report_payment_processing_date,
            y.report_org_unit_1,
            y.report_group_id_code
        FROM
            (
                SELECT
                    transaction_number,
                    report_org_unit_1,
                    report_group_id_code
                FROM
                    wsc_ahcs_cncr_txn_line_t
                WHERE
                    batch_id = p_batch_id
                GROUP BY
                    transaction_number,
                    report_org_unit_1,
                    report_group_id_code
                HAVING
                    report_group_id_code != report_org_unit_1
            )                        s,
            wsc_ahcs_cncr_txn_line_t y
        WHERE
                y.transaction_number = s.transaction_number
            AND y.batch_id = p_batch_id
            AND y.src_system <> 'WESCO';

        CURSOR cncr_stg_line_split_data_cur (
            p_batch_id NUMBER
        ) IS
        SELECT
            y.*
        FROM
            (
                SELECT
                    transaction_number,
                    report_org_unit_1,
                    report_group_id_code
                FROM
                    wsc_ahcs_cncr_txn_line_t
                WHERE
                    batch_id = p_batch_id
                GROUP BY
                    transaction_number,
                    report_org_unit_1,
                    report_group_id_code
                HAVING
                    report_group_id_code != report_org_unit_1
            )                        s,
            wsc_ahcs_cncr_txn_line_t y
        WHERE
                y.transaction_number = s.transaction_number
            AND y.batch_id = p_batch_id
            AND y.src_system <> 'WESCO';

        TYPE cncr_stg_hdr_type IS
            TABLE OF cncr_stg_hdr_data_cur%rowtype;
        lv_cncr_stg_hdr_type        cncr_stg_hdr_type;
        TYPE cncr_stg_line_type IS
            TABLE OF cncr_stg_line_data_cur%rowtype;
        lv_cncr_stg_line_type       cncr_stg_line_type;
        TYPE cncr_stg_hdr_split_type IS
            TABLE OF cncr_stg_hdr_split_data_cur%rowtype;
        lv_cncr_stg_hdr_split_type  cncr_stg_hdr_split_type;
        TYPE cncr_stg_line_split_type IS
            TABLE OF cncr_stg_line_split_data_cur%rowtype;
        lv_cncr_stg_line_split_type cncr_stg_line_split_type;
        lv_batch_id                 NUMBER := p_batch_id;
    BEGIN
        p_error_flag := '0';
        dbms_output.put_line('Just Begin');

-- INSERT DATA FROM STAGE TO CONCUR LINE TABLE---
        logging_insert('Concur', p_batch_id, 3, 'Data split insertion from concur temp to concur line begins', NULL,
                      sysdate);
        OPEN cncr_stg_line_data_cur(p_batch_id);
        LOOP
            FETCH cncr_stg_line_data_cur
            BULK COLLECT INTO lv_cncr_stg_line_type LIMIT 400;
            EXIT WHEN lv_cncr_stg_line_type.count = 0;
            FORALL i IN 1..lv_cncr_stg_line_type.count
                INSERT INTO wsc_ahcs_cncr_txn_line_t (
                    line_id,
                    batch_id,
                    transaction_number,
                    constant,
                    src_batch_id,
                    batch_date,
                    employee_id,
                    employee_last_name,
                    employee_first_name,
                    middle_initial,
                    report_id,
                    report_key,
                    reimbursement_currency_alpha_ise,
                    report_submit_date,
                    report_payment_processing_date,
                    report_name,
                    report_total_approved_amount,
                    report_custom_15,
                    report_group_id_code,
                    report_org_unit_1,
                    report_org_unit_2,
                    report_org_unit_3,
                    report_entry_id,
                    report_entry_expense_type_name,
                    report_entry_description,
                    report_entry_custom_17,
                    report_entry_tax_code,
                    report_entry_tax_reclaim_code,
                    journal_account_code,
                    net_adjusted_reclaim_amt,
                    report_entry_tax_reclaim_posted_amt,
                    seq_num,
                    tax_auth_name,
                    default_amount,
                    leg_bu,
                    leg_acct,
          --          leg_wes_acct,
                    leg_dept,
                    leg_loc,
             --       leg_coa,
                    src_system,
                    creation_date,
                    created_by,
                    last_update_date,
                    last_updated_by
                ) VALUES (
                    wsc_concur_line_s1.NEXTVAL,
                    p_batch_id,
                        CASE
                            WHEN ( nvl((
                                SELECT
                                    report_grp_code
                                FROM
                                    wsc_ahcs_cncr_report_grp_t
                                WHERE
                                    report_grp_id = regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL,
                                                                  1)
                            ), regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL,
                                             1)) != regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL,
                                                                  1) )
                                 AND regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL,
                                                   1) NOT LIKE '%Wes%' THEN
                                ( regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                                1)
                                  || '_'
                                  || regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL,
                                                   1)
                                  || '_'
                                  || nvl((
                                    SELECT
                                        report_grp_code
                                    FROM
                                        wsc_ahcs_cncr_report_grp_t
                                    WHERE
                                        report_grp_id = regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL,
                                                                      1)
                                ), regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL,
                                                 1))
                                  || '_'
                                  || replace(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL,
                                                           1), '-', '')
                                  || '_1' )
                            WHEN regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL,
                                               1) LIKE '%Wes%' THEN
                                ( regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                                1)
                                  || '_'
                                  || (
                                    SELECT
                                        report_grp_code
                                    FROM
                                        wsc_ahcs_cncr_report_grp_t
                                    WHERE
                                        report_grp_id = regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL,
                                                                      1)
                                )
                                  || '_'
                                  || regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 36, NULL,
                                                   1)
                                  || '_'
                                  || replace(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL,
                                                           1), '-', '') )
                            ELSE
                                ( regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                                1)
                                  || '_'
                                  || regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL,
                                                   1)
                                  || '_'
                                  || replace(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL,
                                                           1), '-', '') )
                        END,
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL,
                                  1), -- CONSTANT --
                    to_number(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                            1)), -- SRC_BATCH_ID --
                    to_date(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                          1), 'yyyy-mm-dd'), -- BATCH_DATE --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL,
                                  1), -- EMPLOYEE_ID --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL,
                                  1), -- EMPLOYEE_LAST_NAME --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL,
                                  1), -- EMPLOYEE_FIRST_NAME --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL,
                                  1), -- MIDDLE_INITIAL --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL,
                                  1), -- REPORT_ID --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL,
                                  1), -- REPORT_KEY --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL,
                                  1), -- REIMBURSEMENT_CURRENCY_ALPHA_ISE --
                    to_date(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL,
                                          1), 'yyyy-mm-dd'), -- REPORT_SUBMIT_DATE --
                    to_date(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL,
                                          1), 'yyyy-mm-dd'), -- REPORT_PAYMENT_PROCESSING_DATE --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL,
                                  1),-- REPORT_NAME --
                    to_number(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 32, NULL,
                                            1)), -- REPORT_TOTAL_APPROVED_AMOUNT -- 
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL,
                                  1), -- REPORT_CUSTOM_15/REPORT_GROUP_ID --
                    nvl((
                        SELECT
                            report_grp_code
                        FROM
                            wsc_ahcs_cncr_report_grp_t
                        WHERE
                            report_grp_id = regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL,
                                                          1)
                    ), regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL,
                                     1)), -- REPORT_GROUP_ID_CODE --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL,
                                  1), -- REPORT_ORG_UNIT_1 --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 36, NULL,
                                  1), -- REPORT_ORG_UNIT_2 --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 37, NULL,
                                  1), -- REPORT_ORG_UNIT_3 --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 61, NULL,
                                  1), -- REPORT_ENTRY_ID --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 63, NULL,
                                  1), -- REPORT_ENTRY_EXPENSE_TYPE_NAME --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 69, NULL,
                                  1),  -- REPORT_ENTRY_DESC --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 99, NULL,
                                  1),  -- REPORT_ENTRY_CUSTOM_17 --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 232, NULL,
                                  1),  -- REPORT_ENTRY_TAX_CODE --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 236, NULL,
                                  1),  -- REPORT_ENTRY_TAX_RECLAIM_CODE --
                    to_number(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 167, NULL,
                                            1)),  -- JOURNAL_ACCOUNT_CODE --
                    to_number(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 249, NULL,
                                            1)),  -- NET_ADJUSTED_RECLAIM_AMT --
                    to_number(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 231, NULL,
                                            1)),  -- REPORT_ENTRY_TAX_RECLAIM_POSTED_AMT --
                    to_number(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL,
                                            1)),  -- SEQUENCE_NUM --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 225, NULL,
                                  1),  -- TAX_AUTHORITY_NAME --
                        CASE
                            WHEN regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 225, NULL,
                                               1) IS NULL THEN
                                round(to_number(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 249, NULL,
                                                              1)), 2)
                            WHEN regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 225, NULL,
                                               1) IS NOT NULL THEN
                                round(to_number(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 231, NULL,
                                                              1)), 2)
                        END, -- DEFAULT_AMOUNT --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL,
                                  1),  -- LEG_BU --
                        CASE
                            WHEN regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 225, NULL,
                                               1) IS NULL THEN
                                to_number(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 167, NULL,
                                                        1))
                            WHEN regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 225, NULL,
                                               1) IS NOT NULL
                                 AND ( ( to_number(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL,
                                                                 1)) BETWEEN 00301 AND 00399 )
                                       OR regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL,
                                                        1) LIKE '%008%' ) THEN
                                to_number(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 232, NULL,
                                                        1))
                            ELSE
                                to_number(regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 236, NULL,
                                                        1))
                        END, -- LEG_PS_ACCT --
         --           '00000', -- LEG_WES_ACCT
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 37, NULL,
                                  1),  -- LEG_DEPT --
                    regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 36, NULL,
                                  1),  -- LEG_LOC --
                        CASE
                            WHEN regexp_substr(lv_cncr_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL,
                                               1) LIKE '%Wes%' THEN
                                'WESCO'
                            ELSE
                                'ANIXTER'
                        END,
                    sysdate,
                    'FIN_INT',
                    sysdate,
                    'FIN_INT'
                );

        END LOOP;

        COMMIT;
        logging_insert('Concur', p_batch_id, 4, 'Data split insertion from concur temp to concur line ends and hdr begins', NULL,
                      sysdate);
------ INSERT DATA FROM STG TO Concur HDR TABLE for report_group_id=report_org_unit_1 matching -----

        OPEN cncr_stg_hdr_data_cur(p_batch_id);
        LOOP
            FETCH cncr_stg_hdr_data_cur
            BULK COLLECT INTO lv_cncr_stg_hdr_type LIMIT 400;
            EXIT WHEN lv_cncr_stg_hdr_type.count = 0;
            FORALL i IN 1..lv_cncr_stg_hdr_type.count
                INSERT INTO wsc_ahcs_cncr_txn_header_t (
                    header_id,
                    batch_id,
                    transaction_date,
                    transaction_number,
                    transaction_type,
                    source_system,
                    file_name,
                    je_category,
                    event_class,
                    src_batch_id,
                    report_group_id,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date
                ) VALUES (
                    wsc_concur_header_s1.NEXTVAL,
                    p_batch_id,
                    lv_cncr_stg_hdr_type(i).report_payment_date,
                    lv_cncr_stg_hdr_type(i).transaction_number,
                    'CONCUR',
                    'Concur',
                    p_file_name,
                    'Concur',
                    'Concur',
                    lv_cncr_stg_hdr_type(i).src_batch_id,
                    lv_cncr_stg_hdr_type(i).report_group_id,
                    'FIN_INT',
                    sysdate,
                    'FIN_INT',
                    sysdate
                );

        END LOOP;

        COMMIT;
        logging_insert('Concur', p_batch_id, 5, 'Hdr split insertion concur starts.', NULL,
                      sysdate);
-- Split Header and line Transactios -----
--- Creating Offset header line transaction in hdr table.---
        OPEN cncr_stg_hdr_split_data_cur(p_batch_id);
        LOOP
            FETCH cncr_stg_hdr_split_data_cur
            BULK COLLECT INTO lv_cncr_stg_hdr_split_type LIMIT 400;
            EXIT WHEN lv_cncr_stg_hdr_split_type.count = 0;
            FORALL i IN 1..lv_cncr_stg_hdr_split_type.count
                INSERT INTO wsc_ahcs_cncr_txn_header_t (
                    header_id,
                    batch_id,
                    transaction_date,
                    transaction_number,
                    transaction_type,
                    source_system,
                    file_name,
                    je_category,
                    event_class,
                    src_batch_id,
                    report_group_id,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date
                ) VALUES (
                    wsc_concur_header_s1.NEXTVAL,
                    p_batch_id,
                    lv_cncr_stg_hdr_split_type(i).report_payment_processing_date,
                        CASE
                            WHEN substr(lv_cncr_stg_hdr_split_type(i).transaction_number, - 2) = '_1' THEN
                                ( lv_cncr_stg_hdr_split_type(i).src_batch_id
                                  || '_'
                                  || lv_cncr_stg_hdr_split_type(i).report_group_id_code
                                  || '_'
                                  || lv_cncr_stg_hdr_split_type(i).report_org_unit_1
                                  || '_'
                                  || to_char(lv_cncr_stg_hdr_split_type(i).report_payment_processing_date, 'yyyymmdd')
                                  || '_2' )
                        END,
                    'CONCUR',
                    'Concur',
                    p_file_name,
                    'Concur',
                    'Concur',
                    lv_cncr_stg_hdr_split_type(i).src_batch_id,
                    lv_cncr_stg_hdr_split_type(i).report_org_unit_1,
                    'FIN_INT',
                    sysdate,
                    'FIN_INT',
                    sysdate
                );

        END LOOP;

        COMMIT;
        logging_insert('Concur', p_batch_id, 6, 'Hdr split insertion concur ends.', NULL,
                      sysdate);
        logging_insert('Concur', p_batch_id, 7, 'Line split insertion concur starts', NULL,
                      sysdate);
        SELECT
            target_coa
        INTO lv_offset_acct
        FROM
            wsc_ahcs_cncr_report_grp_t
        WHERE
            report_grp_id = 'Offset Account';                  
   -- Line split inserting new offset line in line table ---                   
        OPEN cncr_stg_line_split_data_cur(p_batch_id);
        LOOP
            FETCH cncr_stg_line_split_data_cur
            BULK COLLECT INTO lv_cncr_stg_line_split_type LIMIT 400;
            EXIT WHEN lv_cncr_stg_line_split_type.count = 0;
            FORALL i IN 1..lv_cncr_stg_line_split_type.count
                INSERT INTO wsc_ahcs_cncr_txn_line_t (
                    line_id,
                    batch_id,
                    transaction_number,
                    constant,
                    src_batch_id,
                    batch_date,
                    employee_id,
                    employee_last_name,
                    employee_first_name,
                    middle_initial,
                    report_id,
                    report_key,
                    reimbursement_currency_alpha_ise,
                    report_submit_date,
                    report_payment_processing_date,
                    report_name,
                    report_total_approved_amount,
                    report_custom_15,
                    report_group_id_code,
                    report_org_unit_1,
                    report_org_unit_2,
                    report_org_unit_3,
                    report_entry_id,
                    report_entry_expense_type_name,
                    report_entry_description,
                    report_entry_custom_17,
                    report_entry_tax_code,
                    report_entry_tax_reclaim_code,
                    journal_account_code,
                    net_adjusted_reclaim_amt,
                    report_entry_tax_reclaim_posted_amt,
                    seq_num,
                    tax_auth_name,
                    default_amount,
                    leg_bu,
                    leg_acct,
         --           leg_wes_acct,
                    leg_dept,
                    leg_loc,
                    leg_coa,
                    src_system,
                    creation_date,
                    created_by,
                    last_update_date,
                    last_updated_by
                ) VALUES (
                    wsc_concur_line_s1.NEXTVAL,
                    p_batch_id,
                        CASE
                            WHEN substr(lv_cncr_stg_line_split_type(i).transaction_number, - 2) = '_1' THEN
                                ( lv_cncr_stg_line_split_type(i).src_batch_id
                                  || '_'
                                  || lv_cncr_stg_line_split_type(i).report_group_id_code
                                  || '_'
                                  || lv_cncr_stg_line_split_type(i).report_org_unit_1
                                  || '_'
                                  || to_char(lv_cncr_stg_line_split_type(i).report_payment_processing_date, 'yyyymmdd')
                                  || '_2' )
                        END,
                    lv_cncr_stg_line_split_type(i).constant, --  CONSTANT
                    lv_cncr_stg_line_split_type(i).src_batch_id, --  SRC_BATCH_ID
                    lv_cncr_stg_line_split_type(i).batch_date, --  BATCH_DATE
                    lv_cncr_stg_line_split_type(i).employee_id, --  EMPLOYEE_ID
                    lv_cncr_stg_line_split_type(i).employee_last_name, --  EMPLOYEE_LAST_NAME
                    lv_cncr_stg_line_split_type(i).employee_first_name, --  EMPLOYEE_FIRST_NAME
                    lv_cncr_stg_line_split_type(i).middle_initial, --  MIDDLE_INITIAL
                    lv_cncr_stg_line_split_type(i).report_id, --  REPORT_ID
                    lv_cncr_stg_line_split_type(i).report_key, --  REPORT_KEY
                    lv_cncr_stg_line_split_type(i).reimbursement_currency_alpha_ise, --  REIMBURSEMENT_CURRENCY_ALPHA_ISE
                    lv_cncr_stg_line_split_type(i).report_submit_date, --  REPORT_SUBMIT_DATE
                    lv_cncr_stg_line_split_type(i).report_payment_processing_date, --  REPORT_PAYMENT_PROCESSING_DATE
                    lv_cncr_stg_line_split_type(i).report_name, --  REPORT_NAME
                    lv_cncr_stg_line_split_type(i).report_total_approved_amount, --  REPORT_TOTAL_APPROVED_AMOUNT
                    lv_cncr_stg_line_split_type(i).report_custom_15, --  REPORT_CUSTOM_15
                    lv_cncr_stg_line_split_type(i).report_group_id_code, --  REPORT_GROUP_ID_CODE
                    lv_cncr_stg_line_split_type(i).report_org_unit_1, --  REPORT_ORG_UNIT_1
                    lv_cncr_stg_line_split_type(i).report_org_unit_2, --  REPORT_ORG_UNIT_2
                    lv_cncr_stg_line_split_type(i).report_org_unit_3, --  REPORT_ORG_UNIT_3
                    lv_cncr_stg_line_split_type(i).report_entry_id, --  REPORT_ENTRY_ID
                    lv_cncr_stg_line_split_type(i).report_entry_expense_type_name, --  REPORT_ENTRY_EXPENSE_TYPE_NAME
                    lv_cncr_stg_line_split_type(i).report_entry_description, --  REPORT_ENTRY_DESCRIPTION
                    lv_cncr_stg_line_split_type(i).report_entry_custom_17, --  REPORT_ENTRY_CUSTOM_17
                    lv_cncr_stg_line_split_type(i).report_entry_tax_code, --  REPORT_ENTRY_TAX_CODE
                    lv_cncr_stg_line_split_type(i).report_entry_tax_reclaim_code, --  REPORT_ENTRY_TAX_RECLAIM_CODE
                    lv_cncr_stg_line_split_type(i).journal_account_code, --  JOURNAL_ACCOUNT_CODE
                    lv_cncr_stg_line_split_type(i).net_adjusted_reclaim_amt, --  NET_ADJUSTED_RECLAIM_AMT
                    lv_cncr_stg_line_split_type(i).report_entry_tax_reclaim_posted_amt, --  REPORT_ENTRY_TAX_RECLAIM_POSTED_AMT
                    lv_cncr_stg_line_split_type(i).seq_num, --  SEQ_NUM
                    lv_cncr_stg_line_split_type(i).tax_auth_name, --  TAX_AUTH_NAME
                    lv_cncr_stg_line_split_type(i).default_amount,-- DEFAULT_AMOUNT --
                    lv_cncr_stg_line_split_type(i).report_group_id_code,  -- LEG_BU --
                    lv_offset_acct, -- LEG_PS_ACCT --
   --                 lv_cncr_stg_line_split_type(i).leg_wes_acct, -- LEG_WES_ACCT
                    lv_cncr_stg_line_split_type(i).leg_dept,  -- LEG_DEPT --
                    lv_cncr_stg_line_split_type(i).leg_loc,  -- LEG_LOC --
                    lv_cncr_stg_line_split_type(i).leg_coa, --LEG_COA --
                    lv_cncr_stg_line_split_type(i).src_system, -- Source Line --
                    sysdate,
                    'FIN_INT',
                    sysdate,
                    'FIN_INT'
                );

        END LOOP;

        COMMIT;
        logging_insert('Concur', p_batch_id, 8, 'Line split insertion concur ends', NULL,
                      sysdate);
        logging_insert('Concur', p_batch_id, 9, 'status table insert and header to line field insertion begins', NULL,
                      sysdate); 
----updating the header_id from header table to line table----
        logging_insert('concur', p_batch_id, 10, 'Update concur line table fields from header table begins', NULL,
                      sysdate);
        UPDATE wsc_ahcs_cncr_txn_line_t line
        SET
            ( header_id ) = (
                SELECT
                    hdr.header_id
                FROM
                    wsc_ahcs_cncr_txn_header_t hdr
                WHERE
                        line.transaction_number = hdr.transaction_number
                    AND line.batch_id = hdr.batch_id
            ),
            leg_coa = (
                CASE
                    WHEN 
--                    ( line.src_system = 'WESCO'
--                           AND substr(line.transaction_number, - 2) = '_2' )
--                         OR
                     line.src_system = 'ANIXTER' THEN
                        leg_bu
                        || '.'
                        || leg_loc
                        || '.'
                        || leg_dept
                        || '.'
                        || leg_acct
                        || '.'
                        || leg_vendor
                        || '.'
                        || leg_affiliate
                    ELSE
                        NULL
                END
            )
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        logging_insert('Concur', p_batch_id, 11, 'Update cncr line table fields from header table ends', NULL,
                      sysdate);
        logging_insert('Concur', p_batch_id, 12, 'Inserting records in status table begins', NULL,
                      sysdate);
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
     --       interface_id,
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
                CASE
                    WHEN line.default_amount >= 0 THEN
                        'DR'
                    WHEN line.default_amount < 0  THEN
                        'CR'
                END,
                line.reimbursement_currency_alpha_ise,
                line.default_amount,
                line.leg_coa,
                line.src_batch_id,
                line.seq_num,
                line.transaction_number,
                hdr.transaction_date,
      --          line.interface_id,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
                wsc_ahcs_cncr_txn_line_t   line,
                wsc_ahcs_cncr_txn_header_t hdr
            WHERE
                    line.batch_id = lv_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id;

        COMMIT;
        logging_insert('Concur', p_batch_id, 13, 'Inserting records in status table ends', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            p_error_flag := '1';
            err_msg := substr(sqlerrm, 1, 200);
            dbms_output.put_line(err_msg);
            logging_insert('Concur', p_batch_id, 9.1, 'Error While updating Line table with Header ID/inserting data in status table',
            sqlerrm,
                          sysdate);
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT016', 'Concur', err_msg);
    END wsc_process_cncr_temp_to_header_line_p;

    PROCEDURE wsc_async_process_update_validate_transform_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    ) AS
        err_msg VARCHAR2(4000);
    BEGIN
        logging_insert('Concur', p_batch_id, 1, 'Starts ASYNC DB Scheduler', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        dbms_scheduler.create_job(job_name => 'INVOKE_WSC_PROCESS_CONCUR_STAGE_TO_HEADER_LINE_P' || p_batch_id, job_type => 'PLSQL_BLOCK',
        job_action => '
                                 DECLARE
                                    p_error_flag VARCHAR2(2);
                                 BEGIN                                
         wsc_cncr_pkg.wsc_process_cncr_temp_to_header_line_p('
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
         wsc_ahcs_cncr_validation_transformation_pkg.data_validation_p('
                                                                                                                                         ||
                                                                                                                                         p_batch_id
                                                                                                                                         ||
                                                                                                                                         ');

          end if;                                   
       END;', enabled => true, auto_drop => true,
                                 comments => 'Async steps to split the data from stage and insert into header and line tables. Also, update line table, insert into WSC_AHCS_INT_STATUS_T and call Validation and Transformation procedure');

        logging_insert('Concur', p_batch_id, 200, 'Async V & T completed.', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('Concur', p_batch_id, 1.1, 'Error in Async DB Proc', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            COMMIT;
    END wsc_async_process_update_validate_transform_p;

END wsc_cncr_pkg;
/ 