create or replace PACKAGE wsc_ahcs_coa_sync_pkg AS
    PROCEDURE wsc_ahcs_coa_sync_start (
        p_batch_id NUMBER,
        p_reset_date date
    );

END;
/