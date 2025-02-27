--------------------------------------------------------
--  File created - Monday-September-05-2022   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Table WSC_AHCS_CP_TXN_HEADER_T
--------------------------------------------------------

  CREATE TABLE "FININT"."WSC_AHCS_CP_TXN_HEADER_T" 
   (	"BATCH_ID" NUMBER, 
	"HEADER_ID" NUMBER, 
	"TRANSACTION_TYPE" VARCHAR2(10 BYTE), 
	"LEDGER_NAME" VARCHAR2(20 BYTE), 
	"TRANSACTION_DATE" DATE, 
	"TRANSACTION_NUMBER" VARCHAR2(100 BYTE), 
	"FILE_NAME" VARCHAR2(100 BYTE), 
	"ATTRIBUTE1" NUMBER, 
	"ATTRIBUTE2" NUMBER, 
	"ATTRIBUTE3" NUMBER, 
	"ATTRIBUTE4" NUMBER, 
	"ATTRIBUTE5" NUMBER, 
	"ATTRIBUTE6" DATE, 
	"ATTRIBUTE7" DATE, 
	"ATTRIBUTE8" VARCHAR2(240 BYTE), 
	"ATTRIBUTE9" VARCHAR2(240 BYTE), 
	"ATTRIBUTE10" VARCHAR2(240 BYTE), 
	"ATTRIBUTE11" VARCHAR2(1000 BYTE), 
	"ATTRIBUTE12" VARCHAR2(1000 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(100 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(100 BYTE), 
	 CONSTRAINT "WSC_AHCS_CP_TXN_HEADER_T_PK" PRIMARY KEY ("HEADER_ID"));
  
 

--------------------------------------------------------
--  DDL for Table WSC_AHCS_CP_TXN_LINE_T
--------------------------------------------------------


  CREATE TABLE "FININT"."WSC_AHCS_CP_TXN_LINE_T" 
   (	"BATCH_ID" NUMBER, 
	"HEADER_ID" NUMBER, 
	"LINE_ID" NUMBER, 
	"ACCOUNTING_DATE" DATE, 
	"DEFAULT_AMT" NUMBER, 
	"DR" NUMBER, 
	"CR" NUMBER, 
	"DEFAULT_CURRENCY" VARCHAR2(5 CHAR), 
	"CONVERSION_RATE_TYPE" VARCHAR2(20 CHAR), 
	"COMPANY_NUM" VARCHAR2(15 CHAR), 
	"PAY_CODE" VARCHAR2(30 CHAR), 
	"GL_CODE" VARCHAR2(30 CHAR), 
	"COST_CENTER_NAME" VARCHAR2(30 CHAR), 
	"GL_LEGAL_ENTITY" VARCHAR2(20 CHAR), 
	"GL_OPER_GRP" VARCHAR2(20 CHAR), 
	"GL_ACCT" VARCHAR2(20 CHAR), 
	"GL_DEPT" VARCHAR2(20 CHAR), 
	"GL_SITE" VARCHAR2(20 CHAR), 
	"GL_IC" VARCHAR2(20 CHAR), 
	"GL_PROJECTS" VARCHAR2(20 CHAR), 
	"GL_FUT_1" VARCHAR2(20 CHAR), 
	"GL_FUT_2" VARCHAR2(20 CHAR), 
	"PAY_CODE_DESC" VARCHAR2(50 CHAR), 
	"LEG_SEG_1_4" VARCHAR2(50 CHAR), 
	"TRANSACTION_NUMBER" VARCHAR2(100 CHAR), 
	"LEG_COA" VARCHAR2(100 CHAR), 
	"TARGET_COA" VARCHAR2(100 CHAR), 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(100 CHAR), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(100 CHAR), 
	"ATTRIBUTE1" VARCHAR2(10 BYTE), 
	"ATTRIBUTE2" NUMBER, 
	"ATTRIBUTE3" NUMBER, 
	"ATTRIBUTE4" NUMBER, 
	"ATTRIBUTE5" NUMBER, 
	"ATTRIBUTE6" DATE, 
	"ATTRIBUTE7" DATE, 
	"ATTRIBUTE8" VARCHAR2(240 CHAR), 
	"ATTRIBUTE9" VARCHAR2(240 CHAR), 
	"ATTRIBUTE10" VARCHAR2(240 CHAR), 
	"ATTRIBUTE11" VARCHAR2(1000 CHAR), 
	"ATTRIBUTE12" VARCHAR2(1000 CHAR), 
	"LEG_BU" VARCHAR2(20 CHAR), 
	"LEG_LOC" VARCHAR2(20 CHAR), 
	"LEG_ACCT" VARCHAR2(20 CHAR), 
	"LEG_DEPT" VARCHAR2(20 CHAR), 
	"LINE_SEQ_NBR" NUMBER(10,0), 
	 CONSTRAINT "WSC_AHCS_CP_TXN_LINE_T_PK" PRIMARY KEY ("LINE_ID") );
	
	
COMMIT;