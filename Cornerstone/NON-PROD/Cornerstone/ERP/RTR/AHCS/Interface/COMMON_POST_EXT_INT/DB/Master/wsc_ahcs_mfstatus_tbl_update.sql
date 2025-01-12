create or replace PACKAGE wsc_ahcs_mfstatus_tbl_update AS
    PROCEDURE wsc_ahcs_mfstatus_tbl_impacc_update (
        p_import_acc_id          IN  VARCHAR2,
        p_group_id               IN  VARCHAR2,
        p_ledger_grp_num         IN  VARCHAR2,
        p_source_system          IN  VARCHAR2,
        p_imp_accounting_status  IN  VARCHAR2
    );

    PROCEDURE wsc_ahcs_mfstatus_tbl_creacc_update (
        p_create_acc_id   IN  VARCHAR2,
        p_group_id        IN  VARCHAR2,
        p_ledger_grp_num  IN  VARCHAR2,
        p_source_system   IN  VARCHAR2
    );

    PROCEDURE wsc_ahcs_status_tbl_update (
        p_ledger_grp_num         IN  VARCHAR2,
        p_source_system          IN  VARCHAR2,
        p_imp_accounting_status  IN  VARCHAR2,
        p_group_id               IN VARCHAR2
    );

END wsc_ahcs_mfstatus_tbl_update;
/