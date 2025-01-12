create or replace PACKAGE BODY          "WSC_FA_PKG" AS

    PROCEDURE wsc_ahcs_fa_txn_header_p (
        in_wsc_ahcs_fa_txn_header IN wsc_fa_header_t_type_table
    ) AS
        err_msg VARCHAR2(2000);
    BEGIN
	--logging_insert (null,null,101,'Insertion in FA Header Table starts',null,sysdate);
        FORALL i IN 1..in_wsc_ahcs_fa_txn_header.count
  --LOOP
            INSERT INTO wsc_ahcs_fa_txn_header_t (
                transaction_date,
                transaction_number,
                ledger_name,
                source_trn_nbr,
                source_system,
                leg_ae_header_id,
                event_type,
                event_class,
                acc_date,
                asset_book,
                asset_cat,
                asset_desc,
                header_desc,
                led_leg_name,
                je_name,
                je_category,
                trn_amount,
                file_name,
                transaction_type,
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
                je_batch_name,
                header_id,
                batch_id
            ) VALUES (
                to_date(in_wsc_ahcs_fa_txn_header(i).acc_date, 'yyyy-mm-dd'),
                to_char('EBSFA' || in_wsc_ahcs_fa_txn_header(i).leg_ae_header_id),
                in_wsc_ahcs_fa_txn_header(i).ledger_name,
                in_wsc_ahcs_fa_txn_header(i).source_trn_nbr,
                in_wsc_ahcs_fa_txn_header(i).source_system,
                in_wsc_ahcs_fa_txn_header(i).leg_ae_header_id,
                in_wsc_ahcs_fa_txn_header(i).event_type,
                in_wsc_ahcs_fa_txn_header(i).event_class,
                to_date(in_wsc_ahcs_fa_txn_header(i).acc_date, 'yyyy-mm-dd'),
                in_wsc_ahcs_fa_txn_header(i).asset_book,
                in_wsc_ahcs_fa_txn_header(i).asset_cat,
                in_wsc_ahcs_fa_txn_header(i).asset_desc,
                in_wsc_ahcs_fa_txn_header(i).header_desc,
                in_wsc_ahcs_fa_txn_header(i).led_leg_name,
                in_wsc_ahcs_fa_txn_header(i).je_name,
                in_wsc_ahcs_fa_txn_header(i).je_category,
                in_wsc_ahcs_fa_txn_header(i).trn_amount,
                in_wsc_ahcs_fa_txn_header(i).file_name,
                in_wsc_ahcs_fa_txn_header(i).transaction_type,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate,
                in_wsc_ahcs_fa_txn_header(i).attribute1,
                in_wsc_ahcs_fa_txn_header(i).attribute2,
                in_wsc_ahcs_fa_txn_header(i).attribute3,
                in_wsc_ahcs_fa_txn_header(i).attribute4,
                in_wsc_ahcs_fa_txn_header(i).attribute5,
                in_wsc_ahcs_fa_txn_header(i).attribute6,
                in_wsc_ahcs_fa_txn_header(i).attribute7,
                in_wsc_ahcs_fa_txn_header(i).attribute8,
                in_wsc_ahcs_fa_txn_header(i).attribute9,
                in_wsc_ahcs_fa_txn_header(i).attribute10,
                in_wsc_ahcs_fa_txn_header(i).je_batch_name,
                wsc_fa_header_id_s1.NEXTVAL,
                in_wsc_ahcs_fa_txn_header(i).batch_id
            );

--        logging_insert(NULL, NULL, 102, 'Insertion in FA Header Table ends', NULL,  sysdate);
--END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('EBS FA', NULL, 112, 'Error while Inserting in FA Header Table Proc', sqlerrm,sysdate);
    END wsc_ahcs_fa_txn_header_p;

    PROCEDURE wsc_ahcs_fa_txn_line_p (
        in_wsc_ahcs_fa_txn_line IN wsc_fa_line_t_type_table
    ) AS
        err_msg VARCHAR2(2000);
    BEGIN
--        logging_insert(NULL, NULL, 103, 'Insertion in FA Line Table starts', NULL,sysdate);
        FORALL i IN 1..in_wsc_ahcs_fa_txn_line.count
  --LOOP
            INSERT INTO wsc_ahcs_fa_txn_line_t (
                transaction_number,
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
                je_line_nbr,
                line_desc,
                transaction_type,
                acc_currency,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                line_id,
                batch_id,
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
                target_coa,
                leg_ae_header_id,
                leg_ae_line_nbr,
                source_trn_nbr
            ) VALUES (
                to_char('EBSFA' || in_wsc_ahcs_fa_txn_line(i).leg_ae_header_id),
                in_wsc_ahcs_fa_txn_line(i).default_amount,
                in_wsc_ahcs_fa_txn_line(i).default_currency,
                in_wsc_ahcs_fa_txn_line(i).leg_seg1
                || '.'
                || in_wsc_ahcs_fa_txn_line(i).leg_seg2
                || '.'
                || in_wsc_ahcs_fa_txn_line(i).leg_seg3
                || '.'
                || in_wsc_ahcs_fa_txn_line(i).leg_seg4
                || '.'
                || in_wsc_ahcs_fa_txn_line(i).leg_seg5
                || '.'
                || in_wsc_ahcs_fa_txn_line(i).leg_seg6
                || '.'
                || in_wsc_ahcs_fa_txn_line(i).leg_seg7,
                in_wsc_ahcs_fa_txn_line(i).leg_seg1,
                in_wsc_ahcs_fa_txn_line(i).leg_seg2,
                in_wsc_ahcs_fa_txn_line(i).leg_seg3,
                in_wsc_ahcs_fa_txn_line(i).leg_seg4,
                in_wsc_ahcs_fa_txn_line(i).leg_seg5,
                in_wsc_ahcs_fa_txn_line(i).leg_seg6,
                in_wsc_ahcs_fa_txn_line(i).leg_seg7,
                in_wsc_ahcs_fa_txn_line(i).gl_legal_entity,
                in_wsc_ahcs_fa_txn_line(i).gl_acct,
                in_wsc_ahcs_fa_txn_line(i).gl_oper_grp,
                in_wsc_ahcs_fa_txn_line(i).gl_dept,
                in_wsc_ahcs_fa_txn_line(i).gl_site,
                in_wsc_ahcs_fa_txn_line(i).gl_ic,
                in_wsc_ahcs_fa_txn_line(i).gl_projects,
                in_wsc_ahcs_fa_txn_line(i).gl_fut_1,
                in_wsc_ahcs_fa_txn_line(i).gl_fut_2,
                in_wsc_ahcs_fa_txn_line(i).acc_class,
                in_wsc_ahcs_fa_txn_line(i).acc_amt,
                in_wsc_ahcs_fa_txn_line(i).dr_cr_flag,
                in_wsc_ahcs_fa_txn_line(i).je_line_nbr,
                in_wsc_ahcs_fa_txn_line(i).line_desc,
                in_wsc_ahcs_fa_txn_line(i).transaction_type,
                in_wsc_ahcs_fa_txn_line(i).acc_currency,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate,
                wsc_fa_line_id_s1.NEXTVAL,
                in_wsc_ahcs_fa_txn_line(i).batch_id,
                in_wsc_ahcs_fa_txn_line(i).attribute1,
                in_wsc_ahcs_fa_txn_line(i).attribute2,
                in_wsc_ahcs_fa_txn_line(i).leg_seg1
                || '.'
                || in_wsc_ahcs_fa_txn_line(i).leg_seg2
                || '.'
                || in_wsc_ahcs_fa_txn_line(i).leg_seg3
                || '.'
                || in_wsc_ahcs_fa_txn_line(i).leg_seg4,
                in_wsc_ahcs_fa_txn_line(i).leg_seg5
                || '.'
                || in_wsc_ahcs_fa_txn_line(i).leg_seg6
                || '.'
                || in_wsc_ahcs_fa_txn_line(i).leg_seg7,
                in_wsc_ahcs_fa_txn_line(i).attribute5,
                in_wsc_ahcs_fa_txn_line(i).attribute6,
                in_wsc_ahcs_fa_txn_line(i).attribute7,
                in_wsc_ahcs_fa_txn_line(i).attribute8,
                in_wsc_ahcs_fa_txn_line(i).attribute9,
                in_wsc_ahcs_fa_txn_line(i).attribute10,
                to_date(in_wsc_ahcs_fa_txn_line(i).attribute11, 'yyyy-mm-dd'),
                to_date(in_wsc_ahcs_fa_txn_line(i).attribute12, 'yyyy-mm-dd'),
                in_wsc_ahcs_fa_txn_line(i).target_coa,
                in_wsc_ahcs_fa_txn_line(i).leg_ae_header_id,
                in_wsc_ahcs_fa_txn_line(i).leg_ae_line_nbr,
                in_wsc_ahcs_fa_txn_line(i).source_trn_nbr
            );

   ---     logging_insert(NULL, NULL, 104, 'Insertion in FA Line Table ends', NULL,sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('EBS FA', NULL, 111, 'Error while Inserting in FA Line Table Procedure', sqlerrm,sysdate);
    END wsc_ahcs_fa_txn_line_p;

    PROCEDURE wsc_insert_data_in_gl_status_p (
        p_batch_id          NUMBER,
        p_application_name  VARCHAR2,
        p_file_name         VARCHAR2
    ) IS

        lv_count               NUMBER;
        err_msg                VARCHAR2(2000);
        lv_batch_id   NUMBER := p_batch_id; 
        CURSOR cur_update_line_table (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            header.header_id,
            header.leg_ae_header_id,
            header.led_leg_name
        FROM
            wsc_ahcs_fa_txn_header_t header
        WHERE
                header.batch_id = cur_p_batch_id
            AND header.leg_ae_header_id IS NOT NULL;

        TYPE update_line_header_type IS
            TABLE OF cur_update_line_table%rowtype;
        lv_update_line_header  update_line_header_type;
    BEGIN
        logging_insert('EBS FA', p_batch_id, 1, 'Update FA Line Table with Header ID - Starts ', NULL,sysdate);
     /*   OPEN cur_update_line_table(p_batch_id);
        LOOP
            FETCH cur_update_line_table BULK COLLECT INTO lv_update_line_header LIMIT 400;
            EXIT WHEN lv_update_line_header.count = 0;
            FORALL i IN 1..lv_update_line_header.count
                UPDATE wsc_ahcs_fa_txn_line_t
                SET
                    header_id = lv_update_line_header(i).header_id,
                    leg_coa = leg_coa
                              || '.'
                              || lv_update_line_header(i).led_leg_name
                WHERE
                        batch_id = p_batch_id
                    AND leg_ae_header_id = lv_update_line_header(i).leg_ae_header_id
                    AND leg_ae_header_id IS NOT NULL;

        END LOOP;*/

          /*   UPDATE (select hdr.header_id hdr_id,line.header_id ,hdr.led_leg_name,line.leg_coa
                        from wsc_ahcs_fa_txn_line_t line,wsc_ahcs_fa_txn_header_t hdr
                      where line.leg_ae_header_id = hdr.leg_ae_header_id
                        and line.batch_id = hdr.batch_id
                        and line.batch_id = p_batch_id
                        )
                SET
                    header_id = hdr_id,
                    leg_coa = leg_coa
                              || '.'
                              || led_leg_name;*/
           /* update  wsc_ahcs_fa_txn_line_t line
            set header_id = (select hdr.header_id hdr from wsc_ahcs_fa_txn_header_t hdr
                                where line.leg_ae_header_id = hdr.leg_ae_header_id
                                    and line.batch_id = hdr.batch_id),
                leg_coa = leg_coa || '.'|| (select led_leg_name from wsc_ahcs_fa_txn_header_t hdr
                                where line.leg_ae_header_id = hdr.leg_ae_header_id
                                    and line.batch_id = hdr.batch_id)                    
            where batch_id = p_batch_id*/
            /*and exists 
            (select 1 from wsc_ahcs_fa_txn_header_t hdr
                                where line.leg_ae_header_id = hdr.leg_ae_header_id
                                    and line.batch_id = hdr.batch_id); */  
        update wsc_ahcs_fa_txn_line_t line
        set (header_id,leg_coa) = (select /*+ index(hdr WSC_AHCS_FA_TXN_HEADER_LEG_AE_HEADER_ID_I) */ hdr.header_id,leg_coa || '.'||led_leg_name from wsc_ahcs_fa_txn_header_t hdr
        where line.leg_ae_header_id = hdr.leg_ae_header_id
        and line.batch_id = hdr.batch_id)
        where batch_id = P_BATCH_ID;

        COMMIT;
        logging_insert('EBS FA', p_batch_id, 2, 'Update FA Line Table with Header ID - Ends', NULL,sysdate);
        logging_insert('EBS FA', p_batch_id, 3, 'Insert records in Status Table - Starts', NULL,sysdate);

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
                wsc_ahcs_fa_txn_line_t    line,
                wsc_ahcs_fa_txn_header_t  hdr
            WHERE
                    line.batch_id = lv_batch_id
                AND hdr.header_id(+) = line.header_id
                AND hdr.batch_id(+) = line.batch_id;

        COMMIT;
        logging_insert('EBS FA', p_batch_id, 4, 'Insert records in Status Table - Ends', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('EBS FA', p_batch_id, 113,
                          'Error While updating Line table with Header ID/Inserting data in Status Table',
                          sqlerrm,
                          sysdate);
                          
            WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(p_batch_id,
                        'INT004',
                        'EBS_FA',
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
        logging_insert('EBS FA', p_batch_id, 109, 'Starts ASYNC DB Scheduler', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        dbms_scheduler.create_job(job_name => 'INVOKE_WSC_FA_INSERT_DATA_IN_GL_STATUS_P_' || p_batch_id,
                                 job_type => 'PLSQL_BLOCK',
                                 job_action => 'BEGIN
         WSC_FA_PKG.WSC_INSERT_DATA_IN_GL_STATUS_P('
                                               || p_batch_id
                                               || ','''
                                               || p_application_name
                                               || ''','''
                                               || p_file_name
                                               || ''');
         WSC_AHCS_FA_VALIDATION_TRANSFORMATION_PKG.data_validation('
                                               || p_batch_id
                                               || ');
       END;',
                                 enabled => true,
                                 auto_drop => true,
                                 comments => 'Async steps to update, Insert into WSC_AHCS_INT_STATUS_T and call Validate and Transform procedure');

    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('EBS FA', p_batch_id, 110, 'Error in Async DB Procedure', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            dbms_output.put_line(sqlerrm);
            COMMIT;
    END;

END wsc_fa_pkg;
/