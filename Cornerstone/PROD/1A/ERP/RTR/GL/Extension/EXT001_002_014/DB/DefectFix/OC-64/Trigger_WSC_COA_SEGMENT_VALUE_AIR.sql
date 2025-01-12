 SET DEFINE OFF;
 CREATE OR REPLACE EDITIONABLE TRIGGER "FININT"."WSC_COA_SEGMENT_VALUE_AIR" 
    AFTER 
    INSERT
    ON WSC_GL_COA_SEGMENT_VALUE_T
    FOR EACH ROW   
    Declare
   PRAGMA AUTONOMOUS_TRANSACTION;  
BEGIN

    dbms_scheduler.create_job (
      job_name   =>  'Update_COA_DISABLE_FLAG_AIR'||WSC_GL_COA_DISABLE_SEQ.nextval,
      job_type   => 'PLSQL_BLOCK',
      job_action => 
        'BEGIN 
           WSC_DISABLED_COA_HANDLE_PKG.WSC_DISABLED_COA_HANDLE_PRC('||NVL(''''||:new.SOURCE_SEGMENT1||'''','NULL')||','||NVL(''''||:new.SOURCE_SEGMENT2||'''','NULL')||','||NVL(''''||:new.SOURCE_SEGMENT3||'''','NULL')||','||NVL(''''||:new.SOURCE_SEGMENT4||'''','NULL')||','||NVL(''''||:new.SOURCE_SEGMENT5||'''','NULL')||','||NVL(''''||:new.SOURCE_SEGMENT6||'''','NULL')||','||NVL(''''||:new.SOURCE_SEGMENT7||'''','NULL')||','||NVL(''''||:new.SOURCE_SEGMENT8||'''','NULL')||','||NVL(''''||:new.SOURCE_SEGMENT9||'''','NULL')||','||NVL(''''||:new.SOURCE_SEGMENT10||'''','NULL')||','||:new.rule_id||');
         END;',
      enabled   =>  TRUE,  
      auto_drop =>  TRUE, 
      comments  =>  'Update_COA_DISABLE_FLAG_AIR ');

END;
Commit;