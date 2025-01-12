/**** Data Fix for CM Batches 11280 & 20601 */

-- Back up table 
create table finint.WSC_ahcs_lsi_control_t_INC3565711 as 
SELECT * FROM finint.WSC_ahcs_lsi_control_t where batch_id IN ( '11280','20601');


UPDATE  finint.WSC_ahcs_lsi_control_t  set status = 'MATCHED'
where batch_id IN ( '11280','20601');   -- 2 rows updates


-- Additional datafixes for batch 11280 from November
create table finint.wsc_ahcs_lsi_ap_t_INC3565711 as 
SELECT * FROM finint.wsc_ahcs_lsi_ap_t where batch_id= 11280 and (status is null or status='ERROR');

UPDATE finint.wsc_ahcs_lsi_ap_t set  PAYMENT_DATE = '29-MAY-24'
where batch_id= 11280 and (status is null or status='ERROR');  -- 538 rows updated

create table finint.Wsc_LSI_RECEIPT_FBDI_T_INC3565711 as 
SELECT * FROM finint.Wsc_LSI_RECEIPT_FBDI_T where batch_id= 11280;

UPDATE finint.Wsc_LSI_RECEIPT_FBDI_T set segment20 = '240529'
where batch_id= 11280;   -- 374 rows updated

-- create control table entry 

Insert into finint.WSC_AHCS_int_CONTROL_T (BATCH_ID,SOURCE_APPLICATION,TARGET_APPLICATION,FILE_NAME,STATUS,TOTAL_RECORDS,TOTAL_CREDITS,TOTAL_DEBITS,UCM_ID,IMPORT_ACC_ID,CREATE_ACC_ID,ATTRIBUTE1,ATTRIBUTE2,ATTRIBUTE3,ATTRIBUTE4,ATTRIBUTE5,SOURCE_SYSTEM,TARGET_SYSTEM,CREATED_BY,CREATED_DATE,LAST_UPDATED_BY,LAST_UPDATED_DATE,ATTRIBUTE6,ATTRIBUTE7,ATTRIBUTE8,ATTRIBUTE9,ATTRIBUTE10,ATTRIBUTE11,ATTRIBUTE12,ERROR_FILE_SENT_FLAG,GROUP_ID) values ('11280','Oracle LSI','Oracle AHCS','ORACLELSI_CM_04112023043033','TRANSFORM SUCCESS',null,null,null,null,null,null,null,null,null,null,null,'Oracle LSI','Oracle ERP Cloud','FININT',to_timestamp('04-MAY-24 04.30.13.000000000 AM','DD-MON-RR HH.MI.SSXFF AM'),'FININT',to_timestamp('04-MAY-24 04.30.13.000000000 AM','DD-MON-RR HH.MI.SSXFF AM'),null,null,null,null,null,null,null,null,null);

commit;










