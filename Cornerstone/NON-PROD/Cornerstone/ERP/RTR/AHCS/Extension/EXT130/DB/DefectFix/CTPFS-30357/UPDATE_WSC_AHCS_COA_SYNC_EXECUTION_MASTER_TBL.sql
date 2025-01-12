update wsc_ahcs_coa_sync_execution_master_tbl
set coa_mapping_rule = 'Anixter - OpGroup - Based on Location'
where coa_mapping_rule = 'Anixter - OpGroup - Based on Location ';

commit;
-- 8 records should be updated
