

set define off;

-----------------------------------------------------------------------------------
--Disable Trigger
-----------------------------------------------------------------------------------

alter trigger WSC_COA_CCID_BIR disable;

-----------------------------------------------------------------------------------
--Anixter to cloud, insert wsc_gl_ccid_mapping_t
-----------------------------------------------------------------------------------

insert into wsc_gl_ccid_mapping_t (
  COA_MAP_ID, 
  ENABLE_FLAG, 
  SOURCE_SEGMENT, 
  TARGET_SEGMENT, 
  CREATION_DATE, 
  LAST_UPDATE_DATE, 
  COA_MAP_NAME, 
  CCID_VALUE_ID, 
  UI_FLAG, 
  SOURCE_SEGMENT1, 
  SOURCE_SEGMENT2, 
  SOURCE_SEGMENT3, 
  SOURCE_SEGMENT4, 
  SOURCE_SEGMENT5, 
  SOURCE_SEGMENT6, 
  SOURCE_SEGMENT7, 
  SOURCE_SEGMENT8, 
  created_by,
  last_updated_by,
  version
) 
select 
  COA_MAP_ID, 
  ENABLE_FLAG, 
  SOURCE_SEGMENT, 
  TARGET_SEGMENT, 
  CREATION_DATE, 
  LAST_UPDATE_DATE, 
  COA_MAP_NAME, 
  wsc_gl_ccid_mapping_s.nextval CCID_VALUE_ID, 
  UI_FLAG, 
  SOURCE_SEGMENT1, 
  SOURCE_SEGMENT2, 
  SOURCE_SEGMENT3, 
  SOURCE_SEGMENT4, 
  SOURCE_SEGMENT5, 
  SOURCE_SEGMENT6, 
  SOURCE_SEGMENT7, 
  SOURCE_SEGMENT8, 
  'FIN_INT',
  'FIN_INT',
  1
from 
  (
    select distinct
      5 COA_MAP_ID, 
      'Y' ENABLE_FLAG, 
      SOURCE_SEGMENT1 || '.' || SOURCE_SEGMENT2 || '.' || SOURCE_SEGMENT3 || '.' || SOURCE_SEGMENT4 || '.' || SOURCE_SEGMENT5 || '.' || nvl(SOURCE_SEGMENT6,'00000') SOURCE_SEGMENT, 
      TARGET_COA TARGET_SEGMENT, 
      sysdate CREATION_DATE, 
      sysdate LAST_UPDATE_DATE, 
      'Anixter to Cloud' COA_MAP_NAME, 
      'N' UI_FLAG, 
      SOURCE_SEGMENT1, 
      SOURCE_SEGMENT2, 
      SOURCE_SEGMENT3, 
      SOURCE_SEGMENT4, 
      SOURCE_SEGMENT5, 
      nvl(SOURCE_SEGMENT6,'00000') SOURCE_SEGMENT6, 
      SOURCE_SEGMENT7, 
      SOURCE_SEGMENT8 
    from 
      WSC_AHCS_COA_CONCAT_SEGMENT 
    where 
	  wsc_seq_num is null
	  and
      substr(
        target_coa, 
        1, 
        instr(target_coa, '.', 1, 1)-1
      ) is not null 
      and coa_name = 'Anixter to Cloud'
  );
commit;

-----------------------------------------------------------------------------------
--Enable Trigger
-----------------------------------------------------------------------------------

alter trigger WSC_COA_CCID_BIR enable;