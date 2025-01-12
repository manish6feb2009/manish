create or replace PACKAGE wsc_eclipse_pkg AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */

    PROCEDURE "WSC_ECLIPSE_INSERT_DATA_TEMP_P" (
        in_wsc_eclipse_stage IN WSC_ECLIPSE_TMP_T_TYPE_TABLE
    );

    PROCEDURE "WSC_ECLIPSE_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P" (
        p_batch_id          IN  NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2
    );

    PROCEDURE "WSC_PROCESS_ECLIPSE_TEMP_TO_HEADER_LINE_P" (
        p_batch_id IN NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2,
        p_error_flag OUT VARCHAR2
    ); 

END wsc_eclipse_pkg;
/