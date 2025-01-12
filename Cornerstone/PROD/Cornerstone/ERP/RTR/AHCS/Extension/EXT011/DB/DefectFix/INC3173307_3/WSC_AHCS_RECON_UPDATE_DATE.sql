BEGIN
    UPDATE WSC_AHCS_REFRESH_T
       SET LAST_REFRESH_DATE =
               TO_DATE ('05-01-2024 18:34:56', 'DD-MM-RRRR HH24:MI:SS')
     WHERE DATA_ENTITY_NAME = 'WSC_AHCS_RECON_REPORT';

    DBMS_OUTPUT.put_line ('Updated Rows: ' || SQL%ROWCOUNT);
    COMMIT;
    DBMS_OUTPUT.put_line ('COMMIT completed');
EXCEPTION
    WHEN OTHERS
    THEN
        DBMS_OUTPUT.put_line (
               'ERROR: '
            || SUBSTR (SQLERRM, 1, 500)
            || DBMS_UTILITY.format_error_backtrace);
END;