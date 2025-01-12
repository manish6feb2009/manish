create or replace PACKAGE BODY WSC_ECLIPSE_PKG AS

/**** PROCEDURE INSERT INTO TEMP TABLE STARTS***/
PROCEDURE "WSC_ECLIPSE_INSERT_DATA_TEMP_P" (
      in_wsc_eclipse_stage IN WSC_ECLIPSE_TMP_T_TYPE_TABLE
) AS

BEGIN
    --logging_insert('ECLIPSE', 'BATCH_ID', 1,'STARTS ECLIPSE TEMP TABLE INSERT', NULL,SYSDATE);

    FORALL i IN 1..in_wsc_eclipse_stage.COUNT
    INSERT INTO WSC_AHCS_ECLIPSE_TXN_TMP_T (
                                             batch_id,
                                             rice_id,
                                             data_string,
                                             line_number
                                           ) VALUES 
                                                                                                                                                   (
                                              in_wsc_eclipse_stage(i).batch_id,
                                              in_wsc_eclipse_stage(i).rice_id,
                                              in_wsc_eclipse_stage(i).data_string,
                                              WSC_ECLIPSE_LINE_NBR_SEQ_S1.NEXTVAL
                                            ); 
                                           COMMIT;

    --logging_insert('ECLIPSE', 'BATCH_ID', 1,'ENDS ECLIPSE TEMP TABLE INSERT', NULL,SYSDATE);

              EXCEPTION 
              WHEN OTHERS THEN
    logging_insert('ECLIPSE', 'batch_id', 1.1, 'ERROR IN ECLIPSE TEMP TABLE INSERT DB PROC', SQLERRM,SYSDATE);

END "WSC_ECLIPSE_INSERT_DATA_TEMP_P";
/**** PROCEDURE INSERT INTO TEMP TABLE ENDS***/

PROCEDURE "WSC_ECLIPSE_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P" (
                                                                    p_batch_id IN NUMBER,
                                                                    p_application_name IN VARCHAR2,
                                                                    p_file_name IN VARCHAR2
                                                                   ) AS
                                           err_msg VARCHAR2(4000);
                                           p_error_flag varchar2(2);
BEGIN
    logging_insert('ECLIPSE', p_batch_id, 1, 'STARTS ASYNC DB SCHEDULER', NULL,SYSDATE);

    UPDATE wsc_ahcs_int_control_t
    SET status = 'ASYNC DATA PROCESS'
    WHERE batch_id = p_batch_id; 
COMMIT;

dbms_scheduler.create_job(job_name   => 'INVOKE_WSC_PROCESS_ECLIPSE_TEMP_TO_HEADER_LINE' || p_batch_id,
                          job_type   => 'PLSQL_BLOCK',
                          job_action => '
                            DECLARE
                            p_error_flag VARCHAR2(2);
                            BEGIN
                    WSC_ECLIPSE_PKG.WSC_PROCESS_ECLIPSE_TEMP_TO_HEADER_LINE_P(
                                                                                                                       '|| p_batch_id
                                                                    || ','''
                                                                    || p_application_name
                                                                    || ''','''
                                                                    || p_file_name
                                                                    || ''',
                                                                                                                                                                                                                                                     p_error_flag);
                                                          if p_error_flag = '||'''0'''||' then                                   
                WSC_AHCS_ECLIPSE_VALIDATION_TRANSFORMATION_PKG.DATA_VALIDATION('
                                               || p_batch_id
                                               || ');
                end if;                                                                                                                                                                   

                            END;',
                         enabled => true,
                       auto_drop => true,
                        comments => 'Async steps to split the data from Temp and Insert into Header and Line tables. Also, update Line Table, Insert into WSC_AHCS_INT_STATUS_T and call Validation and Transformation procedure');

   EXCEPTION
   WHEN OTHERS THEN
   err_msg := SUBSTR(SQLERRM, 1, 200);
   logging_insert('ECLIPSE', p_batch_id, 1.1, 'ERROR IN ASYNC DB PROC', SQLERRM,SYSDATE);

  UPDATE wsc_ahcs_int_control_t
   SET status = err_msg 
   WHERE batch_id = p_batch_id; 
   COMMIT;
   dbms_output.put_line(SQLERRM);

   logging_insert('ECLIPSE', p_batch_id, 2, 'ENDS ASYNC DB SCHEDULER', NULL,SYSDATE);

END "WSC_ECLIPSE_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P";

PROCEDURE "WSC_PROCESS_ECLIPSE_TEMP_TO_HEADER_LINE_P" (
                                                           p_batch_id         IN NUMBER,
                                                           p_application_name IN VARCHAR2,
                                                           p_file_name        IN VARCHAR2,
                                                           p_error_flag       OUT VARCHAR2
                                                      ) IS
         v_error_msg VARCHAR2(200);
         v_stage VARCHAR2(200);
         lv_count NUMBER;
         err_msg VARCHAR2(2000);
         l_system VARCHAR2(200);
                             lv_leg_tran_date date;
                             
                              
                              
  CURSOR eclipse_stage_line_data_cur (
                                    p_batch_id NUMBER
                                   ) IS

    SELECT tmp.*,
            ROW_NUMBER()
            OVER(
                ORDER BY
                    line_number
            ) AS row_line_num
     FROM WSC_AHCS_ECLIPSE_TXN_TMP_T tmp
    WHERE batch_id = p_batch_id; 

CURSOR eclipse_stage_hdr_data_cur(
                                    p_batch_id NUMBER
                                  ) IS
select distinct TO_DATE(TRIM(SUBSTR(data_string,35,10)),'MM/DD/YYYY') LEG_TRAN_DATE
from wsc_ahcs_eclipse_txn_tmp_t where batch_id = p_batch_id;
--     SELECT  DISTINCT LEG_TRAN_DATE 
--              FROM WSC_AHCS_ECLIPSE_TXN_LINE_T 
--              WHERE BATCH_ID=p_batch_id;--and rownum=1;*/
   /*SELECT * FROM WSC_AHCS_ECLIPSE_TXN_TMP_T
    WHERE batch_id = p_batch_id;
    --AND rownum=1; */

              TYPE eclipse_stage_hdr_type IS
    TABLE OF eclipse_stage_hdr_data_cur%rowtype;
    lv_eclipse_stg_hdr_type eclipse_stage_hdr_type;



              -- select * from WSC_AHCS_ECLIPSE_TXN_TMP_T where batch_id = p_batch_id order by line_number;


              TYPE eclipse_stage_line_type IS
    TABLE OF eclipse_stage_line_data_cur%rowtype;
    lv_eclipse_stg_line_type eclipse_stage_line_type;

  BEGIN
    BEGIN
         p_error_flag := '0';
    EXCEPTION
    WHEN OTHERS THEN
    logging_insert ('ECLIPSE',p_batch_id,2.1,'VALUE OF ERROR FLAG',SQLERRM,SYSDATE);
    END;

--fetch source system name
   BEGIN
    SELECT attribute3
    INTO l_system
    FROM wsc_ahcs_int_control_t c
    WHERE c.batch_id = p_batch_id; 
              dbms_output.put_line(l_system);
   END;
    dbms_output.put_line('Begin segregration of header line data');
              
--            BEGIN
--              OPEN eclipse_stage_hdr_data_cur(WSC_ECLIPSE_HEADER_T_S1.CURRVAL);
--              FETCH eclipse_stage_hdr_data_cur  INTO lv_leg_tran_date;
--              CLOSE eclipse_stage_hdr_data_cur;
--            END;

/********** PROCESS UNSTRUCTURED ECLIPSE TEMP TABLE DATA TO ECLIPSE HEADER TABLE DATA - START *************/
    logging_insert ('ECLIPSE',p_batch_id,2,'STARTS - TEMP TABLE DATA TO HEADER TABLE DATA INSERTION',NULL,SYSDATE);

       OPEN eclipse_stage_hdr_data_cur(p_batch_id);
        LOOP
            FETCH eclipse_stage_hdr_data_cur BULK COLLECT INTO lv_eclipse_stg_hdr_type LIMIT 4000;
        EXIT WHEN lv_eclipse_stg_hdr_type.COUNT = 0;
        BEGIN
           FORALL i IN 1..lv_eclipse_stg_hdr_type.COUNT
             SAVE EXCEPTIONS
            INSERT INTO WSC_AHCS_ECLIPSE_TXN_HEADER_T (
                        BATCH_ID,
                        HEADER_ID,
                        TRANSACTION_DATE,
                        TRANSACTION_NUMBER,
                        LEDGER_NAME,
                        FILE_NAME,
                        TRANSACTION_TYPE,
                        SOURCE,
                        CREATION_DATE,
                        LAST_UPDATE_DATE,
                        CREATED_BY,
                        LAST_UPDATED_BY
                    ) 
                                                                        VALUES 
                                                              (
                        p_batch_id,
                        WSC_ECLIPSE_HEADER_T_S1.NEXTVAL,
                        lv_eclipse_stg_hdr_type(i).LEG_TRAN_DATE,----lv_leg_tran_date, --- Transaction Date
                        p_file_name||'_'||TO_CHAR(lv_eclipse_stg_hdr_type(i).LEG_TRAN_DATE,'YYYYMMDD'), -- to_char(lv_eclipse_stg_hdr_type(i).LEG_TRAN_DATE,'MM/DD/YYYY'),  --- Transaction Number  TO_CHAR (TO_DATE (batch_rec.POSTING_DATE,'YYYY-MM-DD'),'YYYY/MM/DD'),
                        NULL, --- Ledger Name
                        p_file_name, 
                        'ECLPS',     ---Transaction Type
                        NULL,
                        SYSDATE,
                        SYSDATE,
                        'FIN_INT',
                        'FIN_INT'
                    );
--            logging_insert ('ECLIPSE',p_batch_id,2.1,p_file_name,NULL,SYSDATE);
          EXCEPTION
          WHEN OTHERS THEN
            logging_insert ('ECLIPSE',p_batch_id,2.1,SQLERRM,NULL,SYSDATE);
                                 END;
    END LOOP; 
    COMMIT;
   -- CLOSE eclipse_stage_hdr_data_cur; 

        dbms_output.put_line('HEADER exit');
        logging_insert ('ECLIPSE',p_batch_id,3,'ENDS - TEMP TABLE DATA TO HEADER TABLE DATA INSERTION',NULL,SYSDATE);

/********** PROCESS UNSTRUCTURED ECLIPSE TEMP TABLE DATA TO ECLIPSE LINE TABLE DATA - START *************/
        logging_insert ('ECLIPSE',p_batch_id,4,'STARTS - TEMP TABLE DATA TO LINE TABLE DATA INSERTION',NULL,SYSDATE);

    OPEN eclipse_stage_line_data_cur (p_batch_id);
                  LOOP
                               FETCH eclipse_stage_line_data_cur BULK COLLECT INTO lv_eclipse_stg_line_type LIMIT 4000;
                               EXIT WHEN lv_eclipse_stg_line_type.count = 0;

                  BEGIN
                               FORALL i IN 1..lv_eclipse_stg_line_type.count
          SAVE EXCEPTIONS

                               INSERT INTO WSC_AHCS_ECLIPSE_TXN_LINE_T
                               (
                                     BATCH_ID,
                LINE_ID,
                HEADER_ID,
                ACC_AMT,
                LEG_TRAN_DATE,
                CURRENCY,
                ACC_CURRENCY,
                LEG_BU,
                BU_UNIT_GL,
                TRANS_REF_NBR,
                SOURCE,
                LEG_ACCT,
                LEG_DEPT,
                LEG_LOC,
                LEG_AFFILIATE,
                LEG_LEDGER,
                LEDGER_GROUP,
                GL_LEGAL_ENTITY,
                GL_OPER_GRP,
                GL_ACCT,
                GL_DEPT,
                GL_SITE,
                GL_IC,
                GL_PROJECTS,
                GL_FUT_1,
                GL_FUT_2,
                LEG_VENDOR,
                TRANSACTION_NUMBER,
                AMOUNT,
                LEG_COA,
                LEG_SEG_1_4,
                LEG_SEG_5_7,
                DESCRIPTION,
                TARGET_COA,
                CREATION_DATE,
                LAST_UPDATE_DATE,
                CREATED_BY,
                LAST_UPDATED_BY,
                LINE_NUMBER
                                )
                               VALUES
                               (
                                    p_batch_id,  
               WSC_ECLIPSE_LINE_T_S1.NEXTVAL, --- line_id
               NULL, --- header_id
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,141,16)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,141,16)),NULL), --- acc_amt
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).data_string,16,10)),TO_DATE(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).data_string,16,10)),'MM/DD/YYYY'),NULL), --- leg_transaction_date
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,173,3)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,173,3)),NULL), --- currency
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,176,3)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,176,3)),NULL), --- acc_currency
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,1,5)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,1,5)),NULL), --- leg_bu
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,1,5)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,1,5)),NULL), --- bu_unit_gl
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,1,5)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,1,5)),NULL), --- trans_ref_number
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,218,3)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,218,3)),NULL), --- source
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,70,9)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,70,9)),NULL), --- LEG_ACCT
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,93,4)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,93,4)),NULL), --- leg_dept
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,88,5)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,88,5)),NULL), ---- LEG_LOC
               NULL,   --- '00000', --- leg_affliate
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,50,9)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,50,9)),NULL), --- leg_ledger
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,60,9)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,60,9)),NULL), --- ledger_group
               NULL, ----gl_legal_entity
               NULL, ----gl_operating_group
               NULL, ---gl_acct
               NULL, ---gl_dept
               NULL, ---gl_site
               NULL, ---gl_ic
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,104,7)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,104,7)),'0000'),--NULL, ---gl_projects
               NULL, ---gl_fut_1
               NULL, ---gl_fut_2
               '0000',---vendor
               p_file_name||'_'||TO_CHAR(TO_DATE(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).data_string,35,10)),'MM/DD/YYYY'),'YYYYMMDD'), ---- transaction number
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,157,16)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,157,16)),NULL), --- amount
               SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,1,5) || '.' ||  SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,88,5) ||   '.' ||  SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,93,4) || '.' || SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,70,9) || '.' || NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,126,10)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,126,10)),'0000') || '.' || NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,136,5)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,136,5)),'00000'), --- leg_coa(BU-LOC-DEPT-ACC-VENDOR-AFFILIATE)
               SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,1,5) || '.' ||  SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,88,5) || '.' ||  SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,70,9) || '.' || SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,93,4),     -- leg_seg_1_4   ---- BU-Location-Account-Dept
               '0000' || '.' || '00000', ---leg_seg_5_7, -- Vendor-Affiliate
               NVL2(TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,188,30)),TRIM(SUBSTR(lv_eclipse_stg_line_type(i).DATA_STRING,188,30)),NULL), --- description
               NULL, --- target_coa
               SYSDATE, --- creation_date
               SYSDATE, --- last_update_date
               'FIN_INT', --- created_by
               'FIN_INT', --- last_updated_by
               lv_eclipse_stg_line_type(i).row_line_num
                             );

                             EXCEPTION
        WHEN OTHERS THEN
        logging_insert ('ECLIPSE',p_batch_id,4.1,SQLERRM,NULL,SYSDATE);
                             -- logging_insert ('ECLIPSE',p_batch_id,4.1,'DATA_TYPE MISMATCH ERROR',NULL,SYSDATE);
                             END;
END LOOP;

dbms_output.put_line('LINE exit');
COMMIT;
CLOSE eclipse_stage_line_data_cur;

logging_insert('ECLIPSE',p_batch_id,5,'ENDS - TEMP TABLE DATA TO LINE TABLE DATA INSERTION',NULL,SYSDATE);

logging_insert('ECLIPSE', p_batch_id,6,'STARTS - UPDATING LINE TABLE WITH HEADER ID', NULL,SYSDATE);

UPDATE WSC_AHCS_ECLIPSE_TXN_LINE_T line
        SET header_id = 
          (
                SELECT  /*+ index(hdr WSC_AHCS_ECLIPSE_TXN_HEADER_HDR_SEQ_NBR_I) */
                    hdr.header_id
                FROM
                    WSC_AHCS_ECLIPSE_TXN_HEADER_T hdr
                WHERE
                     line.batch_id = hdr.batch_id
                     and line.LEG_TRAN_DATE = hdr.TRANSACTION_DATE
         ) 
        WHERE
              batch_id = p_batch_id;
COMMIT; 
logging_insert('ECLIPSE', p_batch_id, 7, 'ENDS - UPDATING LINE TABLE WITH HEADER ID', NULL,SYSDATE);

logging_insert('ECLIPSE', p_batch_id, 8, 'STARTS - INSERTING RECORDS IN COMMON STATUS TABLE', NULL,SYSDATE);
INSERT INTO wsc_ahcs_int_status_t (
                HEADER_ID,
                LINE_ID,
                APPLICATION,
                FILE_NAME,
                BATCH_ID,
                STATUS,
                CR_DR_INDICATOR,
                CURRENCY,
                VALUE,
                SOURCE_COA,
                LEGACY_HEADER_ID,
                LEGACY_LINE_NUMBER,
                ATTRIBUTE3,
                ATTRIBUTE11,
                CREATED_BY,
                CREATED_DATE,
                LAST_UPDATED_BY,
                LAST_UPDATED_DATE
                                  )
            SELECT
                line.header_id,
                line.line_id,
                p_application_name,
                p_file_name,
                p_batch_id,
                'NEW',
                decode(sign(line.ACC_AMT),-1,'CR','DR'),
                line.acc_currency,
                line.ACC_AMT,
                line.leg_coa,
                NULL,
                line.line_number,
                line.transaction_number,
                to_date(line.LEG_TRAN_DATE, 'DD-MON-YY'),
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
                WSC_AHCS_ECLIPSE_TXN_LINE_T  line,
                WSC_AHCS_ECLIPSE_TXN_HEADER_T  hdr
            WHERE
                line.batch_id = p_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id;
                             COMMIT;
logging_insert('ECLIPSE',p_batch_id,9,'ENDS - INSERTING RECORDS IN COMMON STATUS TABLE', NULL,SYSDATE);  

    EXCEPTION
    WHEN OTHERS THEN
             p_error_flag := '1';
             err_msg := SUBSTR(SQLERRM, 1, 200);
logging_insert('ECLIPSE', p_batch_id,10.1,'ERROR IN WSC_PROCESS_ECLIPSE_TEMP_TO_HEADER_LINE_P PROCEDURE',SQLERRM,SYSDATE);

wsc_ahcs_int_error_logging.error_logging(p_batch_id,'INT124'|| '_'|| l_system,'ECLIPSE',SQLERRM);

END "WSC_PROCESS_ECLIPSE_TEMP_TO_HEADER_LINE_P";
END WSC_ECLIPSE_PKG;
/