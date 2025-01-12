set define off;
create or replace TRIGGER  "WSC_CCID_MAPPING_BUR" BEFORE UPDATE ON WSC_GL_CCID_MAPPING_T
FOR EACH ROW
BEGIN
 :NEW.LAST_UPDATE_DATE:= SYSDATE;
  :new.version := WSC_GL_COA_DISABLE_VER_SEQ.nextval;
END;
/
create or replace TRIGGER  "WSC_COA_CCID_BIR" BEFORE INSERT ON WSC_GL_CCID_MAPPING_T
FOR EACH ROW
  WHEN (new."CCID_VALUE_ID" IS NULL) BEGIN
  SELECT WSC_GL_CCID_MAPPING_S.NEXTVAL,SYSDATE,SYSDATE 
  INTO :new."CCID_VALUE_ID" ,:new."CREATION_DATE",:new."LAST_UPDATE_DATE" 
  FROM dual;
END;
/
create or replace TRIGGER  "WSC_COA_SEGMENT_VALUE_BIR" BEFORE INSERT ON WSC_GL_COA_SEGMENT_VALUE_T
FOR EACH ROW
  WHEN (new."VALUE_ID" IS NULL) BEGIN
  SELECT WSC_GL_COA_SAGMENT_VALUE_SEQ.NEXTVAL,SYSDATE ,SYSDATE
  INTO :new."VALUE_ID" , :new."CREATION_DATE", :new."LAST_UPDATE_DATE"
  FROM dual;
END;
/
create or replace TRIGGER  "WSC_COA_SEGMENT_VALUE_BUR" BEFORE UPDATE ON WSC_GL_COA_SEGMENT_VALUE_T
FOR EACH ROW
Declare
BEGIN

 :NEW.LAST_UPDATE_DATE:= SYSDATE;
  :new.version := WSC_GL_COA_DISABLE_VER_SEQ.nextval;
END;
/
create or replace TRIGGER  "WSC_GL_CCID_DISABLE_AIR" 
After INSERT on WSC_GL_CCID_MAPPING_T 
for each row
 WHEN (new.enable_flag='Y' AND new.UI_FLAG = 'Y') Declare

  PRAGMA AUTONOMOUS_TRANSACTION;  
BEGIN


dbms_scheduler.create_job (
  job_name   =>  'Update_CCID_DISABLE_FLAG'||WSC_GL_CCID_DISABLE_SEQ.nextval,
  job_type   => 'PLSQL_BLOCK',
  job_action => 
    'BEGIN 
       WSC_DISABLED_COA_HANDLE_PKG.WSC_DISABLED_CCID_HANDLE_PRC('''||:new.SOURCE_SEGMENT||''','||:new.COA_MAP_ID||');
     END;',
  enabled   =>  TRUE,  
  auto_drop =>  TRUE, 
  comments  =>  'Update_CCID_DISABLE_FLAG ');
 
END;
/
create or replace TRIGGER  "WSC_GL_CCID_DISABLE_AUR" 
After Update on WSC_GL_CCID_MAPPING_T 
for each row
 WHEN (new.enable_flag='Y' AND new.UI_FLAG = 'Y') Declare

  PRAGMA AUTONOMOUS_TRANSACTION;  
BEGIN

dbms_scheduler.create_job (
  job_name   =>  'Update_CCID_DISABLE_FLAG'||WSC_GL_CCID_DISABLE_SEQ.nextval,
  job_type   => 'PLSQL_BLOCK',
  job_action => 
    'BEGIN 
       WSC_DISABLED_COA_HANDLE_PKG.WSC_DISABLED_CCID_HANDLE_PRC('||:new.SOURCE_SEGMENT||','||:new.COA_MAP_ID||');
     END;',
  enabled   =>  TRUE,  
  auto_drop =>  TRUE, 
  comments  =>  'Update_CCID_DISABLE_FLAG ');
END;
/
create or replace TRIGGER  "WSC_GL_COA_DISABLE_AUR" 
After Update on WSC_GL_COA_SEGMENT_VALUE_T 
for each row
 WHEN (new.flag='N') Declare
PRAGMA AUTONOMOUS_TRANSACTION;  
BEGIN

--insert into WSC_TBL_TIME_T (a) values ('After Update on WSC_GL_COA_SEGMENT_VALUE_T start');
--commit;

dbms_scheduler.create_job (
  job_name   =>  'Update_COA_DISABLE_FLAG'||WSC_GL_COA_DISABLE_SEQ.nextval,
  job_type   => 'PLSQL_BLOCK',
  job_action => 
    'BEGIN 
       WSC_DISABLED_COA_HANDLE_PKG.WSC_DISABLED_COA_HANDLE_PRC('||NVL(''''||:old.SOURCE_SEGMENT1||'''','NULL')||','||NVL(''''||:old.SOURCE_SEGMENT2||'''','NULL')||','||NVL(''''||:old.SOURCE_SEGMENT3||'''','NULL')||','||NVL(''''||:old.SOURCE_SEGMENT4||'''','NULL')||','||NVL(''''||:old.SOURCE_SEGMENT5||'''','NULL')||','||NVL(''''||:old.SOURCE_SEGMENT6||'''','NULL')||','||NVL(''''||:old.SOURCE_SEGMENT7||'''','NULL')||','||NVL(''''||:old.SOURCE_SEGMENT8||'''','NULL')||','||NVL(''''||:old.SOURCE_SEGMENT9||'''','NULL')||','||NVL(''''||:old.SOURCE_SEGMENT10||'''','NULL')||','||:old.rule_id||');
     END;',
  enabled   =>  TRUE,  
  auto_drop =>  TRUE, 
  comments  =>  'Update_COA_DISABLE_FLAG ');

--insert into WSC_TBL_TIME_T (a) values ('After Update on WSC_GL_COA_SEGMENT_VALUE_T end');
--commit;
END;
/