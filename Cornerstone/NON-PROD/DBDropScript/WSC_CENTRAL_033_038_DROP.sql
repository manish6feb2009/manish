--------------------------------------------------------
--  DROP WSC_AHCS_CENTRAL_TXN_STG_T
--------------------------------------------------------
  PROMPT "DROPING TABLE WSC_AHCS_CENTRAL_TXN_STG_T";

  DROP TABLE "FININT"."WSC_AHCS_CENTRAL_TXN_STG_T";

--------------------------------------------------------
--  DROP WSC_AHCS_CENTRAL_TXN_HEADER_T
--------------------------------------------------------
  PROMPT "DROPING TABLE WSC_AHCS_CENTRAL_TXN_HEADER_T";

  DROP TABLE "FININT"."WSC_AHCS_CENTRAL_TXN_HEADER_T";
  
--------------------------------------------------------
--  DROP WSC_AHCS_CENTRAL_TXN_LINE_T
--------------------------------------------------------
  PROMPT "DROPING TABLE WSC_AHCS_CENTRAL_TXN_LINE_T";

  DROP TABLE "FININT"."WSC_AHCS_CENTRAL_TXN_LINE_T";

--------------------------------------------------------
--  DROP WSC_AHCS_CENTRAL_JE_CTG_MAP_T
--------------------------------------------------------
  PROMPT "DROPING TABLE WSC_AHCS_CENTRAL_JE_CTG_MAP_T";

  DROP TABLE "FININT"."WSC_AHCS_CENTRAL_JE_CTG_MAP_T";
  
--------------------------------------------------------
--  DROPING Sequence WSC_CTRL_HEADER_T_S1
--------------------------------------------------------
  PROMPT "DROPING SEQUENCE WSC_CTRL_HEADER_T_S1";

  DROP SEQUENCE "FININT"."WSC_CTRL_HEADER_T_S1";
  
--------------------------------------------------------
--  DROPING for Sequence WSC_CTRL_HEADER_T_S2
--------------------------------------------------------
   PROMPT "DROPING SEQUENCE WSC_CTRL_HEADER_T_S2";

   DROP SEQUENCE "FININT"."WSC_CTRL_HEADER_T_S2";
   
--------------------------------------------------------
--  DROPING for Sequence WSC_CTRL_LINE_T_S1
--------------------------------------------------------
    PROMPT "DROPING SEQUENCE WSC_CTRL_LINE_T_S1";

    DROP SEQUENCE "FININT"."WSC_CTRL_LINE_T_S1";
	
--------------------------------------------------------
--  Drop Type
--------------------------------------------------------
	PROMPT "DROPPING TYPES";
	DROP TYPE "FININT"."WSC_CENTRAL_S_TYPE_TABLE";
	DROP TYPE "FININT"."WSC_CENTRAL_S_TYPE";
	DROP TYPE "FININT"."WSC_CTRL_TXN_ID_S_TYPE_TABLE";
	DROP TYPE "FININT"."WSC_CTRL_TXN_ID_S_TYPE";