--------------------------------------------------------
--Index WSC_AHCS_FA_TXN_HEADER_BATCH_ID_I
--------------------------------------------------------

  CREATE INDEX "FININT"."WSC_AHCS_FA_TXN_HEADER_BATCH_ID_I" ON "FININT"."WSC_AHCS_FA_TXN_HEADER_T" ("BATCH_ID");
--------------------------------------------------------
--Index WSC_AHCS_FA_TXN_HEADER_LEG_AE_HEADER_ID_I
--------------------------------------------------------

  CREATE INDEX "FININT"."WSC_AHCS_FA_TXN_HEADER_LEG_AE_HEADER_ID_I" ON "FININT"."WSC_AHCS_FA_TXN_HEADER_T" ("LEG_AE_HEADER_ID");
--------------------------------------------------------
--Index WSC_AHCS_FA_TXN_HEADER_T_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "FININT"."WSC_AHCS_FA_TXN_HEADER_T_PK" ON "FININT"."WSC_AHCS_FA_TXN_HEADER_T" ("HEADER_ID") ;

--------------------------------------------------------

ALTER INDEX WSC_AHCS_FA_TXN_HEADER_BATCH_ID_I REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_FA_TXN_HEADER_LEG_AE_HEADER_ID_I REBUILD COMPUTE STATISTICS;
ALTER TABLE "FININT"."WSC_AHCS_FA_TXN_HEADER_T" ADD CONSTRAINT "PRIMARY_KEY" PRIMARY KEY ("HEADER_ID")
USING INDEX "FININT"."WSC_AHCS_FA_TXN_HEADER_T_PK" ENABLE;

--------------------------------------------------------
--   Index WSC_AHCS_FA_TXN_LINE_LEG_AE_HEADER_ID_I
--------------------------------------------------------

  CREATE INDEX "FININT"."WSC_AHCS_FA_TXN_LINE_LEG_AE_HEADER_ID_I" ON "FININT"."WSC_AHCS_FA_TXN_LINE_T" ("LEG_AE_HEADER_ID");
--------------------------------------------------------
--   Index WSC_AHCS_FA_TXN_LINE_BATCH_ID_I
--------------------------------------------------------

  CREATE INDEX "FININT"."WSC_AHCS_FA_TXN_LINE_BATCH_ID_I" ON "FININT"."WSC_AHCS_FA_TXN_LINE_T" ("BATCH_ID");
--------------------------------------------------------
--   Index WSC_AHCS_FA_TXN_LINE_HEADER_ID_I
--------------------------------------------------------

  CREATE INDEX "FININT"."WSC_AHCS_FA_TXN_LINE_HEADER_ID_I" ON "FININT"."WSC_AHCS_FA_TXN_LINE_T" ("HEADER_ID");
--------------------------------------------------------
--   Index WSC_AHCS_FA_TXN_LINE_LEG_COA_I
--------------------------------------------------------

  CREATE INDEX "FININT"."WSC_AHCS_FA_TXN_LINE_LEG_COA_I" ON "FININT"."WSC_AHCS_FA_TXN_LINE_T" ("LEG_COA");
--------------------------------------------------------
--   Index WSC_AHCS_FA_TXN_LINE_T_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "FININT"."WSC_AHCS_FA_TXN_LINE_T_PK" ON "FININT"."WSC_AHCS_FA_TXN_LINE_T" ("LINE_ID");
--------------------------------------------------------
--  Constraints for Table WSC_AHCS_FA_TXN_LINE_T
--------------------------------------------------------
 
ALTER TABLE "FININT"."WSC_AHCS_FA_TXN_LINE_T" ADD CONSTRAINT "PRIMARY_KEY_LINE" PRIMARY KEY ("LINE_ID")
USING INDEX "FININT"."WSC_AHCS_FA_TXN_LINE_T_PK" ENABLE;
ALTER INDEX WSC_AHCS_FA_TXN_LINE_LEG_AE_HEADER_ID_I REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_FA_TXN_LINE_BATCH_ID_I REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_FA_TXN_LINE_HEADER_ID_I REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_FA_TXN_LINE_LEG_COA_I REBUILD COMPUTE STATISTICS;
