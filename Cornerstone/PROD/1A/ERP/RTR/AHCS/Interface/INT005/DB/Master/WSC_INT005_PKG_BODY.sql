create or replace PACKAGE BODY "WSC_AR_PKG" AS

    PROCEDURE "WSC_AR_HEADER_P" (
        in_wsc_ar_header IN wsc_ar_header_t_type_table
    ) AS
    BEGIN
        FORALL i IN 1..in_wsc_ar_header.count
            INSERT INTO wsc_ahcs_ar_txn_header_t (
                header_id,
                batch_id,
                transaction_date,
                transaction_number,
                ledger_name,
                source_trn_nbr,
                source_system,
                trn_amount,
                leg_ae_header_id,
                trd_partner_name,
                trd_partner_nbr,
                event_type,
                event_class,
                acc_date,
                header_desc,
                leg_led_name,
                je_batch_name,
                je_name,
                je_category,
                file_name,
                transaction_type,
                leg_trns_type,
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
                wsc_ar_header_s1.NEXTVAL,
                in_wsc_ar_header(i).batch_id,
                to_char(to_date(in_wsc_ar_header(i).acc_date, 'yyyy-mm-dd'), 'yyyy-mm-dd'),
                'EBSAR' || in_wsc_ar_header(i).leg_ae_header_id,
                in_wsc_ar_header(i).ledger_name,
                in_wsc_ar_header(i).source_trn_nbr,
                in_wsc_ar_header(i).source_system,
                in_wsc_ar_header(i).trn_amount,
                in_wsc_ar_header(i).leg_ae_header_id,
                in_wsc_ar_header(i).trd_partner_name,
                in_wsc_ar_header(i).trd_partner_nbr,
                in_wsc_ar_header(i).event_type,
                in_wsc_ar_header(i).event_class,
                to_date(in_wsc_ar_header(i).acc_date, 'yyyy-mm-dd'),
                in_wsc_ar_header(i).header_desc,
                in_wsc_ar_header(i).leg_led_name,
                in_wsc_ar_header(i).je_batch_name,
                in_wsc_ar_header(i).je_name,
                in_wsc_ar_header(i).je_category,
                in_wsc_ar_header(i).file_name,
                in_wsc_ar_header(i).transaction_type,
                in_wsc_ar_header(i).leg_trns_type,
                in_wsc_ar_header(i).attribute1,
                in_wsc_ar_header(i).attribute2,
                in_wsc_ar_header(i).attribute3,
                in_wsc_ar_header(i).attribute4,
                in_wsc_ar_header(i).attribute5,
                in_wsc_ar_header(i).attribute6,
                in_wsc_ar_header(i).attribute7,
                in_wsc_ar_header(i).attribute8,
                in_wsc_ar_header(i).attribute9,
                in_wsc_ar_header(i).attribute10,
                to_date(in_wsc_ar_header(i).attribute11, 'yyyy-mm-dd'),
                to_date(in_wsc_ar_header(i).attribute12, 'yyyy-mm-dd'),
                sysdate,
                in_wsc_ar_header(i).created_by,
                sysdate,
                in_wsc_ar_header(i).last_updated_by
            );

    END "WSC_AR_HEADER_P";

    PROCEDURE "WSC_AR_LINE_P" (
        in_wsc_ar_line IN wsc_ar_line_t_type_table
    ) AS
    BEGIN
        FORALL i IN 1..in_wsc_ar_line.count
            INSERT INTO wsc_ahcs_ar_txn_line_t (
                line_id,
                batch_id,
                transaction_number,
                source_trn_nbr,
                default_amount,
                default_currency,
                leg_coa,
                leg_seg1,
                leg_seg2,
                leg_seg3,
                leg_seg4,
                leg_seg5,
                leg_seg6,
                leg_seg7,
                gl_legal_entity,
                gl_acct,
                gl_oper_grp,
                gl_dept,
                gl_site,
                gl_ic,
                gl_projects,
                gl_fut_1,
                gl_fut_2,
                acc_class,
                acc_amt,
                dr_cr_flag,
                leg_ae_line_nbr,
                je_line_nbr,
                line_desc,
                line_type,
                acc_currency,
                leg_ae_header_id,
                fx_rate,
                transaction_type,
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
                wsc_ar_line_s1.NEXTVAL,
                in_wsc_ar_line(i).batch_id,
                'EBSAR' || in_wsc_ar_line(i).leg_ae_header_id,
                in_wsc_ar_line(i).source_trn_nbr,
                in_wsc_ar_line(i).default_amount,
                in_wsc_ar_line(i).default_currency,
                in_wsc_ar_line(i).leg_seg1
                || '.'
                || in_wsc_ar_line(i).leg_seg2
                || '.'
                || in_wsc_ar_line(i).leg_seg3
                || '.'
                || in_wsc_ar_line(i).leg_seg4
                || '.'
                || in_wsc_ar_line(i).leg_seg5
                || '.'
                || in_wsc_ar_line(i).leg_seg6
                || '.'
                || in_wsc_ar_line(i).leg_seg7,
                in_wsc_ar_line(i).leg_seg1,
                in_wsc_ar_line(i).leg_seg2,
                in_wsc_ar_line(i).leg_seg3,
                in_wsc_ar_line(i).leg_seg4,
                in_wsc_ar_line(i).leg_seg5,
                in_wsc_ar_line(i).leg_seg6,
                in_wsc_ar_line(i).leg_seg7,
                in_wsc_ar_line(i).gl_legal_entity,
                in_wsc_ar_line(i).gl_acct,
                in_wsc_ar_line(i).gl_oper_grp,
                in_wsc_ar_line(i).gl_dept,
                in_wsc_ar_line(i).gl_site,
                in_wsc_ar_line(i).gl_ic,
                in_wsc_ar_line(i).gl_projects,
                in_wsc_ar_line(i).gl_fut_1,
                in_wsc_ar_line(i).gl_fut_2,
                in_wsc_ar_line(i).acc_class,
                in_wsc_ar_line(i).acc_amt,
                in_wsc_ar_line(i).dr_cr_flag,
                in_wsc_ar_line(i).leg_ae_line_nbr,
                in_wsc_ar_line(i).je_line_nbr,
                in_wsc_ar_line(i).line_desc,
                in_wsc_ar_line(i).line_type,
                in_wsc_ar_line(i).acc_currency,
                in_wsc_ar_line(i).leg_ae_header_id,
                in_wsc_ar_line(i).fx_rate,
                in_wsc_ar_line(i).transaction_type,
                in_wsc_ar_line(i).attribute1,
                in_wsc_ar_line(i).attribute2,
                in_wsc_ar_line(i).leg_seg1
                || '.'
                || in_wsc_ar_line(i).leg_seg2
                || '.'
                || in_wsc_ar_line(i).leg_seg3
                || '.'
                || in_wsc_ar_line(i).leg_seg4,
                in_wsc_ar_line(i).leg_seg5
                || '.'
                || in_wsc_ar_line(i).leg_seg6
                || '.'
                || in_wsc_ar_line(i).leg_seg7,
                in_wsc_ar_line(i).attribute5,
                in_wsc_ar_line(i).attribute6,
                in_wsc_ar_line(i).attribute7,
                in_wsc_ar_line(i).attribute8,
                in_wsc_ar_line(i).attribute9,
                in_wsc_ar_line(i).attribute10,
                to_date(in_wsc_ar_line(i).attribute11, 'yyyy-mm-dd'),
                to_date(in_wsc_ar_line(i).attribute12, 'yyyy-mm-dd'),
                sysdate,
                in_wsc_ar_line(i).created_by,
                sysdate,
                in_wsc_ar_line(i).last_updated_by
            );

    END "WSC_AR_LINE_P";

    PROCEDURE wsc_insert_data_in_gl_status_p (
        p_batch_id          NUMBER,
        p_application_name  VARCHAR2,
        p_file_name         VARCHAR2
    ) IS
        lv_count  NUMBER;
        err_msg   VARCHAR2(2000);

 /*cursor cur_update_line_table(cur_p_batch_id NUMBER) IS
 SELECT header.HEADER_ID , header.LEG_AE_HEADER_ID, header.LEG_LED_NAME
   FROM WSC_AHCS_AR_TXN_HEADER_T header
  WHERE header.batch_id = cur_p_batch_id and header.LEG_AE_HEADER_ID IS NOT NULL;

 type update_line_header_type is table of cur_update_line_table%rowtype;
 lv_update_line_header update_line_header_type; */
 lv_batch_id   NUMBER := p_batch_id; 
    BEGIN
        logging_insert('EBS AR', p_batch_id, 2, 'Updating AR Line table with header id starts', NULL,
                      sysdate);
           /* open cur_update_line_table(p_batch_id);
            loop 
            fetch cur_update_line_table bulk collect into lv_update_line_header limit 400;
            EXIT WHEN lv_update_line_header.COUNT = 0;        
            forall i in 1..lv_update_line_header.count
				update WSC_AHCS_AR_TXN_LINE_T
				set header_id = lv_update_line_header(i).header_id, leg_coa=leg_coa||'.'||lv_update_line_header(i).leg_led_name
                where BATCH_ID = P_BATCH_ID and leg_ae_header_id = lv_update_line_header(i).leg_ae_header_id and LEG_AE_HEADER_ID IS NOT NULL;
            end loop; */
          /*  update wsc_ahcs_ar_txn_line_t line
        set (header_id,leg_coa) = (select hdr.header_id,leg_coa || '.'||leg_led_name from wsc_ahcs_ar_txn_header_t hdr
        where line.LEG_AE_HEADER_ID = hdr.LEG_AE_HEADER_ID
        and line.batch_id = hdr.batch_id)
        where batch_id = P_BATCH_ID; 
        */

    /*    merge into wsc_ahcs_ar_txn_line_t line
        using (select hdr.LEG_AE_HEADER_ID,hdr.batch_id,hdr.header_id,leg_led_name from wsc_ahcs_ar_txn_header_t hdr
        where hdr.batch_id = P_BATCH_ID
        ) h
        on (line.LEG_AE_HEADER_ID = h.LEG_AE_HEADER_ID
        and line.batch_id = h.batch_id
        and line.batch_id = P_BATCH_ID
        )
        when matched then
          update set line.header_id = h.header_id, leg_coa = leg_coa || '.'||leg_led_name ;

            commit; */
        UPDATE wsc_ahcs_ar_txn_line_t line
        SET
            ( header_id,
              leg_coa ) = (
                SELECT /*+ index(hdr WSC_AHCS_AR_TXN_HEADER_LEG_AE_HEADER_ID_I) */ hdr.header_id,
                    leg_coa
                    || '.'
                    || leg_led_name
                FROM
                    wsc_ahcs_ar_txn_header_t hdr
                WHERE
                        line.leg_ae_header_id = hdr.leg_ae_header_id
                    AND line.batch_id = hdr.batch_id
            )
        --and rownum =1)
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        logging_insert('EBS AR', p_batch_id, 3, 'Updating AR Line table with header id ends', NULL,
                      sysdate);
        logging_insert('EBS AR', p_batch_id, 4, 'Inserting records in status table starts', NULL,
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
                line.acc_currency,
                line.acc_amt,
                line.leg_coa,
                line.leg_ae_header_id,
                line.leg_ae_line_nbr,
                hdr.transaction_number,
                hdr.acc_date,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
                wsc_ahcs_ar_txn_line_t    line,
                wsc_ahcs_ar_txn_header_t  hdr
            WHERE
                    line.batch_id = lv_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id;

        COMMIT;
        logging_insert('EBS AR', p_batch_id, 5, 'Inserting records in status table ends', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('EBS AR', p_batch_id, 101,
                          'Error While updating Line table with Header ID/inserting data in status table',
                          sqlerrm,
                          sysdate);

            WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(p_batch_id,
                        'INT005',
                        'EBS_AR',
                        SQLERRM);
            dbms_output.put_line(sqlerrm);
    END;

    PROCEDURE wsc_async_process_update_validate_transform_p (
        p_batch_id          NUMBER,
        p_application_name  VARCHAR2,
        p_file_name         VARCHAR2
    ) AS
        err_msg VARCHAR2(2000);
    BEGIN
        logging_insert('EBS AR', p_batch_id, 1, 'Starts ASYNC DB Scheduler', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        dbms_scheduler.create_job(job_name => 'INVOKE_WSC_AR_INSERT_DATA_IN_GL_STATUS_P' || p_batch_id,
                                 job_type => 'PLSQL_BLOCK',
                                 job_action => 'BEGIN
         WSC_AR_PKG.WSC_INSERT_DATA_IN_GL_STATUS_P('
                                               || p_batch_id
                                               || ','''
                                               || p_application_name
                                               || ''','''
                                               || p_file_name
                                               || ''');
         WSC_AHCS_AR_VALIDATION_TRANSFORMATION_PKG.data_validation('
                                               || p_batch_id
                                               || ');
       END;',
                                 enabled => true,
                                 auto_drop => true,
                                 comments => 'Async steps to update, insert into WSC_AHCS_INT_STATUS_T and call Validate and Transform procedure');

    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('EBS AR', p_batch_id, 102, 'Error in Async DB Proc', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            COMMIT;
            dbms_output.put_line(sqlerrm);
    END;

END wsc_ar_pkg;

/