create or replace TYPE WSC_MFAP_TMP_T_TYPE FORCE AS OBJECT 
( /* TODO enter attribute and method declarations here */ 
"BATCH_ID" NUMBER, 
"RICE_ID" VARCHAR2(50 BYTE), 
"DATA_STRING" VARCHAR2(2000 BYTE)
);

/


create or replace TYPE WSC_MFAP_TMP_T_TYPE_TABLE 
FORCE AS TABLE OF WSC_MFAP_TMP_T_TYPE;

/