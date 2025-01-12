create or replace PACKAGE WSC_UNIVERSAL_PKG AS 

FUNCTION  "WSC_CCID_DUPLICATE" ( 
    P_COA_MAP_NAME VARCHAR2,
    P_source_segment VARCHAR2
)RETURN NUMBER;

FUNCTION  "WSC_CCID_EXIST_COA_MAP_NAME" ( 
    i_value VARCHAR2  
) RETURN NUMBER;

FUNCTION  "WSC_COA_VALUE_SEGMENT_EXISTS_RULE_NAME" ( 
    i_value VARCHAR2 
) RETURN NUMBER ;
FUNCTION  "WSC_COA_VALUE_SEG_DUPLICATE" ( 
    rule_nameV VARCHAR2,
    source_segment1V VARCHAR2,
    source_segment2V VARCHAR2,
    source_segment3V VARCHAR2,
    source_segment4V VARCHAR2,
    source_segment5V VARCHAR2,
    source_segment6V VARCHAR2,
    source_segment7V VARCHAR2,
    source_segment8V VARCHAR2,
    source_segment9V VARCHAR2,
    source_segment10V VARCHAR2
    )RETURN NUMBER;

    FUNCTION  "WSC_COA_VALUE_SEG_IS_NUMBER" ( 
    p_string varchar2
) RETURN NUMBER;

FUNCTION  "WSC_USER_MAPPING_EXIT_COA_MAP_NAME" ( 
    i_value in VARCHAR2
    ) 
RETURN NUMBER;

PROCEDURE wsc_ccid_map_name(o_Clobdata OUT CLOB , P_CCID_MAP_NAME IN Number);
PROCEDURE wsc_tranform_coa_user_mapping(o_Clobdata OUT CLOB,P_USER_NAME IN VARCHAR2);
PROCEDURE wsc_user_coa_map_name(o_Clobdata OUT CLOB , P_COA_MAP_NAME IN Number);
PROCEDURE WSC_USER_COA_MAP_TEMPLATE(o_Clobdata OUT CLOB);
PROCEDURE WSC_VALUE_SEG_CAHE_DOWNLOAD(o_Clobdata OUT CLOB , P_COA_MAP_NAME IN Number);
PROCEDURE wsc_value_seg_coa_map_name(o_Clobdata OUT CLOB , P_COA_MAP_NAME IN Number);
end WSC_UNIVERSAL_PKG;
/