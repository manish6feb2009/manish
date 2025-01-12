SET ECHO ON;
SET DEFINE OFF;

PROMPT "EXECUTING OC-277_Master.sql for OC-277";

---@Create_Backup_Table.sql;
---COMMIT;
---@Update_coa_mapping_rules_Table.sql;
---COMMIT;
@Insert_coa_mapping_rules_Table.sql
COMMIT;