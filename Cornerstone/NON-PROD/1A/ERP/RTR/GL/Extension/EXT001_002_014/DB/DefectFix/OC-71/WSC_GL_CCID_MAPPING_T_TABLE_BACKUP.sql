--backup table for cache table for anixter values
create table FININT.WSC_GL_CCID_MAPPING_T_BKUP_27_MAR_23 as select * from WSC_GL_CCID_MAPPING_T where coa_map_id = 2;
commit;