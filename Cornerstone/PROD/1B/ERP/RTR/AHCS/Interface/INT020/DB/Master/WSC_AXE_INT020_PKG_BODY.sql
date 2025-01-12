create or replace PACKAGE BODY wsc_lhin_pkg AS

    PROCEDURE wsc_lhin_insert_data_temp_p (
        p_wsc_lhin_stg IN wsc_lhin_tmp_t_type_table
    ) AS
    BEGIN
--Inserting the data from OIC to LEASES temporary table-----
        FORALL i IN 1..p_wsc_lhin_stg.count
            INSERT INTO wsc_ahcs_lhin_txn_tmp_t (
                batch_id,
                rice_id,
                capital_lease_id,
                apply_date,
                file_id,
                name,
                category,
                type,
                amount,
                org_fiscal_year,
                org_fiscal_period,
                fiscal_year,
                fiscal_period,
                account,
                account_description,
                record_id,
                business_unit,
                location,
                country,
                amount_tag,
                vendor_number,
                non_ps_vendor_number,
                currency,
                asset_type,
                sub_type,
                lease_classification,
                src_batch_id,
                department,
                line_nbr,
                created_by,
                creation_date
            ) VALUES (
                p_wsc_lhin_stg(i).batch_id,
                p_wsc_lhin_stg(i).rice_id,
                p_wsc_lhin_stg(i).capital_lease_id,
                to_date(p_wsc_lhin_stg(i).apply_date, 'mm/dd/yyyy'),
                p_wsc_lhin_stg(i).file_id,
                p_wsc_lhin_stg(i).name,
                p_wsc_lhin_stg(i).category,
                p_wsc_lhin_stg(i).type,
                p_wsc_lhin_stg(i).amount,
                p_wsc_lhin_stg(i).org_fiscal_year,
                p_wsc_lhin_stg(i).org_fiscal_period,
                p_wsc_lhin_stg(i).fiscal_year,
                p_wsc_lhin_stg(i).fiscal_period,
                p_wsc_lhin_stg(i).account,
                p_wsc_lhin_stg(i).account_description,
                p_wsc_lhin_stg(i).record_id,
                p_wsc_lhin_stg(i).business_unit,
                p_wsc_lhin_stg(i).location,
                p_wsc_lhin_stg(i).country,
                p_wsc_lhin_stg(i).amount_tag,
                p_wsc_lhin_stg(i).vendor_number,
                p_wsc_lhin_stg(i).non_ps_vendor_number,
                p_wsc_lhin_stg(i).currency,
                p_wsc_lhin_stg(i).asset_type,
                p_wsc_lhin_stg(i).sub_type,
                p_wsc_lhin_stg(i).lease_classification,
                p_wsc_lhin_stg(i).src_batch_id,
                p_wsc_lhin_stg(i).department,
                wsc_lhin_tmp_line_nbr_s1.NEXTVAL,
                'FIN_INT',
                sysdate
            );

    END wsc_lhin_insert_data_temp_p;

    PROCEDURE wsc_process_lhin_temp_to_header_line_p (
        p_batch_id         IN NUMBER,
        p_application_name IN VARCHAR2,
        p_file_name        IN VARCHAR2,
        p_error_flag       OUT VARCHAR2
    ) IS

        err_msg               VARCHAR2(4000);
        v_stage               VARCHAR2(200);
        l_file_name           VARCHAR2(200) := p_file_name;
        l_date                DATE;
        CURSOR lhin_stg_hdr_data_cur (
            p_batch_id NUMBER
        ) IS
        SELECT
            *
        FROM
            (
                SELECT
                    ROW_NUMBER()
                    OVER(PARTITION BY file_id
                         ORDER BY
                             file_id DESC
                    ) row1,
                    file_id,
                    category,
                    fiscal_year,
                    fiscal_period,
                    currency,
                    asset_type,
                    sub_type,
                    lease_classification,
                    src_batch_id
                FROM
                    wsc_ahcs_lhin_txn_tmp_t
                WHERE
                    batch_id = p_batch_id
            )
        WHERE
            row1 = 1;

        CURSOR lhin_stg_line_data_cur (
            p_batch_id NUMBER
        ) IS
        SELECT
            tmp.*,
            ROW_NUMBER()
            OVER(
                ORDER BY
                    line_nbr
            ) AS row_line_num
        FROM
            wsc_ahcs_lhin_txn_tmp_t tmp
        WHERE
            batch_id = p_batch_id;

        TYPE lhin_stg_hdr_type IS
            TABLE OF lhin_stg_hdr_data_cur%rowtype;
        lv_lhin_stg_hdr_type  lhin_stg_hdr_type;
        TYPE lhin_stg_line_type IS
            TABLE OF lhin_stg_line_data_cur%rowtype;
        lv_lhin_stg_line_type lhin_stg_line_type;
    BEGIN
        p_error_flag := '0';
        l_date:=to_date(substr(l_file_name,-8),'yyyymmdd');
-- INSERT DATA FROM STAGE TO LEASES HEADER TABLE---
        logging_insert('LEASES', p_batch_id, 3, 'Data split insertion from leases stage to Leases hdr begins', NULL,
                      sysdate);
        OPEN lhin_stg_hdr_data_cur(p_batch_id);
        LOOP
            FETCH lhin_stg_hdr_data_cur
            BULK COLLECT INTO lv_lhin_stg_hdr_type LIMIT 400;
            EXIT WHEN lv_lhin_stg_hdr_type.count = 0;
            FORALL i IN 1..lv_lhin_stg_hdr_type.count
                INSERT INTO wsc_ahcs_lhin_txn_header_t (
                    header_id,
                    batch_id,
                    transaction_date,
                    transaction_number,
                    file_name,
                    file_id,
                    category,
                    fiscal_year,
                    fiscal_period,
                    currency,
                    asset_type,
                    sub_type,
                    lease_classification,
                    src_batch_id,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date
                ) VALUES (
                    wsc_lhin_header_s1.NEXTVAL,
                    p_batch_id,
                    l_date,
                    'LH'
                    || '-'
                    || lv_lhin_stg_hdr_type(i).src_batch_id
                    || '-'
                    || translate(lv_lhin_stg_hdr_type(i).file_id, 'âäàáãåÂÄÀÁÃÅªæÆçÇéêëèÉÊËÈíîïìÍÎÏÌýñÑôöòóõÔÖÒÓÕºØø°þßûüùúÛÜÙÚÿ|´&-()."*/_;[]',
                    'AAAAAAAAAAAAAAACCEEEEEEEEIIIIIIIIINNOOOOOOOOOOOOOOSSUUUUUUUUY/             '),
                    l_file_name,
                    translate(lv_lhin_stg_hdr_type(i).file_id, 'âäàáãåÂÄÀÁÃÅªæÆçÇéêëèÉÊËÈíîïìÍÎÏÌýñÑôöòóõÔÖÒÓÕºØø°þßûüùúÛÜÙÚÿ|´&-()."*/_;[]',
                    'AAAAAAAAAAAAAAACCEEEEEEEEIIIIIIIIINNOOOOOOOOOOOOOOSSUUUUUUUUY/             '),
                    lv_lhin_stg_hdr_type(i).category,
                    lv_lhin_stg_hdr_type(i).fiscal_year,
                    lv_lhin_stg_hdr_type(i).fiscal_period,
                    lv_lhin_stg_hdr_type(i).currency,
                    lv_lhin_stg_hdr_type(i).asset_type,
                    lv_lhin_stg_hdr_type(i).sub_type,
                    lv_lhin_stg_hdr_type(i).lease_classification,
                    lv_lhin_stg_hdr_type(i).src_batch_id,
                    'FIN_INT',
                    sysdate,
                    'FIN_INT',
                    sysdate
                );

        END LOOP;

        COMMIT;
        logging_insert('LEASES', p_batch_id, 4, 'Data split insertion from leases stage to leases hdr ends and line begins', NULL,
                      sysdate);
---- INSERT DATA FROM STG TO LEASES LINE TABLE
        OPEN lhin_stg_line_data_cur(p_batch_id);
        LOOP
            FETCH lhin_stg_line_data_cur
            BULK COLLECT INTO lv_lhin_stg_line_type LIMIT 400;
            EXIT WHEN lv_lhin_stg_line_type.count = 0;
            FORALL i IN 1..lv_lhin_stg_line_type.count
                INSERT INTO wsc_ahcs_lhin_txn_line_t (
                    line_id,
                    batch_id,
                    transaction_number,
                    amount,
                    currency,
                    leg_bu,
                    leg_le,
                    leg_loc,
                    leg_branch,
                    leg_acct,
                    leg_dept,
                    account_description,
                    leg_vendor,
                    non_ps_vendor_number,
                    capital_lease_id,
                    name,
                    record_id,
                    country,
                    amount_tag,
                    type,
                    apply_date,
                    org_fiscal_year,
                    org_fiscal_period,
                    file_id,
                    db_cr_flag,
                    leg_coa,
                    leg_seg_1_4,
                    leg_seg_5_7,
                    line_nbr,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date
                ) VALUES (
                    wsc_lhin_line_s1.NEXTVAL,
                    p_batch_id,
                    'LH'
                    || '-'
                    || lv_lhin_stg_line_type(i).src_batch_id
                    || '-'
                    || translate(lv_lhin_stg_line_type(i).file_id, 'âäàáãåÂÄÀÁÃÅªæÆçÇéêëèÉÊËÈíîïìÍÎÏÌýñÑôöòóõÔÖÒÓÕºØø°þßûüùúÛÜÙÚÿ|´&-()."*/_;[]',
                    'AAAAAAAAAAAAAAACCEEEEEEEEIIIIIIIIINNOOOOOOOOOOOOOOSSUUUUUUUUY/             '),
                    lv_lhin_stg_line_type(i).amount,
                    lv_lhin_stg_line_type(i).currency,
                        CASE
                            WHEN l_file_name LIKE '%NA_%' or l_file_name LIKE '%RA_%' THEN
                                lv_lhin_stg_line_type(i).business_unit
                            WHEN l_file_name LIKE '%NW_%' or l_file_name LIKE '%RW_%' THEN
                                NULL
                        END,
                        CASE
                            WHEN l_file_name LIKE '%NA_%' or l_file_name LIKE '%RA_%' THEN
                                NULL
                            WHEN l_file_name LIKE '%NW_%' or l_file_name LIKE '%RW_%' THEN
                                lv_lhin_stg_line_type(i).business_unit
                        END,
                        CASE
                            WHEN l_file_name LIKE '%NA_%' or l_file_name LIKE '%RA_%' THEN
                                lv_lhin_stg_line_type(i).location
                            WHEN l_file_name LIKE '%NW_%' or l_file_name LIKE '%RW_%' THEN
                                NULL
                        END,
                        CASE
                            WHEN l_file_name LIKE '%NA_%' or l_file_name LIKE '%RA_%' THEN
                                NULL
                            WHEN l_file_name LIKE '%NW_%' or l_file_name LIKE '%RW_%' THEN
                                lv_lhin_stg_line_type(i).location
                        END,
                    lv_lhin_stg_line_type(i).account,
                    lv_lhin_stg_line_type(i).department,
                    lv_lhin_stg_line_type(i).account_description,
                    lv_lhin_stg_line_type(i).vendor_number,
                    lv_lhin_stg_line_type(i).non_ps_vendor_number,
                    lv_lhin_stg_line_type(i).capital_lease_id,
                    lv_lhin_stg_line_type(i).name,
                    lv_lhin_stg_line_type(i).record_id,
                    lv_lhin_stg_line_type(i).country,
                    lv_lhin_stg_line_type(i).amount_tag,
                    lv_lhin_stg_line_type(i).type,
                    lv_lhin_stg_line_type(i).apply_date,
                    lv_lhin_stg_line_type(i).org_fiscal_year,
                    lv_lhin_stg_line_type(i).org_fiscal_period,
                    translate(lv_lhin_stg_line_type(i).file_id, 'âäàáãåÂÄÀÁÃÅªæÆçÇéêëèÉÊËÈíîïìÍÎÏÌýñÑôöòóõÔÖÒÓÕºØø°þßûüùúÛÜÙÚÿ|´&-()."*/_;[]',
                    'AAAAAAAAAAAAAAACCEEEEEEEEIIIIIIIIINNOOOOOOOOOOOOOOSSUUUUUUUUY/             '),
                        CASE
                            WHEN lv_lhin_stg_line_type(i).amount < 0  THEN
                                'CR'
                            WHEN lv_lhin_stg_line_type(i).amount >= 0 THEN
                                'DR'
                        END,
                    lv_lhin_stg_line_type(i).business_unit
                    || '.'
                    || lv_lhin_stg_line_type(i).location
                    || '.'
                    || lv_lhin_stg_line_type(i).department
                    || '.'
                    || lv_lhin_stg_line_type(i).account
                    || '.'
                    || lv_lhin_stg_line_type(i).vendor_number
                    || '.'
                    || '00000',
                    lv_lhin_stg_line_type(i).business_unit
                    || '.'
                    || lv_lhin_stg_line_type(i).location
                    || '.'
                    || lv_lhin_stg_line_type(i).account
                    || '.'
                    || lv_lhin_stg_line_type(i).department,
                    lv_lhin_stg_line_type(i).vendor_number
                    || '.',
                    lv_lhin_stg_line_type(i).row_line_num,
                    'FIN_INT',
                    sysdate,
                    'FIN_INT',
                    sysdate
                );

        END LOOP;

        COMMIT;
        logging_insert('LEASES', p_batch_id, 5, 'Data split insertion from Leases stage to Leases line ends', NULL,
                      sysdate);
        logging_insert('LEASES', p_batch_id, 6, 'status table insert and header to line field insertion begins', NULL,
                      sysdate); 
----updating the header_id from header table to line table----
        logging_insert('LEASES', p_batch_id, 7, 'Update Leases line table fields from header table begins', NULL,
                      sysdate);
        UPDATE wsc_ahcs_lhin_txn_line_t line
        SET
            ( header_id,
              conv_date ) = (
                SELECT
                    hdr.header_id,
                    last_day(add_months(hdr.transaction_date, - 1))
                FROM
                    wsc_ahcs_lhin_txn_header_t hdr
                WHERE
                        line.file_id = hdr.file_id
                    AND line.batch_id = hdr.batch_id
            )
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        logging_insert('LEASES', p_batch_id, 8, 'Update leases line table fields from header table ends', NULL,
                      sysdate);
        logging_insert('LEASES', p_batch_id, 9, 'Inserting records in status table begins', NULL,
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
            legacy_line_number,
            attribute3,
            attribute11,
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
                line.currency,
                line.amount,
                line.leg_coa,
                line.line_nbr,
                line.transaction_number,
                hdr.transaction_date,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
                wsc_ahcs_lhin_txn_line_t   line,
                wsc_ahcs_lhin_txn_header_t hdr
            WHERE
                    line.batch_id = p_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id;

        COMMIT;
        logging_insert('LEASES', p_batch_id, 10, 'Inserting records in status table ends', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            p_error_flag := '1';
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('LEASES', p_batch_id, 9.1, 'Error While updating Line table with Header ID/inserting data in status table',
            sqlerrm,
                          sysdate);
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT020', 'LEASES', err_msg);
    END wsc_process_lhin_temp_to_header_line_p;

    PROCEDURE wsc_async_process_update_validate_transform_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    ) AS
        err_msg VARCHAR2(4000);
    BEGIN
        logging_insert('LEASES', p_batch_id, 5.1, 'Starts ASYNC DB Scheduler', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        dbms_scheduler.create_job(job_name => 'INVOKE_WSC_PROCESS_LEASES_STAGE_TO_HEADER_LINE_P' || p_batch_id, job_type => 'PLSQL_BLOCK',
        job_action => '
                                 DECLARE
                                    p_error_flag VARCHAR2(2);
                                 BEGIN                                
         WSC_LHIN_PKG.wsc_process_lhin_temp_to_header_line_p('
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
         wsc_ahcs_lhin_validation_transformation_pkg.data_validation('
                                                                                                                                         ||
                                                                                                                                         p_batch_id
                                                                                                                                         ||
                                                                                                                                         ');
                                               
          end if;                                   
       END;', enabled => true, auto_drop => true,
                                 comments => 'Async steps to split the data from stage and insert into header and line tables. Also, update line table, insert into WSC_AHCS_INT_STATUS_T and call Validation and Transformation procedure');

        logging_insert('LEASES', p_batch_id, 200, 'Async V & T completed.', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('LHIN', p_batch_id, 5.2, 'Error in Async DB Proc', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            COMMIT;
    END wsc_async_process_update_validate_transform_p;

END wsc_lhin_pkg;
/