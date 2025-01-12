create or replace PACKAGE xxgenai_gl_je_reseng_int_pkg AS

TYPE r_file_rec IS RECORD
(
	status								xxgenai_gl_je_reseng_int_stg.status%type,
	ledger_id							xxgenai_gl_je_reseng_int_stg.ledger_id%type,
	accounting_date						xxgenai_gl_je_reseng_int_stg.accounting_date%type,
	user_je_source_name					xxgenai_gl_je_reseng_int_stg.user_je_source_name%type,
	user_je_category_name				xxgenai_gl_je_reseng_int_stg.user_je_category_name%type,
	currency_code						xxgenai_gl_je_reseng_int_stg.currency_code%type,
	actual_flag							xxgenai_gl_je_reseng_int_stg.actual_flag%type,
	segment1							xxgenai_gl_je_reseng_int_stg.segment1%type,
	segment2							xxgenai_gl_je_reseng_int_stg.segment2%type,
	segment3							xxgenai_gl_je_reseng_int_stg.segment3%type,
	segment4							xxgenai_gl_je_reseng_int_stg.segment4%type,
	segment5							xxgenai_gl_je_reseng_int_stg.segment5%type,
	segment6							xxgenai_gl_je_reseng_int_stg.segment6%type,
	segment7							xxgenai_gl_je_reseng_int_stg.segment7%type,
	segment8							xxgenai_gl_je_reseng_int_stg.segment8%type,
	segment9							xxgenai_gl_je_reseng_int_stg.segment9%type,
	segment10							xxgenai_gl_je_reseng_int_stg.segment10%type,
	entered_dr							xxgenai_gl_je_reseng_int_stg.entered_dr%type,
	entered_cr							xxgenai_gl_je_reseng_int_stg.entered_cr%type,
	converted_dr						xxgenai_gl_je_reseng_int_stg.converted_dr%type,
	converted_cr						xxgenai_gl_je_reseng_int_stg.converted_cr%type,
	journal_batch_name					xxgenai_gl_je_reseng_int_stg.journal_batch_name%type,
	journal_batch_description			xxgenai_gl_je_reseng_int_stg.journal_batch_description%type,
	journal_entry_name					xxgenai_gl_je_reseng_int_stg.journal_entry_name%type,
	journal_entry_description			xxgenai_gl_je_reseng_int_stg.journal_entry_description%type,
	journal_entry_line_description		xxgenai_gl_je_reseng_int_stg.journal_entry_line_description%type,
	currency_conversion_type			xxgenai_gl_je_reseng_int_stg.currency_conversion_type%type,
	currency_conversion_date			xxgenai_gl_je_reseng_int_stg.currency_conversion_date%type,
	currency_conversion_rate			xxgenai_gl_je_reseng_int_stg.currency_conversion_rate%type,
	context_line_dff					xxgenai_gl_je_reseng_int_stg.context_line_dff%type,
	context_line_attribute1				xxgenai_gl_je_reseng_int_stg.context_line_attribute1%type,
	context_line_attribute2				xxgenai_gl_je_reseng_int_stg.context_line_attribute2%type,
	context_line_attribute3				xxgenai_gl_je_reseng_int_stg.context_line_attribute3%type,
	context_line_attribute4				xxgenai_gl_je_reseng_int_stg.context_line_attribute4%type,
	ledger_name							xxgenai_gl_je_reseng_int_stg.ledger_name%type,
	recon_reference						xxgenai_gl_je_reseng_int_stg.recon_reference%type,
	period_name							xxgenai_gl_je_reseng_int_stg.period_name%type
);

TYPE t_file_recs IS TABLE OF r_file_rec;



PROCEDURE insert_file_data
(
	p_file_recs IN t_file_recs,
	p_oic_instance_id IN VARCHAR2,
	p_user IN VARCHAR2,
	p_file_name IN VARCHAR2,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
);

PROCEDURE assign_batch_id
(
	p_oic_instance_id IN VARCHAR2,
	p_file_name IN VARCHAR2,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
);

PROCEDURE validate_records_proc
(
	p_oic_instance_id IN VARCHAR2,
	p_batch_id IN NUMBER,
	p_file_name IN VARCHAR2,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
);

TYPE r_error_recs IS RECORD (
	status 			xxgenai_gl_je_reseng_int_stg.status%TYPE,
	attribute3		VARCHAR2(150) 
);

TYPE t_error_recs IS TABLE OF r_error_recs;


PROCEDURE update_import_status
(
	p_error_recs IN t_error_recs,
	p_oic_instance_id IN VARCHAR2,
	p_ledger_id IN NUMBER,
	p_load_status IN VARCHAR2,
	p_error_message IN VARCHAR2,
	p_error_scope IN VARCHAR2,
	p_record_status IN VARCHAR2,
	p_type IN VARCHAR2,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
);

PROCEDURE reprocess_records
(
	p_oic_instance_id IN VARCHAR2,
	p_file_name IN VARCHAR2,
	p_reprocess_days IN NUMBER,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
);

END xxgenai_gl_je_reseng_int_pkg;