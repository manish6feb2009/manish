create or replace PACKAGE BODY wsc_cp_pkg AS

    PROCEDURE wsc_cp_line_p (
        in_wsc_cp_line IN wsc_ahcs_cloudpay_txn_line_t_type_table
    ) AS
    BEGIN
        FORALL i IN 1..in_wsc_cp_line.count      
            INSERT INTO wsc_ahcs_cp_txn_line_t (          
                batch_id,               
                line_id,               
                default_amt,
                default_currency,               
                company_num,
                pay_code,
                pay_code_desc,
                dr,
                cr,
                conversion_rate_type,              
                gl_code,
                cost_center_name,
                attribute8, --FILENAME
                LINE_SEQ_NBR
            ) VALUES (
                in_wsc_cp_line(i).batch_id,               
                wsc_cp_line_t_s1.NEXTVAL,               
                in_wsc_cp_line(i).default_amt,
                in_wsc_cp_line(i).default_currency,               
                in_wsc_cp_line(i).company_num,
                in_wsc_cp_line(i).pay_code,
                in_wsc_cp_line(i).pay_code_desc,
                in_wsc_cp_line(i).dr,
                in_wsc_cp_line(i).cr,
                in_wsc_cp_line(i).conversion_rate_type,               
                in_wsc_cp_line(i).gl_code,
                in_wsc_cp_line(i).cost_center_name,
                in_wsc_cp_line(i).attribute8,
                WSC_CP_LINE_SEQ_NBR_T_S2.NEXTVAL
            );
 
        COMMIT;
    END wsc_cp_line_p;


 PROCEDURE "WSC_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P" (
        p_batch_id          IN  NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2
    )AS
    
    err_msg VARCHAR2(2000);
    min_value number;
    
    cursor cur_min_value is 
    select min(LINE_SEQ_NBR) from wsc_ahcs_cp_txn_line_t where batch_id = p_batch_id;
        
        BEGIN
        logging_insert('CLOUDPAY', p_batch_id, 1, 'Starts ASYNC DB Scheduler', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;
        
        COMMIT;
        ---update line_seq_nbr
        open cur_min_value;
        fetch cur_min_value into min_value;
        close cur_min_value;
        
        update wsc_ahcs_cp_txn_line_t set LINE_SEQ_NBR = (LINE_SEQ_NBR - min_value) + 1
        where batch_id = p_batch_id;
        commit;
        
        dbms_scheduler.create_job(job_name => 'INVOKE_WSC_CLOUDPAY_INSERT_DATA_IN_GL_STATUS_P' || p_batch_id,
                                 job_type => 'PLSQL_BLOCK',
                                 job_action => 'BEGIN
         wsc_cp_pkg.wsc_insert_data_in_gl_status_p('
                                               || p_batch_id
                                               || ','''
                                               || p_application_name
                                               || ''','''
                                               || p_file_name
                                               || ''');
         WSC_AHCS_CP_VALIDATION_TRANSFORMATION_PKG.data_validation('
                                               || p_batch_id
                                               || ');
       END;',
                                 enabled => true,
                                 auto_drop => true,
                                 comments => 'Async steps to update, insert into WSC_AHCS_INT_STATUS_T and call Validate and Transform procedure');
    --dbms_scheduler.run_job (job_name => 'INVOKE_WSC_AP_INSERT_DATA_IN_GL_STATUS_P');

    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('CLOUDPAY', p_batch_id, 102, 'Error in Async DB Proc', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            COMMIT;
            dbms_output.put_line(sqlerrm);
    END;
    
    
     PROCEDURE wsc_insert_data_in_gl_status_p (
        p_batch_id          NUMBER,
        p_application_name  VARCHAR2,
        p_file_name         VARCHAR2
    ) IS
        lv_count  NUMBER;
        err_msg   VARCHAR2(2000);

 BEGIN
        logging_insert('CLOUDPAY', p_batch_id, 2, 'Updating CLOUDPAY Line table with LEG_COA starts', NULL,
                      sysdate);
                      
      UPDATE wsc_ahcs_cp_txn_line_t line
        SET LEG_SEG_1_4 = SUBSTR(TO_CHAR(cost_center_name),1,5) || '.' || SUBSTR(TO_CHAR(cost_center_name),6,5) || '.' || TO_CHAR(gl_code) || '.'|| SUBSTR(TO_CHAR(cost_center_name),-4,4), 
        CREATION_DATE = SYSDATE, 
        CREATED_BY = 'FIN_INT', 
        LAST_UPDATE_DATE= SYSDATE, 
        LAST_UPDATED_BY = 'FIN_INT',
        LEG_BU = SUBSTR(TO_CHAR(cost_center_name),1,5),
        LEG_LOC = SUBSTR(TO_CHAR(cost_center_name),6,5),
        LEG_ACCT = TO_CHAR(gl_code),
        LEG_DEPT= SUBSTR(TO_CHAR(cost_center_name),-4,4),
       ACCOUNTING_DATE = to_date((substr(substr(attribute8,instr(attribute8,'_',1)+1,instr(attribute8,'_',1,2)-instr(attribute8,'_',1,1)-1),1,4))||(substr(substr(attribute8,instr(attribute8,'_',1)+1,instr(attribute8,'_',1,2)-instr(attribute8,'_',1,1)-1),5,2))||(substr(substr(attribute8,instr(attribute8,'_',1)+1,instr(attribute8,'_',1,2)-instr(attribute8,'_',1,1)-1),7,2)),'yyyymmdd') ,
        LEG_COA = (SUBSTR(TO_CHAR(cost_center_name),1,5) || '.' ||SUBSTR(TO_CHAR(cost_center_name),6,5)|| '.' || SUBSTR(TO_CHAR(cost_center_name),-4,4) || '.'||TO_CHAR(gl_code)||'.'||null||'.'||'00000')
             
        --and rownum =1)
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        logging_insert('CLOUDPAY', p_batch_id, 3, 'Updating CLOUDPAY Line table with LEG_COA ends', NULL,
                      sysdate);
        logging_insert('CLOUDPAY', p_batch_id, 4, 'Inserting records in status table starts', NULL,
                      sysdate);
                      
      INSERT INTO wsc_ahcs_int_status_t (
           
            line_id,
            application,
            file_name,
            batch_id,
            status, 
            CR_DR_INDICATOR,
            currency,
            value,
            source_coa, 
            attribute11,
            created_by,
            created_date,
            last_updated_by,
            last_updated_date,
            ATTRIBUTE4, --putting value of LEG_BU in attribute4 to be used in V&T pkg
            COMPANY_NUM,
            PAY_CODE,
            GL_CODE,
            DR,
            CR,
            legacy_line_number
        )
            SELECT
                line.line_id,
                p_application_name,
                p_file_name,
                p_batch_id,
                'NEW',  
                decode ( line.dr ,0, 'CR', 'DR'),
                line.DEFAULT_CURRENCY,
                line.default_amt,
               -- decode ( line.dr ,0, line.cr, line.dr),
                line.LEG_COA,
                line.ACCOUNTING_DATE,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate,
                line.LEG_BU,
                line.COMPANY_NUM,
                line.PAY_CODE,
                line.GL_CODE,
                line.DR,
                line.CR,
                line.LINE_SEQ_NBR
            FROM
                wsc_ahcs_cp_txn_line_t line          
            WHERE
                    line.batch_id = p_batch_id  ;
                    
            
                   

        COMMIT;
        logging_insert('CLOUDPAY', p_batch_id, 5, 'Inserting records in status table ends', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('CLOUDPAY', p_batch_id, 101,
                          'Error While updating Line table with LEG_COA/inserting data in status table',
                          sqlerrm,
                          sysdate);
                          
             WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(p_batch_id,
                        'INT018',
                        'CLOUDPAY',
                        SQLERRM);
            dbms_output.put_line(sqlerrm);
    END;
END wsc_cp_pkg;
/