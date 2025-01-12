create or replace PACKAGE BODY wsc_ahcs_fa_validation_transformation_pkg IS

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

    FUNCTION "IS_LONG_NULL" (
        p_string IN LONG
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

    PROCEDURE leg_coa_transformation (
        p_batch_id IN NUMBER
    ) IS
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
        lv_batch_id                    NUMBER := p_batch_id;
        CURSOR cur_update_trxn_line_err IS
        SELECT
            line.batch_id,
            line.header_id,
            line.line_id,
            line.target_coa
        FROM
            wsc_ahcs_fa_txn_line_t line,
            wsc_ahcs_int_status_t  status
        WHERE
                line.batch_id = p_batch_id
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
            AND status.batch_id = line.batch_id
            AND status.header_id = line.header_id
            AND status.line_id = line.line_id
            AND status.attribute2 = 'VALIDATION_SUCCESS'; /*ATTRIBUTE2 */

        TYPE update_trxn_line_err_type IS
            TABLE OF cur_update_trxn_line_err%rowtype;
        lv_update_trxn_line_err        update_trxn_line_err_type;
        CURSOR cur_update_trxn_header_err IS
        SELECT DISTINCT
            status.header_id,
            status.batch_id
        FROM
            wsc_ahcs_int_status_t status
        WHERE
                status.batch_id = p_batch_id
            AND status.status = 'TRANSFORM_FAILED';

        TYPE update_trxn_header_err_type IS
            TABLE OF cur_update_trxn_header_err%rowtype;
        lv_update_trxn_header_err      update_trxn_header_err_type;

   ------------------------------------------------------------------------------------------------------------------------------------------------------
   -- Derive the COA map ID for a given source/ target system value.
   -- COA Map ID will subsequently be used to derive the COA mapping rules that are assigned to this source / target combination.
   ------------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_coa_map_id IS
        SELECT
            coa_map_id,
            coa_map.target_system,
            coa_map.source_system
        FROM
            wsc_gl_coa_map_t       coa_map,
            wsc_ahcs_int_control_t ahcs_control
        WHERE
                upper(coa_map.source_system) = upper(ahcs_control.source_system)
            AND upper(coa_map.target_system) = upper(ahcs_control.target_system)
            AND ahcs_control.batch_id = p_batch_id;

   ------------------------------------------------------------------------------------------------------------------------------------------------------
   -- The following cursor will derive the future state COA combination for the given batch_Id for records that have been successfully validated.
   --
   ------------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_leg_seg_value (
            cur_p_src_system VARCHAR2,
            cur_p_tgt_system VARCHAR2
        ) IS
        SELECT
            tgt_coa.leg_coa,
			----------------------------------------------------------------------------------------------------------------------------
			/**********  The following package call will derive the future state COA combination for legacy COA combination ***********/
			--

            wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system, cur_p_tgt_system, tgt_coa.leg_seg1, tgt_coa.leg_seg2, tgt_coa.leg_seg3,
                                               tgt_coa.leg_seg4, tgt_coa.leg_seg5, tgt_coa.leg_seg6, tgt_coa.leg_seg7, tgt_coa.led_leg_name,
                                               NULL, NULL) target_coa 
			--
			-- End of function call to derive target COA.
			----------------------------------------------------------------------------------------------------------------------------                	  

        FROM
            (
                SELECT DISTINCT
                    line.leg_coa,
                    line.leg_seg1,
                    line.leg_seg2,
                    line.leg_seg3,   /*** Fetches distinct legacy combination values ***/
                    line.leg_seg4,
                    line.leg_seg5,
                    line.leg_seg6,
                    line.leg_seg7,
                    header.led_leg_name
                FROM
                    wsc_ahcs_fa_txn_line_t   line,
                    wsc_ahcs_int_status_t    status,
                    wsc_ahcs_fa_txn_header_t header
                WHERE
                        status.batch_id = p_batch_id
                    AND line.target_coa IS NULL
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND header.batch_id = status.batch_id
                    AND header.header_id = status.header_id
                    AND header.header_id = line.header_id
                    AND header.batch_id = line.batch_id
                    AND status.attribute2 = 'VALIDATION_SUCCESS'  /*** Check if the record has been successfully validated through validate procedure ***/
            ) tgt_coa;

        TYPE leg_seg_value_type IS
            TABLE OF cur_leg_seg_value%rowtype;
        lv_leg_seg_value               leg_seg_value_type;

		-------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
        -- for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_inserting_ccid_table IS
        SELECT DISTINCT
            line.leg_coa                                             leg_coa,
--            || '.'
--            || header.led_leg_name      
            line.target_coa                                          target_coa,
            line.leg_seg1,
            line.leg_seg2,
            line.leg_seg3,
            line.leg_seg4,
            line.leg_seg5,
            line.leg_seg6,
            line.leg_seg7,
            substr(line.leg_coa, instr(line.leg_coa, '.', 1, 7) + 1) AS ledger_name
        FROM
            wsc_ahcs_fa_txn_line_t line
--            wsc_ahcs_fa_txn_header_t  header
        WHERE
                line.batch_id = p_batch_id
--            AND line.batch_id = header.batch_id
--            AND line.header_id = header.header_id
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        /*
		cursor cur_inserting_ccid_table is
			select distinct LEG_COA, TARGET_COA from WSC_AHCS_FA_TXN_LINE_T
			 where batch_id = p_batch_id 
			   and attribute1 = 'Y'   
			   and substr(target_coa,1,instr(target_coa,'.',1,1)-1) is not null;  
	    */
        TYPE inserting_ccid_table_type IS
            TABLE OF cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table        inserting_ccid_table_type;

		------------------------------------------------------------------------------------------------------------------------------------------------------
        -- The following cursor picks up the distinct ledger/ legal entities that have been transformed successfully with future state COA values.
	    -- Ledger name is one of the key defaulting attributes required for processing a journal in AHCS.
		------------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_get_ledger IS
        WITH main_data AS (
            SELECT
                lgl_entt.ledger_name,
                lgl_entt.legal_entity_name,
                d_lgl_entt.header_id
            FROM
                wsc_gl_legal_entities_t lgl_entt,
                (
                    SELECT DISTINCT
                        line.gl_legal_entity,
                        line.header_id
                    FROM
                        wsc_ahcs_fa_txn_line_t line,
                        wsc_ahcs_int_status_t  status
                    WHERE
                            line.header_id = status.header_id
                        AND line.batch_id = status.batch_id
                        AND line.line_id = status.line_id
                        AND status.batch_id = p_batch_id
                        AND status.attribute2 = 'VALIDATION_SUCCESS'
                )                       d_lgl_entt
            WHERE
                lgl_entt.flex_segment_value (+) = d_lgl_entt.gl_legal_entity
        )
        SELECT
            *
        FROM
            main_data a
        WHERE
            a.ledger_name IS NOT NULL
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    main_data b
                WHERE
                        a.header_id = b.header_id
                    AND b.ledger_name IS NULL
            );

        TYPE get_ledger_type IS
            TABLE OF cur_get_ledger%rowtype;
        lv_get_ledger                  get_ledger_type;
        CURSOR cur_count_sucss (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            COUNT(1)
        FROM
            wsc_ahcs_int_status_t
        WHERE
                batch_id = cur_p_batch_id
            AND attribute2 = 'TRANSFORM_SUCCESS';
			   
			   
		--- @@@@@@@@@@@@@@@@@@@@@@@@   
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will do a similar matching of total debits and credits but will be restricted at line level. 
        -- ONLY debit not matching to credit at transaction level will be detected after validation.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        /******* @@@@@@@@ Modify this cursor to reflect the appropriate line tables. Also verify the column names are correct @@@@@@@ ********/

        CURSOR cur_line_validation_after_valid (
            cur_p_batch_id NUMBER
        ) IS
        WITH line_cr AS (
            SELECT
                header_id,
                gl_legal_entity,
                SUM(acc_amt) * - 1 sum_data
            FROM
                wsc_ahcs_fa_txn_line_t
            WHERE
                    dr_cr_flag = 'CR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id,
                gl_legal_entity
        ), line_dr AS (
            SELECT
                header_id,
                gl_legal_entity,
                SUM(acc_amt) sum_data
            FROM
                wsc_ahcs_fa_txn_line_t
            WHERE
                    dr_cr_flag = 'DR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id,
                gl_legal_entity
        )
        SELECT
            l_cr.header_id
        FROM
            line_cr l_cr,
            line_dr l_dr
        WHERE
                l_cr.header_id = l_dr.header_id
            AND l_dr.gl_legal_entity = l_cr.gl_legal_entity
            AND ( l_dr.sum_data <> l_cr.sum_data );

		------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_to_update_status (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            b.header_id,
            b.batch_id
        FROM
            wsc_ahcs_int_status_t b
        WHERE
                b.status = 'TRANSFORM_FAILED'
            AND b.batch_id = cur_p_batch_id;

        TYPE line_validation_after_valid_type IS
            TABLE OF cur_line_validation_after_valid%rowtype;
        lv_line_validation_after_valid line_validation_after_valid_type;
        lv_coa_mapid                   NUMBER;
        lv_src_system                  VARCHAR2(100);
        lv_tgt_system                  VARCHAR2(100);
        lv_count_succ                  NUMBER;
    BEGIN 

        -------------------------------------------------------------------------------------------------------------------------------------------
	--1. Identity the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 19, 'Transformation starts', NULL,
                      sysdate);
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_mapid,
            lv_tgt_system,
            lv_src_system;
        CLOSE cur_coa_map_id;
        logging_insert('EBS FA', p_batch_id, 20, 'Transformation Starts (COA MapID,Target System,Source System)', lv_coa_mapid
                                                                                                                  || lv_tgt_system
                                                                                                                  || lv_src_system,
                      sysdate);
--        update target_coa in fa_line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
	--2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 21, 'Check data in cache table to find ', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_fa_txn_line_t line
            SET
                target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa, lv_coa_mapid),
                last_update_date = sysdate
            WHERE
                batch_id = p_batch_id
               /* AND EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t status
                    WHERE
                            status.batch_id = line.batch_id
                        AND status.header_id = line.header_id
                        AND status.line_id = line.line_id
                        AND status.status = 'VALIDATION_SUCCESS'
                        AND status.attribute2 = 'VALIDATION_SUCCESS'
                        AND batch_id = p_batch_id
                )*/;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBS FA', p_batch_id, 22, 'Check data in cache table to find', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

--        update target_coa and attribute1 'Y' in fa_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 23, 'Update Target_COA and Attribute1', NULL,
                      sysdate);
        BEGIN
       /* OPEN cur_leg_seg_value(lv_src_system, lv_tgt_system);
            LOOP
                FETCH cur_leg_seg_value BULK COLLECT INTO lv_leg_seg_value LIMIT 100;
                EXIT WHEN lv_leg_seg_value.count = 0;
                FORALL i IN 1..lv_leg_seg_value.count
	         UPDATE wsc_ahcs_fa_txn_line_t  SET target_coa = lv_leg_seg_value(i).target_coa, attribute1 = 'Y',
		  last_update_date = sysdate
		  WHERE leg_coa = lv_leg_seg_value(i).leg_coa AND batch_id = p_batch_id;
		  END LOOP;
		  */


            UPDATE wsc_ahcs_fa_txn_line_t tgt_coa
            SET
                target_coa = wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, tgt_coa.leg_seg1, tgt_coa.leg_seg2, tgt_coa.
                leg_seg3,
                                                                tgt_coa.leg_seg4, tgt_coa.leg_seg5, tgt_coa.leg_seg6, tgt_coa.leg_seg7,
                                                                substr(leg_coa, instr(leg_coa, '.', 1, 7) + 1), NULL, NULL),
                attribute1 = 'Y'
            WHERE
                    batch_id = p_batch_id
                AND target_coa IS NULL
                AND EXISTS (
                    SELECT /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */
                        1
                    FROM
                        wsc_ahcs_int_status_t status
                    WHERE
                            status.batch_id = p_batch_id
                        AND status.batch_id = tgt_coa.batch_id
                        AND status.header_id = tgt_coa.header_id
                        AND status.line_id = tgt_coa.line_id
                        AND status.attribute2 = 'VALIDATION_SUCCESS'
                );

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBS FA', p_batch_id, 24, 'Error: Update Target_COA and Attribute1', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

--        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 25, 'Insert New Target_COA values', NULL,
                      sysdate);
        BEGIN
            OPEN cur_inserting_ccid_table;
            LOOP
                FETCH cur_inserting_ccid_table
                BULK COLLECT INTO lv_inserting_ccid_table LIMIT 100;
                EXIT WHEN lv_inserting_ccid_table.count = 0;
                FORALL i IN 1..lv_inserting_ccid_table.count
                    INSERT INTO wsc_gl_ccid_mapping_t (
                        ccid_value_id,
                        coa_map_id,
                        source_segment,
                        target_segment,
                        created_by,
                        creation_date,
                        last_updated_by,
                        last_update_date,
                        enable_flag,
                        ui_flag,
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
                        'EBS FA',
                        sysdate,
                        'EBS FA',
                        sysdate,
                        'Y',
                        'N',
                        lv_inserting_ccid_table(i).leg_seg1,
                        lv_inserting_ccid_table(i).leg_seg2,
                        lv_inserting_ccid_table(i).leg_seg3,
                        lv_inserting_ccid_table(i).leg_seg4,
                        lv_inserting_ccid_table(i).leg_seg5,
                        lv_inserting_ccid_table(i).leg_seg6,
                        lv_inserting_ccid_table(i).leg_seg7,
                        lv_inserting_ccid_table(i).ledger_name,
                        NULL,
                        NULL
                    );
                --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
            END LOOP;

            CLOSE cur_inserting_ccid_table;
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        UPDATE wsc_ahcs_fa_txn_line_t
        SET
            attribute1 = NULL
        WHERE
            batch_id = p_batch_id;

        COMMIT;

--      update FA_line table target segments,  where legal_entity must have their in target_coa
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 26, 'Update FA_Line Table Target Segments', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_fa_txn_line_t
            SET
                gl_legal_entity = substr(target_coa, 1, instr(target_coa, '.', 1, 1) - 1),
                gl_oper_grp = substr(target_coa, instr(target_coa, '.', 1, 1) + 1, instr(target_coa, '.', 1, 2) - instr(target_coa, '.',
                1, 1) - 1),
                gl_acct = substr(target_coa, instr(target_coa, '.', 1, 2) + 1, instr(target_coa, '.', 1, 3) - instr(target_coa, '.', 1,
                2) - 1),
                gl_dept = substr(target_coa, instr(target_coa, '.', 1, 3) + 1, instr(target_coa, '.', 1, 4) - instr(target_coa, '.', 1,
                3) - 1),
                gl_site = substr(target_coa, instr(target_coa, '.', 1, 4) + 1, instr(target_coa, '.', 1, 5) - instr(target_coa, '.', 1,
                4) - 1),
                gl_ic = substr(target_coa, instr(target_coa, '.', 1, 5) + 1, instr(target_coa, '.', 1, 6) - instr(target_coa, '.', 1,
                5) - 1),
                gl_projects = substr(target_coa, instr(target_coa, '.', 1, 6) + 1, instr(target_coa, '.', 1, 7) - instr(target_coa, '.',
                1, 6) - 1),
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
                logging_insert('EBS FA', p_batch_id, 27, 'Exception: Update FA_Line Table Target Segments', sqlerrm,
                              sysdate);
        END;

--        if any target_coa is empty in fa_line table will mark it as transform_error in status table
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 28, 'Mark Transform_Error in Status Table if any Target COA is Empty', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    status.attribute2,
                    status.attribute1,
                    status.status,
                    status.error_msg,
                    status.last_updated_date,
                    line.batch_id   bt_id,
                    line.header_id  hdr_id,
                    line.line_id    ln_id,
                    line.target_coa trgt_coa
                FROM
                    wsc_ahcs_int_status_t  status,
                    wsc_ahcs_fa_txn_line_t line
                WHERE
                        status.batch_id = p_batch_id
                    AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND status.attribute2 = 'VALIDATION_SUCCESS'
            )
            SET
                attribute1 = 'L',
                attribute2 = 'TRANSFORM_FAILED',
                status = 'TRANSFORM_FAILED',
                error_msg = trgt_coa,
                last_updated_date = sysdate;

            COMMIT;
            logging_insert('EBS FA', p_batch_id, 19.1, 'updated attribute2 with TRANSFORM_FAILED status', NULL,
                          sysdate);
            FOR rcur_to_update_status IN cur_to_update_status(p_batch_id) LOOP
                UPDATE wsc_ahcs_int_status_t
                SET
                    attribute2 = 'TRANSFORM_FAILED',
                    last_updated_date = sysdate
                WHERE
                        batch_id = rcur_to_update_status.batch_id
                    AND header_id = rcur_to_update_status.header_id;

            END LOOP; 
            /*UPDATE wsc_ahcs_int_status_t a
            SET
                attribute2 = 'TRANSFORM_FAILED',
                last_updated_date = sysdate
            WHERE
                EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t b
                    WHERE
                            a.batch_id = b.batch_id
                        AND a.header_id = b.header_id
                        AND status = 'TRANSFORM_FAILED'
                        AND b.batch_id = p_batch_id
                );*/

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBS FA', p_batch_id, 29, 'Exception: Target_COA is Empty', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

--      update ledger_name in fa_header table where transform_success		
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 30, 'update ledger_name', NULL,
                      sysdate);
        BEGIN
            /*OPEN cur_get_ledger;
            LOOP
                FETCH cur_get_ledger BULK COLLECT INTO lv_get_ledger LIMIT 100;
                EXIT WHEN lv_get_ledger.count = 0;
                FORALL i IN 1..lv_get_ledger.count
                    UPDATE wsc_ahcs_fa_txn_header_t
                    SET
                        ledger_name = lv_get_ledger(i).ledger_name,
                        last_update_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        AND header_id = lv_get_ledger(i).header_id;

            END LOOP;*/
            MERGE INTO wsc_ahcs_fa_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE) */
                              lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t lgl_entt,
                              (
                                  SELECT /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I,batch_status wsc_ahcs_int_status_batch_id_i)  */
                                      line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_fa_txn_line_t line,
                                      wsc_ahcs_int_status_t  status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = lv_batch_id
                                      AND status.attribute2 = 'VALIDATION_SUCCESS'
                              )                       d_lgl_entt
                          WHERE
                              lgl_entt.flex_segment_value = d_lgl_entt.gl_legal_entity
                      )
                      SELECT DISTINCT
                          a.ledger_name,
                          a.header_id
                      FROM
                          main_data a
                      WHERE
                          a.ledger_name IS NOT NULL
                  )
            e ON ( e.header_id = hdr.header_id )
            WHEN MATCHED THEN UPDATE
            SET hdr.ledger_name = e.ledger_name;

            MERGE INTO wsc_ahcs_fa_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE) */
                              lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t lgl_entt,
                              (
                                  SELECT /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I,batch_status wsc_ahcs_int_status_batch_id_i)  */
                                      line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_fa_txn_line_t line,
                                      wsc_ahcs_int_status_t  status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = lv_batch_id
                                      AND status.attribute2 = 'VALIDATION_SUCCESS'
                              )                       d_lgl_entt
                          WHERE
                              lgl_entt.flex_segment_value (+) = d_lgl_entt.gl_legal_entity
                      )
                      SELECT DISTINCT
                          a.ledger_name,
                          a.header_id
                      FROM
                          main_data a
                      WHERE
                          a.ledger_name IS NULL
                  )
            e ON ( e.header_id = hdr.header_id )
            WHEN MATCHED THEN UPDATE
            SET hdr.ledger_name = e.ledger_name;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBS FA', p_batch_id, 31, 'Exception: Update Ledger Name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
		
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7.1. Update status tables after validation where line cr/dr mismatch.
        --    /******* ALL RECORDS MARKED AS VALIDATION FAILED WHEN LINE CR/DR AMOUNT MISMATCH AFTER VALIDATION ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 32, 'Update status tables after validation', NULL,
                      sysdate);
        /*BEGIN
            OPEN cur_line_validation_after_valid(p_batch_id);
            LOOP
                FETCH cur_line_validation_after_valid BULK COLLECT INTO lv_line_validation_after_valid LIMIT 100;
                EXIT WHEN lv_line_validation_after_valid.count = 0;
                FORALL i IN 1..lv_line_validation_after_valid.count
                    UPDATE wsc_ahcs_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = 'Line DR/CR amount mismatch after validation',
                        attribute1 = 'L',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        AND header_id = lv_line_validation_after_valid(i).header_id;

            END LOOP;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBS FA', p_batch_id, 33, 'Exception: Update Status Tables after Validation', sqlerrm,sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;*/

		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 34, 'Update Status Tables with Status', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    sts.attribute2,
                    sts.status,
                    sts.last_updated_date,
                    sts.error_msg
                FROM
                    wsc_ahcs_int_status_t    sts,
                    wsc_ahcs_fa_txn_header_t hdr
                WHERE
                        sts.batch_id = p_batch_id
                    AND hdr.header_id = sts.header_id
                    AND hdr.batch_id = sts.batch_id
                    AND hdr.ledger_name IS NULL
                    AND sts.error_msg IS NULL
                    AND sts.attribute2 = 'VALIDATION_SUCCESS'
            )
            SET
                error_msg = 'Ledger derivation failed',
                attribute2 = 'TRANSFORM_FAILED',
                status = 'TRANSFORM_FAILED',
                last_updated_date = sysdate;

            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'TRANSFORM_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status = 'VALIDATION_SUCCESS'
                AND attribute2 = 'VALIDATION_SUCCESS'
                AND error_msg IS NULL;

            COMMIT;
            UPDATE wsc_ahcs_int_status_t
            SET
                attribute2 = 'TRANSFORM_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND attribute2 = 'VALIDATION_SUCCESS'
                AND error_msg IS NULL;

            COMMIT;

			-------------------------------------------------------------------------------------------------------------------------------------------
			-- 9. Flag the control table to consider this file as TRANSFORMATION COMPLETE. 
			--    /************ THIS WILL SIGNAL OIC TO PICK THIS FILE FOR UCM UPLOAD BY MASTER SCHEDULER ***********************/
			-------------------------------------------------------------------------------------------------------------------------------------------

            OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_succ;
            CLOSE cur_count_sucss;
            IF lv_count_succ > 0 THEN
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'TRANSFORM_SUCCESS',
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            ELSE
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'TRANSFORM_FAILED',
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            END IF;

            COMMIT;
        END;

        logging_insert('EBS FA', p_batch_id, 35, 'Transformation End', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT004', 'EBS_FA', sqlerrm);
    END leg_coa_transformation;

    PROCEDURE data_validation (
        p_batch_id IN NUMBER
    ) IS

        lv_header_err_msg    VARCHAR2(2000) := NULL;
        lv_line_err_msg      VARCHAR2(2000) := NULL;
        lv_header_err_flag   VARCHAR2(100) := 'false';
        lv_line_err_flag     VARCHAR2(100) := 'false';
        lv_count_sucss       NUMBER := 0;
        retcode              VARCHAR2(50);
        TYPE wsc_header_col_value_type IS
            VARRAY(20) OF VARCHAR2(50); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING HEADER OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        lv_header_col_value  wsc_header_col_value_type := wsc_header_col_value_type('SOURCE_TRN_NBR', 'SOURCE_SYSTEM', 'LEG_AE_HEADER_ID',
        'EVENT_TYPE', 'EVENT_CLASS',
                                                                                  'ACC_DATE', 'ASSET_BOOK', 'ASSET_CAT', 'ASSET_DESC',
                                                                                  'HEADER_DESC',
                                                                                  'LED_LEG_NAME', 'JE_NAME', 'JE_CATEGORY', 'TRN_AMOUNT',
                                                                                  'FILE_NAME',
                                                                                  'TRANSACTION_TYPE', 'JE_BATCH_NAME');
        TYPE wsc_line_col_value_type IS
            VARRAY(20) OF VARCHAR2(50); 
/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING LINE OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        lv_line_col_value    wsc_line_col_value_type := wsc_line_col_value_type('DEFAULT_AMOUNT', 'DEFAULT_CURRENCY', 'LEG_SEG1', 'LEG_SEG2',
        'LEG_SEG3',
                                                                            'LEG_SEG4', 'LEG_SEG5', 'LEG_SEG6', 'LEG_SEG7', 'ACC_CLASS',
                                                                            'ACC_AMT', 'DR_CR_FLAG', 'JE_LINE_NBR', 'LINE_DESC', 'ACC_CURRENCY',
                                                                            'LEG_AE_HEADER_ID', 'LEG_AE_LINE_NBR', 'SOURCE_TRN_NBR');


/************ @@@@@ INITIALIZE HEADER AND LINE FLAG TABLE TYPE VARIABLES TO MATCH THE COUNT OF HEADER AND LINE @@@@@ ************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/
        TYPE wsc_ahcs_fa_txn_header_type IS
            TABLE OF INTEGER;
        lv_error_fa_header   wsc_ahcs_fa_txn_header_type := wsc_ahcs_fa_txn_header_type('1', '1', '1', '1', '1',
                                                                                     '1', '1', '1', '1', '1',
                                                                                     '1', '1', '1', '1', '1',
                                                                                     '1', '1', '1', '1', '1');
        TYPE wsc_ahcs_fa_txn_line_type IS
            TABLE OF INTEGER;
        lv_error_fa_line     wsc_ahcs_fa_txn_line_type := wsc_ahcs_fa_txn_line_type('1', '1', '1', '1', '1',
                                                                               '1', '1', '1', '1', '1',
                                                                               '1', '1', '1', '1', '1',
                                                                               '1', '1', '1', '1', '1'); 


-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from LINE STAGING TABLE THAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_wsc_fa_line (
            cur_p_hdr_id VARCHAR2
        ) IS
        SELECT
            default_amount,
            default_currency,
            leg_seg1,
            leg_seg2,
            leg_seg3,
            leg_seg4,
            leg_seg5,
            leg_seg6,
            leg_seg7,
            acc_class,
            acc_amt,
            dr_cr_flag,
            je_line_nbr,
            line_desc,
            acc_currency,
            leg_ae_header_id,
            leg_ae_line_nbr,
            source_trn_nbr,
            line_id
        FROM
            wsc_ahcs_fa_txn_line_t
        WHERE
            header_id = cur_p_hdr_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from HEADER STAGING TABLETHAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_header_id (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            header_id,
            source_trn_nbr,
            source_system,
            leg_ae_header_id,
            event_type,
            event_class,
            acc_date,
            asset_book,
            asset_cat,
            asset_desc,
            header_desc,
            led_leg_name,
            je_name,
            je_category,
            trn_amount,
            file_name,
            transaction_type,
            je_batch_name
        FROM
            wsc_ahcs_fa_txn_header_t
        WHERE
            batch_id = cur_p_batch_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/

		------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will do a 3-way match per transaction between total of header , sum of debits at line & sum of credits at line
        -- and identified if there is a mismatch between these.
        -- All header IDs with such mismatches will be fetched for subsequent flagging.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        /******* @@@@@@@@ Modify this cursor to reflect the header and line tables. Also verify the column names are correct @@@@@@@ ********/
        CURSOR cur_header_validation (
            cur_p_batch_id NUMBER
        ) IS
        WITH line_cr AS (
            SELECT
                header_id,
                SUM(acc_amt) * - 1 sum_data
            FROM
                wsc_ahcs_fa_txn_line_t
            WHERE
                    dr_cr_flag = 'CR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ), line_dr AS (
            SELECT
                header_id,
                SUM(acc_amt) sum_data
            FROM
                wsc_ahcs_fa_txn_line_t
            WHERE
                    dr_cr_flag = 'DR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ), header_amt AS (
            SELECT
                header_id,
                SUM(trn_amount) sum_data
            FROM
                wsc_ahcs_fa_txn_header_t
            WHERE
                batch_id = cur_p_batch_id
            GROUP BY
                header_id
        )
        SELECT
            l_cr.header_id
        FROM
            line_cr    l_cr,
            line_dr    l_dr,
            header_amt h_amt
        WHERE
                l_cr.header_id = h_amt.header_id
            AND l_dr.header_id = h_amt.header_id
            AND ( l_dr.sum_data <> h_amt.sum_data
                  OR l_cr.sum_data <> h_amt.sum_data )
            AND l_dr.header_id = l_cr.header_id;
		------------------------------------------------------------------------------------------------------------------------------------------------

        TYPE header_validation_type IS
            TABLE OF cur_header_validation%rowtype;
        lv_header_validation header_validation_type;


		--- @@@@@@@@@@@@@@@@@@@@@@@@   
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will do a similar matching of total debits and credits but will be restricted at line level. 
        -- ONLY debit not matching to credit at transaction level will be detected.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        /******* @@@@@@@@ Modify this cursor to reflect the appropriate line tables. Also verify the column names are correct @@@@@@@ ********/

        CURSOR cur_line_validation (
            cur_p_batch_id NUMBER
        ) IS
        WITH line_cr AS (
            SELECT
                header_id,
                SUM(acc_amt) * - 1 sum_data
            FROM
                wsc_ahcs_fa_txn_line_t
            WHERE
                    dr_cr_flag = 'CR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        ), line_dr AS (
            SELECT
                header_id,
                SUM(acc_amt) sum_data
            FROM
                wsc_ahcs_fa_txn_line_t
            WHERE
                    dr_cr_flag = 'DR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id
        )
        SELECT
            l_cr.header_id
        FROM
            line_cr l_cr,
            line_dr l_dr
        WHERE
                l_cr.header_id = l_dr.header_id
            AND ( l_cr.sum_data <> l_dr.sum_data );

		------------------------------------------------------------------------------------------------------------------------------------------------

        TYPE line_validation_type IS
            TABLE OF cur_line_validation%rowtype;
        lv_line_validation   line_validation_type;
        CURSOR cur_count_sucss (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            COUNT(1)
        FROM
            wsc_ahcs_int_status_t
        WHERE
                batch_id = cur_p_batch_id
            AND attribute2 = 'VALIDATION_SUCCESS';

        err_msg              VARCHAR2(2000);
    BEGIN		
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
        logging_insert('EBS FA', p_batch_id, 5, 'Start of validation', NULL,
                      sysdate);
        BEGIN
            OPEN cur_header_validation(p_batch_id);
            LOOP
                FETCH cur_header_validation
                BULK COLLECT INTO lv_header_validation LIMIT 100;
                EXIT WHEN lv_header_validation.count = 0;
                FORALL i IN 1..lv_header_validation.count
                    UPDATE wsc_ahcs_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = 'Header Transaction Amount mismatch with Line DR/CR Amount',
                        reextract_required = 'Y',
                        attribute1 = 'H',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        AND header_id = lv_header_validation(i).header_id;

            END LOOP;

            CLOSE cur_header_validation;
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBS FA', p_batch_id, 6, 'Validation Exception', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

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
        logging_insert('EBS FA', p_batch_id, 7, 'Validate Line Totals', NULL,
                      sysdate);
        BEGIN
            OPEN cur_line_validation(p_batch_id);
            LOOP
                FETCH cur_line_validation
                BULK COLLECT INTO lv_line_validation LIMIT 100;
                EXIT WHEN lv_line_validation.count = 0;
                FORALL i IN 1..lv_line_validation.count
                    UPDATE wsc_ahcs_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = 'Line DR/CR Amount Mismatch',
                        reextract_required = 'Y',
                        attribute1 = 'L',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        AND header_id = lv_line_validation(i).header_id;

            END LOOP;

            CLOSE cur_line_validation;
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBS FA', p_batch_id, 8, 'Exception: Validate Line Totals', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
                ROLLBACK;
        END;

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

        logging_insert('EBS FA', p_batch_id, 9, 'Validate Header Feilds', NULL,
                      sysdate);
        BEGIN
            FOR header_id_f IN cur_header_id(p_batch_id) LOOP
                lv_header_err_flag := 'false';
                lv_header_err_msg := NULL;
                lv_error_fa_header := wsc_ahcs_fa_txn_header_type('1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1'); 

/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
/**** @@@ Review/ Change function name to match data type of colum. Also pass the appropriate column name from the cursor @@@@ ******/
/**** @@@ Add more rows if there are more columns to be validated and match it with right function names                       ******/
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/

                lv_error_fa_header(1) := is_varchar2_null(header_id_f.source_trn_nbr);
                lv_error_fa_header(2) := is_varchar2_null(header_id_f.source_system);
                lv_error_fa_header(3) := is_varchar2_null(header_id_f.leg_ae_header_id);
                lv_error_fa_header(4) := is_varchar2_null(header_id_f.event_type);
                lv_error_fa_header(5) := is_varchar2_null(header_id_f.event_class);
                lv_error_fa_header(6) := is_date_null(header_id_f.acc_date);
                lv_error_fa_header(7) := is_varchar2_null(header_id_f.asset_book);
                lv_error_fa_header(8) := is_varchar2_null(header_id_f.asset_cat);
                lv_error_fa_header(9) := is_varchar2_null(header_id_f.asset_desc);
		------	lv_error_fa_header(10) := IS_VARCHAR2_NULL(header_id_f.HEADER_DESC);
                lv_error_fa_header(11) := is_varchar2_null(header_id_f.led_leg_name);
                lv_error_fa_header(12) := is_varchar2_null(header_id_f.je_name);
                lv_error_fa_header(13) := is_varchar2_null(header_id_f.je_category);
                lv_error_fa_header(14) := is_number_null(header_id_f.trn_amount);
                lv_error_fa_header(15) := is_varchar2_null(header_id_f.file_name);
                lv_error_fa_header(16) := is_varchar2_null(header_id_f.transaction_type);
                lv_error_fa_header(17) := is_varchar2_null(header_id_f.je_batch_name);
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/
--		logging_insert (null,p_batch_id,6,'lv_error_fa_header',null,sysdate);

                FOR i IN 1..16 LOOP
                    IF lv_error_fa_header(i) = 0 THEN
                        lv_header_err_msg := lv_header_err_msg
                                             || 'Error in '
                                             || lv_header_col_value(i)
                                             || '. ';
                        lv_header_err_flag := 'true';
                    END IF;
--		logging_insert (null,p_batch_id,7,'lv_error_fa_header',lv_header_err_msg,sysdate);
                END LOOP;

                IF lv_header_err_flag = 'true' THEN
                    UPDATE wsc_ahcs_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = lv_header_err_msg,
                        reextract_required = 'Y',
                        attribute1 = 'H',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        AND header_id = header_id_f.header_id;

                    COMMIT;
                    logging_insert('EBS FA', p_batch_id, 10, 'Header Feilds Validation failed' || header_id_f.header_id, lv_header_err_flag,
                                  sysdate);

                    CONTINUE;
                END IF;


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


                FOR wsc_fa_line IN cur_wsc_fa_line(header_id_f.header_id) LOOP
                    lv_line_err_flag := 'false';
                    lv_line_err_msg := NULL;
                    lv_error_fa_line := wsc_ahcs_fa_txn_line_type('1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1',
                                                                 '1', '1', '1', '1', '1');

                    lv_error_fa_line(1) := is_number_null(wsc_fa_line.default_amount);
                    lv_error_fa_line(2) := is_varchar2_null(wsc_fa_line.default_currency);
                    lv_error_fa_line(3) := is_varchar2_null(wsc_fa_line.leg_seg1);
                    lv_error_fa_line(4) := is_varchar2_null(wsc_fa_line.leg_seg2);
                    lv_error_fa_line(5) := is_varchar2_null(wsc_fa_line.leg_seg3);
                    lv_error_fa_line(6) := is_varchar2_null(wsc_fa_line.leg_seg4);
                    lv_error_fa_line(7) := is_varchar2_null(wsc_fa_line.leg_seg5);
                    lv_error_fa_line(8) := is_varchar2_null(wsc_fa_line.leg_seg6);
                    lv_error_fa_line(9) := is_varchar2_null(wsc_fa_line.leg_seg7);
                    lv_error_fa_line(10) := is_varchar2_null(wsc_fa_line.acc_class);
                    lv_error_fa_line(11) := is_number_null(wsc_fa_line.acc_amt);
                    lv_error_fa_line(12) := is_varchar2_null(wsc_fa_line.dr_cr_flag);
                    lv_error_fa_line(13) := is_number_null(wsc_fa_line.je_line_nbr);
			--	lv_error_fa_line(14) := IS_VARCHAR2_NULL(wsc_fa_line.LINE_DESC);
                    lv_error_fa_line(15) := is_varchar2_null(wsc_fa_line.acc_currency);
                    lv_error_fa_line(16) := is_number_null(wsc_fa_line.leg_ae_header_id);
                    lv_error_fa_line(17) := is_number_null(wsc_fa_line.leg_ae_line_nbr);
                    lv_error_fa_line(18) := is_varchar2_null(wsc_fa_line.source_trn_nbr);
				
				
/**** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ******/

                    FOR j IN 1..18 LOOP
                        IF lv_error_fa_line(j) = 0 THEN
                            lv_line_err_msg := lv_line_err_msg
                                               || 'error in '
                                               || lv_line_col_value(j)
                                               || '. ';
                            lv_line_err_flag := 'true';
                        END IF;
                    END LOOP;

                    IF lv_line_err_flag = 'true' THEN
                        UPDATE wsc_ahcs_int_status_t
                        SET
                            status = 'VALIDATION_FAILED',
                            error_msg = lv_line_err_msg,
                            reextract_required = 'Y',
                            attribute1 = 'L',
                            attribute2 = 'VALIDATION_FAILED',
                            last_updated_date = sysdate
                        WHERE
                                batch_id = p_batch_id
                            AND header_id = header_id_f.header_id
                            AND line_id = wsc_fa_line.line_id;

                        COMMIT;
                        logging_insert('EBS FA', p_batch_id, 11, 'Updated Line ID'
                                                                 || wsc_fa_line.line_id
                                                                 || 'for Header ID'
                                                                 || header_id_f.header_id, lv_line_err_flag,
                                      sysdate);

                        UPDATE wsc_ahcs_int_status_t
                        SET
                            attribute1 = 'L',
                            attribute2 = 'VALIDATION_FAILED',
                            last_updated_date = sysdate
                        WHERE
                                batch_id = p_batch_id
                            AND header_id = header_id_f.header_id;

                        COMMIT;
                        logging_insert('EBS FA', p_batch_id, 12, 'Updated Header ID' || header_id_f.header_id, lv_line_err_flag,
                                      sysdate);

                    END IF;

                END LOOP;

            END LOOP;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                err_msg := substr(sqlerrm, 1, 200);
                logging_insert('EBS FA', p_batch_id, 13, 'Exception: Error in Mandatory Fields check', sqlerrm,
                              sysdate);
        END;

        logging_insert('EBS FA', p_batch_id, 14, 'Ends', NULL,
                      sysdate);
        BEGIN
            logging_insert('EBS FA', p_batch_id, 15, 'Update Status Table - Start', NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'VALIDATION_FAILED',
                error_msg = 'Error in JE_HEADER_ID',
                reextract_required = 'Y',
                attribute1 = 'L',
                attribute2 = 'VALIDATION_FAILED',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND header_id IS NULL;

            COMMIT;
            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'VALIDATION_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status = 'NEW'
                AND error_msg IS NULL;

            COMMIT;
            logging_insert('EBS FA', p_batch_id, 16, 'Status updated in Status Table', NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                attribute2 = 'VALIDATION_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND attribute2 IS NULL;

            COMMIT;
            logging_insert('EBS FA', p_batch_id, 17, 'Attribute2 updated in Status Table', NULL,
                          sysdate);
            OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_sucss;
            CLOSE cur_count_sucss;
            logging_insert('EBS FA', p_batch_id, 18, 'Count Success', lv_count_sucss,
                          sysdate);
            IF lv_count_sucss > 0 THEN
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'VALIDATION_SUCCESS',
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;

                COMMIT;
                BEGIN
                    wsc_ahcs_fa_validation_transformation_pkg.leg_coa_transformation(p_batch_id);
                END;
            ELSE
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'VALIDATION_FAILED',
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;

                COMMIT;
            END IF;

            COMMIT;
            logging_insert('EBS FA', p_batch_id, 36, 'Data Validation Ends', NULL,
                          sysdate);
            logging_insert('EBS FA', p_batch_id, 24, 'Dashboard Starts', NULL,
                          sysdate);
            wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
            logging_insert('EBS FA', p_batch_id, 24, 'Dashboard Ends', NULL,
                          sysdate);
        END;

    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT004', 'EBS_FA', sqlerrm);
    END data_validation;

    PROCEDURE leg_coa_transformation_reprocessing (
        p_batch_id IN NUMBER
    ) IS
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
        CURSOR cur_update_trxn_line_err IS
        SELECT
            line.batch_id,
            line.header_id,
            line.line_id,
            line.target_coa
        FROM
            wsc_ahcs_fa_txn_line_t line,
            wsc_ahcs_int_status_t  status
        WHERE
                status.batch_id = p_batch_id
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
            AND status.batch_id = line.batch_id
            AND status.header_id = line.header_id
            AND status.line_id = line.line_id
            AND status.attribute2 = 'VALIDATION_SUCCESS'; /*ATTRIBUTE2 */

        TYPE update_trxn_line_err_type IS
            TABLE OF cur_update_trxn_line_err%rowtype;
        lv_update_trxn_line_err        update_trxn_line_err_type;
        CURSOR cur_update_trxn_header_err IS
        SELECT DISTINCT
            status.header_id,
            status.batch_id
        FROM
            wsc_ahcs_int_status_t status
        WHERE
                status.batch_id = p_batch_id
            AND status.status = 'TRANSFORM_FAILED';

        TYPE update_trxn_header_err_type IS
            TABLE OF cur_update_trxn_header_err%rowtype;
        lv_update_trxn_header_err      update_trxn_header_err_type;

   ------------------------------------------------------------------------------------------------------------------------------------------------------
   -- Derive the COA map ID for a given source/ target system value.
   -- COA Map ID will subsequently be used to derive the COA mapping rules that are assigned to this source / target combination.
   ------------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_coa_map_id IS
        SELECT
            coa_map_id,
            coa_map.target_system,
            coa_map.source_system
        FROM
            wsc_gl_coa_map_t       coa_map,
            wsc_ahcs_int_control_t ahcs_control
        WHERE
                upper(coa_map.source_system) = upper(ahcs_control.source_system)
            AND upper(coa_map.target_system) = upper(ahcs_control.target_system)
            AND ahcs_control.batch_id = p_batch_id;

   ------------------------------------------------------------------------------------------------------------------------------------------------------
   -- The following cursor will derive the future state COA combination for the given batch_Id for records that have been successfully validated.
   --
   ------------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_leg_seg_value (
            cur_p_src_system VARCHAR2,
            cur_p_tgt_system VARCHAR2
        ) IS
        SELECT
            tgt_coa.leg_coa,
			----------------------------------------------------------------------------------------------------------------------------
			/**********  The following package call will derive the future state COA combination for legacy COA combination ***********/
			--

            wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system, cur_p_tgt_system, tgt_coa.leg_seg1, tgt_coa.leg_seg2, tgt_coa.leg_seg3,
                                               tgt_coa.leg_seg4, tgt_coa.leg_seg5, tgt_coa.leg_seg6, tgt_coa.leg_seg7, tgt_coa.led_leg_name,
                                               NULL, NULL) target_coa 
			--
			-- End of function call to derive target COA.
			----------------------------------------------------------------------------------------------------------------------------                	  

        FROM
            (
                SELECT DISTINCT
                    line.leg_coa,
                    line.leg_seg1,
                    line.leg_seg2,
                    line.leg_seg3,   /*** Fetches distinct legacy combination values ***/
                    line.leg_seg4,
                    line.leg_seg5,
                    line.leg_seg6,
                    line.leg_seg7,
                    header.led_leg_name
                FROM
                    wsc_ahcs_fa_txn_line_t   line,
                    wsc_ahcs_int_status_t    status,
                    wsc_ahcs_fa_txn_header_t header
                WHERE
                        status.batch_id = p_batch_id
                    AND line.target_coa IS NULL
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND header.batch_id = status.batch_id
                    AND header.header_id = status.header_id
                    AND header.header_id = line.header_id
                    AND header.batch_id = line.batch_id
                    AND status.attribute2 = 'TRANSFORM_FAILED'  /*** Check if the record has been successfully validated through validate procedure ***/
            ) tgt_coa;

        TYPE leg_seg_value_type IS
            TABLE OF cur_leg_seg_value%rowtype;
        lv_leg_seg_value               leg_seg_value_type;

		-------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
        -- for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_inserting_ccid_table IS
        SELECT DISTINCT
            line.leg_coa/* || '.' || header.led_leg_name */                                             leg_coa,
            line.target_coa                                          target_coa,
            line.leg_seg1,
            line.leg_seg2,
            line.leg_seg3,
            line.leg_seg4,
            line.leg_seg5,
            line.leg_seg6,
            line.leg_seg7,
            substr(line.leg_coa, instr(line.leg_coa, '.', 1, 7) + 1) AS ledger_name
        FROM
            wsc_ahcs_fa_txn_line_t line
--	    ,wsc_ahcs_fa_txn_header_t  header
        WHERE
                line.batch_id = p_batch_id
--          AND line.batch_id = header.batch_id
--          AND line.header_id = header.header_id
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        /*
		cursor cur_inserting_ccid_table is
			select distinct LEG_COA, TARGET_COA from WSC_AHCS_FA_TXN_LINE_T
			 where batch_id = p_batch_id 
			   and attribute1 = 'Y'   
			   and substr(target_coa,1,instr(target_coa,'.',1,1)-1) is not null;  
	    */

        TYPE inserting_ccid_table_type IS
            TABLE OF cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table        inserting_ccid_table_type;

		------------------------------------------------------------------------------------------------------------------------------------------------------
        -- The following cursor picks up the distinct ledger/ legal entities that have been transformed successfully with future state COA values.
	    -- Ledger name is one of the key defaulting attributes required for processing a journal in AHCS.
		------------------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_get_ledger IS
        WITH main_data AS (
            SELECT
                lgl_entt.ledger_name,
                lgl_entt.legal_entity_name,
                d_lgl_entt.header_id
            FROM
                wsc_gl_legal_entities_t lgl_entt,
                (
                    SELECT DISTINCT
                        line.gl_legal_entity,
                        line.header_id
                    FROM
                        wsc_ahcs_fa_txn_line_t line,
                        wsc_ahcs_int_status_t  status
                    WHERE
                            line.header_id = status.header_id
                        AND line.batch_id = status.batch_id
                        AND line.line_id = status.line_id
                        AND status.batch_id = p_batch_id
                        AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                )                       d_lgl_entt
            WHERE
                lgl_entt.flex_segment_value (+) = d_lgl_entt.gl_legal_entity
        )
        SELECT
            *
        FROM
            main_data a
        WHERE
            a.ledger_name IS NOT NULL
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    main_data b
                WHERE
                        a.header_id = b.header_id
                    AND b.ledger_name IS NULL
            );

        TYPE get_ledger_type IS
            TABLE OF cur_get_ledger%rowtype;
        lv_get_ledger                  get_ledger_type;
        CURSOR cur_count_sucss (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            COUNT(1)
        FROM
            wsc_ahcs_int_status_t
        WHERE
                batch_id = cur_p_batch_id
            AND attribute2 = 'TRANSFORM_SUCCESS'
            AND ( accounting_status IS NULL
                  OR accounting_status = 'IMP_ACC_ERROR' );
			   
			   
		--- @@@@@@@@@@@@@@@@@@@@@@@@   
        ------------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will do a similar matching of total debits and credits but will be restricted at line level. 
        -- ONLY debit not matching to credit at transaction level will be detected after validation.
        ------------------------------------------------------------------------------------------------------------------------------------------------
        /******* @@@@@@@@ Modify this cursor to reflect the appropriate line tables. Also verify the column names are correct @@@@@@@ ********/

        CURSOR cur_line_validation_after_valid (
            cur_p_batch_id NUMBER
        ) IS
        WITH line_cr AS (
            SELECT
                header_id,
                gl_legal_entity,
                SUM(acc_amt) * - 1 sum_data
            FROM
                wsc_ahcs_fa_txn_line_t
            WHERE
                    dr_cr_flag = 'CR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id,
                gl_legal_entity
        ), line_dr AS (
            SELECT
                header_id,
                gl_legal_entity,
                SUM(acc_amt) sum_data
            FROM
                wsc_ahcs_fa_txn_line_t
            WHERE
                    dr_cr_flag = 'DR'
                AND batch_id = cur_p_batch_id
            GROUP BY
                header_id,
                gl_legal_entity
        )
        SELECT
            l_cr.header_id
        FROM
            line_cr l_cr,
            line_dr l_dr
        WHERE
                l_cr.header_id = l_dr.header_id
            AND l_dr.gl_legal_entity = l_cr.gl_legal_entity
            AND ( l_dr.sum_data <> l_cr.sum_data );

		------------------------------------------------------------------------------------------------------------------------------------------------
        CURSOR cur_to_update_status (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
            b.header_id,
            b.batch_id
        FROM
            wsc_ahcs_int_status_t b
        WHERE
                b.status = 'TRANSFORM_FAILED'
            AND b.batch_id = cur_p_batch_id;

        TYPE line_validation_after_valid_type IS
            TABLE OF cur_line_validation_after_valid%rowtype;
        lv_line_validation_after_valid line_validation_after_valid_type;
        lv_coa_mapid                   NUMBER;
        lv_src_system                  VARCHAR2(100);
        lv_tgt_system                  VARCHAR2(100);
        lv_count_succ                  NUMBER;
        retcode                        VARCHAR2(50);
        err_msg                        VARCHAR2(50);
    BEGIN 

        -------------------------------------------------------------------------------------------------------------------------------------------
	--1. Identity the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 19, 'Transformation Starts', NULL,
                      sysdate);
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_mapid,
            lv_tgt_system,
            lv_src_system;
        CLOSE cur_coa_map_id;
        logging_insert('EBS FA', p_batch_id, 20, 'Source & Target Systems', lv_coa_mapid
                                                                            || ' '
                                                                            || lv_tgt_system
                                                                            || ' '
                                                                            || lv_src_system,
                      sysdate);
        
--        update target_coa in fa_line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
	--2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 21, 'Check Data in Cache Table to find COA Combination', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_fa_txn_line_t line
            SET
                target_coa = NULL,
                last_update_date = sysdate
            WHERE
                EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t status
                    WHERE
                            line.batch_id = p_batch_id
                        AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
                        AND status.batch_id = line.batch_id
                        AND status.header_id = line.header_id
                        AND status.line_id = line.line_id
                        AND status.attribute2 = 'TRANSFORM_FAILED'
                );

            UPDATE wsc_ahcs_int_status_t status
            SET
                error_msg = NULL,
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status.attribute2 = 'TRANSFORM_FAILED';

            COMMIT;
        END;

        BEGIN
            UPDATE wsc_ahcs_fa_txn_line_t line
            SET
                target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa, lv_coa_mapid),
                last_update_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND EXISTS (
                    SELECT
                        1
                    FROM --wsc_gl_ccid_mapping_t ccid_map,
                        wsc_ahcs_int_status_t status
                    WHERE /*ccid_map.coa_map_id = lv_coa_mapid and line.leg_coa = ccid_map.source_segment
				    and*/
                            status.batch_id = line.batch_id
                        AND status.header_id = line.header_id
                        AND status.line_id = line.line_id
                        AND status.attribute2 = 'TRANSFORM_FAILED'
                );

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBS FA', p_batch_id, 22, 'Exception: Error in check data in cache table to find COA combination', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

--        update target_coa and attribute1 'Y' in fa_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 23, 'Update Target COA and Attribute1 in Line Table', NULL,
                      sysdate);
        BEGIN
             /* OPEN cur_leg_seg_value(lv_src_system, lv_tgt_system);
            LOOP
                FETCH cur_leg_seg_value BULK COLLECT INTO lv_leg_seg_value LIMIT 100;
                EXIT WHEN lv_leg_seg_value.count = 0;
                FORALL i IN 1..lv_leg_seg_value.count
	         UPDATE wsc_ahcs_fa_txn_line_t  SET target_coa = lv_leg_seg_value(i).target_coa, attribute1 = 'Y',
		  last_update_date = sysdate
		  WHERE leg_coa = lv_leg_seg_value(i).leg_coa AND batch_id = p_batch_id;
		  END LOOP;
		  */


            UPDATE wsc_ahcs_fa_txn_line_t tgt_coa
            SET
                target_coa = wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, tgt_coa.leg_seg1, tgt_coa.leg_seg2, tgt_coa.
                leg_seg3,
                                                                tgt_coa.leg_seg4, tgt_coa.leg_seg5, tgt_coa.leg_seg6, tgt_coa.leg_seg7,
                                                                substr(leg_coa, instr(leg_coa, '.', 1, 7) + 1), NULL, NULL),
                attribute1 = 'Y'
            WHERE
                    batch_id = p_batch_id
                AND target_coa IS NULL
                AND EXISTS (
                    SELECT /*+ index(status WSC_AHCS_INT_STATUS_LINE_ID_I) */
                        1
                    FROM
                        wsc_ahcs_int_status_t status
                    WHERE
                            status.batch_id = p_batch_id
                        AND status.batch_id = tgt_coa.batch_id
                        AND status.header_id = tgt_coa.header_id
                        AND status.line_id = tgt_coa.line_id
                        AND status.attribute2 = 'TRANSFORM_FAILED'
                );

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBS FA', p_batch_id, 24, 'Exception: Error in Update Line Table with Target COA and Attribute1 ', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

--        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 25, 'Insert New Target COA values in CCID Mapping Table', NULL,
                      sysdate);
        BEGIN
            OPEN cur_inserting_ccid_table;
            LOOP
                FETCH cur_inserting_ccid_table
                BULK COLLECT INTO lv_inserting_ccid_table LIMIT 100;
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
                        'EBS FA',
                        'EBS FA',
                        lv_inserting_ccid_table(i).leg_seg1,
                        lv_inserting_ccid_table(i).leg_seg2,
                        lv_inserting_ccid_table(i).leg_seg3,
                        lv_inserting_ccid_table(i).leg_seg4,
                        lv_inserting_ccid_table(i).leg_seg5,
                        lv_inserting_ccid_table(i).leg_seg6,
                        lv_inserting_ccid_table(i).leg_seg7,
                        lv_inserting_ccid_table(i).ledger_name,
                        NULL,
                        NULL
                    );
                --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
            END LOOP;

            CLOSE cur_inserting_ccid_table;
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        UPDATE wsc_ahcs_fa_txn_line_t
        SET
            attribute1 = NULL
        WHERE
            batch_id = p_batch_id;

        COMMIT;

--      update ap_line table target segments,  where legal_entity must have their in target_coa
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 26, 'Update FA Line Table with Target Segments', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_fa_txn_line_t line
            SET
                gl_legal_entity = substr(target_coa, 1, instr(target_coa, '.', 1, 1) - 1),
                gl_oper_grp = substr(target_coa, instr(target_coa, '.', 1, 1) + 1, instr(target_coa, '.', 1, 2) - instr(target_coa, '.',
                1, 1) - 1),
                gl_acct = substr(target_coa, instr(target_coa, '.', 1, 2) + 1, instr(target_coa, '.', 1, 3) - instr(target_coa, '.', 1,
                2) - 1),
                gl_dept = substr(target_coa, instr(target_coa, '.', 1, 3) + 1, instr(target_coa, '.', 1, 4) - instr(target_coa, '.', 1,
                3) - 1),
                gl_site = substr(target_coa, instr(target_coa, '.', 1, 4) + 1, instr(target_coa, '.', 1, 5) - instr(target_coa, '.', 1,
                4) - 1),
                gl_ic = substr(target_coa, instr(target_coa, '.', 1, 5) + 1, instr(target_coa, '.', 1, 6) - instr(target_coa, '.', 1,
                5) - 1),
                gl_projects = substr(target_coa, instr(target_coa, '.', 1, 6) + 1, instr(target_coa, '.', 1, 7) - instr(target_coa, '.',
                1, 6) - 1),
                gl_fut_1 = substr(target_coa, instr(target_coa, '.', 1, 7) + 1, instr(target_coa, '.', 1, 8) - instr(target_coa, '.',
                1, 7) - 1),
                gl_fut_2 = substr(target_coa, instr(target_coa, '.', 1, 8) + 1),
                last_update_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND substr(target_coa, 1, instr(target_coa, '.', 1, 1) - 1) IS NOT NULL
                AND EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t sts
                    WHERE
                            sts.header_id = line.header_id
                        AND sts.line_id = line.line_id
                        AND sts.batch_id = line.batch_id
                        AND sts.attribute2 = 'TRANSFORM_FAILED'
                );

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
                logging_insert('EBS FA', p_batch_id, 27, 'Exception: Error in Update FA Line Table Target Segments', sqlerrm,
                              sysdate);
        END;

--        if any target_coa is empty in fa_line table will mark it as transform_error in status table
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 28, 'Mark Transform_Error in Status Table if any of Target COA is Empty', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    status.attribute2,
                    status.attribute1,
                    status.status,
                    status.error_msg,
                    status.last_updated_date,
                    line.batch_id   bt_id,
                    line.header_id  hdr_id,
                    line.line_id    ln_id,
                    line.target_coa trgt_coa
                FROM
                    wsc_ahcs_int_status_t  status,
                    wsc_ahcs_fa_txn_line_t line
                WHERE
                        line.batch_id = p_batch_id
                    AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
                    AND status.batch_id = line.batch_id
                    AND status.header_id = line.header_id
                    AND status.line_id = line.line_id
                    AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
            )
            SET
                attribute1 = 'L',
                attribute2 = 'TRANSFORM_FAILED',
                status = 'TRANSFORM_FAILED',
                error_msg = trgt_coa,
                last_updated_date = sysdate;

            COMMIT;
            logging_insert('EBS AP', p_batch_id, 19.1, 'updated attribute2 with TRANSFORM_FAILED status', NULL,
                          sysdate);
            FOR rcur_to_update_status IN cur_to_update_status(p_batch_id) LOOP
                UPDATE wsc_ahcs_int_status_t
                SET
                    attribute2 = 'TRANSFORM_FAILED',
                    last_updated_date = sysdate
                WHERE
                        batch_id = rcur_to_update_status.batch_id
                    AND header_id = rcur_to_update_status.header_id;

            END LOOP; 
              
			/*update WSC_AHCS_INT_STATUS_T a
               set ATTRIBUTE2 = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = sysdate
             where exists 
              (select 1 from WSC_AHCS_INT_STATUS_T b 
                where a.batch_id = b.batch_id 
				  and a.header_id = b.header_id 
				  and status = 'TRANSFORM_FAILED'
                  and b.batch_id = p_batch_id ); */

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBS FA', p_batch_id, 29, 'Exception: Mark Transform_Error in Status Table if any of Target COA is Empty',
                sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

--      update ledger_name in ap_header table where transform_success		
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 30, 'Update Ledger Name in FA Header Table', NULL,
                      sysdate);
        BEGIN
           /*    open cur_get_ledger;
            loop
            fetch cur_get_ledger bulk collect into lv_get_ledger limit 100;
            EXIT WHEN lv_get_ledger.COUNT = 0;        
            forall i in 1..lv_get_ledger.count
                update WSC_AHCS_AP_TXN_HEADER_T
                   set ledger_name = lv_get_ledger(i).ledger_name , LAST_UPDATE_DATE = sysdate
                 where batch_id = p_batch_id 
				   and header_id = lv_get_ledger(i).header_id
                   ;
            end loop;  */
            MERGE INTO wsc_ahcs_fa_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT
                              lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t lgl_entt,
                              (
                                  SELECT /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I) */ DISTINCT
                                      line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_fa_txn_line_t line,
                                      wsc_ahcs_int_status_t  status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = p_batch_id
                                      AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                              )                       d_lgl_entt
                          WHERE
                              lgl_entt.flex_segment_value (+) = d_lgl_entt.gl_legal_entity
                      )
                      SELECT DISTINCT
                          a.ledger_name,
                          a.header_id
                      FROM
                          main_data a
                      WHERE
                          a.ledger_name IS NOT NULL
                          AND NOT EXISTS (
                              SELECT
                                  1
                              FROM
                                  main_data b
                              WHERE
                                      a.header_id = b.header_id
                                  AND b.ledger_name IS NULL
                          )
                  )
            e ON ( e.header_id = hdr.header_id )
            WHEN MATCHED THEN UPDATE
            SET hdr.ledger_name = e.ledger_name;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBS FA', p_batch_id, 31, 'Exception: Update Ledger Name in FA Header Table', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
		
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 7.1. Update status tables after validation where line cr/dr mismatch.
        --    /******* ALL RECORDS MARKED AS VALIDATION FAILED WHEN LINE CR/DR AMOUNT MISMATCH AFTER VALIDATION ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 32, 'Update Status Table after Validation', NULL,
                      sysdate);
        /* BEGIN
            OPEN cur_line_validation_after_valid(p_batch_id);
            LOOP
                FETCH cur_line_validation_after_valid BULK COLLECT INTO lv_line_validation_after_valid LIMIT 100;
                EXIT WHEN lv_line_validation_after_valid.count = 0;
                FORALL i IN 1..lv_line_validation_after_valid.count
                    UPDATE wsc_ahcs_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = 'Line DR/CR Amount mismatch after Validation',
                        attribute1 = 'L',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = sysdate
                    WHERE
                            batch_id = p_batch_id
                        AND header_id = lv_line_validation_after_valid(i).header_id;

            END LOOP;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('EBS FA', p_batch_id, 33, 'Exception: Update Status Table after Validation', sqlerrm,sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;
   */
		-------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('EBS FA', p_batch_id, 34, 'Update Status Table with status', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    sts.attribute2,
                    sts.status,
                    sts.last_updated_date,
                    sts.error_msg
                FROM
                    wsc_ahcs_int_status_t    sts,
                    wsc_ahcs_fa_txn_header_t hdr
                WHERE
                        hdr.batch_id = p_batch_id
                    AND hdr.header_id = sts.header_id
                    AND hdr.batch_id = sts.batch_id
                    AND hdr.ledger_name IS NULL
                    AND sts.error_msg IS NULL
                    AND sts.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
            )
            SET
                error_msg = 'Ledger derivation failed',
                attribute2 = 'TRANSFORM_FAILED',
                status = 'TRANSFORM_FAILED',
                last_updated_date = sysdate;

            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'TRANSFORM_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND status IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                AND error_msg IS NULL;

            COMMIT;
            UPDATE wsc_ahcs_int_status_t
            SET
                attribute2 = 'TRANSFORM_SUCCESS',
                last_updated_date = sysdate
            WHERE
                    batch_id = p_batch_id
                AND attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                AND error_msg IS NULL;

            COMMIT;

			-------------------------------------------------------------------------------------------------------------------------------------------
			-- 9. Flag the control table to consider this file as TRANSFORMATION COMPLETE. 
			--    /************ THIS WILL SIGNAL OIC TO PICK THIS FILE FOR UCM UPLOAD BY MASTER SCHEDULER ***********************/
			-------------------------------------------------------------------------------------------------------------------------------------------

            OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_succ;
            CLOSE cur_count_sucss;
            IF lv_count_succ > 0 THEN
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'TRANSFORM_SUCCESS',
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            ELSE
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'TRANSFORM_FAILED',
                    last_updated_date = sysdate
                WHERE
                    batch_id = p_batch_id;

            END IF;

            COMMIT;
        END;

        logging_insert('EBS FA', p_batch_id, 303, 'Dashboard Starts', NULL,
                      sysdate);
        wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
        logging_insert('EBS FA', p_batch_id, 304, 'Dashboard Ends', NULL,
                      sysdate);
        logging_insert('EBS FA', p_batch_id, 35, 'Transformation Ends', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT004', 'EBS_FA', sqlerrm);
    END leg_coa_transformation_reprocessing;

END wsc_ahcs_fa_validation_transformation_pkg;
/