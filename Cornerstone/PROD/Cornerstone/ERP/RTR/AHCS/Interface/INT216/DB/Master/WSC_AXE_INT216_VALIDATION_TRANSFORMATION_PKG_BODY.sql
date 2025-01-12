create or replace PACKAGE BODY wsc_ahcs_mfar_validation_transformation_pkg AS

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

    PROCEDURE wsc_ahcs_mfar_line_copy_p (
        p_batch_id IN NUMBER
    ) AS

        lv_interface_id               VARCHAR2(10) := NULL;
        lv_file_name                  VARCHAR2(50) := NULL;
        CURSOR mfar_sale_line_copy_data_cur (
            p_batch_id NUMBER
        ) IS
        SELECT
            h.interface_id        h_interface_id,
            h.amount              h_amount,
            h.amount_in_cust_curr h_amt_in_cust_curr,
            h.customer_currency   h_cust_curr,
            h.invoice_currency    h_inv_curr,
            h.customer_type,
            h.invoice_type,
            h.emea_flag,
            h.gl_div_headqtr_loc,
            l.line_id,
            l.header_id,
            l.batch_id,
            l.transaction_number,
            l.record_type,
            l.hdr_seq_nbr,
            l.interface_id,
            l.leg_location,
            l.invoice_nbr,
            l.line_seq_number,
            l.line_type,
            l.amount_type,
            l.amount,
            l.amount_in_cust_curr,
            l.line_nbr,
            l.item_nbr,
            l.product_class,
            l.unit_price,
            l.shipped_quantity,
            l.mig_sig,
            l.lrd_ship_from,
            l.db_cr_flag,
            l.leg_bu,
            l.leg_acct,
            l.leg_dept,
            l.leg_vendor,
            l.leg_project,
            l.leg_loc,
            l.gl_currency_cd,
            l.leg_affiliate,
            l.cash_ar50_comments,
            l.payment_code,
            l.uom_c,
            l.uom_cnvrn_factor,
            l.po_nbr,
            l.vendor_stk_nbr,
            l.billed_qty,
            l.avg_unit_cost,
            l.std_unit_cost,
            l.pc_flag,
            l.lsi_line_descr,
            l.invoice_currency,
            l.customer_currency,
            l.vendor_abbrev_c,
            l.vendor_nbr,
            l.vendor_name,
            l.gaap_f,
            l.leg_division,
            l.error_type,
            l.error_code,
            l.leg_coa,
            l.target_coa,
            l.gl_legal_entity,
            l.gl_acct,
            l.gl_oper_grp,
            l.gl_dept,
            l.gl_site,
            l.gl_ic,
            l.gl_projects,
            l.gl_fut_1,
            l.gl_fut_2,
            l.statement_id,
            l.transaction_curr_cd,
            l.transaction_amount,
            l.foreign_ex_rate,
            l.base_curr_cd,
            l.base_amount,
            l.subledger_nbr,
            l.subledger_name,
            l.batch_nbr,
            l.invoice_date,
            l.gl_allcon_comments,
            l.line_updated_by,
            l.line_updated_date,
            l.matching_key,
            l.matching_date,
            l.transaction_type,
            l.order_id,
            l.attribute1,
            l.attribute2,
            l.attribute3,
            l.attribute4,
            l.attribute5,
            l.attribute6,
            l.attribute7,
            l.attribute8,
            l.attribute9,
            l.attribute10,
            l.attribute11,
            l.attribute12,
            l.creation_date,
            l.created_by,
            l.last_update_date,
            l.last_updated_by,
            l.customer_name,
            l.customer_nbr,
            l.cash_check_nbr,
            l.fx_rate_on_invoice,
            l.leg_seg_1_4,
            l.leg_seg_5_7,
            l.leg_loc_sr
        FROM
            wsc_ahcs_mfar_txn_line_t   l,
            wsc_ahcs_mfar_txn_header_t h,
            wsc_ahcs_int_status_t      s
        WHERE
                h.batch_id = p_batch_id
            AND h.batch_id = l.batch_id
            AND h.header_id = l.header_id
            AND h.customer_type = 'IC'
            AND h.invoice_type IN ( 'IV', 'RB', 'NR', 'RA', 'F9' )
            AND l.line_seq_number = 1
            AND s.attribute2 = 'TRANSFORM_SUCCESS'
            AND s.status = 'TRANSFORM_SUCCESS'
            AND s.batch_id = l.batch_id
            AND s.header_id = l.header_id
            AND s.line_id = l.line_id
            AND s.attribute6 is null
            AND h.interface_id = 'SALE'
            AND h.batch_id = s.batch_id
            AND h.header_id = s.header_id
            AND s.accounting_status IS NULL;

        TYPE mfar_sale_line_copy_type_t IS
            TABLE OF mfar_sale_line_copy_data_cur%rowtype;
        lv_mfar_sale_line_copy_type_t mfar_sale_line_copy_type_t;
    BEGIN
        logging_insert('MF AR SALE', p_batch_id, 30.2, 'SALE Line Copy Procedure Insertion Start', NULL,
                      sysdate);
        SELECT
            file_name
        INTO lv_file_name
        FROM
            wsc_ahcs_int_control_t
        WHERE
            batch_id = p_batch_id;

        OPEN mfar_sale_line_copy_data_cur(p_batch_id);
        LOOP
            FETCH mfar_sale_line_copy_data_cur
            BULK COLLECT INTO lv_mfar_sale_line_copy_type_t LIMIT 400;
            EXIT WHEN lv_mfar_sale_line_copy_type_t.count = 0;
            FORALL i IN 1..lv_mfar_sale_line_copy_type_t.count
                INSERT INTO wsc_ahcs_mfar_txn_line_t (
                    line_id,
                    header_id,
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
                    target_coa,
                    gl_legal_entity,
                    gl_acct,
                    gl_oper_grp,
                    gl_dept,
                    gl_site,
                    gl_ic,
                    gl_projects,
                    gl_fut_1,
                    gl_fut_2,
                    statement_id,
                    transaction_curr_cd,
                    transaction_amount,
                    foreign_ex_rate,
                    base_curr_cd,
                    base_amount,
                    subledger_nbr,
                    subledger_name,
                    batch_nbr,
                    invoice_date,
                    gl_allcon_comments,
                    line_updated_by,
                    line_updated_date,
                    matching_key,
                    matching_date,
                    transaction_type,
                    order_id,
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
                    creation_date,
                    created_by,
                    last_update_date,
                    last_updated_by,
                    customer_name,
                    customer_nbr,
                    cash_check_nbr,
                    fx_rate_on_invoice,
                    leg_seg_1_4,
                    leg_seg_5_7,
                    leg_loc_sr
                ) VALUES (
                    wsc_mfar_line_s1.NEXTVAL,
                    lv_mfar_sale_line_copy_type_t(i).header_id,
                    p_batch_id,
                    lv_mfar_sale_line_copy_type_t(i).transaction_number,
                    lv_mfar_sale_line_copy_type_t(i).record_type,
                    lv_mfar_sale_line_copy_type_t(i).hdr_seq_nbr,
                    lv_mfar_sale_line_copy_type_t(i).interface_id,
                    lv_mfar_sale_line_copy_type_t(i).leg_location,
                    lv_mfar_sale_line_copy_type_t(i).invoice_nbr,
                    lv_mfar_sale_line_copy_type_t(i).line_seq_number,
                    lv_mfar_sale_line_copy_type_t(i).line_type,
                    'ICRS', --amount_type,
                    lv_mfar_sale_line_copy_type_t(i).h_amount, --header_amount,
                    lv_mfar_sale_line_copy_type_t(i).h_amt_in_cust_curr, --header_amt_in_cust_curr,
                    - 99999, --line_number,
                    lv_mfar_sale_line_copy_type_t(i).item_nbr,
                    lv_mfar_sale_line_copy_type_t(i).product_class,
                    lv_mfar_sale_line_copy_type_t(i).unit_price,
                    lv_mfar_sale_line_copy_type_t(i).shipped_quantity,
                    lv_mfar_sale_line_copy_type_t(i).mig_sig,
                    lv_mfar_sale_line_copy_type_t(i).lrd_ship_from,
                    lv_mfar_sale_line_copy_type_t(i).db_cr_flag,
                    lv_mfar_sale_line_copy_type_t(i).leg_bu,
                    lv_mfar_sale_line_copy_type_t(i).leg_acct,
                    lv_mfar_sale_line_copy_type_t(i).leg_dept,
                    lv_mfar_sale_line_copy_type_t(i).leg_vendor,
                    lv_mfar_sale_line_copy_type_t(i).leg_project,
                        CASE
                            WHEN lv_mfar_sale_line_copy_type_t(i).emea_flag = 'Y'  THEN
                                lv_mfar_sale_line_copy_type_t(i).leg_location
                            WHEN lv_mfar_sale_line_copy_type_t(i).emea_flag != 'Y' THEN
                                lv_mfar_sale_line_copy_type_t(i).gl_div_headqtr_loc
                        END, --leg_loc,
                    lv_mfar_sale_line_copy_type_t(i).gl_currency_cd,
                    lv_mfar_sale_line_copy_type_t(i).leg_affiliate,
                    lv_mfar_sale_line_copy_type_t(i).cash_ar50_comments,
                    lv_mfar_sale_line_copy_type_t(i).payment_code,
                    lv_mfar_sale_line_copy_type_t(i).uom_c,
                    lv_mfar_sale_line_copy_type_t(i).uom_cnvrn_factor,
                    lv_mfar_sale_line_copy_type_t(i).po_nbr,
                    lv_mfar_sale_line_copy_type_t(i).vendor_stk_nbr,
                    lv_mfar_sale_line_copy_type_t(i).billed_qty,
                    lv_mfar_sale_line_copy_type_t(i).avg_unit_cost,
                    lv_mfar_sale_line_copy_type_t(i).std_unit_cost,
                    lv_mfar_sale_line_copy_type_t(i).pc_flag,
                    lv_mfar_sale_line_copy_type_t(i).lsi_line_descr,
                    lv_mfar_sale_line_copy_type_t(i).h_inv_curr, --header_invoice_currency,
                    lv_mfar_sale_line_copy_type_t(i).h_cust_curr, --header_customer_currency,
                    lv_mfar_sale_line_copy_type_t(i).vendor_abbrev_c,
                    lv_mfar_sale_line_copy_type_t(i).vendor_nbr,
                    lv_mfar_sale_line_copy_type_t(i).vendor_name,
                    lv_mfar_sale_line_copy_type_t(i).gaap_f,
                    lv_mfar_sale_line_copy_type_t(i).leg_division,
                    lv_mfar_sale_line_copy_type_t(i).error_type,
                    lv_mfar_sale_line_copy_type_t(i).error_code,
                    lv_mfar_sale_line_copy_type_t(i).leg_coa,
                    lv_mfar_sale_line_copy_type_t(i).target_coa,
                    lv_mfar_sale_line_copy_type_t(i).gl_legal_entity,
                    lv_mfar_sale_line_copy_type_t(i).gl_acct,
                    lv_mfar_sale_line_copy_type_t(i).gl_oper_grp,
                    lv_mfar_sale_line_copy_type_t(i).gl_dept,
                    lv_mfar_sale_line_copy_type_t(i).gl_site,
                    lv_mfar_sale_line_copy_type_t(i).gl_ic,
                    lv_mfar_sale_line_copy_type_t(i).gl_projects,
                    lv_mfar_sale_line_copy_type_t(i).gl_fut_1,
                    lv_mfar_sale_line_copy_type_t(i).gl_fut_2,
                    lv_mfar_sale_line_copy_type_t(i).statement_id,
                    lv_mfar_sale_line_copy_type_t(i).transaction_curr_cd,
                    lv_mfar_sale_line_copy_type_t(i).transaction_amount,
                    lv_mfar_sale_line_copy_type_t(i).foreign_ex_rate,
                    lv_mfar_sale_line_copy_type_t(i).base_curr_cd,
                    lv_mfar_sale_line_copy_type_t(i).base_amount,
                    lv_mfar_sale_line_copy_type_t(i).subledger_nbr,
                    lv_mfar_sale_line_copy_type_t(i).subledger_name,
                    lv_mfar_sale_line_copy_type_t(i).batch_nbr,
                    lv_mfar_sale_line_copy_type_t(i).invoice_date,
                    lv_mfar_sale_line_copy_type_t(i).gl_allcon_comments,
                    lv_mfar_sale_line_copy_type_t(i).line_updated_by,
                    lv_mfar_sale_line_copy_type_t(i).line_updated_date,
                    lv_mfar_sale_line_copy_type_t(i).matching_key,
                    lv_mfar_sale_line_copy_type_t(i).matching_date,
                    lv_mfar_sale_line_copy_type_t(i).transaction_type,
                    lv_mfar_sale_line_copy_type_t(i).order_id,
                    lv_mfar_sale_line_copy_type_t(i).attribute1,
                    lv_mfar_sale_line_copy_type_t(i).attribute2,
                    lv_mfar_sale_line_copy_type_t(i).attribute3,
                    lv_mfar_sale_line_copy_type_t(i).attribute4,
                    lv_mfar_sale_line_copy_type_t(i).attribute5,
                    lv_mfar_sale_line_copy_type_t(i).attribute6,
                    lv_mfar_sale_line_copy_type_t(i).attribute7,
                    lv_mfar_sale_line_copy_type_t(i).attribute8,
                    lv_mfar_sale_line_copy_type_t(i).attribute9,
                    lv_mfar_sale_line_copy_type_t(i).attribute10,
                    lv_mfar_sale_line_copy_type_t(i).attribute11,
                    lv_mfar_sale_line_copy_type_t(i).attribute12,
                    sysdate,
                    lv_mfar_sale_line_copy_type_t(i).created_by,
                    sysdate,
                    lv_mfar_sale_line_copy_type_t(i).last_updated_by,
                    lv_mfar_sale_line_copy_type_t(i).customer_name,
                    lv_mfar_sale_line_copy_type_t(i).customer_nbr,
                    lv_mfar_sale_line_copy_type_t(i).cash_check_nbr,
                    lv_mfar_sale_line_copy_type_t(i).fx_rate_on_invoice,
                    lv_mfar_sale_line_copy_type_t(i).leg_seg_1_4,
                    lv_mfar_sale_line_copy_type_t(i).leg_seg_5_7,
                    lv_mfar_sale_line_copy_type_t(i).leg_loc_sr
                );

        END LOOP;

        CLOSE mfar_sale_line_copy_data_cur;
        COMMIT;
        logging_insert('MF AR SALE', p_batch_id, 30.3, 'SALE Line Copy insert Ends and Status insert starts', NULL,
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
            attribute2,
            attribute11,
            interface_id,
            ledger_name,
            created_by,
            created_date,
            last_updated_by,
            last_updated_date
        )
            SELECT
                line.header_id,
                line.line_id,
                'MF AR',
                lv_file_name,
                p_batch_id,
                'TRANSFORM_SUCCESS',
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
                'TRANSFORM_SUCCESS',
                hdr.account_date,
                line.interface_id,
                hdr.ledger_name,
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
                AND hdr.batch_id (+) = line.batch_id
                AND line.line_nbr = '-99999'
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t s
                    WHERE
                            s.header_id = line.header_id
                        AND s.batch_id = line.batch_id
                        AND s.line_id = line.line_id
                );

        COMMIT;
        logging_insert('MF AR SALE', p_batch_id, 30.4, 'Inserting records in status table ends', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('MF AR', p_batch_id, 30.11, 'Error in Cpy Line Procedure', err_msg,
                          sysdate);
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT216'
                                                                 || '_'
                                                                 || 'SALE', 'MF AR', err_msg);

    END wsc_ahcs_mfar_line_copy_p;

    PROCEDURE wsc_ledger_name_derivation (
        p_batch_id IN NUMBER
    ) IS

        lv_batch_id          NUMBER;
--    lv_header_id number := 71331;
/*
        CURSOR cur_error_header (
            lc_batch_id NUMBER
        ) IS
       /* SELECT
        1 tst,
            ROW_NUMBER()
            OVER(PARTITION BY hdr.header_id
                 ORDER BY
                     hdr.header_id
            )               row_number_data,
            hdr.*,
            line.attribute5 new_ledger_name
        FROM
            (
                SELECT
                    header_id,
                    attribute5
                FROM
                    wsc_ahcs_mfar_txn_line_t line
                WHERE
                    attribute5 IS NOT NULL
                    AND batch_id = lc_batch_id
                    AND EXISTS (
                        SELECT
                            1
                        FROM
                            wsc_ahcs_int_status_t s
                        WHERE
                            s.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                            AND batch_id = lc_batch_id
                            AND line.line_id = s.line_id
                    )
                GROUP BY
                    header_id,
                    attribute5
            )                          line,
            wsc_ahcs_mfar_txn_header_t hdr
        WHERE
                line.header_id = hdr.header_id
            AND hdr.batch_id = lc_batch_id*/
        /*    with test as
            (
                SELECT 
                    header_id,
                    attribute5
                FROM
                    wsc_ahcs_mfar_txn_line_t line
                WHERE
                    attribute5 IS NOT NULL
                    AND batch_id = lc_batch_id
                    AND EXISTS (
                        SELECT
                            1
                        FROM
                            wsc_ahcs_int_status_t s
                        WHERE
                            s.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                            AND batch_id = lc_batch_id
                            AND line.line_id = s.line_id
                    )
                GROUP BY
                    header_id,
                    attribute5
         )  
 SELECT /*+ index(hdr WSC_AHCS_MFAP_TXN_HEADER_BATCH_ID_I) */
      /*      1 tst,
            hdr.*,
            line.attribute5 new_ledger_name,
            ROW_NUMBER()
            OVER(PARTITION BY hdr.header_id
                 ORDER BY
                     hdr.header_id
            )       row_number_data           

        FROM
            test                   line,
            wsc_ahcs_mfar_txn_header_t hdr
        WHERE
                line.header_id = hdr.header_id
            AND hdr.batch_id = lc_batch_id
           ;
        /*ORDER BY
            hdr.header_id*/

        CURSOR cur_error_header IS
        WITH ln AS (
            SELECT /*+ MATERIALIZE*/
                line.header_id           header_id,
                line.attribute5          attribute5,
                led.static_ledger_number static_ledger_num,
                line.transaction_number  transaction_num
            FROM
                wsc_ahcs_mfar_txn_line_t line,
                wsc_ahcs_int_mf_ledger_t led
            WHERE
                    line.attribute5 = led.ledger_name
                AND led.sub_ledger = 'MF AR'
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
            || static_ledger_num trx_number,
            hdr.*,
            l.attribute5         new_ledger_name
        FROM
            ln                         l,
            wsc_ahcs_mfar_txn_header_t hdr
--            
        WHERE
                l.header_id = hdr.header_id
            AND hdr.batch_id = lv_batch_id;

        TYPE mfar_stg_hdr_type IS
            TABLE OF cur_error_header%rowtype;
        lv_mfar_stg_hdr_type mfar_stg_hdr_type;
    BEGIN
        lv_batch_id := p_batch_id;
        logging_insert('MF AR', p_batch_id, 28.6, 'Update Line table attribute 5 with new ledgername start.', NULL,
                      sysdate);
        UPDATE wsc_ahcs_mfar_txn_line_t line
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
                    wsc_ahcs_mfar_txn_header_t
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

        COMMIT;
        logging_insert('MF AR', p_batch_id, 28.7, 'Update Line table attribute 5 with new ledgername end.', NULL,
                      sysdate);
        FOR i IN cur_error_header LOOP
            INSERT INTO wsc_ahcs_mfar_txn_header_t (
                header_id,
                batch_id,
                transaction_type,
                ledger_name,
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
                statement_id,
                trans_ref,
                statement_amount,
                statement_date,
                statement_upd_by,
                statement_upd_date,
                posting_period,
                posting_year,
                error_type,
                error_code,
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
                creation_date,
                created_by,
                last_update_date,
                last_updated_by
            ) VALUES (
                wsc_mfar_header_s1.NEXTVAL,
                i.batch_id,
                i.transaction_type,
                i.new_ledger_name,
                i.transaction_date,
                i.trx_number,
                i.record_type,
                i.hdr_seq_nbr,
                i.interface_id,
                i.location,
                i.invoice_nbr,
                i.invoice_type,
                i.sale_order_nbr,
                i.customer_nbr,
                i.customer_name,
                i.continent,
                i.customer_type,
                i.payment_terms,
                i.invoice_date,
                i.invoice_due_date,
                i.invc_loc_iso_cntry,
                i.invoice_loc_div,
                i.ship_to_nbr,
                i.invoice_currency,
                i.customer_currency,
                i.fx_rate_on_invoice,
                i.ship_type,
                i.export_type,
                i.record_error_code,
                i.credit_type,
                i.non_ra_credit_type,
                i.ci_profile_type,
                i.amount_type,
                i.amount,
                i.amount_in_cust_curr,
                i.business_unit,
                i.ship_from_location,
                i.tax_invc_i,
                i.freight_vendor_nbr,
                i.freight_invoice_nbr,
                i.freight_terms,
                i.freight_invoice_date,
                i.cash_date,
                i.cash_batch_nbr,
                i.cash_code,
                i.cash_fx_rate,
                i.cash_check_nbr,
                i.cash_entry_date,
                i.cash_lockbox_id,
                i.gl_div_headqtr_loc,
                i.gl_div_hq_loc_bu,
                i.ship_from_loc_bu,
                i.ps_affiliate_bu,
                i.emea_flag,
                i.account_date,
                i.interface_desc_en,
                i.interface_desc_frn,
                i.cust_po,
                i.cust_credit_pref,
                i.bank_deposit_date,
                i.vendor_abbrev_c,
                i.item_uom_c,
                i.ib30_reason_c,
                i.ib30_memo,
                i.receiver_loc,
                i.receiver_nbr,
                i.ra_loc,
                i.ra_nbr,
                i.sales_rep,
                i.freight_bill_nbr,
                i.final_dest,
                i.freight_vendor_name,
                i.fiscal_date,
                i.matching_key,
                i.matching_date,
                i.gaap_amount,
                i.gaap_amount_in_cust_curr,
                i.journal_source_c,
                i.kava_f,
                i.statement_id,
                i.trans_ref,
                i.statement_amount,
                i.statement_date,
                i.statement_upd_by,
                i.statement_upd_date,
                i.posting_period,
                i.posting_year,
                i.error_type,
                i.error_code,
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
                sysdate,
                i.created_by,
                sysdate,
                i.last_updated_by
            );

        END LOOP;

--        OPEN cur_error_header(lv_batch_id);
--        LOOP
--            FETCH cur_error_header
--            BULK COLLECT INTO lv_mfar_stg_hdr_type LIMIT 400;
--            EXIT WHEN lv_mfar_stg_hdr_type.count = 0;
--            FORALL i IN 1..lv_mfar_stg_hdr_type.count
--                INSERT INTO wsc_ahcs_mfar_txn_header_t (
--                    header_id,
--                    batch_id,
--                    transaction_type,
--                    ledger_name,
--                    transaction_date,
--                    transaction_number,
--                    record_type,
--                    hdr_seq_nbr,
--                    interface_id,
--                    location,
--                    invoice_nbr,
--                    invoice_type,
--                    sale_order_nbr,
--                    customer_nbr,
--                    customer_name,
--                    continent,
--                    customer_type,
--                    payment_terms,
--                    invoice_date,
--                    invoice_due_date,
--                    invc_loc_iso_cntry,
--                    invoice_loc_div,
--                    ship_to_nbr,
--                    invoice_currency,
--                    customer_currency,
--                    fx_rate_on_invoice,
--                    ship_type,
--                    export_type,
--                    record_error_code,
--                    credit_type,
--                    non_ra_credit_type,
--                    ci_profile_type,
--                    amount_type,
--                    amount,
--                    amount_in_cust_curr,
--                    business_unit,
--                    ship_from_location,
--                    tax_invc_i,
--                    freight_vendor_nbr,
--                    freight_invoice_nbr,
--                    freight_terms,
--                    freight_invoice_date,
--                    cash_date,
--                    cash_batch_nbr,
--                    cash_code,
--                    cash_fx_rate,
--                    cash_check_nbr,
--                    cash_entry_date,
--                    cash_lockbox_id,
--                    gl_div_headqtr_loc,
--                    gl_div_hq_loc_bu,
--                    ship_from_loc_bu,
--                    ps_affiliate_bu,
--                    emea_flag,
--                    account_date,
--                    interface_desc_en,
--                    interface_desc_frn,
--                    cust_po,
--                    cust_credit_pref,
--                    bank_deposit_date,
--                    vendor_abbrev_c,
--                    item_uom_c,
--                    ib30_reason_c,
--                    ib30_memo,
--                    receiver_loc,
--                    receiver_nbr,
--                    ra_loc,
--                    ra_nbr,
--                    sales_rep,
--                    freight_bill_nbr,
--                    final_dest,
--                    freight_vendor_name,
--                    fiscal_date,
--                    matching_key,
--                    matching_date,
--                    gaap_amount,
--                    gaap_amount_in_cust_curr,
--                    journal_source_c,
--                    kava_f,
--                    statement_id,
--                    trans_ref,
--                    statement_amount,
--                    statement_date,
--                    statement_upd_by,
--                    statement_upd_date,
--                    posting_period,
--                    posting_year,
--                    error_type,
--                    error_code,
--                    attribute1,
--                    attribute2,
--                    attribute3,
--                    attribute4,
--                    attribute5,
--                    attribute6,
--                    attribute7,
--                    attribute8,
--                    attribute9,
--                    attribute10,
--                    attribute11,
--                    attribute12,
--                    creation_date,
--                    created_by,
--                    last_update_date,
--                    last_updated_by
--                ) VALUES (
--                    wsc_mfar_header_s1.NEXTVAL,
--                    lv_mfar_stg_hdr_type(i).batch_id,
--                    lv_mfar_stg_hdr_type(i).transaction_type,
--                    lv_mfar_stg_hdr_type(i).new_ledger_name,
--                    lv_mfar_stg_hdr_type(i).transaction_date,
--                    lv_mfar_stg_hdr_type(i).transaction_number
--                    || '_'
--                    || lv_mfar_stg_hdr_type(i).row_number_data,
--                    lv_mfar_stg_hdr_type(i).record_type,
--                    lv_mfar_stg_hdr_type(i).hdr_seq_nbr,
--                    lv_mfar_stg_hdr_type(i).interface_id,
--                    lv_mfar_stg_hdr_type(i).location,
--                    lv_mfar_stg_hdr_type(i).invoice_nbr,
--                    lv_mfar_stg_hdr_type(i).invoice_type,
--                    lv_mfar_stg_hdr_type(i).sale_order_nbr,
--                    lv_mfar_stg_hdr_type(i).customer_nbr,
--                    lv_mfar_stg_hdr_type(i).customer_name,
--                    lv_mfar_stg_hdr_type(i).continent,
--                    lv_mfar_stg_hdr_type(i).customer_type,
--                    lv_mfar_stg_hdr_type(i).payment_terms,
--                    lv_mfar_stg_hdr_type(i).invoice_date,
--                    lv_mfar_stg_hdr_type(i).invoice_due_date,
--                    lv_mfar_stg_hdr_type(i).invc_loc_iso_cntry,
--                    lv_mfar_stg_hdr_type(i).invoice_loc_div,
--                    lv_mfar_stg_hdr_type(i).ship_to_nbr,
--                    lv_mfar_stg_hdr_type(i).invoice_currency,
--                    lv_mfar_stg_hdr_type(i).customer_currency,
--                    lv_mfar_stg_hdr_type(i).fx_rate_on_invoice,
--                    lv_mfar_stg_hdr_type(i).ship_type,
--                    lv_mfar_stg_hdr_type(i).export_type,
--                    lv_mfar_stg_hdr_type(i).record_error_code,
--                    lv_mfar_stg_hdr_type(i).credit_type,
--                    lv_mfar_stg_hdr_type(i).non_ra_credit_type,
--                    lv_mfar_stg_hdr_type(i).ci_profile_type,
--                    lv_mfar_stg_hdr_type(i).amount_type,
--                    lv_mfar_stg_hdr_type(i).amount,
--                    lv_mfar_stg_hdr_type(i).amount_in_cust_curr,
--                    lv_mfar_stg_hdr_type(i).business_unit,
--                    lv_mfar_stg_hdr_type(i).ship_from_location,
--                    lv_mfar_stg_hdr_type(i).tax_invc_i,
--                    lv_mfar_stg_hdr_type(i).freight_vendor_nbr,
--                    lv_mfar_stg_hdr_type(i).freight_invoice_nbr,
--                    lv_mfar_stg_hdr_type(i).freight_terms,
--                    lv_mfar_stg_hdr_type(i).freight_invoice_date,
--                    lv_mfar_stg_hdr_type(i).cash_date,
--                    lv_mfar_stg_hdr_type(i).cash_batch_nbr,
--                    lv_mfar_stg_hdr_type(i).cash_code,
--                    lv_mfar_stg_hdr_type(i).cash_fx_rate,
--                    lv_mfar_stg_hdr_type(i).cash_check_nbr,
--                    lv_mfar_stg_hdr_type(i).cash_entry_date,
--                    lv_mfar_stg_hdr_type(i).cash_lockbox_id,
--                    lv_mfar_stg_hdr_type(i).gl_div_headqtr_loc,
--                    lv_mfar_stg_hdr_type(i).gl_div_hq_loc_bu,
--                    lv_mfar_stg_hdr_type(i).ship_from_loc_bu,
--                    lv_mfar_stg_hdr_type(i).ps_affiliate_bu,
--                    lv_mfar_stg_hdr_type(i).emea_flag,
--                    lv_mfar_stg_hdr_type(i).account_date,
--                    lv_mfar_stg_hdr_type(i).interface_desc_en,
--                    lv_mfar_stg_hdr_type(i).interface_desc_frn,
--                    lv_mfar_stg_hdr_type(i).cust_po,
--                    lv_mfar_stg_hdr_type(i).cust_credit_pref,
--                    lv_mfar_stg_hdr_type(i).bank_deposit_date,
--                    lv_mfar_stg_hdr_type(i).vendor_abbrev_c,
--                    lv_mfar_stg_hdr_type(i).item_uom_c,
--                    lv_mfar_stg_hdr_type(i).ib30_reason_c,
--                    lv_mfar_stg_hdr_type(i).ib30_memo,
--                    lv_mfar_stg_hdr_type(i).receiver_loc,
--                    lv_mfar_stg_hdr_type(i).receiver_nbr,
--                    lv_mfar_stg_hdr_type(i).ra_loc,
--                    lv_mfar_stg_hdr_type(i).ra_nbr,
--                    lv_mfar_stg_hdr_type(i).sales_rep,
--                    lv_mfar_stg_hdr_type(i).freight_bill_nbr,
--                    lv_mfar_stg_hdr_type(i).final_dest,
--                    lv_mfar_stg_hdr_type(i).freight_vendor_name,
--                    lv_mfar_stg_hdr_type(i).fiscal_date,
--                    lv_mfar_stg_hdr_type(i).matching_key,
--                    lv_mfar_stg_hdr_type(i).matching_date,
--                    lv_mfar_stg_hdr_type(i).gaap_amount,
--                    lv_mfar_stg_hdr_type(i).gaap_amount_in_cust_curr,
--                    lv_mfar_stg_hdr_type(i).journal_source_c,
--                    lv_mfar_stg_hdr_type(i).kava_f,
--                    lv_mfar_stg_hdr_type(i).statement_id,
--                    lv_mfar_stg_hdr_type(i).trans_ref,
--                    lv_mfar_stg_hdr_type(i).statement_amount,
--                    lv_mfar_stg_hdr_type(i).statement_date,
--                    lv_mfar_stg_hdr_type(i).statement_upd_by,
--                    lv_mfar_stg_hdr_type(i).statement_upd_date,
--                    lv_mfar_stg_hdr_type(i).posting_period,
--                    lv_mfar_stg_hdr_type(i).posting_year,
--                    lv_mfar_stg_hdr_type(i).error_type,
--                    lv_mfar_stg_hdr_type(i).error_code,
--                    lv_mfar_stg_hdr_type(i).attribute1,
--                    lv_mfar_stg_hdr_type(i).attribute2,
--                    lv_mfar_stg_hdr_type(i).attribute3,
--                    lv_mfar_stg_hdr_type(i).attribute4,
--                    lv_mfar_stg_hdr_type(i).attribute5,
--                    lv_mfar_stg_hdr_type(i).attribute6,
--                    lv_mfar_stg_hdr_type(i).header_id,
--                    lv_mfar_stg_hdr_type(i).attribute8,
--                    lv_mfar_stg_hdr_type(i).attribute9,
--                    lv_mfar_stg_hdr_type(i).attribute10,
--                    lv_mfar_stg_hdr_type(i).attribute11,
--                    lv_mfar_stg_hdr_type(i).attribute12,
--                    sysdate,
--                    lv_mfar_stg_hdr_type(i).created_by,
--                    sysdate,
--                    lv_mfar_stg_hdr_type(i).last_updated_by
--                );
--
--        END LOOP;
--
--        CLOSE cur_error_header;
--        COMMIT;
        logging_insert('MF AR', p_batch_id, 28.8, 'Header record insertion ends.', NULL,
                      sysdate);
        UPDATE wsc_ahcs_mfar_txn_line_t line
        SET
            line.last_update_date = sysdate,
            header_id = (
                SELECT
                    header_id
                FROM
                    wsc_ahcs_mfar_txn_header_t hdr
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
                    wsc_ahcs_mfar_txn_header_t hdr
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

        COMMIT;
        logging_insert('MF AR', p_batch_id, 28.9, 'Update Header Id and transaction number in Line table ends.', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_status_t sts
        SET
            sts.last_updated_date = sysdate,
            header_id = (
                SELECT
                    header_id
                FROM
                    wsc_ahcs_mfar_txn_line_t line
                WHERE
                        line.line_id = sts.line_id
                    AND line.batch_id = sts.batch_id
                    AND line.batch_id = lv_batch_id
            ),
            attribute3 = (
                SELECT
                    transaction_number
                FROM
                    wsc_ahcs_mfar_txn_line_t line
                WHERE
                        line.line_id = sts.line_id
                    AND line.batch_id = sts.batch_id
                    AND line.batch_id = lv_batch_id
            )
        WHERE
                batch_id = lv_batch_id
            AND sts.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' );

        COMMIT;
        logging_insert('MF AR', p_batch_id, 28.10, 'Update header id and transaction number in status table ends.', NULL,
                      sysdate);
        DELETE FROM wsc_ahcs_mfar_txn_header_t
        WHERE
            header_id IN (
                SELECT DISTINCT
                    attribute7
                FROM
                    wsc_ahcs_mfar_txn_header_t
                WHERE
                        batch_id = lv_batch_id
                    AND attribute7 IS NOT NULL
            )
            AND batch_id = lv_batch_id;

        COMMIT;
        logging_insert('MF AR', p_batch_id, 28.11, 'Delete the old header record with multi ledger ends.', NULL,
                      sysdate);
    END;

    PROCEDURE data_validation (
        p_batch_id IN NUMBER
    ) IS

        lv_header_err_msg    VARCHAR2(2000) := NULL;
        lv_line_err_msg      VARCHAR2(2000) := NULL;
        lv_header_err_flag   VARCHAR2(100) := 'false';
        lv_line_err_flag     VARCHAR2(100) := 'false';
        lv_count_sucss       NUMBER := 0;
        retcode              VARCHAR2(50);
        l_system             VARCHAR2(10);
        TYPE wsc_header_col_value_type IS
            VARRAY(17) OF VARCHAR2(50); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING HEADER OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        lv_header_col_value  wsc_header_col_value_type := wsc_header_col_value_type('RECORD_TYPE', 'HDR_SEQ_NBR', 'INTERFACE_ID', 'LOCATION',
        'INVOICE_NBR',
                                                                                  'CUSTOMER_NBR', 'CUSTOMER_NAME', 'CONTINENT', 'INVOICE_DATE',
                                                                                  'INVOICE_LOC_DIV',
                                                                                  'INVOICE_CURRENCY', 'CUSTOMER_CURRENCY', 'FX_RATE_ON_INVOICE',
                                                                                  'AMOUNT', 'AMOUNT_IN_CUST_CURR',
                                                                                  'BUSINESS_UNIT', 'ACCOUNT_DATE');
        TYPE wsc_line_col_value_type IS
            VARRAY(8) OF VARCHAR2(50); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING LINE OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        lv_line_col_value    wsc_line_col_value_type := wsc_line_col_value_type('HDR_SEQ_NBR', 'LINE_SEQ_NUMBER', 'AMOUNT_TYPE', 'AMOUNT',
        'AMOUNT_IN_CUST_CURR',
                                                                            'INVOICE_CURRENCY', 'CUSTOMER_CURRENCY', 'GL_AXE_LOCATION');


/************ @@@@@ INITIALIZE HEADER AND LINE FLAG TABLE TYPE VARIABLES TO MATCH THE COUNT OF HEADER AND LINE @@@@@ ************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        TYPE wsc_ahcs_mfar_txn_header_type IS
            TABLE OF INTEGER;
        lv_error_mfar_header wsc_ahcs_mfar_txn_header_type := wsc_ahcs_mfar_txn_header_type('1', '1', '1', '1', '1',
                                                                                           '1', '1', '1', '1', '1',
                                                                                           '1', '1', '1', '1', '1',
                                                                                           '1', '1', '1', '1', '1',
                                                                                           '1', '1', '1', '1', '1');
        TYPE wsc_ahcs_mfar_txn_line_type IS
            TABLE OF INTEGER;
        lv_error_mfar_line   wsc_ahcs_mfar_txn_line_type := wsc_ahcs_mfar_txn_line_type('1', '1', '1', '1', '1',
                                                                                     '1', '1', '1', '1', '1',
                                                                                     '1', '1', '1', '1', '1'); 


-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from LINE STAGING TABLETHAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_wsc_mfar_line (
            cur_p_hdr_id VARCHAR2
        ) IS
        SELECT
            line_id,
            hdr_seq_nbr,
         --   leg_location,
            line_seq_number,
          --  line_type,
            amount_type,
            amount,
            amount_in_cust_curr,
            invoice_currency,
            customer_currency,
            leg_loc
        FROM
            wsc_ahcs_mfar_txn_line_t
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
            record_type,
            hdr_seq_nbr,
            interface_id,
            location,
            invoice_nbr,
            customer_nbr,
            customer_name,
            continent,
  --          customer_type,
            invoice_date,
            invoice_loc_div,
            invoice_currency,
            customer_currency,
            fx_rate_on_invoice,
            amount,
            amount_in_cust_curr,
            business_unit,
  --          gl_div_headqtr_loc,
            account_date
--            interface_desc_en,
--            interface_desc_frn,
--            fiscal_date
        FROM
            wsc_ahcs_mfar_txn_header_t
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
        WITH line_cr AS (
            SELECT
                header_id,
                abs(SUM(amount)) sum_data
            FROM
                wsc_ahcs_mfar_txn_line_t
            WHERE
                db_cr_flag IS NULL
--                    = (
--                        CASE
--                            WHEN interface_id = 'SALE' THEN
--                                NULL
----                            WHEN interface_id = 'CASH' THEN
----                                'CR'
--                        END
--                    )
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ), line_dr AS (
            SELECT
                header_id,
                abs(SUM(amount)) sum_data
            FROM
                wsc_ahcs_mfar_txn_line_t
            WHERE
                db_cr_flag IS NULL
--                    = (
--                        CASE
--                            WHEN interface_id = 'SALE' THEN
--                                NULL
----                            WHEN interface_id = 'CASH' THEN
----                                'DR'
--                        END
--                    )
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ), header_amt AS (
            SELECT
                header_id,
                abs(SUM(amount)) sum_data
            FROM
                wsc_ahcs_mfar_txn_header_t
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
                wsc_ahcs_mfar_txn_line_t
            WHERE
                    db_cr_flag = 'CR'
                AND interface_id != 'SALE'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ), line_dr AS (
            SELECT
                header_id,
                abs(SUM(amount)) sum_data
            FROM
                wsc_ahcs_mfar_txn_line_t
            WHERE
                    db_cr_flag = 'DR'
                AND interface_id != 'SALE'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        )
        SELECT
            nvl(cr_hdr, dr_hdr) header_id
        FROM
            (
                SELECT
                    l_cr.header_id cr_hdr,
                    l_dr.header_id dr_hdr,
                    l_cr.sum_data  cr_sum,
                    l_dr.sum_data  dr_sum
                FROM
                    line_cr l_cr,
                    line_dr l_dr
                WHERE
                        nvl(l_dr.sum_data, 0) <> nvl(l_cr.sum_data, 0)
                    AND l_dr.header_id (+) = l_cr.header_id
                UNION
                SELECT
                    l_cr.header_id cr_hdr,
                    l_dr.header_id dr_hdr,
                    l_cr.sum_data  cr_sum,
                    l_dr.sum_data  dr_sum
                FROM
                    line_cr l_cr,
                    line_dr l_dr
                WHERE
                        nvl(l_dr.sum_data, 0) <> nvl(l_cr.sum_data, 0)
                    AND l_dr.header_id = l_cr.header_id (+)
            );


--        WITH line_cr AS (
--            SELECT
--                header_id,
--                abs(SUM(amount)) sum_data
--            FROM
--                wsc_ahcs_mfar_txn_line_t
--            WHERE
--                    db_cr_flag = 'CR'
--                AND interface_id != 'SALE'
--                AND batch_id = cur_p_batch_id
--            GROUP BY
--                header_id
--        ), line_dr AS (
--            SELECT
--                header_id,
--                abs(SUM(amount)) sum_data
--            FROM
--                wsc_ahcs_mfar_txn_line_t
--            WHERE
--                    db_cr_flag = 'DR'
--                AND interface_id != 'SALE'
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
--                l_cr.header_id = l_dr.header_id
--            AND ( l_cr.sum_data <> l_dr.sum_data );

		------------------------------------------------------------------------------------------------------------------------------------------------

        TYPE line_validation_type IS
            TABLE OF cur_line_validation%rowtype;
        lv_line_validation   line_validation_type;
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
        logging_insert('MF AR', p_batch_id, 11, 'Start of validation', NULL,
                      sysdate);
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
                        error_msg = '302|Header Trxn amount mismatch with Line DR/CR Amount',
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
                logging_insert('MF AR', p_batch_id, 11.1, 'Exception while updating status as Header Line amount mismatch.', sqlerrm,
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
        logging_insert('MF AR', p_batch_id, 12, 'Validate line cr db amount mismatch.', NULL,
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
                logging_insert('MF AR', p_batch_id, 12.1, 'exception Validate line totals', sqlerrm,
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
        logging_insert('MF AR', p_batch_id, 13, 'Validate header mandatory fields.', NULL,
                      sysdate);
        FOR header_id_f IN cur_header_id(p_batch_id) LOOP
            lv_header_err_flag := 'false';
            lv_header_err_msg := NULL;
            lv_error_mfar_header := wsc_ahcs_mfar_txn_header_type('1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1'); 

/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
/**** @@@ Review/ Change function name to match data type of colum. Also pass the appropriate column name from the cursor @@@@ ******/
/**** @@@ Add more rows if there are more columns to be validated and match it with right function names                       ******/
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/

            lv_error_mfar_header(1) := is_varchar2_null(header_id_f.record_type);
            lv_error_mfar_header(2) := is_varchar2_null(header_id_f.hdr_seq_nbr);
            lv_error_mfar_header(3) := is_varchar2_null(header_id_f.interface_id);
            lv_error_mfar_header(4) := is_varchar2_null(header_id_f.location);
            lv_error_mfar_header(5) := is_varchar2_null(header_id_f.invoice_nbr);
            lv_error_mfar_header(6) := is_varchar2_null(header_id_f.customer_nbr);
            lv_error_mfar_header(7) := is_varchar2_null(header_id_f.customer_name);
            lv_error_mfar_header(8) := is_varchar2_null(header_id_f.continent);
           -- lv_error_mfar_header(8) := is_varchar2_null(header_id_f.customer_type);
            lv_error_mfar_header(9) := is_date_null(header_id_f.invoice_date);
            lv_error_mfar_header(10) := is_varchar2_null(header_id_f.invoice_loc_div);
            lv_error_mfar_header(11) := is_varchar2_null(header_id_f.invoice_currency);
            lv_error_mfar_header(12) := is_varchar2_null(header_id_f.customer_currency);
            lv_error_mfar_header(13) := is_number_null(header_id_f.fx_rate_on_invoice);
            lv_error_mfar_header(14) := is_number_null(header_id_f.amount);
            lv_error_mfar_header(15) := is_number_null(header_id_f.amount_in_cust_curr);
            lv_error_mfar_header(16) := is_varchar2_null(header_id_f.business_unit);
    --        lv_error_mfar_header(17) := is_varchar2_null(header_id_f.gl_div_headqtr_loc);
            lv_error_mfar_header(17) := is_date_null(header_id_f.account_date);
--            lv_error_mfar_header(19) := is_varchar2_null(header_id_f.interface_desc_en);
--            lv_error_mfar_header(20) := is_varchar2_null(header_id_f.interface_desc_frn);
--            lv_error_mfar_header(21) := is_varchar2_null(header_id_f.fiscal_date);
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
      --    logging_insert (null,p_batch_id,6,'lv_error_poc_header',null,sysdate);
            FOR i IN 1..20 LOOP
                IF lv_error_mfar_header(i) = 0 THEN
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

            FOR wsc_mfar_line IN cur_wsc_mfar_line(header_id_f.header_id) LOOP
                lv_line_err_flag := 'false';
                lv_line_err_msg := NULL;
                lv_error_mfar_line := wsc_ahcs_mfar_txn_line_type('1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1');

                lv_error_mfar_line(1) := is_varchar2_null(wsc_mfar_line.hdr_seq_nbr);
        --        lv_error_mfar_line(2) := is_varchar2_null(wsc_mfar_line.leg_location);
                lv_error_mfar_line(2) := is_varchar2_null(wsc_mfar_line.line_seq_number);
           --     lv_error_mfar_line(4) := is_varchar2_null(wsc_mfar_line.line_type);
                lv_error_mfar_line(3) := is_varchar2_null(wsc_mfar_line.amount_type);
                lv_error_mfar_line(4) := is_number_null(wsc_mfar_line.amount);
                lv_error_mfar_line(5) := is_number_null(wsc_mfar_line.amount_in_cust_curr);
                lv_error_mfar_line(6) := is_varchar2_null(wsc_mfar_line.invoice_currency);
                lv_error_mfar_line(7) := is_varchar2_null(wsc_mfar_line.customer_currency);
                lv_error_mfar_line(8) := is_varchar2_null(wsc_mfar_line.leg_loc);
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
         --   logging_insert (null,p_batch_id,10,'lv_error_poc_line',null,sysdate);
                FOR j IN 1..10 LOOP
                    IF lv_error_mfar_line(j) = 0 THEN
                        lv_line_err_msg := lv_line_err_msg
                                           || '300|Missng value of '
                                           || lv_line_col_value(j)
                                           || '. ';
                        lv_line_err_flag := 'true';
                    END IF;
                END LOOP;
--logging_insert (null,p_batch_id,11,'lv_error_poc_line',null,sysdate);
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
                        AND line_id = wsc_mfar_line.line_id;

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
        logging_insert('MF AR', p_batch_id, 14, 'Validating header and line mandatory fields ends.', NULL,
                      sysdate);
        BEGIN
            logging_insert('MF AR', p_batch_id, 15, 'Start updating validation status in status table.', NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'VALIDATION_FAILED',
                error_msg = '300|Missing value of HDR_SEQ_NBR',
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
            logging_insert('MF AR', p_batch_id, 16, 'Status field updated in status table.', NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                attribute2 = 'VALIDATION_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND attribute2 IS NULL;

            COMMIT;
            logging_insert('MF AR', p_batch_id, 17, 'Attribute2 field updated in status table.', NULL,
                          sysdate);
            OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_sucss;
            CLOSE cur_count_sucss;
            logging_insert('MF AR', p_batch_id, 18, 'Count success records.', lv_count_sucss,
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
                    wsc_ahcs_mfar_validation_transformation_pkg.leg_coa_transformation(p_batch_id);
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
            logging_insert('MF AR', p_batch_id, 40, 'end data_validation', NULL,
                          sysdate);
            logging_insert('MF AR', p_batch_id, 80, 'Dashboard Start', NULL,
                          sysdate);
            wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
            logging_insert('MF AR', p_batch_id, 81, 'Dashboard End', NULL,
                          sysdate);
        END;

        DELETE FROM wsc_ahcs_mfar_txn_tmp_t
        WHERE
            batch_id = p_batch_id;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT216'
                                                                 || '_'
                                                                 || l_system, 'MF AR', sqlerrm);
    END data_validation;

    PROCEDURE cresus_data_validation (
        p_batch_id IN NUMBER
    ) IS

        lv_header_err_msg    VARCHAR2(2000) := NULL;
        lv_line_err_msg      VARCHAR2(2000) := NULL;
        lv_header_err_flag   VARCHAR2(100) := 'false';
        lv_line_err_flag     VARCHAR2(100) := 'false';
        lv_count_sucss       NUMBER := 0;
        retcode              VARCHAR2(50);
        l_system             VARCHAR2(10);
        cresus_tmp_batch_id  NUMBER;
        TYPE wsc_header_col_value_type IS
            VARRAY(5) OF VARCHAR2(50); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING HEADER OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        lv_header_col_value  wsc_header_col_value_type := wsc_header_col_value_type('RECORD_TYPE', 'HDR_SEQ_NBR', 'INTERFACE_ID', 'BUSINESS_UNIT',
        'ACCOUNT_DATE');
        TYPE wsc_line_col_value_type IS
            VARRAY(7) OF VARCHAR2(50); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING LINE OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        lv_line_col_value    wsc_line_col_value_type := wsc_line_col_value_type('HDR_SEQ_NBR', 'LINE_SEQ_NUMBER', 'TRANSACTION_CURR_CD',
        'TRANSACTION_AMOUNT', 'BASE_CURR_CD',
                                                                            'BASE_AMOUNT', 'STATEMENT_ID');


/************ @@@@@ INITIALIZE HEADER AND LINE FLAG TABLE TYPE VARIABLES TO MATCH THE COUNT OF HEADER AND LINE @@@@@ ************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        TYPE wsc_ahcs_mfar_txn_header_type IS
            TABLE OF INTEGER;
        lv_error_mfar_header wsc_ahcs_mfar_txn_header_type := wsc_ahcs_mfar_txn_header_type('1', '1', '1', '1', '1',
                                                                                           '1', '1', '1', '1', '1');
        TYPE wsc_ahcs_mfar_txn_line_type IS
            TABLE OF INTEGER;
        lv_error_mfar_line   wsc_ahcs_mfar_txn_line_type := wsc_ahcs_mfar_txn_line_type('1', '1', '1', '1', '1',
                                                                                     '1', '1', '1', '1', '1'); 


-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from LINE STAGING TABLETHAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_wsc_mfar_line (
            cur_p_hdr_id VARCHAR2
        ) IS
        SELECT
            line_id,
            hdr_seq_nbr,
            line_seq_number,
            transaction_curr_cd,
            transaction_amount,
            base_curr_cd,
            base_amount,
            statement_id
        FROM
            wsc_ahcs_mfar_txn_line_t
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
            record_type,
            hdr_seq_nbr,
            interface_id,
            business_unit,
--            invoice_currency,
--            statement_amount,
--            continent,
--            interface_desc_en,
            account_date
          --  transaction_type
        FROM
            wsc_ahcs_mfar_txn_header_t
        WHERE
            batch_id = cur_p_batch_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/

		------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will do a 3-way match per transaction between total of header , sum of debits at line & sum of credits at line
        -- and identified if there is a mismatch between these.
        -- All header IDs with such mismatches will be fetched for subsequent flagging.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        /******* @@@@@@@@ Modify this cursor to reflect the header and line tables. Also verify the column names are correct @@@@@@@ ********/
--        CURSOR cur_header_validation (
--            cur_p_batch_id NUMBER
--        ) IS
--        WITH line_cr AS (
--            SELECT
--                header_id,
--                abs(SUM(base_amount)) sum_data
--            FROM
--                wsc_ahcs_mfar_txn_line_t
--            WHERE
--                    db_cr_flag = 'CR'
--                AND batch_id = cur_p_batch_id
--            GROUP BY
--                header_id
--        ), line_dr AS (
--            SELECT
--                header_id,
--                abs(SUM(base_amount)) sum_data
--            FROM
--                wsc_ahcs_mfar_txn_line_t
--            WHERE
--                    db_cr_flag = 'DR'
--                AND batch_id = cur_p_batch_id
--            GROUP BY
--                header_id
--        ), header_amt AS (
--            SELECT
--                header_id,
--                abs(SUM(statement_amount)) sum_data
--            FROM
--                wsc_ahcs_mfar_txn_header_t
--            WHERE
--                batch_id = cur_p_batch_id
--            GROUP BY
--                header_id
--        )
--        SELECT
--            l_cr.header_id
--        FROM
--            line_cr    l_cr,
--            line_dr    l_dr,
--            header_amt h_amt
--        WHERE
--                l_cr.header_id = h_amt.header_id
--            AND l_dr.header_id = h_amt.header_id
--            AND ( l_dr.sum_data <> h_amt.sum_data
--                  OR l_cr.sum_data <> h_amt.sum_data )
--            AND l_dr.header_id = l_cr.header_id;
--		------------------------------------------------------------------------------------------------------------------------------------------------
--
--        TYPE header_validation_type IS
--            TABLE OF cur_header_validation%rowtype;
--        lv_header_validation header_validation_type;


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
                abs(SUM(base_amount)) sum_data
            FROM
                wsc_ahcs_mfar_txn_line_t
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
                wsc_ahcs_mfar_txn_line_t
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
                    l_cr.header_id cr_hdr,
                    l_dr.header_id dr_hdr,
                    l_cr.sum_data  cr_sum,
                    l_dr.sum_data  dr_sum
                FROM
                    line_cr l_cr,
                    line_dr l_dr
                WHERE
                        nvl(l_dr.sum_data, 0) <> nvl(l_cr.sum_data, 0)
                    AND l_dr.header_id (+) = l_cr.header_id
                UNION
                SELECT
                    l_cr.header_id cr_hdr,
                    l_dr.header_id dr_hdr,
                    l_cr.sum_data  cr_sum,
                    l_dr.sum_data  dr_sum
                FROM
                    line_cr l_cr,
                    line_dr l_dr
                WHERE
                        nvl(l_dr.sum_data, 0) <> nvl(l_cr.sum_data, 0)
                    AND l_dr.header_id = l_cr.header_id (+)
            );

		------------------------------------------------------------------------------------------------------------------------------------------------

        TYPE line_validation_type IS
            TABLE OF cur_line_validation%rowtype;
        lv_line_validation   line_validation_type;
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
        logging_insert('MF AR', p_batch_id, 11, 'Start of validation', NULL,
                      sysdate);
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
                wsc_ahcs_mfar_txn_header_t h
            WHERE
                h.batch_id = p_batch_id;

        END;

--        BEGIN
--            OPEN cur_header_validation(p_batch_id);
--            LOOP
--                FETCH cur_header_validation
--                BULK COLLECT INTO lv_header_validation LIMIT 100;
--                EXIT WHEN lv_header_validation.count = 0;
--                FORALL i IN 1..lv_header_validation.count
--                    UPDATE wsc_ahcs_int_status_t
--                    SET
--                        status = 'VALIDATION_FAILED',
--                        error_msg = '302|Header Trxn amount mismatch with Line DR/CR Amount',
--                        reextract_required = 'Y',
--                        attribute1 = 'H',
--                        attribute2 = 'VALIDATION_FAILED',
--                        last_updated_date = sysdate
--                    WHERE
--                            batch_id = p_batch_id
--                        AND header_id = lv_header_validation(i).header_id;
--
--            END LOOP;
--
--            CLOSE cur_header_validation;
--            COMMIT;
--        EXCEPTION
--            WHEN OTHERS THEN
--                logging_insert('MF AR', p_batch_id, 11.1, 'exception in Header STATEMENT_AMOUNT mismatch with Line DR/CR Amount', sqlerrm,
--                              sysdate);
--                dbms_output.put_line('Error with Query:  ' || sqlerrm);
--        END;

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
        logging_insert('MF AR', p_batch_id, 12, 'Validate line cr db amount mismatch.', NULL,
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
                logging_insert('MF AR', p_batch_id, 12.1, 'Exception in BASE_AMOUNT cr db mismatch validation.', sqlerrm,
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
        logging_insert('MF AR', p_batch_id, 13, 'Validate header mandatory fields.', NULL,
                      sysdate);
        FOR header_id_f IN cur_header_id(p_batch_id) LOOP
            lv_header_err_flag := 'false';
            lv_header_err_msg := NULL;
            lv_error_mfar_header := wsc_ahcs_mfar_txn_header_type('1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1'); 

/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
/**** @@@ Review/ Change function name to match data type of colum. Also pass the appropriate column name from the cursor @@@@ ******/
/**** @@@ Add more rows if there are more columns to be validated and match it with right function names                       ******/
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/

            lv_error_mfar_header(1) := is_varchar2_null(header_id_f.record_type);
            lv_error_mfar_header(2) := is_varchar2_null(header_id_f.hdr_seq_nbr);
            lv_error_mfar_header(3) := is_varchar2_null(header_id_f.interface_id);
            lv_error_mfar_header(4) := is_varchar2_null(header_id_f.business_unit);
       --     lv_error_mfar_header(5) := is_varchar2_null(header_id_f.invoice_currency);
--            lv_error_mfar_header(6) := is_number_null(header_id_f.statement_amount);
--            lv_error_mfar_header(7) := is_varchar2_null(header_id_f.continent);
--            lv_error_mfar_header(8) := is_varchar2_null(header_id_f.interface_desc_en);
            lv_error_mfar_header(5) := is_date_null(header_id_f.account_date);
    --        lv_error_mfar_header(10) := is_varchar2_null(header_id_f.transaction_type);
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
      --    logging_insert (null,p_batch_id,6,'lv_error_poc_header',null,sysdate);
            FOR i IN 1..7 LOOP
                IF lv_error_mfar_header(i) = 0 THEN
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

            FOR wsc_mfar_line IN cur_wsc_mfar_line(header_id_f.header_id) LOOP
                lv_line_err_flag := 'false';
                lv_line_err_msg := NULL;
                lv_error_mfar_line := wsc_ahcs_mfar_txn_line_type('1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1');

                lv_error_mfar_line(1) := is_varchar2_null(wsc_mfar_line.hdr_seq_nbr);
                lv_error_mfar_line(2) := is_varchar2_null(wsc_mfar_line.line_seq_number);
--                lv_error_mfar_line(4) := is_varchar2_null(wsc_mfar_line.leg_bu);
--                lv_error_mfar_line(5) := is_varchar2_null(wsc_mfar_line.leg_acct);
--                lv_error_mfar_line(6) := is_varchar2_null(wsc_mfar_line.leg_loc);
--                lv_error_mfar_line(7) := is_varchar2_null(wsc_mfar_line.leg_dept);
--                lv_error_mfar_line(8) := is_varchar2_null(wsc_mfar_line.leg_vendor);
--                lv_error_mfar_line(9) := is_varchar2_null(wsc_mfar_line.leg_affiliate);
                lv_error_mfar_line(3) := is_varchar2_null(wsc_mfar_line.transaction_curr_cd);
                lv_error_mfar_line(4) := is_number_null(wsc_mfar_line.transaction_amount);
                --lv_error_mfar_line(12) := is_number_null(wsc_mfar_line.foreign_ex_rate);
                lv_error_mfar_line(5) := is_varchar2_null(wsc_mfar_line.base_curr_cd);
                lv_error_mfar_line(6) := is_number_null(wsc_mfar_line.base_amount);
                lv_error_mfar_line(7) := is_varchar2_null(wsc_mfar_line.statement_id);
--                lv_error_mfar_line(15) := is_varchar2_null(wsc_mfar_line.leg_division);
--                lv_error_mfar_line(16) := is_varchar2_null(wsc_mfar_line.subledger_nbr);
--                lv_error_mfar_line(17) := is_varchar2_null(wsc_mfar_line.subledger_name);
--                lv_error_mfar_line(18) := is_varchar2_null(wsc_mfar_line.batch_nbr);
--                lv_error_mfar_line(19) := is_varchar2_null(wsc_mfar_line.invoice_nbr);
--                lv_error_mfar_line(20) := is_date_null(wsc_mfar_line.invoice_date);
--                lv_error_mfar_line(21) := is_varchar2_null(wsc_mfar_line.gl_allcon_comments);
--                lv_error_mfar_line(22) := is_varchar2_null(wsc_mfar_line.line_updated_by);
--                lv_error_mfar_line(23) := is_date_null(wsc_mfar_line.line_updated_date);
--                lv_error_mfar_line(24) := is_varchar2_null(wsc_mfar_line.line_type);
--                lv_error_mfar_line(25) := is_varchar2_null(wsc_mfar_line.transaction_type);
--                lv_error_mfar_line(26) := is_varchar2_null(wsc_mfar_line.order_id);
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
         --   logging_insert (null,p_batch_id,10,'lv_error_poc_line',null,sysdate);
                FOR j IN 1..8 LOOP
                    IF lv_error_mfar_line(j) = 0 THEN
                        lv_line_err_msg := lv_line_err_msg
                                           || '300|Missing value of '
                                           || lv_line_col_value(j)
                                           || '. ';
                        lv_line_err_flag := 'true';
                    END IF;
                END LOOP;
--logging_insert (null,p_batch_id,11,'lv_error_poc_line',null,sysdate);
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
                        AND line_id = wsc_mfar_line.line_id;

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
        logging_insert('MF AR', p_batch_id, 14, 'Validation Header and Line mandatory fields ends.', NULL,
                      sysdate);
        BEGIN
            logging_insert('MF AR', p_batch_id, 15, 'Start updating validation status in status table.', NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'VALIDATION_FAILED',
                error_msg = '300|Missing value of HDR_SEQ_NBR',
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
            logging_insert('MF AR', p_batch_id, 16, 'Status field updated in status table.', NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                attribute2 = 'VALIDATION_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND attribute2 IS NULL;

            COMMIT;
            logging_insert('MF AR', p_batch_id, 17, 'Attribute2 field updated in status table.', NULL,
                          sysdate);
            OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_sucss;
            CLOSE cur_count_sucss;
            logging_insert('MF AR', p_batch_id, 18, 'Count success records.', lv_count_sucss,
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
                    wsc_ahcs_mfar_validation_transformation_pkg.leg_coa_transformation(p_batch_id);
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
            logging_insert('MF AR', p_batch_id, 40, 'end data_validation', NULL,
                          sysdate);
            logging_insert('MF AR', p_batch_id, 80, 'Dashboard Start', NULL,
                          sysdate);
            wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
            logging_insert('MF AR', p_batch_id, 81, 'Dashboard End', NULL,
                          sysdate);
        END;

      --delete data from temp table for this batch id                      
        DELETE FROM wsc_ahcs_cres_txn_tmp_t
        WHERE
            batch_id = cresus_tmp_batch_id;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT240'
                                                                 || '_'
                                                                 || l_system, 'MF AR', sqlerrm);
    END cresus_data_validation;

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
        CURSOR cur_update_trxn_line_err IS
        SELECT
            line.batch_id,
            line.header_id,
            line.line_id,
            line.target_coa
        FROM
            wsc_ahcs_mfar_txn_line_t line,
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
            wsc_ahcs_mfar_txn_line_t line
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
    --                    wsc_ahcs_mfar_txn_line_t    line,
    --                    wsc_ahcs_int_status_t     status
    ----                    wsc_ahcs_mfar_txn_header_t  header
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
            line.leg_bu,
            line.leg_acct,
            line.leg_dept,
            line.leg_loc,
            line.leg_vendor,
            line.leg_affiliate
    --            line.leg_seg7,
    --            substr(line.leg_coa, instr(line.leg_coa, '.', 1, 7) + 1)                      AS ledger_name
        FROM
            wsc_ahcs_mfar_txn_line_t line
    --              , wsc_ahcs_mfar_txn_header_t header
        WHERE
                line.batch_id = p_batch_id 
    --			   and line.batch_id = header.batch_id
    --			   and line.header_id = header.header_id
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        /*
        cursor cur_inserting_ccid_table is
            select distinct LEG_COA, TARGET_COA from wsc_ahcs_mfar_txn_line_t
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
                        wsc_ahcs_mfar_txn_line_t line,
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
    --                wsc_ahcs_mfar_txn_line_t
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
    --                wsc_ahcs_mfar_txn_line_t
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

        CURSOR cur_ledger_name IS
        WITH main_data AS (
            SELECT  /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE) */
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
                        wsc_ahcs_mfar_txn_line_t line,
                        wsc_ahcs_int_status_t    status
                    WHERE
                            line.header_id = status.header_id
                        AND line.batch_id = status.batch_id
                        AND line.line_id = status.line_id
                        AND status.batch_id = p_batch_id
                                     -- AND LINE.HEADER_ID = 173847
                        AND status.attribute2 = 'VALIDATION_SUCCESS'
                )                       d_lgl_entt
            WHERE
                lgl_entt.flex_segment_value = d_lgl_entt.gl_legal_entity
        ), header_id_data AS (
            SELECT
                COUNT(1),
                header_id
            FROM
                (
                    SELECT
                        COUNT(1),
                        header_id,
                        ledger_name
                    FROM
                        main_data
                    GROUP BY
                        header_id,
                        ledger_name
                )
            GROUP BY
                header_id
            HAVING
                COUNT(1) = 1
        )
        SELECT
            COUNT(1),
            ln.header_id,
            lgl.ledger_name
        FROM
            header_id_data           a,
            wsc_ahcs_mfar_txn_line_t ln,
            wsc_gl_legal_entities_t  lgl
        WHERE
                a.header_id = ln.header_id
            AND lgl.flex_segment_value = ln.gl_legal_entity
        GROUP BY
            ln.header_id,
            lgl.ledger_name;

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
        logging_insert('MF AR', p_batch_id, 19, 'Transformation start', NULL,
                      sysdate);
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_mapid,
            lv_tgt_system,
            lv_src_system;
        CLOSE cur_coa_map_id;
        logging_insert('MF AR', p_batch_id, 20, 'Fetch coa map id, source and target system.', lv_coa_mapid
                                                                                               || lv_tgt_system
                                                                                               || lv_src_system,
                      sysdate);

    --        update target_coa in ap_line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
    --2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF AR', p_batch_id, 21, 'Check data in cache table to find ', NULL,
                      sysdate);
        BEGIN
            IF lv_src_system = 'ANIXTER' THEN
                UPDATE wsc_ahcs_mfar_txn_line_t line
                SET
                    target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa, lv_coa_mapid),
                    last_update_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            ELSE
                UPDATE wsc_ahcs_mfar_txn_line_t line
                SET
                    target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_bu
                                                                   || '.....'
                                                                   || nvl(leg_affiliate, '00000'), lv_coa_mapid)
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
                logging_insert('MF AR', p_batch_id, 21.1, 'Error in Check data in cache table to find', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

    --        update target_coa and attribute1 'Y' in ap_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF AR', p_batch_id, 22, 'Update target_coa and attribute1', NULL,
                      sysdate);
        BEGIN
         /*   open cur_leg_seg_value(lv_src_system, lv_tgt_system);
            loop
            fetch cur_leg_seg_value bulk collect into lv_leg_seg_value limit 100;
            EXIT WHEN lv_leg_seg_value.COUNT = 0;        
            forall i in 1..lv_leg_seg_value.count
                update wsc_ahcs_mfar_txn_line_t set target_coa = lv_leg_seg_value(i).target_coa,  ATTRIBUTE1 = 'Y', 
                LAST_UPDATE_DATE = sysdate 
                where LEG_COA = lv_leg_seg_value(i).LEG_COA and batch_id = p_batch_id;
            end loop;
    */
--            IF ( l_system = 'SALE' ) THEN
   --             logging_insert('MF AR', p_batch_id, 22.1, 'inside SALE', NULL,
 --                             sysdate);
--        open cur_leg_seg_value;
            FOR lv_leg_seg_value IN cur_leg_seg_value LOOP
                lv_target_coa := replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, lv_leg_seg_value.leg_bu, lv_leg_seg_value.
                leg_loc, lv_leg_seg_value.leg_dept,
                                                                           lv_leg_seg_value.leg_acct, lv_leg_seg_value.leg_vendor, nvl(
                                                                           lv_leg_seg_value.leg_affiliate, '00000'), NULL, NULL, NULL,
                                                                           NULL), ' ', '');

                UPDATE wsc_ahcs_mfar_txn_line_t line
                SET
                    target_coa = lv_target_coa,
                    attribute1 = 'Y'
                WHERE
                        leg_coa = lv_leg_seg_value.leg_coa
                    AND batch_id = p_batch_id
                    AND target_coa IS NULL;

            END LOOP;
--
--            ELSE
--                UPDATE wsc_ahcs_mfar_txn_line_t tgt_coa
--                SET
--                    target_coa = replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, tgt_coa.leg_bu, tgt_coa.leg_loc,
--                    tgt_coa.leg_dept,
--                                                                            tgt_coa.leg_acct, tgt_coa.leg_vendor, nvl(tgt_coa.leg_affiliate,
--                                                                            '00000'), NULL, NULL, NULL, NULL), ' ', ''),
--                    attribute1 = 'Y'
--                WHERE
--                        batch_id = p_batch_id
--                    AND target_coa IS NULL
--                    AND EXISTS (
--                        SELECT /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */
--                            1
--                        FROM
--                            wsc_ahcs_int_status_t status
--                        WHERE
--                                status.batch_id = p_batch_id
--                            AND status.batch_id = tgt_coa.batch_id
--                            AND status.header_id = tgt_coa.header_id
--                            AND status.line_id = tgt_coa.line_id
--                            AND status.attribute2 = 'VALIDATION_SUCCESS'
--                    );

  --          END IF;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('MF AR', p_batch_id, 22.1, 'Error in update target_coa and attribute1', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

    --        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF AR', p_batch_id, 23, 'Insert new target_coa values', NULL,
                      sysdate);
        BEGIN
  --          IF lv_src_system = 'ANIXTER' THEN
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
                        'MF AR',
                        'MF AR',
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
 --           ELSE
--                OPEN cur_inserting_ccid_table;
--                LOOP
--                    FETCH cur_inserting_ccid_table
--                    BULK COLLECT INTO lv_inserting_ccid_table LIMIT 100;
--                    EXIT WHEN lv_inserting_ccid_table.count = 0;
--                    FORALL i IN 1..lv_inserting_ccid_table.count
--                        INSERT INTO wsc_gl_ccid_mapping_t (
--                            ccid_value_id,
--                            coa_map_id,
--                            source_segment,
--                            target_segment,
--                            creation_date,
--                            last_update_date,
--                            enable_flag,
--                            ui_flag,
--                            created_by,
--                            last_updated_by,
--                            source_segment1,
--                            source_segment2,
--                            source_segment3,
--                            source_segment4,
--                            source_segment5,
--                            source_segment6,
--                            source_segment7,
--                            source_segment8,
--                            source_segment9,
--                            source_segment10
--                        ) VALUES (
--                            wsc_gl_ccid_mapping_s.NEXTVAL,
--                            lv_coa_mapid,
--                            lv_inserting_ccid_table(i).leg_bu
--                            || '.....'
--                            || nvl(lv_inserting_ccid_table(i).leg_affiliate, '00000'),
--                            lv_inserting_ccid_table(i).target_coa,
--                            sysdate,
--                            sysdate,
--                            'Y',
--                            'N',
--                            'MF AR',
--                            'MF AR',
--                            lv_inserting_ccid_table(i).leg_bu,
--                            NULL,
--                            NULL,
--                            NULL,
--                            NULL,
--                            nvl(lv_inserting_ccid_table(i).leg_affiliate, '00000'),
--                            NULL,
--                            NULL,
--                            NULL,
--                            NULL
--                        );
--                --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
--                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
--                END LOOP;
--
--                CLOSE cur_inserting_ccid_table;
--            END IF;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('MF AR', p_batch_id, 23.1, 'Error in ccid table insert.', NULL,
                              sysdate);
        END;

        UPDATE wsc_ahcs_mfar_txn_line_t
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
        logging_insert('MF AR', p_batch_id, 24, 'Update ap_line table target segments', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_mfar_txn_line_t
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
                logging_insert('MF AR', p_batch_id, 24.1, 'Error in update ap_line table target segments', sqlerrm,
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
        logging_insert('MF AR', p_batch_id, 25, 'If any target_coa is empty', NULL,
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
                    wsc_ahcs_mfar_txn_line_t line
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
            logging_insert('MF AR', p_batch_id, 26, 'Updated attribute2 with TRANSFORM_FAILED status', NULL,
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
                  logging_insert('MF AR',p_batch_id,19.2,'updated attribute2 with TRANSFORM_FAILED status',null,sysdate);
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
                logging_insert('MF AR', p_batch_id, 26.1, 'Error in if any target_coa is empty', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

    --      update ledger_name in ap_header table where transform_success		
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF AR', p_batch_id, 27, 'update ledger_name start', NULL,
                      sysdate);
        BEGIN
    --         /*   open cur_get_ledger;
    --            loop
    --            fetch cur_get_ledger bulk collect into lv_get_ledger limit 10;
    --            EXIT WHEN lv_get_ledger.COUNT = 0;        
    --            forall i in 1..lv_get_ledger.count
    --                update wsc_ahcs_mfar_txn_header_t
    --                   set ledger_name = lv_get_ledger(i).ledger_name , LAST_UPDATE_DATE = sysdate
    --                 where batch_id = p_batch_id 
    --				   and header_id = lv_get_ledger(i).header_id
    --                   ;
    --            end loop;*/
    --
            IF ( l_system = 'SALE1' ) THEN
                FOR lv_ledger_name IN cur_ledger_name LOOP
                    UPDATE wsc_ahcs_mfar_txn_header_t hdr
                    SET
                        ledger_name = lv_ledger_name.ledger_name
                    WHERE
                            header_id = lv_ledger_name.header_id
                        AND batch_id = lv_batch_id;

                END LOOP;
            ELSE
                MERGE INTO wsc_ahcs_mfar_txn_header_t hdr
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
                                          wsc_ahcs_mfar_txn_line_t line,
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

            END IF;

            COMMIT;
            logging_insert('MF AR', p_batch_id, 28, 'Update Ledger name Ends', sqlerrm,
                          sysdate);
            logging_insert('ANIXTER AR', p_batch_id, 28.1, 'update transaction number with STATIC_LEDGER_NUMBER -starts', NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_mfar_txn_header_t hdr
            USING wsc_ahcs_int_mf_ledger_t l ON ( l.ledger_name = hdr.ledger_name
                                                  AND l.sub_ledger = 'MF AR'
                                                  AND hdr.ledger_name IS NOT NULL
                                                  AND hdr.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET transaction_number = transaction_number
                                     || '_'
                                     || l.static_ledger_number;

            COMMIT;
            logging_insert('ANIXTER AR', p_batch_id, 28.2, 'update transaction number with STATIC_LEDGER_NUMBER -header table- complete',
            NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_mfar_txn_line_t line
            USING wsc_ahcs_mfar_txn_header_t hdr ON ( line.header_id = hdr.header_id
                                                      AND line.batch_id = hdr.batch_id
                                                      AND hdr.ledger_name IS NOT NULL
                                                      AND hdr.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET line.transaction_number = hdr.transaction_number;

            COMMIT;

--add status insertion
            MERGE INTO wsc_ahcs_int_status_t stauts
            USING wsc_ahcs_mfar_txn_line_t line ON ( line.header_id = stauts.header_id
                                                     AND line.batch_id = stauts.batch_id
                                                     AND line.line_id = stauts.line_id
                                                     AND stauts.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET stauts.attribute3 = line.transaction_number;

            COMMIT;
            logging_insert('ANIXTER AR', p_batch_id, 28.3, 'update transaction number with STATIC_LEDGER_NUMBER -line and status table- complete',
            NULL,
                          sysdate);
            logging_insert('ANIXTER AR', p_batch_id, 28.4, 'update transaction number with STATIC_LEDGER_NUMBER -ends', NULL,
                          sysdate);
            logging_insert('MF AR', p_batch_id, 28.5, 'Update multi Ledger name check with respect to each header id start', sqlerrm,
                          sysdate);
            wsc_ahcs_mfar_validation_transformation_pkg.wsc_ledger_name_derivation(lv_batch_id);
            COMMIT;

          /*  logging_insert('MF AR', p_batch_id, 28, 'After IS NOT NULL', NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_mfar_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE) */
                           /*   lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t lgl_entt,
                              (
                                  SELECT /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I,batch_status wsc_ahcs_int_status_batch_id_i)  */
                                    /*  line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_mfar_txn_line_t line,
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
            SET hdr.ledger_name = e.ledger_name;

            COMMIT; */
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('MF AR', p_batch_id, 28.100, 'Error in update ledger_name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('MF AR', p_batch_id, 28.12, 'Update multi Ledger name check with respect to each header id ends', sqlerrm,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_mfar_txn_header_t h
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
        logging_insert('MF AR', p_batch_id, 29, 'Update status tables after validation', NULL,
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
                logging_insert('MF AR',p_batch_id,23,'Update status tables after validation',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end; */

        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF AR', p_batch_id, 30, 'Update status tables to have status', NULL,
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
                    wsc_ahcs_mfar_txn_header_t hdr
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

            IF l_system = 'SALE' THEN
                logging_insert('MF AR', p_batch_id, 30.1, 'MF AR - Call MF AR Line Copy Procedure Start', NULL,
                              sysdate);
                wsc_ahcs_mfar_validation_transformation_pkg.wsc_ahcs_mfar_line_copy_p(lv_batch_id);
                COMMIT;
                logging_insert('MF AR', p_batch_id, 30.9, 'MF AR - Call MF AR Line Copy Procedure Ends', NULL,
                              sysdate);
            END IF;

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

        logging_insert('MF AR', p_batch_id, 31, 'end transformation', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT216'
                                                                 || '_'
                                                                 || l_system, 'MF AR', sqlerrm);
    END leg_coa_transformation;

    PROCEDURE leg_coa_transformation_jti_mfar (
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
        l_system      VARCHAR2(30);
        lv_batch_id   NUMBER := p_batch_id;
        retcode       VARCHAR2(50);
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

        lv_count_succ NUMBER;
    BEGIN
        BEGIN
            logging_insert('JTI MF AR', p_batch_id, 6, 'Update control table status to validation success.', NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = 'VALIDATION_SUCCESS'
            WHERE
                batch_id = p_batch_id;
	-------------------------------------------------------------------------------------------------------------------------------------------
 -- Update Ledger based on the legal entity in the header table.---
            logging_insert('JTI MF AR', p_batch_id, 7, 'Update ledger name in header table start.', NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_mfar_txn_header_t hdr
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
                                      wsc_ahcs_mfar_txn_line_t line,
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
            logging_insert('JTI MF AR', p_batch_id, 8, 'Update Ledger name Ends', sqlerrm,
                          sysdate);
            logging_insert('JTI MF AR', p_batch_id, 8.1, 'Update static number in header table.', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_mfar_txn_header_t hdr
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
                        AND l.sub_ledger = 'MF AR'
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

            logging_insert('ANIXTER AR', p_batch_id, 8.2, 'update transaction number with STATIC_LEDGER_NUMBER -header table- complete',
            NULL,
                          sysdate);
--            MERGE INTO wsc_ahcs_mfar_txn_line_t line
--            USING wsc_ahcs_mfar_txn_header_t hdr ON ( line.header_id = hdr.header_id
--                                                      AND line.batch_id = hdr.batch_id
--                                                      AND hdr.ledger_name IS NOT NULL
--                                                      AND hdr.batch_id = p_batch_id )
--            WHEN MATCHED THEN UPDATE
--            SET line.transaction_number = hdr.transaction_number;

            COMMIT;
            UPDATE wsc_ahcs_mfar_txn_line_t line
            SET
                line.transaction_number = (
                    SELECT
                        hdr.transaction_number
                    FROM
                        wsc_ahcs_mfar_txn_header_t hdr
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
            logging_insert('ANIXTER AR', p_batch_id, 8.3, 'update transaction number with STATIC_LEDGER_NUMBER -line table- complete',
            NULL,
                          sysdate);
--add status insertion
            MERGE INTO wsc_ahcs_int_status_t stauts
            USING wsc_ahcs_mfar_txn_line_t line ON ( stauts.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                                                     AND line.header_id = stauts.header_id
                                                     AND line.batch_id = stauts.batch_id
                                                     AND line.line_id = stauts.line_id
                                                     AND stauts.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET stauts.attribute3 = line.transaction_number;

            COMMIT;
            logging_insert('ANIXTER AR', p_batch_id, 8.4, 'update transaction number with STATIC_LEDGER_NUMBER -line and status table- complete',
            NULL,
                          sysdate);
            logging_insert('JTI MF AR', p_batch_id, 9, 'Update multi Ledger name check with respect to each header id start', sqlerrm,
                          sysdate);
            wsc_ahcs_mfar_validation_transformation_pkg.wsc_ledger_name_derivation(lv_batch_id);
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('JTI MF AR', p_batch_id, 9.1, 'Error in update ledger name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('JTI MF AR', p_batch_id, 10, 'Update multi Ledger name check with respect to each header id ends', sqlerrm,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_mfar_txn_header_t h
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

        logging_insert('JTI MF AR', p_batch_id, 11, 'Ledger updated in status table and status update started.', NULL,
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
                    wsc_ahcs_mfar_txn_header_t hdr
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
            logging_insert('JTI MF AR', p_batch_id, 12, 'Update status table statuses completed.', NULL,
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

        logging_insert('JTI MF AR', p_batch_id, 303, 'Dashboard Start', NULL,
                      sysdate);
        wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
        logging_insert('JTI MF AR', p_batch_id, 304, 'Dashboard End', NULL,
                      sysdate);
        logging_insert('JTI MF AR', p_batch_id, 31, 'end transformation', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT241_MFAR', 'JTI MF AR', sqlerrm);
    END leg_coa_transformation_jti_mfar;

    PROCEDURE leg_coa_transformation_jti_mfar_reprocess (
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
        lv_group_id      NUMBER; --added for reprocess individual group id process 12th Dec 2022
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
        CURSOR jti_mfar_grp_data_fetch_cur ( --added for reprocess individual group id process 12th Dec 2022
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
            wsc_ahcs_mfar_txn_header_t a
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

        TYPE mfar_grp_type IS
            TABLE OF jti_mfar_grp_data_fetch_cur%rowtype;
        lv_mfar_grp_type mfar_grp_type;
    BEGIN
        BEGIN
            logging_insert('JTI MF AR', p_batch_id, 6, 'Update control table status to validation success.', NULL,
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
            logging_insert('JTI MF AR', p_batch_id, 7, 'Update ledger name in header table start.', NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_mfar_txn_header_t hdr
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
                                      wsc_ahcs_mfar_txn_line_t line,
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
            logging_insert('JTI MF AR', p_batch_id, 8, 'Update Ledger name Ends', sqlerrm,
                          sysdate);
            logging_insert('JTI MF AR', p_batch_id, 8.1, 'Update static number in header table.', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_mfar_txn_header_t hdr
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
                        AND l.sub_ledger = 'MF AR'
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

            logging_insert('ANIXTER AR', p_batch_id, 8.2, 'update transaction number with STATIC_LEDGER_NUMBER -header table- complete',
            NULL,
                          sysdate);
--            MERGE INTO wsc_ahcs_mfar_txn_line_t line
--            USING wsc_ahcs_mfar_txn_header_t hdr ON ( line.header_id = hdr.header_id
--                                                      AND line.batch_id = hdr.batch_id
--                                                      AND hdr.ledger_name IS NOT NULL
--                                                      AND hdr.batch_id = p_batch_id )
--            WHEN MATCHED THEN UPDATE
--            SET line.transaction_number = hdr.transaction_number;

            COMMIT;
            UPDATE wsc_ahcs_mfar_txn_line_t line
            SET
                line.transaction_number = (
                    SELECT
                        hdr.transaction_number
                    FROM
                        wsc_ahcs_mfar_txn_header_t hdr
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
            logging_insert('ANIXTER AR', p_batch_id, 8.3, 'update transaction number with STATIC_LEDGER_NUMBER -line table- complete',
            NULL,
                          sysdate);
--add status insertion
            MERGE INTO wsc_ahcs_int_status_t stauts
            USING wsc_ahcs_mfar_txn_line_t line ON ( stauts.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                                                     AND line.header_id = stauts.header_id
                                                     AND line.batch_id = stauts.batch_id
                                                     AND line.line_id = stauts.line_id
                                                     AND stauts.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET stauts.attribute3 = line.transaction_number;

            COMMIT;
            logging_insert('ANIXTER AR', p_batch_id, 8.4, 'update transaction number with STATIC_LEDGER_NUMBER -line and status table- complete',
            NULL,
                          sysdate);
            logging_insert('JTI MF AR', p_batch_id, 9, 'Update multi Ledger name check with respect to each header id start', sqlerrm,
                          sysdate);
            wsc_ahcs_mfar_validation_transformation_pkg.wsc_ledger_name_derivation(lv_batch_id);
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('JTI MF AR', p_batch_id, 9.1, 'Error in update ledger name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('JTI MF AR', p_batch_id, 10, 'Update multi Ledger name check with respect to each header id ends', sqlerrm,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_mfar_txn_header_t h
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

        logging_insert('JTI MF AR', p_batch_id, 11, 'Ledger updated in status table and status update started.', NULL,
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
                    wsc_ahcs_mfar_txn_header_t hdr
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
            logging_insert('JTI MF AR', p_batch_id, 12, 'Update status table statuses completed.', NULL,
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

        BEGIN --added for reprocess individual group id process 12th Dec 2022
            lv_group_id := wsc_ahcs_mf_grp_id_seq.nextval;
            UPDATE wsc_ahcs_int_control_t
            SET
                group_id = lv_group_id
            WHERE
                    source_application = 'MF AR'
                AND status = 'TRANSFORM_SUCCESS'
                AND group_id IS NULL
                AND batch_id = p_batch_id;

            logging_insert('JTI MF AR', p_batch_id, 290, 'Group Id update in control table ends.' || sqlerrm, NULL,
                          sysdate);
            COMMIT;
            OPEN jti_mfar_grp_data_fetch_cur(lv_group_id);
            LOOP
                FETCH jti_mfar_grp_data_fetch_cur
                BULK COLLECT INTO lv_mfar_grp_type LIMIT 50;
                EXIT WHEN lv_mfar_grp_type.count = 0;
                FORALL i IN 1..lv_mfar_grp_type.count
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
                        lv_mfar_grp_type(i).batch_id,
                        lv_mfar_grp_type(i).file_name,
                        lv_group_id,
                        lv_mfar_grp_type(i).ledger_name,
                        lv_mfar_grp_type(i).source_application,
                        lv_mfar_grp_type(i).interface_id,
                        lv_mfar_grp_type(i).status,
                        'FIN_INT',
                        sysdate,
                        'FIN_INT',
                        sysdate
                    );

            END LOOP;

            COMMIT;
            logging_insert('JTI MF AR', p_batch_id, 291, 'Control Line insertion for group id ends.' || sqlerrm, NULL,
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
            logging_insert('JTI MF AR', p_batch_id, 292, 'Group id update in status table ends.' || sqlerrm, NULL,
                          sysdate);
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('JTI MF AR', p_batch_id, 290.1, 'Error in the reprocess group id block.' || sqlerrm, NULL,
                              sysdate);
        END;

        logging_insert('JTI MF AR', p_batch_id, 303, 'Dashboard Start', NULL,
                      sysdate);
        wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
        logging_insert('JTI MF AR', p_batch_id, 304, 'Dashboard End', NULL,
                      sysdate);
        logging_insert('JTI MF AR', p_batch_id, 350, 'end transformation', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT241_MFAR', 'JTI MF AR', sqlerrm);
    END leg_coa_transformation_jti_mfar_reprocess;

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
        l_system                  VARCHAR2(30);
        lv_batch_id               NUMBER := p_batch_id;
        lv_group_id               NUMBER; --added for reprocess individual group id process 24th Nov 2022
        lv_job_count              NUMBER := NULL;
        lv_file_name              VARCHAR2(50);
        CURSOR cur_update_trxn_line_err IS
        SELECT
            line.batch_id,
            line.header_id,
            line.line_id,
            line.target_coa
        FROM
            wsc_ahcs_mfar_txn_line_t line,
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
    --                    wsc_ahcs_mfar_txn_line_t    line,
    --                    wsc_ahcs_int_status_t     status
    ----                    wsc_ahcs_mfar_txn_header_t  header
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
            line.leg_bu,
            line.leg_acct,
            line.leg_dept,
            line.leg_loc,
            line.leg_vendor,
            line.leg_affiliate
    --            line.leg_seg7,
    --            substr(line.leg_coa, instr(line.leg_coa, '.', 1, 7) + 1)                      AS ledger_name
        FROM
            wsc_ahcs_mfar_txn_line_t line
    --              , wsc_ahcs_mfar_txn_header_t header
        WHERE
                line.batch_id = p_batch_id 
    --			   and line.batch_id = header.batch_id
    --			   and line.header_id = header.header_id
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        /*
        cursor cur_inserting_ccid_table is
            select distinct LEG_COA, TARGET_COA from wsc_ahcs_mfar_txn_line_t
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
                        wsc_ahcs_mfar_txn_line_t line,
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

    --        CURSOR cur_line_validation_after_valid (
    --            cur_p_batch_id NUMBER
    --        ) IS
    --        WITH line_cr AS (
    --            SELECT
    --                header_id,
    --                gl_legal_entity,
    --                SUM(acc_amt) * - 1 sum_data
    --            FROM
    --                wsc_ahcs_mfar_txn_line_t
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
    --                wsc_ahcs_mfar_txn_line_t
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

        CURSOR mfar_grp_data_fetch_cur ( --added for reprocess individual group id process 24th Nov 2022
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
            wsc_ahcs_mfar_txn_header_t a
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

        TYPE mfar_grp_type IS
            TABLE OF mfar_grp_data_fetch_cur%rowtype;
        lv_mfar_grp_type          mfar_grp_type;

    --        TYPE line_validation_after_valid_type IS
    --            TABLE OF cur_line_validation_after_valid%rowtype;
    --        lv_line_validation_after_valid  line_validation_after_valid_type;
        lv_coa_mapid              NUMBER;
        lv_src_system             VARCHAR2(100);
        lv_tgt_system             VARCHAR2(100);
        lv_count_succ             NUMBER;
        retcode                   VARCHAR2(50);
        err_msg                   VARCHAR2(50);
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
        logging_insert('MF AR', p_batch_id, 19, 'Transformation start', NULL,
                      sysdate);
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_mapid,
            lv_tgt_system,
            lv_src_system;
        CLOSE cur_coa_map_id;
        logging_insert('MF AR', p_batch_id, 20, 'Fetch coa map id, source and target system.', lv_coa_mapid
                                                                                               || lv_tgt_system
                                                                                               || lv_src_system,
                      sysdate);

    --        update target_coa in ap_line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
    --2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------

        BEGIN
            UPDATE wsc_ahcs_mfar_txn_line_t line
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

            UPDATE wsc_ahcs_mfar_txn_header_t hdr
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

        logging_insert('MF AR', p_batch_id, 21, 'Check data in cache table to find ', NULL,
                      sysdate);
        BEGIN
            IF lv_src_system = 'ANIXTER' THEN
                UPDATE wsc_ahcs_mfar_txn_line_t line
                SET
                    target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa, lv_coa_mapid),
                    last_update_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            ELSE
                UPDATE wsc_ahcs_mfar_txn_line_t line
                SET
                    target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_bu
                                                                   || '.....'
                                                                   || nvl(leg_affiliate, '00000'), lv_coa_mapid)
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
                logging_insert('MF AR', p_batch_id, 21.1, 'Error in Check data in cache table to find', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

    --        update target_coa and attribute1 'Y' in ap_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF AR', p_batch_id, 22, 'Update target_coa and attribute1', NULL,
                      sysdate);
        BEGIN
         /*   open cur_leg_seg_value(lv_src_system, lv_tgt_system);
            loop
            fetch cur_leg_seg_value bulk collect into lv_leg_seg_value limit 100;
            EXIT WHEN lv_leg_seg_value.COUNT = 0;        
            forall i in 1..lv_leg_seg_value.count
                update wsc_ahcs_mfar_txn_line_t set target_coa = lv_leg_seg_value(i).target_coa,  ATTRIBUTE1 = 'Y', 
                LAST_UPDATE_DATE = sysdate 
                where LEG_COA = lv_leg_seg_value(i).LEG_COA and batch_id = p_batch_id;
            end loop;
    */

            UPDATE wsc_ahcs_mfar_txn_line_t tgt_coa
            SET
                target_coa = replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, tgt_coa.leg_bu, tgt_coa.leg_loc,
                tgt_coa.leg_dept,
                                                                        tgt_coa.leg_acct, tgt_coa.leg_vendor, nvl(tgt_coa.leg_affiliate,
                                                                        '00000'), NULL, NULL, NULL, NULL), ' ', ''),
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
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('MF AR', p_batch_id, 22.1, 'Error in update target_coa and attribute1', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

    --        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF AR', p_batch_id, 23, 'Insert new target_coa values', NULL,
                      sysdate);
        BEGIN
  --          IF lv_src_system = 'ANIXTER' THEN
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
                        'MF AR',
                        'MF AR',
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
 --           ELSE
--                OPEN cur_inserting_ccid_table;
--                LOOP
--                    FETCH cur_inserting_ccid_table
--                    BULK COLLECT INTO lv_inserting_ccid_table LIMIT 100;
--                    EXIT WHEN lv_inserting_ccid_table.count = 0;
--                    FORALL i IN 1..lv_inserting_ccid_table.count
--                        INSERT INTO wsc_gl_ccid_mapping_t (
--                            ccid_value_id,
--                            coa_map_id,
--                            source_segment,
--                            target_segment,
--                            creation_date,
--                            last_update_date,
--                            enable_flag,
--                            ui_flag,
--                            created_by,
--                            last_updated_by,
--                            source_segment1,
--                            source_segment2,
--                            source_segment3,
--                            source_segment4,
--                            source_segment5,
--                            source_segment6,
--                            source_segment7,
--                            source_segment8,
--                            source_segment9,
--                            source_segment10
--                        ) VALUES (
--                            wsc_gl_ccid_mapping_s.NEXTVAL,
--                            lv_coa_mapid,
--                            lv_inserting_ccid_table(i).leg_bu
--                            || '.....'
--                            || nvl(lv_inserting_ccid_table(i).leg_affiliate, '00000'),
--                            lv_inserting_ccid_table(i).target_coa,
--                            sysdate,
--                            sysdate,
--                            'Y',
--                            'N',
--                            'MF AR',
--                            'MF AR',
--                            lv_inserting_ccid_table(i).leg_bu,
--                            NULL,
--                            NULL,
--                            NULL,
--                            NULL,
--                            nvl(lv_inserting_ccid_table(i).leg_affiliate, '00000'),
--                            NULL,
--                            NULL,
--                            NULL,
--                            NULL
--                        );
--                --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
--                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
--                END LOOP;
--
--                CLOSE cur_inserting_ccid_table;
--            END IF;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('MF AR', p_batch_id, 23.1, 'Error in ccid table insert.', NULL,
                              sysdate);
        END;

        UPDATE wsc_ahcs_mfar_txn_line_t
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
        logging_insert('MF AR', p_batch_id, 24, 'Update ap_line table target segments', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_mfar_txn_line_t
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
                logging_insert('MF AR', p_batch_id, 24.1, 'Error in update ap_line table target segments', sqlerrm,
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
        logging_insert('MF AR', p_batch_id, 25, 'If any target_coa is empty', NULL,
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
                    wsc_ahcs_mfar_txn_line_t line
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
            logging_insert('MF AR', p_batch_id, 26, 'Updated attribute2 with TRANSFORM_FAILED status', NULL,
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
                  logging_insert('MF AR',p_batch_id,19.2,'updated attribute2 with TRANSFORM_FAILED status',null,sysdate);
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
                logging_insert('MF AR', p_batch_id, 26.1, 'Error in if any target_coa is empty', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

    --      update ledger_name in ap_header table where transform_success		
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF AR', p_batch_id, 27, 'update ledger_name', NULL,
                      sysdate);
        BEGIN
    --         /*   open cur_get_ledger;
    --            loop
    --            fetch cur_get_ledger bulk collect into lv_get_ledger limit 10;
    --            EXIT WHEN lv_get_ledger.COUNT = 0;        
    --            forall i in 1..lv_get_ledger.count
    --                update wsc_ahcs_mfar_txn_header_t
    --                   set ledger_name = lv_get_ledger(i).ledger_name , LAST_UPDATE_DATE = sysdate
    --                 where batch_id = p_batch_id 
    --				   and header_id = lv_get_ledger(i).header_id
    --                   ;
    --            end loop;*/
    --
            MERGE INTO wsc_ahcs_mfar_txn_header_t hdr
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
                                      wsc_ahcs_mfar_txn_line_t line,
                                      wsc_ahcs_int_status_t    status
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
            logging_insert('MF AR', p_batch_id, 28, 'update ledger name ends.', NULL,
                          sysdate);
            logging_insert('MF AR', p_batch_id, 28, 'Update multi ledger_name for header id start.', NULL,
                          sysdate);
            logging_insert('ANIXTER AR', p_batch_id, 28.1, 'update transaction number with STATIC_LEDGER_NUMBER -starts', NULL,
                          sysdate);
--            MERGE INTO wsc_ahcs_mfar_txn_header_t hdr
--            USING wsc_ahcs_int_mf_ledger_t l ON ( l.ledger_name = hdr.ledger_name
--                                                  AND l.sub_ledger = 'MF AR'
--                                                  AND hdr.ledger_name IS NOT NULL
--                                                  AND hdr.batch_id = p_batch_id )
--            WHEN MATCHED THEN UPDATE
--            SET transaction_number = transaction_number
--                                     || '_'
--                                     || l.static_ledger_number;
--
--            COMMIT;
            UPDATE wsc_ahcs_mfar_txn_header_t hdr
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
                        AND l.sub_ledger = 'MF AR'
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

            logging_insert('ANIXTER AR', p_batch_id, 28.2, 'update transaction number with STATIC_LEDGER_NUMBER -header table- complete',
            NULL,
                          sysdate);
--            MERGE INTO wsc_ahcs_mfar_txn_line_t line
--            USING wsc_ahcs_mfar_txn_header_t hdr ON ( line.header_id = hdr.header_id
--                                                      AND line.batch_id = hdr.batch_id
--                                                      AND hdr.ledger_name IS NOT NULL
--                                                      AND hdr.batch_id = p_batch_id )
--            WHEN MATCHED THEN UPDATE
--            SET line.transaction_number = hdr.transaction_number;

            COMMIT;
            UPDATE wsc_ahcs_mfar_txn_line_t line
            SET
                line.transaction_number = (
                    SELECT
                        hdr.transaction_number
                    FROM
                        wsc_ahcs_mfar_txn_header_t hdr
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
            logging_insert('ANIXTER AR', p_batch_id, 28.3, 'update transaction number with STATIC_LEDGER_NUMBER -line table- complete',
            NULL,
                          sysdate);
--add status insertion
            MERGE INTO wsc_ahcs_int_status_t stauts
            USING wsc_ahcs_mfar_txn_line_t line ON ( stauts.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                                                     AND line.header_id = stauts.header_id
                                                     AND line.batch_id = stauts.batch_id
                                                     AND line.line_id = stauts.line_id
                                                     AND stauts.batch_id = p_batch_id )
            WHEN MATCHED THEN UPDATE
            SET stauts.attribute3 = line.transaction_number;

            COMMIT;
            logging_insert('ANIXTER AR', p_batch_id, 28.4, 'update transaction number with STATIC_LEDGER_NUMBER in status table -ends',
            NULL,
                          sysdate);
            wsc_ahcs_mfar_validation_transformation_pkg.wsc_ledger_name_derivation(lv_batch_id);
            COMMIT;

          /*  logging_insert('MF AR', p_batch_id, 28, 'After IS NOT NULL', NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_mfar_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE) */
                           /*   lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t lgl_entt,
                              (
                                  SELECT /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I,batch_status wsc_ahcs_int_status_batch_id_i)  */
                                    /*  line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_mfar_txn_line_t line,
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
            SET hdr.ledger_name = e.ledger_name;

            COMMIT; */
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('MF AR', p_batch_id, 28.1, 'Error in update ledger_name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        logging_insert('MF AR', p_batch_id, 28.8, 'update multi ledger name for a header id ends.', NULL,
                      sysdate);
        BEGIN
            MERGE INTO wsc_ahcs_int_status_t sts
            USING (
                      SELECT
                          *
                      FROM
                          wsc_ahcs_mfar_txn_header_t h
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
        logging_insert('MF AR', p_batch_id, 29, 'Update status tables after validation', NULL,
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
                logging_insert('MF AR',p_batch_id,23,'Update status tables after validation',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end; */

        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('MF AR', p_batch_id, 30, 'Update status tables to have status', NULL,
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
                    wsc_ahcs_mfar_txn_header_t hdr
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
                AND attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
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
            SELECT
                COUNT(1)
            INTO lv_job_count
            FROM
                sys.dba_scheduler_running_jobs
            WHERE
                job_name LIKE 'MFAR_REPROCESSING_'
                              || lv_file_name
                              || '%';

            IF
                l_system = 'SALE'
                AND lv_job_count >= 1
            THEN
                logging_insert('MF AR', p_batch_id, 30.1, 'MF AR - Call MF AR Line Copy Procedure Start', NULL,
                              sysdate);
                wsc_ahcs_mfar_validation_transformation_pkg.wsc_ahcs_mfar_line_copy_p(lv_batch_id);
                COMMIT;
                logging_insert('MF AR', p_batch_id, 30.9, 'MF AR - Call MF AR Line Copy Procedure Ends', NULL,
                              sysdate);
            END IF;

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
                    source_application = 'MF AR'
                AND status = 'TRANSFORM_SUCCESS'
                AND group_id IS NULL
                AND batch_id = p_batch_id;

            logging_insert('MF AR', p_batch_id, 290, 'Group Id update in control table ends.' || sqlerrm, NULL,
                          sysdate);
            COMMIT;
            OPEN mfar_grp_data_fetch_cur(lv_group_id);
            LOOP
                FETCH mfar_grp_data_fetch_cur
                BULK COLLECT INTO lv_mfar_grp_type LIMIT 50;
                EXIT WHEN lv_mfar_grp_type.count = 0;
                FORALL i IN 1..lv_mfar_grp_type.count
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
                        lv_mfar_grp_type(i).batch_id,
                        lv_mfar_grp_type(i).file_name,
                        lv_group_id,
                        lv_mfar_grp_type(i).ledger_name,
                        lv_mfar_grp_type(i).source_application,
                        lv_mfar_grp_type(i).interface_id,
                        lv_mfar_grp_type(i).status,
                        'FIN_INT',
                        sysdate,
                        'FIN_INT',
                        sysdate
                    );

            END LOOP;

            COMMIT;
            logging_insert('MF AR', p_batch_id, 291, 'Control Line insertion for group id ends.' || sqlerrm, NULL,
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
            logging_insert('MF AR', p_batch_id, 292, 'Group id update in status table ends.' || sqlerrm, NULL,
                          sysdate);
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('MF AR', p_batch_id, 290.1, 'Error in the reprocess group id block.' || sqlerrm, NULL,
                              sysdate);
        END;

        logging_insert('MF AR', p_batch_id, 303, 'Dashboard Start', NULL,
                      sysdate);
        wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
        logging_insert('MF AR', p_batch_id, 304, 'Dashboard End', NULL,
                      sysdate);
        logging_insert('MF AR', p_batch_id, 31, 'end transformation', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT216'
                                                                 || '_'
                                                                 || l_system, 'MF AR', sqlerrm);
    END leg_coa_transformation_reprocessing;

    PROCEDURE wsc_ahcs_mfar_grp_id_upd_p (
        in_grp_id IN NUMBER
    ) AS

        lv_grp_id        NUMBER := in_grp_id;
        err_msg          VARCHAR2(4000);
        CURSOR mfar_grp_data_fetch_cur (
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
            wsc_ahcs_mfar_txn_header_t a
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

        TYPE mfar_grp_type IS
            TABLE OF mfar_grp_data_fetch_cur%rowtype;
        lv_mfar_grp_type mfar_grp_type;
    BEGIN
-- Updating Group Id for MF AP Files in control table----

        UPDATE wsc_ahcs_int_control_t
        SET
            group_id = lv_grp_id
        WHERE
                source_application = 'MF AR'
            AND status = 'TRANSFORM_SUCCESS'
            AND group_id IS NULL;

        COMMIT;
        OPEN mfar_grp_data_fetch_cur(lv_grp_id);
        LOOP
            FETCH mfar_grp_data_fetch_cur
            BULK COLLECT INTO lv_mfar_grp_type LIMIT 50;
            EXIT WHEN lv_mfar_grp_type.count = 0;
            FORALL i IN 1..lv_mfar_grp_type.count
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
                    lv_mfar_grp_type(i).batch_id,
                    lv_mfar_grp_type(i).file_name,
                    lv_grp_id,
                    lv_mfar_grp_type(i).ledger_name,
                    lv_mfar_grp_type(i).source_application,
                    lv_mfar_grp_type(i).interface_id,
                    lv_mfar_grp_type(i).status,
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
    END wsc_ahcs_mfar_grp_id_upd_p;

    PROCEDURE wsc_ahcs_mfar_ctrl_line_tbl_led_num_upd (
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
                        AND ml.sub_ledger = 'MF AR'
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
                        AND ml.sub_ledger = 'MF AR'
                        AND ml.ledger_name = status.ledger_name
                ) );

            COMMIT;
        END IF;
    END wsc_ahcs_mfar_ctrl_line_tbl_led_num_upd;

    PROCEDURE wsc_ahcs_mfar_ctrl_line_ucm_id_upd (
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
                        AND ml.sub_ledger = 'MF AR'
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
                        AND ml.sub_ledger = 'MF AR'
                        AND ml.ledger_name = status.ledger_name
                ) );

            COMMIT;
        END IF;
    END wsc_ahcs_mfar_ctrl_line_ucm_id_upd;

END wsc_ahcs_mfar_validation_transformation_pkg;
/