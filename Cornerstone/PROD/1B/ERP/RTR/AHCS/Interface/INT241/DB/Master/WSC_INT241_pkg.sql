create or replace PACKAGE "WSC_MFJTI_PKG" AS
    PROCEDURE wsc_jtiinv_header_p (
        in_wsc_jtiinv_header IN wsc_jti_mfinv_header_t_type_table
    );

    PROCEDURE wsc_jtiinv_line_p (
        in_wsc_jtiinv_line IN wsc_jti_mfinv_line_t_type_table
    );

   /* PROCEDURE ledger_transformation_jti_mfinv (
        p_batch_id IN NUMBER
    ); */

    PROCEDURE wsc_jti_mfap_async_process_update_validate_transform_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    );

    PROCEDURE wsc_jti_mfap_insert_data_in_gl_status_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2,
        p_error_flag       OUT VARCHAR2
    );

    PROCEDURE wsc_jti_mfap_line_p (
        in_wsc_jti_mfap_line IN wsc_jti_mfap_line_t_type_table
    );

    PROCEDURE wsc_jti_mfap_header_p (
        in_wsc_jti_mfap_header IN wsc_jti_mfap_header_t_type_table
    );

    PROCEDURE wsc_jti_mfar_insert_data_to_hdr (
        p_batch_id          IN NUMBER,
        p_jti_mfar_header_t IN wsc_jti_mfar_hdr_t_type_table
    );

    PROCEDURE wsc_jti_mfar_insert_data_to_line (
        p_batch_id        IN NUMBER,
        p_jti_mfar_line_t IN wsc_jti_mfar_line_t_type_table
    );

    PROCEDURE wsc_jti_mfar_insert_data_in_gl_status_p (
        p_batch_id         IN NUMBER,
        p_application_name IN VARCHAR2,
        p_file_name        IN VARCHAR2,
        p_error_flag       OUT VARCHAR2
    );

    PROCEDURE wsc_jti_mfar_async_process_update_validate_transform_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    );

    PROCEDURE wsc_jti_mfinv_async_process_update_validate_transform_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    );

    PROCEDURE wsc_jti_mfinv_insert_data_in_gl_status_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2,
        p_error_flag       OUT VARCHAR2
    );

END wsc_mfjti_pkg;
/