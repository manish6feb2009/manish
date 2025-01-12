create table finint.WSC_AHCS_COA_SYNC_EXECUTION_HDR_TBL_INC3408050 as select * from "FININT"."WSC_AHCS_COA_SYNC_EXECUTION_HDR_TBL" where batch_id=12;

update FININT.WSC_AHCS_COA_SYNC_EXECUTION_HDR_TBL set submission_status='CANCELLED' where batch_id='12';
commit;
-- 1 record should be updated
