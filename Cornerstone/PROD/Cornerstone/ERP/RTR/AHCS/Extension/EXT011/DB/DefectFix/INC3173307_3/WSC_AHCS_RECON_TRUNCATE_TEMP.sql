
BEGIN
    EXECUTE IMMEDIATE 'Truncate table WSC_AHCS_RECON_REP_TEMP_T';
EXCEPTION
    WHEN OTHERS
    THEN
        DBMS_OUTPUT.put_line (
            'Error!: ' || SQLERRM || DBMS_UTILITY.format_error_backtrace);
END;
/