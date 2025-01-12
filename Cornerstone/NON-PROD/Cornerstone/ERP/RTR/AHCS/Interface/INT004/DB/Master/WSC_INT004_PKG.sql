--------------------------------------------------------
--   Package WSC_FA_PKG
--------------------------------------------------------

CREATE OR REPLACE PACKAGE "FININT"."WSC_FA_PKG" AS 

 /* $Header: WSC_FA_PKG.pks  ver 1.0 2021/07/15 12:30:00  $
    +==========================================================================+
    |              Copyright (c) 2020 Wesco.                                 |
    |                        All rights reserved                               |
    +==========================================================================+
    |                                                                          |
    |  FILENAME                                                                |
    |    WSC_FA_PKG.pks                                    |
    |                                                                          |
    |  DESCRIPTION     										                   |
    |                                                                          |
    |  HISTORY                                                                 |
    |                                                                          |
    | Version    Date        Author                Description                 |
    | =======    ==========  =============         ============================|
    | 1.0        2021/07/15	  Snehal Shirke         Initial Version            |
    |                                                                          |
    |                                                                          |
    +==========================================================================+
    */ 

   -- ===============================================================================
    -- PROCEDURE : WSC_FA_HEADER_P
    --
    -- PARAMETERS: 
    --            IN_WSC_AHCS_FA_TXN_HEADER  WSC_FA_HEADER_T_TYPE_TABLE
    --             
    --
    -- Description : Procedure to insert header level FA details to staging table.
    -- ==============================================================================================
    PROCEDURE "WSC_AHCS_FA_TXN_HEADER_P" 
    (
      IN_WSC_AHCS_FA_TXN_HEADER IN WSC_FA_HEADER_T_TYPE_TABLE
    );

    -- ===============================================================================
    -- PROCEDURE : WSC_FA_LINE_P
    --
    -- PARAMETERS: 
    --            IN_WSC_AHCS_FA_TXN_LINE  WSC_FA_LINE_T_TYPE_TABLE
    --             
    --
    -- Description : Procedure to insert line level FA details to staging table.
    -- ==============================================================================================   

    PROCEDURE "WSC_AHCS_FA_TXN_LINE_P" 
        (
          IN_WSC_AHCS_FA_TXN_LINE IN WSC_FA_LINE_T_TYPE_TABLE
        );

    -- ===============================================================================
    -- PROCEDURE : WSC_INSERT_DATA_IN_GL_STATUS_P
    --
    -- PARAMETERS: 
    --    P_BATCH_ID NUMBER,
    --    P_APPLICATION_NAME VARCHAR2,
    --    P_FILE_NAME VARCHAR2
    --             
    --
    -- Description : Procedure to insert into status table and update header id in line staging table.
    -- ==============================================================================================      

 PROCEDURE WSC_INSERT_DATA_IN_GL_STATUS_P (P_BATCH_ID NUMBER,P_APPLICATION_NAME VARCHAR2,P_FILE_NAME VARCHAR2);

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
END WSC_FA_PKG;

/