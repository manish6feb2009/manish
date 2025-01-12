
update wsc_ahcs_int_control_t set STATUS ='IMP_ACC_SUCCESS' WHERE file_name = 'EBS_AP_20240319_030023';
commit;

update wsc_ahcs_int_status_t set ACCOUNTING_STATUS ='IMP_ACC_SUCCESS' WHERE file_name = 'EBS_AP_20240319_030023';

commit;