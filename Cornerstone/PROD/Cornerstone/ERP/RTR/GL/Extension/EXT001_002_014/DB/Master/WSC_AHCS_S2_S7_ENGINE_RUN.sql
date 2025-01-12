------------------------------------------
--Segment 2 to Segment 7 Wesco to Cloud
------------------------------------------
update wsc_ahcs_coa_concat_segment
set source_segment1 = null, source_segment8 = null, target_coa =null
where coa_name in ('Wesco to Cloud');
commit;
------------------------------------------
--183,107 rows updated
------------------------------------------

-----------------------------------------------------------------------------------
--Wesco to Cloud, update wsc_ahcs_coa_concat_segment
-----------------------------------------------------------------------------------
insert into wsc_tbl_time_t (a,b,c) values ('1',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 1 and 10000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('2',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 10001 and 20000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('3',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 20001 and 30000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('4',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 30001 and 40000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('5',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 40001 and 50000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('6',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 50001 and 60000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('7',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 60001 and 70000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('8',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 70001 and 80000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('9',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 80001 and 90000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('10',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 90001 and 100000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('11',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 100001 and 110000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('12',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 110001 and 120000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('13',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 120001 and 130000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('14',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 130001 and 140000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('15',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 140001 and 150000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('16',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 150001 and 160000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('17',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 160001 and 170000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('18',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 170001 and 180000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('19',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 180001 and 190000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('20',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle EBS','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 190001 and 200000) and COA_NAME='Wesco to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('21',sysdate,00623525);
commit;


-----------------------------------------------------------------------------------
--Disable Trigger
-----------------------------------------------------------------------------------
alter trigger WSC_COA_CCID_BIR disable;

-----------
--s2_s7
-----------
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
      1 COA_MAP_ID, 
      'Y' ENABLE_FLAG, 
      SOURCE_SEGMENT1 || '.' || SOURCE_SEGMENT2 || '.' || SOURCE_SEGMENT3 || '.' || SOURCE_SEGMENT4 || '.' || SOURCE_SEGMENT5 || '.' || SOURCE_SEGMENT6 || '.' || SOURCE_SEGMENT7 || '.' || SOURCE_SEGMENT8 SOURCE_SEGMENT, 
      TARGET_COA TARGET_SEGMENT, 
      sysdate CREATION_DATE, 
      sysdate LAST_UPDATE_DATE, 
      'WESCO to Cloud' COA_MAP_NAME, 
      'N' UI_FLAG, 
      SOURCE_SEGMENT1, 
      SOURCE_SEGMENT2, 
      SOURCE_SEGMENT3, 
      SOURCE_SEGMENT4, 
      SOURCE_SEGMENT5, 
      SOURCE_SEGMENT6, 
      SOURCE_SEGMENT7, 
      SOURCE_SEGMENT8 
    from 
      WSC_AHCS_COA_CONCAT_SEGMENT 
    where 
      substr(
        target_coa, 
        1, 
        instr(target_coa, '.', 1, 1)-1
      ) is not null 
      and coa_name = 'Wesco to Cloud'
      and source_segment1 is null and source_segment8 is null and target_coa like '%.%'
  );
 
-----------------------------------------------------------------------------------
--Enable Trigger
-----------------------------------------------------------------------------------
alter trigger WSC_COA_CCID_BIR enable;