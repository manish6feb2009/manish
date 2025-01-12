--------------------------------------------------
--WSC_INTER_INTRA_COMPANY_BIR
--------------------------------------------------

create or replace TRIGGER  "WSC_INTER_INTRA_COMPANY_BIR" BEFORE INSERT ON WSC_INTER_INTRA_COMPANY_FILE_LINE_T
FOR EACH ROW
    WHEN (new."LINE_ID" IS NULL) BEGIN
  SELECT WSC_INTER_INTRA_COMPANY_SEQ_T.nextVal 
  INTO :new."LINE_ID" 
  FROM dual;
END;
/