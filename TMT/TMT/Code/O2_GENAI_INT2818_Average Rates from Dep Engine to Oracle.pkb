g_retcode_error  CONSTANT NUMBER := 2;
    g_flag_n         CONSTANT VARCHAR2(1) := 'N';
    g_flag_e         CONSTANT VARCHAR2(1) := 'E';
    g_flag_process   CONSTANT VARCHAR2(10) := 'P';

    PROCEDURE insert_pre_stg (
        p_oic_instance_id  IN   NUMBER,
        p_file_name        IN   VARCHAR2,
        p_source           IN   VARCHAR2,
        p_batch_id         IN   NUMBER,
        p_status_out       OUT  VARCHAR2,
        p_err_msg_out      OUT  VARCHAR2
    ) AS

        CURSOR v_dep_engine_stg IS
        SELECT
            created_by,
            last_updated_by,
            dep_engine_record,
            file_name,
            batch_id
        FROM
            xxgenai_fa_dep_engine_rates_inbound
        WHERE
                oic_instance_id = p_oic_instance_id
            AND upper(source) = upper(p_source)
            AND file_name = nvl(p_file_name, file_name)
            AND batch_id = p_batch_id;

    BEGIN
        dbms_output.put_line('POPULATE STAGING STARTED ');
        FOR dep_engine_cur IN v_dep_engine_stg LOOP
            dbms_output.put_line('inside loop -');
            BEGIN
                INSERT INTO xxgenai_fa_dep_engine_rates_int_stg (
                    oic_instance_id,
                    file_name,
                    country,
                    location,
                    model_year,
                    model_code,
                    model_trim,
                    fuel_type,
                    daily_rate_avg,
                    effective_date_from,
                    process_flag,
                    creation_date,
                    created_by,
                    last_update_date,
                    last_updated_by,
                    batch_id
                ) VALUES (
                    p_oic_instance_id,
                    dep_engine_cur.file_name,
                    TRIM(regexp_substr(dep_engine_cur.dep_engine_record, '[^|]+', 1, 1)),
                    TRIM(regexp_substr(dep_engine_cur.dep_engine_record, '[^|]+', 1, 2)),
                    TRIM(regexp_substr(dep_engine_cur.dep_engine_record, '[^|]+', 1, 3)),
                    TRIM(regexp_substr(dep_engine_cur.dep_engine_record, '[^|]+', 1, 4)),
                    TRIM(regexp_substr(dep_engine_cur.dep_engine_record, '[^|]+', 1, 5)),
                    TRIM(regexp_substr(dep_engine_cur.dep_engine_record, '[^|]+', 1, 6)),
                    TRIM(regexp_substr(dep_engine_cur.dep_engine_record, '[^|]+', 1, 7)),
                    TRIM(regexp_substr(dep_engine_cur.dep_engine_record, '[^|]+', 1, 8)),
                    'N',
                    sysdate,
                    dep_engine_cur.created_by,
                    sysdate,
                    dep_engine_cur.last_updated_by,
                    dep_engine_cur.batch_id
                );

            END;

        END LOOP;

        COMMIT;
        p_status_out := 'S';
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(sqlerrm);
            p_status_out := 'E';
            p_err_msg_out := 'Error occurred at insert_pre_stg ' || sqlerrm;
    END insert_pre_stg;

    PROCEDURE main_proc (
        p_oic_instance_id  IN   NUMBER,
        p_batch_id         IN   NUMBER,
        p_file_name        IN   VARCHAR2,
        p_status_out       OUT  VARCHAR2,
        p_err_msg_out      OUT  VARCHAR2
    ) IS

        x_out_message          VARCHAR2(2000) DEFAULT NULL;
        x_file                 VARCHAR2(2000) DEFAULT NULL;
        x_error_message        VARCHAR2(2000) DEFAULT NULL;
        x_suc_rec_count        NUMBER DEFAULT 0;
        x_err_rec_count        NUMBER DEFAULT 0;
        x_total_rec_count      NUMBER DEFAULT 0;
        x_flag_err_rec         VARCHAR2(5) DEFAULT 'N';
        x_rate_cnt             NUMBER;
        x_eff_cnt              NUMBER;
        x_eff_date_cnt         NUMBER;
        x_upd_rec_count        NUMBER;
        x_country_count        NUMBER DEFAULT 0;
        x_country              xxgenai_fa_dep_engine_rates_int_stg.country%TYPE;
        x_location             xxgenai_fa_dep_engine_rates_int_stg.location%TYPE;
        x_location_count       NUMBER DEFAULT 0;
        x_effective_date_to    VARCHAR2(100) DEFAULT NULL;
        x_effective_date_from  VARCHAR2(100) DEFAULT NULL;
        e_common_loader_failed EXCEPTION;
        e_file_not_found EXCEPTION;
        e_err_exists EXCEPTION;
        CURSOR c_val_data_cur IS
        SELECT
            oic_instance_id,
            file_name,
            country,
            location,
            model_year,
            model_code,
            model_trim,
            fuel_type,
            daily_rate_avg,
            effective_date_from,
            process_flag,
            creation_date,
            created_by,
            last_update_date,
            last_updated_by,
            record_id,
            effective_date_to,
            error_message,
            batch_id,
            error_code,
            error_scope,
            load_status
        FROM
            xxgenai_fa_dep_engine_rates_int_stg stg
        WHERE
                file_name = nvl(p_file_name, file_name)
            AND process_flag = g_flag_n
            AND oic_instance_id = p_oic_instance_id
            AND batch_id = p_batch_id
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    xxgenai_fa_dep_engine_rates_int_stg
                WHERE
                        model_year = stg.model_year
                    AND model_trim = stg.model_trim
                    AND model_code = stg.model_code
                    AND daily_rate_avg = stg.daily_rate_avg
                    AND process_flag = 'P'
            ) 
            AND model_code IS NOT NULL
            AND model_year IS NOT NULL
            AND model_trim IS NOT NULL
            AND daily_rate_avg IS NOT NULL
            AND EXISTS (
                SELECT
                    flv.lookup_code
                FROM
                    xxgenai_fah_fnd_lookup_values flv
                WHERE
                        flv.lookup_type = 'XX_FA_COUNTRY_CODE'
                    AND flv.enabled_flag = 'Y'
                    AND flv.lookup_code = stg.country
                    AND trunc(sysdate) BETWEEN nvl(flv.start_date_active, trunc(sysdate)) AND nvl(flv.end_date_active, trunc(sysdate))
            );

        TYPE c_val_data_t IS
            TABLE OF xxgenai_fa_dep_engine_rates_int_stg%rowtype;
        c_val_data_list        c_val_data_t;
    BEGIN

			OPEN c_val_data_cur;
        FETCH c_val_data_cur BULK COLLECT INTO c_val_data_list;
        dbms_output.put_line('cursordatacounttest : ' || c_val_data_list.count);
        CLOSE c_val_data_cur;
        UPDATE xxgenai_fa_dep_engine_rates_int_stg
        SET
            process_flag = g_flag_e,
            error_message = error_message
                            || '||'
                            || 'Location not valid'
        WHERE
                batch_id = p_batch_id
            AND process_flag IN ( g_flag_n, g_flag_e )
            AND oic_instance_id = p_oic_instance_id
            AND location IS NOT NULL
            AND NOT EXISTS (
                SELECT
                    flv.lookup_code
                FROM
                    xxgenai_fah_fnd_lookup_values flv
                WHERE
                        flv.lookup_type = 'XX_FA_DEPRATE_LOC_CODE'
                    AND flv.enabled_flag = 'Y'
                    AND flv.lookup_code = xxgenai_fa_dep_engine_rates_int_stg.location
                    AND flv.description = xxgenai_fa_dep_engine_rates_int_stg.country
                    AND trunc(sysdate) BETWEEN nvl(flv.start_date_active, trunc(sysdate)) AND nvl(flv.end_date_active, trunc(sysdate))
            );

        dbms_output.put_line('File Name : ' || p_file_name);
        x_error_message := NULL;
        FOR c_val_data IN c_val_data_cur LOOP
x_error_message := NULL;


			IF c_val_data.effective_date_from IS NULL THEN
                x_effective_date_from := to_char(to_date(substr(c_val_data.file_name, 20, 8), 'yyyymmdd'), 'DD-MON-YYYY');
            ELSE
                x_effective_date_from := to_date(c_val_data.effective_date_from, 'DD-MON-YYYY');
            END IF;


           IF to_number(c_val_data.daily_rate_avg) < 0 THEN
                x_error_message := 'Daily Average Rate should be positive';
            END IF;

            IF
                c_val_data.country NOT IN ( 'US', 'CA' )
                AND c_val_data.fuel_type IS NULL
            THEN
                x_error_message := 'Body Style and Fuel Type cannot be NULL for International Risk Vehicles';
                dbms_output.put_line(x_error_message);
            END IF;
              UPDATE xxgenai_fa_dep_engine_rates_int_stg
            SET
                process_flag = decode(x_error_message, NULL, g_flag_process, g_flag_e),
                effective_date_from = x_effective_date_from,
                error_message = decode(x_error_message, NULL, NULL, error_message
                                                                    || '||'
                                                                    || x_error_message)
            WHERE
                    record_id = c_val_data.record_id
                AND process_flag IN ( g_flag_n, g_flag_e )
                AND oic_instance_id = p_oic_instance_id;

        END LOOP;

        BEGIN
            dbms_output.put_line('OutLoopTest');
            FORALL i IN 1..c_val_data_list.count
                UPDATE xxgenai_fa_dep_engine_rates_int_stg
                SET
                    effective_date_to = to_date(c_val_data_list(i).effective_date_from) - 1,
                    last_update_date = sysdate,
                    process_flag = 'U'
                WHERE
                        1 = 1
                    AND process_flag = 'P'
                    AND country = c_val_data_list(i).country
                    AND nvl(location, 'X') = nvl(c_val_data_list(i).location, 'X')
                    AND model_year = c_val_data_list(i).model_year
                    AND model_trim = c_val_data_list(i).model_trim
                    AND model_code = c_val_data_list(i).model_code
                    AND to_date(effective_date_from, 'DD-MON-YYYY') < to_date(c_val_data_list(i).effective_date_from, 'DD-MON-YYYY')
                    AND daily_rate_avg <> c_val_data_list(i).daily_rate_avg;

        END;

        UPDATE xxgenai_fa_dep_engine_rates_int_stg
        SET
            process_flag = g_flag_e,
            error_message = error_message
                            || '||'
                            || 'Mandatory Fields Not Entered'
        WHERE
                batch_id = p_batch_id
            AND process_flag IN ( g_flag_n )
            AND oic_instance_id = p_oic_instance_id;

        COMMIT;
		EXCEPTION
        WHEN OTHERS THEN
            p_status_out := 'Exception occurred in Main program '
                            || substr(sqlerrm, 1, 200);
            p_err_msg_out := g_retcode_error;
            dbms_output.put_line(to_char('Exception occured at - '
                                         || 'CALL STACK :'
                                         || dbms_utility.format_call_stack
                                         || 'ERROR STACK :'
                                         || dbms_utility.format_error_stack
                                         || 'ERROR BACKTRACE : '
                                         || dbms_utility.format_error_backtrace));

    END main_proc;

    PROCEDURE assign_batchid (
        p_oic_instance_id  IN   NUMBER,
        p_status_out       OUT  VARCHAR2,
        p_err_msg_out      OUT  VARCHAR2
    ) AS

        x_batch_size  NUMBER := 900;
        x_count       NUMBER;
        x_from_seq    NUMBER := 0;
        x_to_seq      NUMBER := 0;
        x_batch_id    NUMBER := 0;
    BEGIN
        SELECT
            MIN(record_id)
        INTO x_from_seq
        FROM
            xxgenai_fa_dep_engine_rates_inbound
        WHERE
            oic_instance_id = p_oic_instance_id;

        SELECT
            MAX(record_id)
        INTO x_to_seq
        FROM
            xxgenai_fa_dep_engine_rates_inbound
        WHERE
            oic_instance_id = p_oic_instance_id;

        WHILE x_from_seq <= x_to_seq LOOP
            x_batch_id := x_batch_id + 1;
            UPDATE xxgenai_fa_dep_engine_rates_inbound
            SET
                batch_id = x_batch_id
            WHERE
                    record_id >= x_from_seq
                AND oic_instance_id = p_oic_instance_id
                AND ROWNUM <= 900;

            x_from_seq := x_from_seq + 900;
            EXIT WHEN x_from_seq > x_to_seq;
            COMMIT;
        END LOOP;

        p_status_out := 'S';
    EXCEPTION
        WHEN OTHERS THEN
            p_status_out := 'E';
            p_err_msg_out := sqlerrm;
    END assign_batchid;

END xxgenai_fa_dep_engine_rates_pkg;


