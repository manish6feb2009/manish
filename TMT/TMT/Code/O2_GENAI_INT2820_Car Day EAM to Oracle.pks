create or replace PACKAGE xxgenai_gl_cda_lh_int_pkg AUTHID current_user AS
PROCEDURE assign_batchid (
        p_oic_instance_id IN NUMBER,
        p_file_name       IN VARCHAR2,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    );

    PROCEDURE purge_rec_proc (
        p_oic_instance_id IN NUMBER,
        p_validated_flag  IN VARCHAR2,
        p_error_flag      IN VARCHAR2,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    );

    PROCEDURE update_status_proc (
        p_oic_instance_id  IN NUMBER,
        p_intial_flag      IN VARCHAR2,
        p_validated_flag   IN VARCHAR2,
        p_last_updated_by  IN VARCHAR2,
        p_last_update_date IN DATE,
        p_status_out       OUT VARCHAR2,
        p_err_msg_out      OUT VARCHAR2
    );

    PROCEDURE populate_ledger_id (
        p_oic_instance_id IN NUMBER,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    );

    PROCEDURE validate_records_proc (
        p_oic_instance_id  IN NUMBER,
        p_batchid          IN NUMBER,
        p_intial_flag      IN VARCHAR2,
        p_validated_flag   IN VARCHAR2,
        p_error_flag       IN VARCHAR2,
        p_last_updated_by  IN VARCHAR2,
        p_last_update_date IN DATE,
        p_status_out       OUT VARCHAR2,
        p_err_msg_out      OUT VARCHAR2,
        p_flag_valid       IN VARCHAR2,
        p_flag_err         IN VARCHAR2,
        p_filename         IN VARCHAR2
    );

    PROCEDURE populate_legal_entity (
        p_oic_instance_id IN NUMBER,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    );

    TYPE xxgenai_gl_cda_lh_int_r IS RECORD (
        ledger_id           xxgenai_gl_cda_lh_int.ledger_id%TYPE,
        count_gl_je_headers xxgenai_gl_cda_lh_int.count_gl_je_headers%TYPE
    );
    TYPE xxgenai_gl_cda_lh_int_t IS
        TABLE OF xxgenai_gl_cda_lh_int_r;
    PROCEDURE populate_reverse_journal_count (
        p_journal_count_recs IN xxgenai_gl_cda_lh_int_t,
        p_oic_instance_id    IN NUMBER,
        p_batchid            IN NUMBER,
        p_validated_flag     IN VARCHAR2,
        p_error_flag         IN VARCHAR2,
        p_status_out         OUT VARCHAR2,
        p_err_msg_out        OUT VARCHAR2,
        p_flag_valid         IN VARCHAR2,
        p_flag_err           IN VARCHAR2,
        p_filename           IN VARCHAR2
    );

END xxgenai_gl_cda_lh_int_pkg;