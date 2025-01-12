create or replace PACKAGE BODY wsc_ahcs_eclipse_validation_transformation_pkg AS

    err_msg VARCHAR2(100);

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


    PROCEDURE LEG_COA_TRANSFORMATION (
                                        p_batch_id IN NUMBER
                                     ) AS
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
        l_system     VARCHAR2(30);

        CURSOR cur_update_trxn_line_err IS
        SELECT
            line.batch_id,
            line.header_id,
            line.line_id,
            line.target_coa
        FROM
            wsc_ahcs_eclipse_txn_line_t line,
            wsc_ahcs_int_status_t    status
        WHERE
                line.batch_id = p_batch_id
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
            AND status.batch_id = line.batch_id
            AND status.header_id = line.header_id
            AND status.line_id = line.line_id
            AND status.attribute2 = 'VALIDATION_SUCCESS'; /*ATTRIBUTE2 */

        TYPE update_trxn_line_err_type IS
            TABLE OF cur_update_trxn_line_err%rowtype;
        lv_update_trxn_line_err   update_trxn_line_err_type;

        CURSOR cur_update_trxn_header_err IS
        SELECT DISTINCT
            status.header_id,
            status.batch_id
        FROM wsc_ahcs_int_status_t status
        WHERE
                status.batch_id = p_batch_id
            AND status.status = 'TRANSFORM_FAILED';

        TYPE update_trxn_header_err_type IS
            TABLE OF cur_update_trxn_header_err%rowtype;
        lv_update_trxn_header_err update_trxn_header_err_type;
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

    --        CURSOR cur_leg_seg_value (
    --            cur_p_src_system  VARCHAR2,
    --            cur_p_tgt_system  VARCHAR2
    --        ) IS
    --        SELECT
    --            tgt_coa.leg_coa,
    --			----------------------------------------------------------------------------------------------------------------------------
    --			/**********  The following package call will derive the future state COA combination for legacy COA combination ***********/
    --			--
    --
    --            wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system, cur_p_tgt_system, tgt_coa.leg_seg1, tgt_coa.leg_seg2,
    --                                               tgt_coa.leg_seg3,
    --                                               tgt_coa.leg_seg4,
    --                                               tgt_coa.leg_seg5,
    --                                               tgt_coa.leg_seg6,
    --                                               tgt_coa.leg_seg7,
    --                                               tgt_coa.leg_led_name,
    --                                               NULL,
    --                                               NULL) target_coa 
    --			--
    --			-- End of function call to derive target COA.
    --			----------------------------------------------------------------------------------------------------------------------------                	  
    --
    --        FROM
    --            (
    --                SELECT DISTINCT
    --                    line.GL_BUSINESS_UNIT,
    --                    line.GL_ACCOUNT,
    --                    line.GL_DEPARTMENT,
    --                    line.GL_LOCATION,   /*** Fetches distinct legacy combination values ***/
    --                    line.GL_VENDOR_NBR_FULL,
    --                    line.AFFILIATE
    --                FROM
    --                    wsc_ahcs_eclipse_txn_line_t    line,
    --                    wsc_ahcs_int_status_t     status
    ----                    wsc_ahcs_eclipse_txn_header_t  header
    --                WHERE
    --                        status.batch_id = p_batch_id
    --                    AND line.target_coa IS NULL
    --                    AND status.batch_id = line.batch_id
    --                    AND status.header_id = line.header_id
    --                    AND status.line_id = line.line_id
    --                    AND header.batch_id = status.batch_id
    --                    AND header.header_id = status.header_id
    --                    AND header.header_id = line.header_id
    --                    AND header.batch_id = line.batch_id
    --                    AND status.attribute2 = 'VALIDATION_SUCCESS'  /*** Check if the record has been successfully validated through validate procedure ***/
    --            ) tgt_coa;
    --
    --        TYPE leg_seg_value_type IS
    --            TABLE OF cur_leg_seg_value%rowtype;
    --        lv_leg_seg_value                leg_seg_value_type;

        -------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursor will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
        -- for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_inserting_ccid_table IS
        SELECT DISTINCT
            line.leg_coa    leg_coa,
            line.target_coa target_coa,
            line.LEG_BU,
            line.LEG_ACCT,
            line.LEG_DEPT,
            line.LEG_LOC,
            line.LEG_VENDOR,
            line.LEG_AFFILIATE
    --            line.leg_seg7,
    --            substr(line.leg_coa, instr(line.leg_coa, '.', 1, 7) + 1)                      AS ledger_name
        FROM
            wsc_ahcs_eclipse_txn_line_t line
    --              , wsc_ahcs_eclipse_txn_header_t header
        WHERE
                line.batch_id = p_batch_id 
    --			   and line.batch_id = header.batch_id
    --			   and line.header_id = header.header_id
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        /*
        cursor cur_inserting_ccid_table is
            select distinct LEG_COA, TARGET_COA from wsc_ahcs_eclipse_txn_line_t
             where batch_id = p_batch_id 
               and attribute1 = 'Y'   
               and substr(target_coa,1,instr(target_coa,'.',1,1)-1) is not null;  
        */

        TYPE inserting_ccid_table_type IS
            TABLE OF cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table   inserting_ccid_table_type;

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
                        wsc_ahcs_eclipse_txn_line_t line,
                        wsc_ahcs_int_status_t    status
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
        lv_get_ledger             get_ledger_type;

        /*CURSOR cur_count_sucss (
            cur_p_batch_id NUMBER
        )*/
        CURSOR cur_count_error (
            cur_p_batch_id NUMBER
        )
		IS
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

    --        CURSOR cur_line_validation_after_valid (
    --            cur_p_batch_id NUMBER
    --        ) IS
    --        WITH line_cr AS (
    --            SELECT
    --                header_id,
    --                gl_legal_entity,
    --                SUM(acc_amt) * - 1 sum_data
    --            FROM
    --                wsc_ahcs_eclipse_txn_line_t
    --            WHERE
    --                    dr_cr_flag = 'CR'
    --                AND batch_id = cur_p_batch_id
    --            GROUP BY
    --                header_id,
    --                gl_legal_entity
    --        ), line_dr AS (
    --            SELECT
    --                header_id,
    --                gl_legal_entity,
    --                SUM(acc_amt) sum_data
    --            FROM
    --                wsc_ahcs_eclipse_txn_line_t
    --            WHERE
    --                    dr_cr_flag = 'DR'
    --                AND batch_id = cur_p_batch_id
    --            GROUP BY
    --                header_id,
    --                gl_legal_entity
    --        )
    --        SELECT
    --            l_cr.header_id
    --        FROM
    --            line_cr  l_cr,
    --            line_dr  l_dr
    --        WHERE
    --                l_cr.header_id = l_dr.header_id
    --            AND l_dr.gl_legal_entity = l_cr.gl_legal_entity
    --            AND ( l_dr.sum_data <> l_cr.sum_data );

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

    --        TYPE line_validation_after_valid_type IS
    --            TABLE OF cur_line_validation_after_valid%rowtype;
    --        lv_line_validation_after_valid  line_validation_after_valid_type;

        lv_coa_mapid              NUMBER;
        lv_src_system             VARCHAR2(100);
        lv_tgt_system             VARCHAR2(100);
        lv_count_succ             NUMBER;
		lv_count_err              NUMBER;
    BEGIN
        BEGIN
            SELECT
                attribute3
            INTO l_system
            FROM
                wsc_ahcs_int_control_t c
            WHERE
                c.batch_id = p_batch_id;
            dbms_output.put_line(l_system);
        END;
        -------------------------------------------------------------------------------------------------------------------------------------------
    --1. Identity the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('ECLIPSE', p_batch_id,17,'TRANSFORMATION STARTS',NULL,SYSDATE);
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_mapid,
            lv_tgt_system,
            lv_src_system;
        CLOSE cur_coa_map_id;
       /* logging_insert('ECLIPSE', p_batch_id, 15, 'Transformation start', lv_coa_mapid
                                                                             || lv_tgt_system
                                                                             || lv_src_system,
                      SYSDATE); */

    --        update target_coa in eclipse_line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
    --2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('ECLIPSE', p_batch_id,18,'CHECK DATA IN CACHE TABLE TO FIND', NULL,SYSDATE);
        BEGIN
            UPDATE wsc_ahcs_eclipse_txn_line_t line
            SET
                target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa, lv_coa_mapid),
                last_update_date = SYSDATE
            WHERE
                batch_id = p_batch_id
               /*and exists 
                (select 1 from /*wsc_gl_ccid_mapping_t ccid_map,*/
                         --WSC_AHCS_INT_STATUS_T status 
                  --where /*ccid_map.coa_map_id = lv_coa_mapid and line.leg_coa = ccid_map.source_segment
    --				    and */ status.batch_id = line.batch_id
                   /* and status.header_id = line.header_id
                    and status.line_id = line.line_id
                    and status.status = 'VALIDATION_SUCCESS'
                    and status.attribute2 = 'VALIDATION_SUCCESS'
                    AND batch_id = p_batch_id)*/;
            COMMIT;
            EXCEPTION
            WHEN OTHERS THEN
    logging_insert('ECLIPSE',p_batch_id,206,'ERROR IN CHECK DATA IN CACHE TABLE TO FIND',SQLERRM,SYSDATE);
    dbms_output.put_line('Error with Query:  ' || SQLERRM);
        END;

    --        update target_coa and attribute1 'Y' in eclipse_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('ECLIPSE', p_batch_id, 19, 'UPDATE TARGET_COA AND ATTRIBUTE1', NULL,SYSDATE);
        BEGIN
         /*   open cur_leg_seg_value(lv_src_system, lv_tgt_system);
            loop
            fetch cur_leg_seg_value bulk collect into lv_leg_seg_value limit 100;
            EXIT WHEN lv_leg_seg_value.COUNT = 0;        
            forall i in 1..lv_leg_seg_value.count
                update wsc_ahcs_eclipse_txn_line_t set target_coa = lv_leg_seg_value(i).target_coa,  ATTRIBUTE1 = 'Y', 
                LAST_UPDATE_DATE = SYSDATE 
                where LEG_COA = lv_leg_seg_value(i).LEG_COA and batch_id = p_batch_id;
            end loop;
    */

            UPDATE wsc_ahcs_eclipse_txn_line_t tgt_coa
            SET
                target_coa = replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, tgt_coa.LEG_BU, tgt_coa.LEG_LOC,
                tgt_coa.LEG_DEPT,
                                                                tgt_coa.LEG_ACCT, tgt_coa.LEG_VENDOR, nvl(tgt_coa.LEG_AFFILIATE,
                                                                '00000'), NULL, NULL, NULL, NULL),' ' , ''),
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
    logging_insert('ECLIPSE', p_batch_id,207, 'ERROR IN UPDATE TARGET_COA AND ATTRIBUTE1', SQLERRM,SYSDATE);
    dbms_output.put_line('Error with Query:  ' || SQLERRM);
        END;

    --        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('ECLIPSE', p_batch_id, 20, 'INSERT NEW TARGET_COA VALUES', NULL,SYSDATE);
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
                        SYSDATE,
                        SYSDATE,
                        'Y',
                        'N',
                        'ECLIPSE',
                        'ECLIPSE',
                        lv_inserting_ccid_table(i).LEG_BU,
                        lv_inserting_ccid_table(i).LEG_LOC,
                        lv_inserting_ccid_table(i).LEG_DEPT,
                        lv_inserting_ccid_table(i).LEG_ACCT,
                        lv_inserting_ccid_table(i).LEG_VENDOR,
                        lv_inserting_ccid_table(i).LEG_AFFILIATE,
                        NULL,
                        NULL,
                        NULL,
                        NULL
                    );

                --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, SYSDATE, SYSDATE, 'Y');
            END LOOP;
        CLOSE cur_inserting_ccid_table;

            UPDATE wsc_ahcs_eclipse_txn_line_t
            SET
                attribute1 = NULL
            WHERE
                batch_id = p_batch_id;
            COMMIT;
            EXCEPTION 
			WHEN OTHERS THEN
logging_insert('ECLIPSE', p_batch_id, 207,'ERROR', SQLERRM,SYSDATE);
     END;

    --      update eclipse_line table target segments,  where legal_entity must have their in target_coa
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('ECLIPSE', p_batch_id,20,'UPDATE ECLIPSE LINE TABLE TARGET SEGMENTS', NULL,SYSDATE);
        BEGIN
            UPDATE wsc_ahcs_eclipse_txn_line_t
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
                last_update_date = SYSDATE
            WHERE
                    batch_id = p_batch_id
                AND substr(target_coa, 1, instr(target_coa, '.', 1, 1) - 1) IS NOT NULL;
            COMMIT;
            EXCEPTION
            WHEN OTHERS THEN
    dbms_output.put_line('Error with Query:  ' || SQLERRM);
    logging_insert('ECLIPSE',p_batch_id,22,'ERROR IN UPDATE ECLIPSE LINE TABLE TARGET SEGMENTS',SQLERRM,SYSDATE);
    END;

    --        if any target_coa is empty in eclipse_line table will mark it as transform_error in status table
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
   -- logging_insert('ECLIPSE',p_batch_id,21,'IF ANY TARGET_COA IS EMPTY', NULL,SYSDATE);
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
                    wsc_ahcs_int_status_t    status,
                    wsc_ahcs_eclipse_txn_line_t line
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
                last_updated_date = SYSDATE;
            COMMIT;

    --logging_insert('ECLIPSE', p_batch_id, 21.1,'UPDATED ATTRIBUTE2 WITH TRANSFORM_FAILED STATUS', NULL,SYSDATE);

            FOR rcur_to_update_status IN cur_to_update_status(p_batch_id) LOOP
                UPDATE wsc_ahcs_int_status_t
                SET
                    attribute2 = 'TRANSFORM_FAILED',
                    last_updated_date = SYSDATE
                WHERE
                        batch_id = rcur_to_update_status.batch_id
                    AND header_id = rcur_to_update_status.header_id;
            END LOOP;  

            /*update WSC_AHCS_INT_STATUS_T a
               set ATTRIBUTE2 = 'TRANSFORM_FAILED', LAST_UPDATED_DATE = SYSDATE
             where a.batch_id = p_batch_id
               AND exists 
              (select 1 from WSC_AHCS_INT_STATUS_T b 
                where a.batch_id = b.batch_id 
                  and a.header_id = b.header_id 
                  and b.status = 'TRANSFORM_FAILED'
                  and b.batch_id = p_batch_id );
                  logging_insert('ECLIPSE',p_batch_id,19.2,'updated attribute2 with TRANSFORM_FAILED status',null,SYSDATE);
                  /*merge into WSC_AHCS_INT_STATUS_T a
                    using (select b.header_id,b.batch_id
                            from WSC_AHCS_INT_STATUS_T b 
                        where b.status = 'TRANSFORM_FAILED'
                          and b.batch_id = p_batch_id) b
                          on (a.batch_id = b.batch_id 
                          and a.header_id = b.header_id 
                          and a.batch_id = p_batch_id)
                        when matched then
                        update set a.ATTRIBUTE2 = 'TRANSFORM_FAILED', a.LAST_UPDATED_DATE = SYSDATE;*/
            COMMIT;
            EXCEPTION
            WHEN OTHERS THEN
    logging_insert('ECLIPSE',p_batch_id,207,'ERROR IN IF ANY TARGET_COA IS EMPTY',SQLERRM,SYSDATE);
    dbms_output.put_line('Error with Query:  ' || SQLERRM);
        END;

    --      update ledger_name in eclipse_header table where transform_success		
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('ECLIPSE', p_batch_id, 23,'UPDATE LEDGER_NAME STARTS', NULL,SYSDATE);

        BEGIN
    --         /*   open cur_get_ledger;
    --            loop
    --            fetch cur_get_ledger bulk collect into lv_get_ledger limit 10;
    --            EXIT WHEN lv_get_ledger.COUNT = 0;        
    --            forall i in 1..lv_get_ledger.count
    --                update wsc_ahcs_eclipse_txn_header_t
    --                   set ledger_name = lv_get_ledger(i).ledger_name , LAST_UPDATE_DATE = SYSDATE
    --                 where batch_id = p_batch_id 
    --				   and header_id = lv_get_ledger(i).header_id
    --                   ;
    --            end loop;*/

    --
            MERGE INTO wsc_ahcs_eclipse_txn_header_t hdr
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
                                      wsc_ahcs_eclipse_txn_line_t line,
                                      wsc_ahcs_int_status_t    status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = p_batch_id
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

            MERGE INTO wsc_ahcs_eclipse_txn_header_t hdr
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
                                      wsc_ahcs_eclipse_txn_line_t line,
                                      wsc_ahcs_int_status_t    status
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
    logging_insert('ECLIPSE', p_batch_id, 208, 'ERROR IN UPDATE LEDGER_NAME',SQLERRM,SYSDATE);
    dbms_output.put_line('Error with Query:  ' || SQLERRM);
        END;
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 7.1. Update status tables after validation where line cr/dr mismatch.
        --    /******* ALL RECORDS MARKED AS VALIDATION FAILED WHEN LINE CR/DR AMOUNT MISMATCH AFTER VALIDATION ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('ECLIPSE',p_batch_id,24,'STARTS UPDATE STATUS TABLE AFTER VALIDATION SUCCESS',NULL,SYSDATE);
        /*begin
            open cur_line_validation_after_valid(p_batch_id);
            loop
            fetch cur_line_validation_after_valid bulk collect into lv_line_validation_after_valid limit 100;
            EXIT WHEN lv_line_validation_after_valid.COUNT = 0;        
            forall i in 1..lv_line_validation_after_valid.count
                update WSC_AHCS_INT_STATUS_T set STATUS = 'VALIDATION_FAILED', 
                    ERROR_MSG = 'Line DR/CR amount mismatch after validation', 
                    ATTRIBUTE1 = 'L',
                    ATTRIBUTE2='VALIDATION_FAILED', 
                    LAST_UPDATED_DATE = SYSDATE
                where BATCH_ID = P_BATCH_ID 
                  and HEADER_ID = lv_line_validation_after_valid(i).header_id;
            end loop;
            commit;
        exception
            when others then
                logging_insert('ECLIPSE',p_batch_id,23,'Update status tables after validation',SQLERRM,SYSDATE);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end; */

        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
    logging_insert('ECLIPSE',p_batch_id,25,'UPDATE STATUS TABLE TO HAVE STATUS TRANSFORM SUCCESS ', NULL,SYSDATE);
        BEGIN
               UPDATE (
                    SELECT
                        sts.attribute2,
                        sts.status,
                        sts.last_updated_date,
                        sts.error_msg
                    FROM
                        wsc_ahcs_int_status_t     sts,
                        wsc_ahcs_eclipse_txn_header_t  hdr
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
                    last_updated_date = SYSDATE;

            UPDATE wsc_ahcs_int_status_t
            SET
                status = 'TRANSFORM_SUCCESS',
                last_updated_date = SYSDATE
            WHERE
                    batch_id = p_batch_id
                AND status = 'VALIDATION_SUCCESS'
                AND attribute2 = 'VALIDATION_SUCCESS'
                AND error_msg IS NULL;
            COMMIT;

            UPDATE wsc_ahcs_int_status_t
            SET
                attribute2 = 'TRANSFORM_SUCCESS',
                last_updated_date = SYSDATE
            WHERE
                    batch_id = p_batch_id
                AND attribute2 = 'VALIDATION_SUCCESS'
                AND error_msg IS NULL;
            COMMIT;

            -------------------------------------------------------------------------------------------------------------------------------------------
            -- 9. Flag the control table to consider this file as TRANSFORMATION COMPLETE. 
            --    /************ THIS WILL SIGNAL OIC TO PICK THIS FILE FOR UCM UPLOAD BY MASTER SCHEDULER ***********************/
            -------------------------------------------------------------------------------------------------------------------------------------------

           /* OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_succ;
            CLOSE cur_count_sucss;*/
			
			OPEN cur_count_error(p_batch_id);
            FETCH cur_count_error INTO lv_count_err;
            CLOSE cur_count_error;
            IF lv_count_err > 0 THEN
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'TRANSFORM_SUCCESS',
                    last_updated_date = SYSDATE
                WHERE
                    batch_id = p_batch_id;
            ELSE
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'TRANSFORM_FAILED',
                    last_updated_date = SYSDATE
                WHERE
                    batch_id = p_batch_id;
            END IF;
            COMMIT;
    END;

    logging_insert('ECLIPSE',p_batch_id,26,'TRANSFORMATION ENDS',NULL,SYSDATE);
        EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT124'
                                                                 || '_'
                                                                 || l_system, 'ECLIPSE', SQLERRM);
 END LEG_COA_TRANSFORMATION;


 PROCEDURE DATA_VALIDATION (
                              p_batch_id IN NUMBER
                           ) IS 

-- TODO: Implementation required for PROCEDURE WSC_AHCS_ECLIPSE_VALIDATION_TRANSFORMATION_PKG.DATA_VALIDATION
        lv_header_err_msg    VARCHAR2(2000) := NULL;
        lv_line_err_msg      VARCHAR2(2000) := NULL;
        lv_header_err_flag   VARCHAR2(100) := 'false';
        lv_line_err_flag     VARCHAR2(100) := 'false';
        l_system             VARCHAR2(30);
        lv_count_sucss       NUMBER := 0;
		lv_count_error       NUMBER := 0;
        retcode              NUMBER;
        total_sum            NUMBER;
		

            TYPE wsc_header_col_value_type IS
            VARRAY(70) OF VARCHAR2(200); 

/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING HEADER OBJECT TYPE ARGUMENT @@@@@@@ ********************************/
/************* @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/

            lv_header_col_value  wsc_header_col_value_type := wsc_header_col_value_type('TRANSACTION_DATE',
                                                                                        'TRANSACTION_NUMBER',
                                                                                        'FILE_NAME'
		                                                                               );


            TYPE wsc_line_col_value_type IS
            VARRAY(40) OF VARCHAR2(200); 

/************* @@@@@ INSERT YOUR CHANGES HERE TO USE THE CORRESPONDING LINE OBJECT TYPE ARGUMENT @@@@@@@  ********************************/
/************* @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/

            lv_line_col_value    wsc_line_col_value_type := wsc_line_col_value_type('ACC_AMT', 
                                                                                'LEG_TRAN_DATE', 
                                                                                'CURRENCY',   
                                                                                'ACC_CURRENCY', 
                                                                                'LEG_BU',  
                                                                                'BU_UNIT_GL', 
                                                                                'TRANS_REF_NBR', 
                                                                                'SOURCE', 
                                                                                'LEG_ACCT',
                                                                                'LEG_DEPT', 
                                                                                'LEG_LOC', 
                                                                                'LEG_LEDGER',
                                                                                'LEDGER_GROUP',
                                                                                'TRANSACTION_NUMBER',
                                                                                'AMOUNT',
                                                                                'DESCRIPTION'
		                                                                        );

/************ @@@@@ INITIALIZE HEADER AND LINE FLAG TABLE TYPE VARIABLES TO MATCH THE COUNT OF HEADER AND LINE @@@@@ ************/
/************ @@@@@ CHANGE THE TABLE TYPE & VARIABLE NAMES FOR THE HEADER & LINE TABLE TYPES  @@@@@@@@@@@ ***********************/

        TYPE wsc_ahcs_eclipse_header_txn_t_type IS
        TABLE OF INTEGER;
        lv_error_eclipse_header wsc_ahcs_eclipse_header_txn_t_type := wsc_ahcs_eclipse_header_txn_t_type('1', '1', '1');

        TYPE wsc_ahcs_eclipse_line_txn_t_type IS
        TABLE OF INTEGER;
        lv_error_eclipse_line   wsc_ahcs_eclipse_line_txn_t_type := wsc_ahcs_eclipse_line_txn_t_type('1', '1', '1', '1',
                                                                                                     '1', '1', '1', '1',
                                                                                                     '1', '1', '1', '1',
                                                                                                     '1', '1', '1', '1'
                                                                                                    ); 


-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from HEADER STAGING TABLE THAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
       CURSOR cur_header_id (
            cur_p_batch_id NUMBER
        ) IS
        SELECT
		     HEADER_ID,
		     TRANSACTION_DATE,
             TRANSACTION_NUMBER,
             FILE_NAME
        FROM
            WSC_AHCS_ECLIPSE_TXN_HEADER_T
        WHERE
            batch_id = cur_p_batch_id;  /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/ 


-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Following cursor will fetch ALL COLUMN NAMES from LINE STAGING TABLE THAT MUST BE VALIDATED for data types
-------------------------------------------------------------------------------------------------------------------------------------------------------
       CURSOR cur_wsc_eclipse_line (
              cur_p_hdr_id VARCHAR2
                                 ) IS
        SELECT
          LINE_ID,
		  ACC_AMT, 
          LEG_TRAN_DATE, 
          CURRENCY,   
          ACC_CURRENCY, 
          LEG_BU,  
          BU_UNIT_GL, 
          TRANS_REF_NBR, 
          SOURCE, 
          LEG_ACCT,
          LEG_DEPT, 
          LEG_LOC, 
          LEG_LEDGER,
          LEDGER_GROUP,
          TRANSACTION_NUMBER,
          AMOUNT,
          DESCRIPTION
        FROM
            WSC_AHCS_ECLIPSE_TXN_LINE_T
        WHERE
            header_id = cur_p_hdr_id; /******** @@@@@@@@@@@@ MODIFY TABLE NAME & COLUMN NAMES TO BE VALIDATED @@@@@@@@@@****/
			
			
			
	  ----LINE AMOUNT VALIDATION
     /*   CURSOR 	CUR_LINE_AMOUNT_VALIDATION (
		                                  cur_p_batch_id NUMBER
									   ) IS
									   WITH line_amt AS (
									                      SELECT HEADER_ID,ABS(SUM(AMOUNT))SUM_AMOUNT FROM WSC_AHCS_ECLIPSE_TXN_LINE_T
														  WHERE BATCH_ID= cur_p_batch_id
														  GROUP BY HEADER_ID
									                    )
														SELECT lnamt.HEADER_ID FROM line_amt lnamt
														WHERE lnamt.SUM_AMOUNT <>0
														AND HEADER_ID=lnamt.HEADER_ID;
												
												
		TYPE line_amount_validation_type IS
            TABLE OF CUR_LINE_AMOUNT_VALIDATION%rowtype;
        lv_line_amt_validation   line_amount_validation_type; */ ---- DP-RTR-AHCS-114


        /*CURSOR cur_count_sucss  (
                                 cur_p_batch_id NUMBER
                                ) */
								
		CURSOR cur_count_error  (
                                 cur_p_batch_id NUMBER
                                )IS
       /* SELECT COUNT(1)
        FROM wsc_ahcs_int_status_t
        WHERE
		    batch_id = cur_p_batch_id
            AND attribute2 = 'VALIDATION_SUCCESS'; */
			
		SELECT COUNT(1)
        FROM wsc_ahcs_int_status_t
        WHERE
		    batch_id = cur_p_batch_id
            AND attribute2 <> 'VALIDATION_SUCCESS';

		    err_msg       VARCHAR2(2000);	
BEGIN
    logging_insert('ECLIPSE', p_batch_id, 11, 'START OF MANDATORY FIELDS VALIDATION', NULL,SYSDATE);			  
	BEGIN 
	       SELECT attribute3
            INTO l_system
            FROM wsc_ahcs_int_control_t c
            WHERE
                c.batch_id = p_batch_id;
            dbms_output.put_line(l_system);
	END;

    logging_insert('ECLIPSE',p_batch_id,12,'VALIDATE MANDATORY HEADER COLUMNS STARTS', NULL, SYSDATE);

		FOR header_id_f IN cur_header_id(p_batch_id) LOOP
		        lv_header_err_flag := 'false';
                lv_header_err_msg := NULL;
                lv_error_eclipse_header := wsc_ahcs_eclipse_header_txn_t_type('1', '1', '1');
                lv_error_eclipse_header(1) := is_date_null(header_id_f.transaction_date);
                lv_error_eclipse_header(2) := is_varchar2_null(header_id_f.transaction_number);
                lv_error_eclipse_header(3) := is_varchar2_null(header_id_f.file_name);

		    FOR i IN 1..3 LOOP
                IF lv_error_eclipse_header(i) = 0 
					   THEN
                        lv_header_err_msg := lv_header_err_msg
                                             || '300|Missing Value of'
                                             || lv_header_col_value(i)
                                             || '. ';
                        lv_header_err_flag := 'true';
                END IF;
            END LOOP;

				    IF lv_header_err_flag = 'true' THEN
                    UPDATE wsc_ahcs_int_status_t
                        SET
						    status = 'VALIDATION_FAILED',
                            error_msg = lv_header_err_msg,
                            reextract_required = 'Y',
                            attribute1 = 'H',
                            attribute2 = 'VALIDATION_FAILED',
                            last_updated_date = SYSDATE
                        WHERE
                            batch_id = p_batch_id
                            AND status = 'NEW'
                            AND header_id = header_id_f.header_id;
                        COMMIT;

    logging_insert('ECLIPSE',p_batch_id,204,'MANDATORY COLUMN VALIDATION FAILED FOR HEADER FOR:' || header_id_f.header_id,lv_header_err_flag,SYSDATE);

                    CONTINUE;               
                    END IF;

    logging_insert('ECLIPSE',p_batch_id,13,'VALIDATE MANDATORY LINE COLUMNS STARTS', header_id_f.header_id, SYSDATE);

		FOR wsc_eclipse_line IN cur_wsc_eclipse_line(header_id_f.header_id) LOOP
                lv_line_err_flag := 'false';
                lv_line_err_msg := NULL;
                lv_error_eclipse_line := wsc_ahcs_eclipse_line_txn_t_type('1', '1', '1', '1',
                                                                          '1', '1', '1', '1',
                                                                          '1', '1', '1', '1',
                                                                          '1', '1', '1', '1');
		BEGIN																  
                lv_error_eclipse_line(1) := is_number_null(wsc_eclipse_line.acc_amt);
                lv_error_eclipse_line(2) := is_date_null(wsc_eclipse_line.leg_tran_date);
                lv_error_eclipse_line(3) := is_varchar2_null(wsc_eclipse_line.currency);
                lv_error_eclipse_line(4) := is_varchar2_null(wsc_eclipse_line.acc_currency);
                lv_error_eclipse_line(5) := is_varchar2_null(wsc_eclipse_line.leg_bu);
                lv_error_eclipse_line(6):= is_varchar2_null(wsc_eclipse_line.bu_unit_gl);
                lv_error_eclipse_line(7) := is_varchar2_null(wsc_eclipse_line.trans_ref_nbr);
                lv_error_eclipse_line(8) := is_varchar2_null(wsc_eclipse_line.source);
                lv_error_eclipse_line(9) := is_varchar2_null(wsc_eclipse_line.LEG_ACCT);
				lv_error_eclipse_line(10) := is_varchar2_null(wsc_eclipse_line.leg_dept);
                lv_error_eclipse_line(11) := is_varchar2_null(wsc_eclipse_line.LEG_LOC);
                lv_error_eclipse_line(12) := is_varchar2_null(wsc_eclipse_line.leg_ledger);
                lv_error_eclipse_line(13) := is_varchar2_null(wsc_eclipse_line.ledger_group);
                lv_error_eclipse_line(14) := is_varchar2_null(wsc_eclipse_line.transaction_number);
                lv_error_eclipse_line(15) := is_varchar2_null(wsc_eclipse_line.amount);
                lv_error_eclipse_line(16) := is_varchar2_null(wsc_eclipse_line.description);
		EXCEPTION 
		WHEN OTHERS THEN
    logging_insert('ECLIPSE', p_batch_id,205,'ERROR MANDATORY LINE COLUMN MISSING',SQLERRM,SYSDATE);
		END;
    		    FOR j IN 1..16 LOOP
                    IF lv_error_eclipse_line(j) = 0 THEN
                        lv_line_err_msg := lv_line_err_msg
                                           || '300|Missng value of '
                                           || lv_line_col_value(j)
                                           || '. ';
                        lv_line_err_flag := 'true';
                    END IF;
                END LOOP;	   

                   IF lv_line_err_flag = 'true' THEN
                    UPDATE wsc_ahcs_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        error_msg = nvl(error_msg
                                       -- || ','
                                        || lv_line_err_msg, lv_line_err_msg),
                        reextract_required = 'Y',
                        attribute1 = 'L',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = SYSDATE
                    WHERE
                        batch_id = p_batch_id
                        AND status = 'NEW'
                        AND header_id = header_id_f.header_id
                        AND line_id = wsc_eclipse_line.line_id;

                    UPDATE wsc_ahcs_int_status_t
                    SET
                        attribute1 = 'L',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = SYSDATE
                    WHERE
                            batch_id = p_batch_id
                        AND status = 'NEW'
                        AND header_id = header_id_f.header_id;
                END IF;
            END LOOP;

/*logging_insert('ECLIPSE',p_batch_id, 204,'MANDATORY FIELD VALIDATION FAILED FOR HEADER' || header_id_f.header_id,lv_header_err_flag,SYSDATE);*/

logging_insert('ECLIPSE', p_batch_id, 14,'HEADER LINE MANDATORY COLUMN VALIDATION COMPLETED FOR:  ' || 'HEADER_ID:' || header_id_f.header_id,lv_header_err_flag,SYSDATE);
           END LOOP;   
/****MANDATORY COLUMN CHECK COMPLETED*****/


/****LINE VALIDATION START HERE****/
		/*BEGIN   
		    --SELECT SUM(amount) INTO total_sum FROM wsc_ahcs_eclipse_txn_line_t WHERE batch_id = p_batch_id;		
            SELECT SUM(amount) INTO total_sum FROM wsc_ahcs_eclipse_txn_line_t WHERE batch_id = p_batch_id GROUP BY HEADER_ID;						
			IF total_sum <> 0 THEN
			UPDATE wsc_ahcs_int_status_t
                    SET
                        status = 'VALIDATION_FAILED',
                        --error_msg = 'VALIDATION FAILED LINE AMOUNT NOT EQUAL TO ZERO',
						error_msg = '301|Line DR/CR amount mismatch',
                        reextract_required = 'Y',
                        attribute1 = 'L',
                        attribute2 = 'VALIDATION_FAILED',
                        last_updated_date = SYSDATE
                    WHERE
                        batch_id = p_batch_id;
			END IF;
		END; */
		
	/*	BEGIN
		OPEN CUR_LINE_AMOUNT_VALIDATION(p_batch_id);
		LOOP
		FETCH CUR_LINE_AMOUNT_VALIDATION
		BULK COLLECT INTO lv_line_amt_validation LIMIT 100;
		EXIT WHEN lv_line_amt_validation.COUNT = 0;
		FORALL i IN 1..lv_line_amt_validation.COUNT
		        UPDATE wsc_ahcs_int_status_t
                        SET
                            status = 'VALIDATION_FAILED',
                            error_msg = '301|Line DR/CR Amount Mismatch',
                            reextract_required = 'Y',
                            attribute1 = 'L',
                            attribute2 = 'VALIDATION_FAILED',
                            last_updated_date = SYSDATE
                        WHERE
                                batch_id = p_batch_id
                            AND status = 'NEW'
                            AND header_id = lv_line_amt_validation(i).header_id;
		END LOOP;
		CLOSE CUR_LINE_AMOUNT_VALIDATION;
		COMMIT;
     EXCEPTION
         WHEN OTHERS THEN
    logging_insert('MF INV', p_batch_id, 14.1, 'Exception in GL AMOUNT IN LOCAL_CURRENCY Validation', SQLERRM,SYSDATE);
    dbms_output.put_line('Error with Query:  ' || SQLERRM);
            ROLLBACK;	
		END; */

		UPDATE wsc_ahcs_int_status_t
            SET
                status = 'VALIDATION_SUCCESS',
                last_updated_date = SYSDATE
            WHERE
                batch_id = p_batch_id
                AND status = 'NEW'
                AND error_msg IS NULL;
        COMMIT;
logging_insert('ECLIPSE', p_batch_id,15,'COMMON STATUS TABLE UPDATED', NULL,SYSDATE);

            UPDATE wsc_ahcs_int_status_t
            SET
			    attribute2 = 'VALIDATION_SUCCESS',
                last_updated_date = SYSDATE
            WHERE
                batch_id = p_batch_id
                AND attribute2 IS NULL;
            COMMIT;

		   /* OPEN cur_count_sucss(p_batch_id);
            FETCH cur_count_sucss INTO lv_count_sucss;
            CLOSE cur_count_sucss; */
			
			OPEN cur_count_error(p_batch_id);
            FETCH cur_count_error INTO lv_count_error;
            CLOSE cur_count_error;
logging_insert('ECLIPSE', p_batch_id, 16, 'CHECK COUNT SUCCESS > 0 ', lv_count_sucss,SYSDATE);

          /*  IF lv_count_sucss > 0 THEN
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'VALIDATION_SUCCESS',
                    last_updated_date = SYSDATE
                WHERE
                    batch_id = p_batch_id;
                COMMIT;
              BEGIN
                   wsc_ahcs_eclipse_validation_transformation_pkg.leg_coa_transformation(p_batch_id);
               END;
            ELSE
                UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'VALIDATION_FAILED',
                    last_updated_date = SYSDATE
                WHERE
                    batch_id = p_batch_id;
            END IF; */
			
			IF lv_count_error > 0 THEN
			    UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'VALIDATION_FAILED',
                    last_updated_date = SYSDATE
                WHERE
                    batch_id = p_batch_id;
            ELSE
			    UPDATE wsc_ahcs_int_control_t
                SET
                    status = 'VALIDATION_SUCCESS',
                    last_updated_date = SYSDATE
                WHERE
                    batch_id = p_batch_id;
                COMMIT;
              BEGIN
                   wsc_ahcs_eclipse_validation_transformation_pkg.leg_coa_transformation(p_batch_id);
               END;
                
            END IF;
        COMMIT;
		
	 DELETE from WSC_AHCS_ECLIPSE_TXN_TMP_T where batch_id = p_batch_id   ;  
     logging_insert('ECLIPSE', p_batch_id, 127, 'deleted data from WSC_AHCS_ECLIPSE_TXN_TMP_T for this batch_id', NULL,sysdate);

    END DATA_VALIDATION;
	
	PROCEDURE leg_coa_transformation_reprocessing (
        p_batch_id IN NUMBER
    ) AS
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
        l_system                   VARCHAR2(30);
        CURSOR cur_update_trxn_line_err IS
        SELECT
            line.batch_id,
            line.header_id,
            line.line_id,
            line.target_coa
        FROM
            wsc_ahcs_eclipse_txn_line_t  line,
            wsc_ahcs_int_status_t   status
        WHERE
                line.batch_id = p_batch_id
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
            AND status.batch_id = line.batch_id
            AND status.header_id = line.header_id
            AND status.line_id = line.line_id
            AND status.attribute2 = 'VALIDATION_SUCCESS'; /*ATTRIBUTE2 */

        TYPE update_trxn_line_err_type IS
            TABLE OF cur_update_trxn_line_err%rowtype;
        lv_update_trxn_line_err    update_trxn_line_err_type;

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
        lv_update_trxn_header_err  update_trxn_header_err_type;

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
            wsc_gl_coa_map_t        coa_map,
            wsc_ahcs_int_control_t  ahcs_control
        WHERE
                upper(coa_map.source_system) = upper(ahcs_control.source_system)
            AND upper(coa_map.target_system) = upper(ahcs_control.target_system)
            AND ahcs_control.batch_id = p_batch_id;

    ------------------------------------------------------------------------------------------------------------------------------------------------------
    -- The following cursor will derive the future state COA combination for the given batch_Id for records that have been successfully validated.
    --
    ------------------------------------------------------------------------------------------------------------------------------------------------------

    --        CURSOR cur_leg_seg_value (
    --            cur_p_src_system  VARCHAR2,
    --            cur_p_tgt_system  VARCHAR2
    --        ) IS
    --        SELECT
    --            tgt_coa.leg_coa,
    --			----------------------------------------------------------------------------------------------------------------------------
    --			/**********  The following package call will derive the future state COA combination for legacy COA combination ***********/
    --			--
    --
    --            wsc_gl_coa_mapping_pkg.coa_mapping(cur_p_src_system, cur_p_tgt_system, tgt_coa.leg_seg1, tgt_coa.leg_seg2,
    --                                               tgt_coa.leg_seg3,
    --                                               tgt_coa.leg_seg4,
    --                                               tgt_coa.leg_seg5,
    --                                               tgt_coa.leg_seg6,
    --                                               tgt_coa.leg_seg7,
    --                                               tgt_coa.leg_led_name,
    --                                               NULL,
    --                                               NULL) target_coa 
    --			--
    --			-- End of function call to derive target COA.
    --			----------------------------------------------------------------------------------------------------------------------------                	  
    --
    --        FROM
    --            (
    --                SELECT DISTINCT
    --                    line.GL_BUSINESS_UNIT,
    --                    line.GL_ACCOUNT,
    --                    line.GL_DEPARTMENT,
    --                    line.GL_LOCATION,   /*** Fetches distinct legacy combination values ***/
    --                    line.GL_VENDOR_NBR_FULL,
    --                    line.AFFILIATE
    --                FROM
    --                    wsc_ahcs_eclipse_txn_line_t line,
    --                    wsc_ahcs_int_status_t     status
    ----                    wsc_ahcs_eclipse_txn_header_t  header
    --                WHERE
    --                        status.batch_id = p_batch_id
    --                    AND line.target_coa IS NULL
    --                    AND status.batch_id = line.batch_id
    --                    AND status.header_id = line.header_id
    --                    AND status.line_id = line.line_id
    --                    AND header.batch_id = status.batch_id
    --                    AND header.header_id = status.header_id
    --                    AND header.header_id = line.header_id
    --                    AND header.batch_id = line.batch_id
    --                    AND status.attribute2 = 'VALIDATION_SUCCESS'  /*** Check if the record has been successfully validated through validate procedure ***/
    --            ) tgt_coa;
    --
    --        TYPE leg_seg_value_type IS
    --            TABLE OF cur_leg_seg_value%rowtype;
    --        lv_leg_seg_value                leg_seg_value_type;

        -------------------------------------------------------------------------------------------------------------------------------------------
        -- Following cursorh will retrieve all the records from STAGING table that has the future state COA successfully derived from the engine
        -- for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------

        CURSOR cur_inserting_ccid_table IS
        SELECT DISTINCT
            line.leg_coa       leg_coa,
            line.target_coa    target_coa,
            line.leg_bu,
            line.leg_acct,
            line.leg_dept,
            line.leg_loc,
            line.leg_vendor,
            line.leg_affiliate

    --            line.leg_seg7,
    --            substr(line.leg_coa, instr(line.leg_coa, '.', 1, 7) + 1)                      AS ledger_name
        FROM
            wsc_ahcs_eclipse_txn_line_t line
    --              , wsc_ahcs_eclipse_txn_header_t header
        WHERE
                line.batch_id = p_batch_id 
    --			   and line.batch_id = header.batch_id
    --			   and line.header_id = header.header_id
            AND line.attribute1 = 'Y'
            AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NOT NULL;  /* Implies that the COA value has been successfully derived from engine */
        /*
        cursor cur_inserting_ccid_table is
            select distinct LEG_COA, TARGET_COA from wsc_ahcs_eclipse_txn_line_t
             where batch_id = p_batch_id 
               and attribute1 = 'Y'   
               and substr(target_coa,1,instr(target_coa,'.',1,1)-1) is not null;  
        */

        TYPE inserting_ccid_table_type IS
            TABLE OF cur_inserting_ccid_table%rowtype;
        lv_inserting_ccid_table    inserting_ccid_table_type;

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
                wsc_gl_legal_entities_t  lgl_entt,
                (
                    SELECT DISTINCT
                        line.gl_legal_entity,
                        line.header_id
                    FROM
                        wsc_ahcs_eclipse_txn_line_t  line,
                        wsc_ahcs_int_status_t   status
                    WHERE
                            line.header_id = status.header_id
                        AND line.batch_id = status.batch_id
                        AND line.line_id = status.line_id
                        AND status.batch_id = p_batch_id
                        AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
                )                        d_lgl_entt
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
        lv_get_ledger              get_ledger_type;
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

    --        CURSOR cur_line_validation_after_valid (
    --            cur_p_batch_id NUMBER
    --        ) IS
    --        WITH line_cr AS (
    --            SELECTg
    --                header_id,
    --                gl_legal_entity,
    --                SUM(acc_amt) * - 1 sum_data
    --            FROM
    --                wsc_ahcs_eclipse_txn_line_t
    --            WHERE
    --                    dr_cr_flag = 'CR'
    --                AND batch_id = cur_p_batch_id
    --            GROUP BY
    --                header_id,
    --                gl_legal_entity
    --        ), line_dr AS (
    --            SELECT
    --                header_id,
    --                gl_legal_entity,
    --                SUM(acc_amt) sum_data
    --            FROM
    --                wsc_ahcs_eclipse_txn_line_t
    --            WHERE
    --                    dr_cr_flag = 'DR'
    --                AND batch_id = cur_p_batch_id
    --            GROUP BY
    --                header_id,
    --                gl_legal_entity
    --        )
    --        SELECT
    --            l_cr.header_id
    --        FROM
    --            line_cr  l_cr,
    --            line_dr  l_dr
    --        WHERE
    --                l_cr.header_id = l_dr.header_id
    --            AND l_dr.gl_legal_entity = l_cr.gl_legal_entity
    --            AND ( l_dr.sum_data <> l_cr.sum_data );

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

    --        TYPE line_validation_after_valid_type IS
    --            TABLE OF cur_line_validation_after_valid%rowtype;
    --        lv_line_validation_after_valid  line_validation_after_valid_type;
        lv_coa_mapid               NUMBER;
        lv_src_system              VARCHAR2(100);
        lv_tgt_system              VARCHAR2(100);
        lv_count_succ              NUMBER;
        retcode                    VARCHAR2(50);
        err_msg                    VARCHAR2(50);
    BEGIN
        BEGIN
            SELECT
                attribute3
            INTO l_system
            FROM
                wsc_ahcs_int_control_t c
            WHERE
                c.batch_id = p_batch_id;

            dbms_output.put_line(l_system);
        END;
        -------------------------------------------------------------------------------------------------------------------------------------------
    --1. Identity the COA map corresponding to the source/ target system for the current batch ID (file name)        
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Eclipse', p_batch_id, 15, 'Transformation start', NULL,
                      sysdate);
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_mapid,
            lv_tgt_system,
            lv_src_system;
        CLOSE cur_coa_map_id;
        logging_insert('Eclipse', p_batch_id, 15.1, 'Transformation start',
                      lv_coa_mapid
                      || lv_tgt_system
                      || lv_src_system,
                      sysdate);

    --        update target_coa in eclipse_line table where source_segment is already present in ccid table
        -------------------------------------------------------------------------------------------------------------------------------------------
    --2. Check data in cache table to find the future state COA combination
        --   update the future state COA values in the staging table for records marked VALIDATION SUCCESS (successfully passed validations).
        -------------------------------------------------------------------------------------------------------------------------------------------
        
        BEGIN
            UPDATE wsc_ahcs_eclipse_txn_line_t line
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
--                        AND substr(line.target_coa, 1, instr(line.target_coa, '.', 1, 1) - 1) IS NULL
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
        
        
        
        logging_insert('Eclipse', p_batch_id, 16, 'Check data in cache table to find ', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_eclipse_txn_line_t line
            SET
                target_coa = wsc_gl_coa_mapping_pkg.ccid_match(leg_coa, lv_coa_mapid),
                last_update_date = sysdate
            WHERE
                batch_id = p_batch_id
               /*and exists 
                (select 1 from /*wsc_gl_ccid_mapping_t ccid_map,*/
                         --WSC_AHCS_INT_STATUS_T status 
                  --where /*ccid_map.coa_map_id = lv_coa_mapid and line.leg_coa = ccid_map.source_segment
    --				    and */ status.batch_id = line.batch_id
                   /* and status.header_id = line.header_id
                    and status.line_id = line.line_id
                    and status.status = 'VALIDATION_SUCCESS'
                    and status.attribute2 = 'VALIDATION_SUCCESS'
                    AND batch_id = p_batch_id)*/;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Eclipse', p_batch_id, 22, 'Error in Check data in cache table to find', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

    --        update target_coa and attribute1 'Y' in eclipse_line table where distinct leg_coa and target_coa is null      
        -------------------------------------------------------------------------------------------------------------------------------------------
        --3. Fetch the distinct source and target (derived from COA engine) COA values for the current batch ID
        --   Update the staging tables with the derived COA values, mark ATTRIBUTE1 = 'Y' indicating that derivation was successful.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Eclipse', p_batch_id, 17, 'update target_coa and attribute1', NULL,
                      sysdate);
        BEGIN
         /*   open cur_leg_seg_value(lv_src_system, lv_tgt_system);
            loop
            fetch cur_leg_seg_value bulk collect into lv_leg_seg_value limit 100;
            EXIT WHEN lv_leg_seg_value.COUNT = 0;        
            forall i in 1..lv_leg_seg_value.count
                update wsc_ahcs_eclipse_txn_line_t set target_coa = lv_leg_seg_value(i).target_coa,  ATTRIBUTE1 = 'Y', 
                LAST_UPDATE_DATE = sysdate 
                where LEG_COA = lv_leg_seg_value(i).LEG_COA and batch_id = p_batch_id;
            end loop;
    */

            UPDATE wsc_ahcs_eclipse_txn_line_t tgt_coa
            SET
                target_coa = replace(wsc_gl_coa_mapping_pkg.coa_mapping(lv_src_system, lv_tgt_system, tgt_coa.leg_bu,lpad(tgt_coa.leg_loc, 5, '0'),
                tgt_coa.leg_dept,tgt_coa.leg_acct,tgt_coa.leg_vendor,nvl(tgt_coa.leg_affiliate, '00000'),
                NULL,NULL,NULL,NULL),' ',''),
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
                logging_insert('Eclipse', p_batch_id, 19, 'Error in update target_coa and attribute1', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

    --        insert new target_coa values derived from coa_mapping function into ccid_mapping table which values are for future use
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 4. Refresh the cache table with the newly derived future state COA values for the current batch ID
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Eclipse', p_batch_id, 16, 'insert new target_coa values', NULL,
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
                        'Eclipse',
                        'Eclipse',
                        lv_inserting_ccid_table(i).leg_bu,
                        lpad(lv_inserting_ccid_table(i).leg_loc, 5, '0'),
                        lv_inserting_ccid_table(i).leg_dept,
                        lv_inserting_ccid_table(i).leg_acct,
                        lv_inserting_ccid_table(i).leg_vendor,
                        lv_inserting_ccid_table(i).leg_affiliate,
                        NULL,
                        NULL,
                        NULL,
                        NULL
                    );

                --insert into wsc_gl_ccid_mapping_t(COA_MAP_ID, SOURCE_SEGMENT, TARGET_SEGMENT, CREATION_DATE, LAST_UPDATE_DATE, ENABLE_FLAG)
                --values (lv_coa_mapid, lv_inserting_ccid_table(i).LEG_COA, lv_inserting_ccid_table(i).TARGET_COA, sysdate, sysdate, 'Y');
            END LOOP;

            CLOSE cur_inserting_ccid_table;
            UPDATE wsc_ahcs_eclipse_txn_line_t
            SET
                attribute1 = NULL
            WHERE
                batch_id = p_batch_id;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Eclipse', p_batch_id, 16, '.', sqlerrm,
                              sysdate);
        END;

    --      update eclipse_line table target segments,  where legal_entity must have their in target_coa
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 5. Update lines staging table with individual segment values split from the derived target segment concatenated values given by engine/         
              --cache tables.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Eclipse', p_batch_id, 18, 'update ap_line table target segments', NULL,
                      sysdate);
        BEGIN
            UPDATE wsc_ahcs_eclipse_txn_line_t
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
                logging_insert('Eclipse', p_batch_id, 27, 'Error in update eclipse_line table target segments', sqlerrm,
                              sysdate);
        END;

    --        if any target_coa is empty in eclipse_line table will mark it as transform_error in status table
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 6. Update status tables to the following for those records that do not have future state COA derived from both cache & engine:
        --    a. Status          = 'TRANSFORM FAILED'
        --    b. Error Message   = 'Error message returned from the engine'
        --    c. Attribute1      = This is a flex attribute that will imply whether the failure is line level. COA mapping errors are line specific.
        --    d. Attribute2      = Error message for that line. Will be same as that of status as this is a line level failure.
        --    e. Re-extract Flag = Will not be populated, implying this is a re-processing scenario and the mapping tables must be corrected.
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Eclipse', p_batch_id, 19, 'if any target_coa is empty', NULL,
                      sysdate);
        BEGIN
            UPDATE (
                SELECT
                    status.attribute2,
                    status.attribute1,
                    status.status,
                    status.error_msg,
                    status.last_updated_date,
                    line.batch_id      bt_id,
                    line.header_id     hdr_id,
                    line.line_id       ln_id,
                    line.target_coa    trgt_coa
                FROM
                    wsc_ahcs_int_status_t   status,
                    wsc_ahcs_eclipse_txn_line_t  line
                WHERE
                        status.batch_id = p_batch_id
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
            logging_insert('Eclipse', p_batch_id, 19.1, 'updated attribute2 with TRANSFORM_FAILED status', NULL,
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
             where a.batch_id = p_batch_id
               AND exists 
              (select 1 from WSC_AHCS_INT_STATUS_T b 
                where a.batch_id = b.batch_id 
                  and a.header_id = b.header_id 
                  and b.status = 'TRANSFORM_FAILED'
                  and b.batch_id = p_batch_id );
                  logging_insert('Eclipse',p_batch_id,19.2,'updated attribute2 with TRANSFORM_FAILED status',null,sysdate);
                  /*merge into WSC_AHCS_INT_STATUS_T a
                    using (select b.header_id,b.batch_id
                            from WSC_AHCS_INT_STATUS_T b 
                        where b.status = 'TRANSFORM_FAILED'
                          and b.batch_id = p_batch_id) b
                          on (a.batch_id = b.batch_id 
                          and a.header_id = b.header_id 
                          and a.batch_id = p_batch_id)
                        when matched then
                        update set a.ATTRIBUTE2 = 'TRANSFORM_FAILED', a.LAST_UPDATED_DATE = sysdate;*/
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Eclipse', p_batch_id, 29, 'Error in if any target_coa is empty', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

    --      update ledger_name in ap_header table where transform_success		
        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 7. Update ledger name column in the header staging table 
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Eclipse', p_batch_id, 20, 'update ledger_name', NULL,
                      sysdate);
        BEGIN
    --         /*   open cur_get_ledger;
    --            loop
    --            fetch cur_get_ledger bulk collect into lv_get_ledger limit 10;
    --            EXIT WHEN lv_get_ledger.COUNT = 0;        
    --            forall i in 1..lv_get_ledger.count
    --                update wsc_ahcs_eclipse_txn_header_t
    --                   set ledger_name = lv_get_ledger(i).ledger_name , LAST_UPDATE_DATE = sysdate
    --                 where batch_id = p_batch_id 
    --				   and header_id = lv_get_ledger(i).header_id
    --                   ;
    --            end loop;*/

    --
--            MERGE INTO wsc_ahcs_eclipse_txn_header_t hdr
--            USING (
--                      WITH main_data AS (
--                          SELECT /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE) */
--                              lgl_entt.ledger_name,
--                              lgl_entt.legal_entity_name,
--                              d_lgl_entt.header_id,
--                              d_lgl_entt.business_unit
--                          FROM
--                              wsc_gl_legal_entities_t  lgl_entt,
--                              (
--                                  SELECT /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I,batch_status wsc_ahcs_int_status_batch_id_i) */
--                                      line.gl_legal_entity,
--                                      line.header_id,
--                                      line.business_unit
--                                  FROM
--                                      wsc_ahcs_eclipse_txn_line_t  line,
--                                      wsc_ahcs_int_status_t   status
--                                  WHERE
--                                          line.header_id = status.header_id
--                                      AND line.batch_id = status.batch_id
--                                      AND line.line_id = status.line_id
--                                      AND status.batch_id = p_batch_id
--                                      AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
--                              )                        d_lgl_entt
--                          WHERE
--                              lgl_entt.flex_segment_value = d_lgl_entt.gl_legal_entity
--                      )
--                      SELECT DISTINCT
--                          a.ledger_name,
--                          a.header_id,
--                          a.business_unit
--                      FROM
--                          main_data a
--                      WHERE
--                          a.ledger_name IS NOT NULL
--                  )
--            e ON ( e.header_id = hdr.header_id )
--            WHEN MATCHED THEN UPDATE
--            SET hdr.ledger_name = e.ledger_name , hdr.LEG_BUS_UNIT = e.business_unit, hdr.TRANS_REF_NBR = e.business_unit;
--
--            MERGE INTO wsc_ahcs_eclipse_txn_header_t hdr
--            USING (
--                      WITH main_data AS (
--                          SELECT /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE,batch_status wsc_ahcs_int_status_batch_id_i) */
--                              lgl_entt.ledger_name,
--                              lgl_entt.legal_entity_name,
--                              d_lgl_entt.header_id,
--                              d_lgl_entt.business_unit
--                          FROM
--                              wsc_gl_legal_entities_t  lgl_entt,
--                              (
--                                  SELECT /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I) */ DISTINCT
--                                      line.gl_legal_entity,
--                                      line.header_id,
--                                      line.business_unit
--                                  FROM
--                                      wsc_ahcs_eclipse_txn_line_t  line,
--                                      wsc_ahcs_int_status_t   status
--                                  WHERE
--                                          line.header_id = status.header_id
--                                      AND line.batch_id = status.batch_id
--                                      AND line.line_id = status.line_id
--                                      AND status.batch_id = p_batch_id
--                                      AND status.attribute2 IN ( 'VALIDATION_SUCCESS', 'TRANSFORM_FAILED' )
--                              )                        d_lgl_entt
--                          WHERE
--                              lgl_entt.flex_segment_value (+) = d_lgl_entt.gl_legal_entity
--                      )
--                      SELECT DISTINCT
--                          a.ledger_name,
--                          a.header_id,
--                          a.business_unit
--                      FROM
--                          main_data a
--                      WHERE
--                          a.ledger_name IS NULL
--                  )
--            e ON ( e.header_id = hdr.header_id )
--            WHEN MATCHED THEN UPDATE
--            SET hdr.ledger_name = e.ledger_name, hdr.LEG_BUS_UNIT = e.business_unit, hdr.TRANS_REF_NBR = e.business_unit;
MERGE INTO wsc_ahcs_eclipse_txn_header_t hdr
            USING (
                      WITH main_data AS (
                          SELECT /*+ index(lgl_entt WSC_AHCS_FLEX_SEGMENT_VALUE) */ 
--                          SELECT  
                              lgl_entt.ledger_name,
                              lgl_entt.legal_entity_name,
                              d_lgl_entt.header_id
                          FROM
                              wsc_gl_legal_entities_t lgl_entt,
                              (
                                  SELECT /*+ index(status WSC_AHCS_INT_STATUS_ATT2_STTS_I,batch_status wsc_ahcs_int_status_batch_id_i)  */
--                                  SELECT 
                                      line.gl_legal_entity,
                                      line.header_id
                                  FROM
                                      wsc_ahcs_eclipse_txn_line_t line,
                                      wsc_ahcs_int_status_t    status
                                  WHERE
                                          line.header_id = status.header_id
                                      AND line.batch_id = status.batch_id
                                      AND line.line_id = status.line_id
                                      AND status.batch_id = p_batch_id
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
                          AND a.header_id IN (
                              SELECT
                                  d.header_id
                              FROM
                                  (
                                      SELECT
                                          COUNT(1), b.header_id
                                      FROM
                                          (
                                              SELECT DISTINCT
                                                  a.ledger_name, a.header_id
                                              FROM
                                                  main_data a
                                              WHERE
                                                  a.ledger_name IS NOT NULL
                                          ) b
                                      GROUP BY
                                          b.header_id
                                      HAVING
                                          COUNT(1) = 1
                                  ) d
                          )
                  )
            e ON ( e.header_id = hdr.header_id )
            WHEN MATCHED THEN UPDATE
            SET hdr.ledger_name = e.ledger_name;

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('Eclipse', p_batch_id, 22, 'Error in update ledger_name', sqlerrm,
                              sysdate);
                dbms_output.put_line('Error with Query:  ' || sqlerrm);
        END;

        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 7.1. Update status tables after validation where line cr/dr mismatch.
        --    /******* ALL RECORDS MARKED AS VALIDATION FAILED WHEN LINE CR/DR AMOUNT MISMATCH AFTER VALIDATION ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Eclipse', p_batch_id, 21, 'Update status tables after validation', NULL,
                      sysdate);
        /*begin
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
                logging_insert('Eclipse',p_batch_id,23,'Update status tables after validation',SQLERRM,sysdate);
                dbms_output.put_line('Error with Query:  ' || SQLERRM);
        end; */

        -------------------------------------------------------------------------------------------------------------------------------------------
        -- 8. Update status tables to have status of remaining lines which are not flagged as error in the earlier step to TRANSFORM_SUCCESS.
        --    /******* ALL RECORDS MARKED AS TRANSFORM SUCCESS WILL BE UPLOADED TO UCM FOR CREATE ACCOUNTING TO CREATE AHCS JOURNALS ********/
        -------------------------------------------------------------------------------------------------------------------------------------------
        logging_insert('Eclipse', p_batch_id, 22, 'Update status tables to have status', NULL,
                      sysdate);
        BEGIN
                UPDATE (
                    SELECT
                        sts.attribute2,
                        sts.status,
                        sts.last_updated_date,
                        sts.error_msg
                    FROM
                        wsc_ahcs_int_status_t     sts,
                        wsc_ahcs_eclipse_txn_header_t  hdr
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

        logging_insert('Eclipse', p_batch_id, 23, 'end transformation', NULL,
                      sysdate);
        logging_insert('Eclipse', p_batch_id, 24, 'Dashboard Start', NULL,
                      sysdate);
        wsc_ahcs_recon_records_pkg.refresh_validation_oic(retcode, err_msg);
        logging_insert('Eclipse', p_batch_id, 25, 'Dashboard End', NULL,
                      sysdate);
        logging_insert('Eclipse', p_batch_id, 26, 'end transformation', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT124'
                                                    || '_'
                                                    || l_system,
                                                    'Eclipse',
                                                    sqlerrm);
    END leg_coa_transformation_reprocessing;

END wsc_ahcs_eclipse_validation_transformation_pkg;
/