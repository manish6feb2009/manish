create or replace package WSC_INTER_INTRA_COMPANY_VALIDATION_PKG as

	PROCEDURE wsc_gl_ic_validation(p_batch_id IN number);
    
    PROCEDURE WSC_GL_IC_DB_INSERT_USERNAME(P_INS_VAL WSC_USER_DATA_ACCESS_T_TAB,
		P_ERR_MSG OUT VARCHAR2,
		P_ERR_CODE OUT VARCHAR2
	);
end WSC_INTER_INTRA_COMPANY_VALIDATION_PKG;
/