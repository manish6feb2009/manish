create table wsc_ahcs_lsi_control_t_INC2764852 
as select * from wsc_ahcs_lsi_control_t where batch_id=3373;

update wsc_ahcs_lsi_control_t set ahcs_import_status='SUCCESS' where batch_id=3373;
commit;
/