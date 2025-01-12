create or replace PACKAGE wsc_ahcs_mfinv_validation_transformation_pkg AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */

    PROCEDURE data_validation (
        p_batch_id IN NUMBER
    );


    PROCEDURE leg_coa_transformation (
        p_batch_id IN NUMBER
    );

	PROCEDURE wsc_ledger_name_derivation (
        p_batch_id IN NUMBER
    );

	PROCEDURE wsc_ahcs_mfinv_grp_id_upd_p (
        in_grp_id IN NUMBER
    );

	 PROCEDURE wsc_ahcs_mfinv_ctrl_line_tbl_ucm_update (
        p_ucmdoc_id       IN  VARCHAR2,
        p_group_id        IN  VARCHAR2,
        p_ledger_grp_num  IN  VARCHAR2
    );


	 PROCEDURE leg_coa_transformation_JTI_MFINV (
        p_batch_id IN NUMBER
    );

     PROCEDURE wsc_ahcs_mfinv_ctrl_line_tbl_ledger_grp_num_update (      
        p_group_id        IN  VARCHAR2,
        p_ledger_grp_num  IN  VARCHAR2
    );

    PROCEDURE leg_coa_transformation_reprocessing (
        p_batch_id IN NUMBER
       
    );

    PROCEDURE leg_coa_transformation_jti_mfinv_reprocess (
        p_batch_id IN NUMBER
    );
	
	 PROCEDURE wsc_ahcs_mfinv_invt_line_copy_p (
        p_batch_id IN NUMBER
    );

    FUNCTION is_date_null (
        p_string IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION is_long_null (
        p_string IN LONG
    ) RETURN NUMBER;

    FUNCTION is_number_null (
        p_string IN NUMBER
    ) RETURN NUMBER;

    FUNCTION is_varchar2_null (
        p_string IN VARCHAR2
    ) RETURN NUMBER;

END wsc_ahcs_mfinv_validation_transformation_pkg;
/