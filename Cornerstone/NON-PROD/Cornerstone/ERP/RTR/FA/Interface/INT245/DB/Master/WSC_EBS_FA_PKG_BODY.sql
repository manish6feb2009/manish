create or replace PACKAGE BODY "WSC_EBS_FA_PKG" AS

    PROCEDURE WSC_FA_P (
        IN_WSC_EBS_FA IN WSC_EBS_FA_T_TYPE_TABLE
    ) AS
    BEGIN
        FORALL i IN 1..IN_WSC_EBS_FA.count
            INSERT INTO WSC_EBS_FA_TXN_T (
                        FA_TXN_T_ID              ,
                        ASSETID                  ,
                        DESCRIPTION              ,
                        TAG_NUMBER               ,
                        MANUFACTURER_NAME        ,
                        SERIAL_NUMBER            ,
                        MODEL_NUMBER             ,
                        FIXED_ASSETS_COST        ,
                        DATE_PLACED_IN_SERVICE   ,
                        FIXED_ASSETS_UNITS       ,
                        LINE_STATUS              ,
                        PARENT_MASS_ADDITION_ID          ,
                        PAYABLES_COST            ,
                        COST_CLR_ACCOUNT_SEGMENT1,
                        COST_CLR_ACCOUNT_SEGMENT2,
                        COST_CLR_ACCOUNT_SEGMENT3,
                        COST_CLR_ACCOUNT_SEGMENT4,
                        COST_CLR_ACCOUNT_SEGMENT5,
                        COST_CLR_ACCOUNT_SEGMENT6,
                        COST_CLR_ACCOUNT_SEGMENT7,
                        COST_CLR_ACCOUNT_SEGMENT8,
                        COST_CLR_ACCOUNT_SEGMENT9,
                        SUPPLIER_NAME            ,
                        PO_NUMBER                ,
                        INVOICE_NUMBER           ,
                        INVOICE_DATE             ,
                        PAYABLES_UNITS           ,
                        INVOICE_LINE_NUMBER      ,
                        INVOICE_PAYMENT_NUMBER   ,
                        BIR_NUMBER               ,
                        SUPPLIER_NUMBER          ,
                        SPLIT_MERGED_CODE        ,
                        FILE_NAME                ,
                        CREATED_BY               ,
                        CREATION_DATE            ,
                        LAST_UPDATED_BY          ,
                        LAST_UPDATE_DATE         ,
                        ATTRIBUTE1               ,
                        ATTRIBUTE2               ,
                        ATTRIBUTE3               ,
                        ATTRIBUTE4               ,
                        ATTRIBUTE5               ,
                        ATTRIBUTE6               ,
                        ATTRIBUTE7               ,
                        ATTRIBUTE8               ,
                        ATTRIBUTE9               ,
                        ATTRIBUTE10              ,
                        BATCH_ID)
                        VALUES (
                WSC_EBS_FA_TXN_T_S1.NEXTVAL               ,        
                IN_WSC_EBS_FA(i).ASSETID                  ,
                IN_WSC_EBS_FA(i).DESCRIPTION              ,
                IN_WSC_EBS_FA(i).TAG_NUMBER               ,
                IN_WSC_EBS_FA(i).MANUFACTURER_NAME        ,
                IN_WSC_EBS_FA(i).SERIAL_NUMBER            ,
                IN_WSC_EBS_FA(i).MODEL_NUMBER             ,
                IN_WSC_EBS_FA(i).FIXED_ASSETS_COST        ,
                to_date(IN_WSC_EBS_FA(i).DATE_PLACED_IN_SERVICE,'yyyy/mm/dd') ,
                IN_WSC_EBS_FA(i).FIXED_ASSETS_UNITS       ,
                IN_WSC_EBS_FA(i).LINE_STATUS              ,
                IN_WSC_EBS_FA(i).PARENT_MASS_ADDITION_ID  ,
                IN_WSC_EBS_FA(i).PAYABLES_COST            ,
                IN_WSC_EBS_FA(i).COST_CLR_ACCOUNT_SEGMENT1,
                IN_WSC_EBS_FA(i).COST_CLR_ACCOUNT_SEGMENT2,
                IN_WSC_EBS_FA(i).COST_CLR_ACCOUNT_SEGMENT3,
                IN_WSC_EBS_FA(i).COST_CLR_ACCOUNT_SEGMENT4,
                IN_WSC_EBS_FA(i).COST_CLR_ACCOUNT_SEGMENT5,
                IN_WSC_EBS_FA(i).COST_CLR_ACCOUNT_SEGMENT6,
                IN_WSC_EBS_FA(i).COST_CLR_ACCOUNT_SEGMENT7,
                IN_WSC_EBS_FA(i).COST_CLR_ACCOUNT_SEGMENT8,
                IN_WSC_EBS_FA(i).COST_CLR_ACCOUNT_SEGMENT9,
                IN_WSC_EBS_FA(i).SUPPLIER_NAME            ,
                IN_WSC_EBS_FA(i).PO_NUMBER                ,
                IN_WSC_EBS_FA(i).INVOICE_NUMBER           ,
                to_date(IN_WSC_EBS_FA(i).INVOICE_DATE, 'yyyy/mm/dd') ,
                IN_WSC_EBS_FA(i).PAYABLES_UNITS           ,
                IN_WSC_EBS_FA(i).INVOICE_LINE_NUMBER      ,
                IN_WSC_EBS_FA(i).INVOICE_PAYMENT_NUMBER   ,
                IN_WSC_EBS_FA(i).BIR_NUMBER               ,
                IN_WSC_EBS_FA(i).SUPPLIER_NUMBER          ,
                IN_WSC_EBS_FA(i).SPLIT_MERGED_CODE        ,
                IN_WSC_EBS_FA(i).FILE_NAME                ,
                'FININT'                                    ,
                sysdate                                   ,
                'FININT'                                  ,
                sysdate         ,
                IN_WSC_EBS_FA(i).ATTRIBUTE1               ,
                IN_WSC_EBS_FA(i).ATTRIBUTE2               ,
                IN_WSC_EBS_FA(i).ATTRIBUTE3               ,
                IN_WSC_EBS_FA(i).ATTRIBUTE4               ,
                IN_WSC_EBS_FA(i).ATTRIBUTE5               ,
                IN_WSC_EBS_FA(i).ATTRIBUTE6               ,
                IN_WSC_EBS_FA(i).ATTRIBUTE7               ,
                IN_WSC_EBS_FA(i).ATTRIBUTE8               ,
                IN_WSC_EBS_FA(i).ATTRIBUTE9               ,
                IN_WSC_EBS_FA(i).ATTRIBUTE10              ,
                IN_WSC_EBS_FA(i).BATCH_ID
            );

    END WSC_FA_P;

    PROCEDURE WSC_INSERT_DATA_IN_STATUS_P (
        p_batch_id          NUMBER,
        p_application_name  VARCHAR2,
        p_file_name         VARCHAR2
    ) IS
        lv_count  NUMBER;
        err_msg   VARCHAR2(2000);

  lv_batch_id   NUMBER := p_batch_id; 
    BEGIN
       logging_insert('EBS APFA', p_batch_id, 1, 'Inserting records in status table starts', NULL,
                      sysdate);
        INSERT INTO wsc_gen_int_status_t (
            header_id,
            application,
            file_name,
            batch_id,
            status,
            value,
            source_coa,
            legacy_header_id,
            attribute3,
            attribute11,
            created_by,
            created_date,
            last_updated_by,
            last_updated_date
        )
            SELECT
                hdr.FA_TXN_T_ID,
                p_application_name,
                p_file_name,
                p_batch_id,
                'NEW',
                hdr.FIXED_ASSETS_COST,
                hdr.COST_CLR_ACCOUNT_SEGMENT1||'.'||hdr.COST_CLR_ACCOUNT_SEGMENT2||'.'||hdr.COST_CLR_ACCOUNT_SEGMENT3||'.'||hdr.COST_CLR_ACCOUNT_SEGMENT4||'.'||hdr.COST_CLR_ACCOUNT_SEGMENT5||'.'||hdr.COST_CLR_ACCOUNT_SEGMENT6||'.'||hdr.COST_CLR_ACCOUNT_SEGMENT7||'.'||hdr.COST_CLR_ACCOUNT_SEGMENT8||'.'||hdr.COST_CLR_ACCOUNT_SEGMENT9,
                hdr.ASSETID,
                hdr.LINE_STATUS,
                hdr.INVOICE_DATE,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
                wsc_ebs_fa_txn_t    hdr
            WHERE
                    hdr.batch_id = lv_batch_id;

        COMMIT;
        logging_insert('EBS APFA', p_batch_id, 2, 'Inserting records in status table ends', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('EBS APFA', p_batch_id, 101,
                          'Error While inserting data in status table',
                          sqlerrm,
                          sysdate);

             WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(p_batch_id,
                        'INT245',
                        'EBS_APFA',
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
        logging_insert('EBS APFA', p_batch_id, 1, 'Starts ASYNC DB Scheduler', NULL,
                      sysdate);
        UPDATE wsc_gen_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        dbms_scheduler.create_job(job_name => 'INVOKE_WSC_INSERT_DATA_IN_STATUS_P' || p_batch_id,
                                 job_type => 'PLSQL_BLOCK',
                                 job_action => 'BEGIN
         WSC_EBS_FA_PKG.WSC_INSERT_DATA_IN_STATUS_P('
                                               || p_batch_id
                                               || ','''
                                               || p_application_name
                                               || ''','''
                                               || p_file_name
                                               || ''');
         WSC_EBS_FA_VALIDATION_TRANSFORMATION_PKG.data_validation('
                                               || p_batch_id
                                               || ');
       END;',
                                 enabled => true,
                                 auto_drop => true,
                                 comments => 'Async steps to update, insert into WSC_AHCS_GEN_INT_STATUS_T and call Validate and Transform procedure');

    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('EBS APFA', p_batch_id, 102, 'Error in Async DB Proc', sqlerrm,
                          sysdate);
            UPDATE wsc_gen_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            COMMIT;
            dbms_output.put_line(sqlerrm);
    END;

END WSC_EBS_FA_PKG;
/
