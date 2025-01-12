create or replace PACKAGE BODY          "WSC_AHCS_AR_VALIDATION_TRANSFORMATION_PKG" IS
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

    PROCEDURE leg_coa_transformation(p_batch_id IN number) IS
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
			select line.batch_id,line.header_id,line.line_id, line.target_coa
			  from WSC_AHCS_AR_TXN_LINE_T line, WSC_AHCS_INT_STATUS_T status
			 where line.batch_id = p_batch_id
			   and substr(line.target_coa,1,instr(line.target_coa,'.',1,1)-1)  is null
			   and status.batch_id = line.batch_id
			   and status.header_id = line.header_id
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

				wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system,cur_p_tgt_system,tgt_coa.leg_seg1,
				tgt_coa.leg_seg2,tgt_coa.leg_seg3,tgt_coa.leg_seg4,tgt_coa.leg_seg5,tgt_coa.leg_seg6,
				tgt_coa.leg_seg7,tgt_coa.leg_led_name,null,null) target_coa 
			--
			-- End of function call to derive target COA.
			----------------------------------------------------------------------------------------------------------------------------                	  

		  from (select distinct line.LEG_COA, line.LEG_SEG1, line.LEG_SEG2, line.LEG_SEG3,   /*** Fetches distinct legacy combination values ***/
					line.LEG_SEG4, line.LEG_SEG5, line.LEG_SEG6, line.LEG_SEG7,header.leg_led_name  
                from WSC_AHCS_AR_TXN_LINE_T line, WSC_AHCS_INT_STATUS_T status, WSC_AHCS_AR_TXN_HEADER_T header
               where status.batch_id = p_batch_id and line.target_coa is null
                 and status.batch_id = line.batch_id
                 and status.header_id = line.header_id
                 and status.line_id = line.line_id
				 and header.batch_id = status.batch_id
                 and header.header_id = status.header_id
                 and header.header_id = line.header_id
                 and header.batch_id = line.batch_id
                 and status.attribute2 = 'VALIDATION_SUCCESS'  /*** Check if the record has been successfully validated through validate procedure ***/
				) tgt_coa;

		type leg_seg_value_type is table of cur_leg_seg_value%rowtype;
        lv_leg_seg_value leg_seg_value_type;

		-------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
        -- for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------

		cursor cur_inserting_ccid_table is
			select distinct line.LEG_COA/*||'.'||header.LEG_LED_NAME*/ LEG_COA, line.TARGET_COA TARGET_COA, line.LEG_SEG1, line.LEG_SEG2, line.LEG_SEG3, line.LEG_SEG4, line.LEG_SEG5, line.LEG_SEG6, line.LEG_SEG7, substr(line.LEG_COA,instr(line.LEG_COA,'.',1,7)+1) as ledger_name
			  from WSC_AHCS_AR_TXN_LINE_T line
--              , WSC_AHCS_AR_TXN_HEADER_T header
			 where line.batch_id = p_batch_id 
--			   and line.batch_id = header.batch_id
--			   and line.header_id = header.header_id
			   and line.attribute1 = 'Y'   
			   and substr(line.target_coa,1,instr(line.target_coa,'.',1,1)-1) is not null;  /* Implies that the COA value has been successfully derived from engine */

        /*
		cursor cur_inserting_ccid_table is
			select distinct LEG_COA, TARGET_COA from WSC_AHCS_AR_TXN_LINE_T
			 where batch_id = p_batch_id 
			   and attribute1 = 'Y'   
			   and substr(target_coa,1,instr(target_coa,'.',1,1)-1) is not null;  
	    */
		type inserting_ccid_table_type is table of cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table inserting_ccid_table_type;

		------------------------------------------------------------------------------------------------------------------------------------------------------
        -- The following cursor picks up the distinct ledger/ legal entities that have been transformed successfully with future state COA values.
	    -- Ledger name is one of the key defaulting attributes required for processing a journal in AHCS.
		------------------------------------------------------------------------------------------------------------------------------------------------------

        cursor cur_get_ledger is 
        with main_data as
			(select lgl_entt.ledger_name, lgl_entt.LEGAL_ENTITY_NAME, d_lgl_entt.header_id
			  from wsc_gl_legal_entities_t lgl_entt,
			(select distinct line.GL_LEGAL_ENTITY, line.header_id from WSC_AHCS_AR_TXN_LINE_T line, WSC_AHCS_INT_STATUS_T status 
				where line.header_id = status.header_id
				  and line.batch_id = status.batch_id
				  and line.line_id = status.line_id
				  and status.batch_id = p_batch_id
				  and status.attribute2 = 'VALIDATION_SUCCESS') d_lgl_entt
			 where lgl_entt.flex_segment_value(+) = d_lgl_entt.GL_LEGAL_ENTITY
             )
             select * from  main_data a
                where a.ledger_name is not null
                and not exists 
                 (select 1 from main_data b
                   where a.header_id = b.header_id
                     and b.ledger_name is null);

		type get_ledger_type is table of cur_get_ledger%rowtype;
        lv_get_ledger get_ledger_type;

        cursor cur_count_sucss(cur_p_batch_id number) is 
			select count(1) 
			  from WSC_AHCS_INT_STATUS_T 
			 where BATCH_ID = cur_p_batch_id 
			   and attribute2 = 'TRANSFORM_SUCCESS' ;


		--- @@@@@@@@@@@@@@@@@@@@@@@@   
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will do a similar matching of total debits and credits but will be restricted at line level. 
        -- ONLY debit not matching to credit at transaction level will be detected after validation.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        /******* @@@@@@@@ Modify this cursor to reflect the appropriate line tables. Also verify the column names are correct @@@@@@@ ********/

		cursor cur_line_validation_after_valid(cur_p_batch_id number) is 
			with line_cr as (
			   SELECT header_id,GL_LEGAL_ENTITY, sum(ACC_AMT)*-1 sum_data 
				 FROM WSC_AHCS_AR_TXN_LINE_T 
				where DR_CR_FLAG = 'CR' 
				  and batch_id = cur_p_batch_id group by header_id,GL_LEGAL_ENTITY),
			   line_dr as (
			   SELECT header_id,GL_LEGAL_ENTITY, sum(ACC_AMT) sum_data 
				 FROM WSC_AHCS_AR_TXN_LINE_T 
				where DR_CR_FLAG = 'DR' 
				  and batch_id = cur_p_batch_id group by header_id,GL_LEGAL_ENTITY)
			   select l_cr.header_id from line_cr l_cr, line_dr l_dr
			   where l_cr.header_id = l_dr.header_id 
				  and l_dr.GL_LEGAL_ENTITY = l_cr.GL_LEGAL_ENTITY 
				  and (l_dr.sum_data <> l_cr.sum_data );

		------------------------------------------------------------------------------------------------------------------------------------------------

          cursor cur_to_update_status(cur_p_batch_id number) is
            select b.header_id,b.batch_id
                            from WSC_AHCS_INT_STATUS_T b 
                        where b.status = 'TRANSFORM_FAILED'
                          and b.batch_id = cur_p_batch_id;


		type line_validation_after_valid_type is table of cur_line_validation_after_valid%rowtype;
        lv_line_validation_after_valid line_validation_after_valid_type;


        lv_coa_mapid number;
        lv_src_system varchar2(100);
        lv_tgt_system varchar2(100);
        lv_count_succ number;

    begin 

        -------------------------------------------------------------------------------------------------------------------------------------------
	--1. Identity the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert ('EBS AR',p_batch_id,19,'transformation start',null,sysdate);

        open cur_coa_map_id;
        fetch cur_coa_map_id into lv_coa_mapid,lv_tgt_system,lv_src_system;
        close cur_coa_map_id;

        logging_insert('EBS AR',p_batch_id,20,'transformation start',lv_coa_mapid||lv_tgt_system||lv_src_system,sysdate);

--        update target_coa in ar_line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
	--2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS AR',p_batch_id,13,'Check data in cache table to find ',null,sysdate);

		begin 
            UPDATE WSC_AHCS_AR_TXN_LINE_T line
               SET TARGET_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa,lv_coa_mapid), LAST_UPDATE_DATE = sysdate
             where batch_id = p_batch_id
               /*and exists 
				(select 1 from /* wsc_gl_ccid_mapping_t ccid_map,*/
                /*WSC_AHCS_INT_STATUS_T status 
				  where /*ccid_map.coa_map_id = lv_coa_mapid and line.leg_coa = ccid_map.source_segment
				    and status.batch_id = line.batch_id
				    and status.header_id = line.header_id
				    and status.line_id = line.line_id
				    and status.status = 'VALIDATION_SUCCESS'
                    and status.attribute2 = 'VALIDATION_SUCCESS')*/;
            commit;
        exception 
            when others then
             logging_insert('EBS AR',p_batch_id,22,'Check data in cache table to find',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;

--        update target_coa and attribute1 'Y' in ar_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS AR',p_batch_id,17,'update target_coa and attribute1',null,sysdate);
		begin
        /*    open cur_leg_seg_value(lv_src_system, lv_tgt_system);
            loop
            fetch cur_leg_seg_value bulk collect into lv_leg_seg_value limit 100;
            EXIT WHEN lv_leg_seg_value.COUNT = 0;        
            forall i in 1..lv_leg_seg_value.count
                update WSC_AHCS_AR_TXN_LINE_T set target_coa = lv_leg_seg_value(i).target_coa,  ATTRIBUTE1 = 'Y', 
                LAST_UPDATE_DATE = sysdate 
                where LEG_COA = lv_leg_seg_value(i).LEG_COA and batch_id = p_batch_id;
            end loop;
            close cur_leg_seg_value; */

           update WSC_AHCS_AR_TXN_LINE_T TGT_COA
            set target_coa = wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system,lv_tgt_system,TGT_COA.leg_seg1,
                            TGT_COA.leg_seg2,TGT_COA.leg_seg3,TGT_COA.leg_seg4,TGT_COA.leg_seg5,TGT_COA.leg_seg6,
                            TGT_COA.leg_seg7,substr(leg_coa,instr(leg_coa,'.',1,7)+1),null,null) ,  ATTRIBUTE1 = 'Y'  
            where batch_id = p_batch_id
            and target_coa is null
            and exists
            (select /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */  1 from WSC_AHCS_INT_STATUS_T status
            where status.batch_id = p_batch_id 
                             and status.batch_id = TGT_COA.batch_id
                             and status.header_id = TGT_COA.header_id
                             and status.line_id = TGT_COA.line_id
                             and status.attribute2 = 'VALIDATION_SUCCESS');


            commit;
        exception
            when others then
            logging_insert('EBS AR',p_batch_id,24,'update target_coa and attribute1',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;

--        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS AR',p_batch_id,16,'insert new target_coa values',null,sysdate);
		begin
            open cur_inserting_ccid_table;
            loop
            fetch cur_inserting_ccid_table bulk collect into lv_inserting_ccid_table limit 100;
            EXIT WHEN lv_inserting_ccid_table.COUNT = 0;        
            forall i in 1..lv_inserting_ccid_table.count
                insert into wsc_gl_ccid_mapping_t(CCID_VALUE_ID,COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG, UI_FLAG,CREATED_BY, LAST_UPDATED_BY,source_segment1,source_segment2,source_segment3,source_segment4,source_segment5,source_segment6,source_segment7,source_segment8,source_segment9,source_segment10)
                values (wsc_gl_ccid_mapping_s.nextval,lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y', 'N', 'EBS AR', 'EBS AR', lv_inserting_ccid_table(i).LEG_SEG1, lv_inserting_ccid_table(i).LEG_SEG2, lv_inserting_ccid_table(i).LEG_SEG3, lv_inserting_ccid_table(i).LEG_SEG4, lv_inserting_ccid_table(i).LEG_SEG5, lv_inserting_ccid_table(i).LEG_SEG6, lv_inserting_ccid_table(i).LEG_SEG7, lv_inserting_ccid_table(i).ledger_name, null, null );
                --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
            end loop;
            close cur_inserting_ccid_table;
         EXCEPTION 
            WHEN OTHERS THEN
                NULL;
            END;
			update WSC_AHCS_AR_TXN_LINE_T set attribute1 = null 
			 where batch_id = p_batch_id;

			commit;
        

--      update ar_line table target segments,  where legal_entity must have their in target_coa
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS AR',p_batch_id,18,'update ar_line table target segments',null,sysdate);
		begin
            update WSC_AHCS_AR_TXN_LINE_T
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
                logging_insert('EBS AR',p_batch_id,27,'update ar_line table target segments',SQLERRM,sysdate);
        end;

--        if any target_coa is empty in ar_line table will mark it as transform_error in status table
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
             logging_insert('EBS AR',p_batch_id,19,'if any target_coa is empty',null,sysdate);

        begin

			update
			(
			select status.attribute2,status.attribute1,status.status,status.error_msg,status.last_updated_date,
			   line.batch_id bt_id,line.header_id hdr_id,line.line_id ln_id, line.target_coa trgt_coa
				  from WSC_AHCS_INT_STATUS_T status,WSC_AHCS_AR_TXN_LINE_T line
				where status.batch_id = p_batch_id
				 and substr(line.target_coa,1,instr(line.target_coa,'.',1,1)-1)  is null
				 and status.batch_id = line.batch_id
				 and status.header_id = line.header_id
				 and status.line_id = line.line_id
				 and status.attribute2 = 'VALIDATION_SUCCESS'
			)
			set attribute1 = 'L',
			   attribute2= 'TRANSFORM_FAILED',
			   status = 'TRANSFORM_FAILED',
			   error_msg = trgt_coa,
			   last_updated_date = sysdate;
            commit;

logging_insert('EBS AR',p_batch_id,19.1,'updated attribute2 with TRANSFORM_FAILED status',null,sysdate);

          for rcur_to_update_status in cur_to_update_status(p_batch_id) LOOP
                update WSC_AHCS_INT_STATUS_T
                set ATTRIBUTE2 = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = sysdate
                where batch_id=rcur_to_update_status.batch_id
                AND header_id=rcur_to_update_status.header_id;
              END LOOP; 

			/*update WSC_AHCS_INT_STATUS_T a
               set ATTRIBUTE2 = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = sysdate
             where a.batch_id = p_batch_id
               and exists 
              (select 1 from WSC_AHCS_INT_STATUS_T b 
                where a.batch_id = b.batch_id 
				  and a.header_id = b.header_id 
				  and b.status = 'TRANSFORM_FAILED'
                  and b.batch_id = p_batch_id );*/
            commit;

        exception
            when others then
            logging_insert('EBS AR',p_batch_id,29,'if any target_coa is empty',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;

--      update ledger_name in ar_header table where transform_success		
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS AR',p_batch_id,20,'update ledger_name',null,sysdate);

        begin
           /* open cur_get_ledger;
            loop
            fetch cur_get_ledger bulk collect into lv_get_ledger limit 100;
            EXIT WHEN lv_get_ledger.COUNT = 0;        
            forall i in 1..lv_get_ledger.count
                update WSC_AHCS_AR_TXN_HEADER_T
                   set ledger_name = lv_get_ledger(i).ledger_name , LAST_UPDATE_DATE = sysdate
                 where batch_id = p_batch_id 
				   and header_id = lv_get_ledger(i).header_id;
            end loop; */
            MERGE INTO WSC_AHCS_AR_TXN_HEADER_T hdr
            USING (with main_data as
                (select /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE) */  lgl_entt.ledger_name, lgl_entt.LEGAL_ENTITY_NAME, d_lgl_entt.header_id
                              from wsc_gl_legal_entities_t lgl_entt,
                            (select /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I,batch_status wsc_ahcs_int_status_batch_id_i)  */  line.GL_LEGAL_ENTITY, line.header_id from WSC_AHCS_AR_TXN_LINE_T line, WSC_AHCS_INT_STATUS_T status 
                                where line.header_id = status.header_id
                                  and line.batch_id = status.batch_id
                                  and line.line_id = status.line_id
                                  and status.batch_id = p_batch_id
                                  and status.attribute2 = 'VALIDATION_SUCCESS') d_lgl_entt
                             where lgl_entt.flex_segment_value = d_lgl_entt.GL_LEGAL_ENTITY
                               )
                        select DISTINCT A.LEDGER_NAME,a.header_id from  main_data a
                        where a.ledger_name is not null
                        ) e
            ON (e.header_id = hdr.header_id)
          WHEN MATCHED THEN
            UPDATE SET hdr.ledger_name = e.ledger_name;

            MERGE INTO WSC_AHCS_AR_TXN_HEADER_T hdr
            USING (with main_data as
                (select /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE) */  distinct lgl_entt.ledger_name, lgl_entt.LEGAL_ENTITY_NAME, d_lgl_entt.header_id
                              from wsc_gl_legal_entities_t lgl_entt,
                            (select /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I,batch_status wsc_ahcs_int_status_batch_id_i)  */  line.GL_LEGAL_ENTITY, line.header_id from WSC_AHCS_AR_TXN_LINE_T line, WSC_AHCS_INT_STATUS_T status 
                                where line.header_id = status.header_id
                                  and line.batch_id = status.batch_id
                                  and line.line_id = status.line_id
                                  and status.batch_id = p_batch_id
                                  and status.attribute2 = 'VALIDATION_SUCCESS') d_lgl_entt
                             where lgl_entt.flex_segment_value(+) = d_lgl_entt.GL_LEGAL_ENTITY
                               )
                        select DISTINCT A.LEDGER_NAME,a.header_id from  main_data a
                        where a.ledger_name is null
                        ) e
            ON (e.header_id = hdr.header_id)
          WHEN MATCHED THEN
            UPDATE SET hdr.ledger_name = e.ledger_name;

            commit;
        exception
            when others then
            logging_insert('EBS AR',p_batch_id,31,'update ledger_name',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;

		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7.1. Update status tables after validation where line cr/dr mismatch.
        --    /******* ALL RECORDS MARKED AS VALIDATION FAILED WHEN LINE CR/DR AMOUNT MISMATCH AFTER VALIDATION ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
		logging_insert('EBS AR',p_batch_id,21,'Update status tables after validation',null,sysdate);

	/*	begin
            open cur_line_validation_after_valid(p_batch_id);
            loop
            fetch cur_line_validation_after_valid bulk collect into lv_line_validation_after_valid limit 100;
            EXIT WHEN lv_line_validation_after_valid.COUNT = 0;        
            forall i in 1..lv_line_validation_after_valid.count
				update WSC_AHCS_INT_STATUS_T set STATUS = 'VALIDATION_FAILED', 
					ERROR_MSG = 'Line DR/CR amount mismatch after validation', 
					ATTRIBUTE1 = 'L',
					ATTRIBUTE2='VALIDATION_FAILED', 
					LAST_UPDATED_DATE = sysdate
				where BATCH_ID = P_BATCH_ID 
				  and HEADER_ID = lv_line_validation_after_valid(i).header_id;
            end loop;
            commit;
        exception
            when others then
            logging_insert('EBS AR',p_batch_id,33,'Update status tables after validation',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;
*/
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
       logging_insert('EBS AR',p_batch_id,22,'Update status tables to have status',null,sysdate);

        begin    

    update (select sts.ATTRIBUTE2,sts.status,sts.last_updated_date,STS.ERROR_MSG
                     from WSC_AHCS_INT_STATUS_T sts ,WSC_AHCS_AR_TXN_HEADER_T hdr
                    where sts.BATCH_ID = P_BATCH_ID 
                      and hdr.header_id = sts.header_id
                      and hdr.batch_id = sts.batch_id
                      and hdr.ledger_name is null
                      AND sts.error_msg is NULL
                      AND sts.attribute2 = 'VALIDATION_SUCCESS'
                   )
               set ERROR_MSG = 'Ledger derivation failed',ATTRIBUTE2 = 'TRANSFORM_FAILED',STATUS = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = sysdate
             ;

            update WSC_AHCS_INT_STATUS_T set STATUS = 'TRANSFORM_SUCCESS', LAST_UPDATED_DATE = sysdate
             where BATCH_ID = P_BATCH_ID 
			   and STATUS = 'VALIDATION_SUCCESS' 
               and attribute2 = 'VALIDATION_SUCCESS' 
			   and ERROR_MSG is null;
            commit;

            update WSC_AHCS_INT_STATUS_T set Attribute2 = 'TRANSFORM_SUCCESS', LAST_UPDATED_DATE = sysdate
             where BATCH_ID = P_BATCH_ID 
			   and ATTRIBUTE2 = 'VALIDATION_SUCCESS'
                and ERROR_MSG is null;
            commit;

			-------------------------------------------------------------------------------------------------------------------------------------------
			-- 9. Flag the control table to consider this file as TRANSFORMATION COMPLETE. 
			--    /************ THIS WILL SIGNAL OIC TO PICK THIS FILE FOR UCM UPLOAD BY MASTER SCHEDULER ***********************/
			-------------------------------------------------------------------------------------------------------------------------------------------

			open cur_count_sucss(P_BATCH_ID);
            fetch cur_count_sucss into lv_count_succ;
            close cur_count_sucss;

            if lv_count_succ > 0 then
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
logging_insert('EBS AR',p_batch_id,23,'end transformation',null,sysdate);
EXCEPTION
        WHEN OTHERS THEN
            WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(p_batch_id,
                        'INT005',
                        'EBS_AR',
                        SQLERRM); 
    end leg_coa_transformation; 

	procedure data_validation(p_batch_id in number) IS	

		lv_header_err_msg varchar2(2000) := null;
		lv_line_err_msg varchar2(2000) := null;
		lv_header_err_flag varchar2(100) := 'false';
		lv_line_err_flag varchar2(100) := 'false';
        lv_count_sucss number := 0;
         retcode NUMBER;

		type wsc_header_col_value_type IS VARRAY(20) OF VARCHAR2(50); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING HEADER OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
		lv_header_col_value wsc_header_col_value_type := wsc_header_col_value_type('SOURCE_TRN_NBR','SOURCE_SYSTEM','LEG_HEADER_ID','TRD_PARTNER_NAME','TRD_PARTNER_NBR','TRD_PARTNER_SITE','EVENT_TYPE','EVENT_CLASS','TRN_AMOUNT','ACC_DATE','HEADER_DESC','LEG_LED_NAME','JE_BATCH_NAME','JE_NAME','JE_CATEGORY','FILE_NAME', 'TRANSACTION_TYPE');

		type wsc_line_col_value_type IS VARRAY(20) OF VARCHAR2(50); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING LINE OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/     
		lv_line_col_value wsc_line_col_value_type := wsc_line_col_value_type('SOURCE_TRN_NBR','LEG_HEADER_ID','ENTERED_AMOUNT','ACC_AMT','ENTERED_CURRENCY','ACC_CURRENCY','LEG_SEG1','LEG_SEG2','LEG_SEG3','LEG_SEG4','LEG_SEG5','LEG_SEG6','LEG_SEG7','ACC_CLASS','DR_CR_FLAG','LEG_AE_LINE_NBR','JE_LINE_NBR','LINE_DESC','FX_RATE');


/************ @@@@@ INITIALIZE HEADER AND LINE FLAG TABLE TYPE VARIABLES TO MATCH THE COUNT OF HEADER AND LINE @@@@@ ************/
--/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        type WSC_AHCS_AR_TXN_HEADER_TYPE IS table OF INTEGER; 
        lv_error_ar_header WSC_AHCS_AR_TXN_HEADER_TYPE := WSC_AHCS_AR_TXN_HEADER_TYPE('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'); 
        type WSC_AHCS_AR_TXN_LINE_TYPE IS table OF INTEGER; 
        lv_error_ar_line WSC_AHCS_AR_TXN_LINE_TYPE := WSC_AHCS_AR_TXN_LINE_TYPE('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'); 


-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from LINE STAGING TABLETHAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
		CURSOR cur_wsc_ar_line(cur_p_hdr_id varchar2) is 
			SELECT SOURCE_TRN_NBR,LEG_AE_HEADER_ID,DEFAULT_AMOUNT,ACC_AMT,DEFAULT_CURRENCY,ACC_CURRENCY,LEG_SEG1,LEG_SEG2,
			LEG_SEG3,LEG_SEG4,LEG_SEG5,LEG_SEG6,LEG_SEG7,ACC_CLASS,DR_CR_FLAG,LEG_AE_LINE_NBR,JE_LINE_NBR,LINE_DESC,FX_RATE, LINE_ID
			  FROM WSC_AHCS_AR_TXN_LINE_T 
			 where HEADER_ID = cur_p_hdr_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from HEADER STAGING TABLETHAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
		CURSOR cur_header_id(cur_p_batch_id number) is 
			select header_id, SOURCE_TRN_NBR, SOURCE_SYSTEM, LEG_AE_HEADER_ID, TRD_PARTNER_NAME, TRD_PARTNER_NBR, 
			 EVENT_TYPE, EVENT_CLASS, TRN_AMOUNT, ACC_DATE, HEADER_DESC, LEG_LED_NAME, JE_BATCH_NAME, JE_NAME, JE_CATEGORY, FILE_NAME, TRANSACTION_TYPE
			  from WSC_AHCS_AR_TXN_HEADER_T 
			 where BATCH_ID = cur_p_batch_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/

		------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will do a 3-way match per transaction between total of header , sum of debits at line & sum of credits at line
        -- and identified if there is a mismatch between these.
        -- All header IDs with such mismatches will be fetched for subsequent flagging.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        /******* @@@@@@@@ Modify this cursor to reflect the header and line tables. Also verify the column names are correct @@@@@@@ ********/
		cursor cur_header_validation(cur_p_batch_id number) is with line_cr as (
			SELECT header_id, sum(ACC_AMT)*-1 sum_data 
			  FROM WSC_AHCS_AR_TXN_LINE_T 
			 where DR_CR_FLAG = 'CR' 
			   and batch_id = cur_p_batch_id group by header_id),
			line_dr as (
			SELECT header_id, sum(ACC_AMT) sum_data 
			  FROM WSC_AHCS_AR_TXN_LINE_T 
			 where DR_CR_FLAG = 'DR' 
			   and batch_id = cur_p_batch_id group by header_id),
			header_amt as(
			SELECT header_id, sum(TRN_AMOUNT) sum_data FROM WSC_AHCS_AR_TXN_HEADER_T 
            where batch_id = cur_p_batch_id group by header_id)
			select l_cr.header_id from line_cr l_cr, line_dr l_dr, header_amt h_amt 
			 where l_cr.header_id = h_amt.header_id 
			   and l_dr.header_id = h_amt.header_id 
			   and (l_dr.sum_data <> h_amt.sum_data or l_cr.sum_data <> h_amt.sum_data)
               and l_dr.header_id = l_cr.header_id;
		------------------------------------------------------------------------------------------------------------------------------------------------

		type header_validation_type is table of cur_header_validation%rowtype;
        lv_header_validation header_validation_type;


		--- @@@@@@@@@@@@@@@@@@@@@@@@   
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will do a similar matching of total debits and credits but will be restricted at line level. 
        -- ONLY debit not matching to credit at transaction level will be detected.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        /******* @@@@@@@@ Modify this cursor to reflect the appropriate line tables. Also verify the column names are correct @@@@@@@ ********/

		cursor cur_line_validation(cur_p_batch_id number) is with line_cr as (
			SELECT header_id, sum(ACC_AMT)*-1 sum_data FROM WSC_AHCS_AR_TXN_LINE_T 
			 where DR_CR_FLAG = 'CR' 
			   and batch_id = cur_p_batch_id group by header_id),
			line_dr as (
			SELECT header_id, sum(ACC_AMT) sum_data FROM WSC_AHCS_AR_TXN_LINE_T 
			where DR_CR_FLAG = 'DR' and batch_id = cur_p_batch_id group by header_id)
			select l_cr.header_id 
			  from line_cr l_cr, line_dr l_dr 
			 where l_cr.header_id = l_dr.header_id 
			 and(l_cr.sum_data <> l_dr.sum_data);

		------------------------------------------------------------------------------------------------------------------------------------------------

		type line_validation_type is table of cur_line_validation%rowtype;
        lv_line_validation line_validation_type;

        cursor cur_count_sucss(cur_p_batch_id number) is 
        select count(1) 
		  from WSC_AHCS_INT_STATUS_T 
         where BATCH_ID = cur_p_batch_id 
		   and attribute2 = 'VALIDATION_SUCCESS' ;

err_msg varchar2(2000);
    Begin		
		------------------------------------------------------------------------------------------------------------------------------------------------
        -- 1. Start of validation.
        --    Identify transactions wherein header amount does not match with line credits & debits.
        --    Flag status table as follows:-
        --    a) Overall record status         = VALIDATION_FAILED
        --    b) Re-extract required           = 'Y', implying that the record must be re-extracted.
        --    c) Attribute1                    = 'H', flex attribute,implying this to be a header level failure. 
        --    d) Attribute2                    = VALIDATION FAILED, same as that of the line status.
        --
        --    Note: Irrespective of header or line level failure, the source system will re-extract entire header and lines.
        --          Header & line level flag in ATTRIBUTE1 is ONLY FOR the re-extract notification engine to send that line identifer or
        --          or just the header identifier in the re-extract notification to source. This will optimize and cut down on file size.

        ------------------------------------------------------------------------------------------------------------------------------------------------
      logging_insert ('EBS AR',p_batch_id,6,'Start of validation',null,sysdate);

		begin
            open cur_header_validation(p_batch_id);
            loop
            fetch cur_header_validation bulk collect into lv_header_validation limit 100;
            EXIT WHEN lv_header_validation.COUNT = 0;        
            forall i in 1..lv_header_validation.count
				update WSC_AHCS_INT_STATUS_T set STATUS = 'VALIDATION_FAILED', 
					ERROR_MSG = 'Header Trxn amount mismatch with Line DR/CR Amount', 
					REEXTRACT_REQUIRED = 'Y',ATTRIBUTE1 = 'H',ATTRIBUTE2='VALIDATION_FAILED', LAST_UPDATED_DATE = sysdate
				where BATCH_ID = P_BATCH_ID 
				  and HEADER_ID = lv_header_validation(i).header_id;
            end loop;
            close cur_header_validation;
            commit;
        exception
            when others then
            logging_insert ('EBS AR',p_batch_id,2,'exception of validation',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;

		------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2. Validate line totals
        --    Identify transactions wherein debits does not match credits.
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
        logging_insert ('EBS AR',p_batch_id,7,'Validate line totals',null,sysdate);

		begin
            open cur_line_validation(p_batch_id);
            loop
            fetch cur_line_validation bulk collect into lv_line_validation limit 100;
            EXIT WHEN lv_line_validation.COUNT = 0;        
            forall i in 1..lv_line_validation.count
				update WSC_AHCS_INT_STATUS_T set STATUS = 'VALIDATION_FAILED', 
					ERROR_MSG = 'Line DR/CR amount mismatch', 
					REEXTRACT_REQUIRED = 'Y',ATTRIBUTE1 = 'L',ATTRIBUTE2='VALIDATION_FAILED', LAST_UPDATED_DATE = sysdate
				where BATCH_ID = P_BATCH_ID 
				  and HEADER_ID = lv_line_validation(i).header_id;
            end loop;
            close cur_line_validation;
            commit;
        exception
            when others then
            logging_insert ('EBS AR',p_batch_id,103,'exception Validate line totals',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
                ROLLBACK;
        end; 

        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- 3. Validate header fields
        --    Identify header fields that fail data type mismatch.
        --    Flag status table as follows:-
        --    a) Overall record status         = VALIDATION_FAILED
        --    b) Re-extract required           = 'Y', implying that the record must be re-extracted.
        --    c) Attribute1                    = 'H', flex attribute,implying this to be a header level failure. 
        --    d) Attribute2                    = VALIDATION FAILED, same as that of the line status.
        --
        --    Note: Irrespective of header or line level failure, the source system will re-extract entire header and lines.
        --          Header & line level flag in ATTRIBUTE1 is ONLY FOR the re-extract notification engine to send that line identifer or
        --          or just the header identifier in the re-extract notification to source. This will optimize and cut down on file size.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert ('EBS AR',p_batch_id,8,'Validate header fields',null,sysdate);
begin

		for header_id_f in cur_header_id(p_batch_id) loop
			lv_header_err_flag := 'false';
			lv_header_err_msg := null;
            lv_error_ar_header := WSC_AHCS_AR_TXN_HEADER_TYPE('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'); 

/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
/**** @@@ Review/ Change function name to match data type of colum. Also pass the appropriate column name from the cursor @@@@ ******/
/**** @@@ Add more rows if there are more columns to be validated and match it with right function names                       ******/
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/

            lv_error_ar_header(1) := IS_VARCHAR2_NULL(header_id_f.SOURCE_TRN_NBR);
            lv_error_ar_header(2) := IS_VARCHAR2_NULL(header_id_f.SOURCE_SYSTEM);
            lv_error_ar_header(3) := IS_NUMBER_NULL(header_id_f.LEG_AE_HEADER_ID);
            --lv_error_ar_header(4) := IS_VARCHAR2_NULL(header_id_f.TRD_PARTNER_NAME);
            --lv_error_ar_header(5) := IS_VARCHAR2_NULL(header_id_f.TRD_PARTNER_NBR);
            lv_error_ar_header(7) := IS_VARCHAR2_NULL(header_id_f.EVENT_TYPE);
            lv_error_ar_header(8) := IS_VARCHAR2_NULL(header_id_f.EVENT_CLASS);
            lv_error_ar_header(9) := IS_NUMBER_NULL(header_id_f.TRN_AMOUNT);
            lv_error_ar_header(10) := IS_DATE_NULL(header_id_f.ACC_DATE);
--            lv_error_ar_header(11) := IS_VARCHAR2_NULL(header_id_f.HEADER_DESC);
            lv_error_ar_header(12) := IS_VARCHAR2_NULL(header_id_f.LEG_LED_NAME);
            lv_error_ar_header(13) := IS_VARCHAR2_NULL(header_id_f.JE_BATCH_NAME);
            lv_error_ar_header(14) := IS_VARCHAR2_NULL(header_id_f.JE_NAME);
            lv_error_ar_header(15) := IS_VARCHAR2_NULL(header_id_f.JE_CATEGORY);
            lv_error_ar_header(16) := IS_VARCHAR2_NULL(header_id_f.FILE_NAME);
          --  lv_error_ar_header(17) := IS_VARCHAR2_NULL(header_id_f.LEG_TRNS_TYPE);
--            lv_error_ar_header(17) := IS_VARCHAR2_NULL(header_id_f.SOURCE_TRN_NBR);
            lv_error_ar_header(17) := IS_VARCHAR2_NULL(header_id_f.TRANSACTION_TYPE);
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
  --          logging_insert ('EBS AR',p_batch_id,6,'lv_error_ar_header',null,sysdate);

			for i in 1..17 loop
				if lv_error_ar_header(i) = 0 then
					lv_header_err_msg := lv_header_err_msg || 'error in ' || lv_header_col_value(i) || '. ';
					lv_header_err_flag := 'true';
				end if;
     --       logging_insert ('EBS AR',p_batch_id,7,'lv_error_ar_header',lv_header_err_msg,sysdate);
			end loop;

			if lv_header_err_flag = 'true' then
				update WSC_AHCS_INT_STATUS_T set STATUS = 'VALIDATION_FAILED', 
					ERROR_MSG = lv_header_err_msg, REEXTRACT_REQUIRED = 'Y',ATTRIBUTE1 = 'H',ATTRIBUTE2='VALIDATION_FAILED', LAST_UPDATED_DATE = sysdate
				where BATCH_ID = P_BATCH_ID 
				  and HEADER_ID = header_id_f.header_id;
                  commit;

                   logging_insert ('EBS AR',p_batch_id,201,'Header Validation failed' || header_id_f.header_id,lv_header_err_flag,sysdate);
				continue;
			end if;
--            logging_insert ('EBS AR',p_batch_id,8,'lv_header_err_flag end',lv_header_err_flag,sysdate);


		------------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Validate line level fields
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

--   logging_insert ('EBS AR',p_batch_id,9,'lv_line_err_flag',null,sysdate);
			for wsc_ar_line in cur_wsc_ar_line(header_id_f.header_id) loop
				lv_line_err_flag := 'false';
				lv_line_err_msg := null;
                lv_error_ar_line := WSC_AHCS_AR_TXN_LINE_TYPE('1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1'); 

				lv_error_ar_line(1) := IS_VARCHAR2_NULL(wsc_ar_line.SOURCE_TRN_NBR);
				lv_error_ar_line(2) := IS_NUMBER_NULL(wsc_ar_line.LEG_AE_HEADER_ID);
				lv_error_ar_line(3) := IS_NUMBER_NULL(wsc_ar_line.DEFAULT_AMOUNT);
				lv_error_ar_line(4) := IS_NUMBER_NULL(wsc_ar_line.ACC_AMT);
				lv_error_ar_line(5) := IS_VARCHAR2_NULL(wsc_ar_line.DEFAULT_CURRENCY);
				lv_error_ar_line(6) := IS_VARCHAR2_NULL(wsc_ar_line.ACC_CURRENCY);
				lv_error_ar_line(7) := IS_VARCHAR2_NULL(wsc_ar_line.LEG_SEG1);
				lv_error_ar_line(8) := IS_VARCHAR2_NULL(wsc_ar_line.LEG_SEG2);
				lv_error_ar_line(9) := IS_VARCHAR2_NULL(wsc_ar_line.LEG_SEG3);
				lv_error_ar_line(10) := IS_VARCHAR2_NULL(wsc_ar_line.LEG_SEG4);
				lv_error_ar_line(11) := IS_VARCHAR2_NULL(wsc_ar_line.LEG_SEG5);
				lv_error_ar_line(12) := IS_VARCHAR2_NULL(wsc_ar_line.LEG_SEG6);
				lv_error_ar_line(13) := IS_VARCHAR2_NULL(wsc_ar_line.LEG_SEG7);
				lv_error_ar_line(14) := IS_VARCHAR2_NULL(wsc_ar_line.ACC_CLASS);
				lv_error_ar_line(15) := IS_VARCHAR2_NULL(wsc_ar_line.DR_CR_FLAG);
				lv_error_ar_line(16) := IS_NUMBER_NULL(wsc_ar_line.LEG_AE_LINE_NBR);
				lv_error_ar_line(17) := IS_NUMBER_NULL(wsc_ar_line.JE_LINE_NBR);
--				lv_error_ar_line(18) := IS_VARCHAR2_NULL(wsc_ar_line.LINE_DESC);
--				lv_error_ar_line(19) := IS_NUMBER_NULL(wsc_ar_line.FX_RATE);
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
--                  logging_insert ('EBS AR',p_batch_id,10,'lv_error_ar_line',null,sysdate);
				for j in 1..17 loop
					if lv_error_ar_line(j) = 0 then
						lv_line_err_msg := lv_line_err_msg || 'error in ' || lv_line_col_value(j) || '. ';
						lv_line_err_flag := 'true';
					end if;
				end loop;
--                         logging_insert ('EBS AR',p_batch_id,11,'lv_error_ar_line',null,sysdate);
				if lv_line_err_flag = 'true' then
					update WSC_AHCS_INT_STATUS_T set STATUS = 'VALIDATION_FAILED', 
						ERROR_MSG = lv_line_err_msg, REEXTRACT_REQUIRED = 'Y',ATTRIBUTE1 = 'L',ATTRIBUTE2='VALIDATION_FAILED', LAST_UPDATED_DATE = sysdate
					 where BATCH_ID = P_BATCH_ID 
					   and HEADER_ID = header_id_f.header_id 
					   and LINE_ID = wsc_ar_line.LINE_ID;

                commit;
                logging_insert ('EBS AR',p_batch_id,202,'Updated Line ID' || wsc_ar_line.LINE_ID || 'for Header ID' || header_id_f.header_id,lv_line_err_flag,sysdate);
                    update WSC_AHCS_INT_STATUS_T set ATTRIBUTE1 = 'L',ATTRIBUTE2='VALIDATION_FAILED', LAST_UPDATED_DATE = sysdate
					 where BATCH_ID = P_BATCH_ID 
					   and HEADER_ID = header_id_f.header_id ;
                    commit;

                     logging_insert ('EBS AR',p_batch_id,203,'Updated Header ID' || header_id_f.header_id,lv_line_err_flag,sysdate);
				end if;
                --  logging_insert ('EBS AR',p_batch_id,12,'lv_line_err_flag',lv_line_err_flag,sysdate);
			end loop;
		end loop;  
		commit;
        EXCEPTION
    WHEN OTHERS THEN
    err_msg := SUBSTR(SQLERRM,1,200);
     logging_insert ('EBS AR',p_batch_id,204,'Error in mandatory field check',SQLERRM,sysdate);
     end;

 logging_insert ('EBS AR',p_batch_id,9,'end',null,sysdate);

    begin   

    logging_insert ('EBS AR',p_batch_id,10,'start updating',null,sysdate);

    UPDATE wsc_ahcs_int_status_t
            SET
              status = 'VALIDATION_FAILED',
                        error_msg = 'error in LEG_AE_HEADER_ID',
                        reextract_required = 'Y',
                        attribute1 = 'L',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                    and header_id is null;
                    Commit;

		update WSC_AHCS_INT_STATUS_T set STATUS = 'VALIDATION_SUCCESS', LAST_UPDATED_DATE = sysdate
         where BATCH_ID = P_BATCH_ID 
		   and STATUS = 'NEW' and ERROR_MSG is null;
           Commit;

 logging_insert ('EBS AR',p_batch_id,11,'staus updated',null,sysdate);

        update WSC_AHCS_INT_STATUS_T set Attribute2 = 'VALIDATION_SUCCESS', LAST_UPDATED_DATE = sysdate
         where BATCH_ID = P_BATCH_ID 
		   and ATTRIBUTE2 IS NULL;
           Commit;

  logging_insert ('EBS AR',p_batch_id,12,'attribute 2 updated',null,sysdate);

        open cur_count_sucss(P_BATCH_ID);
        fetch cur_count_sucss into lv_count_sucss;
        close cur_count_sucss;

         logging_insert ('EBS AR',p_batch_id,15,'count success',lv_count_sucss,sysdate);

        if lv_count_sucss > 0 then
            update WSC_AHCS_INT_CONTROL_T set STATUS = 'VALIDATION_SUCCESS', LAST_UPDATED_DATE = sysdate
             WHERE BATCH_ID = P_BATCH_ID ;
             Commit;
             begin
            WSC_AHCS_AR_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation(P_BATCH_ID);
             end;
        else
           update WSC_AHCS_INT_CONTROL_T set STATUS = 'VALIDATION_FAILED', LAST_UPDATED_DATE = sysdate
            WHERE BATCH_ID = P_BATCH_ID ;            
        end if;        
        commit;
        logging_insert ('EBS AR',p_batch_id,24,'end data_validation',null,sysdate);
        logging_insert ('EBS AR',p_batch_id,301,'Dashboard Start',null,sysdate);
        WSC_AHCS_RECON_RECORDS_PKG.REFRESH_VALIDATION_OIC(retcode,err_msg);
        logging_insert ('EBS AR',p_batch_id,302,'Dashboard End',null,sysdate);
    end;    
EXCEPTION
        WHEN OTHERS THEN
            WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(p_batch_id,
                        'INT005',
                        'EBS_AR',
                        SQLERRM); 
	end data_validation;
    PROCEDURE leg_coa_transformation_reprocessing(p_batch_id IN number) IS
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
			select line.batch_id,line.header_id,line.line_id, line.target_coa
			  from WSC_AHCS_AR_TXN_LINE_T line, WSC_AHCS_INT_STATUS_T status
			 where line.batch_id = p_batch_id
			   and substr(line.target_coa,1,instr(line.target_coa,'.',1,1)-1)  is null
			   and status.batch_id = line.batch_id
			   and status.header_id = line.header_id
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

				wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system,cur_p_tgt_system,tgt_coa.leg_seg1,
				tgt_coa.leg_seg2,tgt_coa.leg_seg3,tgt_coa.leg_seg4,tgt_coa.leg_seg5,tgt_coa.leg_seg6,
				tgt_coa.leg_seg7,tgt_coa.leg_led_name,null,null) target_coa 
			--
			-- End of function call to derive target COA.
			----------------------------------------------------------------------------------------------------------------------------                	  

		  from (select distinct line.LEG_COA, line.LEG_SEG1, line.LEG_SEG2, line.LEG_SEG3,   /*** Fetches distinct legacy combination values ***/
					line.LEG_SEG4, line.LEG_SEG5, line.LEG_SEG6, line.LEG_SEG7,header.leg_led_name 
                from WSC_AHCS_AR_TXN_LINE_T line, WSC_AHCS_INT_STATUS_T status,WSC_AHCS_AR_TXN_HEADER_T header
               where status.batch_id = p_batch_id and line.target_coa is null
                 and status.batch_id = line.batch_id
                 and status.header_id = line.header_id
                 and status.line_id = line.line_id
                 and header.batch_id = status.batch_id
                 and header.header_id = status.header_id
                 and header.header_id = line.header_id
                 and header.batch_id = line.batch_id
                 and status.attribute2 = 'TRANSFORM_FAILED'  /*** Check if the record has been successfully validated through validate procedure ***/
				) tgt_coa;

		type leg_seg_value_type is table of cur_leg_seg_value%rowtype;
        lv_leg_seg_value leg_seg_value_type;

		-------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
        -- for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------

        cursor cur_inserting_ccid_table is
			select distinct line.LEG_COA/*||'.'||header.LEG_LED_NAME */LEG_COA, line.TARGET_COA TARGET_COA, line.LEG_SEG1, line.LEG_SEG2, line.LEG_SEG3, line.LEG_SEG4, line.LEG_SEG5, line.LEG_SEG6, line.LEG_SEG7, substr(line.LEG_COA,instr(line.LEG_COA,'.',1,7)+1) as ledger_name
			  from WSC_AHCS_AR_TXN_LINE_T line
 --             , WSC_AHCS_AR_TXN_HEADER_T header
			 where line.batch_id = p_batch_id 
--			   and line.batch_id = header.batch_id
--			   and line.header_id = header.header_id
			   and line.attribute1 = 'Y'   
			   and substr(line.target_coa,1,instr(line.target_coa,'.',1,1)-1) is not null;  /* Implies that the COA value has been successfully derived from engine */
        /*
		cursor cur_inserting_ccid_table is
			select distinct LEG_COA, TARGET_COA from WSC_AHCS_AR_TXN_LINE_T
			 where batch_id = p_batch_id 
			   and attribute1 = 'Y'   
			   and substr(target_coa,1,instr(target_coa,'.',1,1)-1) is not null;  
	    */

		type inserting_ccid_table_type is table of cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table inserting_ccid_table_type;

		------------------------------------------------------------------------------------------------------------------------------------------------------
        -- The following cursor picks up the distinct ledger/ legal entities that have been transformed successfully with future state COA values.
	    -- Ledger name is one of the key defaulting attributes required for processing a journal in AHCS.
		------------------------------------------------------------------------------------------------------------------------------------------------------

        cursor cur_get_ledger is 
        with main_data as
        (select lgl_entt.ledger_name, lgl_entt.LEGAL_ENTITY_NAME, d_lgl_entt.header_id
                      from wsc_gl_legal_entities_t lgl_entt,
                    (select distinct line.GL_LEGAL_ENTITY, line.header_id from WSC_AHCS_AR_TXN_LINE_T line, WSC_AHCS_INT_STATUS_T status 
                        where line.header_id = status.header_id
                          and line.batch_id = status.batch_id
                          and line.line_id = status.line_id
                          and status.batch_id = P_BATCH_ID
                          and status.attribute2 in ('VALIDATION_SUCCESS','TRANSFORM_FAILED')) d_lgl_entt
                     where lgl_entt.flex_segment_value(+) = d_lgl_entt.GL_LEGAL_ENTITY
                       )
                select * from  main_data a
                where a.ledger_name is not null
                and not exists 
                 (select 1 from main_data b
                   where a.header_id = b.header_id
                     and b.ledger_name is null);

		type get_ledger_type is table of cur_get_ledger%rowtype;
        lv_get_ledger get_ledger_type;

        cursor cur_count_sucss(cur_p_batch_id number) is 
			select count(1) 
			  from WSC_AHCS_INT_STATUS_T 
			 where BATCH_ID = cur_p_batch_id 
			   and attribute2 = 'TRANSFORM_SUCCESS'
               and (accounting_status is null or accounting_status = 'IMP_ACC_ERROR');


		--- @@@@@@@@@@@@@@@@@@@@@@@@   
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will do a similar matching of total debits and credits but will be restricted at line level. 
        -- ONLY debit not matching to credit at transaction level will be detected after validation.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        /******* @@@@@@@@ Modify this cursor to reflect the appropriate line tables. Also verify the column names are correct @@@@@@@ ********/

		cursor cur_line_validation_after_valid(cur_p_batch_id number) is 
			with line_cr as (
			   SELECT header_id,GL_LEGAL_ENTITY, sum(ACC_AMT)*-1 sum_data 
				 FROM WSC_AHCS_AR_TXN_LINE_T 
				where DR_CR_FLAG = 'CR' 
				  and batch_id = cur_p_batch_id group by header_id,GL_LEGAL_ENTITY),
			   line_dr as (
			   SELECT header_id,GL_LEGAL_ENTITY, sum(ACC_AMT) sum_data 
				 FROM WSC_AHCS_AR_TXN_LINE_T 
				where DR_CR_FLAG = 'DR' 
				  and batch_id = cur_p_batch_id group by header_id,GL_LEGAL_ENTITY)
			   select l_cr.header_id from line_cr l_cr, line_dr l_dr
			   where l_cr.header_id = l_dr.header_id 
				  and l_dr.GL_LEGAL_ENTITY = l_cr.GL_LEGAL_ENTITY 
				  and (l_dr.sum_data <> l_cr.sum_data );

		------------------------------------------------------------------------------------------------------------------------------------------------

        cursor cur_to_update_status(cur_p_batch_id number) is	
            select b.header_id,b.batch_id	
                            from WSC_AHCS_INT_STATUS_T b	
                        where b.status = 'TRANSFORM_FAILED'
                          and b.batch_id = cur_p_batch_id;

		type line_validation_after_valid_type is table of cur_line_validation_after_valid%rowtype;
        lv_line_validation_after_valid line_validation_after_valid_type;


        lv_coa_mapid number;
        lv_src_system varchar2(100);
        lv_tgt_system varchar2(100);
        lv_count_succ number;
        RETCODE VARCHAR2(50);
        ERR_MSG VARCHAR2(50);

    begin 

        -------------------------------------------------------------------------------------------------------------------------------------------
	--1. Identity the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert ('EBS AR',p_batch_id,14,'Transformation start',null,sysdate);

        open cur_coa_map_id;
        fetch cur_coa_map_id into lv_coa_mapid,lv_tgt_system,lv_src_system;
        close cur_coa_map_id;

        logging_insert('EBS AR',p_batch_id,14,'Transformation start',lv_coa_mapid||lv_tgt_system||lv_src_system,sysdate);

--        update target_coa in ar_line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
	--2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS AR',p_batch_id,13,'Check data in cache table to find ',null,sysdate);

          begin
			update WSC_AHCS_AR_TXN_LINE_T line
			set target_coa = null,
			    last_update_date = sysdate
           where batch_id = p_batch_id and
           exists ( select 1
                          from WSC_AHCS_INT_STATUS_T status
                            where line.batch_id = p_batch_id
                             and substr(line.target_coa,1,instr(line.target_coa,'.',1,1)-1)  is null
                             and status.batch_id = line.batch_id
                             and status.header_id = line.header_id
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
            UPDATE WSC_AHCS_AR_TXN_LINE_T line
               SET TARGET_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa,lv_coa_mapid), LAST_UPDATE_DATE = sysdate
             where batch_id = p_batch_id
               and exists 
				(select 1 
                   from --wsc_gl_ccid_mapping_t ccid_map,
                        WSC_AHCS_INT_STATUS_T status 
				  where /*ccid_map.coa_map_id = lv_coa_mapid and line.leg_coa = ccid_map.source_segment
				    and*/ status.batch_id = line.batch_id
				    and status.header_id = line.header_id
				    and status.line_id = line.line_id
				    and status.attribute2 = 'TRANSFORM_FAILED');
            commit;
        exception 
            when others then
                logging_insert('EBS AR',p_batch_id,22,'Check data in cache table to find',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;

--        update target_coa and attribute1 'Y' in ar_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS AR',p_batch_id,17,'update target_coa and attribute1',null,sysdate);

		begin
          /*  open cur_leg_seg_value(lv_src_system, lv_tgt_system);
            loop
            fetch cur_leg_seg_value bulk collect into lv_leg_seg_value limit 100;
            EXIT WHEN lv_leg_seg_value.COUNT = 0;        
            forall i in 1..lv_leg_seg_value.count
                update WSC_AHCS_AR_TXN_LINE_T set target_coa = lv_leg_seg_value(i).target_coa,  ATTRIBUTE1 = 'Y', 
                LAST_UPDATE_DATE = sysdate 
                where LEG_COA = lv_leg_seg_value(i).LEG_COA and batch_id = p_batch_id;
            end loop;
            close cur_leg_seg_value;
            commit;
        exception
            when others then
                logging_insert('EBS AR',p_batch_id,24,'update target_coa and attribute1',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;
*/
        update WSC_AHCS_AR_TXN_LINE_T TGT_COA
            set target_coa = wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system,lv_tgt_system,TGT_COA.leg_seg1,
                            TGT_COA.leg_seg2,TGT_COA.leg_seg3,TGT_COA.leg_seg4,TGT_COA.leg_seg5,TGT_COA.leg_seg6,
                            TGT_COA.leg_seg7,substr(leg_coa,instr(leg_coa,'.',1,7)+1),null,null) ,  ATTRIBUTE1 = 'Y'  
            where batch_id = p_batch_id
            and target_coa is null
            and exists
            (select /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */  1 from WSC_AHCS_INT_STATUS_T status
            where status.batch_id = p_batch_id 
                             and status.batch_id = TGT_COA.batch_id
                             and status.header_id = TGT_COA.header_id
                             and status.line_id = TGT_COA.line_id
                             and status.attribute2 = 'TRANSFORM_FAILED');
            commit;
        exception
            when others then
                logging_insert('EBS Ar',p_batch_id,24,'update target_coa and attribute1',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;

--        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS AR',p_batch_id,16,'insert new target_coa values',null,sysdate);

		begin
            open cur_inserting_ccid_table;
            loop
            fetch cur_inserting_ccid_table bulk collect into lv_inserting_ccid_table limit 100;
            EXIT WHEN lv_inserting_ccid_table.COUNT = 0;        
            forall i in 1..lv_inserting_ccid_table.count
                insert into wsc_gl_ccid_mapping_t(CCID_VALUE_ID,COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG, UI_FLAG,CREATED_BY, LAST_UPDATED_BY,source_segment1,source_segment2,source_segment3,source_segment4,source_segment5,source_segment6,source_segment7,source_segment8,source_segment9,source_segment10)
                values (wsc_gl_ccid_mapping_s.nextval,lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y', 'N', 'EBS AR', 'EBS AR', lv_inserting_ccid_table(i).LEG_SEG1, lv_inserting_ccid_table(i).LEG_SEG2, lv_inserting_ccid_table(i).LEG_SEG3, lv_inserting_ccid_table(i).LEG_SEG4, lv_inserting_ccid_table(i).LEG_SEG5, lv_inserting_ccid_table(i).LEG_SEG6, lv_inserting_ccid_table(i).LEG_SEG7, lv_inserting_ccid_table(i).ledger_name, null, null );
               --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
            end loop;
            close cur_inserting_ccid_table;
            
            EXCEPTION 
            WHEN OTHERS THEN
                NULL;
            END;
            
			update WSC_AHCS_AR_TXN_LINE_T set attribute1 = null 
			 where batch_id = p_batch_id;

			commit;
       

--      update ar_line table target segments,  where legal_entity must have their in target_coa
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS AR',p_batch_id,18,'update ar_line table target segments',null,sysdate);

		begin
            update WSC_AHCS_AR_TXN_LINE_T line
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
                            where sts.header_id = line.header_id
                              and sts.line_id = line.line_id
                              and sts.batch_id = line.batch_id
                              and sts.attribute2 = 'TRANSFORM_FAILED');
            commit;
        exception
            when others then
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
                logging_insert('EBS AR',p_batch_id,27,'update ar_line table target segments',SQLERRM,sysdate);
        end;

--        if any target_coa is empty in ar_line table will mark it as transform_error in status table
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS AR',p_batch_id,19,'if any target_coa is empty',null,sysdate);

        begin
			update
			(
			select status.attribute2,status.attribute1,status.status,status.error_msg,status.last_updated_date,
			   line.batch_id bt_id,line.header_id hdr_id,line.line_id ln_id, line.target_coa trgt_coa
				  from WSC_AHCS_INT_STATUS_T status,WSC_AHCS_AR_TXN_LINE_T line
				where status.batch_id = p_batch_id
				 and substr(line.target_coa,1,instr(line.target_coa,'.',1,1)-1)  is null
				 and status.batch_id = line.batch_id
				 and status.header_id = line.header_id
				 and status.line_id = line.line_id
				 and status.attribute2 in ('VALIDATION_SUCCESS','TRANSFORM_FAILED')
			)
			set attribute1 = 'L',
			   attribute2= 'TRANSFORM_FAILED',
			   status = 'TRANSFORM_FAILED',
			   error_msg = trgt_coa,
			   last_updated_date = sysdate;
            commit;

logging_insert('EBS AR',p_batch_id,19.1,'updated attribute2 with TRANSFORM_FAILED status',null,sysdate);

          for rcur_to_update_status in cur_to_update_status(p_batch_id) LOOP
                update WSC_AHCS_INT_STATUS_T	
                set ATTRIBUTE2 = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = sysdate
                where batch_id=rcur_to_update_status.batch_id	
                AND header_id=rcur_to_update_status.header_id;	
              END LOOP;

			/*update WSC_AHCS_INT_STATUS_T a
               set ATTRIBUTE2 = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = sysdate
             where a.batch_id = p_batch_id and exists 
              (select 1 from WSC_AHCS_INT_STATUS_T b 
                where a.batch_id = b.batch_id 
				  and a.header_id = b.header_id 
				  and status = 'TRANSFORM_FAILED'
                  and b.batch_id = p_batch_id );
                   */
            commit;

        exception
            when others then
                logging_insert('EBS AR',p_batch_id,29,'if any target_coa is empty',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);          
        end;

--      update ledger_name in ar_header table where transform_success		
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS AR',p_batch_id,20,'update ledger_name',null,sysdate);

        begin
    MERGE INTO WSC_AHCS_AR_TXN_HEADER_T hdr
            USING (with main_data as
                (select lgl_entt.ledger_name, lgl_entt.LEGAL_ENTITY_NAME, d_lgl_entt.header_id
                              from wsc_gl_legal_entities_t lgl_entt,
                            (select /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I) */ distinct line.GL_LEGAL_ENTITY, line.header_id from WSC_AHCS_AR_TXN_LINE_T line, WSC_AHCS_INT_STATUS_T status 
                                where line.header_id = status.header_id
                                  and line.batch_id = status.batch_id
                                  and line.line_id = status.line_id
                                  and status.batch_id = p_batch_id
                                  and status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED')) d_lgl_entt
                             where lgl_entt.flex_segment_value(+) = d_lgl_entt.GL_LEGAL_ENTITY
                               )
                        select DISTINCT A.LEDGER_NAME,a.header_id from  main_data a
                        where a.ledger_name is not null
                        and not exists 
                         (select 1 from main_data b
                           where a.header_id = b.header_id
                             and b.ledger_name is null)) e
            ON (e.header_id = hdr.header_id)
          WHEN MATCHED THEN
            UPDATE SET hdr.ledger_name = e.ledger_name;
            commit;
            /*open cur_get_ledger;
            loop
            fetch cur_get_ledger bulk collect into lv_get_ledger limit 100;
            EXIT WHEN lv_get_ledger.COUNT = 0;        
            forall i in 1..lv_get_ledger.count
                update WSC_AHCS_AR_TXN_HEADER_T
                   set ledger_name = lv_get_ledger(i).ledger_name , LAST_UPDATE_DATE = sysdate
                 where batch_id = p_batch_id 
				   and header_id = lv_get_ledger(i).header_id
                   ;
            end loop;
            close cur_get_ledger;
            commit; */
        exception
            when others then
                logging_insert('EBS AR',p_batch_id,31,'update ledger_name',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;

		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7.1. Update status tables after validation where line cr/dr mismatch.
        --    /******* ALL RECORDS MARKED AS VALIDATION FAILED WHEN LINE CR/DR AMOUNT MISMATCH AFTER VALIDATION ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
		logging_insert('EBS AR',p_batch_id,21,'Update status tables after validation',null,sysdate);
	/*	begin
            open cur_line_validation_after_valid(p_batch_id);
            loop
            fetch cur_line_validation_after_valid bulk collect into lv_line_validation_after_valid limit 100;
            EXIT WHEN lv_line_validation_after_valid.COUNT = 0;        
            forall i in 1..lv_line_validation_after_valid.count
				update WSC_AHCS_INT_STATUS_T set STATUS = 'VALIDATION_FAILED', 
					ERROR_MSG = 'Line DR/CR amount mismatch after validation', 
					ATTRIBUTE1 = 'L',
					ATTRIBUTE2='VALIDATION_FAILED', 
					LAST_UPDATED_DATE = sysdate
				where BATCH_ID = P_BATCH_ID 
				  and HEADER_ID = lv_line_validation_after_valid(i).header_id;
            end loop;
            commit;
        exception
            when others then
                logging_insert('EBS AR',p_batch_id,33,'Update status tables after validation',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end;
*/
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('EBS AR',p_batch_id,22,'Update status tables to have status',null,sysdate);

        begin    

            update (select sts.ATTRIBUTE2,sts.status,sts.last_updated_date,STS.ERROR_MSG
                     from WSC_AHCS_INT_STATUS_T sts ,WSC_AHCS_AR_TXN_HEADER_T hdr
                    where sts.BATCH_ID = P_BATCH_ID 
                      and hdr.header_id = sts.header_id
                      and hdr.batch_id = sts.batch_id
                      and hdr.ledger_name is null
                      AND sts.error_msg is NULL
                      AND sts.attribute2 in ('VALIDATION_SUCCESS','TRANSFORM_FAILED')
                   )
               set ERROR_MSG = 'Ledger derivation failed',ATTRIBUTE2 = 'TRANSFORM_FAILED',STATUS = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = sysdate
             ;

            update WSC_AHCS_INT_STATUS_T set STATUS = 'TRANSFORM_SUCCESS', LAST_UPDATED_DATE = sysdate
             where BATCH_ID = P_BATCH_ID 
			   and STATUS in ('VALIDATION_SUCCESS','TRANSFORM_FAILED')
			   and ERROR_MSG is null;
            commit;

            update WSC_AHCS_INT_STATUS_T set Attribute2 = 'TRANSFORM_SUCCESS', LAST_UPDATED_DATE = sysdate
             where BATCH_ID = P_BATCH_ID 
			   and ATTRIBUTE2 in ('VALIDATION_SUCCESS','TRANSFORM_FAILED')
               and ERROR_MSG is null;
            commit;

			-------------------------------------------------------------------------------------------------------------------------------------------
			-- 9. Flag the control table to consider this file as TRANSFORMATION COMPLETE. 
			--    /************ THIS WILL SIGNAL OIC TO PICK THIS FILE FOR UCM UPLOAD BY MASTER SCHEDULER ***********************/
			-------------------------------------------------------------------------------------------------------------------------------------------

			open cur_count_sucss(P_BATCH_ID);
            fetch cur_count_sucss into lv_count_succ;
            close cur_count_sucss;

            if lv_count_succ > 0 then
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

logging_insert ('EBS AR',p_batch_id,303,'Dashboard Start',null,sysdate);

WSC_AHCS_RECON_RECORDS_PKG.REFRESH_VALIDATION_OIC(retcode,err_msg);

logging_insert ('EBS AR',p_batch_id,304,'Dashboard End',null,sysdate);

logging_insert('EBS AR',p_batch_id,23,'end transformation',null,sysdate);

EXCEPTION
        WHEN OTHERS THEN
            WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(p_batch_id,
                        'INT005',
                        'EBS_AR',
                        SQLERRM);  
    end leg_coa_transformation_reprocessing;     


END WSC_AHCS_AR_VALIDATION_TRANSFORMATION_PKG;
/