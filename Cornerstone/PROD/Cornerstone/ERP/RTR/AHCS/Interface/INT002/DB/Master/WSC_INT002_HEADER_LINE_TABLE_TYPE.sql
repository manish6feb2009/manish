--------------------------------------------------------
--  File created - Friday-September-03-2021   
--------------------------------------------------------
--+========================================================================|
--| RICE_ID             : INT002 - WESCO EBS AP Inbound to AHCS
--| Module/Object Name  : WSC_AP_HEADER_T_TYPE.sql
--|
--| Description         : Header table type creation Script
--|
--| Creation Date       : 03-SEPT-2021
--|
--| Author              : JIGYASA KAMTHAN
--|
--+========================================================================|
--| Modification History
--+========================================================================|
--| Date			Who					Version	    Change Description
--| -----------------------------------------------------------------------|
--| 03-SEPT-2021		JIGYASA KAMTHAN   	Draft	    Initial draft version  |
--+========================================================================|
--------------------------------------------------------
--  DDL for Type WSC_AP_HEADER_T_TYPE
--------------------------------------------------------

  CREATE OR REPLACE  TYPE "FININT"."WSC_AP_HEADER_T_TYPE" AS OBJECT 
( /* TODO enter attribute and method declarations here */ 
SOURCE_TRN_NBR VARCHAR2(100),
	SOURCE_SYSTEM VARCHAR2(100),
	LEG_HEADER_ID NUMBER, 
	TRD_PARTNER_NAME VARCHAR2(100),
	TRD_PARTNER_NBR VARCHAR2(100),
	TRD_PARTNER_SITE VARCHAR2(100),
	EVENT_TYPE VARCHAR2(100),
	EVENT_CLASS VARCHAR2(100),
	TRN_AMOUNT NUMBER, 
	ACC_DATE VARCHAR2(100) , 
	HEADER_DESC VARCHAR2(2000) , 
	LEG_LED_NAME VARCHAR2(100),
	JE_BATCH_NAME VARCHAR2(100),
	JE_NAME VARCHAR2(100),
	JE_CATEGORY VARCHAR2(100),
	FILE_NAME VARCHAR2(100),
	CREATED_BY VARCHAR2(100),
	CREATION_DATE VARCHAR2(100), 
	LAST_UPDATED_BY VARCHAR2(100),
	LAST_UPDATE_DATE VARCHAR2(100), 
	ATTRIBUTE1 VARCHAR2(100),
	ATTRIBUTE2 VARCHAR2(100),
	ATTRIBUTE3 VARCHAR2(100),
	ATTRIBUTE4 VARCHAR2(100),
	ATTRIBUTE5 VARCHAR2(100),
	ATTRIBUTE6 VARCHAR2(100),
	ATTRIBUTE7 VARCHAR2(100),
	ATTRIBUTE8 VARCHAR2(100),
	ATTRIBUTE9 VARCHAR2(100),
	ATTRIBUTE10 VARCHAR2(100),
	BATCH_ID VARCHAR2(100),
	HEADER_ID VARCHAR2(100),
	TRANSACTION_DATE VARCHAR2(100), 
	TRANSACTION_NUMBER VARCHAR2(100),
	LEDGER_NAME VARCHAR2(100),	
	TRN_TYPE VARCHAR2(100),
    ATTRIBUTE11 VARCHAR2(100),
	ATTRIBUTE12 VARCHAR2(100)
);

/ 
--------------------------------------------------------
-- DDL for Type WSC_AP_HEADER_T_TYPE_TABLE
--------------------------------------------------------

CREATE OR REPLACE TYPE "FININT"."WSC_AP_HEADER_T_TYPE_TABLE" 
AS TABLE OF WSC_AP_HEADER_T_TYPE;
/
--------------------------------------------------------
--  File created - Friday-September-03-2021   
--------------------------------------------------------
--+========================================================================|
--| RICE_ID             : INT002 - WESCO EBS AP Inbound to AHCS
--| Module/Object Name  : WSC_AP_LINE_T_TYPE.sql
--|
--| Description         : Line table type creation Script
--|
--| Creation Date       : 03-SEPT-2021
--|
--| Author              : JIGYASA KAMTHAN
--|
--+========================================================================|
--| Modification History
--+========================================================================|
--| Date			Who					Version	    Change Description
--| -----------------------------------------------------------------------|
--| 03-SEPT-2021		JIGYASA KAMTHAN   	Draft	    Initial draft version  |
--+========================================================================|
--------------------------------------------------------
--  DDL for Type WSC_AP_LINE_T_TYPE
--------------------------------------------------------

  CREATE OR REPLACE TYPE "FININT"."WSC_AP_LINE_T_TYPE" AS OBJECT 
( /* TODO enter attribute and method declarations here */ 
"SOURCE_TRN_NBR" VARCHAR2(100), 
	"LEG_HEADER_ID" NUMBER, 
	"ENTERED_AMOUNT" NUMBER, 
	"ACC_AMT" NUMBER, 
	"ENTERED_CURRENCY" VARCHAR2(100), 
	"ACC_CURRENCY" VARCHAR2(100), 
	"LEG_SEG1" VARCHAR2(100), 
	"LEG_SEG2" VARCHAR2(100), 
	"LEG_SEG3" VARCHAR2(100), 
	"LEG_SEG4" VARCHAR2(100), 
	"LEG_SEG5" VARCHAR2(100), 
	"LEG_SEG6" VARCHAR2(100), 
	"LEG_SEG7" VARCHAR2(100), 
	"ACC_CLASS" VARCHAR2(100), 
	"DR_CR_FLAG" VARCHAR2(100), 
	"LEG_AE_LINE_NBR" NUMBER, 
	"JE_LINE_NBR" NUMBER, 
	"LINE_DESC" VARCHAR2(2000),
	"FX_RATE" NUMBER, 
	"CREATED_BY" VARCHAR2(100), 
	"CREATION_DATE" VARCHAR2(100), 
	"LAST_UPDATED_BY" VARCHAR2(100), 
	"LAST_UPDATE_DATE" VARCHAR2(100),	
	"BATCH_ID" VARCHAR2(100), 
	"LINE_ID" VARCHAR2(100), 
	"TRANSACTION_NUMBER" VARCHAR2(100), 
	"LEG_COA" VARCHAR2(100), 
	"GL_LEGAL_ENTITY" VARCHAR2(100), 
	"GL_ACCT" VARCHAR2(100), 
	"GL_OPER_GRP" VARCHAR2(100), 
	"GL_DEPT" VARCHAR2(100), 
	"GL_SITE" VARCHAR2(100), 
	"GL_IC" VARCHAR2(100), 
	"GL_PROJECTS" VARCHAR2(100), 
	"GL_FUT_1" VARCHAR2(100), 
	"GL_FUT_2" VARCHAR2(1000),
	"LINE_TYPE" VARCHAR2(100), 
	"ATTRIBUTE1" VARCHAR2(100), 
	"ATTRIBUTE2" VARCHAR2(100), 
	"ATTRIBUTE3" VARCHAR2(100), 
	"ATTRIBUTE4" VARCHAR2(100), 
	"ATTRIBUTE5" VARCHAR2(100), 
	"ATTRIBUTE6" NUMBER, 
	"ATTRIBUTE7" NUMBER,
	"ATTRIBUTE8" NUMBER, 
	"ATTRIBUTE9" NUMBER, 
	"ATTRIBUTE10" NUMBER, 
	"ATTRIBUTE11" VARCHAR2(100), 
	"ATTRIBUTE12" VARCHAR2(100),
    "DEFAULT_AMOUNT" VARCHAR2(100),
    "DEFAULT_CURRENCY" VARCHAR2(100)
);

/

--------------------------------------------------------
--  DDL for Type WSC_AP_LINE_T_TYPE_TABLE
--------------------------------------------------------

  CREATE OR REPLACE TYPE "FININT"."WSC_AP_LINE_T_TYPE_TABLE" 
AS TABLE OF WSC_AP_LINE_T_TYPE;
/
