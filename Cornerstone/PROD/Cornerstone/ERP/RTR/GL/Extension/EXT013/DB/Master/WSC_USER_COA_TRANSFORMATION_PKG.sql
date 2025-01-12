create or replace PACKAGE WSC_USER_COA_TRANSFORMATION_PKG AS 

    FUNCTION transformation_one ( 
        P_COA_MAP_NAME in varchar2,
        p_src_sgt1 IN varchar2,
        pp_src_sgt2 IN varchar2,
        p_src_sgt3 IN varchar2,
        p_src_sgt4 IN varchar2,
        p_src_sgt5 IN varchar2,
        p_src_sgt6 IN varchar2,
        p_src_sgt7 IN varchar2,
        p_src_sgt8 IN varchar2,
        p_src_sgt9 IN varchar2,
        p_src_sgt10 IN varchar2,
        p_user_name  IN varchar2
    ) RETURN VARCHAR2;

    FUNCTION  "EXIT_COA_MAP_NAME" ( 
        i_value in VARCHAR2
    ) 
    RETURN NUMBER;

    FUNCTION  ccid_match ( 
        src_sgt IN varchar2,
        P_COA_MAP_ID in  number
    )RETURN VARCHAR2;

	PROCEDURE leg_coa_transformation(p_batch_id IN number, p_user_name in varchar2);
    
    PROCEDURE leg_coa_transformation_adfdi(p_batch_id IN number, p_user_name in varchar2);
    
end WSC_USER_COA_TRANSFORMATION_PKG;
/