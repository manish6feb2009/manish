create or replace PACKAGE wsc_poc_pkg AS 

   /* $Header: wsc_poc_pkg.pks  ver 1.0 2021/07/12 06:30:00  $
    +==========================================================================+
    |              Copyright (c) 2020 Wesco.                                 |
    |                        All rights reserved                               |
    +==========================================================================+
    |                                                                          |
    |  FILENAME                                                                |
    |    wsc_poc_pkg.pks                                    |
    |                                                                          |
    |  DESCRIPTION     										                   |
    |                                                                          |
    |  HISTORY                                                                 |
    |                                                                          |
    | Version    Date        Author                Description                 |
    | =======    ==========  =============         ============================|
    | 1.0        2021/07/12	  Syed Zafer Ali    Initial Version            |
    |                                                                          |
    |                                                                          |
    +==========================================================================+
    */

        -- ================================================================================================
    -- PROCEDURE : IMPORT_HEADER_DATA_TO_STG
    --
    -- PARAMETERS: 
    --             p_ics_run_id - OIC Run ID
    --             p_event_name - Event Name
    --             
    --
    -- Description : Procedure to import poc header data from ftp poc header file to staging table.
    -- ====================================================================================================
    PROCEDURE import_header_data_to_stg (
        p_ics_run_id   IN VARCHAR2,
        p_event_name   IN VARCHAR2,
        p_batch_id     IN NUMBER,
        p_poc_header_t IN wsc_poc_header_tt,
        x_status       OUT VARCHAR2
    );

-- ========================================================================================================
    -- PROCEDURE : IMPORT_LINE_DATA_TO_STG
    --
    -- PARAMETERS: 
    --             p_ics_run_id - OIC Run ID
    --             p_event_name - Event Name
    --             
    --
    -- Description : Procedure to import poc line data from ftp poc line file to staging table.
    -- ====================================================================================================
    PROCEDURE import_line_data_to_stg (
        p_ics_run_id IN VARCHAR2,
        p_event_name IN VARCHAR2,
        p_poc_line_t IN wsc_poc_line_tt,
        p_batch_id   IN NUMBER,
        x_status     OUT VARCHAR2
    );
-- ========================================================================================================
    -- PROCEDURE : WSC_INSERT_POC_DATA_IN_GL_STATUS
    --
    -- PARAMETERS: 
    --             p_ics_run_id - OIC Run ID
    --             p_event_name - Event Name
    --             
    --
    -- Description : Procedure to insert the line data of poc to gl status table as well as update the header_id for respective lines having header.
    -- ================================================================================================================================================

    PROCEDURE wsc_insert_poc_data_in_gl_status (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
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

END wsc_poc_pkg;
/