--------------------------------------------------------
--  DDL for Index WSC_AHCS_CENTRAL_TXN_LINE_T_I
--------------------------------------------------------
  PROMPT "CREATING INDEX WSC_AHCS_CENTRAL_TXN_LINE_T_I";

  CREATE INDEX "FININT"."WSC_AHCS_CENTRAL_TXN_LINE_T_I" ON "FININT"."WSC_AHCS_CENTRAL_TXN_LINE_T" ("LINE_ID") COMPUTE STATISTICS;
--------------------------------------------------------
--  DDL for Index WSC_AHCS_CENTRAL_TXN_LINE_LEG_COA_I
--------------------------------------------------------
  PROMPT "CREATING INDEX WSC_AHCS_CENTRAL_TXN_LINE_LEG_COA_I";

  CREATE INDEX "FININT"."WSC_AHCS_CENTRAL_TXN_LINE_LEG_COA_I" ON "FININT"."WSC_AHCS_CENTRAL_TXN_LINE_T" ("LEG_COA") COMPUTE STATISTICS;
--------------------------------------------------------
--  DDL for Index WSC_AHCS_CENTRAL_TXN_LINE_BATCH_ID_I
--------------------------------------------------------
  PROMPT "CREATING INDEX WSC_AHCS_CENTRAL_TXN_LINE_BATCH_ID_I";

  CREATE INDEX "FININT"."WSC_AHCS_CENTRAL_TXN_LINE_BATCH_ID_I" ON "FININT"."WSC_AHCS_CENTRAL_TXN_LINE_T" ("BATCH_ID") COMPUTE STATISTICS;

--------------------------------------------------------
--  DDL for Index WSC_AHCS_CENTRAL_TXN_HEADER_T_I
--------------------------------------------------------  
  
  PROMPT "CREATING INDEX WSC_AHCS_CENTRAL_TXN_HEADER_T_I";
  
  CREATE INDEX "FININT"."WSC_AHCS_CENTRAL_TXN_HEADER_T_I" ON "FININT"."WSC_AHCS_CENTRAL_TXN_LINE_T" ("HEADER_ID") COMPUTE STATISTICS;

COMMIT;