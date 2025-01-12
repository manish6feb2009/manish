SET ECHO ON;
SET DEFINE OFF;

PROMPT "EXECUTING INC3452584_Master.sql for INC3452584";

@Create_Backup_Table.sql;
COMMIT;
@Update_Control_Status_Table.sql;
COMMIT;