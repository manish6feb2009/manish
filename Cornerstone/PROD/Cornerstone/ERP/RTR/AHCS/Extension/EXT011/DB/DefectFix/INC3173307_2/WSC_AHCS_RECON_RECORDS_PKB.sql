CREATE OR REPLACE Package BODY FININT.WSC_AHCS_RECON_RECORDS_PKG IS

Procedure INSERT_REC(P_INS_VAL WSC_AHCS_RECON_REP_TEMP_T_TAB,
                     ERRBUF OUT VARCHAR2,
                     RETCODE OUT VARCHAR2) IS
L_TRX_NUMBER VARCHAR2(2000):= NULL;
L_ERR_MSG VARCHAR2(2000);
L_ERR_CODE VARCHAR2(2);
BEGIN


FOR i in P_INS_VAL.FIRST..P_INS_VAL.LAST LOOP
BEGIN
insert into WSC_AHCS_RECON_REP_TEMP_T values (P_INS_VAL(i).FILE_NAME,P_INS_VAL(i).TRX_NUMBER,P_INS_VAL(i).JOB_ID,P_INS_VAL(i).STATUS,P_INS_VAL(i).COMPLETION_DATE);
Commit;
Exception
    WHEN OTHERS THEN
        L_TRX_NUMBER:=L_TRX_NUMBER||P_INS_VAL(i).TRX_NUMBER;
 END;       
END LOOP;

 ERRBUF := L_TRX_NUMBER; 
 RETCODE := L_ERR_CODE;
EXCEPTION
 WHEN OTHERS THEN
  ERRBUF := 'Error while inserting';
  RETCODE := 2; 
END;

PROCEDURE CALL_ASYC_UPDATE(ERRBUF OUT VARCHAR2,
                     RETCODE OUT VARCHAR2) IS

BEGIN
dbms_scheduler.create_job (
  job_name   =>  'Update_WSC_AHCS_INT_STATUS'||WSC_AHCS_RECON_RECORDS_SEQ.nextval,
  job_type   => 'PLSQL_BLOCK',
  job_action => 
    'DECLARE
     L_ERR_MSG VARCHAR2(2000);
     L_ERR_CODE VARCHAR2(2);
     BEGIN 
       WSC_AHCS_RECON_RECORDS_PKG.UPDATE_REC(L_ERR_MSG,L_ERR_CODE);
     END;',
  enabled   =>  TRUE,  
  auto_drop =>  TRUE, 
  comments  =>  'Update_WSC_AHCS_INT_STATUS ');
END;  



PROCEDURE UPDATE_REC (ERRBUF OUT VARCHAR2, RETCODE OUT VARCHAR2)
IS
    L_ERR_MSG    VARCHAR2 (100) := NULL;
    L_COM_DATE   DATE;
BEGIN
    wsc_ahcs_recon_records_pkg.vlog ('UPDATE_REC BEGIN', 'UPDATE_REC');
    wsc_ahcs_recon_records_pkg.vlog ('Merge start', 'UPDATE_REC');

    MERGE INTO wsc_ahcs_int_status_t wais
         USING (SELECT Status,
                       JOB_ID,
                       trx_number,
                       File_Name
                  FROM WSC_AHCS_RECON_REP_TEMP_T) temp
            ON (    wais.attribute3 = temp.trx_number
                AND wais.file_name =
                    NVL (
                        SUBSTR (temp.File_Name,
                                1,
                                INSTR (temp.File_Name, '.', 1) - 1),
                        temp.File_Name))
    WHEN MATCHED
    THEN
        UPDATE SET
            wais.attribute4 =
                substr(NVL2 (attribute4, attribute4 || ',', NULL) || temp.JOB_ID,1,200),
            wais.attribute5 = temp.JOB_ID,
            wais.accounting_status = temp.status,
            wais.LAST_UPDATED_DATE = SYSDATE;

    wsc_ahcs_recon_records_pkg.vlog ('Updated Rows: ' || SQL%ROWCOUNT,
                                     'UPDATE_REC');
    wsc_ahcs_recon_records_pkg.vlog ('Merge Completed', 'UPDATE_REC');


    BEGIN
        wsc_ahcs_recon_records_pkg.vlog ('Select MAX Date start',
                                         'UPDATE_REC');

        SELECT MAX (Completion_date)
          INTO L_COM_DATE
          FROM WSC_AHCS_RECON_REP_TEMP_T;

        IF L_COM_DATE IS NOT NULL
        THEN
            UPDATE WSC_AHCS_REFRESH_T
               SET LAST_REFRESH_DATE = L_COM_DATE,
                   LAST_UPDATE_DATE = SYSDATE,
                   LAST_UPDATED_BY = 'Integration Program'
             WHERE DATA_ENTITY_NAME = 'WSC_AHCS_RECON_REPORT';

            wsc_ahcs_recon_records_pkg.vlog (
                'Updated Rows: ' || SQL%ROWCOUNT,
                'UPDATE_REC');

            wsc_ahcs_recon_records_pkg.vlog (
                'Select MAX date IF, L_COM_DATE:' || L_COM_DATE,
                'UPDATE_REC');
        END IF;

        wsc_ahcs_recon_records_pkg.vlog ('Select MAX date completed',
                                         'UPDATE_REC');
    END;

    COMMIT;
    wsc_ahcs_recon_records_pkg.vlog ('COMMIT completed', 'UPDATE_REC');

    BEGIN
        wsc_ahcs_recon_records_pkg.vlog (
            'BEGIN TRUNCATE WSC_AHCS_RECON_REP_TEMP_T',
            'UPDATE_REC');

        EXECUTE IMMEDIATE 'Truncate table WSC_AHCS_RECON_REP_TEMP_T';

        wsc_ahcs_recon_records_pkg.vlog (
            'TRUNCATE WSC_AHCS_RECON_REP_TEMP_T Completed',
            'UPDATE_REC');
    EXCEPTION
        WHEN OTHERS
        THEN
            --NULL;
            wsc_ahcs_recon_records_pkg.vlog (
                   'TRUNCATE WHEN OTHERS '
                || SUBSTR (SQLERRM, 1,500)
                || DBMS_UTILITY.format_error_backtrace,
                'UPDATE_REC');
    END;

    BEGIN
        wsc_ahcs_recon_records_pkg.vlog ('WSC_AHCS_DSHB2_UNI_REC_V refresh start',
                                 'UPDATE_REC');

        BEGIN
            DBMS_MVIEW.REFRESH('WSC_AHCS_DSHB2_UNI_REC_V','C'); -- independent
           -- DBMS_SNAPSHOT.REFRESH ('"FININT"."WSC_AHCS_DSHB2_UNI_REC_V"','C');
        EXCEPTION
            WHEN OTHERS
            THEN
                wsc_ahcs_recon_records_pkg.vlog (
                       'DBMS_SNAPSHOT.REFRESH WSC_AHCS_DSHB2_UNI_REC_V WHEN OTHERS '
                    || SUBSTR (SQLERRM, 1,500)
                    || DBMS_UTILITY.format_error_backtrace,
                    'UPDATE_REC');
        END;

        wsc_ahcs_recon_records_pkg.vlog (
            'WSC_AHCS_DSHB2_UNI_REC_V refresh completed',
            'UPDATE_REC');

        wsc_ahcs_recon_records_pkg.vlog (
            'WSC_AHCS_DASHBOARD1_V refresh start',
            'UPDATE_REC');

        BEGIN
            DBMS_MVIEW.REFRESH('WSC_AHCS_DASHBOARD1_V','C'); -- independent
            --DBMS_SNAPSHOT.REFRESH ('"FININT"."WSC_AHCS_DASHBOARD1_V"', 'C');
        EXCEPTION
            WHEN OTHERS
            THEN
                wsc_ahcs_recon_records_pkg.vlog (
                       'DBMS_SNAPSHOT.REFRESH WSC_AHCS_DASHBOARD1_V WHEN OTHERS '
                    || SUBSTR  (SQLERRM, 1,500)
                    || DBMS_UTILITY.format_error_backtrace,
                    'UPDATE_REC');
        END;

        wsc_ahcs_recon_records_pkg.vlog (
            'WSC_AHCS_DASHBOARD1_V refresh completed',
            'UPDATE_REC');

        wsc_ahcs_recon_records_pkg.vlog ('WSC_AHCS_DSHB2_DR_CR_V refresh start',
                                 'UPDATE_REC');

        BEGIN
            DBMS_MVIEW.REFRESH('WSC_AHCS_DSHB2_DR_CR_V','C'); -- dependent
            --DBMS_SNAPSHOT.REFRESH ('"FININT"."WSC_AHCS_DSHB2_DR_CR_V"', 'C');
        EXCEPTION
            WHEN OTHERS
            THEN
                wsc_ahcs_recon_records_pkg.vlog (
                       'DBMS_SNAPSHOT.REFRESH WSC_AHCS_DSHB2_DR_CR_V WHEN OTHERS '
                    || SUBSTR  (SQLERRM, 1,500)
                    || DBMS_UTILITY.format_error_backtrace,
                    'UPDATE_REC');
        END;

        wsc_ahcs_recon_records_pkg.vlog ('WSC_AHCS_DSHB2_DR_CR_V refresh completed',
                                 'UPDATE_REC');


        wsc_ahcs_recon_records_pkg.vlog ('WSC_AHCS_DSHB2_MAIN_V refresh start',
                                 'UPDATE_REC');

        BEGIN
            DBMS_MVIEW.REFRESH('WSC_AHCS_DSHB2_MAIN_V','C'); -- dependent
            --DBMS_SNAPSHOT.REFRESH ('"FININT"."WSC_AHCS_DSHB2_MAIN_V"', 'C');
        EXCEPTION
            WHEN OTHERS
            THEN
                wsc_ahcs_recon_records_pkg.vlog (
                       'DBMS_SNAPSHOT.REFRESH WSC_AHCS_DSHB2_MAIN_V WHEN OTHERS '
                    || SUBSTR (SQLERRM, 1,500)
                    || DBMS_UTILITY.format_error_backtrace,
                    'UPDATE_REC');
        END;

        wsc_ahcs_recon_records_pkg.vlog ('WSC_AHCS_DSHB2_MAIN_V refresh completed',
                                 'UPDATE_REC');

        wsc_ahcs_recon_records_pkg.vlog (
            'Truncate WSC_AHCS_DASHBOARD2_STAGE_T start',
            'UPDATE_REC');

        EXECUTE IMMEDIATE 'Truncate table WSC_AHCS_DASHBOARD2_STAGE_T';

        wsc_ahcs_recon_records_pkg.vlog (
            'Truncate WSC_AHCS_DASHBOARD2_STAGE_T Completed',
            'UPDATE_REC');

        --Insert into WSC_AHCS_DASHBOARD2_STAGE_T  select * from WSC_AHCS_DASHBOARD2_V;
        wsc_ahcs_recon_records_pkg.vlog (
            'Insert into WSC_AHCS_DASHBOARD2_STAGE_T start',
            'UPDATE_REC');

        INSERT INTO WSC_AHCS_DASHBOARD2_STAGE_T (APPLICATION,
                                                 ACCOUNTING_PERIOD,
                                                 INTERFACE_PROC_STATUS,
                                                 CREATE_ACC_STATUS,
                                                 TOTAL_CR,
                                                 TOTAL_DR,
                                                 NUM_ROWS,
                                                 DUMMY,
                                                 DUMMY4,
                                                 SOURCE_SYSTEM)
            SELECT APPLICATION,
                   ACCOUNTING_PERIOD,
                   INTERFACE_PROC_STATUS,
                   CREATE_ACC_STATUS,
                   TOTAL_CR,
                   TOTAL_DR,
                   NUM_ROWS,
                   DUMMY,
                   DUMMY4,
                   SOURCE_SYSTEM
              FROM WSC_AHCS_DASHBOARD2_V;

        wsc_ahcs_recon_records_pkg.vlog ('Inserted Rows: ' || SQL%ROWCOUNT,
                                         'UPDATE_REC');
        wsc_ahcs_recon_records_pkg.vlog (
            'Insert into WSC_AHCS_DASHBOARD2_STAGE_T completed ',
            'UPDATE_REC');

        wsc_ahcs_recon_records_pkg.vlog (
            'Truncate WSC_AHCS_DASHBOARD2_T start',
            'UPDATE_REC');

        EXECUTE IMMEDIATE 'Truncate table WSC_AHCS_DASHBOARD2_T';

        wsc_ahcs_recon_records_pkg.vlog (
            'Truncate WSC_AHCS_DASHBOARD2_T completed ',
            'UPDATE_REC');


        wsc_ahcs_recon_records_pkg.vlog (
            'Insert into WSC_AHCS_DASHBOARD2_STAGE_T start ',
            'UPDATE_REC');

        --Insert into WSC_AHCS_DASHBOARD2_T  select * from WSC_AHCS_DASHBOARD2_STAGE_T;
        INSERT INTO WSC_AHCS_DASHBOARD2_T (APPLICATION,
                                           ACCOUNTING_PERIOD,
                                           INTERFACE_PROC_STATUS,
                                           CREATE_ACC_STATUS,
                                           TOTAL_CR,
                                           TOTAL_DR,
                                           NUM_ROWS,
                                           DUMMY,
                                           DUMMY4,
                                           SOURCE_SYSTEM)
            SELECT APPLICATION,
                   ACCOUNTING_PERIOD,
                   INTERFACE_PROC_STATUS,
                   CREATE_ACC_STATUS,
                   TOTAL_CR,
                   TOTAL_DR,
                   NUM_ROWS,
                   DUMMY,
                   DUMMY4,
                   SOURCE_SYSTEM
              FROM WSC_AHCS_DASHBOARD2_STAGE_T;

        wsc_ahcs_recon_records_pkg.vlog (
            'Insert into WSC_AHCS_DASHBOARD2_STAGE_T completed ',
            'UPDATE_REC');

        wsc_ahcs_recon_records_pkg.vlog ('update WSC_AHCS_REFRESH_T start ',
                                         'UPDATE_REC');

        UPDATE WSC_AHCS_REFRESH_T
           SET LAST_REFRESH_DATE = SYSDATE,
               LAST_UPDATE_DATE = SYSDATE,
               LAST_UPDATED_BY = 'Integration Program'
         WHERE DATA_ENTITY_NAME = 'WSC_AHCS_DASHBOARD2_REFRESH';

        wsc_ahcs_recon_records_pkg.vlog ('Inserted Rows: ' || SQL%ROWCOUNT,
                                         'UPDATE_REC');

        wsc_ahcs_recon_records_pkg.vlog (
            'update WSC_AHCS_REFRESH_T completed ',
            'UPDATE_REC');

        wsc_ahcs_recon_records_pkg.vlog ('COMMIT start ', 'UPDATE_REC');

        COMMIT;
        wsc_ahcs_recon_records_pkg.vlog ('COMMIT completed ', 'UPDATE_REC');

        wsc_ahcs_recon_records_pkg.vlog ('UPDATE_REC END', 'UPDATE_REC');
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END;
EXCEPTION
    WHEN OTHERS
    THEN
        ERRBUF := 'ERROR While Updating Records';
        RETCODE := 2;

        wsc_ahcs_recon_records_pkg.vlog (
               'Main WHEN OTHERS '
            || SUBSTR (SQLERRM, 1,500)
            || DBMS_UTILITY.format_error_backtrace,
            'UPDATE_REC');

        wsc_ahcs_recon_records_pkg.vlog (
            'Main WHEN OTHERS, ERRBUF: ' || ERRBUF || ' RETCODE: ' || RETCODE,
            'UPDATE_REC');
END;


PROCEDURE REFRESH_VALIDATION_OIC(RECTCODE OUT NUMBER,
                                ERRBUF OUT VARCHAR2) IS 

begin
 wsc_ahcs_recon_records_pkg.vlog('REFRESH_VALIDATION_OIC BEGIN','REFRESH_VALIDATION_OIC');
 
 wsc_ahcs_recon_records_pkg.vlog('WSC_AHCS_DASHBOARD1_V refresh start', 
                                'REFRESH_VALIDATION_OIC');
                                
 DBMS_MVIEW.REFRESH('WSC_AHCS_DASHBOARD1_V','C');

wsc_ahcs_recon_records_pkg.vlog('WSC_AHCS_DASHBOARD1_V refresh completed', 
                                'REFRESH_VALIDATION_OIC');

wsc_ahcs_recon_records_pkg.vlog('REFRESH_VALIDATION_OIC END','REFRESH_VALIDATION_OIC');

Exception
    WHEN OTHERS THEN
    --NULL;
    ERRBUF := 'ERROR While Updating Records'; 
    RECTCODE :=2;
        wsc_ahcs_recon_records_pkg.vlog('Main WHEN OTHERS '|| SUBSTR(SQLERRM,1,500) || DBMS_UTILITY.format_error_backtrace
    ,'REFRESH_VALIDATION_OIC');
    
    wsc_ahcs_recon_records_pkg.vlog('Main WHEN OTHERS, ERRBUF: '|| ERRBUF ||' RETCODE: '|| RECTCODE
    ,'REFRESH_VALIDATION_OIC'); 
    
end;


PROCEDURE vlog(p_message IN VARCHAR2
,p_location IN VARCHAR2
)  
IS
PRAGMA AUTONOMOUS_TRANSACTION;
--g_debug_flag   VARCHAR2(1) := 'Y'; -- global variable
BEGIN
--    IF g_debug_flag = 'Y' THEN

    DELETE FININT.WSC_AHCS_RECON_DEBUG_T
    WHERE CREATION_DATE <=  SYSDATE -10;


        INSERT INTO FININT.WSC_AHCS_RECON_DEBUG_T (DEBUG_ID,
                                 MESSAGE,
                                 LOCATION,
                                 CREATED_BY,
                                 CREATION_DATE
                                 )
     VALUES ( WSC_AHCS_DEBUG_SEQ.NEXTVAL,
             p_message,
             p_location,
             1,
             SYSDATE
             );
             COMMIT;
  --  END IF;

    COMMIT;
  

 EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      /*DBMS_OUTPUT.put_line (
            'Error!: ' || SQLERRM || DBMS_UTILITY.format_error_backtrace); */
END vlog;


END WSC_AHCS_RECON_RECORDS_PKG;
/