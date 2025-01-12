create or replace PACKAGE XXgenai_FA_REINS_PKG AUTHID CURRENT_USER
AS
PROCEDURE main (
        p_oic_instance_id IN NUMBER,
        p_file_name       IN VARCHAR,
        p_updated_by      IN VARCHAR,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    );

    PROCEDURE assign_batchid (
        p_oic_instance_id IN VARCHAR2,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    );
    end xxgenai_fa_reins_pkg;