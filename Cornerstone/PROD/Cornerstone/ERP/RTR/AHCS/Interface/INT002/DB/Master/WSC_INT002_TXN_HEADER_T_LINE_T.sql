--+========================================================================|
--| RICE_ID             : INT002 - WESCO EBS AP Inbound to AHCS
--| Module/Object Name  : WSC_AHCS_AP_TXN_HEADER_T.sql
--|
--| Description         : Object to create staging table for EBS AP Header Script
--|
--| Creation Date       : 06-SEPT-2021
--|
--| Author              : Jigyasa Kamthan
--|
--+========================================================================|
--| Modification History
--+========================================================================|
--| Date			Who					Version	    Change Description
--| -----------------------------------------------------------------------|
--| 				Jigyasa Kamthan  	Draft	    Initial draft version  |
--+========================================================================|

 
  CREATE TABLE "FININT"."WSC_AHCS_AP_TXN_HEADER_T" 
   (	"BATCH_ID" NUMBER, 
	"HEADER_ID" NUMBER, 
	"SOURCE_TRN_NBR" VARCHAR2(100 BYTE), 
	"SOURCE_SYSTEM" VARCHAR2(100 BYTE), 
	"LEG_HEADER_ID" NUMBER, 
	"TRD_PARTNER_NAME" VARCHAR2(100 BYTE), 
	"TRD_PARTNER_NBR" VARCHAR2(100 BYTE), 
	"TRD_PARTNER_SITE" VARCHAR2(100 BYTE), 
	"EVENT_TYPE" VARCHAR2(100 BYTE), 
	"EVENT_CLASS" VARCHAR2(100 BYTE), 
	"TRN_AMOUNT" NUMBER, 
	"ACC_DATE" DATE, 
	"HEADER_DESC" VARCHAR2(2000 BYTE), 
	"LEG_LED_NAME" VARCHAR2(100 BYTE), 
	"JE_BATCH_NAME" VARCHAR2(100 BYTE), 
	"JE_NAME" VARCHAR2(100 BYTE), 
	"JE_CATEGORY" VARCHAR2(100 BYTE), 
	"FILE_NAME" VARCHAR2(100 BYTE), 
	"TRANSACTION_DATE" DATE, 
	"TRANSACTION_NUMBER" VARCHAR2(100 BYTE), 
	"LEDGER_NAME" VARCHAR2(100 BYTE), 
	"TRN_TYPE" VARCHAR2(100 BYTE), 
	"CREATED_BY" VARCHAR2(100 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(100 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"ATTRIBUTE1" VARCHAR2(100 BYTE), 
	"ATTRIBUTE2" VARCHAR2(100 BYTE), 
	"ATTRIBUTE3" VARCHAR2(100 BYTE), 
	"ATTRIBUTE4" VARCHAR2(100 BYTE), 
	"ATTRIBUTE5" VARCHAR2(100 BYTE), 
	"ATTRIBUTE6" NUMBER, 
	"ATTRIBUTE7" NUMBER, 
	"ATTRIBUTE8" NUMBER, 
	"ATTRIBUTE9" NUMBER, 
	"ATTRIBUTE10" NUMBER, 
	"ATTRIBUTE11" DATE, 
	"ATTRIBUTE12" DATE, 
	 CONSTRAINT "WSC_AHCS_AP_TXN_HEADER_T_PK" PRIMARY KEY ("HEADER_ID")) ;
 
  
--+========================================================================|
--| RICE_ID             : INT002 - WESCO EBS AP Inbound to AHCS
--| Module/Object Name  : WSC_AHCS_AP_TXN_LINE_T.sql
--|
--| Description         : Object to create staging table for EBS AP Line Script
--|
--| Creation Date       : 06-SEPT-2021
--|
--| Author              : Jigyasa Kamthan
--|
--+========================================================================|
--| Modification History
--+========================================================================|
--| Date			Who					Version	    Change Description
--| -----------------------------------------------------------------------|
--| 				Jigyasa Kamthan  	Draft	    Initial draft version  |
--+========================================================================|

  
  
  CREATE TABLE "FININT"."WSC_AHCS_AP_TXN_LINE_T" 
   (	"BATCH_ID" NUMBER, 
	"LINE_ID" NUMBER, 
	"HEADER_ID" NUMBER, 
	"SOURCE_TRN_NBR" VARCHAR2(100 BYTE), 
	"LEG_HEADER_ID" NUMBER, 
	"ENTERED_AMOUNT" NUMBER, 
	"ACC_AMT" NUMBER, 
	"ENTERED_CURRENCY" VARCHAR2(100 BYTE), 
	"ACC_CURRENCY" VARCHAR2(100 BYTE), 
	"LEG_SEG1" VARCHAR2(100 BYTE), 
	"LEG_SEG2" VARCHAR2(100 BYTE), 
	"LEG_SEG3" VARCHAR2(100 BYTE), 
	"LEG_SEG4" VARCHAR2(100 BYTE), 
	"LEG_SEG5" VARCHAR2(100 BYTE), 
	"LEG_SEG6" VARCHAR2(100 BYTE), 
	"LEG_SEG7" VARCHAR2(100 BYTE), 
	"ACC_CLASS" VARCHAR2(100 BYTE), 
	"DR_CR_FLAG" VARCHAR2(100 BYTE), 
	"LEG_AE_LINE_NBR" NUMBER, 
	"JE_LINE_NBR" NUMBER, 
	"LINE_DESC" VARCHAR2(2000 BYTE), 
	"FX_RATE" NUMBER, 
	"TRANSACTION_NUMBER" VARCHAR2(100 BYTE), 
	"LEG_COA" VARCHAR2(100 BYTE), 
	"GL_LEGAL_ENTITY" VARCHAR2(100 BYTE), 
	"GL_ACCT" VARCHAR2(100 BYTE), 
	"GL_OPER_GRP" VARCHAR2(100 BYTE), 
	"GL_DEPT" VARCHAR2(100 BYTE), 
	"GL_SITE" VARCHAR2(100 BYTE), 
	"GL_IC" VARCHAR2(100 BYTE), 
	"GL_PROJECTS" VARCHAR2(100 BYTE), 
	"GL_FUT_1" VARCHAR2(100 BYTE), 
	"GL_FUT_2" VARCHAR2(100 BYTE), 
	"TARGET_COA" VARCHAR2(200 BYTE), 
	"DEFAULT_AMOUNT" VARCHAR2(100 BYTE), 
	"DEFAULT_CURRENCY" VARCHAR2(100 BYTE), 
	"CREATED_BY" VARCHAR2(100 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(100 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LINE_TYPE" VARCHAR2(100 BYTE), 
	"ATTRIBUTE1" VARCHAR2(100 BYTE), 
	"ATTRIBUTE2" VARCHAR2(100 BYTE), 
	"ATTRIBUTE3" VARCHAR2(100 BYTE), 
	"ATTRIBUTE4" VARCHAR2(100 BYTE), 
	"ATTRIBUTE5" VARCHAR2(100 BYTE), 
	"ATTRIBUTE6" NUMBER, 
	"ATTRIBUTE7" NUMBER, 
	"ATTRIBUTE8" NUMBER, 
	"ATTRIBUTE9" NUMBER, 
	"ATTRIBUTE10" NUMBER, 
	"ATTRIBUTE11" DATE, 
	"ATTRIBUTE12" DATE, 
	 CONSTRAINT "WSC_AHCS_AP_TXN_LINE_T_PK" PRIMARY KEY ("LINE_ID"));




COMMIT;