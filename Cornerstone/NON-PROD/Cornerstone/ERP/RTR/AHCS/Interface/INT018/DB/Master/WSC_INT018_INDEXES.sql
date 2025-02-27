--------------------------------------------------------
--  File created - Monday-September-05-2022   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Index
--------------------------------------------------------
CREATE INDEX "FININT"."WSC_AHCS_CP_TXN_HEADER_BATCH_ID_I" ON "FININT"."WSC_AHCS_CP_TXN_HEADER_T" ("BATCH_ID") ;
CREATE INDEX "FININT"."WSC_AHCS_CP_TXN_LINE_BATCH_ID_I" ON "FININT"."WSC_AHCS_CP_TXN_LINE_T" ("BATCH_ID");
CREATE INDEX "FININT"."WSC_AHCS_CP_TXN_LINE_LEG_COA_I" ON "FININT"."WSC_AHCS_CP_TXN_LINE_T" ("LEG_COA");

ALTER INDEX WSC_AHCS_CP_TXN_HEADER_BATCH_ID_I REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_CP_TXN_LINE_BATCH_ID_I REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_CP_TXN_LINE_LEG_COA_I REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_CP_TXN_HEADER_T_PK REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_CP_TXN_LINE_T_PK REBUILD COMPUTE STATISTICS;

commit;