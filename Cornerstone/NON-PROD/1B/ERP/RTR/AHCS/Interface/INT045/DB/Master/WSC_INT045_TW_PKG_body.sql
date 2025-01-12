create or replace PACKAGE BODY "WSC_TW_PKG" AS

    PROCEDURE "WSC_TW_INSERT_DATA_TEMP_P" (
        in_wsc_ahcs_tw_txn_tmp IN wsc_ahcs_tw_txn_tmp_t_type_table
    ) AS
    BEGIN
        FORALL i IN 1..in_wsc_ahcs_tw_txn_tmp.count
            INSERT INTO wsc_ahcs_tw_txn_tmp_t (
                batch_id,
                data_string,
                line_nbr
            ) VALUES (
                in_wsc_ahcs_tw_txn_tmp(i).batch_id,
                in_wsc_ahcs_tw_txn_tmp(i).data_string,
                wsc_tw_tmp_line_nbr_s1.NEXTVAL
            );

    END;

    PROCEDURE wsc_process_tw_temp_to_header_line_p (
        p_batch_id         NUMBER,
        p_application_name IN VARCHAR2,
        p_file_name        IN VARCHAR2
    ) AS

        v_error_msg         VARCHAR2(200);
        v_stage             VARCHAR2(200);
        lv_count            NUMBER;
        err_msg             VARCHAR2(2000);
        p_error_flag        VARCHAR2(2);
        l_system            VARCHAR2(200);
        CURSOR tw_stage_hdr_data_cur (
            p_batch_id NUMBER
        ) IS
        SELECT DISTINCT
            TRIM(substr(data_string, 16, 10)) transaction_date
        FROM
            wsc_ahcs_tw_txn_tmp_t tmp
        WHERE
                batch_id = p_batch_id
            AND data_string NOT LIKE '%CONTROL%';

        CURSOR tw_stage_line_data_cur (
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
            wsc_ahcs_tw_txn_tmp_t tmp
        WHERE
                batch_id = p_batch_id
            AND data_string NOT LIKE '%CONTROL%';

        TYPE tw_stage_line_type IS
            TABLE OF tw_stage_line_data_cur%rowtype;
        lv_tw_stg_line_type tw_stage_line_type;
        control_count       NUMBER;
        tmp_string          VARCHAR2(100);
        sqe                 VARCHAR2(200);
    BEGIN
        BEGIN
            p_error_flag := '0';
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('TW', p_batch_id, 1.1, 'value of error flag', sqlerrm,
                              sysdate);
        END;

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
            SELECT
                data_string
            INTO tmp_string
            FROM
                wsc_ahcs_tw_txn_tmp_t
            WHERE
                data_string LIKE '%CONTROL%'
                AND batch_id = p_batch_id;

            UPDATE wsc_ahcs_int_control_t
            SET
                total_records = to_number(substr(tmp_string, instr(tmp_string, ' ')))
            WHERE
                batch_id = p_batch_id;

        END;

        dbms_output.put_line(' Begin inserting records into header line table');
    /********** PROCESS STAGE TABLE DATA TO HEADER TABLE DATA - START *************/
        logging_insert('TW', p_batch_id, 2, 'INSERT DATA TO HEADER TABLE DATA - START', NULL,
                      sysdate);
        FOR wsc_tw_hdr IN tw_stage_hdr_data_cur(p_batch_id) LOOP
            INSERT INTO wsc_ahcs_tw_txn_header_t (
                batch_id,
                header_id,
                transaction_type,
                transaction_date,
                transaction_number,
                ledger_name,
                leg_bus_unit,
                file_name,
                source,
                trans_ref_nbr,
                creation_date,
                created_by,
                last_update_date,
                last_updated_by
            ) VALUES (
                p_batch_id,
                wsc_tw_header_t_s1.NEXTVAL,
                'TREASURY',
                to_date(wsc_tw_hdr.transaction_date, 'MM/DD/YYYY'), --TRANSACTION_DATE
                concat((replace(p_file_name, '_', '')
                        || '_'), to_char(to_date(wsc_tw_hdr.transaction_date, 'MM/DD/YYYY'), 'MMDD')), -- Transaction_number
                NULL --LEDGER_NAME
                ,
                NULL --LEG_BUS_UNIT
                ,
                p_file_name,
                'TMI' --SOURCE
                ,
                NULL --TRANS_REF_NBR
                ,
                sysdate --CREATION_DATE
                ,
                'FIN_INT' --CREATED_BY
                ,
                sysdate --LAST_UPDATE_DATE
                ,
                'FIN_INT' --LAST_UPDATED_BY
            );

        END LOOP;
--                FROM 
--                WSC_AHCS_TW_TXN_TMP_T temp
--                WHERE
--                temp.batch_id = p_batch_id
--                and rownum=1;
--                
        COMMIT;

   /* logging_insert('TW', p_batch_id, 2.3, 'value of error flag', p_error_flag,sysdate);
    CLOSE TW_stage_hdr_data_cur;
    EXCEPTION
        WHEN OTHERS THEN
            p_error_flag := '1';
             err_msg := substr(sqlerrm, 1, 200);
             wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT123'
                                                    || '_'
                                                    || l_system,
                                                    'TW',
                                                    sqlerrm); */

   -- END;
   -- logging_insert('TW', p_batch_id, 2.4, 'value of error flag at header level', p_error_flag, sysdate);
        dbms_output.put_line('HEADER exit');
        COMMIT;
        logging_insert('TW', p_batch_id, 3, 'INSERT DATA TO HEADER TABLE DATA - END', NULL,
                      sysdate);


 /********** PROCESS UNSTRUCTURED TEMP TABLE DATA TO LINE TABLE DATA - START *************/
        dbms_output.put_line('Insert Data into Line Table');
        logging_insert('TW', p_batch_id, 4, 'STAGE TABLE DATA TO LINE TABLE DATA - START', NULL,
                      sysdate);
        OPEN tw_stage_line_data_cur(p_batch_id);
        LOOP
            FETCH tw_stage_line_data_cur
            BULK COLLECT INTO lv_tw_stg_line_type LIMIT 400;
            EXIT WHEN lv_tw_stg_line_type.count = 0;
            BEGIN
                FORALL i IN 1..lv_tw_stg_line_type.count
                    INSERT INTO wsc_ahcs_tw_txn_line_t (
                        batch_id,
                        line_id,
           --             header_id,
                        business_unit,
                        appl_jrnl_id,
                        axe_trans_dt,
                        axe_line_nbr,
                        accounting_dt,
                        business_unit_gl,
                        ledger,
                        ledger_group,
                        account,
                        altacct,
                        axe_loc,
                        deptid,
                        product,
                        axe_mrkt_chnl,
                        axe_project,
                        project_id,
                        axe_vendor_10,
                        affiliate,
                        monetary_amount,
                        foreign_amount,
                        currency_cd,
                        foreign_currency,
                        gl_distrib_status,
                        trans_ref_nbr,
                        descr,
                        source,
                        filler,
                        transaction_number,
                        leg_bu,
                        leg_acct,
                        leg_dept,
                        leg_loc,
                        leg_vendor,
                        leg_affiliate,
                        gl_legal_entity,
                        gl_oper_grp,
                        gl_acct,
                        gl_dept,
                        gl_site,
                        gl_ic,
                        gl_projects,
                        gl_fut_1,
                        gl_fut_2,
                        leg_coa,
                        leg_seg_1_4,
                        leg_seg_5_7,
                        line_nbr,
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
                        p_batch_id,
                        wsc_tw_line_t_s1.NEXTVAL,
                  --      wsc_tw_header_t_s1.CURRVAL, --header_id
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 0, 5)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 6, 10)),
                        to_date(TRIM(substr(lv_tw_stg_line_type(i).data_string, 16, 10)), 'MM/DD/YYYY'),
                        to_number(TRIM(substr(lv_tw_stg_line_type(i).data_string, 26, 9))),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 35, 10)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 45, 5)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 50, 10)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 60, 10)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 70, 9)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 79, 9)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 88, 5)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 93, 4)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 97, 5)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 102, 2)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 104, 7)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 111, 15)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 126, 10)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 136, 5)),
                        to_number(TRIM(substr(lv_tw_stg_line_type(i).data_string, 141, 16))),
                        to_number(TRIM(substr(lv_tw_stg_line_type(i).data_string, 157, 16))),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 173, 3)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 176, 3)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 179, 1)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 180, 8)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 188, 30)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 218, 3)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 221)),
   --                     replace(p_file_name, '_', ''), --TRANSACTION_NUMBER
                        concat((replace(p_file_name, '_', '')
                                || '_'), to_char(to_date(TRIM(substr(lv_tw_stg_line_type(i).data_string, 16, 10)), 'MM/DD/YYYY'), 'MMDD')), -- Transaction_number
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 45, 5)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 70, 9)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 93, 4)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 88, 5)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 126, 10)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 136, 5)),
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 45, 5))
                        || '.'
                        || TRIM(substr(lv_tw_stg_line_type(i).data_string, 88, 5))
                        || '.'
                        || TRIM(substr(lv_tw_stg_line_type(i).data_string, 93, 4))
                        || '.'
                        || TRIM(substr(lv_tw_stg_line_type(i).data_string, 70, 9))
                        || '.'
                        || TRIM(substr(lv_tw_stg_line_type(i).data_string, 126, 10))
                        || '.'
                        || nvl(TRIM(substr(lv_tw_stg_line_type(i).data_string, 136, 5)), '00000'),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 45, 5))
                        || '.'
                        || TRIM(substr(lv_tw_stg_line_type(i).data_string, 88, 5))
                        || '.'
                        || TRIM(substr(lv_tw_stg_line_type(i).data_string, 70, 9))
                        || '.'
                        || TRIM(substr(lv_tw_stg_line_type(i).data_string, 93, 4)),
                        TRIM(substr(lv_tw_stg_line_type(i).data_string, 126, 10))
                        || '.'
                        || TRIM(substr(lv_tw_stg_line_type(i).data_string, 136, 5)),
                        lv_tw_stg_line_type(i).row_line_num,
                        sysdate,
                        'FIN_INT',
                        sysdate,
                        'FIN_INT',
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL
                    );

--/********** PROCESS UNSTRUCTURED STAGE TABLE DATA TO LINE TABLE DATA - END *************/
            EXCEPTION
                WHEN OTHERS THEN
                    sqe := substr(sqlerrm, 1, 200);
                    UPDATE wsc_ahcs_int_control_t
                    SET
                        attribute1 = sqe
                    WHERE
                        batch_id = p_batch_id;

                    logging_insert('TW', p_batch_id, 5.1, sqlerrm, NULL,
                                  sysdate);
            END;

        END LOOP;
-- /*logging_insert('TW', p_batch_id, 2.5, 'value of error flag', p_error_flag,
--      sysdate);
        CLOSE tw_stage_line_data_cur;
--        UPDATE wsc_ahcs_tw_txn_header_t
--        SET
--            transaction_date = (
--                SELECT DISTINCT
--                    ( axe_trans_dt )
--                FROM
--                    wsc_ahcs_tw_txn_line_t
--                WHERE
--                    batch_id = p_batch_id
--            )
--        WHERE
--            batch_id = p_batch_id;
--
--    END;
--  --  logging_insert('TW', p_batch_id, 2.6, 'value of error flag at line level', p_error_flag,sysdate);
        dbms_output.put_line('LINE exit');
        COMMIT;
        logging_insert('TW', p_batch_id, 5, 'Temp TABLE DATA TO LINE TABLE DATA - END', NULL,
                      sysdate);
        logging_insert('TW', p_batch_id, 6, 'Updating TW Line table with header id starts', NULL,
                      sysdate);
        UPDATE wsc_ahcs_tw_txn_line_t line
        SET
            ( header_id ) = (
                SELECT  /*+ index(hdr WSC_AHCS_TW_TXN_HDR_T_PK) */
                    hdr.header_id --,leg_coa
                FROM
                    wsc_ahcs_tw_txn_header_t hdr
                WHERE
                        line.batch_id = hdr.batch_id
                    AND line.transaction_number = hdr.transaction_number
            )
        --and rownum =1)
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        logging_insert('TW', p_batch_id, 7, 'Updating TW Line table with header id ends', NULL,
                      sysdate);
        logging_insert('TW', p_batch_id, 8, 'Inserting records in status table starts', NULL,
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
                decode(sign(line.monetary_amount), - 1, 'CR', 'DR'),
                line.currency_cd,
                line.monetary_amount,
                line.leg_coa,
                NULL,
                line.line_nbr,
                line.transaction_number,
                hdr.transaction_date,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
                wsc_ahcs_tw_txn_line_t   line,
                wsc_ahcs_tw_txn_header_t hdr
            WHERE
                    line.batch_id = p_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id;

--        COMMIT;
--        logging_insert('TW', p_batch_id, 9, 'Inserting records in status table ends', NULL,
--                      sysdate);    
    EXCEPTION
        WHEN OTHERS THEN
            p_error_flag := '1';
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('TW', p_batch_id, 9.1, 'Error in WSC_PROCESS_MFAP_STAGE_TO_HEADER_LINE proc', sqlerrm,
                          sysdate);
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT045', 'TW', sqlerrm);
--
--            dbms_output.put_line(sqlerrm);

--begin null;
--end;
    END wsc_process_tw_temp_to_header_line_p;

    PROCEDURE wsc_async_process_update_validate_transform_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    ) AS
        err_msg VARCHAR2(2000);
    BEGIN
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;

        dbms_scheduler.create_job(job_name => 'WSC_PROCESS_TW_TEMP_TO_HEADER_LINE_P' || p_batch_id, job_type => 'PLSQL_BLOCK', job_action =>
        'BEGIN
         WSC_TW_PKG.WSC_PROCESS_TW_TEMP_TO_HEADER_LINE_P('
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
         wsc_ahcs_tw_validation_transformation_pkg.data_validation('
                                                                                                                                          ||
                                                                                                                                          p_batch_id
                                                                                                                                          ||
                                                                                                                                          ');
       END;', enabled => true, auto_drop => true,
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
    END wsc_async_process_update_validate_transform_p;

END wsc_tw_pkg;

/

--create or replace PACKAGE BODY          "WSC_TW_PKG" AS
--
--    PROCEDURE "WSC_TW_INSERT_DATA_TEMP_P" 
--    (
--      IN_WSC_AHCS_TW_TXN_TMP IN WSC_AHCS_TW_TXN_TMP_T_TYPE_TABLE
--    ) AS
--    BEGIN
--		FORALL i IN 1..IN_WSC_AHCS_TW_TXN_TMP.count
--            INSERT INTO WSC_AHCS_TW_TXN_TMP_T (
--                batch_id,
--                data_string
--            ) VALUES (
--                IN_WSC_AHCS_TW_TXN_TMP(i).batch_id,
--                IN_WSC_AHCS_TW_TXN_TMP(i).data_string
--            );
--	END;
--
--    PROCEDURE WSC_PROCESS_TW_TEMP_TO_HEADER_LINE_P (
--        p_batch_id NUMBER,
--        p_application_name  IN  VARCHAR2,
--        p_file_name         IN  VARCHAR2
--    ) AS
--	
--    v_error_msg            VARCHAR2(200);
--    v_stage                VARCHAR2(200);
--    lv_count  NUMBER;
--    err_msg   VARCHAR2(2000);
--    l_system  VARCHAR2(200);
--
--    CURSOR tw_stage_line_data_cur (
--        p_batch_id NUMBER
--    ) IS
--    SELECT
--        *
--    FROM
--        WSC_AHCS_TW_TXN_TMP_T
--    WHERE
--            batch_id = p_batch_id
--            and data_string not like '%CONTROL%';
--
--    TYPE tw_stage_line_type IS TABLE OF tw_stage_line_data_cur%rowtype;
--    lv_tw_stg_line_type  tw_stage_line_type;
--
--    control_count NUMBER;
--    tmp_string VARCHAR2(100);
--    sqe VARCHAR2(200);
--    BEGIN
----        begin
----            p_error_flag := '0';
----        exception 
----        when others then
----            logging_insert ('TW',p_batch_id,1.1,'value of error flag',sqlerrm,sysdate);
----        end; 
--
--       BEGIN
--            SELECT attribute3 INTO l_system
--              FROM wsc_ahcs_int_control_t c
--             WHERE c.batch_id = p_batch_id; 
--            dbms_output.put_line(l_system);
--        END;
--        
--        begin 
--            select data_string into tmp_string from WSC_AHCS_TW_TXN_TMP_T where data_string like '%CONTROL%'
--            and batch_id = p_batch_id;
--            update wsc_ahcs_int_control_t set total_records = to_number(substr(tmp_string,instr(tmp_string,' ')))
--            where batch_id = p_batch_id;
--            
--        end;
--    dbms_output.put_line(' Begin inserting records into header line table');
--    /********** PROCESS STAGE TABLE DATA TO HEADER TABLE DATA - START *************/
--    logging_insert ('TW',p_batch_id,2,'INSERT DATA TO HEADER TABLE DATA - START',NULL,sysdate);
--
--            INSERT INTO WSC_AHCS_TW_TXN_HEADER_T(
--			 BATCH_ID
--            ,HEADER_ID
--            ,TRANSACTION_TYPE
--            ,TRANSACTION_DATE
--            ,TRANSACTION_NUMBER
--            ,LEDGER_NAME
--            ,LEG_BUS_UNIT
--            ,FILE_NAME
--            ,SOURCE
--            ,TRANS_REF_NBR
--            ,CREATION_DATE
--            ,CREATED_BY
--            ,LAST_UPDATE_DATE
--            ,LAST_UPDATED_BY
--            ) values( 
--                p_batch_id,	
--                wsc_tw_header_t_s1.NEXTVAL,
--				'TREASURY',
--                null, --TRANSACTION_DATE
--                REPLACE(p_file_name,'_',''), -- Transaction_number
--                null --LEDGER_NAME
--                ,null --LEG_BUS_UNIT
--                ,p_file_name
--                ,'TMI' --SOURCE
--                ,null --TRANS_REF_NBR
--                ,sysdate --CREATION_DATE
--                ,'FIN_INT' --CREATED_BY
--                ,sysdate --LAST_UPDATE_DATE
--                ,'FIN_INT' --LAST_UPDATED_BY
--                );
----                FROM 
----                WSC_AHCS_TW_TXN_TMP_T temp
----                WHERE
----                temp.batch_id = p_batch_id
----                and rownum=1;
----                
--            COMMIT;
--
--   /* logging_insert('TW', p_batch_id, 2.3, 'value of error flag', p_error_flag,sysdate);
--    CLOSE TW_stage_hdr_data_cur;
--    EXCEPTION
--        WHEN OTHERS THEN
--            p_error_flag := '1';
--             err_msg := substr(sqlerrm, 1, 200);
--             wsc_ahcs_int_error_logging.error_logging(p_batch_id,
--                                                    'INT123'
--                                                    || '_'
--                                                    || l_system,
--                                                    'TW',
--                                                    sqlerrm); */
--
--   -- END;
--   -- logging_insert('TW', p_batch_id, 2.4, 'value of error flag at header level', p_error_flag, sysdate);
--    dbms_output.put_line('HEADER exit');
--    COMMIT;
--    logging_insert ('TW',p_batch_id,3,'INSERT DATA TO HEADER TABLE DATA - END',NULL,sysdate);
--
--
-- /********** PROCESS UNSTRUCTURED TEMP TABLE DATA TO LINE TABLE DATA - START *************/
--    dbms_output.put_line('Insert Data into Line Table');
--    logging_insert ('TW',p_batch_id,4,'STAGE TABLE DATA TO LINE TABLE DATA - START',NULL,sysdate);
--
--    OPEN TW_stage_line_data_cur(p_batch_id);
--    LOOP
--        FETCH TW_stage_line_data_cur BULK COLLECT INTO lv_TW_stg_line_type LIMIT 400;
--        EXIT WHEN lv_TW_stg_line_type.count = 0;
--	BEGIN
--        FORALL i IN 1..lv_TW_stg_line_type.count
--           INSERT INTO WSC_AHCS_TW_TXN_LINE_T (
--				BATCH_ID
--                ,LINE_ID
--                ,HEADER_ID
--                ,BUSINESS_UNIT
--                ,APPL_JRNL_ID
--                ,AXE_TRANS_DT
--                ,AXE_LINE_NBR
--                ,ACCOUNTING_DT
--                ,BUSINESS_UNIT_GL
--                ,LEDGER
--                ,LEDGER_GROUP
--                ,ACCOUNT
--                ,ALTACCT
--                ,AXE_LOC
--                ,DEPTID
--                ,PRODUCT
--                ,AXE_MRKT_CHNL
--                ,AXE_PROJECT
--                ,PROJECT_ID
--                ,AXE_VENDOR_10
--                ,AFFILIATE
--                ,MONETARY_AMOUNT
--                ,FOREIGN_AMOUNT
--                ,CURRENCY_CD
--                ,FOREIGN_CURRENCY
--                ,GL_DISTRIB_STATUS
--                ,TRANS_REF_NBR
--                ,DESCR
--                ,SOURCE
--                ,FILLER
--                ,TRANSACTION_NUMBER
--                ,LEG_BU
--                ,LEG_ACCT
--                ,LEG_DEPT
--                ,LEG_LOC
--                ,LEG_VENDOR
--                ,LEG_AFFILIATE
--                ,GL_LEGAL_ENTITY
--                ,GL_OPER_GRP
--                ,GL_ACCT
--                ,GL_DEPT
--                ,GL_SITE
--                ,GL_IC
--                ,GL_PROJECTS
--                ,GL_FUT_1
--                ,GL_FUT_2
--                ,LEG_COA
--                ,LEG_SEG_1_4
--                ,LEG_SEG_5_7
--                ,CREATION_DATE
--                ,CREATED_BY
--                ,LAST_UPDATE_DATE
--                ,LAST_UPDATED_BY
--                ,ATTRIBUTE1
--                ,ATTRIBUTE2
--                ,ATTRIBUTE3
--                ,ATTRIBUTE4
--                ,ATTRIBUTE5
--                ,ATTRIBUTE6
--                ,ATTRIBUTE7
--                ,ATTRIBUTE8
--                ,ATTRIBUTE9
--                ,ATTRIBUTE10
--                ,ATTRIBUTE11
--                ,ATTRIBUTE12
--                ) 
--                VALUES (
--                p_batch_id,
--                wsc_tw_line_t_s1.NEXTVAL,
--                wsc_tw_header_t_s1.CURRVAL, --header_id
--				TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,0,5)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,6,10)),
--                to_date(TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,16,10)),'MM/DD/YYYY'),
--                to_number(TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,26,9))),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,35,10)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,45,5)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,50,10)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,60,10)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,70,9)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,79,9)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,88,5)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,93,4)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,97,5)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,102,2)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,104,7)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,111,15)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,126,10)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,136,5)),
--                to_number(TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,141,16))),
--                to_number(TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,157,16))),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,173,3)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,176,3)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,179,1)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,180,8)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,188,30)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,218,3)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,221)),
--                REPLACE(p_file_name,'_',''), --TRANSACTION_NUMBER
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,45,5)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,70,9)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,93,4)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,88,5)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,126,10)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,136,5)),
--                null,
--                null,
--                null,
--                null,
--                null,
--                null,
--                null,
--                null,
--                null,
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,45,5)) || '.' || 
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,88,5)) || '.' || 
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,93,4)) || '.' || 
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,70,9)) || '.' || 
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,126,10)) || '.' ||
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,136,5)),
--				TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,45,5)) || '.' || TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,88,5)) || '.' || TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,70,9)) || '.' || TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,93,4)),
--                TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,126,10)) || '.' ||TRIM(SUBSTR(lv_tw_stg_line_type(i).data_string,136,5))
--                ,sysdate
--                ,'FIN_INT'
--                ,sysdate
--                ,'FIN_INT'
--                ,null
--                ,null
--                ,null
--                ,null
--                ,null
--                ,null
--                ,null
--                ,null
--                ,null
--                ,null
--                ,null
--                ,null
--                  );
--
----/********** PROCESS UNSTRUCTURED STAGE TABLE DATA TO LINE TABLE DATA - END *************/
--	EXCEPTION
--        WHEN OTHERS THEN
--        sqe := substr(sqlerrm,1,200);
--        update wsc_ahcs_int_control_t set attribute1=sqe where batch_id=p_batch_id;
--        logging_insert ('TW',p_batch_id,5.1,sqlerrm,NULL,sysdate);
--		END;
--    END LOOP;
---- /*logging_insert('TW', p_batch_id, 2.5, 'value of error flag', p_error_flag,
----      sysdate);
--    CLOSE TW_stage_line_data_cur;
--    update WSC_AHCS_TW_TXN_HEADER_T set TRANSACTION_DATE = (select distinct(axe_trans_dt) from WSC_AHCS_TW_TXN_LINE_T where batch_id = p_batch_id) where batch_id = p_batch_id;
----
----    END;
----  --  logging_insert('TW', p_batch_id, 2.6, 'value of error flag at line level', p_error_flag,sysdate);
--    dbms_output.put_line('LINE exit');
--    COMMIT;
--    logging_insert ('TW',p_batch_id,5,'Temp TABLE DATA TO LINE TABLE DATA - END',NULL,sysdate);
--
--    logging_insert('TW', p_batch_id, 6, 'Updating TW Line table with header id starts', NULL,
--                      sysdate);
----
----
----        UPDATE WSC_AHCS_TW_TXN_LINE_T line
----        SET
----            ( header_id) --,leg_coa )
----			= (
----                SELECT  /*+ index(hdr WSC_AHCS_TW_TXN_HDR_T_PK) */
----                    hdr.header_id --,leg_coa
----                FROM
----                    WSC_AHCS_TW_TXN_HEADER_T hdr
----                WHERE
----                    line.batch_id = hdr.batch_id
----            )
----        --and rownum =1)
----        WHERE
----            batch_id = p_batch_id;
----
----        COMMIT;
----        logging_insert('TW', p_batch_id, 7, 'Updating TW Line table with header id ends', NULL,
----                      sysdate);
--        logging_insert('TW', p_batch_id, 8, 'Inserting records in status table starts', NULL,
--                      sysdate);
--        INSERT INTO wsc_ahcs_int_status_t (
--                HEADER_ID,
--                LINE_ID,
--                APPLICATION,
--                FILE_NAME,
--                BATCH_ID,
--                STATUS,
--                CR_DR_INDICATOR,
--                CURRENCY,
--                VALUE,
--                SOURCE_COA,
--                LEGACY_HEADER_ID,
--                LEGACY_LINE_NUMBER,
--                ATTRIBUTE3,
--                ATTRIBUTE11,
--                CREATED_BY,
--                CREATED_DATE,
--                LAST_UPDATED_BY,
--                LAST_UPDATED_DATE
--        )
--            SELECT
--                line.header_id,
--                line.line_id,
--                p_application_name,
--                p_file_name,
--                p_batch_id,
--                'NEW',
--                NULL,
--                line.CURRENCY_CD,
--                line.MONETARY_AMOUNT,
--                line.leg_coa,
--                NULL,
--                NULL,
--                line.transaction_number,
--                to_date(hdr.TRANSACTION_DATE, 'yyyy-mm-dd'),
--                'FIN_INT',
--                sysdate,
--                'FIN_INT',
--                sysdate
--            FROM
--                WSC_AHCS_TW_TXN_LINE_T    line,
--                WSC_AHCS_TW_TXN_HEADER_T  hdr
--            WHERE
--                    line.batch_id = p_batch_id
--                AND hdr.header_id (+) = line.header_id
--                AND hdr.batch_id (+) = line.batch_id;
--
----        COMMIT;
----        logging_insert('TW', p_batch_id, 9, 'Inserting records in status table ends', NULL,
----                      sysdate);    
----    EXCEPTION
----        WHEN OTHERS THEN
----           p_error_flag := '1';
----            err_msg := substr(sqlerrm, 1, 200);
----            logging_insert('TW', p_batch_id, 9.1,
----                          'Error in WSC_PROCESS_MFAP_STAGE_TO_HEADER_LINE proc',
----                          sqlerrm,
----                          sysdate);
----            wsc_ahcs_int_error_logging.error_logging(p_batch_id,
----                                                    'INT045'
----                                                    || '_'
----                                                    || l_system,
----                                                    'TW',
----                                                    sqlerrm);
----
----            dbms_output.put_line(sqlerrm);
--
----begin null;
----end;
--	END WSC_PROCESS_TW_TEMP_TO_HEADER_LINE_P;
--
--
--    PROCEDURE wsc_async_process_update_validate_transform_p (
--        p_batch_id          NUMBER,
--        p_application_name  VARCHAR2,
--        p_file_name         VARCHAR2
--    ) AS
--        err_msg VARCHAR2(2000);
--    BEGIN
--		UPDATE wsc_ahcs_int_control_t
--        SET
--            status = 'ASYNC DATA PROCESS'
--        WHERE
--            batch_id = p_batch_id;
--
--        dbms_scheduler.create_job(job_name => 'WSC_PROCESS_TW_TEMP_TO_HEADER_LINE_P' || p_batch_id, job_type => 'PLSQL_BLOCK',
--                                 job_action => 'BEGIN
--         WSC_TW_PKG.WSC_PROCESS_TW_TEMP_TO_HEADER_LINE_P('
--                                               || p_batch_id
--                                               || ','''
--                                               || p_application_name
--                                               || ''','''
--                                               || p_file_name
--                                               || ''');
--         wsc_ahcs_tw_validation_transformation_pkg.data_validation('
--                                               || p_batch_id
--                                               || ');
--       END;',
--                                 enabled => true,
--                                 auto_drop => true,
--                                 comments => 'Async steps to process stage data and update, insert into WSC_AHCS_INT_STATUS_T and call Validate and Transform procedure');
--
--    EXCEPTION
--        WHEN OTHERS THEN
--            err_msg := substr(sqlerrm, 1, 200);
--            UPDATE wsc_ahcs_int_control_t
--            SET
--                status = err_msg
--            WHERE
--                batch_id = p_batch_id;
--
--            dbms_output.put_line(sqlerrm);
--    END wsc_async_process_update_validate_transform_p;
--    
--END WSC_TW_PKG;