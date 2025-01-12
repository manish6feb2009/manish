---EBS
Insert into finint.wsc_gl_coa_mapping_rules_t
(RULE_ID,COA_MAP_ID,RULE_NAME,DESCRIPTION,RULE_PRIORITY,SOURCE_SYSTEM,TARGET_SYSTEM,SOURCE_SEGMENT1,SOURCE_SEGMENT2,SOURCE_SEGMENT3,SOURCE_SEGMENT4,SOURCE_SEGMENT5,SOURCE_SEGMENT6,SOURCE_SEGMENT7,SOURCE_SEGMENT8,SOURCE_SEGMENT9,SOURCE_SEGMENT10,TARGET_SEGMENT,DEFAULT_VALUE,CREATED_BY,CREATION_DATE,LAST_UPDATED_BY,LAST_UPDATE_DATE,LAST_UPDATED_LOGIN,ATTRIBUTE1,ATTRIBUTE2,ATTRIBUTE3,ATTRIBUTE4,ATTRIBUTE5,ATTRIBUTE6,ATTRIBUTE7,ATTRIBUTE8,ATTRIBUTE9,ATTRIBUTE10) 
values (71,1,'WESCO - Site - Based on Account',null,1,'Oracle EBS','Oracle ERP Cloud',null,null,'Y',null,null,null,null,null,null,null,'segment5',null,null,sysdate,null,null,null,null,null,null,null,null,null,null,null,null,null);
commit;
---select * from finint.wsc_gl_coa_mapping_rules_t where rule_id='71' and source_system='Oracle EBS'; --- should retun 1 row
/

---POC
Insert into finint.wsc_gl_coa_mapping_rules_t
(RULE_ID,COA_MAP_ID,RULE_NAME,DESCRIPTION,RULE_PRIORITY,SOURCE_SYSTEM,TARGET_SYSTEM,SOURCE_SEGMENT1,SOURCE_SEGMENT2,SOURCE_SEGMENT3,SOURCE_SEGMENT4,SOURCE_SEGMENT5,SOURCE_SEGMENT6,SOURCE_SEGMENT7,SOURCE_SEGMENT8,SOURCE_SEGMENT9,SOURCE_SEGMENT10,TARGET_SEGMENT,DEFAULT_VALUE,CREATED_BY,CREATION_DATE,LAST_UPDATED_BY,LAST_UPDATE_DATE,LAST_UPDATED_LOGIN,ATTRIBUTE1,ATTRIBUTE2,ATTRIBUTE3,ATTRIBUTE4,ATTRIBUTE5,ATTRIBUTE6,ATTRIBUTE7,ATTRIBUTE8,ATTRIBUTE9,ATTRIBUTE10) 
values (71,4,'WESCO - Site - Based on Account',null,1,'Oracle POC','Oracle ERP Cloud',null,null,'Y',null,null,null,null,null,null,null,'segment5',null,null,sysdate,null,sysdate,null,null,null,null,null,null,null,null,null,null,null);
commit;
---select * from finint.wsc_gl_coa_mapping_rules_t where rule_id=71 and source_system='Oracle POC'; --- should retuen 1 row
/