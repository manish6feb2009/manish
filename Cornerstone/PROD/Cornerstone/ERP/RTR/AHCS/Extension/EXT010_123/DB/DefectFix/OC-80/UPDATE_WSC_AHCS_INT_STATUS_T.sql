UPDATE FININT.WSC_AHCS_INT_STATUS_T
SET source_coa = Replace(source_coa, '0000', '7998')
WHERE file_name = 'cs_nightly_feed_042023001909'
AND source_coa like '0000%';
-- 2 records should be updated
