--------------------------------------------------------
--  DDL for Index WSC_AHCS_CRES_TXN_TMP_BATCH_ID_I
--------------------------------------------------------

  CREATE INDEX "FININT"."WSC_AHCS_CRES_TXN_TMP_BATCH_ID_I" ON "FININT"."WSC_AHCS_CRES_TXN_TMP_T" ("BATCH_ID") ;
  
--------------------------------------------------------
--  DDL for Index WSC_AHCS_CRES_TMP_T_REG_I
--------------------------------------------------------

  CREATE INDEX "FININT"."WSC_AHCS_CRES_TMP_T_REG_I" ON "FININT"."WSC_AHCS_CRES_TXN_TMP_T" ( REGEXP_SUBSTR ("DATA_STRING",'([^|]*)(\||$)',1,1,NULL,1)) ;
  
ALTER INDEX WSC_AHCS_CRES_TXN_TMP_BATCH_ID_I REBUILD COMPUTE STATISTICS;
ALTER INDEX WSC_AHCS_CRES_TMP_T_REG_I REBUILD COMPUTE STATISTICS;
commit;