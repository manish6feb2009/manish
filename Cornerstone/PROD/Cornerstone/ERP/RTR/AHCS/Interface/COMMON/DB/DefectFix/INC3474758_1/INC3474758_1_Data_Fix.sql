create table finint.wsc_ahcs_int_control_t_INC3474758 as select * from finint.wsc_ahcs_int_control_t where file_name='CRESUS_EU_03152024_235406' and source_application='MF AP';
update finint.wsc_ahcs_int_control_t set status='GROUP_ID_GENERATED' where file_name='CRESUS_EU_03152024_235406' and source_application='MF AP';
Commit;