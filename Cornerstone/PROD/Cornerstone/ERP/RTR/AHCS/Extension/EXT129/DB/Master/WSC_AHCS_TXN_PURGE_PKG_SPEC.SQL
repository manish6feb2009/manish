create or replace PACKAGE WSC_AHCS_TXN_PURGE_PKG AS

    PROCEDURE delete_data_system (
        P_BATCH_ID NUMBER
    );

--FUNCTION purge_eligible_check (
--        p_application         VARCHAR2,
--        p_ledger              VARCHAR2,
--        p_transaction_number  VARCHAR2,
--        p_transaction_date    DATE
--    ) RETURN NUMBER ;
END;
/