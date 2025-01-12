  /*==================================================*/
          /* INDEX WSC_AHCS_FLEX_SEGMENT_VALUE */
  /*==================================================*/
  CREATE INDEX "FININT"."WSC_AHCS_FLEX_SEGMENT_VALUE" ON "FININT"."WSC_GL_LEGAL_ENTITIES_T" ("FLEX_SEGMENT_VALUE") COMPUTE STATISTICS;

  /*==================================================*/
          /* INDEX WSC_AHCS_INT_CONTROL_T_PK */
  /*==================================================*/
  CREATE UNIQUE INDEX "FININT"."WSC_AHCS_INT_CONTROL_T_PK" ON "FININT"."WSC_AHCS_INT_CONTROL_T" ("BATCH_ID") COMPUTE STATISTICS;
  
  /*==================================================*/
           /*INDEX WSC_AHCS_INT_STATUS_ACC_STS_I*/
  /*==================================================*/
  CREATE INDEX "FININT"."WSC_AHCS_INT_STATUS_ACC_STS_I" ON "FININT"."WSC_AHCS_INT_STATUS_T" ("ACCOUNTING_STATUS") COMPUTE STATISTICS;
  
  
  /*==================================================*/
           /*INDEX WSC_AHCS_INT_STATUS_ATT2_STTS_I*/
  /*==================================================*/
  CREATE INDEX "FININT"."WSC_AHCS_INT_STATUS_ATT2_STTS_I" ON "FININT"."WSC_AHCS_INT_STATUS_T" ("ATTRIBUTE2") COMPUTE STATISTICS;
  
  
  /*==================================================*/
           /*INDEX WSC_AHCS_INT_STATUS_ATTRIBUTE3_T*/
  /*==================================================*/
  CREATE INDEX "FININT"."WSC_AHCS_INT_STATUS_ATTRIBUTE3_T" ON "FININT"."WSC_AHCS_INT_STATUS_T" ("ATTRIBUTE3") COMPUTE STATISTICS;
  
  
  /*==================================================*/
           /*INDEX WSC_AHCS_INT_STATUS_BATCH_ID_I*/
  /*==================================================*/
  CREATE INDEX "FININT"."WSC_AHCS_INT_STATUS_BATCH_ID_I" ON "FININT"."WSC_AHCS_INT_STATUS_T" ("BATCH_ID") COMPUTE STATISTICS;
  
  
  /*==================================================*/
           /*INDEX WSC_AHCS_INT_STATUS_FILENAME_I*/
  /*==================================================*/
  CREATE INDEX "FININT"."WSC_AHCS_INT_STATUS_FILENAME_I" ON "FININT"."WSC_AHCS_INT_STATUS_T" ("FILE_NAME") COMPUTE STATISTICS;
  
  
  /*==================================================*/
           /*INDEX WSC_AHCS_INT_STATUS_HEADER_ID_I*/
  /*==================================================*/
  CREATE INDEX "FININT"."WSC_AHCS_INT_STATUS_HEADER_ID_I" ON "FININT"."WSC_AHCS_INT_STATUS_T" ("HEADER_ID") COMPUTE STATISTICS;
  
  
  /*==================================================*/
           /*INDEX WSC_AHCS_INT_STATUS_LEG_HDR_ID_I*/
  /*==================================================*/
  CREATE INDEX "FININT"."WSC_AHCS_INT_STATUS_LEG_HDR_ID_I" ON "FININT"."WSC_AHCS_INT_STATUS_T" ("LEGACY_HEADER_ID") COMPUTE STATISTICS;
  
  
  /*==================================================*/
           /*INDEX WSC_AHCS_INT_STATUS_LEG_LINE_I*/
  /*==================================================*/
  CREATE INDEX "FININT"."WSC_AHCS_INT_STATUS_LEG_LINE_I" ON "FININT"."WSC_AHCS_INT_STATUS_T" ("LEGACY_LINE_NUMBER") COMPUTE STATISTICS;
  
  
  /*==================================================*/
           /*INDEX WSC_AHCS_INT_STATUS_LINE_ID_I*/
  /*==================================================*/
  CREATE INDEX "FININT"."WSC_AHCS_INT_STATUS_LINE_ID_I" ON "FININT"."WSC_AHCS_INT_STATUS_T" ("LINE_ID") COMPUTE STATISTICS;
  
  
  /*==================================================*/
           /*INDEX WSC_AHCS_INT_STATUS_STATUS_I*/
  /*==================================================*/
  CREATE INDEX "FININT"."WSC_AHCS_INT_STATUS_STATUS_I" ON "FININT"."WSC_AHCS_INT_STATUS_T" ("STATUS") COMPUTE STATISTICS;


