insert into wsc_ahcs_refresh_t (LAST_REFRESH_DATE ,DATA_ENTITY_NAME, LAST_UPDATE_DATE,LAST_UPDATED_BY) 
values (sysdate- 30 ,'EBSFA_LOCATIONS',sysdate,'FININT');
commit;
 
insert into wsc_ahcs_refresh_t (LAST_REFRESH_DATE ,DATA_ENTITY_NAME, LAST_UPDATE_DATE,LAST_UPDATED_BY) 
values (sysdate- 30 ,'EBSFA_CATEGORIES',sysdate,'FININT');

commit;