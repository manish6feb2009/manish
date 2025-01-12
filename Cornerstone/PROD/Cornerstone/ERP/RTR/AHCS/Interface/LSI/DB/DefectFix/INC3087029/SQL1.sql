create table wsc_ahcs_lsi_control_t_INC3087029 
as select * from wsc_ahcs_lsi_control_t where batch_id=10757;

update wsc_ahcs_lsi_control_t set receipt_status='ERROR' where batch_id=10757;
commit;
/