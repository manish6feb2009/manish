create or replace PACKAGE wsc_mfap_pkg AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */

    PROCEDURE "WSC_MFAP_INSERT_DATA_TEMP_P" (
        in_wsc_mainframeap_stage IN WSC_MFAP_TMP_T_TYPE_TABLE
    );

    PROCEDURE "WSC_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P" (
        p_batch_id          IN  NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2
    );

    PROCEDURE "WSC_PROCESS_MFAP_TEMP_TO_HEADER_LINE_P" (
        p_batch_id IN NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2,
       p_error_flag OUT VARCHAR2
    );

END wsc_mfap_pkg;
/