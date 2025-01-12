create or replace PACKAGE wsc_mfar_pkg AS 

  /* $Header: wsc_mfar_pkg.pks  ver 1.0 2022/02/15 08:30:00  $
    +==========================================================================+
    |              Copyright (c) 2020 Wesco.                                 |
    |                        All rights reserved                               |
    +==========================================================================+
    |                                                                          |
    |  FILENAME                                                                |
    |    wsc_mfar_pkg.pks                                    |
    |                                                                          |
    |  DESCRIPTION     										                   |
    |                                                                          |
    |  HISTORY                                                                 |
    |                                                                          |
    | Version    Date        Author                Description                 |
    | =======    ==========  =============         ============================|
    | 1.0        2022/02/15	  Syed Zafer Ali    Initial Version            |
    |                                                                          |
    |                                                                          |
    +==========================================================================+
    */

    -- ================================================================================================
    -- PROCEDURE : WSC_MFAR_INSERT_DATA_TEMP_P
    --
    -- PARAMETERS: 
    --             
    --             
    --             
    --
    -- Description : Procedure to import mfar data from ftp to temporary ar staging table.
    -- ====================================================================================================
    PROCEDURE wsc_mfar_insert_data_temp_p (
        p_wsc_mfar_stg IN wsc_mfar_tmp_t_type_table
    );

-- ================================================================================================
    -- PROCEDURE : WSC_PROCESS_MFAR_TEMP_TO_HEADER_LINE_P
    --
    -- PARAMETERS: 
    --             p_batch_id 
    --             p_application_name
    --             p_file_name 
    --
    -- Description : Procedure to split mfar data from temporary stage table to header and line table and update header_id to line, insert data to status table.
    -- ==========================================================================================================================================================
    PROCEDURE wsc_process_mfar_temp_to_header_line_p (
        p_batch_id         IN NUMBER,
        p_application_name IN VARCHAR2,
        p_file_name        IN VARCHAR2,
        p_error_flag       OUT VARCHAR2
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

    PROCEDURE wsc_async_process_update_validate_transform_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    );

END wsc_mfar_pkg;
/