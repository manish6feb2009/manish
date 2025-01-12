create or replace PACKAGE BODY "WSC_PSFA_PKG" AS

    PROCEDURE wsc_ahcs_psfa_txn_header_p (
        in_wsc_ahcs_psfa_txn_header IN wsc_psfa_header_t_type_table
    ) AS
        err_msg VARCHAR2(2000);
    BEGIN
	--logging_insert (null,null,101,'Insertion in PSFA Header Table starts',null,sysdate);
        FORALL i IN 1..in_wsc_ahcs_psfa_txn_header.count
  --LOOP
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
--                transaction_date,
--                transaction_number,
--                ledger_name,
--                source_trn_nbr,
--                source_system,
--                leg_ae_header_id,
--                event_type,
--                event_class,
--                ACCOUNTING_DATE,
--                asset_book,
--                asset_cat,
--                asset_desc,
--                header_desc,
--                led_leg_name,
--                je_name,
--                je_category,
--                trn_amount,
--                file_name,
--                transaction_type,
--                created_by,
--                creation_date,
--                last_updated_by,
--                last_update_date,
--                attribute1,
--                attribute2,
--                attribute3,
--                attribute4,
--                attribute5,
--                attribute6,
--                attribute7,
--                attribute8,
--                attribute9,
--                attribute10,
--                je_batch_name,
--                header_id,
--                batch_id
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
--                to_date(in_wsc_ahcs_PSFA_txn_header(i).ACCOUNTING_DATE, 'yyyy-mm-dd'),
--                in_wsc_ahcs_PSFA_txn_header(i).TRANSACTION_NUMBER,
--                in_wsc_ahcs_PSFA_txn_header(i).ledger_name,
--                in_wsc_ahcs_PSFA_txn_header(i).source_trn_nbr,
--                in_wsc_ahcs_PSFA_txn_header(i).source_system,
--                in_wsc_ahcs_PSFA_txn_header(i).leg_ae_header_id,
--                in_wsc_ahcs_PSFA_txn_header(i).event_type,
--                in_wsc_ahcs_PSFA_txn_header(i).event_class,
--                to_date(in_wsc_ahcs_PSFA_txn_header(i).ACCOUNTING_DATE, 'yyyy-mm-dd'),
--                in_wsc_ahcs_PSFA_txn_header(i).asset_book,
--                in_wsc_ahcs_PSFA_txn_header(i).asset_cat,
--                in_wsc_ahcs_PSFA_txn_header(i).asset_desc,
--                in_wsc_ahcs_PSFA_txn_header(i).header_desc,
--                in_wsc_ahcs_PSFA_txn_header(i).led_leg_name,
--                in_wsc_ahcs_PSFA_txn_header(i).je_name,
--                in_wsc_ahcs_PSFA_txn_header(i).je_category,
--                in_wsc_ahcs_PSFA_txn_header(i).trn_amount,
--                in_wsc_ahcs_PSFA_txn_header(i).file_name,
--                in_wsc_ahcs_PSFA_txn_header(i).transaction_type,
--                'FIN_INT',
--                sysdate,
--                'FIN_INT',
--                sysdate,
--                in_wsc_ahcs_PSFA_txn_header(i).attribute1,
--                in_wsc_ahcs_PSFA_txn_header(i).attribute2,
--                in_wsc_ahcs_PSFA_txn_header(i).attribute3,
--                in_wsc_ahcs_PSFA_txn_header(i).attribute4,
--                in_wsc_ahcs_PSFA_txn_header(i).attribute5,
--                in_wsc_ahcs_PSFA_txn_header(i).attribute6,
--                in_wsc_ahcs_PSFA_txn_header(i).attribute7,
--                in_wsc_ahcs_PSFA_txn_header(i).attribute8,
--                in_wsc_ahcs_PSFA_txn_header(i).attribute9,
--                in_wsc_ahcs_PSFA_txn_header(i).attribute10,
--                in_wsc_ahcs_PSFA_txn_header(i).je_batch_name,
--                wsc_PSFA_header_id_s1.NEXTVAL,
--                in_wsc_ahcs_PSFA_txn_header(i).batch_id
            );

--        logging_insert(NULL, NULL, 102, 'Insertion in PSFA Header Table ends', NULL,  sysdate);
--END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
--            logging_insert('PSFA', NULL, 112, 'Error while Inserting in PSFA Header Table Proc', sqlerrm,sysdate);
    END wsc_ahcs_psfa_txn_header_p;

    PROCEDURE wsc_ahcs_psfa_txn_line_p (
        in_wsc_ahcs_psfa_txn_line IN wsc_psfa_line_t_type_table
    ) AS
        err_msg VARCHAR2(2000);
    BEGIN
        logging_insert(NULL, NULL, in_wsc_ahcs_psfa_txn_line.count, 'Insertion in PSFA Line Table starts', NULL,
                      sysdate);
        FORALL i IN 1..in_wsc_ahcs_psfa_txn_line.count
  --LOOP
            INSERT INTO wsc_ahcs_psfa_txn_line_t (
                batch_id,
                line_id,
--                HEADER_ID,
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
                attribute12
--                transaction_number,
--                dePSFAult_amount,
--                dePSFAult_currency,
--                leg_coa,
--                leg_seg1,
--                leg_seg2,
--                leg_seg3,
--                leg_seg4,
--                leg_seg5,
--                leg_seg6,
--                leg_seg7,
--                gl_legal_entity,
--                gl_acct,
--                gl_oper_grp,
--                gl_dept,
--                gl_site,
--                gl_ic,
--                gl_projects,
--                gl_fut_1,
--                gl_fut_2,
--                acc_class,
--                acc_amt,
--                dr_cr_flag,
--                je_line_nbr,
--                line_desc,
--                transaction_type,
--                acc_currency,
--                created_by,
--                creation_date,
--                last_updated_by,
--                last_update_date,
--                line_id,
--                batch_id,
--                attribute1,
--                attribute2,
--                attribute3,
--                attribute4,
--                attribute5,
--                attribute6,
--                attribute7,
--                attribute8,
--                attribute9,
--                attribute10,
--                attribute11,
--                attribute12,
--                target_coa,
--                leg_ae_header_id,
--                leg_ae_line_nbr,
--                source_trn_nbr
            ) VALUES (
                in_wsc_ahcs_psfa_txn_line(i).batch_id,
                wsc_psfa_line_t_s1.NEXTVAL,
--                in_wsc_ahcs_PSFA_txn_line(i).HEADER_ID,
                wsc_psfa_line_seq_nbr_t_s2.NEXTVAL,
                in_wsc_ahcs_psfa_txn_line(i).hdr_seq_nbr,
                to_number(in_wsc_ahcs_psfa_txn_line(i).txn_amount),
                to_number(in_wsc_ahcs_psfa_txn_line(i).amount),
                to_date(in_wsc_ahcs_psfa_txn_line(i).rate_effdt, 'yyyy-mm-dd'),
               -- decode(instr(in_wsc_ahcs_psfa_txn_line(i).amount, '-'), 0, 'CR', 'DR'),
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
--                in_wsc_ahcs_PSFA_txn_line(i).LEG_COA
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
                ||  '00000', ---leg_coa concatenation
                in_wsc_ahcs_psfa_txn_line(i).target_coa,
                in_wsc_ahcs_psfa_txn_line(i).unit
                || '.'
                || in_wsc_ahcs_psfa_txn_line(i).location
                || '.'
                || in_wsc_ahcs_psfa_txn_line(i).account
                || '.'
                || in_wsc_ahcs_psfa_txn_line(i).dept_id, ----leg1_4
                in_wsc_ahcs_psfa_txn_line(i).anixter_vendor, --leg5_7
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
                in_wsc_ahcs_psfa_txn_line(i).attribute12
--                to_char('PSFA' || in_wsc_ahcs_PSFA_txn_line(i).leg_ae_header_id),
--                in_wsc_ahcs_PSFA_txn_line(i).dePSFAult_amount,
--                in_wsc_ahcs_PSFA_txn_line(i).dePSFAult_currency,
--                in_wsc_ahcs_PSFA_txn_line(i).leg_seg1
--                || '.'
--                || in_wsc_ahcs_PSFA_txn_line(i).leg_seg2
--                || '.'
--                || in_wsc_ahcs_PSFA_txn_line(i).leg_seg3
--                || '.'
--                || in_wsc_ahcs_PSFA_txn_line(i).leg_seg4
--                || '.'
--                || in_wsc_ahcs_PSFA_txn_line(i).leg_seg5
--                || '.'
--                || in_wsc_ahcs_PSFA_txn_line(i).leg_seg6
--                || '.'
--                || in_wsc_ahcs_PSFA_txn_line(i).leg_seg7,
--                in_wsc_ahcs_PSFA_txn_line(i).leg_seg1,
--                in_wsc_ahcs_PSFA_txn_line(i).leg_seg2,
--                in_wsc_ahcs_PSFA_txn_line(i).leg_seg3,
--                in_wsc_ahcs_PSFA_txn_line(i).leg_seg4,
--                in_wsc_ahcs_PSFA_txn_line(i).leg_seg5,
--                in_wsc_ahcs_PSFA_txn_line(i).leg_seg6,
--                in_wsc_ahcs_PSFA_txn_line(i).leg_seg7,
--                in_wsc_ahcs_PSFA_txn_line(i).gl_legal_entity,
--                in_wsc_ahcs_PSFA_txn_line(i).gl_acct,
--                in_wsc_ahcs_PSFA_txn_line(i).gl_oper_grp,
--                in_wsc_ahcs_PSFA_txn_line(i).gl_dept,
--                in_wsc_ahcs_PSFA_txn_line(i).gl_site,
--                in_wsc_ahcs_PSFA_txn_line(i).gl_ic,
--                in_wsc_ahcs_PSFA_txn_line(i).gl_projects,
--                in_wsc_ahcs_PSFA_txn_line(i).gl_fut_1,
--                in_wsc_ahcs_PSFA_txn_line(i).gl_fut_2,
--                in_wsc_ahcs_PSFA_txn_line(i).acc_class,
--                in_wsc_ahcs_PSFA_txn_line(i).acc_amt,
--                in_wsc_ahcs_PSFA_txn_line(i).dr_cr_flag,
--                in_wsc_ahcs_PSFA_txn_line(i).je_line_nbr,
--                in_wsc_ahcs_PSFA_txn_line(i).line_desc,
--                in_wsc_ahcs_PSFA_txn_line(i).transaction_type,
--                in_wsc_ahcs_PSFA_txn_line(i).acc_currency,
--                'FIN_INT',
--                sysdate,
--                'FIN_INT',
--                sysdate,
--                wsc_PSFA_line_id_s1.NEXTVAL,
--                in_wsc_ahcs_PSFA_txn_line(i).batch_id,
--                in_wsc_ahcs_PSFA_txn_line(i).attribute1,
--                in_wsc_ahcs_PSFA_txn_line(i).attribute2,
--                in_wsc_ahcs_PSFA_txn_line(i).leg_seg1
--                || '.'
--                || in_wsc_ahcs_PSFA_txn_line(i).leg_seg2
--                || '.'
--                || in_wsc_ahcs_PSFA_txn_line(i).leg_seg3
--                || '.'
--                || in_wsc_ahcs_PSFA_txn_line(i).leg_seg4,
--                in_wsc_ahcs_PSFA_txn_line(i).leg_seg5
--                || '.'
--                || in_wsc_ahcs_PSFA_txn_line(i).leg_seg6
--                || '.'
--                || in_wsc_ahcs_PSFA_txn_line(i).leg_seg7,
--                in_wsc_ahcs_PSFA_txn_line(i).attribute5,
--                in_wsc_ahcs_PSFA_txn_line(i).attribute6,
--                in_wsc_ahcs_PSFA_txn_line(i).attribute7,
--                in_wsc_ahcs_PSFA_txn_line(i).attribute8,
--                in_wsc_ahcs_PSFA_txn_line(i).attribute9,
--                in_wsc_ahcs_PSFA_txn_line(i).attribute10,
--                to_date(in_wsc_ahcs_PSFA_txn_line(i).attribute11, 'yyyy-mm-dd'),
--                to_date(in_wsc_ahcs_PSFA_txn_line(i).attribute12, 'yyyy-mm-dd'),
--                in_wsc_ahcs_PSFA_txn_line(i).target_coa,
--                in_wsc_ahcs_PSFA_txn_line(i).leg_ae_header_id,
--                in_wsc_ahcs_PSFA_txn_line(i).leg_ae_line_nbr,
--                in_wsc_ahcs_PSFA_txn_line(i).source_trn_nbr
            );

   ---     logging_insert(NULL, NULL, 104, 'Insertion in PSFA Line Table ends', NULL,sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
--            logging_insert('PSFA', NULL, 111, 'Error while Inserting in PSFA Line Table Procedure', sqlerrm,sysdate);
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
--            legacy_header_id,
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
--                line.leg_ae_header_id,
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

--create or replace PACKAGE BODY "WSC_PSFA_PKG" AS
--
--	PROCEDURE WSC_PSFA_HEADER_P 
--    (
--		IN_WSC_AHCS_PSFA_TXN_HEADER IN WSC_PSFA_HEADER_T_TYPE_TABLE
--    ) AS
--    BEGIN	 
--        NULL;
--    END WSC_PSFA_HEADER_P;
--
--    PROCEDURE WSC_PSFA_LINE_P
--	(
--		IN_WSC_AHCS_PSFA_TXN_LINE IN WSC_PSFA_LINE_T_TYPE_TABLE
--	)AS
--    BEGIN 
--        NULL;
--    END WSC_PSFA_LINE_P;
--
--    PROCEDURE WSC_INSERT_PSFA_DATA_IN_GL_STATUS (
--        p_batch_id          NUMBER,
--        p_application_name  VARCHAR2,
--        p_file_name         VARCHAR2
--    ) AS
--    BEGIN 
--        NULL;
--    END WSC_INSERT_PSFA_DATA_IN_GL_STATUS;
--
--    PROCEDURE WSC_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P (
--        p_batch_id          NUMBER,
--        p_application_name  VARCHAR2,
--        p_file_name         VARCHAR2
--    ) AS
--    BEGIN  
--        NULL;
--    END WSC_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P;
--
--END WSC_PSFA_PKG;
