create or replace PACKAGE BODY wsc_mfar_pkg AS

    PROCEDURE wsc_mfar_insert_data_temp_p (
        p_wsc_mfar_stg IN wsc_mfar_tmp_t_type_table
    ) AS
    BEGIN
----        logging_insert('MF AR', p_batch_id, 1, 'Data insertion from sftp to mfar stage begins', NULL,
--                      sysdate);
        FORALL i IN 1..p_wsc_mfar_stg.count
            INSERT INTO wsc_ahcs_mfar_txn_tmp_t (
                batch_id,
                rice_id,
                data_string
            ) VALUES (
                p_wsc_mfar_stg(i).batch_id,
                p_wsc_mfar_stg(i).rice_id,
              REPLACE(p_wsc_mfar_stg(i).data_string,'"',' ')
    --            regexp_replace(p_wsc_mfar_stg(i).data_string, '[^a-z_A-Z 0-9|]')
            );
--    --    logging_insert('MF AR', p_batch_id, 2, 'Data insertion from sftp to mfar stage ends', NULL,
--                      sysdate);
    END wsc_mfar_insert_data_temp_p;

    PROCEDURE wsc_process_mfar_temp_to_header_line_p (
        p_batch_id         IN NUMBER,
        p_application_name IN VARCHAR2,
        p_file_name        IN VARCHAR2,
        p_error_flag       OUT VARCHAR2
    ) IS

        err_msg               VARCHAR2(4000);
        v_stage               VARCHAR2(200);
        l_system              VARCHAR2(200);
        CURSOR mfar_stg_hdr_data_cur (
            p_batch_id NUMBER
        ) IS
        SELECT
            *
        FROM
            wsc_ahcs_mfar_txn_tmp_t
        WHERE
                batch_id = p_batch_id
            AND TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 1, NULL,
                                   1)) = 'H';

        CURSOR mfar_stg_line_data_cur (
            p_batch_id NUMBER
        ) IS
        SELECT
            *
        FROM
            wsc_ahcs_mfar_txn_tmp_t
        WHERE
                batch_id = p_batch_id
            AND TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 1, NULL,
                                   1)) = 'D';

        TYPE mfar_stg_hdr_type IS
            TABLE OF mfar_stg_hdr_data_cur%rowtype;
        lv_mfar_stg_hdr_type  mfar_stg_hdr_type;
        TYPE mfar_stg_line_type IS
            TABLE OF mfar_stg_line_data_cur%rowtype;
        lv_mfar_stg_line_type mfar_stg_line_type;
        lv_batch_id           NUMBER := p_batch_id;
    BEGIN
        p_error_flag := '0';
            --fetch the source application name from control table ----
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

        dbms_output.put_line('Just Begin');
-- INSERT DATA FROM STAGE TO MFAR HEADER TABLE---
        logging_insert('MF AR', p_batch_id, 3, 'Data split insertion from mfar stage to mfar hdr begins', NULL,
                      sysdate);
        OPEN mfar_stg_hdr_data_cur(p_batch_id);
        LOOP
            FETCH mfar_stg_hdr_data_cur
            BULK COLLECT INTO lv_mfar_stg_hdr_type LIMIT 400;
            EXIT WHEN lv_mfar_stg_hdr_type.count = 0;
            FORALL i IN 1..lv_mfar_stg_hdr_type.count
                INSERT INTO wsc_ahcs_mfar_txn_header_t (
                    header_id,
                    batch_id,
                    transaction_date,
                    transaction_number,
                    record_type,
                    hdr_seq_nbr,
                    interface_id,
                    location,
                    invoice_nbr,
                    invoice_type,
                    sale_order_nbr,
                    customer_nbr,
                    customer_name,
                    continent,
                    customer_type,
                    payment_terms,
                    invoice_date,
                    invoice_due_date,
                    invc_loc_iso_cntry,
                    invoice_loc_div,
                    ship_to_nbr,
                    invoice_currency,
                    customer_currency,
                    fx_rate_on_invoice,
                    ship_type,
                    export_type,
                    record_error_code,
                    credit_type,
                    non_ra_credit_type,
                    ci_profile_type,
                    amount_type,
                    amount,
                    amount_in_cust_curr,
                    business_unit,
                    ship_from_location,
                    tax_invc_i,
                    freight_vendor_nbr,
                    freight_invoice_nbr,
                    freight_terms,
                    freight_invoice_date,
                    cash_date,
                    cash_batch_nbr,
                    cash_code,
                    cash_fx_rate,
                    cash_check_nbr,
                    cash_entry_date,
                    cash_lockbox_id,
                    gl_div_headqtr_loc,
                    gl_div_hq_loc_bu,
                    ship_from_loc_bu,
                    ps_affiliate_bu,
                    emea_flag,
                    account_date,
                    interface_desc_en,
                    interface_desc_frn,
                    cust_po,
                    cust_credit_pref,
                    bank_deposit_date,
                    vendor_abbrev_c,
                    item_uom_c,
                    ib30_reason_c,
                    ib30_memo,
                    receiver_loc,
                    receiver_nbr,
                    ra_loc,
                    ra_nbr,
                    sales_rep,
                    freight_bill_nbr,
                    final_dest,
                    freight_vendor_name,
                    fiscal_date,
                    matching_key,
                    matching_date,
                    gaap_amount,
                    gaap_amount_in_cust_curr,
                    journal_source_c,
                    kava_f,
                    error_type,
                    error_code,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date
                ) VALUES (
                    wsc_mfar_header_s1.NEXTVAL,
                    p_batch_id,
--                    to_char(to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 49, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 49, NULL,
                                               1)), 'mm/dd/yyyy'),
                        CASE
                            WHEN TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                                    1)) = 'SALE' THEN
                                'SII'
                                || TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                                      1))
                            WHEN TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                                    1)) = 'CASH' THEN
                                'CRI'
                                || TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                                      1))
                            WHEN TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                                    1)) = 'LSIR' THEN
                                'LSI'
                                || TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                                      1))
                            WHEN TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                                    1)) = 'ARIN' THEN
                                'ARI'
                                || TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                                      1))
                            WHEN TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                                    1)) = 'SPER' THEN
                                'SPR'
                                || TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                                      1))
                        END,
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL,
                                               1)), 'mm/dd/yyyy'),
--                    to_char(to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL,
                                               1)), 'mm/dd/yyyy'),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL,
                                       1)),
                    to_number(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL,
                                                 1))),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL,
                                       1)),
                    to_number(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL,
                                                 1))),
                    to_number(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 29, NULL,
                                                 1))),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 30, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 31, NULL,
                                       1)),
                    to_number(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 32, NULL,
                                                 1))),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 33, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 34, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 36, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 36, NULL,
                                               1)), 'mm/dd/yyyy'),
--                    to_char(to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 37, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 37, NULL,
                                               1)), 'mm/dd/yyyy'),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 38, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 39, NULL,
                                       1)),
                    to_number(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 40, NULL,
                                                 1))),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 41, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 42, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 42, NULL,
                                               1)), 'mm/dd/yyyy'),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 43, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 44, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 45, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 46, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 47, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 48, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 49, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 49, NULL,
                                               1)), 'mm/dd/yyyy'),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 50, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 51, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 52, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 53, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 54, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 54, NULL,
                                               1)), 'mm/dd/yyyy'),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 56, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 57, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 58, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 59, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 60, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 61, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 62, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 63, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 64, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 65, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 66, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 67, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 68, NULL,
                                       1)),
--                    to_char(to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 69, NULL,
--                                                       1)), 'mm/dd/yyyy'), 'yyyy-mm-dd'),
                    to_date(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 69, NULL,
                                               1)), 'mm/dd/yyyy'),
                    to_number(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 70, NULL,
                                                 1))),
                    to_number(TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 71, NULL,
                                                 1))),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 72, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 73, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 74, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 75, NULL,
                                       1)),
                    'FIN_INT',
                    sysdate,
                    'FIN_INT',
                    sysdate
                );

        END LOOP;

        COMMIT;
        logging_insert('MF AR', p_batch_id, 4, 'Data split insertion from mfar stage to mfar hdr ends and line begins', NULL,
                      sysdate);
---- INSERT DATA FROM STG TO MFAR LINE TABLE
        OPEN mfar_stg_line_data_cur(p_batch_id);
        LOOP
            FETCH mfar_stg_line_data_cur
            BULK COLLECT INTO lv_mfar_stg_line_type LIMIT 400;
            EXIT WHEN lv_mfar_stg_line_type.count = 0;
            FORALL i IN 1..lv_mfar_stg_line_type.count
                INSERT INTO wsc_ahcs_mfar_txn_line_t (
                    line_id,
                    batch_id,
                    transaction_number,
                    record_type,
                    hdr_seq_nbr,
                    interface_id,
                    leg_location,
                    invoice_nbr,
                    line_seq_number,
                    line_type,
                    amount_type,
                    amount,
                    amount_in_cust_curr,
                    line_nbr,
                    item_nbr,
                    product_class,
                    unit_price,
                    shipped_quantity,
                    mig_sig,
                    lrd_ship_from,
                    db_cr_flag,
                    leg_bu,
                    leg_acct,
                    leg_dept,
                    leg_vendor,
                    leg_project,
                    leg_loc,
                    gl_currency_cd,
                    leg_affiliate,
                    cash_ar50_comments,
                    payment_code,
                    uom_c,
                    uom_cnvrn_factor,
                    po_nbr,
                    vendor_stk_nbr,
                    billed_qty,
                    avg_unit_cost,
                    std_unit_cost,
                    pc_flag,
                    lsi_line_descr,
                    invoice_currency,
                    customer_currency,
                    vendor_abbrev_c,
                    vendor_nbr,
                    vendor_name,
                    gaap_f,
                    leg_division,
                    error_type,
                    error_code,
                    leg_coa,
                    leg_seg_1_4,
                    leg_seg_5_7,
                    leg_loc_sr,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date
                ) VALUES (
                    wsc_mfar_line_s1.NEXTVAL,
                    p_batch_id,
                        CASE
                            WHEN TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                                    1)) = 'SALE' THEN
                                'SII'
                                || TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                                      1))
                            WHEN TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                                    1)) = 'CASH' THEN
                                'CRI'
                                || TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                                      1))
                            WHEN TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                                    1)) = 'LSIR' THEN
                                'LSI'
                                || TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                                      1))
                            WHEN TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                                    1)) = 'ARIN' THEN
                                'ARI'
                                || TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                                      1))
                            WHEN TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                                    1)) = 'SPER' THEN
                                'SPR'
                                || TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                                      1))
                        END,
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL,
                                       1)),
                    to_number(TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL,
                                                 1))),
                    to_number(TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL,
                                                 1))),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL,
                                       1)),
                    to_number(TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL,
                                                 1))),
                    to_number(TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL,
                                                 1))),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 29, NULL,
                                       1)),
                    to_number(TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 30, NULL,
                                                 1))),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 31, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 32, NULL,
                                       1)),
                    to_number(TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 33, NULL,
                                                 1))),
                    to_number(TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 34, NULL,
                                                 1))),
                    to_number(TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL,
                                                 1))),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 36, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 37, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 38, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 39, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 40, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 41, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 42, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 43, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 44, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 45, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 46, NULL,
                                       1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL,
                                       1))
                    || '.'
                    || TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL,
                                          1))
                    || '.'
                    || TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL,
                                          1))
                    || '.'
                    || TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL,
                                          1))
                    || '.'
                    || TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL,
                                          1))
                    || '.'
                    || nvl(TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL,
                                              1)), '00000'),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL,
                                       1))
                    || '.'
                    || TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL,
                                          1))
                    || '.'
                    || TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL,
                                          1))
                    || '.'
                    || TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL,
                                          1)),
                    TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL,
                                       1))
                    || '.'
                    || TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL,
                                          1)),
                        CASE
                            WHEN TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL,
                                                    1)) = 'LSIR' THEN
                                TRIM(regexp_substr(lv_mfar_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL,
                                                   1))
                        END,
                    'FIN_INT',
                    sysdate,
                    'FIN_INT',
                    sysdate
                );

        END LOOP;

        COMMIT;
        logging_insert('MF AR', p_batch_id, 5, 'Data split insertion from mfar stage to mfar line ends', NULL,
                      sysdate);
        logging_insert('MF AR', p_batch_id, 6, 'status table insert and header to line field insertion begins', NULL,
                      sysdate); 
----updating the header_id from header table to line table----
        logging_insert('MF AR', p_batch_id, 7, 'Update mfar line table fields from header table begins', NULL,
                      sysdate);
        UPDATE wsc_ahcs_mfar_txn_line_t line
        SET
            ( header_id,
              line_type,
              customer_name,
              customer_nbr,
              cash_check_nbr,
              invoice_date,
              leg_division,
              matching_key,
              matching_date,
              fx_rate_on_invoice,
              leg_loc_sr ) = (
                SELECT
                    hdr.header_id,
                    CASE
                        WHEN hdr.interface_id = 'CASH' THEN
                            hdr.cash_code
                        ELSE
                            line_type
                    END,
                    hdr.customer_name,
                    hdr.customer_nbr || hdr.continent,
                    hdr.cash_check_nbr,
                    hdr.invoice_date,
                    CASE
                        WHEN hdr.interface_id = 'SALE' THEN
                            hdr.invoice_loc_div
                        WHEN hdr.interface_id = 'ARIN' THEN
                            hdr.invoice_loc_div
                        ELSE
                            leg_division
                    END,
                    hdr.matching_key,
                    hdr.matching_date,
                    hdr.fx_rate_on_invoice,
                    CASE
                        WHEN hdr.interface_id != 'LSIR' THEN
                            hdr.location
                        ELSE
                            line.leg_loc_sr
                    END
                FROM
                    wsc_ahcs_mfar_txn_header_t hdr
                WHERE
                        line.hdr_seq_nbr = hdr.hdr_seq_nbr
                    AND line.batch_id = hdr.batch_id
            )
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        logging_insert('MF AR', p_batch_id, 8, 'Update mfar line table fields from header table ends', NULL,
                      sysdate);
        logging_insert('MF AR', p_batch_id, 9, 'Inserting records in status table begins', NULL,
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
                nvl(line.db_cr_flag,
                    CASE
                        WHEN line.amount >= 0 THEN
                            'DR'
                        WHEN line.amount < 0  THEN
                            'CR'
                    END
                ),
                line.invoice_currency,
                line.amount,
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
                    line.batch_id = lv_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id;

        COMMIT;
        logging_insert('MF AR', p_batch_id, 10, 'Inserting records in status table ends', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            p_error_flag := '1';
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('MF AR', p_batch_id, 9.1, 'Error While updating Line table with Header ID/inserting data in status table',
            sqlerrm,
                          sysdate);
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT216'
                                                                 || '_'
                                                                 || l_system, 'MF AR', err_msg);

    END wsc_process_mfar_temp_to_header_line_p;

    PROCEDURE wsc_async_process_update_validate_transform_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    ) AS
        err_msg VARCHAR2(4000);
    BEGIN
        logging_insert('MF AR', p_batch_id, 5.1, 'Starts ASYNC DB Scheduler', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        dbms_scheduler.create_job(job_name => 'INVOKE_WSC_PROCESS_MFAR_STAGE_TO_HEADER_LINE_P' || p_batch_id, job_type => 'PLSQL_BLOCK',
        job_action => '
                                 DECLARE
                                    p_error_flag VARCHAR2(2);
                                 BEGIN                                
         WSC_MFAR_PKG.wsc_process_mfar_temp_to_header_line_p('
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
         wsc_ahcs_mfar_validation_transformation_pkg.data_validation('
                                                                                                                                       ||
                                                                                                                                       p_batch_id
                                                                                                                                       ||
                                                                                                                                       ');
                                               
          end if;                                   
       END;', enabled => true, auto_drop => true,
                                 comments => 'Async steps to split the data from stage and insert into header and line tables. Also, update line table, insert into WSC_AHCS_INT_STATUS_T and call Validation and Transformation procedure');

        logging_insert('MF AR', p_batch_id, 200, 'Async V & T completed.', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('MF AR', p_batch_id, 5.2, 'Error in Async DB Proc', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            COMMIT;
    END wsc_async_process_update_validate_transform_p;

END wsc_mfar_pkg;
/