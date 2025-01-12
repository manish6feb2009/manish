create or replace PACKAGE wsc_cres_pkg AS 


  -- ====================================================================================================
    -- PROCEDURE : WSC_CRES_INSERT_DATE_TEMP_P
    --
    -- PARAMETERS: 
    --             
    --             
    --             
    --
    -- Description : Procedure to import cresus data from ftp to temporary staging table.
    -- =======================================================================================================
    PROCEDURE wsc_cres_insert_data_temp_p (
        p_wsc_cres_stg IN wsc_mfar_tmp_t_type_table
    );

-- ===========================================================================================================
    -- PROCEDURE : WSC_PROCESS_MFAP_STAGE_TO_HEADER_LINE
    --
    -- PARAMETERS: 
    --             p_batch_id
    --             p_application_name
    --             p_file_name
    --
    -- Description : Procedure to insert cresus data from temporary stage table to AP header and line table and updating header_id to line as well as status table data insertion.
    -- ===========================================================================================================================================================================
    PROCEDURE wsc_process_mfap_temp_to_header_line_p (
        p_batch_id_t         NUMBER,
        p_batch_id         NUMBER,
        p_application_name IN VARCHAR2,
        p_file_name        IN VARCHAR2,
        p_error_flag       OUT VARCHAR2
    );
-- ========================================================================================================
    -- PROCEDURE : WSC_PROCESS_MFAR_STAGE_TO_HEADER_LINE
    --
    -- PARAMETERS: 
    --             p_batch_id
    --             p_application_name
    --             p_file_name
    --
    -- Description : Procedure to insert the line data of CRES to gl status table as well as update the header_id for respective lines having header.
    -- ================================================================================================================================================

    PROCEDURE wsc_process_mfar_temp_to_header_line_p (
        p_batch_id_t         NUMBER,
        p_batch_id         NUMBER,
        p_application_name IN VARCHAR2,
        p_file_name        IN VARCHAR2,
        p_error_flag       OUT VARCHAR2
    );

      -- ===============================================================================
    -- PROCEDURE : WSC_MFAP_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P
    --
    -- PARAMETERS: 
    --    P_BATCH_ID NUMBER,
    --    P_APPLICATION_NAME VARCHAR2,
    --    P_FILE_NAME VARCHAR2
    --             
    --
    -- Description : Procedure to process asynchronously and insert into status table and update header id in line staging table.
    --              perform data validation and transformation for mfap
    -- ==============================================================================================

    PROCEDURE wsc_mfap_async_process_update_validate_transform_p (
        p_batch_id_t         NUMBER,
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    );

      -- ===============================================================================
    -- PROCEDURE : WSC_MFAR_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P
    --
    -- PARAMETERS: 
    --    P_BATCH_ID NUMBER,
    --    P_APPLICATION_NAME VARCHAR2,
    --    P_FILE_NAME VARCHAR2
    --             
    --
    -- Description : Procedure to process asynchronously and insert into status table and update header id in line staging table.
    --              perform data validation and transformation for mfap
    -- ==============================================================================================

    PROCEDURE wsc_mfar_async_process_update_validate_transform_p (
        p_batch_id_t         NUMBER,
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    );

END wsc_cres_pkg;
/