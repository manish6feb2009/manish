create or replace PACKAGE          "WSC_EBS_FA_PKG" AS 
    /* $Header: WSC_EBS_FA_PKG.pks  ver 1.0 2024/02/10 16:30:00  $
    +==========================================================================+
    |              Copyright (c) 2020 Wesco.                                 |
    |                        All rights reserved                               |
    +==========================================================================+
    |                                                                          |
    |  FILENAME                                                                |
    |    WSC_EBS_FA_PKG.pks                                    |
    |                                                                          |
    |  DESCRIPTION     										                   |
    |                                                                          |
    |  HISTORY                                                                 |
    |                                                                          |
    | Version    Date        Author                Description                 |
    | =======    ==========  =============         ============================|
    | 1.0        2024/02/10	  MANISH KUMAR       Initial Version            |
    |                                                                          |
    |                                                                          |
    +==========================================================================+
    */ 

    -- ===============================================================================
    -- PROCEDURE : WSC_FA_P
    --
    -- PARAMETERS: 
    --            IN_WSC_EBS_FA  WSC_EBS_FA_T_TYPE_TABLE
    --             
    --
    -- Description : Procedure to insert header level AP details to staging table.
    -- ==============================================================================================
    PROCEDURE "WSC_FA_P" 
    (
      IN_WSC_EBS_FA IN WSC_EBS_FA_T_TYPE_TABLE
    );
    -- ===============================================================================
    -- PROCEDURE : WSC_INSERT_DATA_IN_STATUS_P
    --
    -- PARAMETERS: 
    --            P_BATCH_ID NUMBER,
    --    P_APPLICATION_NAME VARCHAR2,
    --    P_FILE_NAME VARCHAR2
    --             
    --
    -- Description : Procedure to insert into status table and update header id in line staging table.
    -- ==============================================================================================

     PROCEDURE WSC_INSERT_DATA_IN_STATUS_P 
     ( 
     P_BATCH_ID NUMBER,
     P_APPLICATION_NAME VARCHAR2,
     P_FILE_NAME VARCHAR2
     );

  -- ===============================================================================
    -- PROCEDURE : WSC_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P
    --
    -- PARAMETERS: 
    --            P_BATCH_ID NUMBER,
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
END WSC_EBS_FA_PKG;
/
