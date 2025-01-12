update wsc_ahcs_coa_concat_segment set wsc_seq_num = wsc_seq.nextval where coa_name like 'An%';
commit;

declare
	a number := 2166800;
	b number;
begin
	for b in 1..1000 loop
		insert into wsc_tbl_time_t (a,b,c) values (TO_CHAR(b),sysdate,a);
		commit;
		update wsc_ahcs_coa_concat_segment a
		set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
		a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
		a.SOURCE_SEGMENT8,null,null) 
		where (wsc_seq_num between a and a+100) and COA_NAME='Anixter to Cloud' and target_coa is null;
		commit;
		a := a+100; 
	end loop;
end;


insert into wsc_tbl_time_t (a,b,c) values ('1',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 212821 and 213000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('2',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 213001 and 233000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('3',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 233001 and 253000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('4',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 253001 and 273000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('5',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 273001 and 293000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('6',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 293001 and 313000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('7',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 313001 and 333000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('8',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 333001 and 353000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('9',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 353001 and 373000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('10',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 373001 and 393000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('11',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 393001 and 413000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('12',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 413001 and 433000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('13',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 433001 and 453000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('14',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 453001 and 473000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('15',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 473001 and 493000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('16',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 493001 and 513000) and COA_NAME='Anixter to Cloud';
commit;

insert into wsc_tbl_time_t (a,b,c) values ('17',sysdate,00623525);
commit;
update wsc_ahcs_coa_concat_segment a
set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING('ANIXTER','Oracle ERP Cloud',a.SOURCE_SEGMENT1,
a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
a.SOURCE_SEGMENT8,null,null) 
where (wsc_seq_num between 513001 and 533000) and COA_NAME='Anixter to Cloud';
commit;