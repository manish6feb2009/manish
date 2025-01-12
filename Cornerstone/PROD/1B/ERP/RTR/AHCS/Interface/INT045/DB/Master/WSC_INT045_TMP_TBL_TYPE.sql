--------------------------------------------------------
--  DDL for Type WSC_AHCS_TW_TXN_TMP_T_TYPE
--------------------------------------------------------

create or replace TYPE          "WSC_AHCS_TW_TXN_TMP_T_TYPE" FORCE AS OBJECT
(	"BATCH_ID" NUMBER, 
	"DATA_STRING" VARCHAR2(2000 BYTE)
);


/

--------------------------------------------------------
--  DDL for Type WSC_AHCS_TW_TXN_TMP_T_TYPE_TABLE
--------------------------------------------------------

create or replace TYPE          "WSC_AHCS_TW_TXN_TMP_T_TYPE_TABLE" 
FORCE AS TABLE OF WSC_AHCS_TW_TXN_TMP_T_TYPE;



/
