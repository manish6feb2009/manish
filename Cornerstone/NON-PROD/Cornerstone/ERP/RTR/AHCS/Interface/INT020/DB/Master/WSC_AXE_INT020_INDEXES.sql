--+========================================================================|
--| RICE_ID             : INT020 - Daily Feed From LHIN to Oracle ERP
--| Module/Object Name  : WSC_AXE_LHIN_INDEX.sql
--|
--| Description         : Object to contain Lease Harbor Table Indexes creation Script
--|
--| Creation Date       : 17-MAY-2022
--|
--| Author              : Syed Zafer Ali
--|
--+========================================================================|
--| Modification History
--+========================================================================|
--| Date			Who					Version	    Change Description
--| -----------------------------------------------------------------------|
--| 17-MAY-2022	Syed Zafer Ali   	Draft	    Initial draft version  |
--+========================================================================|

-- DROP INDEX WSC_AHCS_POC_TXN_HEADER_BATCH_ID_I;
-- DROP INDEX WSC_AHCS_POC_TXN_LINE_BATCH_ID_I;
-- DROP INDEX WSC_AHCS_POC_TXN_LINE_HEADER_ID_I;
-- DROP INDEX WSC_AHCS_POC_TXN_LINE_JE_HEADER_ID_I;
-- DROP INDEX WSC_AHCS_POC_TXN_HEADER_JE_HEADER_ID_I;
-- DROP INDEX WSC_AHCS_POC_TXN_LINE_LEG_COA_I;
-- /

CREATE INDEX "FININT"."WSC_AHCS_LHIN_TXN_HEADER_FILE_ID_I" ON "FININT"."WSC_AHCS_LHIN_TXN_HEADER_T" ("FILE_ID");
CREATE INDEX "FININT"."WSC_AHCS_LHIN_TXN_HEADER_BATCH_ID_I" ON "FININT"."WSC_AHCS_LHIN_TXN_HEADER_T" ("BATCH_ID");
CREATE INDEX "FININT"."WSC_AHCS_LHIN_TXN_LINE_FILE_ID_I" ON "FININT"."WSC_AHCS_LHIN_TXN_LINE_T" ("FILE_ID");
CREATE INDEX "FININT"."WSC_AHCS_LHIN_TXN_LINE_LEG_COA_I" ON "FININT"."WSC_AHCS_LHIN_TXN_LINE_T" ("LEG_COA");
CREATE INDEX "FININT"."WSC_AHCS_LHIN_TXN_LINE_BATCH_ID_I" ON "FININT"."WSC_AHCS_LHIN_TXN_LINE_T" ("BATCH_ID");
CREATE INDEX "FININT"."WSC_AHCS_LHIN_TXN_LINE_HEADER_ID_I" ON "FININT"."WSC_AHCS_LHIN_TXN_LINE_T" ("HEADER_ID");
CREATE INDEX "FININT"."WSC_AHCS_LHIN_TXN_TXN_TMP_BATCH_ID_I" ON "FININT"."WSC_AHCS_LHIN_TXN_TMP_T" ("BATCH_ID");

ALTER INDEX WSC_AHCS_LHIN_TXN_HEADER_FILE_ID_I REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_LHIN_TXN_HEADER_BATCH_ID_I REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_LHIN_TXN_HEADER_T_PK REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_LHIN_TXN_LINE_FILE_ID_I REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_LHIN_TXN_LINE_LEG_COA_I REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_LHIN_TXN_LINE_BATCH_ID_I REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_LHIN_TXN_LINE_HEADER_ID_I REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_LHIN_TXN_LINE_T_PK REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_LHIN_TXN_TXN_TMP_BATCH_ID_I REBUILD COMPUTE STATISTICS;

commit;