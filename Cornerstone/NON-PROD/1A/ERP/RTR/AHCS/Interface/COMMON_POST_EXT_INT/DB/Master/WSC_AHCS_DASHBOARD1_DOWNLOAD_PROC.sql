create or replace PROCEDURE wsc_ahcs_dashboard1_download(o_Clobdata OUT CLOB) IS 
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
            FROM (SELECT 'APPLICATION, FILE_NAME,FILE_PROCESSING_DATE, BATCH_ID, STAGED_RECORDS, STAGED_AMOUNT, PROCESSED_RECORDS, PROCESSED_AMOUNT, ERROR_REEXTRACT_RECORDS, ERROR_REEXTRACT_AMOUNT, ERROR_REPROCESS_RECORDS, ERROR_REPROCESS_AMOUNT, SKIPPED_RECORDS, SKIPPED_AMOUNT' AS Col_Value 
                    FROM Dual 
                  UNION ALL 
                  SELECT APPLICATION||','||FILE_NAME||','||FILE_PROCESSING_DATE||','||BATCH_ID||','||STAGED_RECORDS||','||STAGED_AMOUNT||','||PROCESSED_RECORDS||','||PROCESSED_AMOUNT||','||ERROR_REEXTRACT_RECORDS||','||ERROR_REEXTRACT_AMOUNT||','||ERROR_REPROCESS_RECORDS||','||ERROR_REPROCESS_AMOUNT||','||SKIPPED_RECORDS||','||SKIPPED_AMOUNT AS Col_Value 
                    FROM (Select APPLICATION,
                        FILE_NAME,
                        FILE_PROCESSING_DATE,
                        BATCH_ID,
                        STAGED_RECORDS,
                        STAGED_AMOUNT,
                        PROCESSED_RECORDS,
                        PROCESSED_AMOUNT,
                        ERROR_REEXTRACT_RECORDS,
                        ERROR_REEXTRACT_AMOUNT,
                        ERROR_REPROCESS_RECORDS,
                        ERROR_REPROCESS_AMOUNT,
                        SKIPPED_RECORDS,
                        SKIPPED_AMOUNT
                        FROM WSC_AHCS_DASHBOARD1_V order by batch_id desc,NVL(FILE_PROCESSING_DATE,'19-09-1900') desc))); 

  o_Clobdata := l_Clob; 
EXCEPTION 
  WHEN OTHERS THEN 
   DBMS_OUTPUT.PUT_LINE(SQLERRM); 
END;
/