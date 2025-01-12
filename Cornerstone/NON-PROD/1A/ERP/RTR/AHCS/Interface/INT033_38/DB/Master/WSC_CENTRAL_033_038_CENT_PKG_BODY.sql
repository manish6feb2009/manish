create or replace PACKAGE BODY "WSC_CENTRAL_PKG" AS

    PROCEDURE "WSC_CENTERAL_STAGE_P" (
        in_wsc_central_stage IN wsc_central_s_type_table
    ) AS
    BEGIN
        FORALL i IN 1..in_wsc_central_stage.count
            INSERT INTO wsc_ahcs_central_txn_stg_t (
                batch_id,
                rice_id,
                data_string
            ) VALUES (
                in_wsc_central_stage(i).batchid,
                in_wsc_central_stage(i).rice_id,
                in_wsc_central_stage(i).data_string
            );

    END "WSC_CENTERAL_STAGE_P";

    PROCEDURE wsc_process_central_header_t_p (
        p_batch_id IN NUMBER
    ) IS

        txn_id_row    wsc_ctrl_txn_id_s_type;
        txn_id_array  wsc_ctrl_txn_id_s_type_table := wsc_ctrl_txn_id_s_type_table();
        v_error_msg   VARCHAR2(200);
        v_stage       VARCHAR2(200);
        v_txn_id      VARCHAR2(100);
        v_header_id   NUMBER;
        v_counter     NUMBER;
        batch_row     wsc_ahcs_int_control_t%rowtype;
        CURSOR header_primary_data (
            p_batch_id NUMBER
        ) IS
            --select je_code,ledger_name from wsc_ahcs_central_txn_line_t where batch_id = p_batch_id group by je_code,ledger_name;       
        SELECT
            l.je_code,
            l.gl_oper_grp,
            l.gl_legal_entity,
            l.ledger_name,
            SUM(Decode(DR_CR_FLAG,'DR',NVL(DEFAULT_AMOUNT,0),0))-SUM(Decode(DR_CR_FLAG,'CR',NVL(DEFAULT_AMOUNT,0),0)) DIFF_AMT
        FROM
            wsc_ahcs_central_txn_line_t  l,
            wsc_ahcs_int_status_t        s
        WHERE
                l.line_id = s.line_id
            AND s.status = 'TRANSFORM_SUCCESS'
            AND l.batch_id = s.batch_id
            AND l.batch_id = p_batch_id
            AND l.header_id IS NULL
        GROUP BY
            l.je_code,
            l.gl_oper_grp,
            l.gl_legal_entity,
            l.ledger_name;

        CURSOR batch_details (
            p_batch_id NUMBER
        ) IS
        SELECT
            *
        FROM
            wsc_ahcs_int_control_t
        WHERE
            batch_id = p_batch_id;

    BEGIN
    logging_insert('CENTRAL',p_batch_id,40,'Creating Headers',null,sysdate);
        OPEN batch_details(p_batch_id);
        FETCH batch_details INTO batch_row;
        CLOSE batch_details;
        v_counter := 1;
        v_stage := 'INSERT HEADER';
        FOR i IN header_primary_data(p_batch_id) LOOP
            v_header_id := wsc_ctrl_header_t_s1.nextval;
            v_txn_id := 'CTRL' || wsc_ctrl_header_t_s2.nextval;
            INSERT INTO wsc_ahcs_central_txn_header_t (
                transaction_date,
                transaction_number,
                ledger_name,
                je_code,
                je_category,
                file_name,
                file_ext_date,
                source_system,
                file_records_count,
                event_type,
                batch_id,
                header_id,
                DIFF_AMOUNT
            ) VALUES (
                to_date(substr(batch_row.attribute1, 1, 6), 'mmddyy'),
                v_txn_id,
                i.ledger_name,
                i.je_code,
                (
                    SELECT
                        je_category
                    FROM
                        wsc_ahcs_central_je_ctg_map_t
                    WHERE
                        je_code = i.je_code
                ),
                batch_row.file_name,
                to_date(substr(batch_row.attribute1, 1, 6), 'mmddyy'),
                'CENTRAL',
                batch_row.total_records,
                'JOURNALS',
                p_batch_id,
                to_number(v_header_id),
                i.DIFF_AMT
            );

            txn_id_row := wsc_ctrl_txn_id_s_type(i.je_code, i.ledger_name, i.gl_legal_entity, i.gl_oper_grp, v_txn_id,
                                                v_header_id);

            dbms_output.put_line(txn_id_row.header_id);
            dbms_output.put_line(v_counter);
            txn_id_array.extend;
            txn_id_array(v_counter) := txn_id_row;
            v_counter := v_counter + 1;
        END LOOP;
        logging_insert('CENTRAL',p_batch_id,41,'Headers created. total headers: '||v_counter,null,sysdate);

        COMMIT;
        dbms_output.put_line(txn_id_array.count);
        v_stage := 'UPDATE LINE';
        logging_insert('CENTRAL',p_batch_id,42,'updating line data with header value',null,sysdate);
        FORALL i IN 1..txn_id_array.count
            --dbms_output.put_line(txn_id_array(2).header_id);
            MERGE INTO wsc_ahcs_central_txn_line_t l
            USING (
                      SELECT
                          line_id,
                          ROW_NUMBER()
                          OVER(PARTITION BY je_code, ledger_name
                               ORDER BY line_id
                          ) je_line_nbr
                      FROM
                          wsc_ahcs_central_txn_line_t
                      WHERE
                              je_code = txn_id_array(i).je_code
                          AND ledger_name = txn_id_array(i).ledger_name
                          AND batch_id = p_batch_id
                          AND gl_legal_entity = txn_id_array(i).gl_legal_entity
                          AND gl_oper_grp = txn_id_array(i).gl_oper_grp
                  )
            t ON ( l.line_id = t.line_id )
            WHEN MATCHED THEN UPDATE
            SET l.header_id = txn_id_array(i).header_id,
                l.transaction_number = txn_id_array(i).transaction_id,
                l.je_line_nbr = t.je_line_nbr;

        --forall i in 1..txn_id_array.count
--         MERGE INTO WSC_AHCS_INT_STATUS_T s
--            USING (select line_id from wsc_ahcs_central_txn_line_t where je_code = txn_id_array(i).je_code 
--                    and ledger_name = txn_id_array(i).ledger_name and batch_id = p_batch_id) t
--            on (s.line_id = t.line_id)
--            WHEN MATCHED THEN
--                Update set l.header_id = txn_id_array(i).header_id,
--                s.attribute = txn_id_array(i).transaction_id,
--                l.je_line_nbr = t.je_line_nbr;
    logging_insert('CENTRAL',p_batch_id,43,'updated line data with header value',null,sysdate);
        v_stage := 'UPDATE STATUS';
        UPDATE wsc_ahcs_int_status_t s
        SET
            ( header_id,
              attribute3 ) = (
                SELECT
                    l.header_id,
                    l.transaction_number
                FROM
                    wsc_ahcs_central_txn_line_t l
                WHERE
                        s.line_id = l.line_id
                    AND s.batch_id = l.batch_id
                    AND l.batch_id = p_batch_id
            )
        WHERE
                s.batch_id = p_batch_id
            AND s.header_id IS NULL;

        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'TRANSFORM_SUCCESS',
            last_updated_by = 'DB_CENTRAL_PKG',
            last_updated_date = sysdate
        WHERE
            batch_id = p_batch_id;
            commit;
    logging_insert('CENTRAL',p_batch_id,44,'updated status table data with header value',null,sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            v_error_msg := substr(sqlerrm, 1, 150);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = 'VALIDATION_FAILED',
                attribute5 = 'STAGE: '
                             || v_stage
                             || ' || ERROR '
                             || v_error_msg
            WHERE
                batch_id = p_batch_id;

            COMMIT;
    END "WSC_PROCESS_CENTRAL_HEADER_T_P";

    PROCEDURE wsc_process_central_stage_data_p (
        p_batch_id          NUMBER,
        p_application_name  VARCHAR2,
        p_file_name         VARCHAR2
    ) IS

        v_error_msg        VARCHAR2(200);
        v_stage            VARCHAR2(200);
        CURSOR cen_stage_data (
            p_batch_id NUMBER
        ) IS
        SELECT
            *
        FROM
            wsc_ahcs_central_txn_stg_t
        WHERE
                batch_id = p_batch_id
            AND data_string LIKE '%|%';

        TYPE cen_stage_data_type IS
            TABLE OF cen_stage_data%rowtype;
        lv_cen_stage_data  cen_stage_data_type;
        header_row         VARCHAR2(1000);
    BEGIN
        /********** UPDATE CONTROL TABLE - START *************/
        v_stage := 'UPDATE CONTROL TABLE';
        SELECT
            data_string
        INTO header_row
        FROM
            wsc_ahcs_central_txn_stg_t
        WHERE
                batch_id = p_batch_id
            AND data_string NOT LIKE '%|%';

        UPDATE wsc_ahcs_int_control_t
        SET
            total_records = substr(header_row, 25, 7),
            attribute1 = substr(header_row, 11, 14),
            attribute2 = substr(header_row, 1, 2)
        WHERE
            batch_id = p_batch_id;

        COMMIT;
         /********** UPDATE CONTROL TABLE - END *************/

         /********** PROCESS UNSTRUCTURED DATA TO LINE DATA - START *************/
        v_stage := 'PROCESS LINE DATA';
        OPEN cen_stage_data(p_batch_id);
        LOOP
            FETCH cen_stage_data BULK COLLECT INTO lv_cen_stage_data LIMIT 4000;
            EXIT WHEN lv_cen_stage_data.count = 0;
            FORALL i IN 1..lv_cen_stage_data.count
                INSERT INTO wsc_ahcs_central_txn_line_t (
                    default_amount,
                    acc_amt,
                    leg_coa,
                    leg_seg2,
                    leg_seg3,
                    dr_cr_flag,
                    wic,
                    batch_id,
                    line_id,
                    creation_date,
                    created_by,
                    je_code
                ) VALUES (
                    abs(to_number(regexp_substr(lv_cen_stage_data(i).data_string, '[^|]+', 1, 4))),
                    abs(to_number(regexp_substr(lv_cen_stage_data(i).data_string, '[^|]+', 1, 4))),
                    regexp_substr(lv_cen_stage_data(i).data_string, '[^|]+', 1, 1)
                    || '.'
                    || replace(regexp_substr(lv_cen_stage_data(i).data_string, '[^|]+', 1, 2), ' ', ''),
                    regexp_substr(lv_cen_stage_data(i).data_string, '[^|]+', 1, 1),
                    replace(regexp_substr(lv_cen_stage_data(i).data_string, '[^|]+', 1, 2), ' ', ''),
                        CASE
                            WHEN to_number(regexp_substr(lv_cen_stage_data(i).data_string, '[^|]+', 1, 4)) < 0 THEN
                                'CR'
                            ELSE
                                'DR'
                        END,
                    regexp_substr(lv_cen_stage_data(i).data_string, '[^|]+', 1, 5),
                    lv_cen_stage_data(i).batch_id,
                    wsc_ctrl_line_t_s1.NEXTVAL,
                    sysdate,
                    'INTEGRATION',
                    TRIM(regexp_substr(lv_cen_stage_data(i).data_string, '[^|]+', 1, 3))
                );

        END LOOP;

        COMMIT;
        /********** PROCESS UNSTRUCTURED DATA TO LINE DATA - END *************/

        /********** SELECT INSERT FROM LINE TO STATUS - START *************/
        v_stage := 'INSERT INTO STATUS';
        INSERT INTO wsc_ahcs_int_status_t (
            line_id,
            application,
            file_name,
            batch_id,
            status,
            cr_dr_indicator,
            value,
            source_coa,
            attribute11,
            created_by,
            created_date,
            last_updated_by,
            last_updated_date
        )
            SELECT
                line.line_id,
                p_application_name,
                p_file_name,
                p_batch_id,
                'NEW',
                line.dr_cr_flag,
                line.acc_amt,
                line.leg_coa,
                to_date(substr(cont.attribute1, 1, 6), 'mmddyy'),
                 'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
                wsc_ahcs_central_txn_line_t  line,
                wsc_ahcs_int_control_t       cont
            WHERE
                    line.batch_id = cont.batch_id
                AND line.batch_id = p_batch_id;
        /********** SELECT INSERT FROM LINE TO STATUS - END *************/

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_msg := substr(sqlerrm, 1, 150);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = 'VALIDATION_FAILED',
                attribute5 = 'STAGE: '
                             || v_stage
                             || ' || ERROR '
                             || v_error_msg
            WHERE
                batch_id = p_batch_id;

            COMMIT;
            WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(p_batch_id,
                        'INT033',
                        'CENTRAL',
                        SQLERRM);       
    END "WSC_PROCESS_CENTRAL_STAGE_DATA_P";

    PROCEDURE wsc_async_process_central_p (
        p_batch_id          NUMBER,
        p_application_name  VARCHAR2,
        p_file_name         VARCHAR2
    ) AS
        err_msg VARCHAR2(2000);
    BEGIN
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;

        dbms_scheduler.create_job(job_name => 'WSC_PROCESS_CENTRAL_STAGE_DATA_P' || p_batch_id, job_type => 'PLSQL_BLOCK',
                                 job_action => 'BEGIN
         WSC_CENTRAL_PKG.WSC_PROCESS_CENTRAL_STAGE_DATA_P('
                                               || p_batch_id
                                               || ','''
                                               || p_application_name
                                               || ''','''
                                               || p_file_name
                                               || ''');
         WSC_AHCS_CENTRAL_VALIDATION_TRANSFORMATION_PKG.data_validation('
                                               || p_batch_id
                                               || ');
       END;',
                                 enabled => true,
                                 auto_drop => true,
                                 comments => 'Async steps to process stage data and update, insert into WSC_AHCS_INT_STATUS_T and call Validate and Transform procedure');

    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            dbms_output.put_line(sqlerrm);
    END wsc_async_process_central_p;

END wsc_central_pkg;