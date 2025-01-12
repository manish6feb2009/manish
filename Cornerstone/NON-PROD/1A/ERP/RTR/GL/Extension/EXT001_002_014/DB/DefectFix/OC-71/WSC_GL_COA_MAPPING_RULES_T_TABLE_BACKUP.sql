--backup table for coa_mapping_rule for anixter rules
create table FININT.WSC_GL_COA_MAPPING_RULES_T_BKUP_27_MAR_23 as select * from WSC_GL_COA_MAPPING_RULES_T where coa_map_id = 2;
commit;