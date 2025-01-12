create or replace Package BODY WSC_AHCS_DASHBOARD As


Function GET_IMPORT_ACCOUNT_ERROR(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER IS
v_records NUMBER;
BEGIN
Select count(1)
    into v_records
       from WSC_AHCS_INT_STATUS_T WAIS
       where WAIS.batch_id=BID
       AND WAIS.Application=Apps
       AND WAIS.File_name=Fname
       AND WAIS.accounting_status = 'IMP_ACC_ERROR';

      Return (v_records);
EXCEPTION
    WHEN OTHERS THEN
      return 0;
END; 

Function get_STAGED_AMOUNT(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER IS
v_records NUMBER;
BEGIN
Select TO_CHAR((sum(nvl(value,0))),'FM99999999999999999999999.00')
--Select TO_CHAR(abs(sum(nvl(value,0))),'FM99999999999999999999999.00')
    into v_records
       from WSC_AHCS_INT_STATUS_T WAIS
       where WAIS.batch_id=BID
       AND WAIS.Application=Apps
       AND WAIS.File_name=Fname
       AND WAIS.CR_DR_INDICATOR=case when wais.application ='MF AP' and wais.interface_id = 'CAIN' 
       then WAIS.CR_DR_INDICATOR
       when wais.application ='MF INV' and wais.interface_id = 'AIIB' 
       then 'CR'
       else 'DR' end;

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
--Select TO_CHAR(abs(sum(nvl(value,0))),'FM99999999999999999999999.00')
Select TO_CHAR((sum(nvl(value,0))),'FM99999999999999999999999.00')
                 into v_records
       from WSC_AHCS_INT_STATUS_T WAIS
       where WAIS.batch_id=BID
       AND WAIS.Application=Apps
       AND WAIS.File_name=Fname
       AND WAIS.CR_DR_INDICATOR= case when wais.application ='MF AP' and wais.interface_id = 'CAIN' 
       then WAIS.CR_DR_INDICATOR
       when wais.application ='MF INV' and wais.interface_id = 'AIIB' 
       then 'CR'
       else 'DR' end
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
       AND WAIS.Application in ('CENTRAL','LEASES')
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
       AND WAIS.Application in ('CENTRAL','LEASES')
       AND WAIS.CR_DR_INDICATOR='DR'
       AND status='SKIPPED';

              return v_records;

EXCEPTION
              WHEN OTHERS THEN
                             return 0;
END;  

PROCEDURE wsc_ahcs_dashboard_import_error(o_Clobdata OUT CLOB,
                        P_APPLICATION IN VARCHAR2,
                        P_ACC_STATUS IN VARCHAR2,
                        P_ACCOUNTING_PERIOD varchar2,
                        P_SOURCE_SYSTEM varchar2) IS 
  l_Blob         BLOB; 
  l_Clob         CLOB; 

BEGIN 

--INSERT INTO WSC_TBL_TIME_T (A) VALUES(P_APPLICATION);
--INSERT INTO WSC_TBL_TIME_T (A) VALUES(P_ACC_STATUS);
--INSERT INTO WSC_TBL_TIME_T (A) VALUES(P_ACCOUNTING_PERIOD);
--INSERT INTO WSC_TBL_TIME_T (A) VALUES(P_SOURCE_SYSTEM);
--COMMIT;
Dbms_Lob.Createtemporary(Lob_Loc => l_Clob, 
                           Cache   => TRUE, 
                           Dur     => Dbms_Lob.Call); 
--null;
SELECT Clob_Val 
    INTO l_Clob 
    FROM (SELECT Xmlcast(Xmlagg(Xmlelement(e, 
                                           Col_Value || Chr(13) || 
                                           Chr(10))) AS CLOB) AS Clob_Val, 
                 COUNT(*) AS Number_Of_Rows 
            FROM (SELECT 'RECORD_TYPE,INTERFACE_ID,HEADER_ID,LINE_NUMBER,ERROR_CODE,TRANSACTION_NUMBER,COMPANY_NUMBER,PAYCODE,ACCOUNT_NUMBER,AMOUNT,TRANSACTION_DATE,ERROR_MESSAGE,LEDGER_NAME' AS Col_Value 
                    FROM Dual 
                  UNION ALL 
                  select RECORD_TYPE||','||INTERFACE_ID||','||HEADER_ID||','||LINE_NUMBER||','||ERROR_CODE||','||TRANSACTION_NUMBER||','||COMPANY_NUMBER||','||PAYCODE||','||ACCOUNT_NUMBER||','||AMOUNT||','||TRANSACTION_DATE||','||ERROR_MESSAGE||','||LEDGER_NAME
                  from (SELECT 
      * 
    FROM (

SELECT 
  'D' RECORD_TYPE, 
--   TO_CHAR(S.INTERFACE_ID) INTERFACE_ID,
  decode(S.INTERFACE_ID,'SALE','SII','CASH','CRI','LSIR','LSI',
  'SPER','SPR','ARIN','ARI','IFRT','FII','COQI','CQI','OFRT','FTI',
  'INTR','ICI','INVT','ISI','SPEC','SPC',substr(S.INTERFACE_ID,1,3)) 
    INTERFACE_ID,
  TO_CHAR(
    LPAD(S.LEGACY_HEADER_ID, 9, 0)
  ) HEADER_ID, 
  TO_CHAR(S.LEGACY_LINE_NUMBER) LINE_NUMBER, 
  '303' ERROR_CODE, 
  TO_CHAR(S.ATTRIBUTE3) TRANSACTION_NUMBER, 
  TO_CHAR(S.COMPANY_NUM) COMPANY_NUMBER, 
  TO_CHAR(S.PAY_CODE) PAYCODE, 
  TO_CHAR(S.GL_CODE) ACCOUNT_NUMBER, 
  TO_CHAR(S.DR) AMOUNT, 
  TO_CHAR(
    S.ATTRIBUTE11, 
    'YYYY-MM-DD'
  ) TRANSACTION_DATE, 
  CONCAT(
    'IMPORT_ACC_ERROR-', 
    TO_CHAR(C.IMPORT_ACC_ID)
  ) ERROR_MESSAGE, 
  TO_CHAR(S.LEDGER_NAME) LEDGER_NAME
FROM 
  WSC_AHCS_INT_STATUS_T S, 
  WSC_AHCS_INT_CONTROL_LINE_T C,
  WSC_AHCS_DSHB2_UNI_REC_V UNI_REC
WHERE 
UNI_REC.rw = S.ROWID AND
--  S.batch_id = :BATCH_ID
--  and 
  (S.accounting_status = 'IMP_ACC_ERROR'
  or S.accounting_status  is null)
  and to_char(S.attribute11,'MON-YY')=P_ACCOUNTING_PERIOD
  and decode(S.application,'ERP_POC','ERP POC','CENTRAL','Central','ECLIPSE','ECLPS',
    'SXE','SXEUS','TW','APS Treasury','MF INV','MF INVENTORY',S.application) = P_APPLICATION
    AND (decode(S.interface_id,'SALE','SII','CASH','CRI','LSIR','LSI','SPER','SPR','ARIN','ARI',
    'IFRT','FII','COQI','CQI','OFRT','FTI','INTR','ICI','INVT','ISI','SPEC','SPC',substr(S.interface_id,1,3)) = P_SOURCE_SYSTEM
    or S.interface_id is null)
    AND 
    CASE
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status = 'CRE_ACC_SUCCESS' THEN
                'Final Accounted'
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status = 'Draft' THEN
                'Draft Accounted'    
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND ( S.accounting_status IN ( 'CRE_ACC_ERROR' ) ) THEN
                'Error'
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND ( S.accounting_status IN (  'IMP_ACC_ERROR' ) ) THEN
                'Import Error'    
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status = 'IMP_ACC_SUCCESS' THEN
                'Accounting Pending'
			WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status IS NULL THEN
                'Import Pending'
			WHEN ( S.attribute2 IN ( 'TRANSFORM_FAILED', 'VALIDATION_SUCCESS' )
                   OR S.attribute2 IS NULL ) THEN
                'NA'
            WHEN S.attribute2 = 'VALIDATION_FAILED' THEN
                'NA'
            ELSE
                NULL
        END       = P_ACC_STATUS
  and (
    S.INTERFACE_ID IN (
      'APIN', 'ARIN', 'AQIN', 'ADIN', 'CAIN', 
      'LSIP', 'LSIR', 'CASH', 'SALE', 'SPER', 
      'AIIB', 'COQI', 'DAIN', 'IBIN', 'IFRT', 
      'INTR', 'INVT', 'IRIN', 'OFRT', 'SPEC', 
      'BKIN','JTI'
    ) 
    or S.APPLICATION in ('LEASES','CONCUR')
  ) 
  AND C.GROUP_ID(+) = S.GROUP_ID 
  AND C.BATCH_ID(+) = S.BATCH_ID 
  AND C.LEDGER_NAME(+) = S.LEDGER_NAME

union all 
SELECT 
  'D', 
--   TO_CHAR(S.INTERFACE_ID), 
  decode(S.INTERFACE_ID,'SALE','SII','CASH','CRI','LSIR','LSI',
  'SPER','SPR','ARIN','ARI','IFRT','FII','COQI','CQI','OFRT','FTI',
  'INTR','ICI','INVT','ISI','SPEC','SPC',substr(S.INTERFACE_ID,1,3)) 
    INTERFACE_ID,
  TO_CHAR(
    LPAD(S.LEGACY_HEADER_ID, 9, 0)
  ), 
  TO_CHAR(S.LEGACY_LINE_NUMBER), 
  '303', 
  TO_CHAR(S.ATTRIBUTE3), 
  TO_CHAR(S.COMPANY_NUM), 
  TO_CHAR(S.PAY_CODE), 
  TO_CHAR(S.GL_CODE), 
  TO_CHAR(S.DR), 
  TO_CHAR(
    S.ATTRIBUTE11, 
    'YYYY-MM-DD'
  ), 
  CONCAT(
    'IMPORT_ACC_ERROR-', 
    TO_CHAR(C.IMPORT_ACC_ID)
  ), 
  TO_CHAR(S.LEDGER_NAME) 
FROM 
  WSC_AHCS_INT_STATUS_T S, 
  WSC_AHCS_INT_CONTROL_T C,
  WSC_AHCS_DSHB2_UNI_REC_V UNI_REC
WHERE 
UNI_REC.rw = S.ROWID AND
--  S.batch_id =  :BATCH_ID
--  and S.accounting_status = 'IMP_ACC_ERROR' 
(S.accounting_status = 'IMP_ACC_ERROR'
  or S.accounting_status  is null)
  and to_char(S.attribute11,'MON-YY')=P_ACCOUNTING_PERIOD
  and decode(S.application,'ERP_POC','ERP POC','CENTRAL','Central','ECLIPSE','ECLPS',
    'SXE','SXEUS','TW','APS Treasury','MF INV','MF INVENTORY',S.application) = P_APPLICATION
    AND 
    CASE
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status = 'CRE_ACC_SUCCESS' THEN
                'Final Accounted'
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status = 'Draft' THEN
                'Draft Accounted'    
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND ( S.accounting_status IN ( 'CRE_ACC_ERROR' ) ) THEN
                'Error'
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND ( S.accounting_status IN (  'IMP_ACC_ERROR' ) ) THEN
                'Import Error'    
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status = 'IMP_ACC_SUCCESS' THEN
                'Accounting Pending'
			WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status IS NULL THEN
                'Import Pending'
			WHEN ( S.attribute2 IN ( 'TRANSFORM_FAILED', 'VALIDATION_SUCCESS' )
                   OR S.attribute2 IS NULL ) THEN
                'NA'
            WHEN S.attribute2 = 'VALIDATION_FAILED' THEN
                'NA'
            ELSE
                NULL
        END       = P_ACC_STATUS
  and S.APPLICATION IN (
    'CLOUDPAY', 'ECLIPSE', 'SXE', 'PS FA',
    'TW'
  ) 
  AND C.BATCH_ID(+) = S.BATCH_ID

  UNION ALL 
SELECT 
  DISTINCT 'H', 
  decode(S.INTERFACE_ID,'SALE','SII','CASH','CRI','LSIR','LSI',
  'SPER','SPR','ARIN','ARI','IFRT','FII','COQI','CQI','OFRT','FTI',
  'INTR','ICI','INVT','ISI','SPEC','SPC',substr(S.INTERFACE_ID,1,3)) 
    INTERFACE_ID,
  TO_CHAR(
    LPAD(S.LEGACY_HEADER_ID, 9, 0)
  ), 
  NULL, 
  '303', 
  TO_CHAR(S.ATTRIBUTE3), 
  TO_CHAR(S.COMPANY_NUM), 
  TO_CHAR(S.PAY_CODE), 
  TO_CHAR(S.GL_CODE), 
  NULL, 
  TO_CHAR(
    S.ATTRIBUTE11, 
    'YYYY-MM-DD'
  ) TRANSACTION_DATE, 
  CONCAT(
    'IMPORT_ACC_ERROR-', 
    TO_CHAR(C.IMPORT_ACC_ID)
  ), 
  TO_CHAR(S.LEDGER_NAME) 
FROM 
  WSC_AHCS_INT_STATUS_T S, 
  WSC_AHCS_INT_CONTROL_LINE_T C,
  WSC_AHCS_DSHB2_UNI_REC_V UNI_REC
WHERE 
UNI_REC.rw = S.ROWID AND
--  S.batch_id = : batch_id 
--  and S.accounting_status = 'IMP_ACC_ERROR' 
(S.accounting_status = 'IMP_ACC_ERROR'
  or S.accounting_status  is null)
  and to_char(S.attribute11,'MON-YY')=P_ACCOUNTING_PERIOD
  and decode(S.application,'ERP_POC','ERP POC','CENTRAL','Central','ECLIPSE','ECLPS',
    'SXE','SXEUS','TW','APS Treasury','MF INV','MF INVENTORY',S.application) = P_APPLICATION
    AND (decode(S.interface_id,'SALE','SII','CASH','CRI','LSIR','LSI','SPER','SPR','ARIN','ARI',
    'IFRT','FII','COQI','CQI','OFRT','FTI','INTR','ICI','INVT','ISI','SPEC','SPC',substr(S.interface_id,1,3)) = P_SOURCE_SYSTEM
    or S.interface_id is null)
    AND 
    CASE
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status = 'CRE_ACC_SUCCESS' THEN
                'Final Accounted'
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status = 'Draft' THEN
                'Draft Accounted'    
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND ( S.accounting_status IN ( 'CRE_ACC_ERROR' ) ) THEN
                'Error'
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND ( S.accounting_status IN (  'IMP_ACC_ERROR' ) ) THEN
                'Import Error'    
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status = 'IMP_ACC_SUCCESS' THEN
                'Accounting Pending'
			WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status IS NULL THEN
                'Import Pending'
			WHEN ( S.attribute2 IN ( 'TRANSFORM_FAILED', 'VALIDATION_SUCCESS' )
                   OR S.attribute2 IS NULL ) THEN
                'NA'
            WHEN S.attribute2 = 'VALIDATION_FAILED' THEN
                'NA'
            ELSE
                NULL
        END       = P_ACC_STATUS
  and (
    S.INTERFACE_ID IN (
      'APIN', 'ARIN', 'AQIN', 'ADIN', 'CAIN', 
      'LSIP', 'LSIR', 'CASH', 'SALE', 'SPER', 
      'AIIB', 'COQI', 'DAIN', 'IBIN', 'IFRT', 
      'INTR', 'INVT', 'IRIN', 'OFRT', 'SPEC', 
      'BKIN', 'JTI'
    ) 
    or S.APPLICATION in ('LEASES','CONCUR')
  ) 
  AND C.GROUP_ID(+) = S.GROUP_ID 
  AND C.BATCH_ID(+) = S.BATCH_ID 
  AND C.LEDGER_NAME(+) = S.LEDGER_NAME 
UNION ALL 
SELECT 
  DISTINCT 'H', 
  decode(S.INTERFACE_ID,'SALE','SII','CASH','CRI','LSIR','LSI',
  'SPER','SPR','ARIN','ARI','IFRT','FII','COQI','CQI','OFRT','FTI',
  'INTR','ICI','INVT','ISI','SPEC','SPC',substr(S.INTERFACE_ID,1,3)) 
    INTERFACE_ID,
  TO_CHAR(
    LPAD(S.LEGACY_HEADER_ID, 9, 0)
  ), 
  NULL, 
  '303', 
  TO_CHAR(S.ATTRIBUTE3), 
  TO_CHAR(S.COMPANY_NUM), 
  TO_CHAR(S.PAY_CODE), 
  TO_CHAR(S.GL_CODE), 
  NULL, 
  TO_CHAR(
    S.ATTRIBUTE11, 
    'YYYY-MM-DD'
  ) TRANSACTION_DATE, 
  CONCAT(
    'IMPORT_ACC_ERROR-', 
    TO_CHAR(C.IMPORT_ACC_ID)
  ), 
  TO_CHAR(S.LEDGER_NAME) 
FROM 
  WSC_AHCS_INT_STATUS_T S, 
  WSC_AHCS_INT_CONTROL_T C,
  WSC_AHCS_DSHB2_UNI_REC_V UNI_REC
WHERE 
UNI_REC.rw = S.ROWID AND
--  S.batch_id = :batch_id 
--  and S.accounting_status = 'IMP_ACC_ERROR' 
(S.accounting_status = 'IMP_ACC_ERROR'
  or S.accounting_status  is null)
  and to_char(S.attribute11,'MON-YY')=P_ACCOUNTING_PERIOD
  and decode(S.application,'ERP_POC','ERP POC','CENTRAL','Central','ECLIPSE','ECLPS',
    'SXE','SXEUS','TW','APS Treasury','MF INV','MF INVENTORY',S.application) = P_APPLICATION
    AND 
    CASE
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status = 'CRE_ACC_SUCCESS' THEN
                'Final Accounted'
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status = 'Draft' THEN
                'Draft Accounted'    
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND ( S.accounting_status IN ( 'CRE_ACC_ERROR' ) ) THEN
                'Error'
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND ( S.accounting_status IN (  'IMP_ACC_ERROR' ) ) THEN
                'Import Error'    
            WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status = 'IMP_ACC_SUCCESS' THEN
                'Accounting Pending'
			WHEN S.attribute2 = 'TRANSFORM_SUCCESS'
                 AND S.accounting_status IS NULL THEN
                'Import Pending'
			WHEN ( S.attribute2 IN ( 'TRANSFORM_FAILED', 'VALIDATION_SUCCESS' )
                   OR S.attribute2 IS NULL ) THEN
                'NA'
            WHEN S.attribute2 = 'VALIDATION_FAILED' THEN
                'NA'
            ELSE
                NULL
        END       = P_ACC_STATUS
  and S.APPLICATION IN (
    'CLOUDPAY', 'ECLIPSE', 'SXE', 
    'TW', 'PS FA'
  ) 
  AND C.BATCH_ID(+) = S.BATCH_ID
)
ORDER BY 

      HEADER_ID, 
RECORD_TYPE DESC,
to_number(LINE_NUMBER)
)
                  )); 
  o_Clobdata := l_Clob; 

end;


PROCEDURE wsc_ahcs_dashboard_error(o_Clobdata OUT CLOB,
                                                                                                                                                                                            P_APPLICATION IN VARCHAR2,
                                                                                                                                                                                            P_STATUS IN VARCHAR2,
                                                                                                                                                                                            P_ACC_STATUS IN VARCHAR2,
                                                                                                                                                                                            P_ACCOUNTING_PERIOD varchar2,
                                                                                                                                                                                            P_SOURCE_SYSTEM varchar2) IS 
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
                    FROM (With wais as (SELECT
    a.interface_id,
    a.rowid rw,
    b.application,
    a.file_name,
    a.source_coa,
    a.accounting_error_msg,
    a.error_msg,
    a.legacy_header_id,
    a.legacy_line_number,
    a.attribute2,
    a.cr_dr_indicator,
    a.currency,
    a.value,
    a.attribute11,
    a.accounting_status,
    a.status,
    a.header_id,
    a.line_id,
    a.attribute3
FROM
    wsc_ahcs_int_status_t  a,
    (
    SELECT
            rw,
            application,
			legacy_header_id,
            legacy_line_number,
            interface_id
        FROM
            (
                SELECT  
                    ROWID rw,
                    application,
                    legacy_header_id,
                    legacy_line_number,
                    interface_id,
                    RANK()
                    OVER( PARTITION BY application,decode(application,'CENTRAL',header_id,nvl(legacy_header_id,header_id)),decode(application,'CENTRAL',line_id,nvl(legacy_line_number,line_id))
                        ORDER BY
                            last_updated_date DESC
                    )     rnk
                FROM
                    wsc_ahcs_int_status_t
            )
        WHERE
            rnk = 1

    )                      b
WHERE
a.rowid=b.rw)

                    Select wais.File_Name,
       wais.Source_COA,
       decode(wais.application,'EBS AP',waptl.Target_COA,'EBS AP1',waptl.Target_COA,'EBS AR',wartl.Target_COA,'EBS AR1',wartl.Target_COA,'EBS FA',wfatl.Target_COA,'ERP_POC',wpoctl.Target_COA,NULL) Target_COA,
       --wais.Target_COA,
       NVL(wais.accounting_error_msg,wais.error_msg) ERROR_MSG,
       --NULL AHCS_TRANSACTION_NUMBER,
       --decode(wais.application,'EBS AP',waptl.SOURCE_TRN_NBR,'EBS AP1',waptl.SOURCE_TRN_NBR,'EBS AR',wartl.SOURCE_TRN_NBR,'EBS AR1',wartl.SOURCE_TRN_NBR,'EBS FA1',wfatl.SOURCE_TRN_NBR,'EBS FA',wfatl.SOURCE_TRN_NBR,NULL) Source_Trx_Num,
       case
			when wais.application = 'EBS AP' then waptl.SOURCE_TRN_NBR
			when wais.application = 'EBS AR' then wartl.SOURCE_TRN_NBR
			when wais.application = 'EBS FA' then wfatl.SOURCE_TRN_NBR
			when wais.application = 'MF AP' then wmfaph.INVOICE_NBR ||'~'|| wmfaph.VENDOR_NBR || '~'|| to_char(wmfaph.INVOICE_DATE,'ddmmyyyy')
			when wais.application = 'MF AR' then wmfarh.INVOICE_NBR ||'~'|| wmfarh.CUSTOMER_NBR
			when wais.application = 'MF INV' and wais.INTERFACE_ID in ('INVT','IBIN','INTR','AIIB','SPEC','IFRT','OFRT') then wmfinvh.INVOICE_NBR ||'~'|| wmfinvh.VENDOR_NBR ||'~'|| to_char(wmfinvh.INVOICE_DATE,'dd-mm-yyyy')
			when wais.application = 'MF INV' and wais.INTERFACE_ID = 'IRIN' then wmfinvl.ITEM_NBR ||'~'|| wmfinvh.RECEIVER_LOC ||'~'|| wmfinvh.RECEIVER_NBR
			when wais.application = 'MF INV' and wais.INTERFACE_ID = 'COQI' then wmfinvh.VENDOR_PART_NBR ||'~'|| wmfinvh.PS_LOCATION --wmfinvl.PART_NBR || wmfinvl.PS_LOCATION
			when wais.application = 'MF INV' and wais.INTERFACE_ID = 'DAIN' then wmfinvh.PURCHASE_ORDER_NBR ||'~'|| wmfinvl.VENDOR_NBR ||'~'|| to_char(wmfinvl.INVOICE_DATE,'dd-mm-yyyy') --wmfinvl.PO_NBR || wmfinvh.VENDOR_NBR || to_char(wmfinvl.INVOICE_DATE,'dd-mm-yyyy')
			when wais.application = 'PS FA'  then wpsfah.ASSET_ID
			when wais.application = 'Leases' then wlhinl.RECORD_ID
			else null 
		end Source_Trx_Num,	   
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
    wsc_ahcs_poc_txn_line_t wpoctl,
	WSC_AHCS_MFAP_TXN_HEADER_T wmfaph,
	WSC_AHCS_MFAP_TXN_LINE_T wmfapl,
	WSC_AHCS_MFAR_TXN_HEADER_T wmfarh,
	WSC_AHCS_MFAR_TXN_LINE_T wmfarl,
	WSC_AHCS_MFINV_TXN_HEADER_T wmfinvh,
	WSC_AHCS_MFINV_TXN_LINE_T wmfinvl,
	WSC_AHCS_PSFA_TXN_HEADER_T wpsfah,
	WSC_AHCS_PSFA_TXN_LINE_T wpsfal,
	WSC_AHCS_LHIN_TXN_HEADER_T wlhinh,
	WSC_AHCS_LHIN_TXN_LINE_T wlhinl,
	WSC_AHCS_SXE_TXN_HEADER_T wsxeh,
	WSC_AHCS_SXE_TXN_LINE_T wsxel, 
	WSC_AHCS_ECLIPSE_TXN_HEADER_T weclh,
	WSC_AHCS_ECLIPSE_TXN_LINE_T wecll,
	WSC_AHCS_TW_TXN_HEADER_T wtwh,
	WSC_AHCS_TW_TXN_LINE_T wtwl,
	WSC_AHCS_CP_TXN_HEADER_T wcph,
	WSC_AHCS_CP_TXN_LINE_T wcpl

Where
-- changed decode statement (INC2693472)
nvl( 
decode(wais.interface_id,
'SALE','SII','CASH','CRI','LSIR','LSI',
'SPER','SPR','ARIN','ARI','IFRT','FII',
'COQI','CQI','OFRT','FTI','INTR','ICI',
'INVT','ISI','SPEC','SPC','IBIN','IBI',
'IRIN','IRI','DAIN','DAI','AIIB','AII',
substr(wais.interface_id,1,3))
,'X') = nvl(P_SOURCE_SYSTEM,nvl(wais.INTERFACE_ID,'X'))
AND decode(wais.application,'EBS AP',wais.header_id,null)=wapth.header_id(+)
AND decode(wais.application,'EBS AP',wais.header_id,null)=waptl.HEADER_ID(+)
AND decode(wais.application,'EBS AP',wais.line_id,null)=waptl.line_id(+)
AND decode(wais.application,'EBS AR',wais.header_id,null)=warth.header_id(+)
AND decode(wais.application,'EBS AR',wais.header_id,null)=wartl.HEADER_ID(+)
AND decode(wais.application,'EBS AR',wais.line_id,null)=wartl.line_id(+)
AND decode(wais.application,'EBS FA',wais.header_id,null)=wfath.header_id(+)
AND decode(wais.application,'EBS FA',wais.header_id,null)=wfatl.HEADER_ID(+)
AND decode(wais.application,'EBS FA',wais.line_id,null)=wfatl.line_id(+)
AND decode(wais.application,'ERP_POC',wais.header_id,null)=wpocth.header_id(+)
AND decode(wais.application,'ERP_POC',wais.header_id,null)=wpoctl.HEADER_ID(+)
AND decode(wais.application,'ERP_POC',wais.line_id,null)=wpoctl.line_id(+) 
AND decode(wais.application,'MF AP',wais.header_id,null)=wmfaph.header_id(+)
AND decode(wais.application,'MF AP',wais.header_id,null)=wmfapl.HEADER_ID(+)
AND decode(wais.application,'MF AP',wais.line_id,null)=wmfapl.line_id(+)
AND decode(wais.application,'MF AR',wais.header_id,null)=wmfarh.header_id(+)
AND decode(wais.application,'MF AR',wais.header_id,null)=wmfarl.HEADER_ID(+)
AND decode(wais.application,'MF AR',wais.line_id,null)=wmfarl.line_id(+)
AND decode(wais.application,'MF INV',wais.header_id,null)=wmfinvh.header_id(+)
AND decode(wais.application,'MF INV',wais.header_id,null)=wmfinvl.HEADER_ID(+)
AND decode(wais.application,'MF INV',wais.line_id,null)=wmfinvl.line_id(+)
AND decode(wais.application,'PS FA',wais.header_id,null)=wpsfah.header_id(+)
AND decode(wais.application,'PS FA',wais.header_id,null)=wpsfal.HEADER_ID(+)
AND decode(wais.application,'PS FA',wais.line_id,null)=wpsfal.line_id(+)
AND decode(wais.application,'LEASES',wais.header_id,null)=wlhinh.header_id(+)
AND decode(wais.application,'LEASES',wais.header_id,null)=wlhinl.HEADER_ID(+)
AND decode(wais.application,'LEASES',wais.line_id,null)=wlhinl.line_id(+)
AND decode(wais.application,'SXE',wais.header_id,null)=wsxeh.header_id(+)
AND decode(wais.application,'SXE',wais.header_id,null)=wsxel.HEADER_ID(+)
AND decode(wais.application,'SXE',wais.line_id,null)=wsxel.line_id(+)
AND decode(wais.application,'ECLIPSE',wais.header_id,null)=weclh.header_id(+)
AND decode(wais.application,'ECLIPSE',wais.header_id,null)=wecll.HEADER_ID(+)
AND decode(wais.application,'ECLIPSE',wais.line_id,null)=wecll.line_id(+)
AND decode(wais.application,'TW',wais.header_id,null)=wtwh.header_id(+)
AND decode(wais.application,'TW',wais.header_id,null)=wtwl.HEADER_ID(+)
AND decode(wais.application,'TW',wais.line_id,null)=wtwl.line_id(+)
AND decode(wais.application,'CLOUDPAY',wais.header_id,null)=wcph.header_id(+)
AND decode(wais.application,'CLOUDPAY',wais.header_id,null)=wcpl.HEADER_ID(+)
AND decode(wais.application,'CLOUDPAY',wais.line_id,null)=wcpl.line_id(+)
AND decode(wais.status,'TRANSFORM_SUCCESS',NVL(wais.Accounting_status,'NA'),wais.status)!=decode(wais.status,'TRANSFORM_SUCCESS',NVL2(wais.Accounting_status,'CRE_ACC_SUCCESS','NA'),'TRANSFORM_SUCCESS')
AND decode(wais.status,'TRANSFORM_SUCCESS',NVL(wais.Accounting_status,'NA'),wais.status)!=decode(wais.status,'TRANSFORM_SUCCESS',NVL2(wais.Accounting_status,'IMP_ACC_SUCCESS','NA'),'TRANSFORM_SUCCESS')
AND decode(wais.application,'ERP_POC','ERP POC','CENTRAL','Central','ECLIPSE','ECLPS','SXE','SXEUS','TW','APS Treasury','MF INV','MF INVENTORY',wais.application)=P_APPLICATION
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