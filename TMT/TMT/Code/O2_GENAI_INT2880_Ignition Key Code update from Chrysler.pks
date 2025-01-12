create or replace PACKAGE xxgenai_po_chrysler_ignition_updates_pkg AS
	PROCEDURE populate_main_stg
(
	p_oic_instance_id IN NUMBER,
	p_file_oic_instance_id IN NUMBER,
	p_file_name IN VARCHAR2,
	p_source    IN VARCHAR2,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
);
PROCEDURE update_run_time_error
(
	p_instance_id   IN    NUMBER,
	p_update_status IN    VARCHAR2,
	p_error_scope   IN    VARCHAR2,
	p_error_message IN    VARCHAR2,		
	p_batch_id      IN    NUMBER,
	p_file_name		IN	  VARCHAR2,
	p_status_out    OUT   VARCHAR2,
	p_err_msg_out   OUT   VARCHAR2
);

PROCEDURE ASSIGN_BATCH_ID (
        p_instance_id   IN    NUMBER,
        p_status_out    OUT   VARCHAR2,
        p_err_msg_out   OUT   VARCHAR2
        );

TYPE t_po_data_rec IS RECORD
   (
	  PO_NUMBER					XXgenai_PO_CHRYSLER_KEY_UPDATES_PO_DTLS_STG .PO_NUMBER%type
	, PO_LINE_NUMBER 			XXgenai_PO_CHRYSLER_KEY_UPDATES_PO_DTLS_STG .PO_LINE_NUMBER%type
	, PO_SCHEDULE_NUMBER		XXgenai_PO_CHRYSLER_KEY_UPDATES_PO_DTLS_STG .PO_SCHEDULE_NUMBER%type
	, PO_HEADER_ID				XXgenai_PO_CHRYSLER_KEY_UPDATES_PO_DTLS_STG .PO_HEADER_ID%type
	, PO_LINE_ID				XXgenai_PO_CHRYSLER_KEY_UPDATES_PO_DTLS_STG .PO_LINE_ID%type
	, PO_LINE_LOCATION_ID	    XXgenai_PO_CHRYSLER_KEY_UPDATES_PO_DTLS_STG .PO_LINE_LOCATION_ID%type
	, VIN		                XXgenai_PO_CHRYSLER_KEY_UPDATES_PO_DTLS_STG .VIN%type
	, VEHICLE_COLOR             XXgenai_PO_CHRYSLER_KEY_UPDATES_PO_DTLS_STG .VEHICLE_COLOR%type
    , VEHICLE_ORDER_NUMBER             XXgenai_PO_CHRYSLER_KEY_UPDATES_PO_DTLS_STG .VEHICLE_ORDER_NUMBER%type
	   );
   TYPE t_po_data_tbl IS TABLE OF t_po_data_rec INDEX BY BINARY_INTEGER;	
PROCEDURE populate_po_dtls_stg
(
	p_po_data_recs IN t_po_data_tbl,
	p_oic_instance_id IN NUMBER,
	p_user IN VARCHAR2,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
);

PROCEDURE assign_rest_batches
(
	p_oic_instance_id IN NUMBER,
	p_batch_size IN NUMBER,
	p_po_header_id IN NUMBER,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
);

PROCEDURE validate_records_proc
(
	p_oic_instance_id IN NUMBER,
	p_batch_id IN NUMBER,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
);
END xxgenai_po_chrysler_ignition_updates_pkg;