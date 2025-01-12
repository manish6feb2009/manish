-- updateing ccid table with coa_map_id = 2
update FININT.WSC_GL_CCID_MAPPING_T set enable_flag = 'N',LAST_UPDATED_BY = 'FIN_INT', LAST_UPDATE_DATE = sysdate where coa_map_id = 2;
commit;