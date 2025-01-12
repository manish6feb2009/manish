create table wsc_ahcs_int_control_t_bckup_INC2618056 as
select * from wsc_ahcs_int_control_t where group_id = 15 ;


update wsc_ahcs_int_control_t
set group_id = null
where group_id = 15;