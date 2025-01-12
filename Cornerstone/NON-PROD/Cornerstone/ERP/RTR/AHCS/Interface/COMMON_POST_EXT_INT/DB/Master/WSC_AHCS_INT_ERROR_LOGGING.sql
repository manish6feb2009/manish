create or replace Package  "WSC_AHCS_INT_ERROR_LOGGING" AS
    
Procedure "ERROR_LOGGING"(BATCH_ID   VARCHAR2,
                        RICE_ID     VARCHAR2,
                        P_APPLICATION VARCHAR2,
                        ERROR_MSG VARCHAR2);

END;
/
