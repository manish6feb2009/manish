create or replace PACKAGE          "WSC_AR_PKG" AS 

   /* $Header: WSC_AR_PKG.pks  ver 1.0 2021/07/14 16:30:00  $
    +==========================================================================+
    |              Copyright (c) 2020 Wesco.                                 |
    |                        All rights reserved                               |
    +==========================================================================+
    |                                                                          |
    |  FILENAME                                                                |
    |    WSC_AR_PKG.pks                                    |
    |                                                                          |
    |  DESCRIPTION     										                   |
    |                                                                          |
    |  HISTORY                                                                 |
    |                                                                          |
    | Version    Date        Author                Description                 |
    | =======    ==========  =============         ============================|
    | 1.0        2021/07/14	  Harman Singh Datta    Initial Version            |
    |                                                                          |
    |                                                                          |
    +==========================================================================+
    */ 

         -- ===============================================================================
    -- PROCEDURE : WSC_AR_HEADER_P
    --
    -- PARAMETERS: 
    --            IN_WSC_AR_HEADER  WSC_AR_HEADER_T_TYPE_TABLE
    --             
    --
    -- Description : Procedure to insert header level AR details to staging table.
    -- ==============================================================================================
    PROCEDURE "WSC_AR_HEADER_P" 
    (
      IN_WSC_AR_HEADER IN WSC_AR_HEADER_T_TYPE_TABLE
    );


         -- ===============================================================================
    -- PROCEDURE : WSC_AR_LINE_P
    --
    -- PARAMETERS: 
    --            IN_WSC_AR_LINE WSC_AR_LINE_T_TYPE_TABLE
    --             
    --
    -- Description : Procedure to insert header level AR details to staging table.
    -- ==============================================================================================
    PROCEDURE "WSC_AR_LINE_P" 
    (
      IN_WSC_AR_LINE IN WSC_AR_LINE_T_TYPE_TABLE
    );

    -- ===============================================================================
    -- PROCEDURE : WSC_INSERT_DATA_IN_GL_STATUS_P
    --
    -- PARAMETERS: 
    --            P_BATCH_ID NUMBER,
    --    P_APPLICATION_NAME VARCHAR2,
    --    P_FILE_NAME VARCHAR2
    --             
    --
    -- Description : Procedure to insert into status table and update header id in line staging table.
    -- ==============================================================================================

    PROCEDURE WSC_INSERT_DATA_IN_GL_STATUS_P 
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

END WSC_AR_PKG;
/