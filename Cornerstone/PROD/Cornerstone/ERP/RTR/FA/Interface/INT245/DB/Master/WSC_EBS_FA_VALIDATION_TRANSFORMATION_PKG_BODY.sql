create or replace PACKAGE BODY "WSC_EBS_FA_VALIDATION_TRANSFORMATION_PKG" IS

     FUNCTION "IS_DATE_NULL" (
        p_string IN DATE
    ) RETURN NUMBER IS
    BEGIN
        IF p_string IS NULL THEN
            RETURN 0;
        ELSE
            RETURN 1;
        END IF;
    END;

    FUNCTION "IS_NUMBER_NULL" (
        p_string IN NUMBER
    ) RETURN NUMBER IS
        p_num NUMBER;
    BEGIN
        p_num := to_number(p_string);
        IF p_string IS NOT NULL THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END;

    FUNCTION "IS_VARCHAR2_NULL" (
        p_string IN VARCHAR2
    ) RETURN NUMBER IS
    BEGIN
        IF p_string IS NULL THEN
            RETURN 0;
        ELSE
            RETURN 1;
        END IF;
    END;

    PROCEDURE leg_data_transformation (
        p_batch_id IN NUMBER
    ) IS
	  -- +====================================================================+
      -- | Name             : transform_staging_data_to_Cloud FA                  |
      -- | Description      : Transforms data read into the staging tables    |
      -- |                    to Mass Addition FBDI format.                                 |
      -- |                    Following transformation will be applied :-     |
      -- |                    1. Derive future state COA based on legacy Cost Clearing COA  |
      -- |                       values in staging tables.                    |
      -- |					  2. Derive Asset BOOK							  |
	  -- | 					  3. Derive Location							  |
	  -- | 					  4  Derive Asset Category and Asset Type         |
	  -- |                                                                    |
      -- |                    Transformation will be performed on the basis   |
      -- |                    of batch_id.                                    |
      -- |                    Every file coming from source |
      -- |                    will be mapped to a unique batch_id             |
      -- |                    This procedure will (based on parameter) will   |
      -- |                    transform all records   |
      -- |                    from the file.                                  |
      -- +====================================================================+

------------------------------------------------------------------------------------------------------------------------------------------------------
   -- Derive the COA map ID for a given source/ target system value.
   -- COA Map ID will subsequently be used to derive the COA mapping rules that are assigned to this source / target combination.
   ------------------------------------------------------------------------------------------------------------------------------------------------------

        l_transformed NUMBER := 0;
        CURSOR cur_coa_map_id IS
        SELECT
            coa_map_id,
            coa_map.target_system,
            coa_map.source_system
        FROM
            wsc_gl_coa_map_t        coa_map,
            wsc_gen_int_control_t  ahcs_control
        WHERE
                upper(coa_map.source_system) = upper(ahcs_control.source_system)
            AND upper(coa_map.target_system) = upper(ahcs_control.target_system)
            AND ahcs_control.batch_id = p_batch_id;

   ------------------------------------------------------------------------------------------------------------------------------------------------------
   -- The following cursor will derive the future state COA combination for the given batch_Id for records that have been successfully validated.
   --
   ------------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_leg_seg_value (
            cur_p_src_system  VARCHAR2,
            cur_p_tgt_system  VARCHAR2
        ) IS
        SELECT
           ----------------------------------------------------------------------------------------------------------------------------
			/**********  The following package call will derive the future state COA combination for legacy COA combination ***********/
			--
            tgt_coa.COST_CLR_ACCOUNT_SEGMENT1||'.'||tgt_coa.COST_CLR_ACCOUNT_SEGMENT2||'.'||tgt_coa.COST_CLR_ACCOUNT_SEGMENT3||'.'||tgt_coa.COST_CLR_ACCOUNT_SEGMENT4||'.'||tgt_coa.COST_CLR_ACCOUNT_SEGMENT5||'.'||tgt_coa.COST_CLR_ACCOUNT_SEGMENT6||'.'||tgt_coa.COST_CLR_ACCOUNT_SEGMENT7 legacy_coa,
            wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system, cur_p_tgt_system, 
                                              tgt_coa.COST_CLR_ACCOUNT_SEGMENT1, 
                                              tgt_coa.COST_CLR_ACCOUNT_SEGMENT2,
                                               tgt_coa.COST_CLR_ACCOUNT_SEGMENT3,
                                               tgt_coa.COST_CLR_ACCOUNT_SEGMENT4,
                                               tgt_coa.COST_CLR_ACCOUNT_SEGMENT5,
                                               tgt_coa.COST_CLR_ACCOUNT_SEGMENT6,
                                               tgt_coa.COST_CLR_ACCOUNT_SEGMENT7,
                                               NULL,
                                               NULL,
                                               NULL) target_coa 
			--
			-- End of function call to derive target COA.
			----------------------------------------------------------------------------------------------------------------------------                	  

        FROM
            (
                SELECT DISTINCT
                    txn.COST_CLR_ACCOUNT_SEGMENT1,
                    txn.COST_CLR_ACCOUNT_SEGMENT2,
                    txn.COST_CLR_ACCOUNT_SEGMENT3,
                    txn.COST_CLR_ACCOUNT_SEGMENT4,   /*** Fetches distinct legacy combination values ***/
                    txn.COST_CLR_ACCOUNT_SEGMENT5,
                    txn.COST_CLR_ACCOUNT_SEGMENT6,
                    txn.COST_CLR_ACCOUNT_SEGMENT7
                FROM
                    WSC_EBS_FA_TXN_T    txn,
                    wsc_gen_int_status_t     status
                WHERE
                        status.batch_id = p_batch_id
                    AND txn.target_coa IS NULL
                    AND status.batch_id = txn.batch_id
                    AND status.header_id = txn.FA_TXN_T_ID
                    AND status.status = 'VALIDATION_SUCCESS'  /*** Check if the record has been successfully validated through validate procedure ***/
            ) tgt_coa;

        TYPE leg_seg_value_type IS
            TABLE OF cur_leg_seg_value%rowtype;

		lv_leg_seg_value          leg_seg_value_type;
       ------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
        -- for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_inserting_ccid_table IS
        SELECT DISTINCT
            txn.COST_CLR_ACCOUNT_SEGMENT1||'.'||txn.COST_CLR_ACCOUNT_SEGMENT2||'.'||txn.COST_CLR_ACCOUNT_SEGMENT3||'.'||txn.COST_CLR_ACCOUNT_SEGMENT4||'.'||txn.COST_CLR_ACCOUNT_SEGMENT5||'.'||txn.COST_CLR_ACCOUNT_SEGMENT6||'.'||txn.COST_CLR_ACCOUNT_SEGMENT7 LEG_COA,
            txn.target_coa  target_coa,
            txn.COST_CLR_ACCOUNT_SEGMENT1,
            txn.COST_CLR_ACCOUNT_SEGMENT2,
            txn.COST_CLR_ACCOUNT_SEGMENT3,
            txn.COST_CLR_ACCOUNT_SEGMENT4,
            txn.COST_CLR_ACCOUNT_SEGMENT5,
            txn.COST_CLR_ACCOUNT_SEGMENT6,
            txn.COST_CLR_ACCOUNT_SEGMENT7,
            txn.COST_CLR_ACCOUNT_SEGMENT8,
            txn.COST_CLR_ACCOUNT_SEGMENT9
        FROM
            WSC_EBS_FA_TXN_T txn
        WHERE
                txn.batch_id = p_batch_id 
            AND txn.attribute1 = 'Y'
            AND substr(txn.target_coa, 1, instr(txn.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */

        TYPE inserting_ccid_table_type IS
            TABLE OF cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table         inserting_ccid_table_type;


        CURSOR cur_to_update_status (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
           count(1)
        FROM
            wsc_gen_int_status_t b
        WHERE
                b.status = 'TRANSFORM_FAILED'
            AND b.batch_id = cur_p_batch_id;

        lv_count_transform_fail number :=0;   

		CURSOR cur_asset_category (
            cur_p_batch_id NUMBER
        ) IS
		SELECT distinct BATCH_ID,
			   GL_ACCT
		FROM WSC_EBS_FA_TXN_T
		WHERE BATCH_ID=cur_p_batch_id;

        lv_coa_mapid                    NUMBER;
        lv_src_system                   VARCHAR2(100);
        lv_tgt_system                   VARCHAR2(100);
        lv_count_succ                   NUMBER;
		LV_FY25_RULE_ID				NUMBER;
		lv_batch_id   					NUMBER := p_batch_id; 
        lv_err_msg                      VARCHAR2(4000) := NULL;
    BEGIN 

        -------------------------------------------------------------------------------------------------------------------------------------------
	--1. Identity the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBSAPFA', p_batch_id, 1, 'Transformation start', NULL,
                      sysdate);
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_mapid,
            lv_tgt_system,
            lv_src_system;
        CLOSE cur_coa_map_id;

		logging_insert('EBSAPFA', p_batch_id, 2, 'COA MAP ID derive start', lv_coa_mapid
                                                                         || lv_tgt_system
                                                                         || lv_src_system,
                      sysdate);
      -------------------------------------------------------------------------------------------------------------------------------------------\\
        	--2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBSAPFA', p_batch_id, 3, 'Check data in cache table to find ', NULL,
                      sysdate);
        BEGIN
            UPDATE WSC_EBS_FA_TXN_T txn
            SET
                target_coa = wsc_gl_coa_mapping_pkg.ccid_match(COST_CLR_ACCOUNT_SEGMENT1||'.'||COST_CLR_ACCOUNT_SEGMENT2||'.'||COST_CLR_ACCOUNT_SEGMENT3||'.'||COST_CLR_ACCOUNT_SEGMENT4||'.'||COST_CLR_ACCOUNT_SEGMENT5||'.'||COST_CLR_ACCOUNT_SEGMENT6||'.'||COST_CLR_ACCOUNT_SEGMENT7||'.'||COST_CLR_ACCOUNT_SEGMENT8||'.'||COST_CLR_ACCOUNT_SEGMENT9, lv_coa_mapid),
				last_update_date = sysdate
            WHERE
                batch_id = p_batch_id
          ;

            COMMIT;

        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBSAPFA', p_batch_id, 4, 'Error in Check data in cache table to find', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        --update target_coa and attribute1 'Y' in ap_line table where distinct leg_coa and target_coa is null      
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBSAPFA', p_batch_id, 5, 'update target_coa and attribute1', NULL,
                      sysdate);
        BEGIN

            UPDATE WSC_EBS_FA_TXN_T tgt_coa
            SET
                target_coa = wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system,
                                                                lv_tgt_system, 
                                                                tgt_coa.COST_CLR_ACCOUNT_SEGMENT1,
                                                                tgt_coa.COST_CLR_ACCOUNT_SEGMENT2,
                                                                tgt_coa.COST_CLR_ACCOUNT_SEGMENT3,
                                                                tgt_coa.COST_CLR_ACCOUNT_SEGMENT4,   
                                                                tgt_coa.COST_CLR_ACCOUNT_SEGMENT5,
                                                                tgt_coa.COST_CLR_ACCOUNT_SEGMENT6,
                                                                tgt_coa.COST_CLR_ACCOUNT_SEGMENT7,
                                                                tgt_coa.COST_CLR_ACCOUNT_SEGMENT8,
                                                                tgt_coa.COST_CLR_ACCOUNT_SEGMENT9,
                                                                 NULL),
                attribute1 = 'Y'
            WHERE
                    batch_id = lv_batch_id
                AND target_coa IS NULL
                AND EXISTS (
                    SELECT /*+ index(status WSC_GEN_INT_STATUS_HED_ID_I) */  1
                    FROM
                        wsc_gen_int_status_t status
                    WHERE
                            status.batch_id = p_batch_id
                        AND status.batch_id = tgt_coa.batch_id
                        AND status.header_id = tgt_coa.FA_TXN_T_ID
                        AND status.status = 'VALIDATION_SUCCESS'
                );

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBSAPFA', p_batch_id, 6, 'Error in update target_coa and attribute1', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

--        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBSAPFA', p_batch_id, 7, 'insert new target_coa values', NULL,
                      sysdate);
        BEGIN
            OPEN cur_inserting_ccid_table;
            LOOP
                FETCH cur_inserting_ccid_table BULK COLLECT INTO lv_inserting_ccid_table LIMIT 100;
                EXIT WHEN lv_inserting_ccid_table.count = 0;
                FORALL i IN 1..lv_inserting_ccid_table.count
                    INSERT INTO wsc_gl_ccid_mapping_t (
                        ccid_value_id,
                        coa_map_id,
                        source_segment,
                        target_segment,
                        creation_date,
                        last_update_date,
                        enable_flag,
                        ui_flag,
                        created_by,
                        last_updated_by,
                        source_segment1,
                        source_segment2,
                        source_segment3,
                        source_segment4,
                        source_segment5,
                        source_segment6,
                        source_segment7,
                        source_segment8,
                        source_segment9,
                        source_segment10
                    ) VALUES (
                        wsc_gl_ccid_mapping_s.NEXTVAL,
                        lv_coa_mapid,
                        lv_inserting_ccid_table(i).leg_coa,
                        lv_inserting_ccid_table(i).target_coa,
                        sysdate,
                        sysdate,
                        'Y',
                        'N',
                        'EBSAPFA',
                        'EBSAPFA',
                        lv_inserting_ccid_table(i).COST_CLR_ACCOUNT_SEGMENT1,
                        lv_inserting_ccid_table(i).COST_CLR_ACCOUNT_SEGMENT2,
                        lv_inserting_ccid_table(i).COST_CLR_ACCOUNT_SEGMENT3,
                        lv_inserting_ccid_table(i).COST_CLR_ACCOUNT_SEGMENT4,
                        lv_inserting_ccid_table(i).COST_CLR_ACCOUNT_SEGMENT5,
                        lv_inserting_ccid_table(i).COST_CLR_ACCOUNT_SEGMENT6,
                        lv_inserting_ccid_table(i).COST_CLR_ACCOUNT_SEGMENT7,
                        lv_inserting_ccid_table(i).COST_CLR_ACCOUNT_SEGMENT8,
                        lv_inserting_ccid_table(i).COST_CLR_ACCOUNT_SEGMENT9,
                        NULL
                    );
           END LOOP;

            CLOSE cur_inserting_ccid_table;
            EXCEPTION 
            WHEN OTHERS THEN
                NULL;
            END;
 		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBSAPFA', p_batch_id, 8, 'update ap_line table target segments', NULL,
                      sysdate);
        BEGIN
            UPDATE WSC_EBS_FA_TXN_T
            SET
                gl_legal_entity = substr(target_coa, 1, instr(target_coa, '.', 1, 1) - 1),
                gl_oper_grp = substr(target_coa, instr(target_coa, '.', 1, 1) + 1, instr(target_coa, '.', 1, 2) - instr(target_coa,
                '.', 1, 1) - 1),
                gl_acct = substr(target_coa, instr(target_coa, '.', 1, 2) + 1, instr(target_coa, '.', 1, 3) - instr(target_coa, '.',
                1, 2) - 1),
                gl_dept = substr(target_coa, instr(target_coa, '.', 1, 3) + 1, instr(target_coa, '.', 1, 4) - instr(target_coa, '.',
                1, 3) - 1),
                gl_site = substr(target_coa, instr(target_coa, '.', 1, 4) + 1, instr(target_coa, '.', 1, 5) - instr(target_coa, '.',
                1, 4) - 1),
                gl_ic = substr(target_coa, instr(target_coa, '.', 1, 5) + 1, instr(target_coa, '.', 1, 6) - instr(target_coa, '.',
                1, 5) - 1),
                gl_projects = substr(target_coa, instr(target_coa, '.', 1, 6) + 1, instr(target_coa, '.', 1, 7) - instr(target_coa,
                '.', 1, 6) - 1),
                gl_fut_1 = substr(target_coa, instr(target_coa, '.', 1, 7) + 1, instr(target_coa, '.', 1, 8) - instr(target_coa, '.',
                1, 7) - 1),
                gl_fut_2 = substr(target_coa, instr(target_coa, '.', 1, 8) + 1),
                last_update_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND substr(target_coa, 1, instr(target_coa, '.', 1, 1) - 1) IS NOT NULL;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
                logging_insert('EBSAPFA', p_batch_id, 9, 'Error in update ap_line table target segments', sqlerrm,
                              sysdate);
        END; 

-------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBSAPFA', p_batch_id, 10, 'if any target_coa is empty', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    status.status,
                    status.error_msg,
                    status.err_code,
                    status.last_updated_date,
                    txn.batch_id      bt_id,
                    txn.fa_txn_t_id     hdr_id,
                    txn.target_coa    trgt_coa
                FROM
                    wsc_gen_int_status_t   status,
                    WSC_EBS_FA_TXN_T  txn
                WHERE
                        status.batch_id = p_batch_id
                    AND substr(txn.target_coa, 1, instr(txn.target_coa, '.', 1, 1) - 1) IS NULL
                    AND status.batch_id = txn.batch_id
                    AND status.header_id = txn.fa_txn_t_id
                    AND status.status = 'VALIDATION_SUCCESS'
            )
            SET
                status = 'TRANSFORM_FAILED',
                error_msg = error_msg||' COA Mapping Error',
                Err_code = Err_code||' '||304,
                last_updated_date = sysdate;

            COMMIT;

            IF SQL%ROWCOUNT >0 THEN

            lv_err_msg := 'COA Mapping Error';
            logging_insert('EBSAPFA', p_batch_id, 10.1, 'updated status with TRANSFORM_FAILED status', NULL,
                          sysdate);
            END IF;              

        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBSAPFA', p_batch_id, 10.2, 'No target_coa is empty', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;



	--------------------------------------------------------------------------------------------------------
      -- LOCATION DERIVATION	
	--------------------------------------------------------------------------------------------------------
			Begin
			Select rule_id 
			into LV_FY25_RULE_ID
			from WSC_GL_COA_FY25_MAPPING_RULES_T a;

			EXCEPTION	
				WHEN OTHERS THEN
					LV_FY25_RULE_ID := NULL;
			END;

			Begin
			Merge into WSC_EBS_FA_TXN_T TRX_ID
			USING (Select b.target_segment,b.SOURCE_SEGMENT2
			from WSC_GL_COA_SEGMENT_VALUE_T b
			Where b.rule_id=LV_FY25_RULE_ID
			AND b.FLAG = 'Y')  TAR_LOC
			ON (TRX_ID.COST_CLR_ACCOUNT_SEGMENT2=TAR_LOC.SOURCE_SEGMENT2 AND TRX_ID.BATCH_ID=p_batch_id)
			When matched Then
				update set TRX_ID.TARGET_LOC=TAR_LOC.target_segment;

            COMMIT;

            Merge into WSC_EBS_FA_TXN_T TRX_ID
			USING (Select a.SEGMENT1,a.SEGMENT2,a.SEGMENT3,a.SEGMENT4
			from WSC_EBS_FA_LOCATIONS_T a
			Where 1=1
			AND a.ENABLED_FLAG = 'Y')  TAR_LOC
			ON (TRX_ID.TARGET_LOC=TAR_LOC.SEGMENT1 AND TRX_ID.BATCH_ID=p_batch_id)
			When matched Then
				update set TRX_ID.TARGET_LOC_SEG2=TAR_LOC.SEGMENT2,
                          TRX_ID.TARGET_LOC_SEG3=TAR_LOC.SEGMENT3,
                          TRX_ID.TARGET_LOC_SEG4=TAR_LOC.SEGMENT4;
            COMMIT;              

			EXCEPTION
				WHEN OTHERS THEN	
			        logging_insert('EBSAPFA', p_batch_id, 11, 'Error in Location Derivtion', sqlerrm,
                              sysdate);
                    dbms_output.put_line('Error with Query:  ' || sqlerrm);
			END;	

			/* for failed derivation, TRNASFORM FAIL udpate */	
        ---Commented as per logic change 
		/*	UPDATE wsc_gen_int_status_t S
                SET status = 'TRANSFORM_FAILED',
                    s.error_msg=error_msg||' Location not mapped',
                    s.err_code=s.err_code||' '||308,
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id
					AND exists ( Select 1 FROM WSC_EBS_FA_TXN_T
								WHERE BATCH_ID=p_batch_id
                                AND FA_TXN_T_ID=S.header_id
								AND (TARGET_LOC IS NULL OR TARGET_LOC_SEG2 IS NULL));  */

             Update WSC_EBS_FA_TXN_T
             Set TARGET_LOC=NULL
             WHERE BATCH_ID=p_batch_id
             AND (TARGET_LOC_SEG2 IS NULL OR TARGET_LOC_SEG3 IS NULL OR TARGET_LOC_SEG4 IS NULL);

            COMMIT;  

            IF SQL%ROWCOUNT > 0 THEN
              lv_err_msg := lv_err_msg || ' Location not mapped';
            END IF;  

    ----------------------------------------------------------------------------------------------------------
	--	Asset Book
	----------------------------------------------------------------------------------------------------------

		BEGIN
		update WSC_EBS_FA_TXN_T A
			set A.ASSET_BOOK = (Select distinct C.ASSET_BOOK
                 FROM WSC_EBS_FA_TXN_T B,
                      WSC_EBS_FA_CATEGORIES_T C,
                      WSC_GL_LEGAL_ENTITIES_T D
                 WHERE B.BATCH_ID=A.BATCH_ID
                 AND B.FA_TXN_T_ID=A.FA_TXN_T_ID
                 AND B.GL_LEGAL_ENTITY= D.FLEX_SEGMENT_VALUE
                 AND D.LEDGER_NAME = C.LEDGER_NAME)
			WHERE BATCH_ID=p_batch_id;   

            COMMIT;

		EXCEPTION	
			WHEN OTHERS THEN 
				 logging_insert('EBSAPFA', p_batch_id, 12, 'Error in Asset Book Derivtion', sqlerrm,
                              sysdate);
                    dbms_output.put_line('Error with Query:  ' || sqlerrm);


		END;

         UPDATE wsc_gen_int_status_t S
                SET status = 'TRANSFORM_FAILED',
                    s.error_msg=error_msg||' Asset Book derivation failed',
                    s.err_code=s.err_code||' '||309,
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id
					AND exists ( Select 1 FROM WSC_EBS_FA_TXN_T
								WHERE BATCH_ID=p_batch_id
                                AND FA_TXN_T_ID=S.header_id
								AND ASSET_BOOK IS NULL);
                 COMMIT;   

              IF SQL%ROWCOUNT > 0 THEN
              lv_err_msg := lv_err_msg || ' Asset Book derivation failed';
            END IF;      

	------------------------------------------------------------------------------------------------------------
		--Asset Category and Asset Type
	------------------------------------------------------------------------------------------------------------	

		For r_cur_asset_category in cur_asset_category(p_batch_id) LOOP

			BEGIN
			Merge into WSC_EBS_FA_TXN_T FA
			Using (Select CAT_SEG1,CAT_SEG2,ASSET_CLEARING_ACC,WIP_CLEARING_ACC,ASSET_BOOK
				   FROM WSC_EBS_FA_CATEGORIES_T
				   WHERE ENABLED_FLAG='Y') B
			ON (FA.BATCH_ID=p_batch_id AND r_cur_asset_category.GL_ACCT=FA.GL_ACCT AND B.ASSET_BOOK=FA.ASSET_BOOK AND (B.ASSET_CLEARING_ACC = FA.GL_ACCT OR B.WIP_CLEARING_ACC = FA.GL_ACCT ))
			WHEN MATCHED THEN 
				UPDATE SET FA.MAJOR_CATEGORY = B.CAT_SEG1,
					   FA.MINOR_CATEGORY = B.CAT_SEG2,
					   FA.ASSET_TYPE = Decode(FA.GL_ACCT,B.ASSET_CLEARING_ACC,'CAPITALIZED',B.WIP_CLEARING_ACC,'CIP',NULL);
			Commit;

			EXCEPTION	
			WHEN OTHERS THEN 
				 logging_insert('EBSAPFA', p_batch_id, 13, 'Error in Category/Asset type Derivtion for GL Account-'||r_cur_asset_category.GL_ACCT, sqlerrm,
                              sysdate);
                    dbms_output.put_line('Error with Query:  ' || sqlerrm);
			END;

		END LOOP;

           UPDATE wsc_gen_int_status_t status
               SET status = 'TRANSFORM_SUCCESS',
                last_updated_date = sysdate
            WHERE BATCH_ID=p_batch_id
            AND status = 'VALIDATION_SUCCESS'
            AND EXISTS ( SELECT 1 FROM
                        WSC_EBS_FA_TXN_T  txn
                        WHERE substr(txn.target_coa, 1, instr(txn.target_coa, '.', 1, 1) - 1) IS NOT NULL
                        AND txn.ASSET_BOOK IS NOT NULL
                        AND status.header_id = txn.fa_txn_t_id
                        AND status.batch_id=txn.batch_id);
        Commit;  

         OPEN cur_to_update_status(p_batch_id);
         FETCH cur_to_update_status into lv_count_transform_fail;
         CLOSE cur_to_update_status;

    logging_insert('EBSAPFA', p_batch_id, 14, 'count transform failed', lv_count_transform_fail,
                          sysdate);   

      if lv_count_transform_fail > 0 THEN 

           UPDATE wsc_gen_int_status_t
            SET status = 'TRANSFORM_FAILED',
            Err_code=999,
            Error_Msg='Other Record in Error',
            last_updated_date = sysdate
              WHERE
                    batch_id = p_batch_id
                    AND STATUS='TRANSFORM_SUCCESS';	

                COMMIT;

    	Update wsc_gen_int_control_t 
		 	Set LAST_UPDATED_DATE=SYSDATE,
			status='TRANSFORM_FAILED'
		WHERE batch_id=p_batch_id;
       Commit; 


     Else 

       begin
            Select count(1)
            into l_transformed
            from wsc_gen_int_status_t
            where batch_id=p_batch_id
            AND status='TRANSFORM_SUCCESS';
            exception
                when others then 
                    l_transformed :=0;
             End;       

          Update wsc_gen_int_control_t 
		 	Set LAST_UPDATED_DATE=SYSDATE,
            attribute3=l_transformed,
			status='TRANSFORM_SUCCESS'
        	WHERE batch_id=p_batch_id;
            COMMIT;
     End If;




     EXCEPTION
        WHEN OTHERS THEN
            WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(p_batch_id,
                        'INT245',
                        'EBSAPFA',
                        SQLERRM);                  
    END leg_data_transformation;

    PROCEDURE data_validation (
        p_batch_id IN NUMBER
    ) IS

        lv_header_err_msg     VARCHAR2(2000) := NULL;
        lv_header_err_flag    VARCHAR2(100) := 'false';
        lv_count_sucss        NUMBER := 0;
		lv_count_tot        NUMBER := 0;
        lv_count_failed     NUMBER := 0;
		lv_err_duplicate 	VARCHAR2(20000) := NULL;	
        retcode               VARCHAR2(50);
        l_validated         NUMBER := 0;

		TYPE wsc_header_col_value_type IS
            VARRAY(22) OF VARCHAR2(50); 

        lv_header_col_value   wsc_header_col_value_type := wsc_header_col_value_type('ASSETID','FIXED_ASSETS_COST',
                                                                                 'DATE_PLACED_IN_SERVICE', 'FIXED_ASSETS_UNITS',
                                                                                  'LINE_STATUS',
                                                                                  'PAYABLES_COST',
                                                                                  'COST_CLR_ACCOUNT_SEGMENT1',
                                                                                  'COST_CLR_ACCOUNT_SEGMENT2',
                                                                                  'COST_CLR_ACCOUNT_SEGMENT3',
                                                                                  'COST_CLR_ACCOUNT_SEGMENT4',
                                                                                  'COST_CLR_ACCOUNT_SEGMENT5',
                                                                                  'COST_CLR_ACCOUNT_SEGMENT6',
                                                                                  'COST_CLR_ACCOUNT_SEGMENT7',
                                                                                  'SUPPLIER_NAME',
                                                                                  'INVOICE_NUMBER',
                                                                                  'INVOICE_DATE',
                                                                                  'PAYABLES_UNITS',
                                                                                  'INVOICE_LINE_NUMBER',
                                                                                  'SUPPLIER_NUMBER');

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from HEADER STAGING TABLETHAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_header_id (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
           FA_TXN_T_ID         header_id ,
            ASSETID                  ,
            DESCRIPTION              ,
            FIXED_ASSETS_COST        ,
            DATE_PLACED_IN_SERVICE   ,
            FIXED_ASSETS_UNITS       ,
            LINE_STATUS              ,
            PAYABLES_COST            ,
            COST_CLR_ACCOUNT_SEGMENT1,
            COST_CLR_ACCOUNT_SEGMENT2,
            COST_CLR_ACCOUNT_SEGMENT3,
            COST_CLR_ACCOUNT_SEGMENT4,
            COST_CLR_ACCOUNT_SEGMENT5,
            COST_CLR_ACCOUNT_SEGMENT6,
            COST_CLR_ACCOUNT_SEGMENT7,
            SUPPLIER_NAME            ,
            INVOICE_NUMBER           ,
            INVOICE_DATE             ,
            PAYABLES_UNITS           ,
            INVOICE_LINE_NUMBER      ,
           	SUPPLIER_NUMBER
        FROM
            WSC_EBS_FA_TXN_T
        WHERE
            batch_id = cur_p_batch_id;  

        CURSOR cur_count_failed (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            COUNT(1)
        FROM
            wsc_gen_int_status_t
        WHERE
                batch_id = cur_p_batch_id
            AND status = 'VALIDATION_FAILED';

		 CURSOR cur_count_tot (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            COUNT(1)
        FROM
            wsc_gen_int_status_t
        WHERE
                batch_id = cur_p_batch_id;	

     CURSOR cur_count_duplicate IS
        SELECT
            COUNT(1),assetid
        FROM
            WSC_EBS_FA_TXN_T TXN
        WHERE 1=1
        AND EXISTS ( SELECT 1 FROM
                     WSC_GEN_INT_STATUS_T 
                    WHERE APPLICATION='EBSAPFA'
                    AND STATUS NOT IN ('TRANSFORM_FAILED','VALIDATION_FAILED','IMPORT_FAILED')
                    AND TXN.FA_TXN_T_ID = HEADER_ID)
		group by assetid
		having count(1)>1;	

		CURSOR cur_incorrect_linestatus (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            header_id
        FROM
            wsc_gen_int_status_t
        WHERE
		batch_id = cur_p_batch_id
		and attribute3 NOT IN ('NEW','MERGED');	


        err_msg               VARCHAR2(2000);

   TYPE wsc_ebs_fa_txn_header_type IS
            TABLE OF INTEGER;
      lv_error_ap_header    wsc_ebs_fa_txn_header_type := wsc_ebs_fa_txn_header_type('1', '1', '1', '1', '1',
                                                                                       '1', '1', '1', '1', '1',
                                                                                       '1', '1', '1', '1', '1',
                                                                                       '1', '1', '1', '1', '1');    

    BEGIN		
		------------------------------------------------------------------------------------------------------------------------------------------------
        -- 1. Validate header fields
        --    Identify header fields that fail data type mismatch.
        --    Flag status table as follows:-
        --    a) Overall record status         = VALIDATION_FAILED
        --    b) Re-extract required           = 'Y', implying that the record must be re-extracted.       ------------------------------------------------------------------------------------------------------------------------------------------------

       logging_insert('EBAAPFA', p_batch_id, 1, 'Start of validation', NULL,
                      sysdate);
        logging_insert('EBSAPFA', p_batch_id, 2, 'Validate header fields', NULL,
                      sysdate);

		BEGIN
            FOR header_id_f IN cur_header_id(p_batch_id) LOOP
                lv_header_err_flag := 'false';
                lv_header_err_msg := NULL;
                 lv_error_ap_header   := wsc_ebs_fa_txn_header_type('1', '1', '1', '1', '1',
                                                                   '1', '1', '1', '1', '1',
                                                                   '1', '1', '1', '1', '1',
                                                                   '1', '1', '1', '1', '1');



                lv_error_ap_header(1) := is_number_null(header_id_f.ASSETID);
                lv_error_ap_header(3) := is_number_null(header_id_f.FIXED_ASSETS_COST);
               lv_error_ap_header(4) := is_date_null(header_id_f.DATE_PLACED_IN_SERVICE);
               lv_error_ap_header(5) := is_number_null(header_id_f.FIXED_ASSETS_UNITS);
               lv_error_ap_header(6) := is_varchar2_null(header_id_f.LINE_STATUS);
                lv_error_ap_header(7) := is_number_null(header_id_f.PAYABLES_COST);
                lv_error_ap_header(8) := is_varchar2_null(header_id_f.COST_CLR_ACCOUNT_SEGMENT1);
                lv_error_ap_header(9) := IS_VARCHAR2_NULL(header_id_f.COST_CLR_ACCOUNT_SEGMENT2);
                lv_error_ap_header(10) := is_varchar2_null(header_id_f.COST_CLR_ACCOUNT_SEGMENT3);
               lv_error_ap_header(11) := is_varchar2_null(header_id_f.COST_CLR_ACCOUNT_SEGMENT4);
                lv_error_ap_header(12) := is_varchar2_null(header_id_f.COST_CLR_ACCOUNT_SEGMENT5);
                lv_error_ap_header(13) := is_varchar2_null(header_id_f.COST_CLR_ACCOUNT_SEGMENT6);
                lv_error_ap_header(14) := is_varchar2_null(header_id_f.COST_CLR_ACCOUNT_SEGMENT7);
                lv_error_ap_header(15) := is_varchar2_null(header_id_f.SUPPLIER_NAME);
                lv_error_ap_header(16) := is_varchar2_null(header_id_f.INVOICE_NUMBER);
                lv_error_ap_header(17) := is_date_null(header_id_f.INVOICE_DATE);
                lv_error_ap_header(18) := is_varchar2_null(header_id_f.PAYABLES_UNITS);
                lv_error_ap_header(19) := is_varchar2_null(header_id_f.INVOICE_LINE_NUMBER);
                lv_error_ap_header(20) := is_varchar2_null(header_id_f.SUPPLIER_NUMBER);


                FOR i IN 1..20 LOOP
                    IF lv_error_ap_header(i) = 0 THEN
                        lv_header_err_msg := lv_header_err_msg
                                             || 'error in '
                                             || lv_header_col_value(i)
                                             || '. ';
                        lv_header_err_flag := 'true';
                    END IF;

                END LOOP;

                IF lv_header_err_flag = 'true' THEN
                    UPDATE wsc_gen_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = 'Mandatory field validation error-'||lv_header_err_msg,
                        ERR_CODE = 300,
                        reextract_required = 'Y',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        AND header_id = header_id_f.header_id;

                    COMMIT;
                    logging_insert('EBSAPFA', p_batch_id, 3, ' Validation failed' || header_id_f.header_id,
                                  lv_header_err_flag,
                                  sysdate);

                    CONTINUE;
                END IF;

             END LOOP;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                err_msg := substr(sqlerrm, 1, 200);
                logging_insert('EBSAPFA', p_batch_id, 4, 'Error in mandatory field check', sqlerrm,
                              sysdate);
        END;

------------------------------------------------------------------------------------------------------------------------------------------------
        -- 2. Validation for header file containing Duplicate records
        --    Flag status table as follows:-
        --    a) Overall record status         = VALIDATION_FAILED
        --    b) Re-extract required           = 'Y', implying that the record must be re-extracted.       ------------------------------------------------------------------------------------------------------------------------------------------------	

		    For r_count_duplicate in cur_count_duplicate Loop


			  UPDATE wsc_gen_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = 'Duplicate Data Error(legacy header id) '||r_count_duplicate.assetid,
                        ERR_CODE = 306,
                        reextract_required = 'Y',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        AND legacy_header_id = r_count_duplicate.assetid;

                    COMMIT;

				   logging_insert('EBSAPFA', p_batch_id, 5, 'Header Validation failed, duplicate legacy header id' || r_count_duplicate.assetid,NULL,sysdate);

            END LOOP;

------------------------------------------------------------------------------------------------------------------------------------------------
        -- 3. Validation for Line Status in file
        --    Flag status table as follows:-
        --    a) Overall record status         = VALIDATION_FAILED
        --    b) Re-extract required           = 'Y', implying that the record must be re-extracted.       ------------------------------------------------------------------------------------------------------------------------------------------------		

			  UPDATE wsc_gen_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = 'Incorrect Line Status',
                        ERR_CODE = 307,
                        reextract_required = 'Y',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                       AND attribute3 NOT IN ('NEW','MERGED');

                    COMMIT;

                IF SQL%ROWCOUNT >0 THEN
                    logging_insert('EBSAPFA', p_batch_id, 6, 'Header Validation failed, INCORRECT line status', NULL,sysdate);
                END IF;    


        logging_insert('EBSAPFA', p_batch_id, 9, 'end', NULL,
                      sysdate);
        BEGIN
            logging_insert('EBSAPFA', p_batch_id, 7, 'start updating', NULL,
                          sysdate);

			UPDATE wsc_gen_int_status_t
            SET
                status = 'VALIDATION_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status = 'NEW'
                AND error_msg IS NULL;

            COMMIT;
            logging_insert('EBSAPFA', p_batch_id, 8, 'status updated', NULL,
                          sysdate);


			OPEN cur_count_failed(p_batch_id);
            FETCH cur_count_failed INTO lv_count_failed;
            CLOSE cur_count_failed;
            logging_insert('EBSAPFA', p_batch_id, 9, 'count failed', lv_count_failed,
                          sysdate);

			OPEN cur_count_tot(p_batch_id);
            FETCH cur_count_tot INTO lv_count_tot;
            CLOSE cur_count_tot;

			 UPDATE wsc_gen_int_control_t
                SET
                    total_records = lv_count_tot,
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;
			 commit;	



            IF lv_count_failed > 0 THEN

            UPDATE wsc_gen_int_status_t
            SET status = 'VALIDATION_FAILED',
            Err_code=999,
            Error_Msg='Other Record in Error',
            last_updated_date = sysdate
              WHERE
            batch_id = p_batch_id
            AND STATUS='VALIDATION_SUCCESS';	

            COMMIT;

				 UPDATE wsc_gen_int_control_t
                SET
                    status = 'VALIDATION_FAILED',
					last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;	

                COMMIT;

            ELSE

            begin
            Select count(1)
            into l_validated
            from wsc_gen_int_status_t
            where batch_id=p_batch_id
            AND status='VALIDATION_SUCCESS';
            exception
                when others then 
                    l_validated :=0;
             End;       

                UPDATE wsc_gen_int_control_t
                SET
                    status = 'VALIDATION_SUCCESS',
                    attribute2=l_validated,
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;
    
        BEGIN
            WSC_EBS_FA_VALIDATION_TRANSFORMATION_PKG.leg_data_transformation(p_batch_id);
         END;  
         
        

            END IF;

            COMMIT;
            logging_insert('EBSAPFA', p_batch_id, 10, 'end data_validation', NULL,
                          sysdate);
        END;




      EXCEPTION
        WHEN OTHERS THEN
            WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(p_batch_id,
                        'INT245',
                        'EBSAPFA',
                        SQLERRM);   

    END data_validation; 

     PROCEDURE Insert_Asset_Created_IN_PaaS(IN_ASSET_CREATE WSC_EBS_FA_ASSET_CREATED_T_TYPE_TABLE)
     IS 
     BEGIN
      FORALL i IN 1..IN_ASSET_CREATE.count

       INSERT INTO WSC_EBS_FA_ASSET_CREATED_T(
                        BATCH_NAME        ,
                        MASS_ADDITION_ID ,
                        ASSET_NUMBER     ,
                        BOOK_TYPE_CODE   ,
                        ASSET_TYPE       ,
                        BIR_NUMBER       ,
                        ASSET_ID         ,
                        POSTING_STATUS   ,
                        QUEUE_NAME       ,
                        TRANSACTION_NAME )
                     VALUES
                     (  IN_ASSET_CREATE(i).BATCH_NAME ,          
                        IN_ASSET_CREATE(i).MASS_ADDITION_ID,  
                        IN_ASSET_CREATE(i).ASSET_NUMBER      ,
                        IN_ASSET_CREATE(i).BOOK_TYPE_CODE   , 
                        IN_ASSET_CREATE(i).ASSET_TYPE        ,
                        IN_ASSET_CREATE(i).ATTRIBUTE1        ,
                        IN_ASSET_CREATE(i).ASSET_ID          ,
                        IN_ASSET_CREATE(i).POSTING_STATUS    ,
                        IN_ASSET_CREATE(i).QUEUE_NAME        ,
                        IN_ASSET_CREATE(i).TRANSACTION_NAME);

                Commit;
    END Insert_Asset_Created_IN_PaaS;   

PROCEDURE UPDATE_REC (P_BATCH_NAME VARCHAR2,LV_LOAD_ID NUMBER)
  IS
    LV_BATCH_ID    NUMBER := 0;
    LV_COUNT       NUMBER := 0;
    LV_TOT_REC     NUMBER := 0;
    LV_ERR_MSG  VARCHAR2(4000);
    l_imp           NUMBER :=0;
BEGIN

 Begin   
  SELECT BATCH_ID, TOTAL_RECORDS
  INTO LV_BATCH_ID,LV_TOT_REC
  FROM wsc_gen_int_control_t
  WHERE IMPORT_ACC_ID=LV_LOAD_ID;
 Exception
    WHEN OTHERS THEN
     LV_BATCH_ID := NULL;
 END;    


    MERGE INTO wsc_gen_int_status_t wais
         USING (SELECT POSTING_STATUS,
                       QUEUE_NAME,
                       TRANSACTION_NAME,
                       LV_LOAD_ID
                  FROM WSC_EBS_FA_ASSET_CREATED_T
                  WHERE BATCH_NAME=P_BATCH_NAME) temp
            ON (LV_BATCH_ID||'-'||wais.legacy_header_id = temp.TRANSACTION_NAME
                AND wais.bATCH_id=LV_BATCH_ID)
           WHEN MATCHED THEN
            UPDATE SET wais.STATUS='IMPORT_SUCCESS';
        commit;  


    UPDATE wsc_gen_int_status_t
    SET STATUS='IMPORT_FAILED',
       ERR_CODE=305,
       ERROR_MSG='Failed in FA Mass Additions'
    WHERE BATCH_ID=LV_BATCH_ID
    AND STATUS = 'IMPORT_INITIATED';
    commit;

    Begin
    SELECT COUNT(1) 
    INTO LV_COUNT
    FROM wsc_gen_int_status_t
    WHERE STATUS='IMPORT_FAILED'
    AND BATCH_ID=LV_BATCH_ID;
    exception   
     when others then 
        null;
     END;

     IF LV_COUNT >0 THEN
        IF LV_TOT_REC = LV_COUNT THEN 
            UPDATE wsc_gen_int_control_t
            SET STATUS='IMPORT_FAILED_ENTIRE_FILE'
            WHERE BATCH_ID=LV_BATCH_ID;
            COMMIT;
       ELSE
            UPDATE wsc_gen_int_control_t
            SET STATUS='IMPORT_FAILED_PARITAL_FILE'
            WHERE BATCH_ID=LV_BATCH_ID; 
            COMMIT;
       END IF;  

        UPDATE wsc_gen_int_status_t
            SET status = 'IMPORT_FAILED',
            Err_code=999,
            Error_Msg='Other Record in Error',
            last_updated_date = sysdate
              WHERE
                    batch_id = LV_BATCH_ID
                    AND STATUS='IMPORT_SUCCESS';	
          COMMIT;

     ELSE

      begin
            Select count(1)
            into l_imp
            from wsc_gen_int_status_t
            where batch_id=LV_BATCH_ID
            AND status='IMPORT_SUCCESS';
            exception
                when others then 
                    l_imp :=0;
             End;       

         UPDATE wsc_gen_int_control_t
        SET STATUS='IMPORT_SUCCESS',
            attribute4=l_imp
        WHERE BATCH_ID=LV_BATCH_ID;


     END IF;
     COMMIT;

       DELETE FROM WSC_EBS_FA_ASSET_CREATED_T WHERE BATCH_NAME=P_BATCH_NAME;
      COMMIT;

EXCEPTION
        WHEN OTHERS THEN
           DELETE FROM WSC_EBS_FA_ASSET_CREATED_T WHERE BATCH_NAME=P_BATCH_NAME;
            COMMIT;

           WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(LV_BATCH_ID,
                        'INT245',
                        'EBSAPFA',
                        'Error while doing reconciliation');   


END UPDATE_REC;

PROCEDURE CALL_ASYC_UPDATE(P_BATCH_NAME VARCHAR2,LV_LOAD_ID NUMBER) IS

BEGIN
dbms_scheduler.create_job (
  job_name   =>  'Update_WSC_GEN_INT_STATUS'||to_char(sysdate,'DDMMYYYYHH24MISS'),
  job_type   => 'PLSQL_BLOCK',
  job_action => 
    'DECLARE
      BEGIN 
       WSC_EBS_FA_VALIDATION_TRANSFORMATION_PKG.UPDATE_REC('''||P_BATCH_NAME||''','||LV_LOAD_ID||');
     END;',
  enabled   =>  TRUE,  
  auto_drop =>  FALSE, 
  comments  =>  'Update_WSC_GEN_INT_STATUS ');
END;

 PROCEDURE UPDATE_ESS_ID(P_JOB_ID NUMBER,P_BATCH_ID NUMBER)
 IS
 BEGIN
   update wsc_gen_int_control_t 
   set attribute1=decode(attribute1,NULL,P_JOB_ID,attribute1||','||P_JOB_ID)
   where batch_id=P_BATCH_ID;
   COMMIT;

 EXCEPTION
  WHEN OTHERS THEN
   NULL;
END  UPDATE_ESS_ID;  

PROCEDURE Insert_Categories_IN_PaaS(IN_ASSET_CATEGORIES WSC_EBS_FA_ASSET_CATEGORIES_T_TYPE_TABLE)
 IS 
     BEGIN
DELETE FROM WSC_EBS_FA_CATEGORIES_TEMP_T;
		COMMIT;


      FORALL i IN 1..IN_ASSET_CATEGORIES.count

       INSERT INTO WSC_EBS_FA_CATEGORIES_Temp_T(
                        CAT_SEG1           ,
                        CAT_SEG2           ,
                        ASSET_CLEARING_ACC ,
                        WIP_CLEARING_ACC   ,
                        DEPRN_EXPENSE_ACC  ,
                        ENABLED_FLAG       ,
                        ASSET_BOOK         ,
                        LEDGER_NAME        ,
                        CREATED_BY         , 
                        CREATION_DATE      ,
                        LAST_UPDATED_BY    , 
                        LAST_UPDATE_DATE )
                     VALUES
                     (  IN_ASSET_CATEGORIES(i).CAT_SEG1           ,
                        IN_ASSET_CATEGORIES(i).CAT_SEG2           ,
                        IN_ASSET_CATEGORIES(i).ASSET_CLEARING_ACC ,
                        IN_ASSET_CATEGORIES(i).WIP_CLEARING_ACC   ,
                        IN_ASSET_CATEGORIES(i).DEPRN_EXPENSE_ACC  ,
                        IN_ASSET_CATEGORIES(i).ENABLED_FLAG       ,
                        IN_ASSET_CATEGORIES(i).ASSET_BOOK         ,
                        IN_ASSET_CATEGORIES(i).LEDGER_NAME        ,
                        'FIN_INT',
                        sysdate,
                        'FIN_INT',
                        sysdate);

                Commit;

         WSC_EBS_FA_VALIDATION_TRANSFORMATION_PKG.MERGE_Categories_IN_PaaS;       

  Exception
        WHEN OTHERS THEN
             WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(null,
                        'INT245',
                        'EBSAPFA',
                        'Error while doing inserting into WSC_EBS_FA_CATEGORIES_Temp_T');  

END Insert_Categories_IN_PaaS;

PROCEDURE MERGE_Categories_IN_PaaS
IS 

BEGIN
                  BEGIN

            MERGE INTO WSC_EBS_FA_CATEGORIES_T a
            USING (SELECT * FROM WSC_EBS_FA_CATEGORIES_TEMP_T)b
            ON (a.cat_seg1=b.cat_seg1 and a.cat_seg2=b.cat_seg2 and  a.asset_book=b.asset_book)
        WHEN MATCHED THEN
        Update set  a.asset_clearing_acc=b.asset_clearing_acc,
            a.wip_clearing_acc=b.wip_clearing_acc,
                a.deprn_expense_acc=b.deprn_expense_acc,
                a.enabled_flag=b.enabled_flag,
                a.ledger_name=b.ledger_name,
                a.LAST_UPDATE_DATE=sysdate

        WHEN NOT MATCHED THEN
        INSERT (cat_seg1,cat_seg2,asset_clearing_acc,wip_clearing_acc,deprn_expense_acc,ENABLED_FLAG,asset_book,ledger_name,CREATED_BY,CREATION_DATE,LAST_UPDATED_BY,LAST_UPDATE_DATE)
        VALUES (b.cat_seg1,b.cat_seg2,b.asset_clearing_acc,b.wip_clearing_acc,b.deprn_expense_acc,b.ENABLED_FLAG,b.asset_book,b.ledger_name,'FININT',SYSDATE,'FININT',SYSDATE);

		Commit;
        Exception
        WHEN OTHERS THEN
             WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(null,
                        'INT245',
                        'EBSAPFA',
                        'Error while doing inserting into WSC_EBS_FA_CATEGORIES_T');  
                        END;

END;


PROCEDURE Insert_Locations_IN_PaaS(IN_ASSET_LOCATIONS WSC_EBS_FA_ASSET_LOCATIONS_T_TYPE_TABLE)
 IS 
     BEGIN
DELETE FROM WSC_EBS_FA_LOCATIONS_Temp_T;
		COMMIT;

      FORALL i IN 1..IN_ASSET_LOCATIONS.count

       INSERT INTO WSC_EBS_FA_LOCATIONS_Temp_T(
                        SEGMENT1         , 
                        SEGMENT2         , 
                        SEGMENT3         , 
                        SEGMENT4         , 
                        ENABLED_FLAG     , 
                        CREATED_BY       , 
                        CREATION_DATE    , 
                        LAST_UPDATED_BY  , 
                        LAST_UPDATE_DATE ,
                        LOCATION_ID)
                     VALUES
                     (  IN_ASSET_LOCATIONS(i).SEGMENT1         , 
                        IN_ASSET_LOCATIONS(i).SEGMENT2         , 
                        IN_ASSET_LOCATIONS(i).SEGMENT3         , 
                        IN_ASSET_LOCATIONS(i).SEGMENT4         , 
                        IN_ASSET_LOCATIONS(i).ENABLED_FLAG     , 
                        'FIN_INT',
                        sysdate,
                        'FIN_INT',
                        sysdate,
                        IN_ASSET_LOCATIONS(i).LOCATION_ID);

                Commit;
            WSC_EBS_FA_VALIDATION_TRANSFORMATION_PKG.Merge_Locations_IN_PaaS;

   Exception
        WHEN OTHERS THEN
             WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(null,
                        'INT245',
                        'EBSAPFA',
                        'Error while doing inserting into WSC_EBS_FA_LOCATIONS_Temp_T');  

END Insert_Locations_IN_PaaS;

PROCEDURE Merge_Locations_IN_PaaS
IS 
BEGIN

				MERGE INTO WSC_EBS_FA_LOCATIONS_T a
            USING (SELECT * FROM WSC_EBS_FA_LOCATIONS_Temp_T)b
            ON (a.LOCATION_ID=b.LOCATION_ID)
            WHEN MATCHED THEN
    Update set  a.SEGMENT1=b.segment1,
                a.SEGMENT2=b.segment2,
                a.SEGMENT3=b.segment3,
                a.SEGMENT4=b.segment4,
                a.enabled_flag=b.enabled_flag,
                a.LAST_UPDATE_DATE=sysdate
WHEN NOT MATCHED THEN
        INSERT (LOCATION_ID,SEGMENT1,SEGMENT2,SEGMENT3,SEGMENT4,ENABLED_FLAG,CREATED_BY,CREATION_DATE,LAST_UPDATED_BY,LAST_UPDATE_DATE)
        VALUES (b.LOCATION_ID,b.SEGMENT1,b.SEGMENT2,b.SEGMENT3,b.SEGMENT4,b.ENABLED_FLAG,'FININT',SYSDATE,'FININT',SYSDATE);

		COMMIT;


  Exception WHEN OTHERS THEN
        WSC_AHCS_INT_ERROR_LOGGING.ERROR_LOGGING(null,
                        'INT245',
                        'EBSAPFA',
                        'Error while doing inserting into WSC_EBS_FA_LOCATIONS_T');
                        END;      

END WSC_EBS_FA_VALIDATION_TRANSFORMATION_PKG;
/