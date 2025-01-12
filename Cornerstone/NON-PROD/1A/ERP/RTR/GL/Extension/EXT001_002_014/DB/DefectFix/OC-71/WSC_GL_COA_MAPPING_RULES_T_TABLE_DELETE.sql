-- deleteing old rules from coa_rules table which has coa_map_id=2
delete from FININT.WSC_GL_COA_MAPPING_RULES_T where coa_map_id = 2;
commit;