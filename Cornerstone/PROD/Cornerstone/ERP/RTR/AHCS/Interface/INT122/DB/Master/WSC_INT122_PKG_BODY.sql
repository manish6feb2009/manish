create or replace PACKAGE BODY wsc_poc_pkg AS

    PROCEDURE import_header_data_to_stg (
        p_ics_run_id   IN VARCHAR2,
        p_event_name   IN VARCHAR2,
        p_batch_id     IN NUMBER,
        p_poc_header_t IN wsc_poc_header_tt,
        x_status       OUT VARCHAR2
    ) AS
    --    lc_header_id NUMBER;
    BEGIN
 --logging_insert ('ERP POC',p_batch_id,1,'Insertion to POC header staging table start',null,sysdate);   
        FORALL i IN 1..p_poc_header_t.count
            INSERT INTO wsc_ahcs_poc_txn_header_t (
                header_id,
                batch_id,
                transaction_number,
                ledger_name,
                je_source,
                source_system,
                je_amount,
                je_header_id,
                je_header_desc,
                leg_led_name,
                je_batch_name,
                je_category,
                file_name,
                transaction_type,
                transaction_date,
                gl_date,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
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
                wsc_poc_header_s1.NEXTVAL,
                p_batch_id,
                p_poc_header_t(i).transaction_number,
                p_poc_header_t(i).ledger_name,
                p_poc_header_t(i).je_source,
                p_poc_header_t(i).source_system,
                abs(p_poc_header_t(i).je_amount),
                p_poc_header_t(i).je_header_id,
                p_poc_header_t(i).je_header_desc,
                p_poc_header_t(i).leg_led_name,
                p_poc_header_t(i).je_batch_name,
                p_poc_header_t(i).je_category,
                p_poc_header_t(i).file_name,
                p_poc_header_t(i).transaction_type,
                to_date(p_poc_header_t(i).transaction_date,'yyyy-mm-dd'),
                to_date(p_poc_header_t(i).gl_date,'yyyy-mm-dd'),
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate,
                p_poc_header_t(i).attribute1,
                p_poc_header_t(i).attribute2,
                p_poc_header_t(i).attribute3,
                p_poc_header_t(i).attribute4,
                p_poc_header_t(i).attribute5,
                p_poc_header_t(i).attribute6,
                p_poc_header_t(i).attribute7,
                p_poc_header_t(i).attribute8,
                p_poc_header_t(i).attribute9,
                p_poc_header_t(i).attribute10,
                to_date(p_poc_header_t(i).attribute11, 'yyyy-mm-dd'),
                to_date(p_poc_header_t(i).attribute12, 'yyyy-mm-dd')
            );
-- END LOOP
        COMMIT;
        x_status := 'SUCCESS';
-- logging_insert ('ERP POC',p_batch_id,2,'Insertion to POC header stage completed.',null,sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('Error While inserting the data into header'
                                 || sqlerrm
                                 || $$plsql_unit
                                 || 'Line'
                                 || $$plsql_line);
--logging_insert ('ERP POC',p_batch_id,3,'Exception while inserting data to POC header stage table ',sqlerrm,sysdate);
            x_status := sqlerrm(sqlcode)
                        || $$plsql_unit
                        || 'Line'
                        || $$plsql_line;
    END import_header_data_to_stg;

    PROCEDURE import_line_data_to_stg (
        p_ics_run_id IN VARCHAR2,
        p_event_name IN VARCHAR2,
        p_poc_line_t IN wsc_poc_line_tt,
        p_batch_id   IN NUMBER,
        x_status     OUT VARCHAR2
    ) AS
    BEGIN
--logging_insert ('ERP POC',p_batch_id,4,'Insertion to POC line stage table start. ',null,sysdate);
--Begin loop to insert the records in line table
        FORALL i IN 1..p_poc_line_t.count
            INSERT INTO wsc_ahcs_poc_txn_line_t (
                line_id,
                default_amount,
                acc_amt,
                default_currency,
                acc_currency,
                leg_seg1,
                leg_seg2,
                leg_seg3,
                leg_seg4,
                leg_seg5,
                leg_seg6,
                leg_seg7,
                dr_cr_flag,
                je_line_nbr,
                je_line_desc,
                fx_rate,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                target_coa,
                batch_id,
                transaction_number,
                leg_coa,
                gl_legal_entity,
                gl_acct,
                gl_oper_grp,
                gl_dept,
                gl_site,
                gl_ic,
                gl_projects,
                gl_fut_1,
                gl_fut_2,
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
                je_header_id
            ) VALUES (
                wsc_poc_line_s1.NEXTVAL,
                abs(p_poc_line_t(i).default_amount),
                abs(p_poc_line_t(i).acc_amt),
                p_poc_line_t(i).default_currency,
                p_poc_line_t(i).acc_currency,
                p_poc_line_t(i).leg_seg1,
                p_poc_line_t(i).leg_seg2,
                p_poc_line_t(i).leg_seg3,
                p_poc_line_t(i).leg_seg4,
                p_poc_line_t(i).leg_seg5,
                p_poc_line_t(i).leg_seg6,
                p_poc_line_t(i).leg_seg7,
                p_poc_line_t(i).dr_cr_flag,
                p_poc_line_t(i).je_line_nbr,
                p_poc_line_t(i).je_line_desc,
                p_poc_line_t(i).fx_rate,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate,
                p_poc_line_t(i).target_coa,
                p_batch_id,
                p_poc_line_t(i).transaction_number,
                p_poc_line_t(i).leg_seg1
                || '.'
                || p_poc_line_t(i).leg_seg2
                || '.'
                || p_poc_line_t(i).leg_seg3
                || '.'
                || p_poc_line_t(i).leg_seg4
                || '.'
                || p_poc_line_t(i).leg_seg5
                || '.'
                || p_poc_line_t(i).leg_seg6
                || '.'
                || p_poc_line_t(i).leg_seg7,
                p_poc_line_t(i).gl_legal_entity,
                p_poc_line_t(i).gl_acct,
                p_poc_line_t(i).gl_oper_grp,
                p_poc_line_t(i).gl_dept,
                p_poc_line_t(i).gl_site,
                p_poc_line_t(i).gl_ic,
                p_poc_line_t(i).gl_projects,
                p_poc_line_t(i).gl_fut_1,
                p_poc_line_t(i).gl_fut_2,
                p_poc_line_t(i).attribute1,
                p_poc_line_t(i).attribute2,
                p_poc_line_t(i).leg_seg1
                || '.'
                || p_poc_line_t(i).leg_seg2
                || '.'
                || p_poc_line_t(i).leg_seg3
                || '.'
                || p_poc_line_t(i).leg_seg4,
                p_poc_line_t(i).leg_seg5
                || '.'
                || p_poc_line_t(i).leg_seg6
                || '.'
                || p_poc_line_t(i).leg_seg7, 
                p_poc_line_t(i).attribute5,
                p_poc_line_t(i).attribute6,
                p_poc_line_t(i).attribute7,
                p_poc_line_t(i).attribute8,
                p_poc_line_t(i).attribute9,
                p_poc_line_t(i).attribute10,
                to_date(p_poc_line_t(i).attribute11, 'yyyy-mm-dd'),
                to_date(p_poc_line_t(i).attribute12, 'yyyy-mm-dd'),
                p_poc_line_t(i).je_header_id
            );
        COMMIT;
        x_status := 'SUCCESS';
--logging_insert ('ERP POC',p_batch_id,5,'Insertion to POC line stage table completed. ',null,sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('Error While inserting the data into header'
                                 || sqlerrm
                                 || $$plsql_unit
                                 || 'Line'
                                 || $$plsql_line);
--logging_insert (null,p_batch_id,106,'Exception while inserting POC line stage table ',sqlerrm,sysdate);
            x_status := sqlerrm(sqlcode)
                        || $$plsql_unit
                        || 'Line'
                        || $$plsql_line;
    END import_line_data_to_stg;

    PROCEDURE wsc_insert_poc_data_in_gl_status (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    ) IS

        lv_count              NUMBER;
--        CURSOR cur_update_line_table (
--            cur_p_batch_id NUMBER
--        ) IS
--        SELECT
--            header.header_id,
--            header.je_header_id,
--            header.leg_led_name
--        FROM
--            wsc_ahcs_poc_txn_header_t header
--        WHERE
--            header.batch_id = cur_p_batch_id
--            and header.je_header_id is not null;
--
--        TYPE update_line_header_type IS
--            TABLE OF cur_update_line_table%rowtype;
--        lv_update_line_header update_line_header_type;
    BEGIN
logging_insert ('ERP POC',p_batch_id,9,'Inside the procedure to update header id to POC line table start. ',null,sysdate);
--        OPEN cur_update_line_table(p_batch_id);
--        LOOP
--            FETCH cur_update_line_table
--            BULK COLLECT INTO lv_update_line_header LIMIT 400;
--            EXIT WHEN lv_update_line_header.count = 0;
--            FORALL i IN 1..lv_update_line_header.count
--                UPDATE wsc_ahcs_poc_txn_line_t
--                SET
--                    header_id = lv_update_line_header(i).header_id,leg_coa=leg_coa||'.'||lv_update_line_header(i).leg_led_name
--                WHERE
--                        batch_id = p_batch_id
--                    AND je_header_id = lv_update_line_header(i).je_header_id
--                    and je_header_id is not null;
--
--        END LOOP;       
          update wsc_ahcs_poc_txn_line_t line
        set (header_id,leg_coa) = (select /*+ index(hdr WSC_AHCS_POC_TXN_HEADER_JE_HEADER_ID_I) */ hdr.header_id,leg_coa || '.'||leg_led_name from wsc_ahcs_poc_txn_header_t hdr
        where line.je_header_id = hdr.je_header_id
        and line.batch_id = hdr.batch_id)
        where batch_id = P_BATCH_ID;
--   merge into wsc_ahcs_poc_txn_line_t line
--        using (select hdr.JE_HEADER_ID,hdr.batch_id,hdr.header_id,leg_led_name from wsc_ahcs_poc_txn_header_t hdr
--        where hdr.batch_id = p_batch_id
--        ) h
--        on (line.JE_HEADER_ID = h.JE_HEADER_ID
--        and line.batch_id = h.batch_id
--        and line.batch_id = p_batch_id
--        )
--        when matched then
--          update set line.header_id = h.header_id,leg_coa=leg_coa || '.'||leg_led_name;
        COMMIT;
logging_insert ('ERP POC',p_batch_id,10,'After updating header id to POC line table and before status table insertion. ',null,sysdate);
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
            created_by,
            created_date,
            last_updated_by,
            last_updated_date
        )
            SELECT
                l.header_id,
                l.line_id,
                p_application_name,
                p_file_name,
                p_batch_id,
                'NEW',
                l.dr_cr_flag,
                l.acc_currency,
                l.acc_amt,
                l.leg_coa,
                l.je_header_id,
                l.je_line_nbr,
                h.transaction_number,
                h.gl_date,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
               wsc_ahcs_poc_txn_header_t h,wsc_ahcs_poc_txn_line_t l
            WHERE
                l.batch_id = p_batch_id
                AND h.header_id (+)= l.header_id
                AND h.batch_id (+)= l.batch_id;

        COMMIT;
logging_insert ('ERP POC',p_batch_id,11,'After completing the POC header id and status table insertion. ',null,sysdate);
    EXCEPTION
        WHEN OTHERS THEN
        logging_insert ('ERP POC',p_batch_id,12,'Exception in the procedure for POC header id and status table insertion ',sqlerrm,sysdate);
        WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(p_batch_id,
                        'INT122 ',
                        'EBS_POC',
                        SQLERRM); 
            dbms_output.put_line(sqlerrm);
    END wsc_insert_poc_data_in_gl_status;

    PROCEDURE wsc_async_process_update_validate_transform_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    ) AS
        err_msg VARCHAR2(2000);
    BEGIN
   logging_insert ('ERP POC',p_batch_id,6,'Inside the procedure POC async wrapper begin ',null,sysdate); 
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;
            commit;
logging_insert ('ERP POC',p_batch_id,7,'Inside POC wrapper procedure after updating control status to ASYNC DATA PROCESS ',null,sysdate);
        dbms_scheduler.create_job(job_name => 'INVOKE_WSC_POC_INSERT_DATA_IN_GL_STATUS_P' || p_batch_id, job_type => 'PLSQL_BLOCK', job_action =>
        'BEGIN
         WSC_POC_PKG.wsc_insert_poc_data_in_gl_status('
                                                                                                                                  || p_batch_id
                                                                                                                                  || ','''
                                                                                                                                  || p_application_name
                                                                                                                                  || ''','''
                                                                                                                                  || p_file_name
                                                                                                                                  || ''');
         WSC_AHCS_POC_VALIDATION_TRANSFORMATION_PKG.data_validation('
                                                                                                                                  || p_batch_id
                                                                                                                                  || ');
       END;', enabled => true, auto_drop => true,
                                 comments => 'Non-critical post-booking steps');
    --dbms_scheduler.run_job (job_name => 'INVOKE_WSC_AP_INSERT_DATA_IN_GL_STATUS_P');
logging_insert ('ERP POC',p_batch_id,8,'Inside POC wrapper procedure after running async job for validation pkg. ',null,sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;
                commit;
logging_insert (null,p_batch_id,114,'Exception inside the POC wrapper procedure. check the control and log table for details. ',sqlerrm,sysdate);
            dbms_output.put_line(sqlerrm);
    END;

END wsc_poc_pkg;
/