/*==============================================*/
    /*PROCEDURE WSC_AHCS_BATCH_P*/
/*==============================================*/

create or replace PROCEDURE wsc_ahcs_batch_p (
    out_batch_id OUT NUMBER
) AS
    batch_seq NUMBER;
BEGIN
    SELECT
        WSC_AHCS_BATCH_SEQ.NEXTVAL
    INTO batch_seq
    FROM
        dual;

    out_batch_id := batch_seq;
END wsc_ahcs_batch_p;
/