create table wsc_gl_coa_mapping_rules_t_oc_159_bkp as select * from finint.wsc_gl_coa_mapping_rules_t where rule_id 
in (31,34,8) and source_system='CENTRAL';
commit;
/