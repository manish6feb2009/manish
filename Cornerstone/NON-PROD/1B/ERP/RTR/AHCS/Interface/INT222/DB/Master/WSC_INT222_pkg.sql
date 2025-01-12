create or replace PACKAGE WSC_MFINV_PKG AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */

    PROCEDURE "WSC_MFINV_INSERT_DATA_TEMP_P" (
        IN_WSC_MAINFRAMEINV_STAGE IN WSC_MFINV_TMP_T_TYPE_TABLE
    );

    PROCEDURE "WSC_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P" (
        p_batch_id          IN  NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2
    );

	PROCEDURE "WSC_PROCESS_MFINV_TEMP_TO_HEADER_LINE_P" (
        p_batch_id IN NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2,
       p_error_flag OUT VARCHAR2
    );
END WSC_MFINV_PKG;
/