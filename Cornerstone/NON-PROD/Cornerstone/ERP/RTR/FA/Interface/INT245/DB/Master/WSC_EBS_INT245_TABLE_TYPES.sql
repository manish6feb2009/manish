create or replace TYPE          "WSC_EBS_FA_ASSET_LOCATIONS_T_TYPE"                                          AS OBJECT 
(SEGMENT1               VARCHAR2(100), 
SEGMENT2               VARCHAR2(100) ,
SEGMENT3               VARCHAR2(100) ,
SEGMENT4               VARCHAR2(100) ,
ENABLED_FLAG           VARCHAR2(100) ,
LOCATION_ID		NUMBER);


/

create or replace TYPE          "WSC_EBS_FA_ASSET_LOCATIONS_T_TYPE_TABLE"                                          
AS TABLE OF WSC_EBS_FA_ASSET_LOCATIONS_T_TYPE;

/
create or replace TYPE          "WSC_EBS_FA_ASSET_CREATED_T_TYPE"                                          AS OBJECT 
(BATCH_NAME                               VARCHAR2(120),
MASS_ADDITION_ID                         NUMBER ,
ASSET_NUMBER                     VARCHAR2(80) ,
BOOK_TYPE_CODE                      VARCHAR2(30) ,
ASSET_TYPE               VARCHAR2(11) ,
ATTRIBUTE1                   VARCHAR2(10) ,
ASSET_ID                    NUMBER ,
POSTING_STATUS                      VARCHAR2(10) ,
QUEUE_NAME               VARCHAR2(10) ,
TRANSACTION_NAME          VARCHAR2(80));

/


create or replace TYPE          "WSC_EBS_FA_ASSET_CREATED_T_TYPE_TABLE"                                          
AS TABLE OF WSC_EBS_FA_ASSET_CREATED_T_TYPE; 

/

create or replace TYPE          "WSC_EBS_FA_ASSET_CATEGORIES_T_TYPE"                                          AS OBJECT 
(CAT_SEG1                 VARCHAR2(30), 
CAT_SEG2                 VARCHAR2(30) ,
ASSET_CLEARING_ACC       VARCHAR2(25) ,
WIP_CLEARING_ACC         VARCHAR2(25) ,
DEPRN_EXPENSE_ACC        VARCHAR2(25) ,
ENABLED_FLAG             VARCHAR2(2)  ,
ASSET_BOOK               VARCHAR2(20) ,
LEDGER_NAME              VARCHAR2(20));

/

create or replace TYPE          "WSC_EBS_FA_ASSET_CATEGORIES_T_TYPE_TABLE"                                          
AS TABLE OF WSC_EBS_FA_ASSET_CATEGORIES_T_TYPE;

/

create or replace TYPE          "WSC_EBS_FA_T_TYPE"                                          AS OBJECT 
(ASSETID                         NUMBER ,
DESCRIPTION                     VARCHAR2(100) ,
TAG_NUMBER                      VARCHAR2(100) ,
MANUFACTURER_NAME               VARCHAR2(100) ,
SERIAL_NUMBER                   VARCHAR2(100) ,
MODEL_NUMBER                    VARCHAR2(100) ,
ASSET_TYPE                      VARCHAR2(100) ,
FIXED_ASSETS_COST               NUMBER        ,
DATE_PLACED_IN_SERVICE          VARCHAR2(100) ,
FIXED_ASSETS_UNITS              NUMBER        ,
MAJOR_CATEGORY                  VARCHAR2(100) ,
MINOR_CATEGORY                  VARCHAR2(100) ,
LINE_STATUS                     VARCHAR2(100) ,
PARENT_MASS_ADDITION_ID         NUMBER        ,
PAYABLES_COST                   NUMBER        ,
COST_CLR_ACCOUNT_SEGMENT1       VARCHAR2(100) ,
COST_CLR_ACCOUNT_SEGMENT2       VARCHAR2(100) ,
COST_CLR_ACCOUNT_SEGMENT3       VARCHAR2(100) ,
COST_CLR_ACCOUNT_SEGMENT4       VARCHAR2(100) ,
COST_CLR_ACCOUNT_SEGMENT5       VARCHAR2(100) ,
COST_CLR_ACCOUNT_SEGMENT6       VARCHAR2(100) ,
COST_CLR_ACCOUNT_SEGMENT7       VARCHAR2(100) ,
COST_CLR_ACCOUNT_SEGMENT8       VARCHAR2(100) ,
COST_CLR_ACCOUNT_SEGMENT9       VARCHAR2(100) ,
SUPPLIER_NAME                   VARCHAR2(240) ,
PO_NUMBER                       VARCHAR2(100) ,
INVOICE_NUMBER                  VARCHAR2(100) ,
INVOICE_DATE                    VARCHAR2(100) ,
PAYABLES_UNITS                  NUMBER        ,
INVOICE_LINE_NUMBER             NUMBER        ,
INVOICE_PAYMENT_NUMBER          VARCHAR2(100) ,
BIR_NUMBER                      VARCHAR2(100) ,
SUPPLIER_NUMBER                 VARCHAR2(30) ,
SPLIT_MERGED_CODE               VARCHAR2(30) ,
FILE_NAME                       VARCHAR2(100) ,
CREATED_BY                      VARCHAR2(100) ,
CREATION_DATE                   TIMESTAMP(6)  ,
LAST_UPDATED_BY                 VARCHAR2(100) ,
LAST_UPDATE_DATE                TIMESTAMP(6)  ,
ATTRIBUTE1                      VARCHAR2(100) ,
ATTRIBUTE2                      VARCHAR2(100) ,
ATTRIBUTE3                      VARCHAR2(100) ,
ATTRIBUTE4                      VARCHAR2(100) ,
ATTRIBUTE5                      VARCHAR2(100) ,
ATTRIBUTE6                      NUMBER        ,
ATTRIBUTE7                      NUMBER        ,
ATTRIBUTE8                      NUMBER        ,
ATTRIBUTE9                      VARCHAR2(100) ,
ATTRIBUTE10                     VARCHAR2(100) ,
BATCH_ID                        NUMBER );

/

create or replace TYPE          "WSC_EBS_FA_T_TYPE_TABLE"                                          
AS TABLE OF WSC_EBS_FA_T_TYPE;
/

