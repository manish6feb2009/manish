create or replace PACKAGE          "WSC_TW_PKG" AS 

 /* $Header: WSC_TW_PKG.pks  ver 1.0 2021/07/15 12:30:00  $
    +==========================================================================+
    |              Copyright (c) 2020 Wesco.                                   |
    |                        All rights reserved                               |
    +==========================================================================+
    |                                                                          |
    |  FILENAME                                                                |
    |    WSC_TW_PKG.pks                                                        |
    |                                                                          |
    |  DESCRIPTION     										                   |
    |                                                                          |
    |  HISTORY                                                                 |
    |                                                                          |
    | Version    Date        Author                Description                 |
    | =======    ==========  =============         ============================|
    | 1.0        2022/04/19	 Dhrumil Makadia       Initial Version             |
    |                                                                          |
    |                                                                          |
    +==========================================================================+
    */ 

   -- ===============================================================================
    -- PROCEDURE : WSC_TW_INSERT_DATA_TEMP_P
    --
    -- PARAMETERS: 
    --            IN_WSC_AHCS_TW_TXN_TMP  WSC_AHCS_TW_TXN_TMP_T_TYPE_TABLE
    --             
    --
    -- Description : Procedure to insert header level PSFA details to staging table.
    -- ==============================================================================================
    PROCEDURE "WSC_TW_INSERT_DATA_TEMP_P" 
    (
      IN_WSC_AHCS_TW_TXN_TMP IN WSC_AHCS_TW_TXN_TMP_T_TYPE_TABLE
    );

    -- ===============================================================================
    -- PROCEDURE : WSC_PROCESS_TW_TEMP_TO_HEADER_LINE_P
    --
    -- PARAMETERS: 
    --            P_BATCH_ID NUMBER
    --             
    --
    -- Description : Procedure to insert header level and line level details from temp table.
    -- ==============================================================================================   

    PROCEDURE "WSC_PROCESS_TW_TEMP_TO_HEADER_LINE_P" 
    (
        P_BATCH_ID NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2
    );

    
    -- ===============================================================================
    -- PROCEDURE : WSC_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P
    --
    -- PARAMETERS: 
    --    P_BATCH_ID NUMBER,
    --    P_APPLICATION_NAME VARCHAR2,
    --    P_FILE_NAME VARCHAR2
    --             
    --
    -- Description : Procedure to process asynchronously and insert into status table and update header id in line staging table.
    --              perform data validation and transformation
    -- ==============================================================================================
     PROCEDURE WSC_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P
    (
        P_BATCH_ID NUMBER,
        P_APPLICATION_NAME VARCHAR2,
        P_FILE_NAME VARCHAR2
    );
END WSC_TW_PKG;
/