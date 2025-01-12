PROMPT "CREATE/UPDATE PACKAGE wsc_central_pkg";

create or replace PACKAGE wsc_central_pkg AS 

/* $Header: WSC_CENTRAL_PKG.pks  ver 1.0 2021/07/14 16:30:00  $
    +==========================================================================+
    |              Copyright (c) 2020 Wesco.                                 |
    |                        All rights reserved                               |
    +==========================================================================+
    |                                                                          |
    |  FILENAME                                                                |
    |    WSC_CENTRAL_PKG.pks                                    |
    |                                                                          |
    |  DESCRIPTION     										                   |
    |                                                                          |
    |  HISTORY                                                                 |
    |                                                                          |
    | Version    Date        Author                Description                 |
    | =======    ==========  =============         ============================|
    | 1.0        2021/08/18	  Harman Singh Datta    Initial Version            |
    |                                                                          |
    |                                                                          |
    +==========================================================================+
    */ 

         -- ===============================================================================
    -- PROCEDURE : WSC_CENTERAL_STAGE_P
    --
    -- PARAMETERS: 
    --            IN_WSC_CENTRAL_STAGE  WSC_CENTRAL_S_TYPE_TABLE
    --             
    --
    -- Description : Procedure to insert CENTRAL details to staging table.
    -- ==============================================================================================
    PROCEDURE "WSC_CENTERAL_STAGE_P" (
        in_wsc_central_stage IN wsc_central_s_type_table
    );

       -- ===============================================================================
    -- PROCEDURE : wsc_process_central_stage_data_p
    --
    -- PARAMETERS: 
    --            
    --     BATCH_ID IN NUMBER        
    --
    -- Description : Procedure to process CENTRAL data from staging table to Header and Line table.
    -- ==============================================================================================
    PROCEDURE "WSC_PROCESS_CENTRAL_STAGE_DATA_P" (
        p_batch_id IN NUMBER,
        P_APPLICATION_NAME IN VARCHAR2,
        P_FILE_NAME IN VARCHAR2
    );

       -- ===============================================================================
    -- PROCEDURE : WSC_ASYNC_PROCESS_CENTRAL_P
    --
    -- PARAMETERS: 
    --            
    --     BATCH_ID IN NUMBER        
    --
    -- Description : Procedure to process CENTRAL data from staging table to Header and Line table.
    -- ==============================================================================================
    PROCEDURE WSC_ASYNC_PROCESS_CENTRAL_P (
        p_batch_id IN NUMBER,
        P_APPLICATION_NAME IN VARCHAR2,
        P_FILE_NAME IN VARCHAR2
    );

       -- ===============================================================================
    -- PROCEDURE : WSC_PROCESS_CENTRAL_HEADER_T_P
    --
    -- PARAMETERS: 
    --            
    --     BATCH_ID IN NUMBER        
    --
    -- Description : Procedure to process CENTRAL data from line table to Header.
    -- ==============================================================================================
    PROCEDURE WSC_PROCESS_CENTRAL_HEADER_T_P (
        p_batch_id IN NUMBER
    );


END wsc_central_pkg;
/
