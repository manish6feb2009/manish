--backup table for cache table for anixter values
create table FININT.WSC_GL_CCID_MAPPING_T_BKUP_13_APR_23 as select * from FININT.WSC_GL_CCID_MAPPING_T where coa_map_id = 2;
commit;