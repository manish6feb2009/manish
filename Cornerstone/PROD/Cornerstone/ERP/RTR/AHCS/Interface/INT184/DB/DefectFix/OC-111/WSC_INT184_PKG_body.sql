create or replace PACKAGE BODY "WSC_PSFA_PKG" AS

/* $Header: WSC_PSFA_PKG.pkb  ver 1.0 2021/07/15 12:30:00  $
    +==========================================================================+
    |              Copyright (c) 2020 Wesco.                                 |
    |                        All rights reserved                               |
    +==========================================================================+
    |                                                                          |
    |  FILENAME                                                                |
    |    WSC_PSFA_PKG.pkb                                   |
    |                                                                          |
    |  DESCRIPTION     										                   |
    |                                                                          |
    |  HISTORY                                                                 |
    |                                                                          |
    | Version    Date        Author                Description                 |
    | =======    ==========  =============         ============================|
    | 1.0        2021/07/15	  Snehal Shirke         Initial Version            |
    | 2.0        2023/11/01   Satya                 JIRA # OC-111 Adding 
                                                    LEG_AFFILIATE in LINE LEVEL
                                                    As GL Accountant I need AHCS 
                                                    specific to PSFA subledger 
                                                    to use updated inbound file 
                                                   layout & mapping intercompany 
                                                      from source file to derive 
                                                        future cloud IC segment.
    |
    |                                                                          |
    +==========================================================================+
    */

    PROCEDURE wsc_ahcs_psfa_txn_header_p (
        in_wsc_ahcs_psfa_txn_header IN wsc_psfa_header_t_type_table
    ) AS
        err_msg VARCHAR2(2000);
    BEGIN
        FORALL i IN 1..in_wsc_ahcs_psfa_txn_header.count
            INSERT INTO wsc_ahcs_psfa_txn_header_t (
                batch_id,
                header_id,
                hdr_seq_nbr,
                fiscal_year,
                accounting_period,
                asset_id,
                journal_id,
                cost,
                ltd_dep,
                nbv,
                accounting_date,
                trans_date,
                ledger_name,
                transaction_number,
                book,
                trans_type,
                category,
                profile_id,
                cap_num,
                invoice,
                file_name,
                descr,
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
                attribute12
            ) VALUES (
                in_wsc_ahcs_psfa_txn_header(i).batch_id,
                wsc_psfa_header_t_s1.NEXTVAL,
                in_wsc_ahcs_psfa_txn_header(i).hdr_seq_nbr,
                in_wsc_ahcs_psfa_txn_header(i).fiscal_year,
                in_wsc_ahcs_psfa_txn_header(i).accounting_period,
                in_wsc_ahcs_psfa_txn_header(i).asset_id,
                in_wsc_ahcs_psfa_txn_header(i).journal_id,
                in_wsc_ahcs_psfa_txn_header(i).cost,
                in_wsc_ahcs_psfa_txn_header(i).ltd_dep,
                in_wsc_ahcs_psfa_txn_header(i).nbv,
                to_date(in_wsc_ahcs_psfa_txn_header(i).accounting_date, 'yyyy-mm-dd'),
                to_date(in_wsc_ahcs_psfa_txn_header(i).trans_date, 'yyyy-mm-dd'),
                in_wsc_ahcs_psfa_txn_header(i).ledger_name,
                in_wsc_ahcs_psfa_txn_header(i).transaction_number,
                in_wsc_ahcs_psfa_txn_header(i).book,
                in_wsc_ahcs_psfa_txn_header(i).trans_type,
                in_wsc_ahcs_psfa_txn_header(i).category,
                in_wsc_ahcs_psfa_txn_header(i).profile_id,
                in_wsc_ahcs_psfa_txn_header(i).cap_num,
                in_wsc_ahcs_psfa_txn_header(i).invoice,
                in_wsc_ahcs_psfa_txn_header(i).file_name,
                in_wsc_ahcs_psfa_txn_header(i).descr,
                sysdate,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                in_wsc_ahcs_psfa_txn_header(i).attribute1,
                in_wsc_ahcs_psfa_txn_header(i).attribute2,
                in_wsc_ahcs_psfa_txn_header(i).attribute3,
                in_wsc_ahcs_psfa_txn_header(i).attribute4,
                in_wsc_ahcs_psfa_txn_header(i).attribute5,
                in_wsc_ahcs_psfa_txn_header(i).attribute6,
                in_wsc_ahcs_psfa_txn_header(i).attribute7,
                in_wsc_ahcs_psfa_txn_header(i).attribute8,
                in_wsc_ahcs_psfa_txn_header(i).attribute9,
                in_wsc_ahcs_psfa_txn_header(i).attribute10,
                in_wsc_ahcs_psfa_txn_header(i).attribute11,
                in_wsc_ahcs_psfa_txn_header(i).attribute12
            );

    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
    END wsc_ahcs_psfa_txn_header_p;

    PROCEDURE wsc_ahcs_psfa_txn_line_p (
        in_wsc_ahcs_psfa_txn_line IN wsc_psfa_line_t_type_table
    ) AS
        err_msg VARCHAR2(2000);
    BEGIN
        logging_insert(NULL, NULL, in_wsc_ahcs_psfa_txn_line.count, 'Insertion in PSFA Line Table starts', NULL,
                      sysdate);
        FORALL i IN 1..in_wsc_ahcs_psfa_txn_line.count
  
            INSERT INTO wsc_ahcs_psfa_txn_line_t (
                batch_id,
                line_id,
                line_seq_number,
                hdr_seq_nbr,
                txn_amount,
                amount,
                rate_effdt,
                dr_cr_flag,
                gl_legal_entity,
                gl_oper_grp,
                gl_acct,
                gl_dept,
                gl_site,
                gl_ic,
                gl_projects,
                gl_fut_1,
                gl_fut_2,
                transaction_number,
                txn_currency_cd,
                currency_cd,
                unit,
                account,
                dept_id,
                anixter_vendor,
                location,
                leg_coa,
                target_coa,
                leg_seg_1_4,
                leg_seg_5_7,
                distribution_type,
                rate_type,
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
				LEG_AFFILIATE --- Added on 11-01-2023 for JIRA # OC-111
            ) VALUES (
                in_wsc_ahcs_psfa_txn_line(i).batch_id,
                wsc_psfa_line_t_s1.NEXTVAL,
                wsc_psfa_line_seq_nbr_t_s2.NEXTVAL,
                in_wsc_ahcs_psfa_txn_line(i).hdr_seq_nbr,
                to_number(in_wsc_ahcs_psfa_txn_line(i).txn_amount),
                to_number(in_wsc_ahcs_psfa_txn_line(i).amount),
                to_date(in_wsc_ahcs_psfa_txn_line(i).rate_effdt, 'yyyy-mm-dd'),
                decode(sign(in_wsc_ahcs_psfa_txn_line(i).amount), - 1, 'CR', 'DR'),
                in_wsc_ahcs_psfa_txn_line(i).gl_legal_entity,
                in_wsc_ahcs_psfa_txn_line(i).gl_oper_grp,
                in_wsc_ahcs_psfa_txn_line(i).gl_acct,
                in_wsc_ahcs_psfa_txn_line(i).gl_dept,
                in_wsc_ahcs_psfa_txn_line(i).gl_site,
                in_wsc_ahcs_psfa_txn_line(i).gl_ic,
                in_wsc_ahcs_psfa_txn_line(i).gl_projects,
                in_wsc_ahcs_psfa_txn_line(i).gl_fut_1,
                in_wsc_ahcs_psfa_txn_line(i).gl_fut_2,
                in_wsc_ahcs_psfa_txn_line(i).transaction_number,
                in_wsc_ahcs_psfa_txn_line(i).txn_currency_cd,
                in_wsc_ahcs_psfa_txn_line(i).currency_cd,
                in_wsc_ahcs_psfa_txn_line(i).unit,
                in_wsc_ahcs_psfa_txn_line(i).account,
                in_wsc_ahcs_psfa_txn_line(i).dept_id,
                in_wsc_ahcs_psfa_txn_line(i).anixter_vendor,
                in_wsc_ahcs_psfa_txn_line(i).location,
                in_wsc_ahcs_psfa_txn_line(i).unit
                || '.'
                || in_wsc_ahcs_psfa_txn_line(i).location
                || '.'
                || in_wsc_ahcs_psfa_txn_line(i).dept_id
                || '.'
                || in_wsc_ahcs_psfa_txn_line(i).account
                || '.'
                || in_wsc_ahcs_psfa_txn_line(i).anixter_vendor 
                || '.'
                ||  in_wsc_ahcs_psfa_txn_line(i).LEG_AFFILIATE,  ---leg_coa concatenation --- --- Added on 11-01-2023 for JIRA # OC-111
                in_wsc_ahcs_psfa_txn_line(i).target_coa,
                in_wsc_ahcs_psfa_txn_line(i).unit
                || '.'
                || in_wsc_ahcs_psfa_txn_line(i).location
                || '.'
                || in_wsc_ahcs_psfa_txn_line(i).account
                || '.'
                || in_wsc_ahcs_psfa_txn_line(i).dept_id, ----leg1_4
                in_wsc_ahcs_psfa_txn_line(i).anixter_vendor || '.' || in_wsc_ahcs_psfa_txn_line(i).LEG_AFFILIATE , --leg5_7 --- Added on 11-01-2023 for JIRA # OC-111
                in_wsc_ahcs_psfa_txn_line(i).distribution_type,
                in_wsc_ahcs_psfa_txn_line(i).rate_type,
                sysdate,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                in_wsc_ahcs_psfa_txn_line(i).attribute1,
                in_wsc_ahcs_psfa_txn_line(i).attribute2,
                in_wsc_ahcs_psfa_txn_line(i).attribute3,
                in_wsc_ahcs_psfa_txn_line(i).attribute4,
                in_wsc_ahcs_psfa_txn_line(i).attribute5,
                in_wsc_ahcs_psfa_txn_line(i).attribute6,
                in_wsc_ahcs_psfa_txn_line(i).attribute7,
                in_wsc_ahcs_psfa_txn_line(i).attribute8,
                in_wsc_ahcs_psfa_txn_line(i).attribute9,
                in_wsc_ahcs_psfa_txn_line(i).attribute10,
                in_wsc_ahcs_psfa_txn_line(i).attribute11,
                in_wsc_ahcs_psfa_txn_line(i).attribute12,
				in_wsc_ahcs_psfa_txn_line(i).LEG_AFFILIATE  --- Added on 11-01-2023 for JIRA # OC-111
            );
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
    END wsc_ahcs_psfa_txn_line_p;

    PROCEDURE wsc_insert_data_in_gl_status_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    ) IS
        lv_count NUMBER;
        err_msg  VARCHAR2(2000);
    BEGIN
        logging_insert('PSFA', p_batch_id, 1, 'Update PSFA Line Table with Header ID - Starts ', NULL,
                      sysdate);
        UPDATE wsc_ahcs_psfa_txn_line_t line
        SET
            ( header_id ) = (
                SELECT /*+ index(hdr WSC_AHCS_PSFA_TXN_HEADER_LEG_AE_HEADER_ID_I) */
                    hdr.header_id
                FROM
                    wsc_ahcs_psfa_txn_header_t hdr
                WHERE
                        line.transaction_number = hdr.transaction_number
                    AND line.batch_id = hdr.batch_id
            )
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        logging_insert('PSFA', p_batch_id, 2, 'Update PSFA Line Table with Header ID - Ends', NULL,
                      sysdate);
        logging_insert('PSFA', p_batch_id, 3, 'Insert records in Status Table - Starts', NULL,
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
                line.dr_cr_flag,
                line.txn_currency_cd,
                line.amount,
                line.leg_coa,
                line.line_seq_number,
                hdr.transaction_number,
                hdr.accounting_date,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
                wsc_ahcs_psfa_txn_line_t   line,
                wsc_ahcs_psfa_txn_header_t hdr
            WHERE
                    line.batch_id = p_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id;

        COMMIT;
        logging_insert('PSFA', p_batch_id, 4, 'Insert records in Status Table - Ends', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('PSFA', p_batch_id, 113, 'Error While updating Line table with Header ID/Inserting data in Status Table', sqlerrm,
                          sysdate);
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT184', 'PSFA', sqlerrm);
            dbms_output.put_line(sqlerrm);
    END;

    PROCEDURE wsc_async_process_update_validate_transform_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    ) AS

        err_msg   VARCHAR2(2000);
        min_value NUMBER;
        CURSOR cur_min_value IS
        SELECT
            MIN(line_seq_number)
        FROM
            wsc_ahcs_psfa_txn_line_t
        WHERE
            batch_id = p_batch_id;

    BEGIN
        logging_insert('PSFA', p_batch_id, 109, 'Starts ASYNC DB Scheduler', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;

        COMMIT;
         ---update line_seq_nbr
        OPEN cur_min_value;
        FETCH cur_min_value INTO min_value;
        CLOSE cur_min_value;
        UPDATE wsc_ahcs_psfa_txn_line_t
        SET
            line_seq_number = ( line_seq_number - min_value ) + 1
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        dbms_scheduler.create_job(job_name => 'INVOKE_WSC_PSFA_INSERT_DATA_IN_GL_STATUS_P_' || p_batch_id, job_type => 'PLSQL_BLOCK',
        job_action => 'BEGIN
         WSC_PSFA_PKG.WSC_INSERT_DATA_IN_GL_STATUS_P('
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
                                                                                                                                    ''');
         WSC_AHCS_PSFA_VALIDATION_TRANSFORMATION_PKG.data_validation('
                                                                                                                                    ||
                                                                                                                                    p_batch_id
                                                                                                                                    ||
                                                                                                                                    ');
       END;', enabled => true, auto_drop => true,
                                 comments => 'Async steps to update, Insert into WSC_AHCS_INT_STATUS_T and call Validate and Transform procedure');

    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('PSFA', p_batch_id, 110, 'Error in Async DB Procedure', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            dbms_output.put_line(sqlerrm);
            COMMIT;
    END;

END wsc_psfa_pkg;
/