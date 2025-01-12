create or replace Package BODY WSC_AHCS_DASHBOARD As

Function get_STAGED_AMOUNT(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER IS
v_records NUMBER;
BEGIN
Select TO_CHAR(sum(nvl(value,0)),'FM99999999999999999999999.00')
    into v_records
       from WSC_AHCS_INT_STATUS_T WAIS
       where WAIS.batch_id=BID
       AND WAIS.Application=Apps
       AND WAIS.File_name=Fname
       AND WAIS.CR_DR_INDICATOR='DR';

      Return (v_records);
EXCEPTION
    WHEN OTHERS THEN
      return 0;
END; 

Function get_PROCESSED_RECORDS(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER IS
v_records NUMBER;
BEGIN
Select count(*)
    into v_records
       from WSC_AHCS_INT_STATUS_T WAIS
       where WAIS.batch_id=BID
       AND WAIS.Application=Apps
       AND WAIS.File_name=Fname
       AND WAIS.attribute2 = 'TRANSFORM_SUCCESS';

      Return (v_records);
EXCEPTION
    WHEN OTHERS THEN
      return 0;
END;      

Function get_PROCESSED_AMOUNT(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER IS
v_records NUMBER;
BEGIN
Select TO_CHAR(sum(nvl(value,0)),'FM99999999999999999999999.00')
                 into v_records
       from WSC_AHCS_INT_STATUS_T WAIS
       where WAIS.batch_id=BID
       AND WAIS.Application=Apps
       AND WAIS.File_name=Fname
       AND WAIS.CR_DR_INDICATOR='DR'
       AND WAIS.attribute2 in ('TRANSFORM_SUCCESS');

                return v_records;
EXCEPTION
                             WHEN OTHERS THEN
                                           return 0;
END;                                  

Function get_ERROR_REEXTRACT_RECORDS(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER IS
v_records NUMBER;
BEGIN
Select count(*)
              into v_records
       from WSC_AHCS_INT_STATUS_T WAIS
       where WAIS.batch_id=BID
       AND WAIS.Application=Apps
       AND WAIS.File_name=Fname
       AND attribute2='VALIDATION_FAILED';

              return v_records;

EXCEPTION
              WHEN OTHERS THEN
                             return 0;
END;

Function get_ERROR_REEXTRACT_AMOUNT(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER IS
v_records NUMBER;
BEGIN
Select TO_CHAR(sum(nvl(value,0)),'FM99999999999999999999999.00')
              into v_records
       from WSC_AHCS_INT_STATUS_T WAIS
       where WAIS.batch_id=BID
       AND WAIS.Application=Apps
       AND WAIS.File_name=Fname
       AND WAIS.CR_DR_INDICATOR='DR'
       AND attribute2 in ('VALIDATION_FAILED');

                             return v_records;

EXCEPTION
              WHEN OTHERS THEN
                             return 0;
END;  

Function get_ERROR_REPROCESS_RECORDS(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER IS
v_records NUMBER;
BEGIN
Select count(*)
              into v_records
       from WSC_AHCS_INT_STATUS_T WAIS
       where WAIS.batch_id=BID
       AND WAIS.Application=Apps
       AND WAIS.File_name=Fname
       AND attribute2='TRANSFORM_FAILED';

              return v_records;

EXCEPTION
              WHEN OTHERS THEN
                             return 0;
END;

Function get_ERROR_REPROCESS_AMOUNT(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER IS
v_records NUMBER;
BEGIN
Select TO_CHAR(sum(nvl(value,0)),'FM99999999999999999999999.00')
              into v_records
       from WSC_AHCS_INT_STATUS_T WAIS
       where WAIS.batch_id=BID
       AND WAIS.Application=Apps
       AND WAIS.File_name=Fname
       AND WAIS.CR_DR_INDICATOR='DR'
       AND attribute2 in ('TRANSFORM_FAILED');

                             return v_records;

EXCEPTION
              WHEN OTHERS THEN
                             return 0;
END;  

Function get_SKIPPED_RECORDS(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER IS
v_records NUMBER;
BEGIN
Select count(*)
                             into v_records
       from WSC_AHCS_INT_STATUS_T WAIS
       where WAIS.batch_id=BID
       AND WAIS.Application=Apps
       AND WAIS.File_name=Fname
       AND WAIS.Application='CENTRAL'
       AND status='SKIPPED';

              return v_records;

EXCEPTION
              WHEN OTHERS THEN
                             return 0;
END;        

Function get_SKIPPED_AMOUNT(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER IS
v_records NUMBER;
BEGIN

Select TO_CHAR(sum(nvl(value,0)),'FM99999999999999999999999.00')
                into v_records
       from WSC_AHCS_INT_STATUS_T WAIS
       where WAIS.batch_id=BID
       AND WAIS.Application=Apps
       AND WAIS.File_name=Fname
       AND WAIS.Application='CENTRAL'
       AND WAIS.CR_DR_INDICATOR='DR'
       AND status='SKIPPED';

              return v_records;

EXCEPTION
              WHEN OTHERS THEN
                             return 0;
END;  


PROCEDURE wsc_ahcs_dashboard_error(o_Clobdata OUT CLOB,
                                                                                                                                                                                            P_APPLICATION IN VARCHAR2,
                                                                                                                                                                                            P_STATUS IN VARCHAR2,
                                                                                                                                                                                            P_ACC_STATUS IN VARCHAR2,
                                                                                                                                                                                            P_ACCOUNTING_PERIOD varchar2) IS 
  l_Blob         BLOB; 
  l_Clob         CLOB; 

BEGIN 

  Dbms_Lob.Createtemporary(Lob_Loc => l_Clob, 
                           Cache   => TRUE, 
                           Dur     => Dbms_Lob.Call); 
  SELECT Clob_Val 
    INTO l_Clob 
    FROM (SELECT Xmlcast(Xmlagg(Xmlelement(e, 
                                           Col_Value || Chr(13) || 
                                           Chr(10))) AS CLOB) AS Clob_Val, 
                 COUNT(*) AS Number_Of_Rows 
            FROM (SELECT 'FILE_NAME, SOURCE_COA, FUTURE_COA,ERROR_MSG, SOURCE_TRANSACTION_NUMBER, LEGACY_AE_HEADER_ID, LEGACY_LINE_NUMBER,STATUS,CR_DR,CURRENCY,AMOUNT,ACCOUNTING_DATE, AHCS CREATE ACCOUNTING REQ_ID, REPROCESS_REQUIRED,REEXTRACT_REQUIRED' AS Col_Value 
                    FROM Dual 
                  UNION ALL 
                  SELECT FILE_NAME||','||Source_COA||','||Target_COA||','||ERROR_MSG||','||Source_Trx_Num||','||Legacy_header_id||','||Legacy_Line_Number||','||Status||','||CR_DR_Indicator||','||Currency||','||Value||','||ACCOUNTING_DATE||','||AHCS_CREATE_ACCOUNTING_REQ_ID||','||REPROCESS_REQUIRED||','||REEXTRACT_REQUIRED AS Col_Value 
                    FROM (With wais as (Select a.rowid rw,b.APPLICATION,a.File_Name,a.Source_COA,a.accounting_error_msg,a.error_msg,a.Legacy_header_id,a.Legacy_Line_Number,a.Attribute2,a.CR_DR_Indicator,a.currency,a.value,a.attribute11,a.Accounting_status,a.status,a.header_id,a.line_id
                  from wsc_ahcs_int_status_t a,(SELECT LEGACY_HEADER_ID,LEGACY_LINE_NUMBER,APPLICATION,MAX(last_updated_date) lat_last_update_date
                                FROM wsc_ahcs_int_status_t where application!='CENTRAL'
                                GROUP BY LEGACY_HEADER_ID,
                                LEGACY_LINE_NUMBER,
                                APPLICATION)b where a.LEGACY_HEADER_ID=b.LEGACY_HEADER_ID and a.LEGACY_LINE_NUMBER=b.LEGACY_LINE_NUMBER and b.lat_last_update_date=a.last_updated_date and a.APPLICATION=b.APPLICATION)

                    Select wais.File_Name,
       wais.Source_COA,
       decode(wais.application,'EBS AP',waptl.Target_COA,'EBS AP1',waptl.Target_COA,'EBS AR',wartl.Target_COA,'EBS AR1',wartl.Target_COA,'EBS FA',wfatl.Target_COA,'ERP_POC',wpoctl.Target_COA,NULL) Target_COA,
       --wais.Target_COA,
       NVL(wais.accounting_error_msg,wais.error_msg) ERROR_MSG,
       --NULL AHCS_TRANSACTION_NUMBER,
       decode(wais.application,'EBS AP',waptl.SOURCE_TRN_NBR,'EBS AP1',waptl.SOURCE_TRN_NBR,'EBS AR',wartl.SOURCE_TRN_NBR,'EBS AR1',wartl.SOURCE_TRN_NBR,'EBS FA1',wfatl.SOURCE_TRN_NBR,'EBS FA',wfatl.SOURCE_TRN_NBR,NULL) Source_Trx_Num,
       wais.Legacy_header_id,
       wais.Legacy_Line_Number,
       wais.Attribute2 Status,
       wais.CR_DR_Indicator,
       wais.currency,
       wais.value,
       to_char(wais.attribute11,'YYYY-MM-DD') ACCOUNTING_DATE,
       NULL AHCS_CREATE_ACCOUNTING_REQ_ID,
       Decode(wais.attribute2,'TRANSFORM_FAILED','Y','N') REPROCESS_REQUIRED,
       Decode(wais.attribute2,'VALIDATION_FAILED','Y','N') REEXTRACT_REQUIRED

From wais,
     wsc_ahcs_ap_txn_header_t wapth,
    wsc_ahcs_ap_txn_line_t waptl,
    wsc_ahcs_ar_txn_header_t warth,
    wsc_ahcs_ar_txn_line_t wartl ,
    wsc_ahcs_fa_txn_header_t wfath ,
    wsc_ahcs_fa_txn_line_t wfatl,
    wsc_ahcs_poc_txn_header_t wpocth,
    wsc_ahcs_poc_txn_line_t wpoctl

Where decode(wais.application,'EBS AP','EBS Accounts Payable','EBS AP1','EBS Accounts Payable','OTH')=wapth.source_system(+) 
AND decode(wais.application,'EBS AP',wais.header_id,'EBS AP1',wais.header_id,null)=wapth.header_id(+)
AND decode(wais.application,'EBS AP',wais.header_id,'EBS AP1',wais.header_id,null)=waptl.HEADER_ID(+)
AND decode(wais.application,'EBS AP',wais.line_id,'EBS AP1',wais.line_id,null)=waptl.line_id(+)
AND decode(wais.application,'EBS AR','EBS Accounts Receivable','EBS AR1','EBS Accounts Receivable','OTH')=warth.source_system(+) 
AND decode(wais.application,'EBS AR',wais.header_id,'EBS AR1',wais.header_id,null)=warth.header_id(+)
AND decode(wais.application,'EBS AR',wais.header_id,'EBS AR1',wais.header_id,null)=wartl.HEADER_ID(+)
AND decode(wais.application,'EBS AR',wais.line_id,'EBS AR1',wais.line_id,null)=wartl.line_id(+)
AND decode(wais.application,'EBS FA','EBS FA','OTH')=wfath.source_system(+) 
AND decode(wais.application,'EBS FA',wais.header_id,null)=wfath.header_id(+)
AND decode(wais.application,'EBS FA',wais.header_id,null)=wfatl.HEADER_ID(+)
AND decode(wais.application,'EBS FA',wais.line_id,null)=wfatl.line_id(+)
AND decode(wais.application,'ERP_POC','ERP POC','OTH')=wpocth.source_system(+)
AND decode(wais.application,'ERP_POC',wais.header_id,null)=wpocth.header_id(+)
AND decode(wais.application,'ERP_POC',wais.header_id,null)=wpoctl.HEADER_ID(+)
AND decode(wais.application,'ERP_POC',wais.line_id,null)=wpoctl.line_id(+) 
AND decode(wais.status,'TRANSFORM_SUCCESS',NVL(wais.Accounting_status,'NA'),wais.status)!=decode(wais.status,'TRANSFORM_SUCCESS',NVL2(wais.Accounting_status,'CRE_ACC_SUCCESS','NA'),'TRANSFORM_SUCCESS')
AND decode(wais.status,'TRANSFORM_SUCCESS',NVL(wais.Accounting_status,'NA'),wais.status)!=decode(wais.status,'TRANSFORM_SUCCESS',NVL2(wais.Accounting_status,'IMP_ACC_SUCCESS','NA'),'TRANSFORM_SUCCESS')
AND decode(wais.application,'ERP_POC','ERP POC',wais.application)=P_APPLICATION
AND wais.application!='CENTRAL'
AND to_char(wais.attribute11,'MON-YY')=P_ACCOUNTING_PERIOD
AND Case
       WHEN wais.Attribute2='TRANSFORM_SUCCESS' and wais.Accounting_status='IMP_ACC_SUCCESS' THEN
           'Accounted'
       WHEN wais.Attribute2='TRANSFORM_SUCCESS' and (wais.Accounting_status in ('CRE_ACC_ERROR','IMP_ACC_ERROR'))  THEN   
           'Error'
       WHEN wais.Attribute2='TRANSFORM_SUCCESS' and (wais.Accounting_status='IMP_ACC_SUCCESS' or wais.Accounting_status is null)  THEN   
           'Pending' 
        WHEN (wais.Attribute2 in ('TRANSFORM_FAILED','VALIDATION_SUCCESS') or wais.Attribute2 is null) THEN
            'NA'
        WHEN wais.Attribute2='VALIDATION_FAILED' THEN
            'NA'         
        ELSE NVL(wais.Accounting_status,1)
        END =NVL(P_ACC_STATUS,1)
AND Case
        WHEN (wais.Attribute2 in ('TRANSFORM_FAILED','VALIDATION_SUCCESS') or wais.Attribute2 is null) THEN
            'Reprocessing Error'
        WHEN wais.Attribute2='VALIDATION_FAILED' THEN
            'Re-extract Error'
          WHEN wais.Attribute2='TRANSFORM_SUCCESS' THEN
            'Success'
        ELSE 
            wais.Attribute2
        END =P_STATUS

      UNION ALL

        Select wais.File_Name,
       wais.Source_COA,
       wcentrall.Target_COA Target_COA,
       NVL(wais.accounting_error_msg,wais.error_msg) ERROR_MSG,
       NULL Source_Trx_Num,
       wais.Legacy_header_id,
       wais.Legacy_Line_Number,
       wais.Attribute2 Status,
       wais.CR_DR_Indicator,
       'USD' Currency,
       wais.Value,
       to_char(wais.attribute11,'YYYY-MM-DD') ACCOUNTING_DATE,
       NULL AHCS_CREATE_ACCOUNTING_REQ_ID,
       Decode(wais.attribute2,'TRANSFORM_FAILED','Y','N') REPROCESS_REQUIRED,
       Decode(wais.attribute2,'VALIDATION_FAILED','Y','N') REEXTRACT_REQUIRED

From wsc_ahcs_int_status_t wais,
    wsc_ahcs_central_txn_line_t wcentrall
where wais.application='CENTRAL' 
AND initcap(wais.application)=P_APPLICATION
AND wais.line_id=wcentrall.line_id   
AND decode(wais.status,'TRANSFORM_SUCCESS',NVL(wais.Accounting_status,'NA'),wais.status)!=decode(wais.status,'TRANSFORM_SUCCESS',NVL2(wais.Accounting_status,'CRE_ACC_SUCCESS','NA'),'TRANSFORM_SUCCESS')
AND decode(wais.status,'TRANSFORM_SUCCESS',NVL(wais.Accounting_status,'NA'),wais.status)!=decode(wais.status,'TRANSFORM_SUCCESS',NVL2(wais.Accounting_status,'IMP_ACC_SUCCESS','NA'),'TRANSFORM_SUCCESS')
AND to_char(wais.attribute11,'MON-YY')=P_ACCOUNTING_PERIOD
AND Case
       WHEN wais.Attribute2='TRANSFORM_SUCCESS' and wais.Accounting_status='IMP_ACC_SUCCESS' THEN
           'Accounted'
       WHEN wais.Attribute2='TRANSFORM_SUCCESS' and (wais.Accounting_status in ('CRE_ACC_ERROR','IMP_ACC_ERROR'))  THEN   
           'Error'
       WHEN wais.Attribute2='TRANSFORM_SUCCESS' and (wais.Accounting_status='IMP_ACC_SUCCESS' or wais.Accounting_status is null)  THEN   
           'Pending' 
        WHEN (wais.Attribute2 in ('TRANSFORM_FAILED')) THEN
            'NA'
        WHEN wais.Attribute2='VALIDATION_FAILED' THEN
            'NA'         
        ELSE NVL(wais.Accounting_status,1)
        END =NVL(P_ACC_STATUS,1)
AND Case
        WHEN (wais.Attribute2 in ('TRANSFORM_FAILED')) THEN
            'Reprocessing Error'
        WHEN wais.Attribute2='VALIDATION_FAILED' THEN
            'Re-extract Error'
          WHEN wais.Attribute2='TRANSFORM_SUCCESS' THEN
            'Success'
        ELSE 
            wais.Attribute2
        END =P_STATUS))); 

  o_Clobdata := l_Clob; 
EXCEPTION 
  WHEN OTHERS THEN 
    NULL; 
END;  

END WSC_AHCS_DASHBOARD;
/