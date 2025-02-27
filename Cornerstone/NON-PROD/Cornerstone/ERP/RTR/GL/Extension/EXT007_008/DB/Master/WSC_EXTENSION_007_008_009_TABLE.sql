
CREATE TABLE  "WSC_GL_CONSOLIDATION_RULE_ERR_T" 
   (	"RULE_ID" NUMBER, 
	"RULE_NAME" VARCHAR2(100), 
	"VALUE_ID" NUMBER, 
	"BATCH_ID" VARCHAR2(500), 
	"SOURCE_SEGMENT1" VARCHAR2(200), 
	"SOURCE_SEGMENT2" VARCHAR2(200), 
	"SOURCE_SEGMENT3" VARCHAR2(200), 
	"SOURCE_SEGMENT4" VARCHAR2(200), 
	"SOURCE_SEGMENT5" VARCHAR2(200), 
	"SOURCE_SEGMENT6" VARCHAR2(200), 
	"SOURCE_SEGMENT7" VARCHAR2(200), 
	"SOURCE_SEGMENT8" VARCHAR2(200), 
	"SOURCE_SEGMENT9" VARCHAR2(200), 
	"SOURCE_SEGMENT10" VARCHAR2(200), 
	"TARGET_SEGMENT" VARCHAR2(200), 
	"ERROR_DESC" VARCHAR2(2000), 
	"ERROR_CODE" VARCHAR2(500), 
	"USERNAME" VARCHAR2(500), 
	"CREATION_DATE" VARCHAR2(500), 
	"CREATED_BY" VARCHAR2(500), 
	"LAST_UPDATE_DATE" VARCHAR2(500), 
	"LAST_UPDATED_BY" VARCHAR2(500), 
	"ATTRIBUTE1" VARCHAR2(1000), 
	"ATTRIBUTE2" VARCHAR2(1000), 
	"ATTRIBUTE3" VARCHAR2(1000), 
	"ATTRIBUTE4" VARCHAR2(1000), 
	"ATTRIBUTE5" VARCHAR2(1000), 
	"ATTRIBUTE6" VARCHAR2(1000), 
	"ATTRIBUTE7" VARCHAR2(1000), 
	"ATTRIBUTE8" VARCHAR2(1000), 
	"ATTRIBUTE9" VARCHAR2(1000), 
	"ATTRIBUTE10" VARCHAR2(1000)
   );

CREATE TABLE  "WSC_GL_CCID_MAPPING_ERR_T" 
   (	"COA_MAP_ID" NUMBER, 
	"BATCH_ID" VARCHAR2(500), 
	"CCID_VALUE_ID" NUMBER, 
	"COA_MAP_NAME" VARCHAR2(100), 
	"SOURCE_SEGMENT" VARCHAR2(200), 
	"TARGET_SEGMENT" VARCHAR2(200), 
	"ENABLE_FLAG" VARCHAR2(10), 
	"ERROR_DESC" VARCHAR2(2000), 
	"ERROR_CODE" VARCHAR2(500), 
	"USER_NAME" VARCHAR2(200), 
	"UI_FLAG" VARCHAR2(1), 
	"CREATION_DATE" VARCHAR2(500), 
	"CREATED_BY" VARCHAR2(500), 
	"LAST_UPDATE_DATE" VARCHAR2(500), 
	"LAST_UPDATED_BY" VARCHAR2(500), 
	"ATTRIBUTE1" VARCHAR2(1000), 
	"ATTRIBUTE2" VARCHAR2(1000), 
	"ATTRIBUTE3" VARCHAR2(1000), 
	"ATTRIBUTE4" VARCHAR2(1000), 
	"ATTRIBUTE5" VARCHAR2(1000), 
	"ATTRIBUTE6" VARCHAR2(1000), 
	"ATTRIBUTE7" VARCHAR2(1000), 
	"ATTRIBUTE8" VARCHAR2(1000), 
	"ATTRIBUTE9" VARCHAR2(1000), 
	"ATTRIBUTE10" VARCHAR2(1000)
   );