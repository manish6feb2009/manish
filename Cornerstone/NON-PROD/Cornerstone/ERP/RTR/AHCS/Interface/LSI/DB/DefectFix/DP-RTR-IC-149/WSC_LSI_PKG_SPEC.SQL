create or replace PACKAGE wsc_lsi_pkg AS 
 ------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PACKAGE             WSC_LSI_PKG AS
------------------------------------------------------------------------------------------
-- COPYRIGHT (C) Wesco Inc.
--
-- Protected as an unpublished work.  All Rights Reserved.
--
-- The computer program listings, specifications, and documentation herein
-- are the property of Wesco Incorporated and shall not be
-- reproduced, copied, disclosed, or used in whole or in part for any
-- reason without the express written permission of Wesco Incorporated.
--
-- DESCRIPTION:
-- This package contains supporting procedures required for LSI Process sources data from Oracle SaaS ERP and
-- destined for AHCS.
-- 
--
-- FILE LOCATION AND VERSION
-- $Header: WSC_LSI_PKG.pkg
--
-- MODIFICATION HISTORY :
--
-- Name                              Date      Ver   Description
-- =================              ===========  ===   ====================================
-- Manish Kumar/Deloitte Consulting  MAY-22     1.0   Created
-- Manish Kumar/Deloitte Consulting  OCT-22     1.0   Tech Details for CM solution
-- Manish Kumar/Deloitte Consulting  Jul-23     1.0   User Story DP-RTR-IC-159 + Concurrency Fix 
-- Manish Kumar/Deloitte Consulting  Aug-23     1.0   User Story DP-RTR-IC-149
----------------------------------------------------------------------------------------

    PROCEDURE wsc_lsi_lookup_p (
        in_wsc_lookup IN wsc_ahcs_lsi_lookup_t_type_table
    );

    PROCEDURE wsc_ahcs_lsi_kickoff_reprocess (
        p_batch_id  NUMBER,
        lv_acc_date DATE
    );

    PROCEDURE lsi_error_report_download (
        o_clobdata OUT CLOB
    );

    PROCEDURE wsc_lsi_ar_ap_download (
        o_clobdata OUT CLOB
    );

    PROCEDURE wsc_lsi_ar_ap_cm_err (
        o_clobdata OUT CLOB
    );

    FUNCTION getnettingle (
        le        VARCHAR2,
        ap_ledger VARCHAR2,
        ar_ledger VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION getnettingnettingle (
        le VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION isprioritybu (
        le VARCHAR2
    ) RETURN NUMBER;

    FUNCTION getnettingledger (
        le VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION getnettingfuncurr (
        le VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION isnettinglefinal (
        le        VARCHAR2,
        nett_le   VARCHAR2,
        ap_ledger VARCHAR2,
        ar_ledger VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION getemea (
        ledger VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION isfinalbu (
        lepr_le   VARCHAR2,
        rcv_le    VARCHAR2,
        ap_ledger VARCHAR2,
        ar_ledger VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE lsi_sc1 (
        p_batch_id                       NUMBER,
        ar_ccid                          VARCHAR2,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      NUMBER,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ar                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      NUMBER,
        intercompany_transaction_type_ap VARCHAR2,
        invoice_number_ap                VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2,
        intercompany_batch_number_ap     VARCHAR2
    );

    PROCEDURE lsi_sc2 (
        ar_ccid                          VARCHAR2,
        p_batch_id                       NUMBER,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      NUMBER,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ap                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      NUMBER,
        intercompany_transaction_type_ap VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2,
        intercompany_batch_number_ap     VARCHAR2
    );

    PROCEDURE lsi_sc3 (
        ar_ccid                          VARCHAR2,
        p_batch_id                       NUMBER,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      NUMBER,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ap                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      NUMBER,
        intercompany_transaction_type_ap VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2,
        intercompany_batch_number_ap     VARCHAR2
    );

    PROCEDURE lsi_sc4_1 (
        ar_ccid                          VARCHAR2,
        p_batch_id                       VARCHAR2,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      VARCHAR2,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ap                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      NUMBER,
        intercompany_transaction_type_ap VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        entered_invoice_amount_ap        NUMBER,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2,
        intercompany_batch_number_ap     VARCHAR2
    );

    PROCEDURE lsi_sc4_2 (
        ar_ccid                          VARCHAR2,
        p_batch_id                       VARCHAR2,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      NUMBER,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ap                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      NUMBER,
        intercompany_transaction_type_ap VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2,
        intercompany_batch_number_ap     VARCHAR2
    );

    PROCEDURE lsi_sc5_1 (
        p_batch_id                       NUMBER,
        ar_ccid                          VARCHAR2,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      NUMBER,
        intercompany_batch_number_ap     VARCHAR2,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ap                VARCHAR2,
        invoice_number_ar                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      VARCHAR2,
        intercompany_transaction_type_ap VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2
    );

    PROCEDURE lsi_sc5_2 (
        p_batch_id                       NUMBER,
        ar_ccid                          VARCHAR2,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      NUMBER,
        intercompany_batch_number_ap     VARCHAR2,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ap                VARCHAR2,
        invoice_number_ar                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      NUMBER,
        intercompany_transaction_type_ap VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2
    );

    PROCEDURE lsi_sc6a1 (
        p_batch_id                       NUMBER,
        ar_ccid                          VARCHAR2,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      NUMBER,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ar                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      NUMBER,
        intercompany_transaction_type_ap VARCHAR2,
        invoice_number_ap                VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2,
        icom_batch_number                VARCHAR2
    );

    PROCEDURE lsi_sc6a2 (
        p_batch_id                       NUMBER,
        ar_ccid                          VARCHAR2,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      NUMBER,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ar                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      NUMBER,
        intercompany_transaction_type_ap VARCHAR2,
        invoice_number_ap                VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2,
        gl_ic_batch_number               VARCHAR2
    );

    PROCEDURE lsi_sc6b1 (
        p_batch_id                       NUMBER,
        ar_ccid                          VARCHAR2,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      NUMBER,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ar                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      NUMBER,
        intercompany_transaction_type_ap VARCHAR2,
        invoice_number_ap                VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2,
        icom_batch_number                VARCHAR2
    );

    PROCEDURE lsi_sc6b2 (
        p_batch_id                       NUMBER,
        ar_ccid                          VARCHAR2,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      NUMBER,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ar                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      NUMBER,
        intercompany_transaction_type_ap VARCHAR2,
        invoice_number_ap                VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2,
        icom_batch_number                VARCHAR2
    );

    PROCEDURE lsi_sc7a1 (
        p_batch_id                       NUMBER,
        ar_ccid                          VARCHAR2,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      NUMBER,
        intercompany_batch_number_ap     VARCHAR2,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ar                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      NUMBER,
        intercompany_transaction_type_ap VARCHAR2,
        invoice_number_ap                VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2
    );

    PROCEDURE lsi_sc7a2 (
        p_batch_id                       NUMBER,
        ar_ccid                          VARCHAR2,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      NUMBER,
        intercompany_batch_number_ap     VARCHAR2,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ar                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      NUMBER,
        intercompany_transaction_type_ap VARCHAR2,
        invoice_number_ap                VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2
    );

    PROCEDURE lsi_sc7b1 (
        p_batch_id                       NUMBER,
        ar_ccid                          VARCHAR2,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      NUMBER,
        intercompany_batch_number_ap     VARCHAR2,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ar                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      NUMBER,
        intercompany_transaction_type_ap VARCHAR2,
        invoice_number_ap                VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2
    );

    PROCEDURE lsi_sc7b2 (
        p_batch_id                       NUMBER,
        ar_ccid                          VARCHAR2,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      NUMBER,
        intercompany_batch_number_ap     VARCHAR2,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ar                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      NUMBER,
        intercompany_transaction_type_ap VARCHAR2,
        invoice_number_ap                VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2
    );

    PROCEDURE lsi_sc8 (
        p_batch_id                       NUMBER,
        ar_ccid                          VARCHAR2,
        ar_ledger                        VARCHAR2,
        functional_currency_code_ar      VARCHAR2,
        accounted_invoice_amount_ar      NUMBER,
        intercompany_batch_number_ap     VARCHAR2,
        intercompany_legal_entity_ar     VARCHAR2,
        intercompany_transaction_type_ar VARCHAR2,
        invoice_number_ar                VARCHAR2,
        ap_ccid                          VARCHAR2,
        ap_ledger                        VARCHAR2,
        functional_currency_code_ap      VARCHAR2,
        accounted_invoice_amount_ap      NUMBER,
        intercompany_transaction_type_ap VARCHAR2,
        invoice_number_ap                VARCHAR2,
        netting_ar_le                    VARCHAR2,
        netting_ar_ledger                VARCHAR2,
        ar_exchange_rate_netting         VARCHAR2,
        netting_ar_fun_curr              VARCHAR2,
        ap_exchange_rate_netting         VARCHAR2,
        netting_ap_fun_curr              VARCHAR2,
        intercompany_legal_entity_ap     VARCHAR2,
        netting_ap_le                    VARCHAR2,
        netting_ap_ledger                VARCHAR2,
        ap_exchange_rate_type            VARCHAR2,
        ar_exchange_rate_type            VARCHAR2,
        record_type                      VARCHAR2,
        ic_trx_number                    VARCHAR2,
        ap_invoice_id                    NUMBER,
        ar_invoice_id                    NUMBER,
        ap_id2                           NUMBER,
        ar_id2                           NUMBER,
        ap_id3                           NUMBER,
        ar_id3                           NUMBER,
        accounting_period                VARCHAR2
    );

    PROCEDURE wsc_lsi_exchage_rate_p (
        in_wsc_exchange_rate IN wsc_ahcs_lsi_exchange_rate_t_type_table
    );

    PROCEDURE wsc_lsi_apar_p (
        in_wsc_apar_header IN wsc_lsi_apar_t_type_table
    );

    FUNCTION wsc_lsi_apar_batch_p RETURN NUMBER;

    PROCEDURE wsc_async_lsi_match_process_p (
        record_type VARCHAR2,
        errmsg      OUT VARCHAR2,
        errcode     OUT VARCHAR2,
        filename    VARCHAR2
    );

    PROCEDURE wsc_async_lsi_fbdi_process_p (
        p_batch_id NUMBER
    );

    PROCEDURE wsc_lsi_call_payment_receipt_p (
        p_batch_id  NUMBER,
        p_file_name VARCHAR2
    );

    PROCEDURE wsc_lsi_journals_p (
        in_wsc_lsi_journal_data IN wes_ahcs_lsi_journal_t_type_table
    );

    PROCEDURE wsc_lsi_apar_match_p (
        p_file_name VARCHAR2
    );

    PROCEDURE wsc_lsi_journals_match_p (
        p_file_name VARCHAR2
    );

    PROCEDURE wsc_lsi_receipt_fbdi_p (
        p_batch_id NUMBER
    );

    PROCEDURE wsc_lsi_netting_p (
        record_type VARCHAR2,
        p_batch_id  NUMBER
    );

    PROCEDURE wsc_lsi_async_netting_p (
        record_type VARCHAR2,
        p_batch_id  NUMBER,
        filename    IN VARCHAR2,
        errorbuf    OUT VARCHAR2,
        rectcode    OUT VARCHAR2
    );

    PROCEDURE wsc_lsi_db_to_ucm_process_p (
        p_batch_id NUMBER
    );

    PROCEDURE wsc_lsi_receipt_created (
        wsc_rep_cre wsc_lsi_receipt_created_t_type_table
    );

    PROCEDURE wsc_lsi_receipt_sync_db (
        p_request_id  NUMBER,
        p_load_req_id NUMBER
    );

    PROCEDURE wsc_lsi_update_process_flag (
        p_batch_id       VARCHAR2,
        p_ledger_grp_num VARCHAR2
    );

    PROCEDURE wsc_ahcs_lsi_kickoff (
        p_record_type VARCHAR2,
        p_from_date   VARCHAR2,
        p_to_date     VARCHAR2
    );

    PROCEDURE wsc_ahcs_lsi_import_failed (
        p_batch_id NUMBER,
        imp_acc_id NUMBER
    );

    PROCEDURE wsc_ahcs_lsi_reprocess_p (
        p_batch_id NUMBER,
        p_acc_date TIMESTAMP
    );

    PROCEDURE wsc_ahcs_async_lsi_reprocess_gl_p (
        p_batch_id NUMBER,
        p_acc_date TIMESTAMP
    );

    PROCEDURE wsc_ahcs_lsi_reprocess_gl_p (
        p_batch_id NUMBER,
        p_acc_date TIMESTAMP
    );

    PROCEDURE wsc_ahcs_lsi_reprocess_cm_p (
        p_batch_id NUMBER,
        p_acc_date TIMESTAMP
    );

    PROCEDURE wsc_ahcs_lsi_credit_memo_invoices (
        p_acc_date  TIMESTAMP,
        p_file_name VARCHAR2
    );

    PROCEDURE wsc_ahcs_lsi_process_after_invoice_callback (
        p_req_id    NUMBER,
        p_submit_id NUMBER
    );

    PROCEDURE wsc_ahcs_lsi_dump_status2credit_memo_t_p (
        cm_inv_status_dump wsc_lsi_credit_memo_invoice_type_table
    );

    PROCEDURE wsc_ahcs_lsin_grp_id_upd_p (
        in_grp_id IN NUMBER
    );

    PROCEDURE wsc_ahcs_lsi_ctrl_line_tbl_led_num_upd (
        p_group_id       IN VARCHAR2,
        p_ledger_grp_num IN VARCHAR2
    );

    PROCEDURE wsc_ahcs_lsi_ctrl_line_ucm_id_upd (
        p_ucmdoc_id      IN VARCHAR2,
        p_group_id       IN VARCHAR2,
        p_ledger_grp_num IN VARCHAR2
    );

    PROCEDURE wsc_ahcs_lsi_dump_cm_validate_t_p (
        cm_val_status_dump wsc_ahcs_lsi_cm_val_t_type_table
    );

    PROCEDURE wsc_ahcs_lsi_update_imp_status (
        p_group_id NUMBER
    );

END WSC_LSI_PKG;
/