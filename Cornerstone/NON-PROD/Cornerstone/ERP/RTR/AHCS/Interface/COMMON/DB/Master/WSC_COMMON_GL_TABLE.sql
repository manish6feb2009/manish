  CREATE TABLE "FININT"."WSC_GL_LEGAL_ENTITIES_T" 
   (	"FLEX_SEGMENT_VALUE" NUMBER, 
	"LEGAL_ENTITY_ID" VARCHAR2(100 BYTE), 
	"LEGAL_ENTITY_NAME" VARCHAR2(100 BYTE), 
	"LEDGER_ID" VARCHAR2(100 BYTE), 
	"LEDGER_NAME" VARCHAR2(100 BYTE), 
	"CURRENCY_CODE" VARCHAR2(100 BYTE), 
	"ATTRIBUTE1" VARCHAR2(1000 BYTE), 
	"ATTRIBUTE2" VARCHAR2(1000 BYTE), 
	"ATTRIBUTE3" VARCHAR2(1000 BYTE), 
	"ATTRIBUTE4" VARCHAR2(1000 BYTE), 
	"ATTRIBUTE5" VARCHAR2(1000 BYTE), 
	"ATTRIBUTE6" VARCHAR2(1000 BYTE), 
	"ATTRIBUTE7" VARCHAR2(1000 BYTE), 
	"ATTRIBUTE8" VARCHAR2(1000 BYTE), 
	"ATTRIBUTE9" VARCHAR2(1000 BYTE), 
	"ATTRIBUTE10" VARCHAR2(1000 BYTE), 
	"CREATION_DATE" DATE DEFAULT SYSDATE, 
	"CREATED_BY" VARCHAR2(200 BYTE), 
	"LAST_UPDATE_DATE" DATE DEFAULT SYSDATE, 
	"LAST_UPDATED_BY" VARCHAR2(200 BYTE), 
	"LAST_UPDATED_LOGIN" NUMBER
   );



  /*================================================*/
           /*TABLE WSC_AHCS_INT_CONTROL_T*/
  /*================================================*/

  CREATE TABLE "FININT"."WSC_AHCS_INT_CONTROL_T" 
   (	"BATCH_ID" VARCHAR2(200 BYTE) NOT NULL ENABLE, 
	"SOURCE_APPLICATION" VARCHAR2(200 BYTE), 
	"TARGET_APPLICATION" VARCHAR2(200 BYTE), 
	"FILE_NAME" VARCHAR2(500 BYTE), 
	"STATUS" VARCHAR2(200 BYTE) NOT NULL ENABLE, 
	"TOTAL_RECORDS" NUMBER, 
	"TOTAL_CREDITS" VARCHAR2(200 BYTE), 
	"TOTAL_DEBITS" VARCHAR2(200 BYTE), 
	"UCM_ID" VARCHAR2(200 BYTE), 
	"IMPORT_ACC_ID" VARCHAR2(200 BYTE), 
	"CREATE_ACC_ID" VARCHAR2(200 BYTE), 
	"ATTRIBUTE1" VARCHAR2(200 BYTE), 
	"ATTRIBUTE2" VARCHAR2(200 BYTE), 
	"ATTRIBUTE3" VARCHAR2(200 BYTE), 
	"ATTRIBUTE4" VARCHAR2(200 BYTE), 
	"ATTRIBUTE5" VARCHAR2(200 BYTE), 
	"SOURCE_SYSTEM" VARCHAR2(200 BYTE), 
	"TARGET_SYSTEM" VARCHAR2(200 BYTE), 
	"CREATED_BY" VARCHAR2(200 BYTE), 
	"CREATED_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(200 BYTE), 
	"LAST_UPDATED_DATE" TIMESTAMP (6), 
	"ATTRIBUTE6" NUMBER, 
	"ATTRIBUTE7" NUMBER, 
	"ATTRIBUTE8" NUMBER, 
	"ATTRIBUTE9" NUMBER, 
	"ATTRIBUTE10" NUMBER, 
	"ATTRIBUTE11" DATE, 
	"ATTRIBUTE12" DATE, 
	"ERROR_FILE_SENT_FLAG" VARCHAR2(1 BYTE)
   ) ;
   


  /*================================================*/
           /*TABLE WSC_AHCS_INT_STATUS_T*/
  /*================================================*/

 CREATE TABLE "FININT"."WSC_AHCS_INT_STATUS_T" 
   (	"HEADER_ID" NUMBER, 
	"LINE_ID" NUMBER, 
	"APPLICATION" VARCHAR2(200 BYTE), 
	"FILE_NAME" VARCHAR2(500 BYTE), 
	"BATCH_ID" NUMBER, 
	"STATUS" VARCHAR2(200 BYTE), 
	"ERROR_MSG" VARCHAR2(200 BYTE), 
	"ACCOUNTING_STATUS" VARCHAR2(200 BYTE), 
	"REEXTRACT_REQUIRED" VARCHAR2(200 BYTE), 
	"ACCOUNTING_ERROR_MSG" VARCHAR2(4000 BYTE), 
	"CR_DR_INDICATOR" VARCHAR2(200 BYTE), 
	"CURRENCY" VARCHAR2(200 BYTE), 
	"VALUE" VARCHAR2(200 BYTE), 
	"SOURCE_COA" VARCHAR2(200 BYTE), 
	"TARGET_COA" VARCHAR2(200 BYTE), 
	"ATTRIBUTE1" VARCHAR2(200 BYTE), 
	"ATTRIBUTE2" VARCHAR2(200 BYTE), 
	"ATTRIBUTE3" VARCHAR2(200 BYTE), 
	"LEGACY_HEADER_ID" NUMBER, 
	"LEGACY_LINE_NUMBER" NUMBER, 
	"CREATED_BY" VARCHAR2(200 BYTE), 
	"CREATED_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(200 BYTE), 
	"LAST_UPDATED_DATE" TIMESTAMP (6), 
	"ATTRIBUTE4" VARCHAR2(200 BYTE), 
	"ATTRIBUTE5" VARCHAR2(200 BYTE), 
	"ATTRIBUTE6" NUMBER, 
	"ATTRIBUTE7" NUMBER, 
	"ATTRIBUTE8" NUMBER, 
	"ATTRIBUTE9" NUMBER, 
	"ATTRIBUTE10" NUMBER, 
	"ATTRIBUTE11" DATE, 
	"ATTRIBUTE12" DATE
   ) ;
   
  
  
  /*================================================*/
           /*TABLE WSC_AHCS_INT_LOGGING_T*/
  /*================================================*/
  
  CREATE TABLE "FININT"."WSC_AHCS_INT_LOGGING_T" 
   (	"ENTITY_NAME" VARCHAR2(100 BYTE), 
	"BATCH_ID" NUMBER, 
	"STEP_NO" NUMBER, 
	"DESCRIPTION1" VARCHAR2(1000 BYTE), 
	"ERR_MSG" VARCHAR2(1000 BYTE), 
	"CREATION_DATE" TIMESTAMP (6)
   ) ;
   
   
     /*================================================*/
           /*TABLE WSC_AHCS_REFRESH_T*/
  /*================================================*/
   CREATE TABLE "FININT"."WSC_AHCS_REFRESH_T" 
   (	"LAST_REFRESH_DATE" TIMESTAMP (6), 
	"DATA_ENTITY_NAME" VARCHAR2(100 BYTE), 
	"LAST_UPDATE_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(80 BYTE),
         "VALUE" VARCHAR2(200 BYTE)
   );


  /*================================================*/
           /*TABLE XX_IMD_DETAILS*/
  /*================================================*/
CREATE TABLE "FININT"."XX_IMD_DETAILS" 
   (	"USER_NAME" VARCHAR2(100 BYTE), 
	"PASSWORD" VARCHAR2(100 BYTE), 
	"URL" VARCHAR2(1000 BYTE), 
	"ATTRIBUTE1" VARCHAR2(100 BYTE), 
	"ATTRIBUTE2" VARCHAR2(100 BYTE), 
	"ATTRIBUTE3" VARCHAR2(100 BYTE), 
	"ATTRIBUTE4" VARCHAR2(100 BYTE), 
	"INSTANCE_NAME" VARCHAR2(200 BYTE)
   );
   
     /*================================================*/
           /*INSERT SQL XX_IMD_DETAILS*/
  /*================================================*/
   
   INSERT INTO XX_IMD_DETAILS (USER_NAME,PASSWORD,URL) VALUES ('FIN_INT','WescoAnixter@12345678901234567890','https://aicdev-anixterpaas.integration.ocp.oraclecloud.com');


  /*================================================*/
           /*TABLE XX_IMD_USER_ROLE_DETAILS_T*/
  /*================================================*/

CREATE TABLE "FININT"."XX_IMD_USER_ROLE_DETAILS_T" 
   (	"USERNAME" VARCHAR2(2000 BYTE), 
	"ROLE" VARCHAR2(2000 BYTE), 
	"EMAIL_ADDRESS" VARCHAR2(2000 BYTE), 
	"FULL_NAME" VARCHAR2(2000 BYTE)
   );


CREATE TABLE "FININT"."WSC_AHCS_DASHBOARD1_AUDIT_T" 
   (	"APPLICATION" VARCHAR2(200 BYTE), 
	"FILE_NAME" VARCHAR2(500 BYTE), 
	"FILE_PROCESSING_DATE" VARCHAR2(30 BYTE), 
	"BATCH_ID" NUMBER, 
	"STAGED_RECORDS" NUMBER, 
	"STAGED_AMOUNT" NUMBER, 
	"PROCESSED_RECORDS" NUMBER, 
	"PROCESSED_AMOUNT" NUMBER, 
	"ERROR_REEXTRACT_RECORDS" NUMBER, 
	"ERROR_REEXTRACT_AMOUNT" NUMBER, 
	"ERROR_REPROCESS_RECORDS" NUMBER, 
	"ERROR_REPROCESS_AMOUNT" NUMBER, 
	"SKIPPED_RECORDS" NUMBER, 
	"SKIPPED_AMOUNT" NUMBER
   );

