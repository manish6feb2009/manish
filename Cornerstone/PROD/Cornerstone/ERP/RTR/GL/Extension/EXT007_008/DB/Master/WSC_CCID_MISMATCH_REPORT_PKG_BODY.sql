CREATE OR REPLACE PACKAGE BODY wsc_ccid_mismatch_report AS
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PACKAGE             WSC_CCID_MISMATCH_REPORT AS
------------------------------------------------------------------------------------------
-- COPYRIGHT (C) Wesco Inc.
--
-- Protected as an unpublished work.  All Rights Reserved.
--
-- The computer program listings, specifications, and documentation herein
-- are the property of Wesco Incorporated and shall not be
-- reproduced, copied, disclosed, or used in whole or in part for any
-- reason without the express written permission of Wesco Incorporated.
--
-- DESCRIPTION:
-- This package contains supporting procedures required for validation of cache table & update data
-- from cache table. Also include download csv procedure, which will be call from the apex
-- give you the result of cache table validation data where mismatch data sorting first.
-- 
--
--
-- The following staging tables must be created before 
-- 1. WSC_CCID_MISMATCH_DATA_HDR_T
-- 2. WSC_CCID_MISMATCH_DATA_T
-- 3. WSC_CCID_MISMATCH_REPORT_T


--
-- PROCEDURE/ FUNCTION LIST:
--
--     Procedure WSC_CCID
--     Procedure WSC_CCID_ALL
--     Procedure WSC_CCID_UPDATE
--     Procedure WSC_MISMATCH_CCID_DOWNLOAD

--
-- MODIFICATION HISTORY :
--
-- Name                              Date      Ver   Description
-- =================              ===========  ===   ====================================
-- Deloitte Consulting            20-JAN-2023  1.0   Created
--
----------------------------------------------------------------------------------------

    PROCEDURE wsc_ccid (
        p_coa_map_id  NUMBER,
        p_batch_id    NUMBER,
        p_username    VARCHAR2
    ) IS

--To find out mismatch data from temp table minu cache table
        CURSOR cur_mismatch_data IS
        SELECT
            target_coa,
            source_segment1,
            source_segment2,
            source_segment3,
            source_segment4,
            source_segment5,
            source_segment6,
            source_segment7,
            source_segment8,
            source_segment9,
            source_segment10,
            source_segment
        FROM
            wsc_ccid_mismatch_report_t
        WHERE
            batch_id = p_batch_id
        MINUS
        SELECT
            target_segment,
            source_segment1,
            source_segment2,
            source_segment3,
            source_segment4,
            source_segment5,
            source_segment6,
            source_segment7,
            source_segment8,
            source_segment9,
            source_segment10,
            source_segment
        FROM
            wsc_gl_ccid_mapping_t
        WHERE
            enable_flag = 'Y';

--Select coa map name, source system and target system based on coa map id
        CURSOR cur_coa_map_id IS
        SELECT
            coa_map_name,
            source_system,
            target_system
        FROM
            wsc_gl_coa_map_t
        WHERE
            coa_map_id = p_coa_map_id;


        lv_coa_map_name   VARCHAR2(100);
        lv_source_system  VARCHAR2(100);
        lv_target_system  VARCHAR2(100);

        min_seq           NUMBER;
        max_seq           NUMBER;
        p_total_count     NUMBER;
        f_total_count     NUMBER;
        p_loop_count      NUMBER; 

--to calculate count of total number of rows inserted in report table, loop count
        CURSOR cur_seq_num IS 
        SELECT
            MIN(wsc_seq_num),
            MAX(wsc_seq_num),
            COUNT(1),
            MAX(wsc_seq_num) - MIN(wsc_seq_num) loop_count
        FROM
            wsc_ccid_mismatch_report_t
        WHERE
            batch_id = p_batch_id;

--to get count, remaining and completed count
        CURSOR cur_com_count IS
        SELECT
            COUNT(1)
        FROM
            wsc_ccid_mismatch_report_t
        WHERE
            target_coa IS NOT NULL
            AND batch_id = p_batch_id;

        com_count         NUMBER;
        rem_count         NUMBER;
        err_msg           VARCHAR2(1000);
    BEGIN
        OPEN cur_coa_map_id;
        FETCH cur_coa_map_id INTO
            lv_coa_map_name,
            lv_source_system,
            lv_target_system;
        CLOSE cur_coa_map_id;

--delete older record from header table
        DELETE FROM wsc_ccid_mismatch_data_hdr_t
        WHERE
            coa_name = lv_coa_map_name;

        COMMIT;

-- insert new records with starting process of validation
        INSERT INTO wsc_ccid_mismatch_data_hdr_t (
            username,
            batch_id,
            status,
            coa_name
        ) VALUES (
            p_username,
            p_batch_id,
            'In Process',
            lv_coa_map_name
        );

        COMMIT;

--delete older record/s from mismatch table
        DELETE FROM wsc_ccid_mismatch_data_t
        WHERE
            coa_name = lv_coa_map_name;

        COMMIT;

--delete older record/s from mismatch report table
        DELETE FROM wsc_ccid_mismatch_report_t
        WHERE
            coa_name = lv_coa_map_name;

        COMMIT;

-- insert all the rows from cache table to temp(report) table to run engine on this table
        INSERT INTO wsc_ccid_mismatch_report_t (
            coa_name,
            source_segment1,
            source_segment2,
            source_segment3,
            source_segment4,
            source_segment5,
            source_segment6,
            source_segment7,
            source_segment8,
            source_segment9,
            source_segment10,
            batch_id,
            source_segment
        )
            SELECT
                lv_coa_map_name,
                source_segment1,
                source_segment2,
                source_segment3,
                source_segment4,
                source_segment5,
                source_segment6,
                source_segment7,
                source_segment8,
                source_segment9,
                source_segment10,
                p_batch_id,
                source_segment
            FROM
                wsc_gl_ccid_mapping_t
            WHERE
                    enable_flag = 'Y'
                AND coa_map_id = p_coa_map_id;

        COMMIT;
    

-- fetch for total count, setting completed count as 0 and remaining as total count
        OPEN cur_seq_num;
        FETCH cur_seq_num INTO
            min_seq,
            max_seq,
            p_total_count,
            p_loop_count;
        CLOSE cur_seq_num;
        f_total_count := p_total_count;
        UPDATE wsc_ccid_mismatch_data_hdr_t
        SET
            total_count = p_total_count,
            complete_count = 0,
            remaining_count = p_total_count
        WHERE
            batch_id = p_batch_id;

        COMMIT;


--p_total_count is to get loop count (added 5 for the backup purpose only)
        p_total_count := trunc(p_loop_count / 100) + 5;


        IF ( p_coa_map_id = 2 ) THEN
            FOR b IN 1..p_total_count LOOP
-- Run engine on tempp table
                UPDATE wsc_ccid_mismatch_report_t a
                SET
                    a.target_coa = wsc_gl_coa_mapping_pkg.coa_mapping(lv_source_system, lv_target_system, a.source_segment1, a.source_segment2,
                    a.source_segment3,
                                                                      a.source_segment4,
                                                                      a.source_segment5,
                                                                      nvl(a.source_segment6, '00000'),
                                                                      a.source_segment7,
                                                                      a.source_segment8,
                                                                      NULL,
                                                                      NULL)
                WHERE
                    ( wsc_seq_num BETWEEN min_seq AND min_seq + 100 )
                    AND coa_name = lv_coa_map_name
                    AND target_coa IS NULL
                    AND batch_id = p_batch_id;

                COMMIT;
                OPEN cur_com_count;
                FETCH cur_com_count INTO com_count;
                CLOSE cur_com_count;
 --update completed count and remaining count
                UPDATE wsc_ccid_mismatch_data_hdr_t
                SET
                    complete_count = com_count,
                    remaining_count = f_total_count - com_count
                WHERE
                    batch_id = p_batch_id;

                COMMIT;
                min_seq := min_seq + 100;
            END LOOP;
    
        ELSE
            FOR b IN 1..p_total_count LOOP
                UPDATE wsc_ccid_mismatch_report_t a
                SET
                    a.target_coa = wsc_gl_coa_mapping_pkg.coa_mapping(lv_source_system, lv_target_system, a.source_segment1, a.source_segment2,
                    a.source_segment3,
                                                                      a.source_segment4,
                                                                      a.source_segment5,
                                                                      a.source_segment6,
                                                                      a.source_segment7,
                                                                      a.source_segment8,
                                                                      NULL,
                                                                      NULL)
                WHERE
                    ( wsc_seq_num BETWEEN min_seq AND min_seq + 100 )
                    AND coa_name = lv_coa_map_name
                    AND target_coa IS NULL
                    AND batch_id = p_batch_id;

                COMMIT;
                OPEN cur_com_count;
                FETCH cur_com_count INTO com_count;
                CLOSE cur_com_count;
                UPDATE wsc_ccid_mismatch_data_hdr_t
                SET
                    complete_count = com_count,
                    remaining_count = f_total_count - com_count
                WHERE
                    batch_id = p_batch_id;

                COMMIT;
                min_seq := min_seq + 100;
            END LOOP;
        
        END IF;
    
    --cur to check differnce between temp and cache and insert into main mismatch data table
        FOR i IN cur_mismatch_data LOOP
            INSERT INTO wsc_ccid_mismatch_data_t (
                coa_name,
                source_segment1,
                source_segment2,
                source_segment3,
                source_segment4,
                source_segment5,
                source_segment6,
                source_segment7,
                source_segment8,
                source_segment9,
                source_segment10,
                target_segment_new,
                batch_id,
                source_segment
            ) VALUES (
                lv_coa_map_name,
                i.source_segment1,
                i.source_segment2,
                i.source_segment3,
                i.source_segment4,
                i.source_segment5,
                i.source_segment6,
                i.source_segment7,
                i.source_segment8,
                i.source_segment9,
                i.source_segment10,
                i.target_coa,
                p_batch_id,
                i.source_segment
            );

            COMMIT;
        END LOOP;
    
    --updating mismatch data with older target segment from cache table
        MERGE INTO wsc_ccid_mismatch_data_t a
        USING wsc_gl_ccid_mapping_t b ON ( a.source_segment = b.source_segment
                                           AND a.batch_id = p_batch_id
                                           AND b.enable_flag = 'Y' )
        WHEN MATCHED THEN UPDATE
        SET a.target_segment_old = b.target_segment;

        COMMIT;
    
        UPDATE wsc_ccid_mismatch_data_hdr_t
        SET
            status = 'Success',
            ccid_status =
                CASE
                    WHEN (
                        SELECT
                            COUNT(1)
                        FROM
                            wsc_ccid_mismatch_data_t
                        WHERE
                            batch_id = p_batch_id
                    ) = 0 THEN
                        'No Action Required'
                    ELSE
                        'Action Required'
                END,
            last_update_date = sysdate,
            total_mismatch = (
                SELECT
                    COUNT(1)
                FROM
                    wsc_ccid_mismatch_data_t
                WHERE
                    batch_id = p_batch_id
            )
        WHERE
            batch_id = p_batch_id;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            UPDATE wsc_ccid_mismatch_data_hdr_t
            SET
                status = 'Error'
            WHERE
                batch_id = p_batch_id;

            COMMIT;
            err_msg := sqlerrm;
            INSERT INTO wsc_tbl_time_t (
                a,
                b,
                c
            ) VALUES (
                err_msg,
                sysdate,
                909090
            );

            COMMIT;
    END;

    PROCEDURE wsc_ccid_update (
        p_username      VARCHAR2,
        p_coa_map_name  VARCHAR2
    ) IS
    BEGIN
        UPDATE wsc_ccid_mismatch_data_hdr_t
        SET
            ccid_status = 'In Process'
        WHERE
            coa_name = p_coa_map_name;
--    WHERE BATCH_ID = P_BATCH_ID;
        COMMIT;
    
--    insert into wsc_tbl_time_t values(P_USERNAME||'123_'||P_COA_MAP_NAME,sysdate,909090990);
--    commit;
--

        UPDATE wsc_gl_ccid_mapping_t b
        SET
            enable_flag = 'N',
            last_update_date = sysdate,
            last_updated_by = 'VALIDATED - ' || p_username
        WHERE
		enable_flag = 'Y' AND
            EXISTS (
                SELECT
                    1
                FROM
                    wsc_gl_coa_map_t a
                WHERE
                        a.coa_map_name = p_coa_map_name
                    AND a.coa_map_id = b.coa_map_id
            )
            AND source_segment IN (
                SELECT
                    source_segment
                FROM
                    wsc_ccid_mismatch_data_t
                WHERE
                    target_segment_old <> target_segment_new
            );

        COMMIT;
        UPDATE wsc_ccid_mismatch_data_hdr_t b
        SET
            ccid_status = 'Success'
        WHERE
            coa_name = p_coa_map_name
--    where exists (select 1 from wsc_gl_coa_map_t a where a.coa_map_name = P_COA_MAP_NAME 
--    and a.COA_MAP_ID = b.COA_MAP_ID ) 
            ;
--    WHERE BATCH_ID = P_BATCH_ID;
        COMMIT;
    END;

    PROCEDURE wsc_mismatch_ccid_download (
        o_clobdata       OUT  CLOB,
        p_ccid_map_name  IN   VARCHAR2
    ) IS
        l_blob  BLOB;
        l_clob  CLOB;
    BEGIN 

--INSERT INTO WSC_TBL_TIME_T (A) VALUES(P_CCID_MAP_ID);
--INSERT INTO WSC_TBL_TIME_T (A) VALUES(P_ACC_STATUS);
--INSERT INTO WSC_TBL_TIME_T (A) VALUES(P_ACCOUNTING_PERIOD);
--INSERT INTO WSC_TBL_TIME_T (A) VALUES(P_SOURCE_SYSTEM);
--COMMIT;
        dbms_lob.createtemporary(lob_loc => l_clob, cache => true,
                                dur => dbms_lob.call); 
--null;
        SELECT
            clob_val
        INTO l_clob
        FROM
            (
                SELECT
                    XMLCAST(XMLAGG(XMLELEMENT(
                        e, col_value
                          || CHR(13)
                          || CHR(10)
                    )) AS CLOB)    AS clob_val,
                    COUNT(*)       AS number_of_rows
                FROM
                    (
                        SELECT
                            'COA_NAME,SOURCE_SEGMENT1,SOURCE_SEGMENT2,SOURCE_SEGMENT3,SOURCE_SEGMENT4,SOURCE_SEGMENT5,SOURCE_SEGMENT6,SOURCE_SEGMENT7,SOURCE_SEGMENT8,SOURCE_SEGMENT9,SOURCE_SEGMENT10,TARGET TEMP TABLE,TARGET CACHE TABLE,MISMATCHED?'
                            AS col_value
                        FROM
                            dual
                        UNION ALL
                        SELECT
                            coa_name
                            || ','
                            || source_segment1
                            || ','
                            || source_segment2
                            || ','
                            || source_segment3
                            || ','
                            || source_segment4
                            || ','
                            || source_segment5
                            || ','
                            || source_segment6
                            || ','
                            || source_segment7
                            || ','
                            || source_segment8
                            || ','
                            || source_segment9
                            || ','
                            || source_segment10
                            || ','
                            || target_segment_new
                            || ','
                            || target_segment_old
                            || ','
                            || mismatch_status
                        FROM
                            (
                                SELECT
                                    coa_name,
                                    source_segment1,
                                    source_segment2,
                                    source_segment3,
                                    source_segment4,
                                    source_segment5,
                                    source_segment6,
                                    source_segment7,
                                    source_segment8,
                                    source_segment9,
                                    source_segment10,
                                    target_segment_new,
                                    target_segment_old,
                                    'Y' mismatch_status
                                FROM
                                    wsc_ccid_mismatch_data_t a
--                    ,
--                    wsc_gl_coa_map_t c
--                    where c.coa_map_name = a.coa_name
--                    and c.coa_map_id = P_CCID_MAP_ID
                                WHERE
                                    a.coa_name = p_ccid_map_name
                                UNION ALL
                                SELECT 
                    -- DECODE(COA_MAP_ID,1,'WESCO to Cloud',2,'Anixter to Cloud',3,'Central to Cloud',4,'POC to Cloud','Peoplesoft to Cloud'),
--                    c.coa_map_name,
                                    b.coa_name,
                                    a.source_segment1,
                                    a.source_segment2,
                                    a.source_segment3,
                                    a.source_segment4,
                                    a.source_segment5,
                                    a.source_segment6,
                                    a.source_segment7,
                                    a.source_segment8,
                                    a.source_segment9,
                                    a.source_segment10,
                                    a.target_segment,
                                    a.target_segment,
                                    'N'
                                FROM
                                    wsc_gl_ccid_mapping_t         a,
                                    wsc_ccid_mismatch_data_hdr_t  b,
                                    wsc_gl_coa_map_t              c
                    --WSC_CCID_MISMATCH_DATA_T b
                                WHERE 
                    --not exists(select 1 from WSC_CCID_MISMATCH_DATA_T
                    --where a.source_segment = b.source_segment)
                                    a.source_segment NOT IN (
                                        SELECT
                                            source_segment
                                        FROM
                                            wsc_ccid_mismatch_data_t
                                    )
                    --and
                                    AND b.status = 'Success'
                                    AND c.coa_map_name = b.coa_name
                                    AND b.coa_name = p_ccid_map_name
                                    AND a.coa_map_id = c.coa_map_id
                                    AND a.enable_flag = 'Y'
--                    and a.coa_map_id = P_CCID_MAP_ID
                            )
                    )
            );

        o_clobdata := l_clob;
    END;

    PROCEDURE wsc_ccid_all (
        p_coa_map_id  NUMBER,
        p_username    VARCHAR2
    ) IS

        p_batch_id     NUMBER;
        CURSOR cur_coa_map_id IS
        SELECT
            coa_map_id
        FROM
            wsc_gl_coa_map_t
        WHERE
            coa_map_id <> 5;

        lv_coa_map_id  VARCHAR2(100);
    BEGIN
        FOR i IN cur_coa_map_id LOOP
            lv_coa_map_id := i.coa_map_id;
            p_batch_id := wsc_ccid_mismatch_batch_id.nextval;
            BEGIN
                dbms_scheduler.create_job(job_name => 'WSC_CCID_MISMATCH_REPORT_ALL_' || p_batch_id, job_type => 'PLSQL_BLOCK',
                                         job_action => 'DECLARE
        L_ERR_MSG VARCHAR2(2000);
        L_ERR_CODE VARCHAR2(2);
        BEGIN 
            WSC_CCID_MISMATCH_REPORT.WSC_CCID('
                                                       || lv_coa_map_id
                                                       || ','
                                                       || p_batch_id
                                                       || ','''
                                                       || p_username
                                                       || ''');
        END;',
                                         enabled => true,
                                         auto_drop => true,
                                         comments => 'WSC_CCID_MISMATCH_REPORT');
            END;

        END LOOP;
    END;

END wsc_ccid_mismatch_report;
/






------------------------less value table------------------------
--create or replace Package BODY WSC_CCID_MISMATCH_REPORT As
--    
--PROCEDURE WSC_CCID(P_COA_MAP_ID number, P_BATCH_ID number) is
--
--cursor cur_mismatch_data is 
--select target_coa,SOURCE_SEGMENT1,
--    SOURCE_SEGMENT2,SOURCE_SEGMENT3,SOURCE_SEGMENT4,SOURCE_SEGMENT5,
--    SOURCE_SEGMENT6,SOURCE_SEGMENT7,SOURCE_SEGMENT8,SOURCE_SEGMENT9,
--    SOURCE_SEGMENT10, SOURCE_SEGMENT from WSC_CCID_MISMATCH_REPORT_T where batch_id = P_BATCH_ID
--minus 
--select TARGET_SEGMENT,SOURCE_SEGMENT1,
--    SOURCE_SEGMENT2,SOURCE_SEGMENT3,SOURCE_SEGMENT4,SOURCE_SEGMENT5,
--    SOURCE_SEGMENT6,SOURCE_SEGMENT7,SOURCE_SEGMENT8,SOURCE_SEGMENT9,
--    SOURCE_SEGMENT10, SOURCE_SEGMENT from wsc_gl_ccid_mapping_t_less_value;
--
--CURSOR cur_coa_map_id IS
--		select COA_MAP_NAME, SOURCE_SYSTEM,TARGET_SYSTEM 
--		from WSC_GL_COA_MAP_T WHERE COA_MAP_ID = P_COA_MAP_ID;
--
--LV_COA_MAP_NAME varchar2(100);
--LV_SOURCE_SYSTEM varchar2(100);
--LV_TARGET_SYSTEM varchar2(100);
--
--P_USERNAME varchar2(100) := 'FININT';
--
--min_seq number;
--max_seq number;
--p_total_count number;
--f_total_count number;
--cursor cur_seq_num is 
--select min (wsc_seq_num),max(wsc_seq_num), count(1) from WSC_CCID_MISMATCH_REPORT_T where batch_id =P_BATCH_ID;
--
--CURSOR CUR_COM_COUNT IS
--SELECT COUNT(1) FROM WSC_CCID_MISMATCH_REPORT_T WHERE TARGET_COA IS NOT NULL AND BATCH_ID = P_BATCH_ID;
--COM_COUNT NUMBER;
--REM_COUNT NUMBER;
--begin
--
----truncate table WSC_CCID_MISMATCH_DATA_HDR_T;
--delete from WSC_CCID_MISMATCH_DATA_HDR_T;
--commit;
--
--delete from WSC_CCID_MISMATCH_DATA_T;
--commit;
--
--INSERT INTO WSC_CCID_MISMATCH_DATA_HDR_T (USERNAME, BATCH_ID, STATUS)
--VALUES (P_USERNAME,P_BATCH_ID,'In Process');
--commit;
--
--open cur_coa_map_id;
--fetch cur_coa_map_id into LV_COA_MAP_NAME,LV_SOURCE_SYSTEM,LV_TARGET_SYSTEM;
--close cur_coa_map_id;
--
--    insert into WSC_CCID_MISMATCH_REPORT_T(COA_NAME, SOURCE_SEGMENT1,
--    SOURCE_SEGMENT2,SOURCE_SEGMENT3,SOURCE_SEGMENT4,SOURCE_SEGMENT5,
--    SOURCE_SEGMENT6,SOURCE_SEGMENT7,SOURCE_SEGMENT8,SOURCE_SEGMENT9,
--    SOURCE_SEGMENT10, BATCH_ID, SOURCE_SEGMENT) select LV_COA_MAP_NAME, SOURCE_SEGMENT1,
--    SOURCE_SEGMENT2,SOURCE_SEGMENT3,SOURCE_SEGMENT4,SOURCE_SEGMENT5,
--    SOURCE_SEGMENT6,SOURCE_SEGMENT7,SOURCE_SEGMENT8,SOURCE_SEGMENT9,
--    SOURCE_SEGMENT10, P_BATCH_ID, SOURCE_SEGMENT
--    from wsc_gl_ccid_mapping_t_less_value
--    where ENABLE_FLAG = 'Y'
--    and coa_map_id = P_COA_MAP_ID;
--    commit;
--    
--    
--open cur_seq_num;
--fetch cur_seq_num into min_seq,max_seq,p_total_count;
--close cur_seq_num;
--f_total_count := p_total_count;
--UPDATE WSC_CCID_MISMATCH_DATA_HDR_T SET TOTAL_COUNT = p_total_count,COMPLETE_COUNT=0,REMAINING_COUNT=p_total_count
--WHERE BATCH_ID = P_BATCH_ID;
--COMMIT;
--
--p_total_count := trunc(p_total_count/100)+5;
--
--
--    
--    if (P_COA_MAP_ID = 2) then
--        for b in 1..p_total_count loop
----            insert into wsc_tbl_time_t (a,b,c) values (TO_CHAR(b),sysdate,min_seq);
----            commit;
--            update WSC_CCID_MISMATCH_REPORT_T a
--            set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING(LV_SOURCE_SYSTEM,LV_TARGET_SYSTEM,a.SOURCE_SEGMENT1,
--            a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),a.SOURCE_SEGMENT7,
--            a.SOURCE_SEGMENT8,null,null) 
--            where (wsc_seq_num between min_seq and min_seq+100) and COA_NAME=LV_COA_MAP_NAME and target_coa is null
--            and batch_id = P_BATCH_ID;
--            commit;
--            
--            open CUR_COM_COUNT;
--            fetch CUR_COM_COUNT into COM_COUNT;
--            close CUR_COM_COUNT;
-- 
--            UPDATE WSC_CCID_MISMATCH_DATA_HDR_T SET COMPLETE_COUNT=COM_COUNT,
--            REMAINING_COUNT=f_total_count - COM_COUNT
--            WHERE BATCH_ID = P_BATCH_ID;
--            COMMIT;
--            min_seq := min_seq+100; 
--        end loop;
--    
----        update WSC_CCID_MISMATCH_REPORT_T a
----        set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING(LV_SOURCE_SYSTEM,LV_TARGET_SYSTEM,a.SOURCE_SEGMENT1,
----        a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,nvl(a.SOURCE_SEGMENT6,'00000'),
----        a.SOURCE_SEGMENT7,a.SOURCE_SEGMENT8,null,null)
----        where COA_NAME=LV_COA_MAP_NAME and target_coa is null and batch_id = P_BATCH_ID;
----        commit;
--    else
--    
--        for b in 1..p_total_count loop
--            insert into wsc_tbl_time_t (a,b,c) values (TO_CHAR(b),sysdate,min_seq);
--            commit;
--            update WSC_CCID_MISMATCH_REPORT_T a
--            set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING(LV_SOURCE_SYSTEM,LV_TARGET_SYSTEM,a.SOURCE_SEGMENT1,
--            a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
--            a.SOURCE_SEGMENT8,null,null)
--            where (wsc_seq_num between min_seq and min_seq+100) and COA_NAME=LV_COA_MAP_NAME and target_coa is null
--            and batch_id = P_BATCH_ID;
--            commit;
--            min_seq := min_seq+100; 
--        end loop;
--        
----        update WSC_CCID_MISMATCH_REPORT_T a
----        set a.TARGET_COA= WSC_GL_COA_MAPPING_PKG.COA_MAPPING(LV_SOURCE_SYSTEM,LV_TARGET_SYSTEM,a.SOURCE_SEGMENT1,
----        a.SOURCE_SEGMENT2,a.SOURCE_SEGMENT3,a.SOURCE_SEGMENT4,a.SOURCE_SEGMENT5,a.SOURCE_SEGMENT6,a.SOURCE_SEGMENT7,
----        a.SOURCE_SEGMENT8,null,null)
----        where COA_NAME=LV_COA_MAP_NAME and target_coa is null and batch_id = P_BATCH_ID;
----        commit;
--    end if;
--    for i in cur_mismatch_data loop
--        insert into WSC_CCID_MISMATCH_DATA_T( COA_NAME, SOURCE_SEGMENT1,
--        SOURCE_SEGMENT2,SOURCE_SEGMENT3,SOURCE_SEGMENT4,SOURCE_SEGMENT5,
--        SOURCE_SEGMENT6,SOURCE_SEGMENT7,SOURCE_SEGMENT8,SOURCE_SEGMENT9,
--        SOURCE_SEGMENT10, target_segment_new, BATCH_ID, SOURCE_SEGMENT)
--        values(LV_COA_MAP_NAME,i.SOURCE_SEGMENT1,
--        i.SOURCE_SEGMENT2,i.SOURCE_SEGMENT3,i.SOURCE_SEGMENT4,i.SOURCE_SEGMENT5,
--        i.SOURCE_SEGMENT6,i.SOURCE_SEGMENT7,i.SOURCE_SEGMENT8,i.SOURCE_SEGMENT9,
--        i.SOURCE_SEGMENT10, i.target_coa, P_BATCH_ID , i.SOURCE_SEGMENT);
--    commit;
--    end loop;
--    
--    
--    MERGE INTO WSC_CCID_MISMATCH_DATA_T a
--    USING wsc_gl_ccid_mapping_t_less_value b
--    ON (a.source_segment = b.source_segment and a.batch_id = P_BATCH_ID)
--      WHEN MATCHED THEN
--    UPDATE SET a.target_segment_old = b.target_segment;
--    commit;
--    
----    update wsc_gl_ccid_mapping_t_less_value set enable_flag='N' where
----    source_segment in ( select source_segment from WSC_CCID_MISMATCH_DATA_T
----    where target_segment_old <> target_segment_new and batch_id = P_BATCH_ID);
----    commit;
--
--
--UPDATE WSC_CCID_MISMATCH_DATA_HDR_T SET STATUS = 'Success', ccid_status = 'Action Required'
--WHERE BATCH_ID = P_BATCH_ID;
--commit;
--    
--end;
--
--PROCEDURE WSC_CCID_UPDATE is
--
--begin
--
--    UPDATE WSC_CCID_MISMATCH_DATA_HDR_T SET CCID_STATUS = 'In Process';
----    WHERE BATCH_ID = P_BATCH_ID;
--    commit;
--
--    update wsc_gl_ccid_mapping_t_less_value set enable_flag='N' where
--    source_segment in ( select source_segment from WSC_CCID_MISMATCH_DATA_T
--    where target_segment_old <> target_segment_new);
--    commit;
--
--    UPDATE WSC_CCID_MISMATCH_DATA_HDR_T SET CCID_STATUS = 'Success';
----    WHERE BATCH_ID = P_BATCH_ID;
--    commit;
--
--end;
--
--end WSC_CCID_MISMATCH_REPORT;