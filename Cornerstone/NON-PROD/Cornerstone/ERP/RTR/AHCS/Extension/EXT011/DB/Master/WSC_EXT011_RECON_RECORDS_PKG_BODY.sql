create or replace Package BODY WSC_AHCS_RECON_RECORDS_PKG IS

Procedure INSERT_REC(P_INS_VAL WSC_AHCS_RECON_REP_TEMP_T_TAB,
                     ERRBUF OUT VARCHAR2,
                     RETCODE OUT VARCHAR2) IS
L_TRX_NUMBER VARCHAR2(2000):= NULL;
L_ERR_MSG VARCHAR2(2000);
L_ERR_CODE VARCHAR2(2);
BEGIN
FOR i in P_INS_VAL.FIRST..P_INS_VAL.LAST LOOP
Begin
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

PROCEDURE UPDATE_REC(ERRBUF OUT VARCHAR2,
                     RETCODE OUT VARCHAR2) IS

L_ERR_MSG VARCHAR2(100) := NULL;
L_COM_DATE DATE;

BEGIN

  merge into wsc_ahcs_int_status_t wais
using ( 
  Select Status,JOB_ID,trx_number,File_Name
    from WSC_AHCS_RECON_REP_TEMP_T 
    ) temp
on    ( wais.attribute3 = temp.trx_number and wais.file_name = NVL(substr(temp.File_Name,1,instr(temp.File_Name,'.',1)-1),temp.File_Name))
when matched then
  update set wais.attribute4 = NVL2(attribute4,attribute4||',',NULL)||temp.JOB_ID,
             wais.attribute5=temp.JOB_ID,
             wais.accounting_status=temp.status,
             wais.LAST_UPDATED_DATE=Sysdate;

BEGIN
   Select max(Completion_date)
   into L_COM_DATE 
   from WSC_AHCS_RECON_REP_TEMP_T;

IF L_COM_DATE IS NOT NULL THEN
   Update WSC_AHCS_REFRESH_T 
   Set LAST_REFRESH_DATE=L_COM_DATE,
       LAST_UPDATE_DATE=Sysdate,
       LAST_UPDATED_BY='Integration Program'
   WHERE DATA_ENTITY_NAME='WSC_AHCS_RECON_REPORT'   ;

 END IF;   
 END;
  commit;

Begin
   Execute immediate 'Truncate table WSC_AHCS_RECON_REP_TEMP_T';
Exception
    WHEN OTHERS THEN
    NULL;
END;  

begin
 DBMS_MVIEW.REFRESH('WSC_AHCS_DASHBOARD1_V','C');

  Execute immediate 'Truncate table WSC_AHCS_DASHBOARD2_STAGE_T'; 

  Insert into WSC_AHCS_DASHBOARD2_STAGE_T  select * from WSC_AHCS_DASHBOARD2_V;
  
  Execute immediate 'Truncate table WSC_AHCS_DASHBOARD2_T'; 

  Insert into WSC_AHCS_DASHBOARD2_T  select * from WSC_AHCS_DASHBOARD2_STAGE_T;

  Update WSC_AHCS_REFRESH_T 
   Set LAST_REFRESH_DATE=Sysdate,
       LAST_UPDATE_DATE=Sysdate,
       LAST_UPDATED_BY='Integration Program'
   WHERE DATA_ENTITY_NAME='WSC_AHCS_DASHBOARD2_REFRESH';

  Commit;
Exception
    WHEN OTHERS THEN
    NULL; 
end;

EXCEPTION 
WHEN OTHERS THEN
    ERRBUF := 'ERROR While Updating Records';
    RETCODE :=2;
END;

PROCEDURE REFRESH_VALIDATION_OIC(RECTCODE OUT NUMBER,
                                ERRBUF OUT VARCHAR2) IS 

begin
 DBMS_MVIEW.REFRESH('WSC_AHCS_DASHBOARD1_V','C');

 Execute immediate 'Truncate table WSC_AHCS_DASHBOARD2_STAGE_T'; 

  Insert into WSC_AHCS_DASHBOARD2_STAGE_T  select * from WSC_AHCS_DASHBOARD2_V;
  
  Execute immediate 'Truncate table WSC_AHCS_DASHBOARD2_T'; 

  Insert into WSC_AHCS_DASHBOARD2_T  select * from WSC_AHCS_DASHBOARD2_STAGE_T;

   Update WSC_AHCS_REFRESH_T 
   Set LAST_REFRESH_DATE=Sysdate,
       LAST_UPDATE_DATE=Sysdate,
       LAST_UPDATED_BY='Validation Program'
   WHERE DATA_ENTITY_NAME='WSC_AHCS_DASHBOARD2_REFRESH';

  Commit;

Exception
    WHEN OTHERS THEN
    NULL; 
end;
 

END WSC_AHCS_RECON_RECORDS_PKG;
/