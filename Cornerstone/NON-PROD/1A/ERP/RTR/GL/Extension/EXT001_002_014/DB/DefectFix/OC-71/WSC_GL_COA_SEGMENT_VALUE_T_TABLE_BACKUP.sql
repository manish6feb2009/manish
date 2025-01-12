--backup table for coa value for anixter values
create table FININT.WSC_GL_COA_SEGMENT_VALUE_T_BKUP_27_MAR_23 as select * from WSC_GL_COA_SEGMENT_VALUE_T 
where rule_id in (select distinct rule_id from FININT.WSC_GL_COA_MAPPING_RULES_T where coa_map_id = 2);
commit;