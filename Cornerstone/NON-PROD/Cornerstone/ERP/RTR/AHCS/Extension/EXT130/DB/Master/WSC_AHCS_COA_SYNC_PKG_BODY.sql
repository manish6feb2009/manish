create or replace PACKAGE BODY wsc_ahcs_coa_sync_pkg AS

    PROCEDURE wsc_ahcs_coa_sync_start (
        p_batch_id    NUMBER,
        p_reset_date  DATE
    ) IS

        CURSOR data_selector (
            cur_reset_date DATE
        ) IS
--        SELECT
--            *
--        FROM
--            wsc_ahcs_coa_sync_execution_master_tbl
--        WHERE
--            coa_mapping_rule IN (
--                SELECT DISTINCT
--                    a.rule_name
--                FROM
--                    wsc_gl_coa_segment_value_t a
--                WHERE
--                        trunc(a.last_update_date) > trunc(cur_reset_date)
--            );

        WITH master_data AS (
            SELECT
                mapping_set_short_name,
                subledger_application
            FROM
                wsc_ahcs_coa_sync_execution_master_tbl
            WHERE
                coa_mapping_rule IN (
                    SELECT
                        a.rule_name
                    FROM
                        wsc_gl_coa_segment_value_t a
                    WHERE
                        a.last_update_date >= cur_reset_date
                    GROUP BY
                        a.rule_name
                )
        )
        SELECT
            master.mapping_set_short_name    AS mapping_set_short_name,
            master.subledger_application     AS subledger_application,
            LISTAGG(master.coa_mapping_rule, '|') WITHIN GROUP(
                ORDER BY
                    master.coa_mapping_rule
            )                                AS coa_mapping_rule,
            output_type,
            output_type_name,
            coa_name
        FROM
            wsc_ahcs_coa_sync_execution_master_tbl master,
            master_data
        WHERE
                master_data.mapping_set_short_name = master.mapping_set_short_name
            AND master_data.subledger_application = master.subledger_application
        GROUP BY
            master.mapping_set_short_name,
            master.subledger_application,
            master.output_type,
            master.output_type_name,
            master.coa_name;

        CURSOR cur_total_count IS
        SELECT
            COUNT(1)
        FROM
            wsc_ahcs_coa_sync_execution_line_tbl
        WHERE
            batch_id = p_batch_id;

        CURSOR cur_count_data (
            p_mapping_set_short_name  VARCHAR2,
            p_subledger_application   VARCHAR2
        ) IS
        SELECT
            COUNT(1) count_number
        FROM
            wsc_gl_coa_segment_value_t              coa_val,
            wsc_ahcs_coa_sync_execution_line_tbl    line,
            wsc_ahcs_coa_sync_execution_master_tbl  master
        WHERE
                master.coa_mapping_rule = coa_val.rule_name
            AND master.mapping_set_short_name = p_mapping_set_short_name
            AND master.subledger_application = p_subledger_application
            AND coa_val.flag = 'Y'
            AND line.batch_id = p_batch_id
            AND master.mapping_set_short_name = line.mapping_set_short_name
            AND master.subledger_application = line.subledger_application
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_coa_sync_exemption_value_tbl exe_val
                WHERE
                    coa_val.target_segment = exe_val.target_value
            );

        lv_submit_time      DATE;
        lv_username         VARCHAR2(100);
        lv_reset_date       DATE;
        lv_total_count      NUMBER;
        lv_count_data       NUMBER;
        l_clob              VARCHAR2(32767);
        l_body              VARCHAR2(32767);
        x_url               VARCHAR2(1000);
        v_user_name         VARCHAR2(4000) := NULL;
        l_xml_result        CLOB;
        l_http_status_code  VARCHAR2(2000);
        x_user_name         VARCHAR2(100);
        x_password          VARCHAR2(100);
    BEGIN
--        SELECT
--            submit_time
--        INTO lv_submit_time
--        FROM
--            wsc_ahcs_coa_sync_execution_hdr_tbl
--        WHERE
--            batch_id = p_batch_id;

        SELECT
            created_by
        INTO lv_username
        FROM
            wsc_ahcs_coa_sync_execution_hdr_tbl
        WHERE
            batch_id = p_batch_id;

        IF p_reset_date IS NULL THEN
            SELECT
                last_refresh_date
            INTO lv_reset_date
            FROM
                wsc_ahcs_refresh_t
            WHERE
                data_entity_name = 'COA_SYNC';

        ELSE
            lv_reset_date := p_reset_date;
        END IF;

--        UPDATE wsc_ahcs_refresh_t
--        SET
--            last_refresh_date = sysdate
--        WHERE
--            data_entity_name = 'COA_SYNC';
--
--        COMMIT;
        FOR i IN data_selector(lv_reset_date) LOOP
            INSERT INTO wsc_ahcs_coa_sync_execution_line_tbl (
                batch_id,
                line_id,
                mapping_set_short_name,
                coa_mapping_rule,
                subledger_application,
                output_type,
                output_type_name,
                coa_name,
--                submit_time,
--                count_data,
                creation_date,
                created_by,
                last_updated_by,
                last_update_date
            ) VALUES (
                p_batch_id,
                wsc_ahcs_coa_sync_execution_line_id_seq.NEXTVAL,
                i.mapping_set_short_name,
                i.coa_mapping_rule,
                i.subledger_application,
                i.output_type,
                i.output_type_name,
                i.coa_name,
--                lv_submit_time,
--                lv_count_data_num,
                sysdate,
                lv_username,
                lv_username,
                sysdate
            );

            OPEN cur_count_data(i.mapping_set_short_name, i.subledger_application);
            FETCH cur_count_data INTO lv_count_data;
            CLOSE cur_count_data;
            UPDATE wsc_ahcs_coa_sync_execution_line_tbl
            SET
                count_data = lv_count_data
            WHERE
                    batch_id = p_batch_id
                AND mapping_set_short_name = i.mapping_set_short_name
                AND subledger_application = i.subledger_application;

        END LOOP;

        COMMIT;
        OPEN cur_total_count;
        FETCH cur_total_count INTO lv_total_count;
        CLOSE cur_total_count;
--        IF ( lv_total_count < 0 ) THEN
        IF ( lv_total_count > 0 ) THEN
            BEGIN
                SELECT
                    user_name,
                    ( replace(password, '&', '&amp;') ) 
                   --, password  
                    ,
                    url
                INTO
                    x_user_name,
                    x_password,
                    x_url
                FROM
                    xx_imd_details
                WHERE
                    ROWNUM = 1;

            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;

            BEGIN
                l_body := '{ "batch_id":"'
                          || p_batch_id
                          || '" }';
                dbms_output.put_line(l_body);
                apex_web_service.g_request_headers.DELETE();
                apex_web_service.g_request_headers(1).name := 'Content-Type';
                apex_web_service.g_request_headers(1).value := 'application/json';
                l_clob := apex_web_service.make_rest_request(p_url => x_url || ':443/ic/api/integration/v1/flows/rest/WESC_AXE_GBL_AHCS_COA_MAPP_SYNC_/1.0/batch_id',
                                                            p_http_method => 'POST',
                                                            p_username => x_user_name,
                                                            p_password => x_password,
                                                            p_body => l_body);

                apex_json.parse(l_clob);
            EXCEPTION
                WHEN OTHERS THEN
                    l_xml_result := NULL;
                    l_http_status_code := '500';
            END;

        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            UPDATE wsc_ahcs_coa_sync_execution_hdr_tbl
            SET
                submission_status = 'ERROR'
            WHERE
                batch_id = p_batch_id;

            COMMIT;
    END;

END;
/
