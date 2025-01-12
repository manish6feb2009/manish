SET ECHO ON;
SET DEFINE OFF;

PROMPT "EXECUTING WSC_CENTRAL_033_OC159.sql";
@OC-159_create_bkp_table.sql;
@OC-159_Update.sql;
@OC-159_Insert.sql;
COMMIT;

