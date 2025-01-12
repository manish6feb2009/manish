----EBS
update finint.wsc_gl_coa_mapping_rules_t set rule_priority='2' where rule_name='WESCO - Site - Based on Branch'
and rule_id=9 and source_system='Oracle EBS' and rule_priority='1';
commit;
--- select * from finint.wsc_gl_coa_mapping_rules_t where rule_priority='2' and rule_name='WESCO - Site - Based on Branch' and rule_id=9 and source_system='Oracle EBS';--it should return one row 
--- select * from finint.wsc_gl_coa_mapping_rules_t where rule_priority='1' and rule_name='WESCO - Site - Based on Branch' and rule_id=9 and source_system='Oracle EBS';--it should return zero row 
/

update finint.wsc_gl_coa_mapping_rules_t set rule_priority='3' where rule_name='Site - Default'
and rule_id=26 and source_system='Oracle EBS' and rule_priority='2';
commit;
--- select * from finint.wsc_gl_coa_mapping_rules_t where rule_priority='3' and rule_name='Site - Default' and rule_id=26 and source_system='Oracle EBS'; it should return 1 row.
--- select * from finint.wsc_gl_coa_mapping_rules_t where rule_priority='2' and rule_name='Site - Default' and rule_id=26 and source_system='Oracle EBS'; it should return 0 row.
/


----POC
update finint.wsc_gl_coa_mapping_rules_t set rule_priority='2' where rule_name='WESCO - Site - Based on Branch'
and rule_id=9 and source_system='Oracle POC' and rule_priority='1';
commit;
--- select * from finint.wsc_gl_coa_mapping_rules_t where rule_priority='2' and rule_name='WESCO - Site - Based on Branch' and rule_id=9 and source_system='Oracle POC'; --- it should return 1 row
--- select * from finint.wsc_gl_coa_mapping_rules_t where rule_priority='1' and rule_name='WESCO - Site - Based on Branch' and rule_id=9 and source_system='Oracle POC'; --- it should return 0 rows
/

update finint.wsc_gl_coa_mapping_rules_t set rule_priority='3' where rule_name='Site - Default'
and rule_id=26 and source_system='Oracle POC'; --- it shoudl return 1 row
commit;
--select * from finint.wsc_gl_coa_mapping_rules_t where rule_priority='3' and rule_name='Site - Default' and rule_id=26 and source_system='Oracle POC'; --- it should return 1 row
--select * from finint.wsc_gl_coa_mapping_rules_t where rule_priority='2' and rule_name='Site - Default' and rule_id=26 and source_system='Oracle POC'; --- it should return 0 rows
/