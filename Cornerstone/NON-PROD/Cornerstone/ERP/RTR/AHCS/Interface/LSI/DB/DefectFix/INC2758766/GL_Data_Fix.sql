create table finint.wsc_ahcs_lsi_journal_t_INC2758766 as SELECT * FROM finint.wsc_ahcs_lsi_journal_t
WHERE  batch_id IN (3306,3372,3420,3459) and intercompany_batch_number
in (
--3306
2835,
2834,
-- 3372
2916,
2914,
2915,
2928,
2903,
2921,
2940,
2917,
2920,
2930,
2935,
2902,
2919,
2901,
2934,
2949,
--3420
2958,
2963,
2961,
2960,
--3459
2999,
2973,
2998,
2997,
3021,
3000
)
and exchange_rate_type='300000275885426';

/*3306*/
update finint.wsc_ahcs_lsi_journal_t set exchange_rate_type='300000275885425' where batch_id=3306 and intercompany_batch_number
in (2835,
2834
)
and exchange_rate_type='300000275885426'; -- 2 rows updated

/*3372*/
update finint.wsc_ahcs_lsi_journal_t set exchange_rate_type='300000275885425' where batch_id=3372 and intercompany_batch_number
in (2916,
2914,
2915,
2928,
2903,
2921,
2940,
2917,
2920,
2930,
2935,
2902,
2919,
2901,
2934,
2949
)
and exchange_rate_type='300000275885426'; --32 rows updated

/*3402*/
update finint.wsc_ahcs_lsi_journal_t set exchange_rate_type='300000275885425' where batch_id=3420 and intercompany_batch_number
in (2958,
2963,
2961,
2960
)
and exchange_rate_type='300000275885426'; --5 rows updated

/*3459*/
update finint.wsc_ahcs_lsi_journal_t set exchange_rate_type='300000275885425' where batch_id=3459 and intercompany_batch_number
in (2999,
2973,
2998,
2997,
3021,
3000
)
and exchange_rate_type='300000275885426'; --10 rows updated

commit;