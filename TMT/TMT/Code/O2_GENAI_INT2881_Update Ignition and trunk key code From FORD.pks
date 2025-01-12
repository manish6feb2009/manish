create or replace PACKAGE  XXgenai_FORD_Ignition_key_UPDATE_PKG  AS 
PROCEDURE populate_main_stg
(
	p_oic_instance_id IN NUMBER,
	p_file_name IN VARCHAR2,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
);

TYPE t_po_stg_rec IS RECORD
		(
		po_header_id					XXgenai_FORD_IGNITION_CODE_STG_TBL.po_header_id%type,
		po_line_id					XXgenai_FORD_IGNITION_CODE_STG_TBL.po_line_id%type,
		po_line_location_id					XXgenai_FORD_IGNITION_CODE_STG_TBL.po_line_location_id%type,
		vin					XXgenai_FORD_IGNITION_CODE_STG_TBL.vin%type
		);

TYPE t_po_stg_tbl IS TABLE OF t_po_stg_rec
			INDEX BY BINARY_INTEGER;
PROCEDURE enter_po_data (
	p_po_rec IN t_po_stg_tbl,
	p_batch IN NUMBER,
        p_oic_instance_id IN NUMBER,
        p_status_out  OUT VARCHAR2,
        p_err_msg_out OUT VARCHAR2
		);
PROCEDURE assign_batch_id (
        p_oic_instance_id IN NUMBER,
        p_status_out  OUT VARCHAR2,
        p_err_msg_out OUT VARCHAR2
		);
PROCEDURE reprocess
		(
			p_oic_instance_id IN NUMBER,
			p_reprocess_id IN NUMBER,
			p_file_name IN VARCHAR2,
			p_status_out OUT VARCHAR2,
			p_err_msg_out OUT VARCHAR2
		);
PROCEDURE assign_rest_batch_id (
        p_oic_instance_id IN NUMBER,
		p_po_id IN NUMBER,
        p_status_out  OUT VARCHAR2,
        p_err_msg_out OUT VARCHAR2
		);
end XXgenai_FORD_Ignition_key_UPDATE_PKG;