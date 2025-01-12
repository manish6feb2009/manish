---EBS
create table finint.wsc_gl_coa_mapping_rules_t_oc_277_ebs as select * from finint.wsc_gl_coa_mapping_rules_t where rule_name='WESCO - Site - Based on Branch'
and rule_id=9 and source_system='Oracle EBS';
commit;
---select * from finint.wsc_gl_coa_mapping_rules_t_oc_277_ebs; should return 1 row
/

create table finint.wsc_gl_coa_mapping_rules_t_oc_277_ebs_default as select * from finint.wsc_gl_coa_mapping_rules_t where rule_name='Site - Default' and rule_id=26 and source_system='Oracle EBS';
commit;
---select * from finint.wsc_gl_coa_mapping_rules_t_oc_277_ebs_default; should return 1 row
/


---POC
create table finint.wsc_gl_coa_mapping_rules_t_oc_277_poc as select * from finint.wsc_gl_coa_mapping_rules_t where rule_name='WESCO - Site - Based on Branch'
and rule_id=9 and source_system='Oracle POC';
commit;
---select * from finint.wsc_gl_coa_mapping_rules_t_oc_277_poc; should return 1 row
/

create table finint.wsc_gl_coa_mapping_rules_t_oc_277_poc_default as select * from finint.wsc_gl_coa_mapping_rules_t where rule_name='Site - Default' and rule_id=26 and source_system='Oracle POC';
commit;
---select * from finint.wsc_gl_coa_mapping_rules_t_oc_277_poc_default; should return 1 row
/