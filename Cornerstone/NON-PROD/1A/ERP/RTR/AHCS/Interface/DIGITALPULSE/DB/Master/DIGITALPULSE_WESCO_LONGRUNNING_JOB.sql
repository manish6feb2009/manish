BEGIN
  DBMS_SCHEDULER.create_job (
    job_name        => 'WESCO_LONGRUNNING_JOB',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN XX_APEX_GET_ESS_DET_SEC_PKG.get_reqID; END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'freq=hourly; interval=1; byminute=0; bysecond=0;',
    enabled         => TRUE);
END;
/   


BEGIN 
    DBMS_SCHEDULER.enable('WESCO_LONGRUNNING_JOB'); 
END;
/