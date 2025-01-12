create or replace PACKAGE BODY WSC_USER_COA_TRANSFORMATION_PKG IS

    FUNCTION transformation_one ( 
        P_COA_MAP_NAME in varchar2,
        p_src_sgt1 IN varchar2,
        pp_src_sgt2 IN varchar2,
        p_src_sgt3 IN varchar2,
        p_src_sgt4 IN varchar2,
        p_src_sgt5 IN varchar2,
        p_src_sgt6 IN varchar2,
        p_src_sgt7 IN varchar2,
        p_src_sgt8 IN varchar2,
        p_src_sgt9 IN varchar2,
        p_src_sgt10 IN varchar2,
        p_user_name  IN varchar2
    ) RETURN VARCHAR2 IS
    
    LV_COA_MAP_ID number;
    lv_tgt_sgt varchar2(1000) := null;
    lv_target_system varchar2(200) := null;
    lv_source_system varchar2(200):= null ;
    lv_error_msg varchar2(1000) := null;
    
    p_src_sgt2 varchar2(100) := case when (P_COA_MAP_NAME = 'WESCO to Cloud') 
    then LPAD(pp_src_sgt2, 6, '0')
    else pp_src_sgt2 end ;
    
--    DECODE(P_COA_MAP_NAME,'WESCO to Cloud',LPAD(pp_src_sgt2, 6, '0'),pp_src_sgt2);
    
    lv_src_sgt varchar2(1000) := case when p_src_sgt1 is not null then p_src_sgt1 else null end ||
    case when p_src_sgt2 is not null then '.'|| p_src_sgt2 else null end ||
    case when p_src_sgt3 is not null then '.'|| p_src_sgt3 else null end ||
    case when p_src_sgt4 is not null then '.'|| p_src_sgt4 else null end ||
    case when p_src_sgt5 is not null then '.'|| p_src_sgt5 else null end ||
    case when p_src_sgt6 is not null then '.'|| p_src_sgt6 else null end ||
    case when p_src_sgt7 is not null then '.'|| p_src_sgt7 else null end ||
    case when P_COA_MAP_NAME in ('WESCO to Cloud' , 'POC to Cloud') then '.'|| p_src_sgt8 when p_src_sgt8 is not null  then '.'|| p_src_sgt8 else null end ||
    case when p_src_sgt9 is not null then '.'|| p_src_sgt9 else null end ||
    case when p_src_sgt10 is not null then '.'|| p_src_sgt10 else null end;

    BEGIN  
    --dbms_output.put_line(lv_src_sgt);
    begin
        select coa_map_id into LV_COA_MAP_ID from wsc_gl_coa_map_t where upper(coa_map_name) = upper(p_coa_map_name);
    exception 
    WHEN OTHERS THEN 
         LV_COA_MAP_ID := null;
    end;
    --dbms_output.put_line('2 ' ||LV_COA_MAP_ID);
    
    begin
        select TARGET_SEGMENT into lv_tgt_sgt from wsc_gl_ccid_mapping_t
        where SOURCE_SEGMENT = lv_src_sgt and COA_MAP_ID = LV_COA_MAP_ID and ENABLE_FLAG = 'Y';
    exception
    WHEN OTHERS THEN 
         lv_tgt_sgt := null;
    end;
    --dbms_output.put_line('3 '||lv_tgt_sgt);
    
    begin
        lv_error_msg := case when upper(P_COA_MAP_NAME) = upper('WESCO to Cloud') and (p_src_sgt1 is null and p_src_sgt8 is not null) then 
            'Source Segment 1 Required'
            when upper(P_COA_MAP_NAME) = upper('WESCO to Cloud') and (p_src_sgt1 is not null and p_src_sgt8 is null) then 
            'Reference 1 Required'
            when upper(P_COA_MAP_NAME) = upper('WESCO to Cloud') and (p_src_sgt9 is not null or p_src_sgt10 is not null) then 
            'Reference 2 & 3 not Required'
            when upper(P_COA_MAP_NAME) = upper('POC to Cloud') and (p_src_sgt1 is null and p_src_sgt8 is not null) then 
            'Source Segment 1 Required'
            when upper(P_COA_MAP_NAME) = upper('POC to Cloud') and (p_src_sgt1 is not null and p_src_sgt8 is null) then 
            'Reference 1 Required'
            when upper(P_COA_MAP_NAME) = upper('POC to Cloud') and (p_src_sgt9 is not null or p_src_sgt10 is not null) then 
            'Reference 2 & 3 not Required'
            when upper(P_COA_MAP_NAME) = upper('CENTRAL to Cloud') and (p_src_sgt3 is not null or p_src_sgt4 is not null
            or p_src_sgt5 is not null or p_src_sgt6 is not null or p_src_sgt7 is not null or p_src_sgt8 is not null
            or p_src_sgt9 is not null or p_src_sgt10 is not null) then 
            'Source Segment 3 to 7 & Reference 1 to 3 not Required'
            else null end;
        if lv_error_msg is not null then
            return lv_error_msg;
        end if;
    exception
    WHEN OTHERS THEN 
         null;
    end;
        if lv_tgt_sgt is not null then
            return lv_tgt_sgt;
        else
            select target_system, source_system into lv_target_system, lv_source_system
              from wsc_gl_coa_map_t
             where COA_MAP_ID = LV_COA_MAP_ID;
    --dbms_output.put_line(lv_target_system);
    --dbms_output.put_line(lv_source_system);
             lv_tgt_sgt  := wsc_gl_coa_mapping_pkg.coa_mapping(lv_source_system,lv_target_system,
                p_src_sgt1, p_src_sgt2,p_src_sgt3,
                p_src_sgt4,p_src_sgt5,p_src_sgt6,
                p_src_sgt7,p_src_sgt8,null,null);
    --dbms_output.put_line('3'||lv_tgt_sgt);
    if  substr(lv_tgt_sgt,1,instr(lv_tgt_sgt,'.',1,1)-1) is not null then 
    
            insert into wsc_gl_ccid_mapping_t(CCID_VALUE_ID, COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, 
            CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG,UI_FLAG, created_by,last_updated_by,source_segment1,source_segment2,source_segment3,source_segment4,source_segment5,
                    source_segment6,source_segment7,source_segment8,source_segment9,source_segment10)
            values (wsc_gl_ccid_mapping_s.nextval,LV_COA_MAP_ID,lv_src_sgt ,
            lv_tgt_sgt,sysdate, sysdate, 'Y','N',p_user_name,p_user_name,p_src_sgt1, p_src_sgt2,p_src_sgt3,
                p_src_sgt4,p_src_sgt5,p_src_sgt6,
                p_src_sgt7,p_src_sgt8,null,null);
            commit;
        end if;
            return lv_tgt_sgt;
        end if;
    EXCEPTION 
        WHEN OTHERS THEN 
            RETURN null; 
    END transformation_one;

    FUNCTION  "EXIT_COA_MAP_NAME" ( 
        i_value in VARCHAR2
    ) 
    RETURN NUMBER IS 
        v_ret_count NUMBER;
    begin
        select count(*) into v_ret_count from wsc_gl_coa_map_t where COA_MAP_NAME = i_value; 
        if(v_ret_count > 0)then
            Return 1;
        else
            Return 0;
        End IF;
        COMMIT;
    Exception
        when no_data_found then
        return 0;
        WHEN OTHERS THEN 
        RETURN 0; 
    end;

    FUNCTION  ccid_match ( 
        src_sgt IN varchar2,
        P_COA_MAP_ID in  number
    ) RETURN VARCHAR2 IS
        f_tgt_sgt varchar2(1000);
        cursor tgt_sgt is select TARGET_SEGMENT from wsc_gl_ccid_mapping_t
        where SOURCE_SEGMENT = src_sgt and COA_MAP_ID = P_COA_MAP_ID and ENABLE_FLAG = 'Y';
    BEGIN  
        open tgt_sgt;
        fetch tgt_sgt into f_tgt_sgt;
        close tgt_sgt;
        return f_tgt_sgt;
    EXCEPTION 
        WHEN no_data_found THEN 
            RETURN null; 
        WHEN OTHERS THEN 
            RETURN null; 
    END ccid_match;

	PROCEDURE leg_coa_transformation(p_batch_id IN number, p_user_name in varchar2) IS
	
		cursor cur_coa_map_id is 
			select distinct coa_map.coa_map_id, coa_map.target_system, coa_map.source_system
			  from wsc_gl_coa_map_t coa_map, WSC_GL_USER_COA_MAPPING_T user_coa
			 where coa_map.COA_MAP_NAME = user_coa.COA_MAP_NAME 
			   and user_coa.batch_id = p_batch_id
               and error_message is null
               order by coa_map_id;
/*
		cursor cur_leg_seg_value(cur_p_src_system varchar2, cur_p_tgt_system varchar2, cur_coa_mapid number) is		
			select tgt_coa.LEGACY_COA,wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system,cur_p_tgt_system,
                tgt_coa.SOURCE_SEGMENT1	,
				tgt_coa.SOURCE_SEGMENT2,tgt_coa.SOURCE_SEGMENT3,tgt_coa.SOURCE_SEGMENT4,tgt_coa.SOURCE_SEGMENT5,
                tgt_coa.SOURCE_SEGMENT6,
				tgt_coa.SOURCE_SEGMENT7,tgt_coa.SOURCE_SEGMENT8,null,null) target_coa from 
                (select line.LEGACY_COA, line.SOURCE_SEGMENT1, line.SOURCE_SEGMENT2, line.SOURCE_SEGMENT3, 
					line.SOURCE_SEGMENT4, line.SOURCE_SEGMENT5, line.SOURCE_SEGMENT6, line.SOURCE_SEGMENT7, line.SOURCE_SEGMENT8
                from WSC_GL_USER_COA_MAPPING_T line
               where line.batch_id = p_batch_id and line.target_coa is null and line.error_message is null
               and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = cur_coa_mapid)
				) tgt_coa;
*/
    cursor cur_leg_seg_value(cur_p_src_system varchar2, cur_p_tgt_system varchar2, cur_coa_mapid number) is	
        select tgt_coa.LEGACY_COA,wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system,cur_p_tgt_system,
                tgt_coa.SOURCE_SEGMENT1	,
				tgt_coa.SOURCE_SEGMENT2,tgt_coa.SOURCE_SEGMENT3,tgt_coa.SOURCE_SEGMENT4,tgt_coa.SOURCE_SEGMENT5,
                tgt_coa.SOURCE_SEGMENT6,
				tgt_coa.SOURCE_SEGMENT7,tgt_coa.SOURCE_SEGMENT8,null,null) target_coa from 
                WSC_GL_USER_COA_MAPPING_T tgt_coa
                where tgt_coa.batch_id = p_batch_id and tgt_coa.target_coa is null and tgt_coa.error_message is null
               and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = cur_coa_mapid);

		type leg_seg_value_type is table of cur_leg_seg_value%rowtype;
        lv_leg_seg_value leg_seg_value_type;

		cursor cur_inserting_ccid_table is
			select distinct LEGACY_COA, TARGET_COA from WSC_GL_USER_COA_MAPPING_T
			 where batch_id = p_batch_id 
			   and attribute1 = 'Y'  
               and error_message is null
			   and substr(target_coa,1,instr(target_coa,'.',1,1)-1) is not null;  

		type inserting_ccid_table_type is table of cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table inserting_ccid_table_type;

		lv_coa_mapid number;
        lv_src_system varchar2(100);
        lv_tgt_system varchar2(100);
		lv_target_coa varchar2(1000);
        
        LV_COA_MAP_CNT number;
        lv_error_msg varchar2(400);
        lv_error1 varchar2(30) := 'False';
        lv_error2 varchar2(30) := 'False';
        
        
        cursor cur_line_table is select SOURCE_SEGMENT1,
        SOURCE_SEGMENT2,
        SOURCE_SEGMENT3,
        SOURCE_SEGMENT4,
        SOURCE_SEGMENT5,
        SOURCE_SEGMENT6,
        SOURCE_SEGMENT7,
        SOURCE_SEGMENT8,
        SOURCE_SEGMENT9,
        SOURCE_SEGMENT10,
        COA_MAP_NAME
        from WSC_GL_USER_COA_MAPPING_T;

	begin 
         update WSC_GL_USER_COA_MAPPING_T set ERROR_MESSAGE = case when upper(COA_MAP_NAME) = upper('WESCO to Cloud') and (SOURCE_SEGMENT1 is null and SOURCE_SEGMENT8 is not null) then 
        'Source Segment 1 Required'
        when upper(COA_MAP_NAME) = upper('WESCO to Cloud') and (SOURCE_SEGMENT1 is not null and SOURCE_SEGMENT8 is null) then 
        'Reference 1 Required'
        when upper(COA_MAP_NAME) = upper('WESCO to Cloud') and (SOURCE_SEGMENT9 is not null or SOURCE_SEGMENT10 is not null) then 
        'Reference 2 & 3 not Required'
        when upper(COA_MAP_NAME) = upper('POC to Cloud') and (SOURCE_SEGMENT1 is null and SOURCE_SEGMENT8 is not null) then 
        'Source Segment 1 Required'
        when upper(COA_MAP_NAME) = upper('POC to Cloud') and (SOURCE_SEGMENT1 is not null and SOURCE_SEGMENT8 is null) then 
        'Reference 1 Required'
        when upper(COA_MAP_NAME) = upper('POC to Cloud') and (SOURCE_SEGMENT9 is not null or SOURCE_SEGMENT10 is not null) then 
        'Reference 2 & 3 not Required'
        when upper(COA_MAP_NAME) = upper('CENTRAL to Cloud') and (SOURCE_SEGMENT3 is not null or SOURCE_SEGMENT4 is not null
        or SOURCE_SEGMENT5 is not null or SOURCE_SEGMENT6 is not null or SOURCE_SEGMENT7 is not null or SOURCE_SEGMENT8 is not null
        or SOURCE_SEGMENT9 is not null or SOURCE_SEGMENT10 is not null) then 
        'Source Segment 3 to 7 & Reference 1 to 3 not Required'
        else null end
        where batch_id = p_batch_id;
--         update WSC_GL_USER_COA_MAPPING_T set ERROR_MESSAGE = ' :: alleast one source segment having a value.'
--              where (SOURCE_SEGMENT1 is null)and(SOURCE_SEGMENT2 is null) 
--            and (SOURCE_SEGMENT3 is null )and (SOURCE_SEGMENT4 is null) 
--            and (SOURCE_SEGMENT5 is null)and (SOURCE_SEGMENT6 is null) 
--            and (SOURCE_SEGMENT7 is null) and (SOURCE_SEGMENT8 is null) 
--            and (SOURCE_SEGMENT9 is null) and (SOURCE_SEGMENT10 is null);
--          commit;
--          
          update WSC_GL_USER_COA_MAPPING_T a set ERROR_MESSAGE = lv_error_msg || ' -> ' || a.COA_MAP_NAME || ' :: COA Map Name value is invalid. Please verify.'
              where WSC_USER_COA_TRANSFORMATION_PKG.EXIT_COA_MAP_NAME(a.COA_MAP_NAME) = 0 and batch_id = p_batch_id;
          commit;     

		for lv_coa in cur_coa_map_id 
		loop
			lv_coa_mapid := lv_coa.coa_map_id;
			lv_tgt_system := lv_coa.target_system;
			lv_src_system := lv_coa.source_system;
--            insert into wsc_tbl_time_t (a,b) values ('1',sysdate);
--            commit;
			begin 
				UPDATE WSC_GL_USER_COA_MAPPING_T line
				   SET TARGET_coa = WSC_USER_COA_TRANSFORMATION_PKG.ccid_match(LEGACY_COA,lv_coa_mapid), LAST_UPDATE_DATE = sysdate
				 where batch_id = p_batch_id and error_message is null
                 and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = lv_coa_mapid);
				   /*and exists 
					(select 1 from wsc_gl_ccid_mapping_t ccid_map
					  where ccid_map.coa_map_id = lv_coa_mapid and line.LEGACY_COA = ccid_map.source_segment);
				*/commit;
			exception 
				when others then
					dbms_output.put_line('Error with Query:  ' || SQLERRM);
			end;
--            insert into wsc_tbl_time_t (a,b) values ('2',sysdate);
--            commit;
			begin
                update WSC_GL_USER_COA_MAPPING_T tgt_coa set target_coa = wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system,
                lv_tgt_system,
                tgt_coa.SOURCE_SEGMENT1	,
				tgt_coa.SOURCE_SEGMENT2,tgt_coa.SOURCE_SEGMENT3,tgt_coa.SOURCE_SEGMENT4,tgt_coa.SOURCE_SEGMENT5,
                tgt_coa.SOURCE_SEGMENT6,
				tgt_coa.SOURCE_SEGMENT7,tgt_coa.SOURCE_SEGMENT8,null,null),  ATTRIBUTE1 = 'Y', 
					LAST_UPDATE_DATE = sysdate 
					where batch_id = p_batch_id and error_message is null
                    and target_coa is null 
                    and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = lv_coa_mapid)
                    ;   
                    commit;
--				open cur_leg_seg_value(lv_src_system, lv_tgt_system, lv_coa_mapid);
--				loop
--				fetch cur_leg_seg_value bulk collect into lv_leg_seg_value limit 400;
--				EXIT WHEN lv_leg_seg_value.COUNT = 0;
                
--				forall i in 1..lv_leg_seg_value.count
--                    update WSC_GL_USER_COA_MAPPING_T set target_coa = lv_leg_seg_value(i).target_coa,  ATTRIBUTE1 = 'Y', 
--					LAST_UPDATE_DATE = sysdate 
--					where LEGACY_COA = lv_leg_seg_value(i).LEGACY_COA and batch_id = p_batch_id and error_message is null
--                    and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = lv_coa_mapid);   
--                    commit;
--                end loop;
--                close cur_leg_seg_value;
--				commit;
			exception
				when others then
					dbms_output.put_line('Error with Query:  ' || SQLERRM);
			end;
--            insert into wsc_tbl_time_t (a,b) values ('3',sysdate);
--            commit;
            begin
            /*
				open cur_inserting_ccid_table;
				loop
				fetch cur_inserting_ccid_table bulk collect into lv_inserting_ccid_table limit 400;
				EXIT WHEN lv_inserting_ccid_table.COUNT = 0;        
				forall i in 1..lv_inserting_ccid_table.count
					insert into wsc_gl_ccid_mapping_t(CCID_VALUE_ID, COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, 
                    CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG,UI_FLAG)
					values (wsc_gl_ccid_mapping_s.nextval,lv_coa_mapid, lv_inserting_ccid_table(i).LEGACY_COA,
                    lv_inserting_ccid_table(i).TARGET_COA,sysdate, sysdate, 'Y','N');
				end loop;
                close cur_inserting_ccid_table;
				update WSC_GL_USER_COA_MAPPING_T set attribute1 = null 
				 where batch_id = p_batch_id and error_message is null;
*/
insert into wsc_gl_ccid_mapping_t(CCID_VALUE_ID, COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, 
                    CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG,UI_FLAG,CREATED_BY,LAST_UPDATED_BY,
                    source_segment1,source_segment2,source_segment3,source_segment4,source_segment5,
                    source_segment6,source_segment7,source_segment8,source_segment9,source_segment10)
select wsc_gl_ccid_mapping_s.nextval , lv_coa_mapid, LEGACY_COA,TARGET_COA,sysdate, sysdate, 'Y','N', p_user_name,p_user_name,source_segment1,source_segment2,source_segment3,source_segment4,source_segment5,
                    source_segment6,source_segment7,source_segment8,source_segment9,source_segment10
from (select distinct LEGACY_COA, TARGET_COA,source_segment1,source_segment2,source_segment3,source_segment4,source_segment5,
                    source_segment6,source_segment7,source_segment8,source_segment9,source_segment10
from WSC_GL_USER_COA_MAPPING_T
			 where batch_id = p_batch_id 
			   and attribute1 = 'Y'  
               and error_message is null
			   and substr(target_coa,1,instr(target_coa,'.',1,1)-1) is not null
               and target_coa is not null 
                    and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = lv_coa_mapid));  
				commit;
			end;
--            insert into wsc_tbl_time_t (a,b) values ('4',sysdate);
--            commit;
            begin
				update WSC_GL_USER_COA_MAPPING_T
				set TARGET_SEGMENT1 = substr(target_coa,1,instr(target_coa,'.',1,1)-1) ,
					TARGET_SEGMENT2 = substr(target_coa,instr(target_coa,'.',1,1)+1,instr(target_coa,'.',1,2)-instr(target_coa,'.',1,1)-1) ,
					TARGET_SEGMENT3 = substr(target_coa,instr(target_coa,'.',1,2)+1,instr(target_coa,'.',1,3)-instr(target_coa,'.',1,2)-1) ,
					TARGET_SEGMENT4 = substr(target_coa,instr(target_coa,'.',1,3)+1,instr(target_coa,'.',1,4)-instr(target_coa,'.',1,3)-1) ,
					TARGET_SEGMENT5 = substr(target_coa,instr(target_coa,'.',1,4)+1,instr(target_coa,'.',1,5)-instr(target_coa,'.',1,4)-1) ,
					TARGET_SEGMENT6 = substr(target_coa,instr(target_coa,'.',1,5)+1,instr(target_coa,'.',1,6)-instr(target_coa,'.',1,5)-1) ,
					TARGET_SEGMENT7 = substr(target_coa,instr(target_coa,'.',1,6)+1,instr(target_coa,'.',1,7)-instr(target_coa,'.',1,6)-1) ,
					TARGET_SEGMENT8 = substr(target_coa,instr(target_coa,'.',1,7)+1,instr(target_coa,'.',1,8)-instr(target_coa,'.',1,7)-1) ,
					TARGET_SEGMENT9 = substr(target_coa,instr(target_coa,'.',1,8)+1) , 
					TARGET_SEGMENT10 = substr(target_coa,instr(target_coa,'.',1,9)+1,instr(target_coa,'.',1,10)-instr(target_coa,'.',1,9)-1) , 
					LAST_UPDATE_DATE = sysdate
				where batch_id = p_batch_id 
                  and error_message is null
				  and substr(target_coa,1,instr(target_coa,'.',1,1)-1)  is not null
                  and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = lv_coa_mapid);
				commit;
			exception
				when others then
					dbms_output.put_line('Error with Query:  ' || SQLERRM);
			end;
--            insert into wsc_tbl_time_t (a,b) values ('5',sysdate);
--            commit;
            update
			(
			select user_coa.ERROR_MESSAGE,user_coa.LAST_UPDATE_DATE,
			   user_coa.batch_id, user_coa.target_coa tgt_coa
				  from WSC_GL_USER_COA_MAPPING_T user_coa
				where user_coa.batch_id = p_batch_id
                 and error_message is null
                 and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = lv_coa_mapid)
				 and substr(user_coa.target_coa,1,instr(user_coa.target_coa,'.',1,1)-1)  is null
			)
			set 
			   ERROR_MESSAGE = tgt_coa,
			   LAST_UPDATE_DATE = sysdate;

			
--            insert into wsc_tbl_time_t (a,b) values ('6',sysdate);
--            commit;
		end loop;
        update WSC_GL_USER_COA_MAPPING_H set status='Success' , last_update_date = sysdate 
        where HEADER_ID = p_batch_id;
        commit;
	end leg_coa_transformation; 


	PROCEDURE leg_coa_transformation_adfdi(p_batch_id IN number, p_user_name in varchar2) IS
	
		cursor cur_coa_map_id is 
			select distinct coa_map.coa_map_id, coa_map.target_system, coa_map.source_system
			  from wsc_gl_coa_map_t coa_map, WSC_GL_ADFDI_COA_MAPPING_T user_coa
			 where coa_map.COA_MAP_NAME = user_coa.COA_MAP_NAME 
			   and user_coa.batch_id = p_batch_id
               and error_message is null
               order by coa_map_id;
/*
		cursor cur_leg_seg_value(cur_p_src_system varchar2, cur_p_tgt_system varchar2, cur_coa_mapid number) is		
			select tgt_coa.LEGACY_COA,wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system,cur_p_tgt_system,
                tgt_coa.SOURCE_SEGMENT1	,
				tgt_coa.SOURCE_SEGMENT2,tgt_coa.SOURCE_SEGMENT3,tgt_coa.SOURCE_SEGMENT4,tgt_coa.SOURCE_SEGMENT5,
                tgt_coa.SOURCE_SEGMENT6,
				tgt_coa.SOURCE_SEGMENT7,tgt_coa.SOURCE_SEGMENT8,null,null) target_coa from 
                (select line.LEGACY_COA, line.SOURCE_SEGMENT1, line.SOURCE_SEGMENT2, line.SOURCE_SEGMENT3, 
					line.SOURCE_SEGMENT4, line.SOURCE_SEGMENT5, line.SOURCE_SEGMENT6, line.SOURCE_SEGMENT7, line.SOURCE_SEGMENT8
                from WSC_GL_ADFDI_COA_MAPPING_T line
               where line.batch_id = p_batch_id and line.target_coa is null and line.error_message is null
               and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = cur_coa_mapid)
				) tgt_coa;
*/
    cursor cur_leg_seg_value(cur_p_src_system varchar2, cur_p_tgt_system varchar2, cur_coa_mapid number) is	
        select tgt_coa.LEGACY_COA,wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system,cur_p_tgt_system,
                tgt_coa.SOURCE_SEGMENT1	,
				tgt_coa.SOURCE_SEGMENT2,tgt_coa.SOURCE_SEGMENT3,tgt_coa.SOURCE_SEGMENT4,tgt_coa.SOURCE_SEGMENT5,
                tgt_coa.SOURCE_SEGMENT6,
				tgt_coa.SOURCE_SEGMENT7,tgt_coa.SOURCE_SEGMENT8,null,null) target_coa from 
                WSC_GL_ADFDI_COA_MAPPING_T tgt_coa
                where tgt_coa.batch_id = p_batch_id and tgt_coa.target_coa is null and tgt_coa.error_message is null
               and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = cur_coa_mapid);

		type leg_seg_value_type is table of cur_leg_seg_value%rowtype;
        lv_leg_seg_value leg_seg_value_type;

		cursor cur_inserting_ccid_table is
			select distinct LEGACY_COA, TARGET_COA from WSC_GL_ADFDI_COA_MAPPING_T
			 where batch_id = p_batch_id 
			   and attribute1 = 'Y'  
               and error_message is null
			   and substr(target_coa,1,instr(target_coa,'.',1,1)-1) is not null;  

		type inserting_ccid_table_type is table of cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table inserting_ccid_table_type;

		lv_coa_mapid number;
        lv_src_system varchar2(100);
        lv_tgt_system varchar2(100);
		lv_target_coa varchar2(1000);
        
        LV_COA_MAP_CNT number;
        lv_error_msg varchar2(400);
        lv_error1 varchar2(30) := 'False';
        lv_error2 varchar2(30) := 'False';
        
        
        cursor cur_line_table is select SOURCE_SEGMENT1,
        SOURCE_SEGMENT2,
        SOURCE_SEGMENT3,
        SOURCE_SEGMENT4,
        SOURCE_SEGMENT5,
        SOURCE_SEGMENT6,
        SOURCE_SEGMENT7,
        SOURCE_SEGMENT8,
        SOURCE_SEGMENT9,
        SOURCE_SEGMENT10,
        COA_MAP_NAME
        from WSC_GL_ADFDI_COA_MAPPING_T;

	begin 
    
         update WSC_GL_ADFDI_COA_MAPPING_T set ERROR_MESSAGE = case when upper(COA_MAP_NAME) = upper('WESCO to Cloud') and (SOURCE_SEGMENT1 is null and SOURCE_SEGMENT8 is not null) then 
        'Source Segment 1 Required'
        when upper(COA_MAP_NAME) = upper('WESCO to Cloud') and (SOURCE_SEGMENT1 is not null and SOURCE_SEGMENT8 is null) then 
        'Reference 1 Required'
        when upper(COA_MAP_NAME) = upper('WESCO to Cloud') and (SOURCE_SEGMENT9 is not null or SOURCE_SEGMENT10 is not null) then 
        'Reference 2 & 3 not Required'
        when upper(COA_MAP_NAME) = upper('POC to Cloud') and (SOURCE_SEGMENT1 is null and SOURCE_SEGMENT8 is not null) then 
        'Source Segment 1 Required'
        when upper(COA_MAP_NAME) = upper('POC to Cloud') and (SOURCE_SEGMENT1 is not null and SOURCE_SEGMENT8 is null) then 
        'Reference 1 Required'
        when upper(COA_MAP_NAME) = upper('POC to Cloud') and (SOURCE_SEGMENT9 is not null or SOURCE_SEGMENT10 is not null) then 
        'Reference 2 & 3 not Required'
        when upper(COA_MAP_NAME) = upper('CENTRAL to Cloud') and (SOURCE_SEGMENT3 is not null or SOURCE_SEGMENT4 is not null
        or SOURCE_SEGMENT5 is not null or SOURCE_SEGMENT6 is not null or SOURCE_SEGMENT7 is not null or SOURCE_SEGMENT8 is not null
        or SOURCE_SEGMENT9 is not null or SOURCE_SEGMENT10 is not null) then 
        'Source Segment 3 to 7 & Reference 1 to 3 not Required'
        else null end
        where batch_id = p_batch_id;
--         update WSC_GL_ADFDI_COA_MAPPING_T set ERROR_MESSAGE = ' :: alleast one source segment having a value.'
--              where (SOURCE_SEGMENT1 is null)and(SOURCE_SEGMENT2 is null) 
--            and (SOURCE_SEGMENT3 is null )and (SOURCE_SEGMENT4 is null) 
--            and (SOURCE_SEGMENT5 is null)and (SOURCE_SEGMENT6 is null) 
--            and (SOURCE_SEGMENT7 is null) and (SOURCE_SEGMENT8 is null) 
--            and (SOURCE_SEGMENT9 is null) and (SOURCE_SEGMENT10 is null);
--          commit;
--          
          update WSC_GL_ADFDI_COA_MAPPING_T a set ERROR_MESSAGE = lv_error_msg || ' -> ' || a.COA_MAP_NAME || ' :: COA Map Name value is invalid. Please verify.'
              where WSC_USER_COA_TRANSFORMATION_PKG.EXIT_COA_MAP_NAME(a.COA_MAP_NAME) = 0 and batch_id = p_batch_id;
          commit;     

		for lv_coa in cur_coa_map_id 
		loop
			lv_coa_mapid := lv_coa.coa_map_id;
			lv_tgt_system := lv_coa.target_system;
			lv_src_system := lv_coa.source_system;
--            insert into wsc_tbl_time_t (a,b) values ('1',sysdate);
--            commit;
			begin 
				UPDATE WSC_GL_ADFDI_COA_MAPPING_T line
				   SET TARGET_coa = WSC_USER_COA_TRANSFORMATION_PKG.ccid_match(LEGACY_COA,lv_coa_mapid), LAST_UPDATE_DATE = sysdate
				 where batch_id = p_batch_id and error_message is null
                 and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = lv_coa_mapid);
				   /*and exists 
					(select 1 from wsc_gl_ccid_mapping_t ccid_map
					  where ccid_map.coa_map_id = lv_coa_mapid and line.LEGACY_COA = ccid_map.source_segment);
				*/commit;
			exception 
				when others then
					dbms_output.put_line('Error with Query:  ' || SQLERRM);
			end;
--            insert into wsc_tbl_time_t (a,b) values ('2',sysdate);
--            commit;
			begin
                update WSC_GL_ADFDI_COA_MAPPING_T tgt_coa set target_coa = wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system,
                lv_tgt_system,
                tgt_coa.SOURCE_SEGMENT1	,
				tgt_coa.SOURCE_SEGMENT2,tgt_coa.SOURCE_SEGMENT3,tgt_coa.SOURCE_SEGMENT4,tgt_coa.SOURCE_SEGMENT5,
                tgt_coa.SOURCE_SEGMENT6,
				tgt_coa.SOURCE_SEGMENT7,tgt_coa.SOURCE_SEGMENT8,null,null),  ATTRIBUTE1 = 'Y', 
					LAST_UPDATE_DATE = sysdate 
					where batch_id = p_batch_id and error_message is null
                    and target_coa is null 
                    and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = lv_coa_mapid)
                    ;   
                    commit;
--				open cur_leg_seg_value(lv_src_system, lv_tgt_system, lv_coa_mapid);
--				loop
--				fetch cur_leg_seg_value bulk collect into lv_leg_seg_value limit 400;
--				EXIT WHEN lv_leg_seg_value.COUNT = 0;
                
--				forall i in 1..lv_leg_seg_value.count
--                    update WSC_GL_ADFDI_COA_MAPPING_T set target_coa = lv_leg_seg_value(i).target_coa,  ATTRIBUTE1 = 'Y', 
--					LAST_UPDATE_DATE = sysdate 
--					where LEGACY_COA = lv_leg_seg_value(i).LEGACY_COA and batch_id = p_batch_id and error_message is null
--                    and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = lv_coa_mapid);   
--                    commit;
--                end loop;
--                close cur_leg_seg_value;
--				commit;
			exception
				when others then
					dbms_output.put_line('Error with Query:  ' || SQLERRM);
			end;
--            insert into wsc_tbl_time_t (a,b) values ('3',sysdate);
--            commit;
            begin
            /*
				open cur_inserting_ccid_table;
				loop
				fetch cur_inserting_ccid_table bulk collect into lv_inserting_ccid_table limit 400;
				EXIT WHEN lv_inserting_ccid_table.COUNT = 0;        
				forall i in 1..lv_inserting_ccid_table.count
					insert into wsc_gl_ccid_mapping_t(CCID_VALUE_ID, COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, 
                    CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG,UI_FLAG)
					values (wsc_gl_ccid_mapping_s.nextval,lv_coa_mapid, lv_inserting_ccid_table(i).LEGACY_COA,
                    lv_inserting_ccid_table(i).TARGET_COA,sysdate, sysdate, 'Y','N');
				end loop;
                close cur_inserting_ccid_table;
				update WSC_GL_ADFDI_COA_MAPPING_T set attribute1 = null 
				 where batch_id = p_batch_id and error_message is null;
*/

insert into wsc_gl_ccid_mapping_t(CCID_VALUE_ID, COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, 
                    CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG,UI_FLAG,CREATED_BY,LAST_UPDATED_BY,
                    source_segment1,source_segment2,source_segment3,source_segment4,source_segment5,
                    source_segment6,source_segment7,source_segment8,source_segment9,source_segment10)
select wsc_gl_ccid_mapping_s.nextval , lv_coa_mapid, LEGACY_COA,TARGET_COA,sysdate, sysdate, 'Y','N', p_user_name,p_user_name,source_segment1,source_segment2,source_segment3,source_segment4,source_segment5,
                    source_segment6,source_segment7,source_segment8,source_segment9,source_segment10
from (select distinct LEGACY_COA, TARGET_COA,source_segment1,source_segment2,source_segment3,source_segment4,source_segment5,
                    source_segment6,source_segment7,source_segment8,source_segment9,source_segment10
from wsc_gl_adfdi_coa_mapping_t

--insert into wsc_gl_ccid_mapping_t(CCID_VALUE_ID, COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, 
--                    CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG,UI_FLAG,CREATED_BY,LAST_UPDATED_BY)
--select wsc_gl_ccid_mapping_s.nextval , lv_coa_mapid, LEGACY_COA,TARGET_COA,sysdate, sysdate, 'Y','N', p_user_name,p_user_name
--from (select distinct LEGACY_COA, TARGET_COA
--from WSC_GL_ADFDI_COA_MAPPING_T
			 where batch_id = p_batch_id 
			   and attribute1 = 'Y'  
               and error_message is null
			   and substr(target_coa,1,instr(target_coa,'.',1,1)-1) is not null
               and target_coa is not null 
                    and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = lv_coa_mapid));  
				commit;
			end;
--            insert into wsc_tbl_time_t (a,b) values ('4',sysdate);
--            commit;
            begin
				update WSC_GL_ADFDI_COA_MAPPING_T
				set TARGET_SEGMENT1 = substr(target_coa,1,instr(target_coa,'.',1,1)-1) ,
					TARGET_SEGMENT2 = substr(target_coa,instr(target_coa,'.',1,1)+1,instr(target_coa,'.',1,2)-instr(target_coa,'.',1,1)-1) ,
					TARGET_SEGMENT3 = substr(target_coa,instr(target_coa,'.',1,2)+1,instr(target_coa,'.',1,3)-instr(target_coa,'.',1,2)-1) ,
					TARGET_SEGMENT4 = substr(target_coa,instr(target_coa,'.',1,3)+1,instr(target_coa,'.',1,4)-instr(target_coa,'.',1,3)-1) ,
					TARGET_SEGMENT5 = substr(target_coa,instr(target_coa,'.',1,4)+1,instr(target_coa,'.',1,5)-instr(target_coa,'.',1,4)-1) ,
					TARGET_SEGMENT6 = substr(target_coa,instr(target_coa,'.',1,5)+1,instr(target_coa,'.',1,6)-instr(target_coa,'.',1,5)-1) ,
					TARGET_SEGMENT7 = substr(target_coa,instr(target_coa,'.',1,6)+1,instr(target_coa,'.',1,7)-instr(target_coa,'.',1,6)-1) ,
					TARGET_SEGMENT8 = substr(target_coa,instr(target_coa,'.',1,7)+1,instr(target_coa,'.',1,8)-instr(target_coa,'.',1,7)-1) ,
					TARGET_SEGMENT9 = substr(target_coa,instr(target_coa,'.',1,8)+1) , 
					TARGET_SEGMENT10 = substr(target_coa,instr(target_coa,'.',1,9)+1,instr(target_coa,'.',1,10)-instr(target_coa,'.',1,9)-1) , 
					LAST_UPDATE_DATE = sysdate
				where batch_id = p_batch_id 
                  and error_message is null
				  and substr(target_coa,1,instr(target_coa,'.',1,1)-1)  is not null
                  and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = lv_coa_mapid);
				commit;
			exception
				when others then
					dbms_output.put_line('Error with Query:  ' || SQLERRM);
			end;
--            insert into wsc_tbl_time_t (a,b) values ('5',sysdate);
--            commit;
            update
			(
			select user_coa.ERROR_MESSAGE,user_coa.LAST_UPDATE_DATE,
			   user_coa.batch_id, user_coa.target_coa tgt_coa
				  from WSC_GL_ADFDI_COA_MAPPING_T user_coa
				where user_coa.batch_id = p_batch_id
                 and error_message is null
                 and COA_MAP_NAME = (select coa_map_name from wsc_gl_coa_map_t where COA_MAP_ID = lv_coa_mapid)
				 and substr(user_coa.target_coa,1,instr(user_coa.target_coa,'.',1,1)-1)  is null
			)
			set 
			   ERROR_MESSAGE = tgt_coa,
			   LAST_UPDATE_DATE = sysdate;

			
--            insert into wsc_tbl_time_t (a,b) values ('6',sysdate);
--            commit;
		end loop;
        update WSC_GL_USER_COA_MAPPING_H set status='Success', last_update_date = sysdate 
        where HEADER_ID = p_batch_id;
--        update 
        commit;
	end leg_coa_transformation_adfdi; 


END WSC_USER_COA_TRANSFORMATION_PKG;
/