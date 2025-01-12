/*** 33 Rows updated ***/
update finint.wsc_ahcs_lsi_ap_t set exchange_rate_type='Actual Rate' where exchange_rate_type='Month End Rate'
and status='ERROR' and batch_id in (3594,3460,3526,3663,3373,3421);

commit;