--------------------------------------------------------
--  DDL for Sequence WSC_CTRL_HEADER_T_S1
--------------------------------------------------------

   PROMPT "CREATING SEQUENCE WSC_CTRL_HEADER_T_S1";

   CREATE SEQUENCE  "FININT"."WSC_CTRL_HEADER_T_S1"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 200 ORDER  CYCLE  NOKEEP  NOSCALE  GLOBAL ;

   
--------------------------------------------------------
--  DDL for Sequence WSC_CTRL_HEADER_T_S2
--------------------------------------------------------
   PROMPT "CREATING SEQUENCE WSC_CTRL_HEADER_T_S2";
   
   CREATE SEQUENCE  "FININT"."WSC_CTRL_HEADER_T_S2"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 200 ORDER  CYCLE  NOKEEP  NOSCALE  GLOBAL ;
  
	
--------------------------------------------------------
--  DDL for Sequence WSC_CTRL_LINE_T_S1
--------------------------------------------------------
   PROMPT "CREATING SEQUENCE WSC_CTRL_LINE_T_S1";

   CREATE SEQUENCE  "FININT"."WSC_CTRL_LINE_T_S1"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 400 ORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;

COMMIT;