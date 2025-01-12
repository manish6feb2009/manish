CREATE OR REPLACE PACKAGE DGTL_PLS.WSC_DGTL_PLS_PURGING_PKG
AS
    PROCEDURE delete_old_data (p_retention_period IN NUMBER);


    PROCEDURE purge_records_async (p_retention_period   IN NUMBER);
END WSC_DGTL_PLS_PURGING_PKG;
/