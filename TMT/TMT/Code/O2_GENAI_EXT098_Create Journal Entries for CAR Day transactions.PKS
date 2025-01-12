create or replace PACKAGE xxgenai_gl_cda_ext_pkg AUTHID current_user AS
TYPE x_error_detail_rec_type IS RECORD (
        rec_status    VARCHAR2(250),
        error_message CLOB,
        je_batch_id   xxgenai_gl_interface.je_batch_id%TYPE,
        ledger_id     xxgenai_gl_interface.ledger_id%TYPE
    );
    TYPE x_err_detail_type IS
        TABLE OF x_error_detail_rec_type;
    PROCEDURE process_validate_mode (
        p_ledger_id IN NUMBER,
        g_errbuff   OUT VARCHAR2,
        g_retcode   OUT VARCHAR2
    );

    TYPE t_ledger_id IS RECORD (
        ledger_id xxgenai_gl_cda_detail.ledger_id%TYPE
    );
    TYPE ledger_id_tab IS
        TABLE OF t_ledger_id;
    PROCEDURE insert_cda_detail (
        p_instance_id    IN NUMBER,
        p_ledger_id_recs IN ledger_id_tab, 
        p_created_by      IN VARCHAR2,
        p_ledger_id      IN NUMBER,
        g_errbuff        OUT VARCHAR2,
        g_retcode        OUT VARCHAR2
    );

    PROCEDURE validate_val_mode (
        p_ledger_id       IN NUMBER,
        p_oic_instance_id IN NUMBER,
        p_batch_id         IN NUMBER,
        g_errbuff         OUT VARCHAR2,
        g_retcode         OUT VARCHAR2
    );

    PROCEDURE validate_summarize (
        p_oic_instance_id IN NUMBER,
        p_created_by      IN VARCHAR2,
        g_errbuff         OUT VARCHAR2,
        g_retcode         OUT VARCHAR2
    );

    PROCEDURE insert_xxgenai_gl_interface (
        p_ledger_id       IN NUMBER,
        p_oic_instance_id IN NUMBER,
        p_created_by      IN VARCHAR2,
        g_errbuff         OUT VARCHAR2,
        g_retcode         OUT VARCHAR2
    );

    PROCEDURE reset_val_mode (
        p_ledger_id       IN NUMBER,
        p_oic_instance_id IN NUMBER,
        p_created_by      IN VARCHAR2,
        g_errbuff         OUT VARCHAR2,
        g_retcode         OUT VARCHAR2
    );

    PROCEDURE update_status (
        p_err_detail_type IN x_err_detail_type,
        p_process_flag    IN VARCHAR2,
        p_failed_status   IN VARCHAR2,
        p_last_updated_by IN  VARCHAR2,
        p_group_id        IN VARCHAR2,
        p_total_rec_count OUT NUMBER,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    );

    PROCEDURE batch_creation (
        p_instance_id IN VARCHAR2,
        p_status_out  OUT VARCHAR2,
        p_err_msg_out OUT VARCHAR2
    );
  PROCEDURE Assign_batch (
        p_instance_id IN VARCHAR2,
        p_status_out  OUT VARCHAR2,
        p_err_msg_out OUT VARCHAR2
    );
END xxgenai_gl_cda_ext_pkg;