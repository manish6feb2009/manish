SET ECHO ON;


PROMPT "EXECUTING WSC_INT122_TABLE.sql";
@WSC_INT122_TABLE.sql;

PROMPT "EXECUTING WSC_INT122_INDEXES.sql";
@WSC_INT122_INDEXES.sql

PROMPT "EXECUTING WSC_INT122_SEQUENCE.sql";
@WSC_INT122_SEQUENCE.sql

PROMPT "EXECUTING WSC_INT122_TABLE_TYPES.sql";
@WSC_INT122_TABLE_TYPES.sql;

PROMPT "EXECUTING WSC_INT122_PKG.sql";
@WSC_INT122_PKG.sql

PROMPT "EXECUTING WSC_INT122_PKG_BODY.sql";
@WSC_INT122_PKG_BODY.sql

PROMPT "EXECUTING WSC_AHCS_INT122_VALIDATION_TRANSFORMATION_PKG.sql";
@WSC_INT122_VALIDATION_TRANSFORMATION_PKG.sql

PROMPT "EXECUTING WSC_AHCS_INT122_VALIDATION_TRANSFORMATION_PKG_BODY.sql";
@WSC_INT122_VALIDATION_TRANSFORMATION_PKG_BODY.sql

COMMIT;
