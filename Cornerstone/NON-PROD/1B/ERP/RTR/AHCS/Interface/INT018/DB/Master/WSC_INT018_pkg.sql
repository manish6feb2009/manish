create or replace PACKAGE wsc_cp_pkg AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */
    PROCEDURE wsc_cp_line_p (
        in_wsc_cp_line IN wsc_ahcs_cloudpay_txn_line_t_type_table
    );

    PROCEDURE "WSC_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P" (
        p_batch_id          IN  NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2
    );

    PROCEDURE wsc_insert_data_in_gl_status_p (
        p_batch_id          NUMBER,
        p_application_name  VARCHAR2,
        p_file_name         VARCHAR2
    );

END wsc_cp_pkg;
/