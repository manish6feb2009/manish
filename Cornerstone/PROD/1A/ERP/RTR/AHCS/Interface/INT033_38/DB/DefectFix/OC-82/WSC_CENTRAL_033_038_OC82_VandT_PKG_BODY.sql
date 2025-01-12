create or replace PACKAGE BODY WSC_AHCS_CENTRAL_VALIDATION_TRANSFORMATION_PKG AS

    FUNCTION  "IS_DATE_NULL" ( 
		p_string IN date 
	) RETURN NUMBER IS 
	BEGIN  
		if p_string is null then
            RETURN 0; 
		else
			return 1;
		end if;
	END;

	FUNCTION  "IS_LONG_NULL" ( 
		p_string IN long 
	) RETURN NUMBER IS 
	BEGIN  
		if p_string is null then
			RETURN 0; 
		else
			return 1;
		end if;
	END;

	FUNCTION  "IS_NUMBER_NULL" ( 
		p_string IN NUMBER 
	) RETURN NUMBER IS 
    p_num number;
	BEGIN  
        p_num := to_number(p_string);
		if p_string is not null then
			RETURN 1; 
		else
			return 0;
		end if;
    exception
        when others then
            return 0;
	END;

    FUNCTION "IS_VALUE_ZERO"(
        p_string IN NUMBER
    ) RETURN NUMBER IS
    p_num number;
    BEGIN  
        p_num := IS_NUMBER_NULL(p_string);
        if (p_num = 1) then
            if p_string != 0 then
                RETURN 1; 
            else
                return 0;
            end if;
        else
            RETURN 0;
        end if;
    exception
        when others then
            return 0;
	END;


	FUNCTION  "IS_VARCHAR2_NULL" ( 
		p_string IN VARCHAR2 
	) RETURN NUMBER IS 
	BEGIN  
		if p_string is null then
			RETURN 0; 
		else
			return 1;
		end if;
	END;

    PROCEDURE leg_coa_transformation(p_batch_id IN number,is_reversal IN number default 0) IS
	  -- +====================================================================+
      -- | Name             : transform_staging_data_to_AHCS                  |
      -- | Description      : Transforms data read into the staging tables    |
      -- |                    to AHCS format.                                 |
      -- |                    Following transformation will be applied :-     |
      -- |                    1. Derive future state COA based on legacy COA  |
      -- |                       values in staging tables.                    |
      -- |                    2. Derive the ledger associated with the        |
      -- |                       transaction based on the balancing segment   |
      -- |                                                                    |
      -- |                    Transformation will be performed on the basis   |
      -- |                    of batch_id.                                    |
      -- |                    Every file set (header/line) coming from source |
      -- |                    will be mapped to a unique batch_id             |
      -- |                    This procedure will (based on parameter) will   |
      -- |                    transform all (or reprocess eligible) records   |
      -- |                    from the file.                                  |
      -- +====================================================================+



   ------------------------------------------------------------------------------------------------------------------------------------------------------
   -- The following cursor will retrieve ALL records from lines table that does not target COA combination derived.
   -- All such columns 
   ------------------------------------------------------------------------------------------------------------------------------------------------------
		cursor cur_update_trxn_line_err is 
			select line.batch_id,line.line_id, line.target_coa
			  from WSC_AHCS_CENTRAL_TXN_LINE_T line, WSC_AHCS_INT_STATUS_T status
			 where line.batch_id = p_batch_id
			   and substr(line.target_coa,1,instr(line.target_coa,'.',1,1)-1)  is null
			   and status.batch_id = line.batch_id
			   and status.line_id = line.line_id
			   and status.attribute2 = 'VALIDATION_SUCCESS' ; /*ATTRIBUTE2 */

        type update_trxn_line_err_type is table of cur_update_trxn_line_err%rowtype;
        lv_update_trxn_line_err update_trxn_line_err_type;


        cursor cur_update_trxn_header_err is 
			select distinct status.header_id,status.batch_id
			  from WSC_AHCS_INT_STATUS_T status
			 where status.batch_id = p_batch_id
			   and status.status = 'TRANSFORM_FAILED' ;         

        type update_trxn_header_err_type is table of cur_update_trxn_header_err%rowtype;
        lv_update_trxn_header_err update_trxn_header_err_type;

   ------------------------------------------------------------------------------------------------------------------------------------------------------
   -- Derive the COA map ID for a given source/ target system value.
   -- COA Map ID will subsequently be used to derive the COA mapping rules that are assigned to this source / target combination.
   ------------------------------------------------------------------------------------------------------------------------------------------------------

        cursor cur_coa_map_id is 
			select coa_map_id, coa_map.target_system, coa_map.source_system
			  from wsc_gl_coa_map_t coa_map, WSC_AHCS_INT_CONTROL_T ahcs_control
			 where UPPER(coa_map.source_system) = UPPER(ahcs_control.source_system) 
			   and UPPER(coa_map.target_system) = UPPER(ahcs_control.target_system)
			   and ahcs_control.batch_id = p_batch_id;

   ------------------------------------------------------------------------------------------------------------------------------------------------------
   -- The following cursor will derive the future state COA combination for the given batch_Id for records that have been successfully validated.
   --
   ------------------------------------------------------------------------------------------------------------------------------------------------------

		cursor cur_leg_seg_value(cur_p_src_system varchar2, cur_p_tgt_system varchar2) is 
			select tgt_coa.leg_coa,
			----------------------------------------------------------------------------------------------------------------------------
			/**********  The following package call will derive the future state COA combination for legacy COA combination ***********/
			--

				wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system,cur_p_tgt_system,tgt_coa.leg_seg2,
				tgt_coa.leg_seg3,null,null,null,null,
                  null,null,null,null)  target_coa 
			--
			-- End of function call to derive target COA.
			----------------------------------------------------------------------------------------------------------------------------                	  

		  from (select distinct line.LEG_COA, line.LEG_SEG2, line.LEG_SEG3   /*** Fetches distinct legacy combination values ***/
                from WSC_AHCS_CENTRAL_TXN_LINE_T line, WSC_AHCS_INT_STATUS_T status
               where line.batch_id = p_batch_id and line.target_coa is null
                 and status.batch_id = line.batch_id
                 and status.line_id = line.line_id
                 and status.attribute2 = 'VALIDATION_SUCCESS'  /*** Check if the record has been successfully validated through validate procedure ***/
				) tgt_coa;

		type leg_seg_value_type is table of cur_leg_seg_value%rowtype;
        lv_leg_seg_value leg_seg_value_type;

		-------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
        -- for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------

        cursor cur_inserting_ccid_table is
			select distinct line.LEG_COA LEG_COA, line.TARGET_COA TARGET_COA,line.LEG_SEG2, line.LEG_SEG3,line.LEDGER_NAME
			  from WSC_AHCS_CENTRAL_TXN_LINE_T line
			 where line.batch_id = p_batch_id
			   and line.attribute1 = 'Y'   
			   and substr(line.target_coa,1,instr(line.target_coa,'.',1,1)-1) is not null;  /* Implies that the COA value has been successfully derived from engine */

		type inserting_ccid_table_type is table of cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table inserting_ccid_table_type;

		------------------------------------------------------------------------------------------------------------------------------------------------------
        -- The following cursor picks up the distinct ledger/ legal entities that have been transformed successfully with future state COA values.
	    -- Ledger name is one of the key defaulting attributes required for processing a journal in AHCS.
		------------------------------------------------------------------------------------------------------------------------------------------------------

        cursor cur_get_ledger is 
        with main_data as
        (select lgl_entt.ledger_name, lgl_entt.LEGAL_ENTITY_NAME
                      from wsc_gl_legal_entities_t lgl_entt,
                    (select distinct line.GL_LEGAL_ENTITY from WSC_AHCS_CENTRAL_TXN_LINE_T line, 
                    WSC_AHCS_INT_STATUS_T status 
                        where line.batch_id = status.batch_id
                          and line.line_id = status.line_id
                          and status.batch_id = P_BATCH_ID
                          and status.attribute2 = 'VALIDATION_SUCCESS') d_lgl_entt
                     where lgl_entt.flex_segment_value(+) = d_lgl_entt.GL_LEGAL_ENTITY
                       )
                select * from  main_data a
                where a.ledger_name is not null
                and not exists 
                 (select 1 from main_data b
                     where b.ledger_name is null);

		type get_ledger_type is table of cur_get_ledger%rowtype;
        lv_get_ledger get_ledger_type;

        cursor cur_count_sucss(cur_p_batch_id number) is 
			select count(1) 
			  from WSC_AHCS_INT_STATUS_T 
			 where BATCH_ID = cur_p_batch_id 
			   and attribute2 = 'TRANSFORM_SUCCESS' ;

        lv_coa_mapid number;
        lv_src_system varchar2(100);
        lv_tgt_system varchar2(100);
        lv_count_succ number;
        test1 varchar2(100);

    begin 

        -------------------------------------------------------------------------------------------------------------------------------------------
	--1. Identity the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert (null,p_batch_id,1001,'transforamation start',null,sysdate);

        open cur_coa_map_id;
        fetch cur_coa_map_id into lv_coa_mapid,lv_tgt_system,lv_src_system;
        close cur_coa_map_id;

        logging_insert(null,p_batch_id,1002,'transforamation start',lv_coa_mapid||lv_tgt_system||lv_src_system,sysdate);

--        update target_coa in ap_line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
	--2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert(null,p_batch_id,1003,'Check data in cache table to find ',null,sysdate);

		begin 
            UPDATE WSC_AHCS_CENTRAL_TXN_LINE_T line
               SET TARGET_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa,lv_coa_mapid), LAST_UPDATE_DATE = sysdate
             where batch_id = p_batch_id;
              /* and exists 
				(select /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */ --1 from wsc_gl_ccid_mapping_t ccid_map,WSC_AHCS_INT_STATUS_T status 
				--  where ccid_map.coa_map_id = lv_coa_mapid and line.leg_coa = ccid_map.source_segment
				  ---  and status.batch_id = line.batch_id
				   -- and status.line_id = line.line_id
				  --  and status.status = 'VALIDATION_SUCCESS');
            commit;
        exception 
            when others then
                logging_insert(null,p_batch_id,1004,'Check data in cache table to find',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;

--        update target_coa and attribute1 'Y' in ap_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert(null,p_batch_id,1005,'update target_coa and attribute1',null,sysdate);

		begin
           /* open cur_leg_seg_value(lv_src_system, lv_tgt_system);
            loop
            logging_insert(null,p_batch_id,1005.01,'update target_coa and attribute1 - start',null,sysdate);
            fetch cur_leg_seg_value bulk collect into lv_leg_seg_value limit 400;
            logging_insert(null,p_batch_id,1005.01,'update target_coa and attribute1 - bet1',null,sysdate);
            EXIT WHEN lv_leg_seg_value.COUNT = 0;        
            forall i in 1..lv_leg_seg_value.count
               update WSC_AHCS_CENTRAL_TXN_LINE_T set target_coa = lv_leg_seg_value(i).target_coa,  ATTRIBUTE1 = 'Y', 
                LAST_UPDATE_DATE = sysdate 
                where LEG_COA = lv_leg_seg_value(i).LEG_COA and batch_id = p_batch_id; 

            end loop; */


             update WSC_AHCS_CENTRAL_TXN_LINE_T TGT_COA
            set target_coa = wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system,lv_tgt_system,TGT_COA.leg_seg2,
                            TGT_COA.leg_seg3,null,null,null,null,
                            null,null,null,null) ,  ATTRIBUTE1 = 'Y'  
            where batch_id = p_batch_id
            and target_coa is null
            and exists
            (select /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */  1 from WSC_AHCS_INT_STATUS_T status
            where status.batch_id = p_batch_id 
                             and status.batch_id = TGT_COA.batch_id
                             and status.line_id = TGT_COA.line_id
                             and status.attribute2 = 'VALIDATION_SUCCESS');



            logging_insert(null,p_batch_id,1005.01,'update target_coa and attribute1 - end',null,sysdate);
            commit;
        exception
            when others then
                logging_insert(null,p_batch_id,1006,'update target_coa and attribute1',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;

--        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert(null,p_batch_id,1007,'insert new target_coa values',null,sysdate);
		begin
            open cur_inserting_ccid_table;
            loop
            fetch cur_inserting_ccid_table bulk collect into lv_inserting_ccid_table limit 400;
            EXIT WHEN lv_inserting_ccid_table.COUNT = 0;        
            forall i in 1..lv_inserting_ccid_table.count
                insert into wsc_gl_ccid_mapping_t(CCID_VALUE_ID,COA_MAP_ID, SOURCE_SEGMENT, 
                TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG, UI_FLAG, CREATED_BY, LAST_UPDATED_BY, source_segment1,source_segment2,source_segment3,source_segment4,source_segment5,source_segment6,source_segment7,source_segment8,source_segment9,source_segment10)
                values (wsc_gl_ccid_mapping_s.nextval, lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, 
                lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y', 'N','CENTRAL', 'CENTRAL',lv_inserting_ccid_table(i).LEG_SEG2, lv_inserting_ccid_table(i).LEG_SEG3, null, null, null, null ,null, lv_inserting_ccid_table(i).LEDGER_NAME, null, null);
                --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
            end loop;

			update WSC_AHCS_CENTRAL_TXN_LINE_T set attribute1 = null 
			 where batch_id = p_batch_id;

			commit;
            exception 
            when others then
                logging_insert(null,p_batch_id,1007.1,'Error insert new target_coa values',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;

--      update ap_line table target segments,  where legal_entity must have their in target_coa
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert(null,p_batch_id,1008,'update ap_line table target segments',null,sysdate);

		begin
            update WSC_AHCS_CENTRAL_TXN_LINE_T
            set GL_LEGAL_ENTITY = substr(target_coa,1,instr(target_coa,'.',1,1)-1) ,
				GL_OPER_GRP = substr(target_coa,instr(target_coa,'.',1,1)+1,instr(target_coa,'.',1,2)-instr(target_coa,'.',1,1)-1) ,
				GL_ACCT = substr(target_coa,instr(target_coa,'.',1,2)+1,instr(target_coa,'.',1,3)-instr(target_coa,'.',1,2)-1) ,
				GL_DEPT = substr(target_coa,instr(target_coa,'.',1,3)+1,instr(target_coa,'.',1,4)-instr(target_coa,'.',1,3)-1) ,
				GL_SITE = substr(target_coa,instr(target_coa,'.',1,4)+1,instr(target_coa,'.',1,5)-instr(target_coa,'.',1,4)-1) ,
				GL_IC = substr(target_coa,instr(target_coa,'.',1,5)+1,instr(target_coa,'.',1,6)-instr(target_coa,'.',1,5)-1) ,
				GL_PROJECTS = substr(target_coa,instr(target_coa,'.',1,6)+1,instr(target_coa,'.',1,7)-instr(target_coa,'.',1,6)-1) ,
				GL_FUT_1 = substr(target_coa,instr(target_coa,'.',1,7)+1,instr(target_coa,'.',1,8)-instr(target_coa,'.',1,7)-1) ,
				GL_FUT_2 = substr(target_coa,instr(target_coa,'.',1,8)+1) , 
				LAST_UPDATE_DATE = sysdate
            where batch_id = p_batch_id 
			  and substr(target_coa,1,instr(target_coa,'.',1,1)-1)  is not null;
            commit;
        exception
            when others then
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
                logging_insert(null,p_batch_id,1009,'update ap_line table target segments',SQLERRM,sysdate);
        end;

--        if any target_coa is empty in ap_line table will mark it as transform_error in status table
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert(null,p_batch_id,1010,'if any target_coa is empty',null,sysdate);

        begin
			update
			(
			select status.attribute2,status.attribute1,status.status,status.error_msg,status.last_updated_date,
			   line.batch_id bt_id,line.line_id ln_id, line.target_coa trgt_coa
				  from WSC_AHCS_INT_STATUS_T status,WSC_AHCS_CENTRAL_TXN_LINE_T line
				where line.batch_id = p_batch_id
				 and substr(line.target_coa,1,instr(line.target_coa,'.',1,1)-1)  is null
				 and status.batch_id = line.batch_id
				 and status.line_id = line.line_id
				 and status.attribute2 = 'VALIDATION_SUCCESS'
			)
			set attribute1 = 'L',
			   attribute2= 'TRANSFORM_FAILED',
			   status = 'TRANSFORM_FAILED',
			   error_msg = trgt_coa,
			   last_updated_date = sysdate;
            commit;

--			update WSC_AHCS_INT_STATUS_T a
--               set ATTRIBUTE2 = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = sysdate
--             where exists 
--              (select 1 from WSC_AHCS_INT_STATUS_T b 
--                where a.batch_id = b.batch_id 
--				  and status = 'TRANSFORM_FAILED'
--                  and b.batch_id = p_batch_id );
--            commit;

        exception
            when others then
                logging_insert(null,p_batch_id,1011,'if any target_coa is empty',SQLERRM ||' - LINE: '||$$plsql_unit ||' ' ||$$plsql_line,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);        
        end;

--      update ledger_name in ap_header table where transform_success		
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the linetable 
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert(null,p_batch_id,1012,'update ledger_name',null,sysdate);

         begin

            merge into WSC_AHCS_CENTRAL_TXN_LINE_T line
            using wsc_gl_legal_entities_t gl
            on (line.GL_LEGAL_ENTITY =  gl.flex_segment_value)
            when matched then 
            update set line.ledger_name = gl.LEDGER_NAME,line.DEFAULT_CURRENCY = gl.CURRENCY_CODE, 
            line.ACC_CURRENCY = gl.CURRENCY_CODE
            where batch_id = p_batch_id;  
            /*
            update WSC_AHCS_CENTRAL_TXN_LINE_T line 
               set LEDGER_NAME = (select LEDGER_NAME from wsc_gl_legal_entities_t 
             where flex_segment_value = line.GL_LEGAL_ENTITY) where batch_id = p_batch_id;
             */
            commit;
        exception
            when others then
            logging_insert(null,p_batch_id,31,'update ledger_name',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;


		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert(null,p_batch_id,1014,'Update status tables to have status',null,sysdate);

        begin    

--            update (select sts.ATTRIBUTE2,sts.status,sts.last_updated_date,sts.ERROR_MSG
--                     from WSC_AHCS_INT_STATUS_T sts ,WSC_AHCS_CENTRAL_TXN_LINE_T line
--                    where line.BATCH_ID = P_BATCH_ID 
--                      and line.batch_id = sts.batch_id
--                      and line.LEDGER_NAME is null
--                      and sts.error_msg is NULL
--                   )
--               set ERROR_MSG = 'Ledger derivation failed',
--                   ATTRIBUTE2 = 'TRANSFORM_FAILED',
--                   STATUS = 'TRANSFORM_FAILED', 
--                   LAST_UPDATED_DATE = sysdate;
--            
            update WSC_AHCS_INT_STATUS_T WAIS
               set ERROR_MSG = 'Ledger derivation failed',
                   ATTRIBUTE2 = 'TRANSFORM_FAILED',
                   STATUS = 'TRANSFORM_FAILED', 
                   LAST_UPDATED_DATE = sysdate
             where BATCH_ID = P_BATCH_ID  and 
             exists (select sts.ATTRIBUTE2,sts.status,sts.last_updated_date,sts.ERROR_MSG
                       from WSC_AHCS_INT_STATUS_T sts ,WSC_AHCS_CENTRAL_TXN_LINE_T line
                      where line.BATCH_ID = p_batch_id 
                        and line.line_id = sts.line_id
                        and WAIS.line_id=sts.line_id
                        and line.batch_id = sts.batch_id
                        and line.LEDGER_NAME is null
                        and sts.error_msg is null
                        AND sts.ATTRIBUTE2 = 'VALIDATION_SUCCESS');  


            commit;

            update WSC_AHCS_INT_STATUS_T set STATUS = 'TRANSFORM_SUCCESS', LAST_UPDATED_DATE = sysdate
             where BATCH_ID = P_BATCH_ID 
			   and STATUS = 'VALIDATION_SUCCESS' 
			   and ERROR_MSG is null;
            commit;

            update WSC_AHCS_INT_STATUS_T set Attribute2 = 'TRANSFORM_SUCCESS', LAST_UPDATED_DATE = sysdate
             where BATCH_ID = P_BATCH_ID 
			   and ATTRIBUTE2 = 'VALIDATION_SUCCESS';
            commit;

			-------------------------------------------------------------------------------------------------------------------------------------------
			-- 9. Flag the control table to consider this file as TRANSFORMATION COMPLETE. 
			--    /************ THIS WILL SIGNAL OIC TO PICK THIS FILE FOR UCM UPLOAD BY MASTER SCHEDULER ***********************/
			-------------------------------------------------------------------------------------------------------------------------------------------

			open cur_count_sucss(P_BATCH_ID);
            fetch cur_count_sucss into lv_count_succ;
            close cur_count_sucss;

            if lv_count_succ > 0 then
                    if is_reversal = 0 then
                        wsc_central_pkg.WSC_PROCESS_CENTRAL_HEADER_T_P(P_BATCH_ID);

                        update WSC_AHCS_INT_CONTROL_T 
                        set STATUS = 'TRANSFORM_SUCCESS', LAST_UPDATED_DATE = sysdate
                        WHERE BATCH_ID = P_BATCH_ID ;
                    end if;





            else
               update WSC_AHCS_INT_CONTROL_T 
			      set STATUS = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = sysdate
                WHERE BATCH_ID = P_BATCH_ID ;            
            end if;        
            commit;
        end;
	logging_insert(null,p_batch_id,1015,'end transformation',null,sysdate);

     EXCEPTION
        WHEN OTHERS THEN
            WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(p_batch_id,
                        'INT033',
                        'CENTRAL',
                        SQLERRM);

    end leg_coa_transformation; 

	procedure data_validation(p_batch_id in number) IS	

		lv_header_err_msg varchar2(2000) := null;
		lv_line_err_msg varchar2(2000) := null;
		lv_header_err_flag varchar2(100) := 'false';
		lv_line_err_flag varchar2(100) := 'false';
        lv_count_sucss number := 0;
        is_error boolean := false;
        v_file_ext_date_data varchar2(30);
        v_file_ext_date date;
        v_error_msg varchar2(2000);
        retcode varchar2(100);
        err_msg varchar2(100);

		type wsc_line_col_value_type IS VARRAY(99) OF VARCHAR2(50); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING LINE OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/     
		lv_line_col_value wsc_line_col_value_type := wsc_line_col_value_type('DEFAULT_AMOUNT','ACC_AMT','LEG_COA','LEG_SEG2','LEG_SEG3','JE_CODE','LINE_ID');


/************ @@@@@ INITIALIZE HEADER AND LINE FLAG TABLE TYPE VARIABLES TO MATCH THE COUNT OF HEADER AND LINE @@@@@ ************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        type WSC_AHCS_CENTRAL_TXN_LINE_TYPE IS table OF INTEGER; 
        lv_error_CENTRAL_line WSC_AHCS_CENTRAL_TXN_LINE_TYPE := WSC_AHCS_CENTRAL_TXN_LINE_TYPE('1','1','1','1','1','1','1','1','1','1'); 

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from LINE STAGING TABLETHAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
		CURSOR cur_wsc_central_line(cur_p_batch_id number) is 
			SELECT DEFAULT_AMOUNT,ACC_AMT,LEG_COA,DR_CR_FLAG,BATCH_ID,LINE_ID,LEG_SEG2,LEG_SEG3,WIC,JE_CODE
			  FROM WSC_AHCS_CENTRAL_TXN_LINE_T 
			 where BATCH_ID = cur_p_batch_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/

        cursor cur_skip_lines(cur_p_batch_id number) is
        select line_id
            from WSC_AHCS_CENTRAL_TXN_LINE_T
            where BATCH_ID = cur_p_batch_id
                and (ACC_AMT = 0 OR JE_CODE IS NULL);

        cursor file_ext_date(cur_p_batch_id number) is
            select attribute1 from WSC_AHCS_INT_CONTROL_T
            where BATCH_ID = cur_p_batch_id;

        cursor cur_count_sucss(cur_p_batch_id number) is 
        select count(1) 
		  from WSC_AHCS_INT_STATUS_T 
         where BATCH_ID = cur_p_batch_id 
		   and attribute2 = 'VALIDATION_SUCCESS' ;

        cursor cur_count_line(cur_p_batch_id number) is 
        select count(1) 
		  from WSC_AHCS_CENTRAL_TXN_LINE_T 
         where BATCH_ID = cur_p_batch_id;

         cursor cur_control_total_record(cur_p_batch_id number) is 
        select total_records
		  from WSC_AHCS_INT_CONTROL_T 
         where BATCH_ID = cur_p_batch_id;

         total_records number;
         count_line number;

    Begin		
		logging_insert (null,p_batch_id,1,'Start of validation',null,sysdate);

		------------------------------------------------------------------------------------------------------------------------------------------------
        -- 1. Validate line total records and validate FILE_EXT_DATE format MMDDYY
        --    Checks total number of records present in line table with reference to control table column "TOTAL_RECORDS"
        --    Flag status table as follows:-
        --    a) Overall record status         = VALIDATION_FAILED
        --    b) Re-extract required           = 'Y', implying that the record must be re-extracted.
        --    c) Attribute1                    = 'L', flex attribute,implying this to be a line level failure. 
        --    d) Attribute2                    = VALIDATION FAILED, same as that of the line status.
        --
        --    Note: Irrespective of header or line level failure, the source system will re-extract entire header and lines.
        --          Header & line level flag in ATTRIBUTE1 is ONLY FOR the re-extract notification engine to send that line identifer or
        --          or just the header identifier in the re-extract notification to source. This will optimize and cut down on file size.

        ------------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert (null,p_batch_id,2,'Validate line totals',null,sysdate);
		begin
            open cur_count_line(p_batch_id);
            fetch cur_count_line into count_line;
            close cur_count_line;

            open cur_control_total_record(p_batch_id);
            fetch cur_control_total_record into total_records;
            close cur_control_total_record;

            open file_ext_date(p_batch_id);
                fetch file_ext_date into v_file_ext_date_data;
            close file_ext_date;

            if count_line != total_records then
                update WSC_AHCS_INT_STATUS_T set STATUS = 'VALIDATION_FAILED', 
					ERROR_MSG = 'Total Line Count Mismatch [Line Count: '||count_line||' | Total Records in File: '||total_records||']', 
					REEXTRACT_REQUIRED = 'Y',ATTRIBUTE1 = 'L',ATTRIBUTE2='VALIDATION_FAILED', LAST_UPDATED_DATE = sysdate,
                    LAST_UPDATED_BY = 'DB_CENTRAL_VandT'
				where BATCH_ID = P_BATCH_ID;

                update WSC_AHCS_INT_CONTROL_T set STATUS = 'VALIDATION_FAILED', 
					LAST_UPDATED_DATE = sysdate,
                    LAST_UPDATED_BY = 'DB_CENTRAL_VandT'
				where BATCH_ID = P_BATCH_ID;             

                is_error := true;
            end if;

            if(v_file_ext_date_data is not null) then
                dbms_output.put_line(v_file_ext_date_data);
                v_file_ext_date := to_date(substr(v_file_ext_date_data,1,6),'mmddyy');

                dbms_output.put_line(v_file_ext_date);
            else
                update WSC_AHCS_INT_STATUS_T set STATUS = 'VALIDATION_FAILED', 
					ERROR_MSG = 'FILE_EXT_DATE is null', 
					REEXTRACT_REQUIRED = 'Y',ATTRIBUTE1 = 'L',ATTRIBUTE2='VALIDATION_FAILED', LAST_UPDATED_DATE = sysdate,
                    LAST_UPDATED_BY = 'DB_CENTRAL_VandT'
				where BATCH_ID = P_BATCH_ID;

                update WSC_AHCS_INT_CONTROL_T set STATUS = 'VALIDATION_FAILED', 
					LAST_UPDATED_DATE = sysdate,
                    LAST_UPDATED_BY = 'DB_CENTRAL_VandT'
				where BATCH_ID = P_BATCH_ID;
                is_error := true;
            end if;

            commit;
        exception
            when others then
                logging_insert (null,p_batch_id,3,'exception Validate line totals and FILE_EXT_DATE format',SQLERRM,sysdate);
                dbms_output.put_line(SQLERRM);
                v_error_msg := SQLERRM;
                update WSC_AHCS_INT_STATUS_T set STATUS = 'VALIDATION_FAILED', 
					ERROR_MSG = v_error_msg, 
					REEXTRACT_REQUIRED = 'Y',ATTRIBUTE1 = 'L',ATTRIBUTE2='VALIDATION_FAILED', LAST_UPDATED_DATE = sysdate,
                    LAST_UPDATED_BY = 'DB_CENTRAL_VandT'
				where BATCH_ID = P_BATCH_ID;

                update WSC_AHCS_INT_CONTROL_T set STATUS = 'VALIDATION_FAILED', 
					LAST_UPDATED_DATE = sysdate,
                    LAST_UPDATED_BY = 'DB_CENTRAL_VandT'
				where BATCH_ID = P_BATCH_ID;

                dbms_output.put_line('Error with Query:  ' || SQLERRM);
                is_error :=true;
        end;

        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2. Validate line level fields
        --    Identify line level fields that fail data type mismatch.
        --    Flag status table as follows:-
        --    a) Overall record status         = VALIDATION_FAILED
        --    b) Re-extract required           = 'Y', implying that the record must be re-extracted.
        --    c) Attribute1                    = 'L', flex attribute,implying this to be a line level failure. 
        --    d) Attribute2                    = VALIDATION FAILED, same as that of the line status.
        --
        --    Note: Irrespective of header or line level failure, the source system will re-extract entire header and lines.
        --          Header & line level flag in ATTRIBUTE1 is ONLY FOR the re-extract notification engine to send that line identifer or
        --          or just the header identifier in the re-extract notification to source. This will optimize and cut down on file size.
        ------------------------------------------------------------------------------------------------------------------------------------------------




/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
/**** @@@ Review/ Change function name to match data type of colum. Also pass the appropriate column name from the cursor @@@@ ******/
/**** @@@ Add more rows if there are more columns to be validated and match it with right function names                       ******/
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
    if(is_error = false) then
            logging_insert (null,p_batch_id,4,'check lv_line_err_flag',null,sysdate);
			for wsc_central_line in cur_wsc_central_line(p_batch_id) loop
				lv_line_err_flag := 'false';
				lv_line_err_msg := null;

                --'DEFAULT_AMOUNT','ACC_AMT','LEG_COA','LEG_SEG2','LEG_SEG3','JE_CODE'
                lv_error_central_line := WSC_AHCS_CENTRAL_TXN_LINE_TYPE('1','1','1','1','1','1','1'); 

				lv_error_central_line(1) := IS_NUMBER_NULL(wsc_central_line.DEFAULT_AMOUNT);
				lv_error_central_line(2) := IS_NUMBER_NULL(wsc_central_line.ACC_AMT);
				lv_error_central_line(3) := IS_VARCHAR2_NULL(wsc_central_line.LEG_COA);
				lv_error_central_line(4) := IS_VARCHAR2_NULL(wsc_central_line.LEG_SEG2);
				lv_error_central_line(5) := IS_VARCHAR2_NULL(wsc_central_line.LEG_SEG3);
				lv_error_central_line(6) := IS_VARCHAR2_NULL(wsc_central_line.JE_CODE);
                lv_error_central_line(7) := IS_NUMBER_NULL(wsc_central_line.LINE_ID);

/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
--                logging_insert (null,p_batch_id,10,'lv_error_ap_line',null,sysdate);

				for j in 1..7 loop
					if lv_error_central_line(j) = 0 then
						lv_line_err_msg := lv_line_err_msg || 'error in ' || lv_line_col_value(j) || '. ';
						lv_line_err_flag := 'true';
					end if;
				end loop;
--                logging_insert (null,p_batch_id,11,'lv_error_ap_line',null,sysdate);
                --'Line Skipped because AMT or JE_CODE is null'
				if lv_line_err_flag = 'true' then   
                begin
					update WSC_AHCS_INT_STATUS_T set 
                        STATUS = case when lv_error_central_line(6) = 0 then 'SKIPPED'
                        else 'VALIDATION_FAILED' end, 
						ERROR_MSG = lv_line_err_msg, 
                        REEXTRACT_REQUIRED = case when lv_error_central_line(6) = 0 then ''
                        else 'Y' end,ATTRIBUTE1 = 'L',
                        ATTRIBUTE2=case when lv_error_central_line(6) = 0 then 'SKIPPED'
                        else 'VALIDATION_FAILED' end, 
                        LAST_UPDATED_DATE = sysdate,
                        LAST_UPDATED_BY = 'DB_CENTRAL_VandT'
					 where BATCH_ID = P_BATCH_ID 
					   and LINE_ID = wsc_central_line.LINE_ID;
                       exception
            when others then
                logging_insert (null,p_batch_id,55555555,'exception Validate line totals',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;
				end if;
--                logging_insert (null,p_batch_id,12,'lv_line_err_flag',lv_line_err_flag,sysdate);
			end loop;
		commit;
        end if;
        logging_insert (null,p_batch_id,13,'end',null,sysdate);

    if (is_error = false) then
    begin    
		logging_insert (null,p_batch_id,14,'start updating',null,sysdate);

        update WSC_AHCS_INT_STATUS_T set STATUS = 'VALIDATION_SUCCESS', LAST_UPDATED_DATE = sysdate
         where BATCH_ID = P_BATCH_ID 
		   and STATUS = 'NEW' and ERROR_MSG is null;

        logging_insert (null,p_batch_id,15,'staus updated',null,sysdate);

        update WSC_AHCS_INT_STATUS_T set Attribute2 = 'VALIDATION_SUCCESS', LAST_UPDATED_DATE = sysdate
         where BATCH_ID = P_BATCH_ID 
		   and ATTRIBUTE2 IS NULL;

        logging_insert (null,p_batch_id,16,'attribute 2 updated',null,sysdate);

        open cur_count_sucss(P_BATCH_ID);
            fetch cur_count_sucss into lv_count_sucss;
        close cur_count_sucss;

        logging_insert (null,p_batch_id,17,'count success',lv_count_sucss,sysdate);

        if lv_count_sucss > 0 then
            update WSC_AHCS_INT_CONTROL_T set STATUS = 'VALIDATION_SUCCESS', LAST_UPDATED_DATE = sysdate
             WHERE BATCH_ID = P_BATCH_ID ;
              begin
                WSC_AHCS_CENTRAL_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation(P_BATCH_ID);
              end;
        else
           update WSC_AHCS_INT_CONTROL_T set STATUS = 'VALIDATION_FAILED', LAST_UPDATED_DATE = sysdate
            WHERE BATCH_ID = P_BATCH_ID ;            
        end if;        

        commit;

        logging_insert (null,p_batch_id,18,'end data_validation',null,sysdate);
         logging_insert ('EBS Central',p_batch_id,301,'Dashboard Start',null,sysdate);
        WSC_AHCS_RECON_RECORDS_PKG.REFRESH_VALIDATION_OIC(retcode,err_msg);
        logging_insert ('EBS Central',p_batch_id,302,'Dashboard End',null,sysdate);
    end;    
    end if;
     EXCEPTION
        WHEN OTHERS THEN
            WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(p_batch_id,
                        'INT033',
                        'CENTRAL',
                        SQLERRM);
	end data_validation;



PROCEDURE leg_coa_transformation_reprocessing(p_batch_id IN number) IS
--	  -- +====================================================================+
--      -- | Name             : transform_staging_data_to_AHCS                  |
--      -- | Description      : Transforms data read into the staging tables    |
--      -- |                    to AHCS format.                                 |
--      -- |                    Following transformation will be applied :-     |
--      -- |                    1. Derive future state COA based on legacy COA  |
--      -- |                       values in staging tables.                    |
--      -- |                    2. Derive the ledger associated with the        |
--      -- |                       transaction based on the balancing segment   |
--      -- |                                                                    |
--      -- |                    Transformation will be performed on the basis   |
--      -- |                    of batch_id.                                    |
--      -- |                    Every file set (header/line) coming from source |
--      -- |                    will be mapped to a unique batch_id             |
--      -- |                    This procedure will (based on parameter) will   |
--      -- |                    transform all (or reprocess eligible) records   |
--      -- |                    from the file.                                  |
--      -- +====================================================================+
--
--
--
--   ------------------------------------------------------------------------------------------------------------------------------------------------------
--   -- The following cursor will retrieve ALL records from lines table that does not target COA combination derived.
--   -- All such columns 
--   ------------------------------------------------------------------------------------------------------------------------------------------------------
		cursor cur_update_trxn_line_err is 
			select line.batch_id,line.line_id, line.target_coa
			  from WSC_AHCS_CENTRAL_TXN_LINE_T line, WSC_AHCS_INT_STATUS_T status
			 where line.batch_id = p_batch_id
			   and substr(line.target_coa,1,instr(line.target_coa,'.',1,1)-1)  is null
			   and status.batch_id = line.batch_id
			   and status.line_id = line.line_id
			   and status.attribute2 = 'TRANSFORM_FAILED' ; /*ATTRIBUTE2 */

        type update_trxn_line_err_type is table of cur_update_trxn_line_err%rowtype;
        lv_update_trxn_line_err update_trxn_line_err_type;


--   ------------------------------------------------------------------------------------------------------------------------------------------------------
--   -- Derive the COA map ID for a given source/ target system value.
--   -- COA Map ID will subsequently be used to derive the COA mapping rules that are assigned to this source / target combination.
--   ------------------------------------------------------------------------------------------------------------------------------------------------------
--
		cursor cur_coa_map_id is 
			select coa_map_id, coa_map.target_system, coa_map.source_system
			  from wsc_gl_coa_map_t coa_map, WSC_AHCS_INT_CONTROL_T ahcs_control
			 where UPPER(coa_map.source_system) = UPPER(ahcs_control.source_system) 
			   and UPPER(coa_map.target_system) = UPPER(ahcs_control.target_system)
			   and ahcs_control.batch_id = p_batch_id;

--   ------------------------------------------------------------------------------------------------------------------------------------------------------
--   -- The following cursor will derive the future state COA combination for the given batch_Id for records that have been successfully validated.
--   --
--   ------------------------------------------------------------------------------------------------------------------------------------------------------
--
        cursor cur_leg_seg_value(cur_p_src_system varchar2, cur_p_tgt_system varchar2) is 
			select tgt_coa.leg_coa,
			----------------------------------------------------------------------------------------------------------------------------
			/**********  The following package call will derive the future state COA combination for legacy COA combination ***********/
			--

				wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system,cur_p_tgt_system,tgt_coa.leg_seg2,
				tgt_coa.leg_seg3,null,null,null,null,
                  null,null,null,null)  target_coa 
			--
			-- End of function call to derive target COA.
			----------------------------------------------------------------------------------------------------------------------------                	  

		  from (select distinct line.LEG_COA, line.LEG_SEG2, line.LEG_SEG3   /*** Fetches distinct legacy combination values ***/
                from WSC_AHCS_CENTRAL_TXN_LINE_T line, WSC_AHCS_INT_STATUS_T status
               where line.batch_id = p_batch_id and line.target_coa is null
                 and status.batch_id = line.batch_id
                 and status.line_id = line.line_id
                 and status.attribute2 = 'TRANSFORM_FAILED'  /*** Check if the record has been successfully validated through validate procedure ***/
				) tgt_coa;

		type leg_seg_value_type is table of cur_leg_seg_value%rowtype;
        lv_leg_seg_value leg_seg_value_type;

--
--		-------------------------------------------------------------------------------------------------------------------------------------------
--        -- Following cursor will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
--        -- for the current batch ID
--        -------------------------------------------------------------------------------------------------------------------------------------------
--
		cursor cur_inserting_ccid_table is
			select distinct line.LEG_COA LEG_COA, line.TARGET_COA TARGET_COA, line.LEG_SEG2, line.LEG_SEG3,line.LEDGER_NAME
			  from WSC_AHCS_CENTRAL_TXN_LINE_T line
			 where line.batch_id = p_batch_id
			   and line.attribute1 = 'Y'   
			   and substr(line.target_coa,1,instr(line.target_coa,'.',1,1)-1) is not null;  /* Implies that the COA value has been successfully derived from engine */

		type inserting_ccid_table_type is table of cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table inserting_ccid_table_type;
--
--		------------------------------------------------------------------------------------------------------------------------------------------------------
--        -- The following cursor picks up the distinct ledger/ legal entities that have been transformed successfully with future state COA values.
--	    -- Ledger name is one of the key defaulting attributes required for processing a journal in AHCS.
--		------------------------------------------------------------------------------------------------------------------------------------------------------
--
		cursor cur_get_ledger is 
        with main_data as
        (select lgl_entt.ledger_name, lgl_entt.LEGAL_ENTITY_NAME
                      from wsc_gl_legal_entities_t lgl_entt,
                    (select distinct line.GL_LEGAL_ENTITY from WSC_AHCS_CENTRAL_TXN_LINE_T line, 
                    WSC_AHCS_INT_STATUS_T status 
                        where line.batch_id = status.batch_id
                          and line.line_id = status.line_id
                          and status.batch_id = P_BATCH_ID
                          and status.attribute2 in ('TRANSFORM_FAILED','VALIDATION_SUCCESS')) d_lgl_entt
                     where lgl_entt.flex_segment_value(+) = d_lgl_entt.GL_LEGAL_ENTITY
                       )
                select * from  main_data a
                where a.ledger_name is not null
                and not exists 
                 (select 1 from main_data b
                     where b.ledger_name is null);

		type get_ledger_type is table of cur_get_ledger%rowtype;
        lv_get_ledger get_ledger_type;

        cursor cur_count_sucss(cur_p_batch_id number) is 
			select count(1) 
			  from WSC_AHCS_INT_STATUS_T 
			 where BATCH_ID = cur_p_batch_id 
			   and attribute2 = 'TRANSFORM_SUCCESS' 
			   and (accounting_status is null or accounting_status = 'IMP_ACC_ERROR');
--
--		--- @@@@@@@@@@@@@@@@@@@@@@@@   
--        ------------------------------------------------------------------------------------------------------------------------------------------------
--        -- Following cursor will do a similar matching of total debits and credits but will be restricted at line level. 
--        -- ONLY debit not matching to credit at transaction level will be detected after validation.
--        ------------------------------------------------------------------------------------------------------------------------------------------------
--        /******* @@@@@@@@ Modify this cursor to reflect the appropriate line tables. Also verify the column names are correct @@@@@@@ ********/
--
		cursor cur_line_validation_after_valid(cur_p_batch_id number) is 
			with line_cr as (
			   SELECT header_id,GL_LEGAL_ENTITY, sum(ACC_AMT)*-1 sum_data 
				 FROM WSC_AHCS_CENTRAL_TXN_LINE_T 
				where DR_CR_FLAG = 'CR' 
				  and batch_id = cur_p_batch_id group by header_id,GL_LEGAL_ENTITY),
			   line_dr as (
			   SELECT header_id,GL_LEGAL_ENTITY, sum(ACC_AMT) sum_data 
				 FROM WSC_AHCS_CENTRAL_TXN_LINE_T 
				where DR_CR_FLAG = 'DR' 
				  and batch_id = cur_p_batch_id group by header_id,GL_LEGAL_ENTITY)
			   select l_cr.header_id from line_cr l_cr, line_dr l_dr
			   where l_cr.header_id = l_dr.header_id 
				  and l_dr.GL_LEGAL_ENTITY = l_cr.GL_LEGAL_ENTITY 
				  and (l_dr.sum_data <> l_cr.sum_data );

--		------------------------------------------------------------------------------------------------------------------------------------------------
        cursor cur_to_update_status(cur_p_batch_id number) is
            select b.header_id,b.batch_id
                            from WSC_AHCS_INT_STATUS_T b 
                        where b.status = 'TRANSFORM_FAILED'
                          and b.batch_id = cur_p_batch_id;

		type line_validation_after_valid_type is table of cur_line_validation_after_valid%rowtype;
        lv_line_validation_after_valid line_validation_after_valid_type;
--
--
        lv_coa_mapid number;
        lv_src_system varchar2(100);
        lv_tgt_system varchar2(100);
        lv_count_succ number;
        retcode varchar2(50);
        ERR_MSG varchar2(50);

    begin 
--
--        -------------------------------------------------------------------------------------------------------------------------------------------
--	--1. Identity the COA map corresponding to the source/ target system for the current batch ID (file name)        
--        -------------------------------------------------------------------------------------------------------------------------------------------

        logging_insert ('CENTRAL',p_batch_id,1001,'transforamation start',null,sysdate);

        open cur_coa_map_id;
        fetch cur_coa_map_id into lv_coa_mapid,lv_tgt_system,lv_src_system;
        close cur_coa_map_id;

        logging_insert('CENTRAL',p_batch_id,1002,'transforamation start',lv_coa_mapid||lv_tgt_system||lv_src_system,sysdate);

----        update target_coa in ap_line table where source_segment is already present in ccid table
--        -------------------------------------------------------------------------------------------------------------------------------------------
--	--2. Check data in cache table to find the future state COA combination
--        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
--        -------------------------------------------------------------------------------------------------------------------------------------------
		logging_insert('CENTRAL',p_batch_id,1003,'Check data in cache table to find ',null,sysdate);

		 begin
			update WSC_AHCS_CENTRAL_TXN_LINE_T line
			set target_coa = null,
			    last_update_date = sysdate
           where batch_id = p_batch_id
           and exists ( select 1
                          from WSC_AHCS_INT_STATUS_T status
                            where status.batch_id = p_batch_id
                             and substr(line.target_coa,1,instr(line.target_coa,'.',1,1)-1)  is null
                             and status.batch_id = line.batch_id
                             and status.line_id = line.line_id
                             and status.attribute2 = 'TRANSFORM_FAILED'
                        );

            update WSC_AHCS_INT_STATUS_T status
			set error_msg = null,
           	   last_updated_date = sysdate
           WHERE batch_id = p_batch_id
             and status.attribute2 = 'TRANSFORM_FAILED';

            commit;
        end;

		begin 
            UPDATE WSC_AHCS_CENTRAL_TXN_LINE_T line
               SET TARGET_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa,lv_coa_mapid), LAST_UPDATE_DATE = sysdate
             where batch_id = p_batch_id
               and exists 
				(select /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */1 from wsc_gl_ccid_mapping_t ccid_map,WSC_AHCS_INT_STATUS_T status 
				  where ccid_map.coa_map_id = lv_coa_mapid and line.leg_coa = ccid_map.source_segment
				    and status.batch_id = line.batch_id
				    and status.line_id = line.line_id
				    and status.status = 'TRANSFORM_FAILED');
            commit;
        exception 
            when others then
                logging_insert('CENTRAL',p_batch_id,1004,'Check data in cache table to find',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;
--
----        update target_coa and attribute1 'Y' in ap_line table where distinct leg_coa and target_coa is null      
--        -------------------------------------------------------------------------------------------------------------------------------------------
--        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
--        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
--        -------------------------------------------------------------------------------------------------------------------------------------------
		logging_insert('CENTRAL',p_batch_id,1005,'update target_coa and attribute1',null,sysdate);

		begin
             /* open cur_leg_seg_value(lv_src_system, lv_tgt_system);
            loop
            logging_insert(null,p_batch_id,1005.01,'update target_coa and attribute1 - start',null,sysdate);
            fetch cur_leg_seg_value bulk collect into lv_leg_seg_value limit 400;
            logging_insert(null,p_batch_id,1005.01,'update target_coa and attribute1 - bet1',null,sysdate);
            EXIT WHEN lv_leg_seg_value.COUNT = 0;        
            forall i in 1..lv_leg_seg_value.count
               update WSC_AHCS_CENTRAL_TXN_LINE_T set target_coa = lv_leg_seg_value(i).target_coa,  ATTRIBUTE1 = 'Y', 
                LAST_UPDATE_DATE = sysdate 
                where LEG_COA = lv_leg_seg_value(i).LEG_COA and batch_id = p_batch_id; 

            end loop; */


             update WSC_AHCS_CENTRAL_TXN_LINE_T TGT_COA
            set target_coa = wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system,lv_tgt_system,TGT_COA.leg_seg2,
                            TGT_COA.leg_seg3,null,null,null,null,
                            null,null,null,null) ,  ATTRIBUTE1 = 'Y'  
            where batch_id = p_batch_id
            and target_coa is null
            and exists
            (select /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */  1 from WSC_AHCS_INT_STATUS_T status
            where status.batch_id = p_batch_id 
                             and status.batch_id = TGT_COA.batch_id
                             and status.line_id = TGT_COA.line_id
                             and status.attribute2 = 'TRANSFORM_FAILED');

            logging_insert('CENTRAL',p_batch_id,1005.01,'update target_coa and attribute1 - end',null,sysdate);
            commit;
        exception
            when others then
                logging_insert('CENTRAL',p_batch_id,1006,'update target_coa and attribute1',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;

--
----        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
--		-------------------------------------------------------------------------------------------------------------------------------------------
--        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
--        -------------------------------------------------------------------------------------------------------------------------------------------
		logging_insert('CENTRAL',p_batch_id,1007,'insert new target_coa values',null,sysdate);
		begin
            open cur_inserting_ccid_table;
            loop
            fetch cur_inserting_ccid_table bulk collect into lv_inserting_ccid_table limit 100;
            EXIT WHEN lv_inserting_ccid_table.COUNT = 0;  
            forall i in 1..lv_inserting_ccid_table.count
                insert into wsc_gl_ccid_mapping_t(CCID_VALUE_ID,COA_MAP_ID, SOURCE_SEGMENT, 
                TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG, UI_FLAG,CREATED_BY, LAST_UPDATED_BY, source_segment1,source_segment2,source_segment3,source_segment4,source_segment5,source_segment6,source_segment7,source_segment8,source_segment9,source_segment10)
                values (wsc_gl_ccid_mapping_s.nextval, lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, 
                lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y', 'N','CENTRAL', 'CENTRAL', lv_inserting_ccid_table(i).LEG_SEG2, lv_inserting_ccid_table(i).LEG_SEG3, null, null, null, null ,null, lv_inserting_ccid_table(i).LEDGER_NAME, null, null);
              --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
            end loop;
			close cur_inserting_ccid_table;
			update WSC_AHCS_CENTRAL_TXN_LINE_T set attribute1 = null 
			 where batch_id = p_batch_id;

			commit;
        end;
--
----      update ap_line table target segments,  where legal_entity must have their in target_coa
--		-------------------------------------------------------------------------------------------------------------------------------------------
--        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
--              --cache tables.
--        -------------------------------------------------------------------------------------------------------------------------------------------

		logging_insert('CENTRAL',p_batch_id,1008,'update ap_line table target segments',null,sysdate);

		begin
            update WSC_AHCS_CENTRAL_TXN_LINE_T line
            set GL_LEGAL_ENTITY = substr(target_coa,1,instr(target_coa,'.',1,1)-1) ,
				GL_OPER_GRP = substr(target_coa,instr(target_coa,'.',1,1)+1,instr(target_coa,'.',1,2)-instr(target_coa,'.',1,1)-1) ,
				GL_ACCT = substr(target_coa,instr(target_coa,'.',1,2)+1,instr(target_coa,'.',1,3)-instr(target_coa,'.',1,2)-1) ,
				GL_DEPT = substr(target_coa,instr(target_coa,'.',1,3)+1,instr(target_coa,'.',1,4)-instr(target_coa,'.',1,3)-1) ,
				GL_SITE = substr(target_coa,instr(target_coa,'.',1,4)+1,instr(target_coa,'.',1,5)-instr(target_coa,'.',1,4)-1) ,
				GL_IC = substr(target_coa,instr(target_coa,'.',1,5)+1,instr(target_coa,'.',1,6)-instr(target_coa,'.',1,5)-1) ,
				GL_PROJECTS = substr(target_coa,instr(target_coa,'.',1,6)+1,instr(target_coa,'.',1,7)-instr(target_coa,'.',1,6)-1) ,
				GL_FUT_1 = substr(target_coa,instr(target_coa,'.',1,7)+1,instr(target_coa,'.',1,8)-instr(target_coa,'.',1,7)-1) ,
				GL_FUT_2 = substr(target_coa,instr(target_coa,'.',1,8)+1) , 
				LAST_UPDATE_DATE = sysdate
            where batch_id = p_batch_id 
			  and substr(target_coa,1,instr(target_coa,'.',1,1)-1)  is not null
			  and exists (select 1 from wsc_ahcs_int_status_t sts
                            where sts.line_id = line.line_id
                              and sts.batch_id = line.batch_id
                              and sts.attribute2 = 'TRANSFORM_FAILED');
            commit;
        exception
            when others then
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
                logging_insert('CENTRAL',p_batch_id,1009,'update ap_line table target segments',SQLERRM,sysdate);
        end;
--
----        if any target_coa is empty in ap_line table will mark it as transform_error in status table
--		-------------------------------------------------------------------------------------------------------------------------------------------
--        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
--        --    a. Status          = 'TRANSFORM FAILED'
--        --    b. Error Message   = 'Error message returned from the engine'
--        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
--        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
--        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
--        -------------------------------------------------------------------------------------------------------------------------------------------
		logging_insert('CENTRAL',p_batch_id,1010,'if any target_coa is empty',null,sysdate);

        begin
			update
			(
			select status.attribute2,status.attribute1,status.status,status.error_msg,status.last_updated_date,
			   line.batch_id bt_id,line.line_id ln_id, line.target_coa trgt_coa
				  from WSC_AHCS_INT_STATUS_T status,WSC_AHCS_CENTRAL_TXN_LINE_T line
				where line.batch_id = p_batch_id
				 and substr(line.target_coa,1,instr(line.target_coa,'.',1,1)-1)  is null
				 and status.batch_id = line.batch_id
				 and status.line_id = line.line_id
				 and status.attribute2 in ('VALIDATION_SUCCESS','TRANSFORM_FAILED')
			)
			set attribute1 = 'L',
			   attribute2= 'TRANSFORM_FAILED',
			   status = 'TRANSFORM_FAILED',
			   error_msg = trgt_coa,
			   last_updated_date = sysdate;
            commit;

			for rcur_to_update_status in cur_to_update_status(p_batch_id) LOOP
                update WSC_AHCS_INT_STATUS_T
                set ATTRIBUTE2 = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = sysdate
                where batch_id=rcur_to_update_status.batch_id
                AND header_id=rcur_to_update_status.header_id;
              END LOOP;

--			update WSC_AHCS_INT_STATUS_T a
--               set ATTRIBUTE2 = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = sysdate
--             where exists 
--              (select 1 from WSC_AHCS_INT_STATUS_T b 
--                where a.batch_id = b.batch_id 
--				  and status = 'TRANSFORM_FAILED'
--                  and b.batch_id = p_batch_id );
            commit;

        exception
            when others then
                logging_insert('CENTRAL',p_batch_id,1011,'if any target_coa is empty',SQLERRM ||' - LINE: '||$$plsql_unit ||' ' ||$$plsql_line,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);        
        end;
--
----      update ledger_name in ap_header table where transform_success		
--		-------------------------------------------------------------------------------------------------------------------------------------------
--        -- 7. Update ledger name column in the header staging table 
--        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('CENTRAL',p_batch_id,1012,'update ledger_name',null,sysdate);

        begin

            merge into WSC_AHCS_CENTRAL_TXN_LINE_T line
            using wsc_gl_legal_entities_t gl
            on (line.GL_LEGAL_ENTITY =  gl.flex_segment_value)
            when matched then 
            update set line.ledger_name = gl.LEDGER_NAME,line.DEFAULT_CURRENCY = gl.CURRENCY_CODE, 
            line.ACC_CURRENCY = gl.CURRENCY_CODE
            where batch_id = p_batch_id;  
            /*
            update WSC_AHCS_CENTRAL_TXN_LINE_T line 
               set LEDGER_NAME = (select LEDGER_NAME from wsc_gl_legal_entities_t 
             where flex_segment_value = line.GL_LEGAL_ENTITY) where batch_id = p_batch_id;
             */
            commit;
        exception
            when others then
            logging_insert(null,p_batch_id,31,'update ledger_name',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;

--		-------------------------------------------------------------------------------------------------------------------------------------------
--        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
--        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
--        -------------------------------------------------------------------------------------------------------------------------------------------
logging_insert(null,p_batch_id,1014,'Update status tables to have status',null,sysdate);

        begin    

--            update (select sts.ATTRIBUTE2,sts.status,sts.last_updated_date,sts.ERROR_MSG
--                     from WSC_AHCS_INT_STATUS_T sts ,WSC_AHCS_CENTRAL_TXN_LINE_T line
--                    where line.BATCH_ID = P_BATCH_ID 
--                      and line.batch_id = sts.batch_id
--                      and line.LEDGER_NAME is null
--                      and sts.error_msg is NULL
--                   )
--               set ERROR_MSG = 'Ledger derivation failed',
--                   ATTRIBUTE2 = 'TRANSFORM_FAILED',
--                   STATUS = 'TRANSFORM_FAILED', 
--                   LAST_UPDATED_DATE = sysdate;
--            
            update WSC_AHCS_INT_STATUS_T WAIS
               set ERROR_MSG = 'Ledger derivation failed',
                   ATTRIBUTE2 = 'TRANSFORM_FAILED',
                   STATUS = 'TRANSFORM_FAILED', 
                   LAST_UPDATED_DATE = sysdate
             where BATCH_ID = P_BATCH_ID  and 
             exists (select sts.ATTRIBUTE2,sts.status,sts.last_updated_date,sts.ERROR_MSG
                       from WSC_AHCS_INT_STATUS_T sts ,WSC_AHCS_CENTRAL_TXN_LINE_T line
                      where line.BATCH_ID = p_batch_id 
                        and line.line_id = sts.line_id
                        and WAIS.line_id=sts.line_id
                        and line.batch_id = sts.batch_id
                        and line.LEDGER_NAME is null
                        and sts.error_msg is null
                        AND sts.ATTRIBUTE2 in ('VALIDATION_SUCCESS','TRANSFORM_FAILED'));  


            commit;

            update WSC_AHCS_INT_STATUS_T set STATUS = 'TRANSFORM_SUCCESS', LAST_UPDATED_DATE = sysdate
             where BATCH_ID = P_BATCH_ID 
			   and STATUS in ('VALIDATION_SUCCESS' ,'TRANSFORM_FAILED')
			   and ERROR_MSG is null;
            commit;

            update WSC_AHCS_INT_STATUS_T set Attribute2 = 'TRANSFORM_SUCCESS', LAST_UPDATED_DATE = sysdate
             where BATCH_ID = P_BATCH_ID 
			   and ATTRIBUTE2 in ('VALIDATION_SUCCESS' ,'TRANSFORM_FAILED')
			   and ERROR_MSG is null;
            commit;
--
--			-------------------------------------------------------------------------------------------------------------------------------------------
--			-- 9. Flag the control table to consider this file as TRANSFORMATION COMPLETE. 
--			--    /************ THIS WILL SIGNAL OIC TO PICK THIS FILE FOR UCM UPLOAD BY MASTER SCHEDULER ***********************/
--			-------------------------------------------------------------------------------------------------------------------------------------------
--
			open cur_count_sucss(P_BATCH_ID);
            fetch cur_count_sucss into lv_count_succ;
            close cur_count_sucss;

            if lv_count_succ > 0 then

                wsc_central_pkg.WSC_PROCESS_CENTRAL_HEADER_T_P(P_BATCH_ID);

                update WSC_AHCS_INT_CONTROL_T 
				   set STATUS = 'TRANSFORM_SUCCESS', LAST_UPDATED_DATE = sysdate
                 WHERE BATCH_ID = P_BATCH_ID ;



            else
               update WSC_AHCS_INT_CONTROL_T 
			      set STATUS = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = sysdate
                WHERE BATCH_ID = P_BATCH_ID ;            
            end if;        
            commit;
        end;
	logging_insert('CENTRAL',p_batch_id,1015,'end transformation',null,sysdate);

	logging_insert ('CENTRAL',p_batch_id,303,'Dashboard Start',null,sysdate);

	WSC_AHCS_RECON_RECORDS_PKG.REFRESH_VALIDATION_OIC(retcode,err_msg);

	logging_insert ('CENTRAL',p_batch_id,304,'Dashboard End',null,sysdate);

	logging_insert('CENTRAL',p_batch_id,23,'end transformation',null,sysdate);

    EXCEPTION
        WHEN OTHERS THEN
            WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(p_batch_id,
                        'INT033',
                        'CENTRAL',
                        SQLERRM);
    end leg_coa_transformation_reprocessing;     

END WSC_AHCS_CENTRAL_VALIDATION_TRANSFORMATION_PKG;
/