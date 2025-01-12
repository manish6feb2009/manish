create table wsc_ahcs_int_control_t_INC3452584_bkp as select * from finint.wsc_ahcs_int_control_t WHERE file_name = 'EBS_AP_20240319_030023' ;

create table wsc_ahcs_int_status_t_INC3452584_bkp as select * from finint.wsc_ahcs_int_status_t WHERE file_name = 'EBS_AP_20240319_030023' ;

commit;

/