create or replace PACKAGE wsc_gl_coa_mapping_pkg IS
    
    FUNCTION coa_mapping(
	src_system VARCHAR2,
	tgt_system VARCHAR2,
    segment_value1 VARCHAR2,
    segment_value2 VARCHAR2,
    segment_value3 VARCHAR2,
    segment_value4 VARCHAR2,
    segment_value5 VARCHAR2,
    segment_value6 VARCHAR2,
    segment_value7 VARCHAR2,
    segment_value8 VARCHAR2,
    segment_value9 VARCHAR2,
    segment_value10 VARCHAR2
) RETURN VARCHAR2;

    FUNCTION  ccid_match ( 
        src_sgt IN varchar2,
        P_COA_MAP_ID in  number
    ) RETURN VARCHAR2;

--   PROCEDURE populate_mapped_coa(
--        src_system varchar2,
--		tgt_system varchar2
--		);

END wsc_gl_coa_mapping_pkg;
/