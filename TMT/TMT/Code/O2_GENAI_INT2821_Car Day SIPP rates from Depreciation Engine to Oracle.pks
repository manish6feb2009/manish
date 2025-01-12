CREATE OR REPLACE PACKAGE xxgenai_gl_inv_sipp_cost_depr_pkg AUTHID current_user IS
 PROCEDURE assign_batchid (
        p_oic_instance_id IN VARCHAR2,
        p_file_name       IN VARCHAR2,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    );

    PROCEDURE purge_data (
        p_oic_instance_id IN VARCHAR2,
        p_validated_flag  IN VARCHAR2,
        p_error_flag      IN VARCHAR2,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    );

    PROCEDURE validate_records_proc (
        p_oic_instance_id  IN VARCHAR2,
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

    PROCEDURE update_status_proc (
        p_oic_instance_id  IN VARCHAR2,
        p_intial_flag      IN VARCHAR2,
        p_validated_flag   IN VARCHAR2,
        p_last_updated_by  IN VARCHAR2,
        p_last_update_date IN DATE,
        p_status_out       OUT VARCHAR2,
        p_err_msg_out      OUT VARCHAR2
    );

END xxgenai_gl_inv_sipp_cost_depr_pkg;