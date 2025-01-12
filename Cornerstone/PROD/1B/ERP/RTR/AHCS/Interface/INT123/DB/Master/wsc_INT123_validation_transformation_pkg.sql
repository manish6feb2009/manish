create or replace PACKAGE WSC_AHCS_SXE_VALIDATION_TRANSFORMATION_PKG AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */ 

   PROCEDURE data_validation(p_batch_id IN number);
   PROCEDURE leg_coa_transformation(p_batch_id IN number);
   PROCEDURE leg_coa_transformation_reprocessing(p_batch_id IN number);
 --- FUNCTION  IS_DATE_NULL(p_string IN varchar2) RETURN NUMBER;
  FUNCTION  IS_LONG_NULL(p_string IN long) RETURN NUMBER;
  FUNCTION  IS_NUMBER_NULL(p_string IN number) RETURN NUMBER;
  FUNCTION  IS_VARCHAR2_NULL(p_string IN varchar2) RETURN NUMBER;

END WSC_AHCS_SXE_VALIDATION_TRANSFORMATION_PKG;
/