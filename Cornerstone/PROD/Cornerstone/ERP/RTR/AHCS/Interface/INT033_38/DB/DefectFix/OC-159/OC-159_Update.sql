update finint.wsc_gl_coa_mapping_rules_t set rule_priority=2,last_updated_by='FIN_INT',LAST_UPDATE_DATE=SYSDATE where rule_id=31 and source_system='CENTRAL';

update finint.wsc_gl_coa_mapping_rules_t set rule_priority=3,last_updated_by='FIN_INT',LAST_UPDATE_DATE=SYSDATE where rule_id=34 and source_system='CENTRAL';

update finint.wsc_gl_coa_mapping_rules_t set rule_priority=4,last_updated_by='FIN_INT',LAST_UPDATE_DATE=SYSDATE where rule_id=8 and source_system='CENTRAL';

commit;
/
