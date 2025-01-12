BEGIN
  DBMS_SCHEDULER.create_job (
    job_name        => 'WESCO_GATHER_STAT_JOB',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN DBMS_STATS.GATHER_SCHEMA_STATS('''||'FININT'||''',DBMS_STATS.AUTO_SAMPLE_SIZE); END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'freq=daily; byhour=7',
    enabled         => TRUE);
END;
/