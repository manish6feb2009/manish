update wsc_ahcs_coa_concat_segment set wsc_seq_num = wsc_seq.nextval where coa_name like 'An%' and wsc_seq_num is null;
commit;

insert into wsc_tbl_time_t (a,b,c) values ('1',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 530302 and 530400) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('2',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 530401 and 550400) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('3',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 550401 and 570400) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('4',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 570401 and 590400) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('5',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 590401 and 610400) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('6',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 610401 and 630400) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('7',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 630401 and 650400) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('8',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 650401 and 670400) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('9',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 670401 and 690400) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('10',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 690401 and 710400) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('11',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 710401 and 730400) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('12',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 730401 and 753169) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('17',sysdate,00623525);
commit;
