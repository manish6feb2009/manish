 create or replace PACKAGE          "WSC_SXE_PKG" AS  

      PROCEDURE "WSC_SXE_INSERT_DATA_TEMP_P" (
        in_wsc_sxe_stage IN WSC_SXE_TMP_T_TYPE_TABLE
    );

    PROCEDURE "WSC_SXE_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P" (
        p_batch_id          IN  NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2
    );

    PROCEDURE "WSC_PROCESS_SXE_TEMP_TO_HEADER_LINE_P" (
        p_batch_id IN NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2,
       p_error_flag OUT VARCHAR2
    );

END WSC_SXE_PKG;
/