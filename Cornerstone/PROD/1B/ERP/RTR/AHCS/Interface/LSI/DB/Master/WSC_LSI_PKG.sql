create or replace PACKAGE          WSC_LSI_PKG AS 

    PROCEDURE WSC_LSI_LOOKUP_P
    (
      IN_WSC_LOOKUP IN WSC_AHCS_LSI_LOOKUP_T_TYPE_TABLE
    );

    procedure wsc_ahcs_lsi_kickoff_reprocess(P_BATCH_ID number, LV_ACC_DATE date);

    PROCEDURE lsi_error_report_download(o_Clobdata OUT CLOB);
    PROCEDURE wsc_lsi_ar_ap_download(o_Clobdata OUT CLOB) ;
    PROCEDURE wsc_lsi_ar_ap_cm_err(o_Clobdata OUT CLOB);
     Function GetNettingLE(LE VARCHAR2,AP_LEDGER VARCHAR2,AR_LEDGER VARCHAR2) RETURN VARCHAR2;
     Function GetNettingNettingLE(LE VARCHAR2) RETURN VARCHAR2;
    Function ISPriorityBU(LE VARCHAR2) RETURN NUMBER;
     Function GetNettingLEDGER(LE VARCHAR2) RETURN VARCHAR2;
     Function GetNettingFunCurr(LE VARCHAR2) RETURN VARCHAR2;
      Function ISNettingLEFinal(LE VARCHAR2,NETT_LE VARCHAR2,AP_LEDGER VARCHAR2,AR_LEDGER VARCHAR2) RETURN VARCHAR2;
      Function GetEMEA(LEDGER VARCHAR2) RETURN VARCHAR2;
      FUNCTION ISFINALBU(LEPR_LE VARCHAR2,RCV_LE VARCHAR2,AP_LEDGER VARCHAR2,AR_LEDGER VARCHAR2) RETURN VARCHAR2;

    Procedure LSI_SC1(  P_BATCH_ID                          NUMBER,
                    AR_CCID                             VARCHAR2,
                    AR_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AR         VARCHAR2,
                    accounted_invoice_amount_AR         NUMBER,
                    intercompany_legal_entity_AR        VARCHAR2,
                    intercompany_transaction_type_AR    VARCHAR2,
                    invoice_number_AR                   VARCHAR2,
                    AP_CCID                             VARCHAR2,
                    AP_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AP         VARCHAR2,
                    accounted_invoice_amount_AP         NUMBER,
                    intercompany_transaction_type_AP    VARCHAR2,
                    invoice_number_AP                   VARCHAR2,
                    NETTING_AR_LE                       VARCHAR2,
                    NETTING_AR_LEDGER                   VARCHAR2,
                    AR_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AR_FUN_CURR                 VARCHAR2,
                    AP_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AP_FUN_CURR                 VARCHAR2,
                    intercompany_legal_entity_AP        VARCHAR2,
                    NETTING_AP_LE                       VARCHAR2,
                    NETTING_AP_LEDGER                   VARCHAR2,
					AP_EXCHANGE_RATE_TYPE 				VARCHAR2,
					AR_EXCHANGE_RATE_TYPE				VARCHAR2,
					RECORD_TYPE VARCHAR2,
					IC_TRX_NUMBER VARCHAR2,
					AP_INVOICE_ID NUMBER,
					AR_INVOICE_ID NUMBER,
                     AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
					ACCOUNTING_PERIOD VARCHAR2,
                    intercompany_batch_number_ap VARCHAR2);

PROCEDURE LSI_SC2(AR_CCID                           VARCHAR2,                
                 P_BATCH_ID                          NUMBER,
                AR_LEDGER                         VARCHAR2,
                FUNCTIONAL_CURRENCY_CODE_AR       VARCHAR2,
                ACCOUNTED_INVOICE_AMOUNT_AR       NUMBER,
                INTERCOMPANY_LEGAL_ENTITY_AR      VARCHAR2,
                INTERCOMPANY_TRANSACTION_TYPE_AR  VARCHAR2,
                INVOICE_NUMBER_AP			      VARCHAR2,
                AP_CCID                           VARCHAR2,
                AP_LEDGER                         VARCHAR2,
                FUNCTIONAL_CURRENCY_CODE_AP       VARCHAR2,
                ACCOUNTED_INVOICE_AMOUNT_AP       NUMBER,
                INTERCOMPANY_TRANSACTION_TYPE_AP  VARCHAR2,
                INTERCOMPANY_LEGAL_ENTITY_AP      VARCHAR2,
                NETTING_AR_LE                     VARCHAR2,
                NETTING_AR_LEDGER                 VARCHAR2,
                AR_EXCHANGE_RATE_NETTING          VARCHAR2,
                NETTING_AR_FUN_CURR               VARCHAR2,
                NETTING_AP_LE                     VARCHAR2,
                NETTING_AP_LEDGER                 VARCHAR2,
                AP_EXCHANGE_RATE_NETTING          VARCHAR2,
                NETTING_AP_FUN_CURR               VARCHAR2,
				AP_EXCHANGE_RATE_TYPE 			  VARCHAR2,
				AR_EXCHANGE_RATE_TYPE			  VARCHAR2,
				RECORD_TYPE						  VARCHAR2,
				IC_TRX_NUMBER 					  VARCHAR2,
				AP_INVOICE_ID                     NUMBER,
				AR_INVOICE_ID                     NUMBER,
                 AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
				ACCOUNTING_PERIOD                 VARCHAR2,
                intercompany_batch_number_ap VARCHAR2);

PROCEDURE LSI_SC3( AR_CCID                           VARCHAR2,                    
                    P_BATCH_ID                         NUMBER, 
                    AR_LEDGER                         VARCHAR2,
                    FUNCTIONAL_CURRENCY_CODE_AR       VARCHAR2,
                    ACCOUNTED_INVOICE_AMOUNT_AR       NUMBER,
                    INTERCOMPANY_LEGAL_ENTITY_AR      VARCHAR2,
                    INTERCOMPANY_TRANSACTION_TYPE_AR  VARCHAR2,
                    INVOICE_NUMBER_AP			      VARCHAR2,
                    AP_CCID                           VARCHAR2,
                    AP_LEDGER                         VARCHAR2,
                    FUNCTIONAL_CURRENCY_CODE_AP       VARCHAR2,
                    ACCOUNTED_INVOICE_AMOUNT_AP       NUMBER,
                    INTERCOMPANY_TRANSACTION_TYPE_AP  VARCHAR2,
                    INTERCOMPANY_LEGAL_ENTITY_AP      VARCHAR2,
                    NETTING_AR_LE                     VARCHAR2,
                    NETTING_AR_LEDGER                 VARCHAR2,
                    AR_EXCHANGE_RATE_NETTING          VARCHAR2,
                    NETTING_AR_FUN_CURR               VARCHAR2,
                    NETTING_AP_LE                     VARCHAR2,
                    NETTING_AP_LEDGER                 VARCHAR2,
                    AP_EXCHANGE_RATE_NETTING          VARCHAR2,
                   NETTING_AP_FUN_CURR               VARCHAR2,
                    AP_EXCHANGE_RATE_TYPE 		  VARCHAR2,
					AR_EXCHANGE_RATE_TYPE			  VARCHAR2,
					RECORD_TYPE						  VARCHAR2,
					IC_TRX_NUMBER 					  VARCHAR2,
					AP_INVOICE_ID                     NUMBER,
					AR_INVOICE_ID                     NUMBER,
                     AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
					ACCOUNTING_PERIOD                 VARCHAR2,
                    intercompany_batch_number_ap VARCHAR2);  

PROCEDURE LSI_SC4_1(AR_CCID                          VARCHAR2,                
                P_BATCH_ID                        VARCHAR2,
                AR_LEDGER                         VARCHAR2,
                FUNCTIONAL_CURRENCY_CODE_AR       VARCHAR2,
                ACCOUNTED_INVOICE_AMOUNT_AR       VARCHAR2,
                INTERCOMPANY_LEGAL_ENTITY_AR      VARCHAR2,
                INTERCOMPANY_TRANSACTION_TYPE_AR  VARCHAR2,
                INVOICE_NUMBER_AP			      VARCHAR2,
                AP_CCID                           VARCHAR2,
                AP_LEDGER                         VARCHAR2,
                FUNCTIONAL_CURRENCY_CODE_AP       VARCHAR2,
                ACCOUNTED_INVOICE_AMOUNT_AP       NUMBER,
                INTERCOMPANY_TRANSACTION_TYPE_AP  VARCHAR2,
                INTERCOMPANY_LEGAL_ENTITY_AP      VARCHAR2,
                NETTING_AR_LE                     VARCHAR2,
                NETTING_AR_LEDGER                 VARCHAR2,
                AR_EXCHANGE_RATE_NETTING          VARCHAR2,
                NETTING_AR_FUN_CURR               VARCHAR2,
                NETTING_AP_LE                     VARCHAR2,
                NETTING_AP_LEDGER                 VARCHAR2,
                AP_EXCHANGE_RATE_NETTING          VARCHAR2,
                NETTING_AP_FUN_CURR               VARCHAR2,
                ENTERED_INVOICE_AMOUNT_AP         NUMBER,
				AP_EXCHANGE_RATE_TYPE 		  VARCHAR2,
			    AR_EXCHANGE_RATE_TYPE			  VARCHAR2,
				RECORD_TYPE						  VARCHAR2,
				IC_TRX_NUMBER 					  VARCHAR2,
				AP_INVOICE_ID                     NUMBER,
				AR_INVOICE_ID                     NUMBER,
                 AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
				ACCOUNTING_PERIOD                 VARCHAR2,
                intercompany_batch_number_ap VARCHAR2);


PROCEDURE LSI_SC4_2(AR_CCID                           VARCHAR2,    
                    P_BATCH_ID  					  VARCHAR2,
                    AR_LEDGER                         VARCHAR2,
                    FUNCTIONAL_CURRENCY_CODE_AR       VARCHAR2,
                    ACCOUNTED_INVOICE_AMOUNT_AR       NUMBER,
                    INTERCOMPANY_LEGAL_ENTITY_AR      VARCHAR2,
                    INTERCOMPANY_TRANSACTION_TYPE_AR  VARCHAR2,
                    INVOICE_NUMBER_AP			      VARCHAR2,
                    AP_CCID                           VARCHAR2,
                    AP_LEDGER                         VARCHAR2,
                    FUNCTIONAL_CURRENCY_CODE_AP       VARCHAR2,
                    ACCOUNTED_INVOICE_AMOUNT_AP       NUMBER,
                    INTERCOMPANY_TRANSACTION_TYPE_AP  VARCHAR2,
                    INTERCOMPANY_LEGAL_ENTITY_AP      VARCHAR2,
                    NETTING_AR_LE                     VARCHAR2,
                    NETTING_AR_LEDGER                 VARCHAR2,
                    AR_EXCHANGE_RATE_NETTING          VARCHAR2,
                    NETTING_AR_FUN_CURR               VARCHAR2,
                    NETTING_AP_LE                     VARCHAR2,
                    NETTING_AP_LEDGER                 VARCHAR2,
                    AP_EXCHANGE_RATE_NETTING          VARCHAR2,
                    NETTING_AP_FUN_CURR               VARCHAR2,
					AP_EXCHANGE_RATE_TYPE 		      VARCHAR2,
					AR_EXCHANGE_RATE_TYPE			  VARCHAR2,
					RECORD_TYPE						  VARCHAR2,
					IC_TRX_NUMBER 					  VARCHAR2,
					AP_INVOICE_ID                     NUMBER,
					AR_INVOICE_ID                     NUMBER,
                     AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
					ACCOUNTING_PERIOD                 VARCHAR2,
					intercompany_batch_number_ap VARCHAR2) ;

PROCEDURE LSI_SC5_1(P_BATCH_ID                   NUMBER,
                AR_CCID                           VARCHAR2,    
                AR_LEDGER                         VARCHAR2,
                FUNCTIONAL_CURRENCY_CODE_AR       VARCHAR2,
                ACCOUNTED_INVOICE_AMOUNT_AR       NUMBER,
                INTERCOMPANY_BATCH_NUMBER_AP      VARCHAR2,
                INTERCOMPANY_LEGAL_ENTITY_AR      VARCHAR2,
                INTERCOMPANY_TRANSACTION_TYPE_AR  VARCHAR2,
                INVOICE_NUMBER_AP			      VARCHAR2,
                INVOICE_NUMBER_AR                 VARCHAR2,
                AP_CCID                           VARCHAR2,
                AP_LEDGER                         VARCHAR2,
                FUNCTIONAL_CURRENCY_CODE_AP       VARCHAR2,
                ACCOUNTED_INVOICE_AMOUNT_AP       VARCHAR2,
                INTERCOMPANY_TRANSACTION_TYPE_AP  VARCHAR2,
                INTERCOMPANY_LEGAL_ENTITY_AP      VARCHAR2,
                NETTING_AR_LE                     VARCHAR2,
                NETTING_AR_LEDGER                 VARCHAR2,
                AR_EXCHANGE_RATE_NETTING          VARCHAR2,
                NETTING_AR_FUN_CURR               VARCHAR2,
                NETTING_AP_LE                     VARCHAR2,
                NETTING_AP_LEDGER                 VARCHAR2,
                AP_EXCHANGE_RATE_NETTING          VARCHAR2,
                NETTING_AP_FUN_CURR               VARCHAR2,
				AP_EXCHANGE_RATE_TYPE 		      VARCHAR2,
				AR_EXCHANGE_RATE_TYPE			  VARCHAR2,
				RECORD_TYPE						  VARCHAR2,
				IC_TRX_NUMBER 					  VARCHAR2,
				AP_INVOICE_ID                     NUMBER,
				AR_INVOICE_ID                     NUMBER,
                 AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
				ACCOUNTING_PERIOD                 VARCHAR2) ;                    

  PROCEDURE LSI_SC5_2(P_BATCH_ID					  NUMBER,
				AR_CCID                           VARCHAR2,    
                AR_LEDGER                         VARCHAR2,
                FUNCTIONAL_CURRENCY_CODE_AR       VARCHAR2,
                ACCOUNTED_INVOICE_AMOUNT_AR       NUMBER,
                INTERCOMPANY_BATCH_NUMBER_AP      VARCHAR2,
                INTERCOMPANY_LEGAL_ENTITY_AR      VARCHAR2,
                INTERCOMPANY_TRANSACTION_TYPE_AR  VARCHAR2,
                INVOICE_NUMBER_AP			      VARCHAR2,
                INVOICE_NUMBER_AR                 VARCHAR2,
                AP_CCID                           VARCHAR2,
                AP_LEDGER                         VARCHAR2,
                FUNCTIONAL_CURRENCY_CODE_AP       VARCHAR2,
                ACCOUNTED_INVOICE_AMOUNT_AP       NUMBER,
                INTERCOMPANY_TRANSACTION_TYPE_AP  VARCHAR2,
                INTERCOMPANY_LEGAL_ENTITY_AP      VARCHAR2,
                NETTING_AR_LE                     VARCHAR2,
                NETTING_AR_LEDGER                 VARCHAR2,
                AR_EXCHANGE_RATE_NETTING          VARCHAR2,
                NETTING_AR_FUN_CURR               VARCHAR2,
                NETTING_AP_LE                     VARCHAR2,
                NETTING_AP_LEDGER                 VARCHAR2,
                AP_EXCHANGE_RATE_NETTING          VARCHAR2,
                NETTING_AP_FUN_CURR               VARCHAR2,
				AP_EXCHANGE_RATE_TYPE 		      VARCHAR2,
				AR_EXCHANGE_RATE_TYPE			  VARCHAR2,
				RECORD_TYPE						  VARCHAR2,
				IC_TRX_NUMBER 					  VARCHAR2,
				AP_INVOICE_ID                     NUMBER,
				AR_INVOICE_ID                     NUMBER,
                 AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
				ACCOUNTING_PERIOD                 VARCHAR2); 

Procedure LSI_SC6A1(P_BATCH_ID          NUMBER,
                    AR_CCID                             VARCHAR2,
                    AR_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AR         VARCHAR2,
                    accounted_invoice_amount_AR         NUMBER,
                    intercompany_legal_entity_AR        VARCHAR2,
                    intercompany_transaction_type_AR    VARCHAR2,
                    invoice_number_AR                   VARCHAR2,
                    AP_CCID                             VARCHAR2,
                    AP_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AP         VARCHAR2,
                    accounted_invoice_amount_AP         NUMBER,
                    intercompany_transaction_type_AP    VARCHAR2,
                    invoice_number_AP                   VARCHAR2,
                    NETTING_AR_LE                       VARCHAR2,
                    NETTING_AR_LEDGER                   VARCHAR2,
                    AR_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AR_FUN_CURR                 VARCHAR2,
                    AP_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AP_FUN_CURR                 VARCHAR2,
                    intercompany_legal_entity_AP        VARCHAR2,
                    NETTING_AP_LE                       VARCHAR2,
                    NETTING_AP_LEDGER                   VARCHAR2,
                    AP_EXCHANGE_RATE_TYPE               VARCHAR2,
                    AR_EXCHANGE_RATE_TYPE               VARCHAR2,
                    RECORD_TYPE                         VARCHAR2,
                    IC_TRX_NUMBER                       VARCHAR2,
                    AP_INVOICE_ID                       NUMBER,
                    AR_INVOICE_ID                       NUMBER,
                     AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
                    ACCOUNTING_PERIOD                   VARCHAR2,
                    ICOM_BATCH_NUMBER                     VARCHAR2); 

Procedure LSI_SC6A2( P_BATCH_ID                          NUMBER,
                    AR_CCID                             VARCHAR2,
                    AR_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AR         VARCHAR2,
                    accounted_invoice_amount_AR         NUMBER,
                    intercompany_legal_entity_AR        VARCHAR2,
                    intercompany_transaction_type_AR    VARCHAR2,
                    invoice_number_AR                   VARCHAR2,
                    AP_CCID                             VARCHAR2,
                    AP_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AP         VARCHAR2,
                    accounted_invoice_amount_AP         NUMBER,
                    intercompany_transaction_type_AP    VARCHAR2,
                    invoice_number_AP                   VARCHAR2,
                    NETTING_AR_LE                       VARCHAR2,
                    NETTING_AR_LEDGER                   VARCHAR2,
                    AR_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AR_FUN_CURR                 VARCHAR2,
                    AP_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AP_FUN_CURR                 VARCHAR2,
                    intercompany_legal_entity_AP        VARCHAR2,
                    NETTING_AP_LE                       VARCHAR2,
                    NETTING_AP_LEDGER                   VARCHAR2,
                    AP_EXCHANGE_RATE_TYPE               VARCHAR2,
                    AR_EXCHANGE_RATE_TYPE               VARCHAR2,
                    RECORD_TYPE                         VARCHAR2,
                    IC_TRX_NUMBER                       VARCHAR2,
                    AP_INVOICE_ID                       NUMBER,
                    AR_INVOICE_ID                       NUMBER,
                     AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
                    ACCOUNTING_PERIOD                   VARCHAR2,
                    GL_IC_BATCH_NUMBER                     VARCHAR2);

Procedure LSI_SC6B1(P_BATCH_ID                          NUMBER,
                    AR_CCID                             VARCHAR2,
                    AR_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AR         VARCHAR2,
                    accounted_invoice_amount_AR         NUMBER,
                    intercompany_legal_entity_AR        VARCHAR2,
                    intercompany_transaction_type_AR    VARCHAR2,
                    invoice_number_AR                   VARCHAR2,
                    AP_CCID                             VARCHAR2,
                    AP_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AP         VARCHAR2,
                    accounted_invoice_amount_AP         NUMBER,
                    intercompany_transaction_type_AP    VARCHAR2,
                    invoice_number_AP                   VARCHAR2,
                    NETTING_AR_LE                       VARCHAR2,
                    NETTING_AR_LEDGER                   VARCHAR2,
                    AR_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AR_FUN_CURR                 VARCHAR2,
                    AP_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AP_FUN_CURR                 VARCHAR2,
                    intercompany_legal_entity_AP        VARCHAR2,
                    NETTING_AP_LE                       VARCHAR2,
                    NETTING_AP_LEDGER                   VARCHAR2,
                    AP_EXCHANGE_RATE_TYPE               VARCHAR2,
                    AR_EXCHANGE_RATE_TYPE               VARCHAR2,
                    RECORD_TYPE                         VARCHAR2,
                    IC_TRX_NUMBER                       VARCHAR2,
                    AP_INVOICE_ID                       NUMBER,
                    AR_INVOICE_ID                       NUMBER,
                     AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
                    ACCOUNTING_PERIOD                   VARCHAR2,
                    ICOM_BATCH_NUMBER                     VARCHAR2);      


Procedure LSI_SC6B2(P_BATCH_ID                          NUMBER,
                    AR_CCID                             VARCHAR2,
                    AR_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AR         VARCHAR2,
                    accounted_invoice_amount_AR         NUMBER,
                    intercompany_legal_entity_AR        VARCHAR2,
                    intercompany_transaction_type_AR    VARCHAR2,
                    invoice_number_AR                   VARCHAR2,
                    AP_CCID                             VARCHAR2,
                    AP_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AP         VARCHAR2,
                    accounted_invoice_amount_AP         NUMBER,
                    intercompany_transaction_type_AP    VARCHAR2,
                    invoice_number_AP                   VARCHAR2,
                    NETTING_AR_LE                       VARCHAR2,
                    NETTING_AR_LEDGER                   VARCHAR2,
                    AR_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AR_FUN_CURR                 VARCHAR2,
                    AP_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AP_FUN_CURR                 VARCHAR2,
                    intercompany_legal_entity_AP        VARCHAR2,
                    NETTING_AP_LE                       VARCHAR2,
                    NETTING_AP_LEDGER                   VARCHAR2,
                    AP_EXCHANGE_RATE_TYPE               VARCHAR2,
                    AR_EXCHANGE_RATE_TYPE               VARCHAR2,
                    RECORD_TYPE                         VARCHAR2,
                    IC_TRX_NUMBER                       VARCHAR2,
                    AP_INVOICE_ID                       NUMBER,
                    AR_INVOICE_ID                       NUMBER,
                     AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
                    ACCOUNTING_PERIOD                   VARCHAR2,
                    ICOM_BATCH_NUMBER                     VARCHAR2);  

  Procedure LSI_SC7A1(P_BATCH_ID                          NUMBER,
                    AR_CCID                             VARCHAR2,
                    AR_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AR         VARCHAR2,
                    accounted_invoice_amount_AR         NUMBER,
					INTERCOMPANY_BATCH_NUMBER_AP      VARCHAR2,
                    intercompany_legal_entity_AR        VARCHAR2,
                    intercompany_transaction_type_AR    VARCHAR2,
                    invoice_number_AR                   VARCHAR2,
                    AP_CCID                             VARCHAR2,
                    AP_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AP         VARCHAR2,
                    accounted_invoice_amount_AP         NUMBER,
                    intercompany_transaction_type_AP    VARCHAR2,
                    invoice_number_AP                   VARCHAR2,
                    NETTING_AR_LE                       VARCHAR2,
                    NETTING_AR_LEDGER                   VARCHAR2,
                    AR_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AR_FUN_CURR                 VARCHAR2,
                    AP_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AP_FUN_CURR                 VARCHAR2,
                    intercompany_legal_entity_AP        VARCHAR2,
                    NETTING_AP_LE                       VARCHAR2,
                    NETTING_AP_LEDGER                   VARCHAR2,
                    AP_EXCHANGE_RATE_TYPE               VARCHAR2,
                    AR_EXCHANGE_RATE_TYPE               VARCHAR2,
                    RECORD_TYPE                         VARCHAR2,
                    IC_TRX_NUMBER                       VARCHAR2,
                    AP_INVOICE_ID                       NUMBER,
                    AR_INVOICE_ID                       NUMBER,
                     AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
                    ACCOUNTING_PERIOD                  VARCHAR2);                  

 Procedure LSI_SC7A2(  P_BATCH_ID                          NUMBER,
                    AR_CCID                             VARCHAR2,
                    AR_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AR         VARCHAR2,
                    accounted_invoice_amount_AR         NUMBER,
					INTERCOMPANY_BATCH_NUMBER_AP      VARCHAR2,
                    intercompany_legal_entity_AR        VARCHAR2,
                    intercompany_transaction_type_AR    VARCHAR2,
                    invoice_number_AR                   VARCHAR2,
                    AP_CCID                             VARCHAR2,
                    AP_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AP         VARCHAR2,
                    accounted_invoice_amount_AP         NUMBER,
                    intercompany_transaction_type_AP    VARCHAR2,
                    invoice_number_AP                   VARCHAR2,
                    NETTING_AR_LE                       VARCHAR2,
                    NETTING_AR_LEDGER                   VARCHAR2,
                    AR_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AR_FUN_CURR                 VARCHAR2,
                    AP_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AP_FUN_CURR                 VARCHAR2,
                    intercompany_legal_entity_AP        VARCHAR2,
                    NETTING_AP_LE                       VARCHAR2,
                    NETTING_AP_LEDGER                   VARCHAR2,
                    AP_EXCHANGE_RATE_TYPE               VARCHAR2,
                    AR_EXCHANGE_RATE_TYPE               VARCHAR2,
                    RECORD_TYPE                         VARCHAR2,
                    IC_TRX_NUMBER                       VARCHAR2,
                    AP_INVOICE_ID                       NUMBER,
                    AR_INVOICE_ID                       NUMBER,
                     AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
                    ACCOUNTING_PERIOD                  VARCHAR2);


  Procedure LSI_SC7B1(  P_BATCH_ID                          NUMBER,
                    AR_CCID                             VARCHAR2,
                    AR_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AR         VARCHAR2,
                    accounted_invoice_amount_AR         NUMBER,
					INTERCOMPANY_BATCH_NUMBER_AP      VARCHAR2,
                    intercompany_legal_entity_AR        VARCHAR2,
                    intercompany_transaction_type_AR    VARCHAR2,
                    invoice_number_AR                   VARCHAR2,
                    AP_CCID                             VARCHAR2,
                    AP_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AP         VARCHAR2,
                    accounted_invoice_amount_AP         NUMBER,
                    intercompany_transaction_type_AP    VARCHAR2,
                    invoice_number_AP                   VARCHAR2,
                    NETTING_AR_LE                       VARCHAR2,
                    NETTING_AR_LEDGER                   VARCHAR2,
                    AR_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AR_FUN_CURR                 VARCHAR2,
                    AP_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AP_FUN_CURR                 VARCHAR2,
                    intercompany_legal_entity_AP        VARCHAR2,
                    NETTING_AP_LE                       VARCHAR2,
                    NETTING_AP_LEDGER                   VARCHAR2,
                    AP_EXCHANGE_RATE_TYPE               VARCHAR2,
                    AR_EXCHANGE_RATE_TYPE               VARCHAR2,
                    RECORD_TYPE                         VARCHAR2,
                    IC_TRX_NUMBER                       VARCHAR2,
                    AP_INVOICE_ID                       NUMBER,
                    AR_INVOICE_ID                       NUMBER,
                     AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
                    ACCOUNTING_PERIOD                  VARCHAR2); 

Procedure LSI_SC7B2( P_BATCH_ID                          NUMBER,
                    AR_CCID                             VARCHAR2,
                    AR_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AR         VARCHAR2,
                    accounted_invoice_amount_AR         NUMBER,
					INTERCOMPANY_BATCH_NUMBER_AP      VARCHAR2,
                    intercompany_legal_entity_AR        VARCHAR2,
                    intercompany_transaction_type_AR    VARCHAR2,
                    invoice_number_AR                   VARCHAR2,
                    AP_CCID                             VARCHAR2,
                    AP_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AP         VARCHAR2,
                    accounted_invoice_amount_AP         NUMBER,
                    intercompany_transaction_type_AP    VARCHAR2,
                    invoice_number_AP                   VARCHAR2,
                    NETTING_AR_LE                       VARCHAR2,
                    NETTING_AR_LEDGER                   VARCHAR2,
                    AR_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AR_FUN_CURR                 VARCHAR2,
                    AP_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AP_FUN_CURR                 VARCHAR2,
                    intercompany_legal_entity_AP        VARCHAR2,
                    NETTING_AP_LE                       VARCHAR2,
                    NETTING_AP_LEDGER                   VARCHAR2,
                    AP_EXCHANGE_RATE_TYPE               VARCHAR2,
                    AR_EXCHANGE_RATE_TYPE               VARCHAR2,
                    RECORD_TYPE                         VARCHAR2,
                    IC_TRX_NUMBER                       VARCHAR2,
                    AP_INVOICE_ID                       NUMBER,
                    AR_INVOICE_ID                       NUMBER,
                     AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
                    ACCOUNTING_PERIOD                  VARCHAR2
					);                      


 Procedure LSI_SC8( P_BATCH_ID                          NUMBER,
                    AR_CCID                             VARCHAR2,
                    AR_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AR         VARCHAR2,
                    accounted_invoice_amount_AR         NUMBER,
					INTERCOMPANY_BATCH_NUMBER_AP      VARCHAR2,
                    intercompany_legal_entity_AR        VARCHAR2,
                    intercompany_transaction_type_AR    VARCHAR2,
                    invoice_number_AR                   VARCHAR2,
                    AP_CCID                             VARCHAR2,
                    AP_LEDGER                           VARCHAR2,
                    functional_Currency_Code_AP         VARCHAR2,
                    accounted_invoice_amount_AP         NUMBER,
                    intercompany_transaction_type_AP    VARCHAR2,
                    invoice_number_AP                   VARCHAR2,
                    NETTING_AR_LE                       VARCHAR2,
                    NETTING_AR_LEDGER                   VARCHAR2,
                    AR_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AR_FUN_CURR                 VARCHAR2,
                    AP_EXCHANGE_RATE_NETTING            VARCHAR2,
                    NETTING_AP_FUN_CURR                 VARCHAR2,
                    intercompany_legal_entity_AP        VARCHAR2,
                    NETTING_AP_LE                       VARCHAR2,
                    NETTING_AP_LEDGER                   VARCHAR2,
                    AP_EXCHANGE_RATE_TYPE               VARCHAR2,
                    AR_EXCHANGE_RATE_TYPE               VARCHAR2,
                    RECORD_TYPE                         VARCHAR2,
                    IC_TRX_NUMBER                       VARCHAR2,
                    AP_INVOICE_ID                       NUMBER,
                    AR_INVOICE_ID                       NUMBER,
                     AP_ID2 NUMBER,
                    AR_ID2 NUMBER,
                    AP_ID3 NUMBER,
                    AR_ID3 NUMBER,
                    ACCOUNTING_PERIOD                  VARCHAR2);               


    PROCEDURE WSC_LSI_EXCHAGE_RATE_P
    (
      IN_WSC_EXCHANGE_RATE IN WSC_AHCS_LSI_EXCHANGE_RATE_T_TYPE_TABLE
    );

    PROCEDURE WSC_LSI_APAR_P
    (
      IN_WSC_APAR_HEADER IN WSC_LSI_APAR_T_TYPE_TABLE
    );

     FUNCTION WSC_LSI_APAR_BATCH_P RETURN  NUMBER;

     PROCEDURE WSC_ASYNC_LSI_MATCH_PROCESS_P
    (
        RECORD_TYPE     VARCHAR2,
        ERRMSG    OUT      VARCHAR2,
        ERRCODE    OUT     VARCHAR2,
        FILENAME           VARCHAR2
    );

      PROCEDURE WSC_ASYNC_LSI_FBDI_PROCESS_P
    (
        P_BATCH_ID NUMBER
    );

     PROCEDURE WSC_LSI_CALL_PAYMENT_RECEIPT_P
    (
        P_BATCH_ID NUMBER,
        P_FILE_NAME VARCHAR2
    );

    PROCEDURE WSC_LSI_JOURNALS_P
    (
    IN_WSC_LSI_JOURNAL_DATA IN WES_AHCS_LSI_JOURNAL_T_TYPE_TABLE
    ); 

    PROCEDURE WSC_LSI_APAR_MATCH_P(P_FILE_NAME VARCHAR2);

    PROCEDURE WSC_LSI_JOURNALS_MATCH_P(P_FILE_NAME VARCHAR2);

    PROCEDURE WSC_LSI_RECEIPT_FBDI_P(P_BATCH_ID NUMBER);

    PROCEDURE WSC_LSI_NETTING_P(RECORD_TYPE VARCHAR2,P_BATCH_ID NUMBER);

    procedure WSC_LSI_ASYNC_NETTING_P(RECORD_TYPE VARCHAR2,P_BATCH_ID NUMBER,FILENAME in varchar2, Errorbuf OUT Varchar2,Rectcode OUT Varchar2);

    PROCEDURE WSC_LSI_DB_TO_UCM_PROCESS_P(P_BATCH_ID NUMBER);

    PROCEDURE WSC_LSI_RECEIPT_CREATED(WSC_REP_CRE WSC_LSI_RECEIPT_CREATED_T_TYPE_TABLE);

    PROCEDURE WSC_LSI_RECEIPT_SYNC_DB(P_REQUEST_ID NUMBER,P_LOAD_REQ_ID NUMBER);

    PROCEDURE WSC_LSI_UPDATE_PROCESS_FLAG(P_BATCH_ID VARCHAR2,P_LEDGER_GRP_NUM VARCHAR2);

   PROCEDURE wsc_ahcs_lsi_kickoff(
		P_RECORD_TYPE VARCHAR2,
		P_FROM_DATE VARCHAR2,
		P_TO_DATE VARCHAR2
	); 

    Procedure wsc_ahcs_lsi_import_failed(P_BATCH_ID NUMBER, IMP_ACC_ID NUMBER);

     Procedure wsc_ahcs_lsi_reprocess_p(P_BATCH_ID NUMBER,P_ACC_DATE TIMESTAMP);

     procedure WSC_AHCS_ASYNC_LSI_REPROCESS_GL_P(P_BATCH_ID NUMBER,P_ACC_DATE TIMESTAMP);

       Procedure wsc_ahcs_lsi_reprocess_gl_p(P_BATCH_ID NUMBER,P_ACC_DATE TIMESTAMP);

       Procedure wsc_ahcs_lsi_reprocess_cm_p(P_BATCH_ID NUMBER,P_ACC_DATE TIMESTAMP);

     PROCEDURE wsc_ahcs_lsi_credit_memo_invoices(P_ACC_DATE TIMESTAMP, P_FILE_NAME VARCHAR2);

     PROCEDURE wsc_ahcs_lsi_process_after_invoice_callback(P_REQ_ID NUMBER,P_SUBMIT_ID NUMBER);

     PROCEDURE wsc_ahcs_lsi_dump_status2credit_memo_t_p(cm_inv_status_dump wsc_lsi_credit_memo_invoice_type_table); 

    PROCEDURE wsc_ahcs_lsin_grp_id_upd_p ( in_grp_id IN NUMBER ) ;

     PROCEDURE wsc_ahcs_lsi_ctrl_line_tbl_led_num_upd (
        p_group_id       IN VARCHAR2,
        p_ledger_grp_num IN VARCHAR2
    );
     PROCEDURE wsc_ahcs_lsi_ctrl_line_ucm_id_upd (
        p_ucmdoc_id      IN VARCHAR2,
        p_group_id       IN VARCHAR2,
        p_ledger_grp_num IN VARCHAR2
    );

    PROCEDURE wsc_ahcs_lsi_dump_cm_validate_t_p(cm_val_status_dump wsc_ahcs_lsi_cm_val_t_TYPE_TABLE);

    PROCEDURE wsc_ahcs_lsi_update_imp_status(p_group_id number);

END WSC_LSI_PKG;
/
