CREATE OR REPLACE PACKAGE FININT.WSC_AHCS_TXN_PURGE_PKG AS

    PROCEDURE delete_data_system (
        P_BATCH_ID NUMBER
    );

/* added for OC-205 Purge for LSI source */
PROCEDURE delete_data_lsi (p_batch_id NUMBER)
;

END;
/