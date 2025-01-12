create or replace PACKAGE BODY          "WSC_SXE_PKG" AS
    PROCEDURE "WSC_SXE_INSERT_DATA_TEMP_P" (
        in_wsc_sxe_stage IN WSC_SXE_TMP_T_TYPE_TABLE
    ) AS
    BEGIN
        FORALL i IN 1..in_wsc_sxe_stage.count
            INSERT INTO WSC_AHCS_SXE_TXN_TMP_T (
                batch_id,
                rice_id,
                data_string,
                line_number
            ) VALUES (
                in_wsc_sxe_stage(i).batch_id,
                in_wsc_sxe_stage(i).rice_id,
                in_wsc_sxe_stage(i).data_string,
                wsc_sxe_tmp_line_nbr_s1.nextval
            );
	COMMIT;

    END "WSC_SXE_INSERT_DATA_TEMP_P";

    PROCEDURE "WSC_SXE_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P" (
        p_batch_id          IN  NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2
    ) AS
        err_msg VARCHAR2(4000);
        p_error_flag varchar2(2);
    BEGIN
        logging_insert('SXE', p_batch_id, 1, 'Start ASYNC DB Scheduler job for SXE', NULL,sysdate);
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;

        COMMIT;
         dbms_scheduler.create_job(job_name => 'INVOKE_WSC_PROCESS_SXE_TEMP_TO_HEADER_LINE' || p_batch_id,
                                 job_type => 'PLSQL_BLOCK',
                                 job_action => '
                                 DECLARE
                                    p_error_flag VARCHAR2(2);
                                 BEGIN                                
         WSC_SXE_PKG.WSC_PROCESS_SXE_TEMP_TO_HEADER_LINE_P('
                                               || p_batch_id
                                               || ','''
                                               || p_application_name
                                               || ''','''
                                               || p_file_name
                                               || ''',
                                                p_error_flag
                                                );
        if p_error_flag = '||'''0'''||' then                                   
         wsc_ahcs_sxe_validation_transformation_pkg.data_validation('
                                               || p_batch_id
                                               || ');

          end if;                                   
       END;',
                                 enabled => true,
                                 auto_drop => true,
                                 comments => 'Async insert data into header and line tables. Also, update line table, insert into WSC_AHCS_INT_STATUS_T and call Validation and Transformation procedure');

    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('SXE', p_batch_id, 5.1, 'Error in Async DB Proc', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            COMMIT;
            dbms_output.put_line(sqlerrm);
    END "WSC_SXE_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P";  

PROCEDURE "WSC_PROCESS_SXE_TEMP_TO_HEADER_LINE_P" (
        p_batch_id IN NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2,
        p_error_flag OUT VARCHAR2
) IS

    v_error_msg            VARCHAR2(200);
    v_stage                VARCHAR2(200);
    lv_count  NUMBER;
    err_msg   VARCHAR2(2000);
    l_system  VARCHAR2(200);

CURSOR sxe_stage_line_data_cur (
                               p_batch_id NUMBER
                               ) IS
        SELECT temp.*,
            ROW_NUMBER()
            OVER(
                ORDER BY
                    line_number
            ) AS row_line_num
     FROM WSC_AHCS_SXE_TXN_TMP_T temp
    WHERE batch_id = p_batch_id; 


    TYPE sxe_stage_line_type IS
        TABLE OF sxe_stage_line_data_cur%rowtype;
    lv_sxe_stg_line_type  sxe_stage_line_type;
	
	
	CURSOR sxe_stage_hdr_data_cur(
                                    p_batch_id NUMBER
                                  ) IS
		select distinct TO_DATE(TRIM(SUBSTR(data_string,35,10)),'MM/DD/YYYY') LEG_TRAN_DATE
from wsc_ahcs_sxe_txn_tmp_t where batch_id = p_batch_id;
								  
								  
								  
	TYPE sxe_stage_hdr_type IS
    TABLE OF sxe_stage_hdr_data_cur%rowtype;
    lv_sxe_stg_hdr_type sxe_stage_hdr_type;
	
    BEGIN
   --initialise p_error_flag with 0
    begin
    p_error_flag := '0';

    exception 
    when others then
        logging_insert ('SXE',p_batch_id,1.1,'value of error flag',sqlerrm,sysdate);
    end; 

BEGIN
    SELECT attribute3
    INTO l_system
    FROM wsc_ahcs_int_control_t c
    WHERE c.batch_id = p_batch_id; 
	dbms_output.put_line(l_system);
   END;
    dbms_output.put_line(' Begin inserting records into header line table');
    /********** PROCESS STAGE TABLE DATA TO HEADER TABLE DATA - START *************/
    logging_insert ('SXE',p_batch_id,2,'INSERT DATA TO HEADER TABLE DATA - START',NULL,sysdate);
	
	OPEN sxe_stage_hdr_data_cur(p_batch_id);
        LOOP
            FETCH sxe_stage_hdr_data_cur BULK COLLECT INTO lv_sxe_stg_hdr_type LIMIT 4000;
        EXIT WHEN lv_sxe_stg_hdr_type.COUNT = 0;
        BEGIN
           FORALL i IN 1..lv_sxe_stg_hdr_type.COUNT
             SAVE EXCEPTIONS
			 
			INSERT INTO WSC_AHCS_SXE_TXN_HEADER_T(
			HEADER_ID,
			BATCH_ID,
			TRANSACTION_DATE,
			TRANSACTION_NUMBER,
            LEDGER_NAME,
			FILE_NAME,
			CREATION_DATE,
			LAST_UPDATE_DATE,
			CREATED_BY,
			LAST_UPDATED_BY,
			ATTRIBUTE1,
			ATTRIBUTE2,
			ATTRIBUTE3,
			ATTRIBUTE4,
			ATTRIBUTE5,
			ATTRIBUTE6,
			ATTRIBUTE7,
			ATTRIBUTE8,
			ATTRIBUTE9,
			ATTRIBUTE10,
			TRANSACTION_TYPE,
			SOURCE
			)
			VALUES(
			wsc_sxe_header_t_s1.NEXTVAL,
                p_batch_id,	
				lv_sxe_stg_hdr_type(i).LEG_TRAN_DATE,
				p_file_name||'_'||TO_CHAR(lv_sxe_stg_hdr_type(i).LEG_TRAN_DATE,'YYYYMMDD'), --||to_date(TRIM(SUBSTR(temp.data_string,35,10)),'MM/DD/YYYY'), -- Transaction_number
				NULL,
                p_file_name,
                sysdate,
				sysdate,
                'FIN_INT',
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
		 EXCEPTION
          WHEN OTHERS THEN
            logging_insert ('SXE',p_batch_id,2.1,SQLERRM,NULL,SYSDATE);
                                 END;
    END LOOP; 
    COMMIT;
 
	
	
     /* begin
            INSERT INTO WSC_AHCS_SXE_TXN_HEADER_T(
			HEADER_ID,
			BATCH_ID,
			TRANSACTION_DATE,
			TRANSACTION_NUMBER,
            LEDGER_NAME,
			FILE_NAME,
			CREATION_DATE,
			LAST_UPDATE_DATE,
			CREATED_BY,
			LAST_UPDATED_BY,
			ATTRIBUTE1,
			ATTRIBUTE2,
			ATTRIBUTE3,
			ATTRIBUTE4,
			ATTRIBUTE5,
			ATTRIBUTE6,
			ATTRIBUTE7,
			ATTRIBUTE8,
			ATTRIBUTE9,
			ATTRIBUTE10,
			TRANSACTION_TYPE,
			SOURCE
            ) SELECT 
                wsc_sxe_header_t_s1.NEXTVAL,
                p_batch_id,	
				nvl2(TRIM(SUBSTR(temp.data_string,35,10)),to_date(TRIM(SUBSTR(temp.data_string,35,10)),'MM/DD/YYYY'),NULL),
				p_file_name||to_date(TRIM(SUBSTR(temp.data_string,35,10)),'MM/DD/YYYY'), -- Transaction_number
				NULL,
                p_file_name,
                sysdate,
				sysdate,
                'FIN_INT',
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
                FROM 
                WSC_AHCS_SXE_TXN_TMP_T temp
                WHERE
                temp.batch_id = p_batch_id
                and rownum=1;

            COMMIT;
            EXCEPTION
                    WHEN OTHERS THEN
                    logging_insert ('SXE',p_batch_id,4.11,sqlerrm,NULL,sysdate);
		END; */
   /* logging_insert('SXE', p_batch_id, 2.3, 'value of error flag', p_error_flag,sysdate);
    CLOSE sxe_stage_hdr_data_cur;
    EXCEPTION
        WHEN OTHERS THEN
            p_error_flag := '1';
             err_msg := substr(sqlerrm, 1, 200);
             wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT123'
                                                    || '_'
                                                    || l_system,
                                                    'SXE',
                                                    sqlerrm); */

   -- END;
   -- logging_insert('SXE', p_batch_id, 2.4, 'value of error flag at header level', p_error_flag, sysdate);
    dbms_output.put_line('HEADER exit');
   -- COMMIT;
    logging_insert ('SXE',p_batch_id,3,'INSERT DATA TO HEADER TABLE DATA - END',NULL,sysdate);


 /********** PROCESS UNSTRUCTURED TEMP TABLE DATA TO LINE TABLE DATA - START *************/
    dbms_output.put_line('Insert Data into Line Table');
    logging_insert ('SXE',p_batch_id,4,'STAGE TABLE DATA TO LINE TABLE DATA - START',NULL,sysdate);

    OPEN sxe_stage_line_data_cur(p_batch_id);
    LOOP
        FETCH sxe_stage_line_data_cur BULK COLLECT INTO lv_sxe_stg_line_type LIMIT 400;
        EXIT WHEN lv_sxe_stg_line_type.count = 0;
	BEGIN
        FORALL i IN 1..lv_sxe_stg_line_type.count
           INSERT INTO WSC_AHCS_SXE_TXN_LINE_T (
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
				ATTRIBUTE1,
				ATTRIBUTE2,
				ATTRIBUTE3,
				ATTRIBUTE4,
				ATTRIBUTE5,
				ATTRIBUTE6,
				ATTRIBUTE7,
				ATTRIBUTE8,
				ATTRIBUTE9,
				ATTRIBUTE10,
				LINE_NUMBER
				) VALUES (
                p_batch_id,
                wsc_sxe_line_t_s1.NEXTVAL,
                NULL, --header_id
				nvl2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,141,16)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,141,16)),NULL),--acc_amt
				nvl2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,16,10)),to_date(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,16,10)),'MM/DD/YYYY'),NULL),--leg_trn_date
				nvl2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,176,3)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,176,3)),NULL),--currency
				nvl2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,173,3)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,173,3)),NULL),--acc_curr
				nvl2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,0,5)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,0,5)),NULL),
				--leg_bu 
				nvl2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,45,5)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,45,5)),NULL),
				--bu_unit_gl
				nvl2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,180,8)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,180,8)),NULL), --TRANS_REF_NBR
				nvl2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,218,3)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,218,3)),NULL),
				--SOURCE
				nvl2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,70,9)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,70,9)),NULL),
				--LEG_ACCT
				nvl2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,93,4)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,93,4)),NULL),
			    ---LEG_DEPT
				nvl2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,88,5)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,88,5)),NULL),
				--LEG_LOC
				NULL, --LEG_AFFILIATE default '00000'
				nvl2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,50,10)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,50,10)),NULL),
				--LEG_LEDGER
				nvl2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,60,10)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,60,10)),NULL),
				--LEDGER_GROUP
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				'0000', --LEG_VENDOR
				p_file_name||'_'||TO_CHAR(TO_DATE(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,35,10)),'MM/DD/YYYY'),'YYYYMMDD'), ---TRANSACTION_NUMBER
				nvl2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,157,16)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,157,16)),NULL),
				--AMOUNT
				SUBSTR(TRIM(lv_sxe_stg_line_type(i).data_string),0,5) || '.' || SUBSTR(TRIM(lv_sxe_stg_line_type(i).data_string),88,5) || '.' || SUBSTR(TRIM(lv_sxe_stg_line_type(i).data_string),93,4) || '.' || SUBSTR(TRIM(lv_sxe_stg_line_type(i).data_string),70,9) || '.' || NVL2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).DATA_STRING,126,10)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).DATA_STRING,126,10)),'0000') || '.' || NVL2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).DATA_STRING,136,5)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).DATA_STRING,136,5)),'00000'), ---leg_coa--(BU-LOC-DEPT-ACC-VENDOR-AFFILIATE)
				SUBSTR(TRIM(lv_sxe_stg_line_type(i).data_string),0,5) || '.' || SUBSTR(TRIM(lv_sxe_stg_line_type(i).data_string),88,5) || '.' || SUBSTR(TRIM(lv_sxe_stg_line_type(i).data_string),70,9) || '.' || SUBSTR(TRIM(lv_sxe_stg_line_type(i).data_string),93,4),    
				-- Concatenated value for BU-Location-Account-Dept --- leg_coa_seg_1_4
				'0000' || '.' || '00000',  -- Concatenated value for Vendor-Affiliate
				nvl2(TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,188,30)),TRIM(SUBSTR(lv_sxe_stg_line_type(i).data_string,188,30)),NULL),
				NULL,
				sysdate,
				sysdate,
				'FIN_INT',
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
				lv_sxe_stg_line_type(i).row_line_num
                  );
/********** PROCESS UNSTRUCTURED STAGE TABLE DATA TO LINE TABLE DATA - END *************/
	EXCEPTION
        WHEN OTHERS THEN
        logging_insert ('SXE',p_batch_id,5.1,sqlerrm,NULL,sysdate);
		END;
    END LOOP;
 /*logging_insert('SXE', p_batch_id, 2.5, 'value of error flag', p_error_flag,
      sysdate);
    CLOSE sxe_stage_line_data_cur;
    EXCEPTION
        WHEN OTHERS THEN
            p_error_flag := '1';
            err_msg := substr(sqlerrm, 1, 200);
             wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT218'
                                                    || '_'
                                                    || l_system,
                                                    'SXE',
                                                    sqlerrm);  */

   -- END;
  --  logging_insert('SXE', p_batch_id, 2.6, 'value of error flag at line level', p_error_flag,sysdate);
    dbms_output.put_line('LINE exit');
    COMMIT;
CLOSE sxe_stage_line_data_cur;
    logging_insert ('SXE',p_batch_id,5,'Temp TABLE DATA TO LINE TABLE DATA - END',NULL,sysdate);

    logging_insert('SXE', p_batch_id, 6, 'Updating SXE Line table with header id starts', NULL,
                      sysdate);


        UPDATE WSC_AHCS_SXE_TXN_LINE_T line
        SET
            ( header_id) --,leg_coa )
			= (
                SELECT  /*+ index(hdr WSC_AHCS_SXE_TXN_HDR_T_PK) */
                    hdr.header_id --,leg_coa
                FROM
                    WSC_AHCS_SXE_TXN_HEADER_T hdr
                WHERE
                    line.batch_id = hdr.batch_id
					AND line.LEG_TRAN_DATE = hdr.TRANSACTION_DATE
            )
        --and rownum =1)
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        logging_insert('SXE', p_batch_id, 7, 'Updating SXE Line table with header id ends', NULL,
                      sysdate);
        logging_insert('SXE', p_batch_id, 8, 'Inserting records in status table starts', NULL,
                      sysdate);
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
                to_date(hdr.TRANSACTION_DATE, 'DD-MON-YY'),
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
                WSC_AHCS_SXE_TXN_LINE_T    line,
                WSC_AHCS_SXE_TXN_HEADER_T  hdr
            WHERE
                    line.batch_id = p_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id;

        COMMIT;
        logging_insert('SXE', p_batch_id, 9, 'Inserting records in status table ends', NULL,
                      sysdate);    
    EXCEPTION
        WHEN OTHERS THEN
           p_error_flag := '1';
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('SXE', p_batch_id, 9.1,
                          'Error in WSC_PROCESS_SXE_STAGE_TO_HEADER_LINE proc',
                          sqlerrm,
                          sysdate);
            wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT123'
                                                    || '_'
                                                    || l_system,
                                                    'SXE',
                                                    sqlerrm);

            dbms_output.put_line(sqlerrm);
    END "WSC_PROCESS_SXE_TEMP_TO_HEADER_LINE_P";


    end WSC_SXE_PKG;
/