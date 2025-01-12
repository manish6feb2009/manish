set define off;

-----------------------------------------------------------------------------------
--after upload update 0 using LPAD
-----------------------------------------------------------------------------------
update wsc_ahcs_coa_concat_segment set 
source_segment1 =lpad(source_segment1,3,'0'),
source_segment2 =lpad(source_segment2,6,'0'),
source_segment3 =lpad(source_segment3,5,'0'),
source_segment4 =lpad(source_segment4,3,'0'),
source_segment5 =lpad(source_segment5,6,'0'),
source_segment6 =lpad(source_segment6,6,'0'),
source_segment7 =lpad(source_segment7,6,'0') 
where COA_NAME in('Wesco to Cloud','POC to Cloud');
commit;

-----------------------------------------------------------------------------------
--after upload all values in wsc_ahcs_coa_concat_segment update sequence
-----------------------------------------------------------------------------------
update wsc_ahcs_coa_concat_segment set wsc_seq_num = wsc_seq.nextval;
commit;

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
--Central to cloud, update wsc_ahcs_coa_concat_segment
-----------------------------------------------------------------------------------
--insert into wsc_tbl_time_t (a,b,c) values ('21',sysdate,00623525);
--commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('CENTRAL','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where COA_NAME='Central to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('22',sysdate,00623525);
commit;
--update wsc_ahcs_coa_concat_segment a
--set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('CENTRAL','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
--a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
--a.SOURCE_SEGMENT8,null,null) 
--where (wsc_seq_num between 202088 and 212087) and COA_NAME='Central to Cloud';
--commit;

--insert into wsc_tbl_time_t (a,b,c) values ('23',sysdate,00623525);
--commit;
--update wsc_ahcs_coa_concat_segment a
--set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('CENTRAL','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
--a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
--a.SOURCE_SEGMENT8,null,null) 
--where (wsc_seq_num between 212088 and 221454) and COA_NAME='Central to Cloud';
--commit;

--insert into wsc_tbl_time_t (a,b,c) values ('24',sysdate,00623525);
--commit;

-----------------------------------------------------------------------------------
--POC to cloud, update wsc_ahcs_coa_concat_segment
-----------------------------------------------------------------------------------
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('Oracle POC','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where 
--(wsc_seq_num between 221455 and 221777) and 
COA_NAME='POC to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('23',sysdate,00623525);
commit;
