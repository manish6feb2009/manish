/**Changes related to Batch id 3205**/	
/**	BKP Table for 3205  **/
Create table FININT.wsc_ahcs_lsi_ap_ar_t_INC2679421  as select * from FININT.wsc_ahcs_lsi_ap_ar_t where batch_id in (3197,3205);

/**	Invoice 506523900004LSI was again tried for creation in SAAS in batch id 3205 due to concurrency issue **/
Delete from FININT.wsc_ahcs_lsi_ap_ar_t where invoice_fbdi_submit_id=5437566 and batch_id=3205;
commit;

/**	BKP Table for 3205 and 3197  **/
Create table FININT.wsc_ahcs_lsi_control_t_INC2679421  as select * from FININT.wsc_ahcs_lsi_control_t where batch_id in (3205,3197);

/** Status needs to be corrected for 3205 on LSI Dashboard which was impacted due to concurrency issue**/
Update FININT.wsc_ahcs_lsi_control_t set INV_CREATE_STATUS='SUCCESS',MATCHED_COUNT='1/1' where batch_id=3205;
commit;

/**	BKP Table for 3197  **/
Create table FININT.wsc_ahcs_lsi_ap_t_INC2679421  as select * from FININT.wsc_ahcs_lsi_ap_t where batch_id in (3197);

/**	BKP Table for 3197  **/
Create table FININT.wsc_ahcs_lsi_ar_t_INC2679421  as select * from FININT.wsc_ahcs_lsi_ar_t where batch_id in (3197);

/**	BKP Table for 3197  **/
Create table FININT.wsc_lsi_credit_memo_invoice_t_INC2679421  as select * from FININT.wsc_lsi_credit_memo_invoice_t;

/**	BKP Table for 3197  **/
Create table FININT.WSC_AHCS_LSI_INVOICE_FOR_CM_H_T_INC2679421  as select * from FININT.WSC_AHCS_LSI_INVOICE_FOR_CM_H_T WHERE BATCH_ID=3197;




/**Changes related to Batch id 3197**/	
/***Records deleted as part of MATCHING Process***/
Insert into FININT.wsc_ahcs_lsi_ap_ar_t
(RECORD_TYPE                         ,                                          
BU                                  ,     
INVOICE_NUMBER                      ,                                          
LEDGER_NAME                         ,                                          
ACCOUNTING_CLASS                    ,                                          
INVOICE_DATE                        ,
ACCOUNTING_DATE                     ,
EXCHANGE_RATE                       ,
EXCHANGE_RATE_TYPE                  ,                                          
EXCHANGE_RATE_DATE                  ,
ENTERED_INVOICE_AMOUNT              ,
ACCOUNTED_INVOICE_AMOUNT            ,
GL_CODE_COMBINATION                 ,                                          
INTERCOMPANY_LEGAL_ENTITY           ,                                          
INTERCOMPANY_TRANSACTION_TYPE       ,                                          
INTERCOMPANY_BATCH_NUMBER           ,
VENDOR_CUST_NAME                    ,                                          
VENDOR_CUST_SITE                    ,                                          
ACCOUNT_NUMBER                      ,                                          
LOCKBOX_NUMBER                      ,                                          
BANK_ORIGINATION_NUMBER             ,                                          
INVOICE_CURRENCY_CODE               ,                                          
FUNCTIONAL_CURRENCY_CODE            ,                                          
CHECK_ID                            ,                                          
PAYMENT_NUMBER                      ,                                          
BANK_ACC                            ,                                          
BATCH_ID                            ,                                          
NETTING_LEDGER                      ,                                          
NETTING_FUN_CURR                    ,                                          
IC_TRX_NUMBER                       ,                                          
INVOICE_ID                          ,                                          
BU_ID                               ,                                          
LOCKBOX_ID                          ,                                          
FILE_NAME                           ,                                          
ACCOUNTING_PERIOD                   ,                                          
EXTRACT_NAME                        ,                                          
STATUS                              ,                                          
INVOICE_FBDI_PROCESS_ID             ,
INVOICE_FBDI_SUBMIT_ID)
SELECT RECORD_TYPE                         ,                                          
BU                                  ,                                          
replace(INVOICE_NUMBER,'LSI','')                      ,                                          
LEDGER_NAME                         ,                                          
ACCOUNTING_CLASS                    ,                                          
INVOICE_DATE                        ,
ACCOUNTING_DATE                     ,
EXCHANGE_RATE                       ,
EXCHANGE_RATE_TYPE                  ,                                          
EXCHANGE_RATE_DATE                  ,
-1*ENTERED_INVOICE_AMOUNT              ,
-1*ACCOUNTED_INVOICE_AMOUNT            ,
GL_CODE_COMBINATION                 ,                                          
INTERCOMPANY_LEGAL_ENTITY           ,                                          
INTERCOMPANY_TRANSACTION_TYPE       ,                                          
INTERCOMPANY_BATCH_NUMBER           ,
VENDOR_CUST_NAME                    ,                                          
VENDOR_CUST_SITE                    ,                                          
ACCOUNT_NUMBER                      ,                                          
LOCKBOX_NUMBER                      ,                                          
BANK_ORIGINATION_NUMBER             ,                                          
INVOICE_CURRENCY_CODE               ,                                          
FUNCTIONAL_CURRENCY_CODE            ,                                          
CHECK_ID                            ,                                          
PAYMENT_NUMBER                      ,                                          
BANK_ACC                            ,                                          
BATCH_ID                            ,                                          
NETTING_LEDGER                      ,                                          
NETTING_FUN_CURR                    ,                                          
IC_TRX_NUMBER                       ,                                          
39016                               ,                                          
BU_ID                               ,                                          
LOCKBOX_ID                          ,                                          
FILE_NAME                           ,                                          
ACCOUNTING_PERIOD                   ,                                          
EXTRACT_NAME                        ,                                          
'MATCHED'							,
INVOICE_FBDI_PROCESS_ID             ,
INVOICE_FBDI_SUBMIT_ID                                                      
FROM  FININT.wsc_ahcs_lsi_ap_ar_t
where invoice_number like '506523900004LSI'  
and invoice_fbdi_submit_id=5412380;          
commit;


/** Batch ID and Status was updated to NULL due to concurrency issue**/
update FININT.wsc_ahcs_lsi_ap_ar_t set batch_id=3197,status='MATCHED' where invoice_number in 
(select replace(invoice_number,'LSI','') from FININT.wsc_ahcs_lsi_ap_ar_t where batch_id=3197);
commit;

		



