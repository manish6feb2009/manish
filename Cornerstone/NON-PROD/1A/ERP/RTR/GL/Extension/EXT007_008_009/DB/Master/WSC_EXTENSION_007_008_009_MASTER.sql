SET ECHO ON;
SET DEFINE OFF;


PROMPT "EXECUTING WSC_EXTENSION_007_008_009_SEQUENCE.sql";
@WSC_EXTENSION_007_008_009_SEQUENCE.sql

PROMPT "EXECUTING WSC_EXTENSION_007_008_009_TABLE.sql";
@WSC_EXTENSION_007_008_009_TABLE.sql;

PROMPT "EXECUTING WSC_EXTENSION_007_008_009_TRIGGER.sql";
@WSC_EXTENSION_007_008_009_TRIGGER.sql

PROMPT "EXECUTING WSC_DISABLED_COA_HANDLE_PKG.sql";
@WSC_DISABLED_COA_HANDLE_PKG.sql

PROMPT "EXECUTING WSC_DISABLED_COA_HANDLE_PKG_BODY.sql";
@WSC_DISABLED_COA_HANDLE_PKG_BODY.sql

COMMIT;