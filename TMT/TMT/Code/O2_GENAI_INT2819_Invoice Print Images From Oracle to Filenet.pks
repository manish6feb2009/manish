create or replace PACKAGE xxgenai_ap_inv_print_images_to_filenet_pkg AS 
PROCEDURE validate_invoice_records (
        p_oic_instance_id IN NUMBER,
        p_record_status   IN VARCHAR2,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    );

PROCEDURE assign_batch_id (
        p_instance_id   IN    NUMBER,
        p_status_out    OUT   VARCHAR2,
        p_err_msg_out   OUT   VARCHAR2
        );

END xxgenai_ap_inv_print_images_to_filenet_pkg;