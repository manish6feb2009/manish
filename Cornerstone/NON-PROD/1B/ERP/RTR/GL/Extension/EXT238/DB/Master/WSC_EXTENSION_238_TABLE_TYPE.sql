---------------------------------------------------
--WSC_USER_DATA_ACCESS_T_TYPE
---------------------------------------------------

create or replace TYPE WSC_USER_DATA_ACCESS_T_TYPE force AS  OBJECT(
    "LEDGER_INTER_ORG_NAME" VARCHAR2(240 BYTE), 
	"LEDGER_INTER_ORG_ID" NUMBER, 
	"LEGAL_ENTITY_ID" NUMBER, 
	"ACTIVE_FLAG" VARCHAR2(2 BYTE), 
	"USERNAME" VARCHAR2(100 BYTE), 
	"ENTITY_TYPE" VARCHAR2(20 BYTE), 
	"COMPLETION_DATE" DATE
);
/

---------------------------------------------------
--WSC_USER_DATA_ACCESS_T_TAB
---------------------------------------------------

create or replace TYPE WSC_USER_DATA_ACCESS_T_TAB AS TABLE OF WSC_USER_DATA_ACCESS_T_TYPE;
/