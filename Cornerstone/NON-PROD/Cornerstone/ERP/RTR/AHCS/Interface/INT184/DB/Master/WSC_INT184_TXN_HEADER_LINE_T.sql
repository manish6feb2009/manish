
  
  CREATE TABLE "FININT"."WSC_AHCS_PSFA_TXN_HEADER_T" 
   (	"BATCH_ID" NUMBER, 
	"HEADER_ID" NUMBER, 
	"HDR_SEQ_NBR" NUMBER, 
	"FISCAL_YEAR" NUMBER, 
	"ACCOUNTING_PERIOD" NUMBER, 
	"COST" NUMBER, 
	"LTD_DEP" NUMBER, 
	"NBV" NUMBER, 
	"ACCOUNTING_DATE" DATE, 
	"TRANS_DATE" DATE, 
	"ASSET_ID" VARCHAR2(20 BYTE), 
	"JOURNAL_ID" VARCHAR2(20 BYTE), 
	"LEDGER_NAME" VARCHAR2(100 BYTE), 
	"TRANSACTION_NUMBER" VARCHAR2(100 BYTE), 
	"BOOK" VARCHAR2(100 BYTE), 
	"TRANS_TYPE" VARCHAR2(100 BYTE), 
	"CATEGORY" VARCHAR2(100 BYTE), 
	"PROFILE_ID" VARCHAR2(100 BYTE), 
	"CAP_NUM" VARCHAR2(100 BYTE), 
	"INVOICE" VARCHAR2(100 BYTE), 
	"FILE_NAME" VARCHAR2(100 BYTE), 
	"DESCR" VARCHAR2(1000 BYTE), 
	"CREATION_DATE" DATE, 
	"CREATED_BY" VARCHAR2(100 BYTE), 
	"LAST_UPDATE_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(100 BYTE), 
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
        "LEG_AFFILIATE" VARCHAR2(5 BYTE), 
	 CONSTRAINT "WSC_AHCS_PSFA_TXN_HEADER_T_PK" PRIMARY KEY ("HEADER_ID"));
  
  
  
  
  CREATE TABLE "FININT"."WSC_AHCS_PSFA_TXN_LINE_T" 
   (	"BATCH_ID" NUMBER, 
	"LINE_ID" NUMBER, 
	"HEADER_ID" NUMBER, 
	"LINE_SEQ_NUMBER" NUMBER, 
	"HDR_SEQ_NBR" NUMBER, 
	"TXN_AMOUNT" NUMBER, 
	"AMOUNT" NUMBER, 
	"RATE_EFFDT" DATE, 
	"GL_LEGAL_ENTITY" VARCHAR2(20 BYTE), 
	"GL_OPER_GRP" VARCHAR2(20 BYTE), 
	"GL_ACCT" VARCHAR2(20 BYTE), 
	"GL_DEPT" VARCHAR2(20 BYTE), 
	"GL_SITE" VARCHAR2(20 BYTE), 
	"GL_IC" VARCHAR2(20 BYTE), 
	"GL_PROJECTS" VARCHAR2(20 BYTE), 
	"GL_FUT_1" VARCHAR2(20 BYTE), 
	"GL_FUT_2" VARCHAR2(20 BYTE), 
	"TRANSACTION_NUMBER" VARCHAR2(100 BYTE), 
	"TXN_CURRENCY_CD" VARCHAR2(100 BYTE), 
	"CURRENCY_CD" VARCHAR2(100 BYTE), 
	"UNIT" VARCHAR2(100 BYTE), 
	"ACCOUNT" VARCHAR2(100 BYTE), 
	"DEPT_ID" VARCHAR2(100 BYTE), 
	"ANIXTER_VENDOR" VARCHAR2(100 BYTE), 
	"LOCATION" VARCHAR2(100 BYTE), 
	"LEG_COA" VARCHAR2(100 BYTE), 
	"TARGET_COA" VARCHAR2(100 BYTE), 
	"LEG_SEG_1_4" VARCHAR2(100 BYTE), 
	"LEG_SEG_5_7" VARCHAR2(100 BYTE), 
	"DISTRIBUTION_TYPE" VARCHAR2(100 BYTE), 
	"RATE_TYPE" VARCHAR2(100 BYTE), 
	"CREATION_DATE" DATE, 
	"CREATED_BY" VARCHAR2(100 BYTE), 
	"LAST_UPDATE_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(100 BYTE), 
	"ATTRIBUTE1" VARCHAR2(20 BYTE), 
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
	"DR_CR_FLAG" VARCHAR2(10 BYTE), 
        "LEG_AFFILIATE" VARCHAR2(5 BYTE), 
	 CONSTRAINT "WSC_AHCS_PSFA_LINE_TXN_T_PK" PRIMARY KEY ("LINE_ID"));
	 
	 COMMIT;