create or replace PROCEDURE WSC_AHCS_GET_GROUP_ID_P(
    out_group_id OUT NUMBER
) AS
    group_seq NUMBER;
BEGIN
    SELECT
        WSC_AHCS_MF_GRP_ID_SEQ.NEXTVAL
    INTO group_seq
    FROM
        dual;

    out_group_id := group_seq;
END WSC_AHCS_GET_GROUP_ID_P;
/