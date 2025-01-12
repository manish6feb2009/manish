declare
    batch_id number := WSC_CCID_MISMATCH_BATCH_ID.nextval;
BEGIN


    HTP.FLUSH;
    HTP.INIT;
    -- insert into wsc_tbl_time_t values(:P_USER_NAME||'_'||:P_COA_MAP_ID,sysdate,909090990);
    -- commit;

    dbms_scheduler.create_job (
    job_name   =>  'WSC_CCID_MISMATCH_REPORT_UPDATE_'||batch_id,
    job_type   => 'PLSQL_BLOCK',
    job_action => 
        'DECLARE
        L_ERR_MSG VARCHAR2(2000);
        L_ERR_CODE VARCHAR2(2);
        BEGIN 
            WSC_CCID_MISMATCH_REPORT.WSC_CCID_UPDATE('''||:P_USER_NAME||''','''||:P_COA_MAP_ID||''');
        END;',
    enabled   =>  TRUE,  
    auto_drop =>  TRUE, 
    comments  =>  'WSC_CCID_MISMATCH_REPORT');

    owa_util.redirect_url('f?p=&APP_ID.:9:&APP_SESSION.');

    exception
    when others then
        null;
    END;