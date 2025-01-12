

--------------------------------------------------------
--  DDL for Type WSC_CENTRAL_S_TYPE
--------------------------------------------------------

  PROMPT "CREATING TYPE WSC_CENTRAL_S_TYPE";

  CREATE OR REPLACE TYPE "FININT"."WSC_CENTRAL_S_TYPE" AS OBJECT 
( 
BATCHID NUMBER,
RICE_ID VARCHAR2(100),
DATA_STRING VARCHAR2(500)
)

/

--------------------------------------------------------
--  DDL for Type WSC_CENTRAL_S_TYPE_TABLE
--------------------------------------------------------
  PROMPT "CREATING TYPE WSC_CENTRAL_S_TYPE_TABLE";
  
  CREATE OR REPLACE  TYPE "FININT"."WSC_CENTRAL_S_TYPE_TABLE" 
AS TABLE OF WSC_CENTRAL_S_TYPE

/


--------------------------------------------------------
--  DDL for Type WSC_CTRL_TXN_ID_S_TYPE
--------------------------------------------------------
  PROMPT "CREATING TYPE WSC_CTRL_TXN_ID_S_TYPE";
  
  CREATE OR REPLACE  TYPE "FININT"."WSC_CTRL_TXN_ID_S_TYPE" AS OBJECT 
( JE_CODE VARCHAR2(100),
LEDGER_NAME VARCHAR2(100),
GL_LEGAL_ENTITY VARCHAR2(10),
GL_OPER_GRP VARCHAR2(10),
TRANSACTION_ID VARCHAR2(100),
HEADER_ID VARCHAR2(100)
)

/


--------------------------------------------------------
--  DDL for Type WSC_CTRL_TXN_ID_S_TYPE_TABLE
--------------------------------------------------------

  CREATE OR REPLACE  TYPE "FININT"."WSC_CTRL_TXN_ID_S_TYPE_TABLE" 
AS TABLE OF WSC_CTRL_TXN_ID_S_TYPE;
/