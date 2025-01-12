-- deleteing old values from coa_value table
delete from FININT.WSC_GL_COA_SEGMENT_VALUE_T where rule_id in (select distinct rule_id from FININT.WSC_GL_COA_MAPPING_RULES_T where coa_map_id = 2);
commit;