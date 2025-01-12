CREATE OR REPLACE PACKAGE BODY DGTL_PLS.WSC_DGTL_PLS_PURGING_PKG
AS
    PROCEDURE VLOG (p_message IN VARCHAR2, p_location IN VARCHAR2)
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        DELETE DGTL_PLS.WSC_DGTL_PLS_DEBUG_T
         WHERE CREATION_DATE <= SYSDATE - 30;


        INSERT INTO DGTL_PLS.WSC_DGTL_PLS_DEBUG_T (DEBUG_ID,
                                                   MESSAGE,
                                                   LOCATION,
                                                   CREATED_BY,
                                                   CREATION_DATE)
             VALUES (DGTL_PLS.WSC_DGTL_PLS_DEBUG_SEQ.NEXTVAL,
                     SUBSTR (p_message, 1, 1000),
                     p_location,
                     1,
                     SYSDATE);



        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
    /*DBMS_OUTPUT.put_line (
          'Error!: ' || SQLERRM || DBMS_UTILITY.format_error_backtrace); */
    END VLOG;

    PROCEDURE delete_old_data (P_RETENTION_PERIOD IN NUMBER)
    IS
        lv_date_threshold   DATE := ADD_MONTHS (SYSDATE, -P_RETENTION_PERIOD); -- to get the threshold date based on P_RETENTION_PERIOD
        c_location          VARCHAR2 (100) := 'delete_old_data'; -- to indicate location in log records
        lv_errm             VARCHAR (1000);         -- to store runtime errors
        lv_err_count        NUMBER := 0;                    -- to count errors
    BEGIN
        VLOG ('Begin', c_location);

        BEGIN
           <<Start_Table1>>
            DELETE FROM
                DGTL_PLS.XX_IMD_ADDITIONAL_INFO_T add_info
                  WHERE EXISTS
                            (SELECT 1
                               FROM DGTL_PLS.XX_IMD_INTEGRATION_ACTIVITY_T
                                    act
                              WHERE     act.id =
                                        add_info.integration_activity_id
                                    AND act.ACTIVITY_DATE < lv_date_threshold);

            VLOG (
                'Deleted XX_IMD_ADDITIONAL_INFO_T rowcount: ' || SQL%ROWCOUNT,
                c_location);
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_err_count := lv_err_count + 1;    -- Increase errors counts
                lv_errm :=
                       lv_errm
                    || 'EXCEPTION: XX_IMD_ADDITIONAL_INFO_T, SQLERRM: '
                    || SQLERRM;
                VLOG (lv_errm, c_location);
        END;


        BEGIN
           <<Start_Table2>>
            DELETE FROM DGTL_PLS.XX_IMD_INTEGRATION_ACTIVITY_T
                  WHERE ACTIVITY_DATE < lv_date_threshold;

            VLOG (
                   'Deleted XX_IMD_INTEGRATION_ACTIVITY_T rowcount: '
                || SQL%ROWCOUNT,
                c_location);
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_err_count := lv_err_count + 1;    -- Increase errors counts
                lv_errm :=
                       lv_errm
                    || 'EXCEPTION: XX_IMD_INTEGRATION_ACTIVITY_T, SQLERRM: '
                    || SQLERRM;
                VLOG (lv_errm, c_location);
        END;

        BEGIN
           <<Start_Table3>>
            DELETE FROM DGTL_PLS.XX_IMD_INTEGRATION_RUN_T
                  WHERE START_TIME < lv_date_threshold;

            VLOG (
                'Deleted XX_IMD_INTEGRATION_RUN_T rowcount: ' || SQL%ROWCOUNT,
                c_location);
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_err_count := lv_err_count + 1;    -- Increase errors counts
                lv_errm :=
                       lv_errm
                    || 'EXCEPTION: XX_IMD_INTEGRATION_RUN_T, SQLERRM: '
                    || SQLERRM;

                VLOG (lv_errm, c_location);
        END;


        BEGIN
           <<Start_Table4>>
            DELETE FROM DGTL_PLS.XX_IMD_JOB_RUN_T
                  WHERE START_TIME < lv_date_threshold;

            VLOG ('Deleted XX_IMD_JOB_RUN_T rowcount: ' || SQL%ROWCOUNT,
                  c_location);
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_err_count := lv_err_count + 1;    -- Increase errors counts
                lv_errm :=
                       lv_errm
                    || 'EXCEPTION: XX_IMD_JOB_RUN_T, SQLERRM: '
                    || SQLERRM;
                VLOG (lv_errm, c_location);
        END;

        VLOG ('lv_err_count: ' || lv_err_count, c_location);

        -- If a error happen in the plsql blocks, calling notification procedure and perform rollback
        IF lv_err_count > 0
        THEN
            lv_errm := lv_errm || ',SQLERRM: ' || SQLERRM;
            lv_errm := SUBSTR (lv_errm, 1, 1000);
            finint.wsc_ahcs_int_error_logging.ERROR_LOGGING_PURGING_NOTIFICATION (
                '',
                'INT_PURGE_002',
                'PURGE_PROCESS',
                lv_errm);
            ROLLBACK;
            VLOG ('ROLLBACK', c_location);
        ELSE
            -- if no erros found in plsql blocks then perform commit
            COMMIT;
            VLOG ('COMMIT', c_location);
        END IF;

        VLOG ('End', c_location);
    -- Main Exeception
    EXCEPTION
        WHEN OTHERS
        THEN
            lv_errm := lv_errm || ',SQLERRM: ' || SQLERRM;
            lv_errm := SUBSTR (lv_errm, 1, 1000);
            VLOG ('Main Exception ' || lv_errm, c_location);
            finint.wsc_ahcs_int_error_logging.ERROR_LOGGING_PURGING_NOTIFICATION (
                '',
                'INT_PURGE_002',
                'PURGE_PROCESS',
                lv_errm);
            ROLLBACK;
    END delete_old_data;


    PROCEDURE purge_records_async (P_RETENTION_PERIOD IN NUMBER)
    IS
        c_location   VARCHAR2 (100) := 'purge_records_async';
    BEGIN
        VLOG ('Begin', c_location);
        VLOG ('P_RETENTION_PERIOD: ' || P_RETENTION_PERIOD, c_location);
        VLOG ('Before post_booking_flow_job', c_location);

        DBMS_SCHEDULER.create_job (
            job_name     =>
                   'DGTL_PLS_PURGE_DATA'
                || TO_CHAR (SYSDATE, 'DDMMYYYYHH24MISS'),
            job_type     => 'PLSQL_BLOCK',
            job_action   =>
                   'BEGIN 
       WSC_DGTL_PLS_PURGING_PKG.delete_old_data('
                || P_RETENTION_PERIOD
                || ');
     END;',
            enabled      => TRUE,
            auto_drop    => TRUE,
            comments     => 'Purging Records from DGTL_PLS Tables');
        VLOG ('End', c_location);
    EXCEPTION
        WHEN OTHERS
        THEN
            VLOG (SQLERRM, c_location);
    END purge_records_async;
END WSC_DGTL_PLS_PURGING_PKG;
/
