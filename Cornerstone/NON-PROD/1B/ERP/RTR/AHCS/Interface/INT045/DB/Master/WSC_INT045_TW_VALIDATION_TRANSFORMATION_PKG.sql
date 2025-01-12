CREATE OR REPLACE PACKAGE wsc_ahcs_tw_validation_transformation_pkg AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */

    PROCEDURE data_validation (
        p_batch_id IN NUMBER
    );

    PROCEDURE leg_coa_transformation (
        p_batch_id IN NUMBER
    );

    PROCEDURE leg_coa_transformation_reprocessing (
        p_batch_id IN NUMBER
    );

    FUNCTION is_date_null (
        p_string IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION is_long_null (
        p_string IN LONG
    ) RETURN NUMBER;

    FUNCTION is_number_null (
        p_string IN NUMBER
    ) RETURN NUMBER;

    FUNCTION is_varchar2_null (
        p_string IN VARCHAR2
    ) RETURN NUMBER;

END wsc_ahcs_tw_validation_transformation_pkg;
/