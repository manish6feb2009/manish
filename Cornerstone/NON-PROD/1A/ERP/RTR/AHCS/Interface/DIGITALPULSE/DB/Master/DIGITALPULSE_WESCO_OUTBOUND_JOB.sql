BEGIN
  DBMS_SCHEDULER.create_job (
    job_name        => 'WESCO_OUTBOUND_JOB',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN XX_APEX_GET_ESS_DET_SEC_PKG.get_reqID_outbound; END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'freq=hourly; interval=1; byminute=0; bysecond=0;',
    enabled         => TRUE);
END;
/   


BEGIN 
    DBMS_SCHEDULER.enable('WESCO_OUTBOUND_JOB'); 
END;
/
