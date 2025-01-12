create or replace PACKAGE BODY xxgenai_gl_cda_ext_pkg AS
g_retcode_normal       CONSTANT NUMBER := 0;
    g_retcode_warning      CONSTANT NUMBER := 1;
    g_retcode_error        CONSTANT VARCHAR2(2) := 'E';
    g_retcode              VARCHAR2(2) := NULL;
    g_errbuff              VARCHAR2(4000) := NULL;
    g_user_id              CONSTANT VARCHAR2(20) := NULL;
    g_request_id           NUMBER := NULL;
    g_period               VARCHAR2(15);  
	g_car                  VARCHAR2(3) := 'Car';
    g_van                  VARCHAR2(3) := 'Van';
    g_indx                 NUMBER := 0;
    g_bulk_limit           NUMBER := 8000;
    g_new                  VARCHAR2(3) := 'NEW';
    g_in_process           VARCHAR2(15) := 'IN_PROCESS';
    g_processed            VARCHAR2(15) := 'PROCESSED';
    g_validated            VARCHAR2(15) := 'VALIDATED';
    g_v                    VARCHAR2(15) := 'VALIDATED';
    g_je_batch_id          NUMBER := NULL;
    g_ledger_id            NUMBER := NULL;
    g_enabled_flag         xxgenai_fah_fnd_lookup_values.enabled_flag%TYPE := 'Y';
    g_gl_cda_sipp_codes    xxgenai_fah_fnd_lookup_values.lookup_type%TYPE := 'XX_GL_CDA_SIPP_CODES';
    g_gl_cda_region        xxgenai_fah_fnd_lookup_values.lookup_type%TYPE := 'XX_GL_CDA_REGION';
    g_gl_cda_stat_accounts xxgenai_fah_fnd_lookup_values.lookup_type%TYPE := 'XX_GL_CDA_STAT_ACCOUNTS';
    g_gl_cda_mdmloca_map   xxgenai_fah_fnd_lookup_values.lookup_type%TYPE := 'XX_GL_CDA_MDMLOCA_MAP';
    g_gl_country_hq_loc    xxgenai_fah_fnd_lookup_values.lookup_type%TYPE := 'XX_GL_COUNTRY_HQ_LOC';
    g_journal_source       VARCHAR2(100) := 'CARDAY';
    g_journal_category     VARCHAR2(100) := 'Statistical';
    g_journal_currency     VARCHAR2(50) := 'STAT';
    g_actual_flag          VARCHAR2(2) := 'A';

  PROCEDURE process_validate_mode (
        p_ledger_id IN NUMBER,
        g_errbuff   OUT VARCHAR2,
        g_retcode   OUT VARCHAR2
    ) IS

        g_ledger_id       NUMBER := p_ledger_id;
        x_398_count       NUMBER := 0;
        x_400_count       NUMBER := 0;
        x_398_error_count NUMBER := 0;
        x_400_error_count NUMBER := 0;
        x_out_message     VARCHAR2(4000) := NULL;
        e_proc_validate EXCEPTION;
    BEGIN
    dbms_output.put_line('Entered procedure - PROCESS_VALIDATE_MODE');
	BEGIN
            SELECT
                upper(xgc.period)
            INTO g_period
            FROM
                xxgenai_gl_cda_lh_int    xgc,
                xxgenai_gl_sipp_cost_stg xgsc
            WHERE
                    1 = 1
                AND xgsc.sipp_code = xgc.sipp_code
                AND upper(xgsc.period) = upper(xgc.period)
                AND xgc.batcherror = g_validated
                AND xgsc.batch_status = g_validated
            GROUP BY
                xgc.period;

        EXCEPTION
            WHEN no_data_found THEN
                x_out_message := x_out_message || 'No Period Value in the Upstream interface table';
                RAISE e_proc_validate;
        END;

        BEGIN
      SELECT
                COUNT(1)
            INTO x_398_count
            FROM
                xxgenai_gl_cda_lh_int          xgc,
                xxgenai_gl_legal_entities_bsvs gle
            WHERE
                    1 = 1
                AND UPPER(xgc.period) = g_period
                AND gle.legal_entity_id IN (
                    SELECT
                        default_legal_context_id
                    FROM
                        xxgenai_business_units hou
                    WHERE
                            1 = 1
                        AND hou.set_of_books_id = nvl(g_ledger_id, hou.set_of_books_id)
                        AND default_legal_context_id = gle.legal_entity_id
                    GROUP BY
                        default_legal_context_id
                )
                AND xgc.legal_entity = gle.flex_segment_value
                AND xgc.batcherror = g_validated;

            IF x_398_count = 0 THEN
                x_out_message := 'No valid data exists in GL_INT_398 - Hertz CDA Vehicle Hours Interface';
                RAISE e_proc_validate;
            END IF;
            SELECT
                COUNT(1)
            INTO x_400_count
            FROM
                xxgenai_gl_sipp_cost_stg      xgs,
                xxgenai_fah_fnd_lookup_values flv,
                xxgenai_gl_ledgers            gl
            WHERE
                    1 = 1
                AND upper(xgs.period) = g_period
                AND xgs.batch_status = g_v
                AND flv.lookup_type = g_gl_cda_region
                AND flv.lookup_code = xgs.region
                AND flv.description = gl.name
                AND gl.ledger_id = nvl(g_ledger_id, gl.ledger_id)
				;

            IF x_400_count = 0 THEN
                x_out_message := x_out_message || 'No valid data exists in GL_INT_400 - Hertz CDA SIPP Average Cost Interface';
                RAISE e_proc_validate;
            END IF;

            dbms_output.put_line('Validated records in GL_INT_398 : '
                                 || x_398_count
                                 || ' and in GL_INT_400 : '
                                 || x_400_count);
        EXCEPTION
            WHEN e_proc_validate THEN
                RAISE e_proc_validate;
            WHEN OTHERS THEN
                x_out_message := 'Unexpected error while checking for the eligible validated records in GL_INT_398 and GL_INT_400 : '
                                 || substr(sqlerrm, 1, 300);
                RAISE e_proc_validate;
        END;

        BEGIN
      dbms_output.put_line('Verify if there are error records in GL_INT_398 and GL_INT_400 for period : '
                                 || g_period
                                 || ' and ledger : '
                                 || g_ledger_id);
            SELECT
                COUNT(1)
            INTO x_398_error_count
            FROM
                xxgenai_gl_cda_lh_int          xgc,
                xxgenai_business_units         hou,
                xxgenai_gl_legal_entities_bsvs gle
            WHERE
                    1 = 1
                AND xgc.batcherror = 'ERROR'
                AND hou.set_of_books_id = nvl(g_ledger_id, hou.set_of_books_id)
                AND gle.legal_entity_id = hou.default_legal_context_id
                AND upper(xgc.period) = g_period
                AND xgc.legal_entity = gle.flex_segment_value;

            IF x_398_error_count >= 1 THEN
                x_out_message := 'Error data exists for GL_INT_398 - Hertz CDA Vehicle Hours Interface';
                RAISE e_proc_validate;
            END IF;
            SELECT
                COUNT(1)
            INTO x_400_error_count
            FROM
                xxgenai_gl_sipp_cost_stg      xgs,
                xxgenai_fah_fnd_lookup_values flv,
                xxgenai_gl_ledgers            gl
            WHERE
                    1 = 1
                AND upper(xgs.period) = g_period
                AND xgs.batch_status = 'ERROR'
                AND flv.lookup_type = g_gl_cda_region
                AND flv.description = gl.name
                AND gl.ledger_id = nvl(g_ledger_id, gl.ledger_id);

            IF x_400_error_count >= 1 THEN
                x_out_message := x_out_message || 'Error data exists for GL_INT_400 - Hertz CDA SIPP Average Cost Interface';
                RAISE e_proc_validate;
            END IF;

            dbms_output.put_line('No error records in GL_INT_398 : '
                                 || x_398_count
                                 || ' and in GL_INT_400 : '
                                 || x_400_count);
        EXCEPTION
            WHEN e_proc_validate THEN
                RAISE e_proc_validate;
            WHEN OTHERS THEN
                x_out_message := 'Unexpected error while checking for the error records in GL_INT_398 or GL_INT_400 interfaces : '
                                 || substr(sqlerrm, 1, 300);
                RAISE e_proc_validate;
        END;

      g_errbuff := x_out_message;
        COMMIT;
    EXCEPTION
        WHEN e_proc_validate THEN
            g_errbuff := x_out_message;
            g_retcode := g_retcode_error;
        WHEN OTHERS THEN
            g_errbuff := 'Unexpected error in procedure - PROCESS_VALIDATE_MODE - '
                         || substr(sqlerrm, 1, 300);
            g_retcode := g_retcode_error;
    END process_validate_mode;

  PROCEDURE insert_cda_detail (
        p_instance_id    IN NUMBER,
        p_ledger_id_recs IN ledger_id_tab, 
        p_created_by     IN VARCHAR2,
        p_ledger_id      IN NUMBER,
        g_errbuff        OUT VARCHAR2,
        g_retcode        OUT VARCHAR2
    ) IS

        x_ledger_recs_count NUMBER DEFAULT 0;
        g_request_id        NUMBER := p_instance_id;
        x_array_size        NUMBER := 10000;
        g_ledger_id         NUMBER := p_ledger_id;
        g_user_id           VARCHAR2(120) := p_created_by;
        x_cur_data       NUMBER DEFAULT 0; 
        CURSOR c_insert_cda_detail IS
        SELECT
           legal_entity,
            xgc.sipp_code       sipp_code,
            location_id,
            car_days,
            g_new,
            hou.set_of_books_id set_of_books_id,
            g_request_id,
            xgsc.brand          brand,
            xgsc.product        product
        FROM
            xxgenai_gl_cda_lh_int          xgc,
            xxgenai_business_units         hou,
            xxgenai_gl_legal_entities_bsvs gle,
            xxgenai_gl_sipp_cost_stg       xgsc,
            xxgenai_hr_locations_all       xhla
        WHERE
                1 = 1
            AND xgsc.sipp_code = xgc.sipp_code
            AND UPPER(xgsc.period) = UPPER(xgc.period)
            AND xgc.batcherror = g_validated
            AND hou.set_of_books_id = nvl(g_ledger_id, hou.set_of_books_id)
            AND gle.legal_entity_id = hou.default_legal_context_id
            AND UPPER(xgc.period) = nvl(g_period, xgc.period)
            AND xgc.legal_entity = gle.flex_segment_value
            AND xgsc.batch_status = g_validated
            AND xhla.internal_location_code = xgc.location_id
            AND xhla.country = xgsc.region
        GROUP BY
           legal_entity,
            xgc.sipp_code,
            location_id,
            car_days,
            g_new,
            hou.set_of_books_id,
            g_request_id,
            xgsc.brand,
            xgsc.product;

        TYPE cda_detail_type IS
            TABLE OF c_insert_cda_detail%rowtype INDEX BY BINARY_INTEGER;
        cda_rec_table       cda_detail_type;
    BEGIN
        BEGIN
            SELECT
                upper(xgc.period)
            INTO g_period
            FROM
                xxgenai_gl_cda_lh_int    xgc,
                xxgenai_gl_sipp_cost_stg xgsc
            WHERE
                    1 = 1
                AND xgsc.sipp_code = xgc.sipp_code
                AND upper(xgsc.period) = upper(xgc.period)
                AND xgc.batcherror = g_validated
                AND xgsc.batch_status = g_validated
            GROUP BY
                xgc.period;

        EXCEPTION
            WHEN no_data_found THEN
                g_errbuff := 'No Period Value in the Upstream interface table';
        END;

        BEGIN
         SELECT
           count(1) into x_cur_data
        FROM
            xxgenai_gl_cda_lh_int          xgc,
            xxgenai_business_units         hou,
            xxgenai_gl_legal_entities_bsvs gle,
            xxgenai_gl_sipp_cost_stg       xgsc,
            xxgenai_hr_locations_all       xhla
        WHERE
                1 = 1
            AND xgsc.sipp_code = xgc.sipp_code
            AND UPPER(xgsc.period) = UPPER(xgc.period)
            AND xgc.batcherror = g_validated
            AND hou.set_of_books_id = nvl(g_ledger_id, hou.set_of_books_id)
            AND gle.legal_entity_id = hou.default_legal_context_id
            AND UPPER(xgc.period) = UPPER(nvl(g_period, xgc.period))
            AND xgc.legal_entity = gle.flex_segment_value
            AND xgsc.batch_status = g_validated
            AND xhla.internal_location_code = xgc.location_id
            AND xhla.country = xgsc.region
      ;
    EXCEPTION
            WHEN no_data_found THEN
                g_errbuff := 'No valid data from Upstream interface table';

        END;
        dbms_output.put_line(' At Start: ' || current_timestamp);
 If x_cur_data > 0 then
        OPEN c_insert_cda_detail;
        LOOP
            dbms_output.put_line('cda_rec_table.COUNT1 :' || cda_rec_table.count);
            FETCH c_insert_cda_detail
            BULK COLLECT INTO cda_rec_table LIMIT x_array_size;
            dbms_output.put_line('cda_rec_table.COUNT2 :' || cda_rec_table.count);
          BEGIN
                dbms_output.put_line('Entered procedure - INSERT_CDA_DETAIL');
                 dbms_output.put_line(' Entered procedure: ' || current_timestamp);
            FORALL j IN 1..cda_rec_table.count SAVE EXCEPTIONS
           INSERT INTO xxgenai_gl_cda_detail (
                        accounting_period,
                        legal_entity,
                        sipp_code,
                        location_unique_id,
                        car_days,
                        status,
                        ledger_id,
                        oic_instance_id,
                        creation_date,
                        created_by,
                        last_update_date,
                        last_updated_by,
                        brand,
                        product
                    ) VALUES (
                        g_period,
                        cda_rec_table(j).legal_entity,
                        cda_rec_table(j).sipp_code,
                        cda_rec_table(j).location_id,
                        cda_rec_table(j).car_days,
                        cda_rec_table(j).g_new,
                        cda_rec_table(j).set_of_books_id,
                        cda_rec_table(j).g_request_id,
                        sysdate,
                        g_user_id,
                        sysdate,
                        g_user_id, 
                        cda_rec_table(j).brand,
                        cda_rec_table(j).product
                    );

                dbms_output.put_line(SQL%rowcount || ' records inserted into XXgenai_GL_CDA_DETAIL table');
                 dbms_output.put_line(' After insert into XXgenai_GL_CDA_DETAIL: ' || current_timestamp);

             FORALL i IN 1..cda_rec_table.count SAVE EXCEPTIONS
             UPDATE xxgenai_gl_cda_lh_int xgc
                    SET
                        source_instance_id = g_request_id
                    WHERE
                            1 = 1
                        AND xgc.sipp_code = cda_rec_table(i).sipp_code
                        AND UPPER(xgc.period) = g_period
                        AND xgc.batcherror = g_validated
                        AND xgc.legal_entity = cda_rec_table(i).legal_entity;

                FORALL k IN 1..cda_rec_table.count SAVE EXCEPTIONS
                    UPDATE xxgenai_gl_sipp_cost_stg xgsc
                    SET
                        source_instance_id = g_request_id
                    WHERE
                            1 = 1
                        AND xgsc.sipp_code = cda_rec_table(k).sipp_code
                        AND UPPER(xgsc.period) = g_period
                        AND xgsc.batch_status = g_validated;

                dbms_output.put_line(SQL%rowcount || ' records inserted into XXgenai_GL_CDA_DETAIL table');
                dbms_output.put_line('Update Source Instance Id in xxgenai_gl_cda_lh_int');
                dbms_output.put_line('Update Source Instance Id in xxgenai_gl_cda_lh_int');
                 dbms_output.put_line(' Update Source Instance Id: ' || current_timestamp);
            END;
        EXIT WHEN c_insert_cda_detail%notfound;
        END LOOP;
        CLOSE c_insert_cda_detail;
        end if;

       BEGIN
            x_ledger_recs_count := p_ledger_id_recs.count;
        EXCEPTION
            WHEN OTHERS THEN
                x_ledger_recs_count := 0;
        END;

        IF x_ledger_recs_count > 0 THEN
            FORALL i IN p_ledger_id_recs.first..p_ledger_id_recs.last SAVE EXCEPTIONS
                UPDATE xxgenai_gl_cda_detail
                SET
                    status = 'ERROR',
                    last_update_date = sysdate,
                    error_message = 'CDA Journal Exists'
                WHERE
                        1 = 1
                    AND oic_instance_id = p_instance_id
                    AND ledger_id = p_ledger_id_recs(i).ledger_id;

        END IF;

        COMMIT;
    dbms_output.put_line(' AT End: ' || current_timestamp);
    EXCEPTION
        WHEN OTHERS THEN
            g_errbuff := 'Unexpected error in procedure - INSERT_CDA_DETAIL - '
                         || substr(sqlerrm, 1, 300);
            g_retcode := g_retcode_error;
    END insert_cda_detail;

  PROCEDURE validate_val_mode (
        p_ledger_id       IN NUMBER,
        p_oic_instance_id IN NUMBER
           ,
        p_batch_id        IN NUMBER,
        g_errbuff         OUT VARCHAR2,
        g_retcode         OUT VARCHAR2
    ) IS

        g_ledger_id        NUMBER := p_ledger_id;
        x_gl_count         NUMBER;
        x_sipp_cnt         NUMBER;
        x_coa_location     VARCHAR2(100);
        x_monthly_cost     NUMBER;
        x_num_of_days      NUMBER;
        x_daily_cost       NUMBER;
        x_weighted_car_day NUMBER;
        x_led_count        NUMBER;
        x_country          VARCHAR2(20);
        x_state            VARCHAR2(20);
        x_cda_region       VARCHAR2(20);
        x_out_message      VARCHAR2(4000);
        x_location_name    VARCHAR2(100);
        x_car_van          VARCHAR2(5);
        x_brand            VARCHAR2(15);
        x_product          VARCHAR2(15);
        x_us_ca_cnt        NUMBER := 0;
        g_oic_instance_id  NUMBER := p_oic_instance_id;
        x_array_size       NUMBER := 10000;
        e_cda_det_err EXCEPTION;
        x_counter          NUMBER;
        CURSOR c_fetch_ledgers IS
        SELECT
            xgc.legal_entity,
            xgc.location_unique_id,
            xgc.sipp_code,
            xgc.car_days,
            xgc.ledger_id,
            xgc.coa_location,
            xgc.cda_region,
            xgc.location_name,
            xgc.monthly_rate,
            xgc.hourly_rate,
            xgc.monthly_days,
            xgc.weighted_car_day,
            xgc.status,
            xgc.car_van,
            xgc.last_update_date,
            xgc.brand,
            xgc.product,
            xgc.country,
            error_message,
            oic_instance_id
        FROM
            xxgenai_gl_cda_detail xgc
        WHERE
                1 = 1
            AND xgc.status = g_new
            AND oic_instance_id = p_oic_instance_id
            AND xgc.ledger_id = nvl(g_ledger_id, xgc.ledger_id)
            AND xgc.batch_id = p_batch_id;

        TYPE fetch_ledgers IS
            TABLE OF c_fetch_ledgers%rowtype;
        fetch_ledgers_rec  fetch_ledgers := fetch_ledgers();
        update_table       fetch_ledgers := fetch_ledgers();
    BEGIN
  dbms_output.put_line('Entered procedure - VALIDATE_VAL_MODE');
        dbms_output.put_line(' At Start: ' || current_timestamp);
        BEGIN
            SELECT
                upper(xgc.period)
            INTO g_period
            FROM
                xxgenai_gl_cda_lh_int    xgc,
                xxgenai_gl_sipp_cost_stg xgsc
            WHERE
                    1 = 1
                AND xgsc.sipp_code = xgc.sipp_code
                AND upper(xgsc.period) = upper(xgc.period)
                AND xgc.batcherror = g_validated
                AND xgsc.batch_status = g_validated
            GROUP BY
                xgc.period;

        EXCEPTION
            WHEN no_data_found THEN
                g_errbuff := 'No Period Value in the Upstream interface table';
        END;

        dbms_output.put_line('g_period: ' || g_period);
      BEGIN
            x_counter := 0;
            OPEN c_fetch_ledgers;
            LOOP
                FETCH c_fetch_ledgers
          BULK COLLECT INTO fetch_ledgers_rec LIMIT x_array_size;
                EXIT WHEN fetch_ledgers_rec.count = 0;
          dbms_output.put_line(' fetch_ledgers_rec.count: ' || fetch_ledgers_rec.count);
                FOR i IN fetch_ledgers_rec.first..fetch_ledgers_rec.last LOOP
                    x_gl_count := 0;
                    x_sipp_cnt := 0;
                    x_coa_location := '';
                    x_monthly_cost := 0;
                    x_num_of_days := 0;
                    x_daily_cost := 0;
                    x_weighted_car_day := 0;
                    x_led_count := 0;
                    x_country := '';
                    x_state := '';
                    x_cda_region := '';
                    x_out_message := '';
                    x_location_name := '';
                    x_car_van := '';
                    x_brand := '';
                    x_product := '';
                    x_us_ca_cnt := 0;
                    update_table.extend;

       SELECT
                        COUNT(1)
                    INTO x_sipp_cnt
                    FROM
                        xxgenai_fah_fnd_lookup_values
                    WHERE
                            1 = 1
                        AND enabled_flag = g_enabled_flag
                        AND lookup_code = fetch_ledgers_rec(i).sipp_code
                        AND lookup_type = g_gl_cda_sipp_codes
                    ;

                    IF x_sipp_cnt = 0 THEN
                        x_out_message := 'SIPP Code: '
                                         || fetch_ledgers_rec(i).sipp_code
                                         || ' does not exists in the lookup XX_GL_CDA_SIPP_CODES';
                        RAISE e_cda_det_err;
                    END IF;

            BEGIN
      dbms_output.put_line('Derive state and country' || fetch_ledgers_rec(i).location_unique_id);
                        SELECT
                            country,
                            region_2
                        INTO
                            x_country,
                            x_state
                        FROM
                            xxgenai_hr_locations_all
                        WHERE
                      internal_location_code = fetch_ledgers_rec(i).location_unique_id
                      EXCEPTION
                        WHEN OTHERS THEN
                            x_out_message := 'Issue in deriving state and country for location_unique_id : ' || fetch_ledgers_rec(i).location_unique_id
                            ;
                            RAISE e_cda_det_err;
                    END;

          IF x_country = 'US' THEN
                        IF x_state = 'HW' THEN
                            x_cda_region := 'HW';
                        ELSIF x_state = 'AK' THEN
                            x_cda_region := 'AK';
                        ELSIF x_state = 'PR' THEN
                            x_cda_region := 'PR';
                    ELSE
                            x_cda_region := 'US';
                        END IF;
                    ELSE
                        BEGIN
                            SELECT
                                meaning
                            INTO x_cda_region
                            FROM
                                xxgenai_fah_fnd_lookup_values
                            WHERE
                                    1 = 1
                                AND lookup_code = x_country
                                AND enabled_flag = g_enabled_flag
                                AND lookup_type = g_gl_cda_region
                               ;

                     EXCEPTION
                            WHEN OTHERS THEN
                                x_out_message := x_out_message
                                                 || 'Issue in deriving CDA Region for Country : '
                                                 || x_country;
                                RAISE e_cda_det_err;
                        END;
                    END IF;

                    dbms_output.put_line('CDA Region is : '
                                         || x_cda_region
                                         || ' for Country : '
                                         || x_country);

           dbms_output.put_line('Derive Cost'
                                         || fetch_ledgers_rec(i).sipp_code
                                         || g_period
                                         || x_cda_region
                                         || g_validated);

                    BEGIN
         
                        SELECT
                            brand
                        INTO x_brand
                        FROM
                            xxgenai_gl_sipp_cost_stg xgs
                        WHERE
                                1 = 1
                            AND sipp_code = fetch_ledgers_rec(i).sipp_code
                            AND upper(period) = g_period
                            AND region = x_cda_region
                            AND batch_status = g_validated
                        GROUP BY
                            brand;

                        dbms_output.put_line('Brand for SIPP Code : '
                                             || fetch_ledgers_rec(i).sipp_code
                                             || ' and CDA Region : '
                                             || x_cda_region
                                             || ' is : '
                                             || x_brand);

                    EXCEPTION
                        WHEN no_data_found THEN
                       SELECT
                                attribute2
                            INTO x_brand
                            FROM
                                xxgenai_fah_fnd_lookup_values
                            WHERE
                                    lookup_type = g_gl_country_hq_loc
                                AND meaning = x_country
                                AND enabled_flag = g_enabled_flag
                                ;

                        WHEN OTHERS THEN
                            dbms_output.put_line('ERROM - :' || sqlerrm);
                            x_out_message := x_out_message
                                             || 'Issue in deriving Brand : '
                                             || x_brand;
                            RAISE e_cda_det_err;
                    END;

                    BEGIN
                    SELECT
                            product
                        INTO x_product
                        FROM
                            xxgenai_gl_sipp_cost_stg xgs
                        WHERE
                                1 = 1
                            AND sipp_code = fetch_ledgers_rec(i).sipp_code
                            AND upper(period) = g_period
                            AND region = x_cda_region
                            AND batch_status = g_validated
                        GROUP BY
                            product;

                        dbms_output.put_line('Product for SIPP Code : '
                                             || fetch_ledgers_rec(i).sipp_code
                                             || ' and CDA Region : '
                                             || x_cda_region
                                             || ' is : '
                                             || x_product);

                    EXCEPTION
                        WHEN no_data_found THEN
                        SELECT
                                attribute5
                            INTO x_product
                            FROM
                                xxgenai_fah_fnd_lookup_values
                            WHERE
                                    lookup_type = g_gl_country_hq_loc
                                AND meaning = x_country
                                AND enabled_flag = g_enabled_flag
                                ;

                        WHEN OTHERS THEN
                            x_out_message := x_out_message
                                             || 'Issue in deriving Product : '
                                             || x_product;
                            RAISE e_cda_det_err;
                    END;

                    BEGIN
                        SELECT
                            cost
                        INTO x_monthly_cost
                        FROM
                            xxgenai_gl_sipp_cost_stg xgs
                        WHERE
                                1 = 1
                            AND sipp_code = fetch_ledgers_rec(i).sipp_code
                            AND upper(period) = g_period
                            AND region = x_cda_region
                            AND batch_status = g_validated
                        GROUP BY
                            cost;

                        IF x_monthly_cost < 0 THEN
                            x_out_message := 'Cost Value is negative';
                            RAISE e_cda_det_err;
                        END IF;
                        dbms_output.put_line('Cost for SIPP Code : '
                                             || fetch_ledgers_rec(i).sipp_code
                                             || ' and CDA Region : '
                                             || x_cda_region
                                             || ' is : '
                                             || x_monthly_cost);

                    EXCEPTION
                        WHEN no_data_found THEN
                            x_monthly_cost := 0;
                    END;

                    SELECT
                        to_char(last_day('01-' || g_period),
                                'DD')
                    INTO x_num_of_days
                    FROM
                        dual;
                   SELECT
                        COUNT(1)
                    INTO x_us_ca_cnt
                    FROM
                        xxgenai_gl_ledgers gl
                    WHERE
                            1 = 1
                        AND gl.ledger_id = fetch_ledgers_rec(i).ledger_id
                        AND ( ( name LIKE '%US%' )
                              OR ( name LIKE '%CA%' ) );

                    IF x_us_ca_cnt >= 1 THEN
                        x_car_van := g_car;
                    ELSE
                        BEGIN
                            SELECT
                                description
                            INTO x_car_van
                            FROM
                                xxgenai_fah_fnd_lookup_values
                            WHERE
                                    1 = 1
                                AND lookup_type = 'XX_GL_CDA_SIPP_CODES'
                                AND enabled_flag = g_enabled_flag
                                AND lookup_code = fetch_ledgers_rec(i).sipp_code
                              ;

                        EXCEPTION
                            WHEN OTHERS THEN
                                x_out_message := x_out_message
                                                 || 'Error in identifying CAR/VAN Value for SIPP Code : '
                                                 || fetch_ledgers_rec(i).sipp_code
                                                 || ' - '
                                                 || substr(sqlerrm, 1, 200);

                                RAISE e_cda_det_err;
                        END;
                    END IF;

               IF x_out_message IS NULL THEN
                     x_counter := x_counter + 1;
                        update_table(x_counter).coa_location := x_coa_location;
                        update_table(x_counter).location_name := x_location_name;
                        update_table(x_counter).cda_region := x_cda_region;
                        update_table(x_counter).monthly_rate := x_monthly_cost;
                        update_table(x_counter).hourly_rate := x_daily_cost;
                        update_table(x_counter).monthly_days := x_num_of_days;
                        update_table(x_counter).weighted_car_day := round(x_weighted_car_day, 8);
                        update_table(x_counter).status := g_in_process;
                        update_table(x_counter).car_van := x_car_van;
                        update_table(x_counter).last_update_date := sysdate;
                        update_table(x_counter).brand := x_brand;
                        update_table(x_counter).product := x_product;
                        update_table(x_counter).country := x_country;
                        update_table(x_counter).ledger_id := fetch_ledgers_rec(i).ledger_id;
                        update_table(x_counter).legal_entity := fetch_ledgers_rec(i).legal_entity;
                        update_table(x_counter).sipp_code := fetch_ledgers_rec(i).sipp_code;
                        update_table(x_counter).oic_instance_id := fetch_ledgers_rec(i).oic_instance_id;
                        update_table(x_counter).location_unique_id := fetch_ledgers_rec(i).location_unique_id;
                        update_table(x_counter).car_days := fetch_ledgers_rec(i).car_days;
                        update_table(x_counter).ledger_id := fetch_ledgers_rec(i).ledger_id;
                    ELSIF x_sipp_cnt = 0 OR x_out_message IS NOT NULL THEN
                        x_counter := x_counter + 1;
                   update_table(x_counter).status := 'ERROR';
                        update_table(x_counter).error_message := x_out_message;
                    END IF;
                    END LOOP;

            END LOOP;

            CLOSE c_fetch_ledgers;	
	        BEGIN
                dbms_output.put_line(' Before Update: ' || current_timestamp);
             FOR x_stg_update IN 1..update_table.count LOOP
                    UPDATE xxgenai_gl_cda_detail
                    SET
                        coa_location = update_table(x_stg_update).coa_location,
                        location_name = update_table(x_stg_update).location_name,
                        cda_region = update_table(x_stg_update).cda_region,
                        monthly_rate = update_table(x_stg_update).monthly_rate,
                        hourly_rate = update_table(x_stg_update).hourly_rate,
                        monthly_days = update_table(x_stg_update).monthly_days,
                        weighted_car_day = update_table(x_stg_update).weighted_car_day,
                        status = update_table(x_stg_update).status,
                        car_van = update_table(x_stg_update).car_van,
                        last_update_date = update_table(x_stg_update).last_update_date,
                        brand = update_table(x_stg_update).brand,
                        product = update_table(x_stg_update).product,
                        country = update_table(x_stg_update).country,
                        error_message = update_table(x_stg_update).error_message
                    WHERE
                            legal_entity = update_table(x_stg_update).legal_entity
                        AND sipp_code = update_table(x_stg_update).sipp_code
                        AND oic_instance_id = update_table(x_stg_update).oic_instance_id
                        AND location_unique_id = update_table(x_stg_update).location_unique_id
                        AND car_days = update_table(x_stg_update).car_days
                        AND ledger_id = update_table(x_stg_update).ledger_id
                        AND status = g_new
                        AND accounting_period = g_period;

                    COMMIT;
                END LOOP;

                dbms_output.put_line(' At After  update: ' || current_timestamp);
            END;

            COMMIT;
        END;

        dbms_output.put_line(' At End: ' || current_timestamp);
      EXCEPTION
        WHEN OTHERS THEN
            g_errbuff := 'Unexpected error in procedure - VALIDATE_VAL_MODE - '
                         || substr(sqlerrm, 1, 300);
            g_retcode := g_retcode_error;
    END validate_val_mode;

  PROCEDURE validate_summarize (
        p_oic_instance_id IN NUMBER,
        p_created_by      IN VARCHAR2,
        g_errbuff         OUT VARCHAR2,
        g_retcode         OUT VARCHAR2
    ) IS

        x_out_message VARCHAR2(4000) := NULL;
        x_ledger_name xxgenai_gl_ledgers.name%TYPE := NULL;
        e_cda_summ_err EXCEPTION;
        g_request_id  NUMBER := p_oic_instance_id;
        g_user_id     VARCHAR2(120) := p_created_by;
        TYPE g_summ_rec IS RECORD (
            accounting_period  xxgenai_gl_cda_summary.accounting_period%TYPE,
            legal_entity       xxgenai_gl_cda_summary.legal_entity%TYPE,
            ledger_name        xxgenai_gl_cda_summary.ledger_name%TYPE,
            ledger_id          xxgenai_gl_cda_summary.ledger_id%TYPE,
            location_unique_id xxgenai_gl_cda_summary.location_unique_id%TYPE,
            location_name      xxgenai_gl_cda_summary.location%TYPE,
            coa_location       xxgenai_gl_cda_summary.coa_location%TYPE,
            car_van            xxgenai_gl_cda_summary.car_van%TYPE,
            cda_region         xxgenai_gl_cda_summary.cda_region%TYPE,
            stat_value         xxgenai_gl_cda_summary.stat_value%TYPE,
            stat_type          xxgenai_gl_cda_summary.stat_type%TYPE,
            status             xxgenai_gl_cda_summary.status%TYPE,
            oic_instance_id    xxgenai_gl_cda_summary.oic_instance_id%TYPE,
            creation_date      xxgenai_gl_cda_summary.creation_date%TYPE,
            created_by         xxgenai_gl_cda_summary.created_by%TYPE,
            last_update_date   xxgenai_gl_cda_summary.last_update_date%TYPE,
            last_updated_by    xxgenai_gl_cda_summary.last_updated_by%TYPE,
            brand              xxgenai_gl_cda_summary.brand%TYPE,
            product            xxgenai_gl_cda_summary.product%TYPE,
            country            xxgenai_gl_cda_summary.product%TYPE   
                               );
        TYPE g_summ_tbl_type IS
            TABLE OF g_summ_rec INDEX BY BINARY_INTEGER;
        g_summ_tbl    g_summ_tbl_type;
        CURSOR c_summ_insert_data IS
        SELECT
            legal_entity,
            coa_location,
            ledger_id,
            SUM(car_days)         car_days,
            SUM(weighted_car_day) weighted_car_day,
            cda_region,
            car_van,
            location_name,
            location_unique_id,
            accounting_period,
            brand,
            product,
            country  
        FROM
            xxgenai_gl_cda_detail xgc
        WHERE
                1 = 1
            AND status = g_in_process
            AND oic_instance_id = g_request_id
        GROUP BY
            legal_entity,
            coa_location,
            ledger_id,
            accounting_period,
            location_unique_id,
            location_name,
            cda_region,
            car_van,
            brand,
            product,
            country   
            ;

    BEGIN
        dbms_output.put_line('Derive Summarized data from CDA Detail table');
        FOR l_summ_data IN c_summ_insert_data LOOP
            BEGIN
                SELECT
                    upper(xgc.period)
                INTO g_period
                FROM
                    xxgenai_gl_cda_lh_int    xgc,
                    xxgenai_gl_sipp_cost_stg xgsc
                WHERE
                        1 = 1
                    AND xgsc.sipp_code = xgc.sipp_code
                    AND upper(xgsc.period) = upper(xgc.period)
                    AND xgc.batcherror = g_validated
                    AND xgsc.batch_status = g_validated
                GROUP BY
                    xgc.period;

            EXCEPTION
                WHEN no_data_found THEN
                    g_errbuff := 'No Period Value in the Upstream interface table';
            END;

            BEGIN
         dbms_output.put_line('Entered c_summ_insert_data ');
                FOR i IN 1..4 LOOP
                    g_indx := g_indx + 1;
                    dbms_output.put_line('Entered loop i : '
                                         || i
                                         || ' and G_INDX : '
                                         || g_indx);
                    IF i = 1 THEN
                        g_summ_tbl(g_indx).stat_type := 'Car Days';
                        g_summ_tbl(g_indx).stat_value := l_summ_data.car_days;
                    ELSIF i = 2 THEN
                        g_summ_tbl(g_indx).stat_type := 'Weighted Car Days';
                        g_summ_tbl(g_indx).stat_value := l_summ_data.weighted_car_day;
                    ELSIF i = 3 THEN
                        g_summ_tbl(g_indx).stat_type := 'Car Day Hours';
                        g_summ_tbl(g_indx).stat_value := l_summ_data.car_days * 24;
                    ELSIF i = 4 THEN
                        g_summ_tbl(g_indx).stat_type := 'Total Weighted Car Hours';
                        g_summ_tbl(g_indx).stat_value := l_summ_data.weighted_car_day * 24;
                    END IF;

                   SELECT
                        name
                    INTO x_ledger_name
                    FROM
                        xxgenai_gl_ledgers
                    WHERE
                            1 = 1
                        AND ledger_id = l_summ_data.ledger_id;

                    g_summ_tbl(g_indx).accounting_period := l_summ_data.accounting_period;
                    g_summ_tbl(g_indx).legal_entity := l_summ_data.legal_entity;
                    g_summ_tbl(g_indx).ledger_name := x_ledger_name;
                    g_summ_tbl(g_indx).ledger_id := l_summ_data.ledger_id;
                    g_summ_tbl(g_indx).location_unique_id := l_summ_data.location_unique_id;
                    g_summ_tbl(g_indx).location_name := l_summ_data.location_name;
                    g_summ_tbl(g_indx).coa_location := l_summ_data.coa_location;
                    g_summ_tbl(g_indx).cda_region := l_summ_data.cda_region;
                    g_summ_tbl(g_indx).car_van := l_summ_data.car_van;
                    g_summ_tbl(g_indx).brand := l_summ_data.brand;
                    g_summ_tbl(g_indx).product := l_summ_data.product;
                    g_summ_tbl(g_indx).country := l_summ_data.country; 
                END LOOP;

                dbms_output.put_line('END LOOP G_INDX : ' || g_indx);
                IF g_indx <= g_bulk_limit THEN
                    BEGIN
                        dbms_output.put_line('G_INDX : '
                                             || g_indx
                                             || ' , G_BULK_LIMIT : '
                                             || g_bulk_limit
                                             || ' and G_SUMM_TBL.COUNT : '
                                             || g_summ_tbl.count);

                        FORALL j IN 1..g_summ_tbl.count SAVE EXCEPTIONS
                            INSERT INTO xxgenai_gl_cda_summary (
                                accounting_period,
                                legal_entity,
                                ledger_name,
                                ledger_id,
                                location_unique_id,
                                location,
                                coa_location,
                                car_van,
                                cda_region,
                                stat_value,
                                stat_type,
                                status,
                                oic_instance_id,
                                creation_date,
                                created_by,
                                last_update_date,
                                last_updated_by,
                                brand,
                                product,
                                country  
                            ) VALUES (
                                g_summ_tbl(j).accounting_period,
                                g_summ_tbl(j).legal_entity,
                                g_summ_tbl(j).ledger_name,
                                g_summ_tbl(j).ledger_id,
                                g_summ_tbl(j).location_unique_id,
                                g_summ_tbl(j).location_name,
                                g_summ_tbl(j).coa_location,
                                g_summ_tbl(j).car_van,
                                g_summ_tbl(j).cda_region,
                                g_summ_tbl(j).stat_value,
                                g_summ_tbl(j).stat_type,
                                g_new,
                                g_request_id,
                                sysdate,
                                g_user_id,
                                sysdate,
                                g_user_id,
                                g_summ_tbl(j).brand, 
                                g_summ_tbl(j).product,
                                g_summ_tbl(j).country  
                            );

                    EXCEPTION
                        WHEN OTHERS THEN
                            x_out_message := 'Error in inserting data into CDA Summary table';
                            RAISE e_cda_summ_err;
                    END;

                    g_indx := 0;
                END IF;

            EXCEPTION
                WHEN e_cda_summ_err THEN
                    RAISE e_cda_summ_err;
                WHEN OTHERS THEN
                    x_out_message := 'Unexpected error in cursor - C_SUMM_DATA - '
                                     || substr(sqlerrm, 1, 200);
                    RAISE e_cda_summ_err;
            END;

        END LOOP;

        COMMIT;
       EXCEPTION
        WHEN e_cda_summ_err THEN
            g_errbuff := x_out_message;
            g_retcode := g_retcode_error;
            ROLLBACK;
        WHEN OTHERS THEN
            ROLLBACK;
            g_errbuff := 'Unexpected error in procedure - VALIDATE_SUMMARIZE - '
                         || substr(sqlerrm, 1, 300);
            g_retcode := g_retcode_error;
    END validate_summarize;

   PROCEDURE insert_xxgenai_gl_interface (
        p_ledger_id       IN NUMBER,
        p_oic_instance_id IN NUMBER,
        p_created_by      IN VARCHAR2,
        g_errbuff         OUT VARCHAR2,
        g_retcode         OUT VARCHAR2
    ) IS

        g_ledger_id   NUMBER := p_ledger_id;
        g_instance_id NUMBER := p_oic_instance_id;
        x_array_size  NUMBER := 10000;
        g_user_id     VARCHAR2(120) := p_created_by;
        x_no_record   NUMBER;
        CURSOR c_insert_gl_interface IS
        SELECT
            g_new                             status,
            ledger_id,
            g_journal_source                  user_je_source_name,
            g_journal_category                user_je_category_name
                            (
                SELECT
                    last_day('01-' || g_period)
                FROM
                    dual
            )                                 accounting_date,
            g_journal_currency                currency_code,
            sysdate                           date_created,
            g_instance_id                     oic_instance_id,
            sysdate                           creation_date,
            g_user_id                         created_by,
            sysdate                           last_update_date,
            g_user_id                         last_updated_by,
            g_actual_flag                     actual_flag,
            legal_entity                                                       
            ,
            brand                                                         
            ,
                (
                SELECT
                    nvl((
                        SELECT
                            xha.attribute8
                        FROM
                            xxgenai_hr_locations_all xha
                        WHERE
                                xha.internal_location_code = xgc.location_unique_id
                            AND xgc.ledger_id = nvl(g_ledger_id, ledger_id)
                        GROUP BY
                            xha.attribute8
                    ),
                        (
                        SELECT
                            attribute3
                        FROM
                            xxgenai_fah_fnd_lookup_values
                        WHERE
                                lookup_type = g_gl_country_hq_loc
                            AND meaning = xgc.country
                          ))
                FROM
                    dual
            )                                 attribute8    
                      ,
                (
                SELECT
                    nvl((
                        SELECT
                            xha.attribute14
                        FROM
                            xxgenai_hr_locations_all xha
                        WHERE
                                xha.internal_location_code = xgc.location_unique_id
                            AND xgc.ledger_id = nvl(g_ledger_id, ledger_id)
                        GROUP BY
                            xha.attribute14
                    ),
                        (
                        SELECT
                            attribute4
                        FROM
                            xxgenai_fah_fnd_lookup_values
                        WHERE
                                lookup_type = g_gl_country_hq_loc
                            AND meaning = xgc.country
                            AND enabled_flag = g_enabled_flag
                           ))
                FROM
                    dual
            )                                 segment4   
            ,
            decode(stat_type,
                   'Car Days',
                   (
                SELECT
                    substr(flv.description,
                           1,
                           instr(flv.description, '-', 1) - 1)
                FROM
                    xxgenai_fah_fnd_lookup_values flv
                WHERE
                        flv.meaning = 'Car Days'
                    AND flv.enabled_flag = g_enabled_flag
                   AND flv.lookup_type = g_gl_cda_stat_accounts
            ),
                   'Weighted Car Days',
                   (
                SELECT
                    substr(flv.description,
                           1,
                           instr(flv.description, '-', 1) - 1)
                FROM
                    xxgenai_fah_fnd_lookup_values flv
                WHERE
                        flv.meaning = 'Weighted Car Days'
                    AND flv.enabled_flag = g_enabled_flag
                    AND flv.lookup_type = g_gl_cda_stat_accounts
            ),
                   'Car Day Hours',
                   (
                SELECT
                    substr(flv.description,
                           1,
                           instr(flv.description, '-', 1) - 1)
                FROM
                    xxgenai_fah_fnd_lookup_values flv
                WHERE
                        flv.meaning = 'Car Day Hours'
                    AND flv.enabled_flag = g_enabled_flag
                    AND flv.lookup_type = g_gl_cda_stat_accounts
            ),
                   'Total Weighted Car Hours',
                   (
                SELECT
                    substr(flv.description,
                           1,
                           instr(flv.description, '-', 1) - 1)
                FROM
                    xxgenai_fah_fnd_lookup_values flv
                WHERE
                        flv.meaning = 'Total Weighted Car Hours'
                    AND flv.enabled_flag = g_enabled_flag
                    AND flv.lookup_type = g_gl_cda_stat_accounts
            ))                                segment5                                                              
            ,
            decode(stat_type,
                   'Car Days',
                   (
                SELECT
                    substr(flv.description,
                           instr(flv.description, '-', 1) + 1,
                           length(flv.description))
                FROM
                    xxgenai_fah_fnd_lookup_values flv
                WHERE
                        flv.meaning = 'Car Days'
                    AND flv.enabled_flag = 'Y'
                    AND flv.lookup_type = g_gl_cda_stat_accounts
            ),
                   'Weighted Car Days',
                   (
                SELECT
                    substr(flv.description,
                           instr(flv.description, '-', 1) + 1,
                           length(flv.description))
                FROM
                    xxgenai_fah_fnd_lookup_values flv
                WHERE
                        flv.meaning = 'Weighted Car Days'
                    AND flv.enabled_flag = 'Y'
                    AND flv.lookup_type = g_gl_cda_stat_accounts
            ),
                   'Car Day Hours',
                   (
                SELECT
                    substr(flv.description,
                           instr(flv.description, '-', 1) + 1,
                           length(flv.description))
                FROM
                    xxgenai_fah_fnd_lookup_values flv
                WHERE
                        flv.meaning = 'Car Day Hours'
                    AND flv.enabled_flag = 'Y'
                    AND flv.lookup_type = g_gl_cda_stat_accounts
            ),
                   'Total Weighted Car Hours',
                   (
                SELECT
                    substr(flv.description,
                           instr(flv.description, '-', 1) + 1,
                           length(flv.description))
                FROM
                    xxgenai_fah_fnd_lookup_values flv
                WHERE
                        flv.meaning = 'Total Weighted Car Hours'
                    AND flv.enabled_flag = 'Y'
                    AND flv.lookup_type = g_gl_cda_stat_accounts
            ))                                segment6                                                      
            ,
            '0000'                            segment7                                                       
            ,
            product                                                                    
            ,
            '0000000'                         segment9                                                       
            ,
            '0000000'                         segment10                                                      
            ,
            decode(sign(stat_value),
                   1,
                   stat_value,
                   0)                         entered_dr                          
                   ,
            decode(sign(stat_value),
                   - 1,
                   abs(stat_value),
                   0)                         entered_cr                   
                   ,
            accounting_period,
            'N'                               process_flag,
            g_instance_id                     interface_group_id,
            xxgenai_gl_cda_record_id_s1.NEXTVAL record_id,
            oic_instance_id                   source_instance_id
        FROM
            xxgenai_gl_cda_summary xgc
        WHERE
                1 = 1
            AND status = g_new
            AND accounting_period = nvl(g_period, accounting_period)
            AND ledger_id = nvl(g_ledger_id, ledger_id);

        TYPE cda_gl_interface_type IS
            TABLE OF c_insert_gl_interface%rowtype INDEX BY BINARY_INTEGER;
        cda_gl_table  cda_gl_interface_type;
    BEGIN
        x_no_record := 0;
        BEGIN
            SELECT
                upper(xgc.period)
            INTO g_period
            FROM
                xxgenai_gl_cda_lh_int    xgc,
                xxgenai_gl_sipp_cost_stg xgsc
            WHERE
                    1 = 1
                AND xgsc.sipp_code = xgc.sipp_code
                AND upper(xgsc.period) = upper(xgc.period)
                AND xgc.batcherror = g_validated
                AND xgsc.batch_status = g_validated
            GROUP BY
                xgc.period;

        EXCEPTION
            WHEN no_data_found THEN
                g_errbuff := g_errbuff || 'No Period Value in the Upstream interface table';
                g_retcode := g_retcode_error;
        END;

        BEGIN
            SELECT
                COUNT(*)
            INTO x_no_record
            FROM
                xxgenai_gl_cda_summary xgc
            WHERE
                    1 = 1
                AND status = g_new
                AND accounting_period = nvl(g_period, accounting_period)
                AND ledger_id = nvl(g_ledger_id, ledger_id);
          EXCEPTION
            WHEN no_data_found THEN
                g_errbuff := g_errbuff || 'No valid data in the CDA Summary table with status as New';
                g_retcode := g_retcode_error;      
        END;

        IF x_no_record > 0 THEN
            OPEN c_insert_gl_interface;
            LOOP
                FETCH c_insert_gl_interface
                BULK COLLECT INTO cda_gl_table LIMIT x_array_size;    

        dbms_output.put_line('Populate GL Interface table with the CDA summary data');
                dbms_output.put_line('Cursor Data Count' || cda_gl_table.count);
         FORALL i IN 1..cda_gl_table.count
                    INSERT INTO xxgenai_gl_interface (
                        status,
                        ledger_id,
                        user_je_source_name,
                        user_je_category_name,
                        accounting_date,
                        currency_code,
                        date_created,
                        oic_instance_id,
                        creation_date,
                        created_by,
                        last_update_date,
                        last_updated_by,
                        actual_flag,
                        segment1,
                        segment2,
                        segment3,
                        segment4,
                        segment5,
                        segment6,
                        segment7,
                        segment8,
                        segment9,
                        segment10,
                        entered_dr,
                        entered_cr,
                        period_name,
                        process_flag,
                        interface_group_id,
                        record_id,
                        source_instance_id
                    ) VALUES (
                        cda_gl_table(i).status,
                        cda_gl_table(i).ledger_id,
                        cda_gl_table(i).user_je_source_name,
                        cda_gl_table(i).user_je_category_name,
                        cda_gl_table(i).accounting_date,
                        cda_gl_table(i).currency_code,
                        cda_gl_table(i).date_created,
                        cda_gl_table(i).oic_instance_id,
                        cda_gl_table(i).creation_date,
                        cda_gl_table(i).created_by,
                        cda_gl_table(i).last_update_date,
                        cda_gl_table(i).last_updated_by,
                        cda_gl_table(i).actual_flag,
                        cda_gl_table(i).legal_entity,
                        cda_gl_table(i).brand,
                        cda_gl_table(i).attribute8,
                        cda_gl_table(i).segment4,
                        cda_gl_table(i).segment5,
                        cda_gl_table(i).segment6,
                        cda_gl_table(i).segment7,
                        cda_gl_table(i).product,
                        cda_gl_table(i).segment9,
                        cda_gl_table(i).segment10,
                        cda_gl_table(i).entered_dr,
                        cda_gl_table(i).entered_cr,
                        cda_gl_table(i).accounting_period,
                        cda_gl_table(i).process_flag,
                        cda_gl_table(i).interface_group_id,
                        cda_gl_table(i).record_id,
                        cda_gl_table(i).source_instance_id
                    );

                COMMIT;
            EXIT WHEN c_insert_gl_interface%notfound;
            END LOOP;

            CLOSE c_insert_gl_interface;
        END IF;

        IF x_no_record = 0 THEN
            g_errbuff := ' Records inserted into GL Interface table because CDA Summary table is empty';
            g_retcode := g_retcode_error;
            UPDATE xxgenai_gl_cda_detail
            SET
                status = 'ERROR',
                error_message = g_errbuff,
                last_update_date = sysdate,
                last_updated_by = g_user_id
            WHERE
                    1 = 1
                AND accounting_period = g_period
                AND status = g_in_process
                AND ledger_id = nvl(g_ledger_id, ledger_id);

            UPDATE xxgenai_gl_cda_summary
            SET
                status = 'ERROR',
                error_message = g_errbuff,
                last_update_date = sysdate,
                last_updated_by = g_user_id
            WHERE
                    1 = 1
                AND accounting_period = g_period
                AND status = g_new
                AND ledger_id = nvl(g_ledger_id, ledger_id);

            UPDATE xxgenai_gl_cda_lh_int
            SET
                batcherror = g_validated,
                last_update_date = sysdate,
                last_updated_by = g_user_id
            WHERE
                    1 = 1
                AND batcherror = g_in_process
                AND upper(period) = g_period
                AND legal_entity IN (
                    SELECT
                        gle.flex_segment_value
                    FROM
                        xxgenai_gl_legal_entities_bsvs gle, xxgenai_business_units         hou
                    WHERE
                            1 = 1
                        AND gle.legal_entity_id = hou.default_legal_context_id
                        AND hou.set_of_books_id = nvl(g_ledger_id, hou.set_of_books_id)
                        AND gle.flex_segment_value = legal_entity
                    GROUP BY
                        gle.flex_segment_value
                );

            UPDATE xxgenai_gl_sipp_cost_stg
            SET
                batch_status = g_v,
                last_update_date = sysdate,
                last_updated_by = g_user_id
            WHERE
                    1 = 1
                AND batch_status = g_in_process
                AND upper(period) = g_period
                AND region IN (
                    SELECT
                        flv.lookup_code
                    FROM
                        xxgenai_fah_fnd_lookup_values flv
                    WHERE
                            1 = 1
                        AND flv.lookup_code = region
                        AND flv.description = nvl(to_char(g_ledger_id),
                                                  flv.description)
                        AND flv.enabled_flag = g_enabled_flag
                );

        END IF;

        COMMIT;
        EXCEPTION
        WHEN OTHERS THEN
            g_errbuff := 'Unexpected error in procedure - INSERT_XXgenai_GL_INTERFACE for inserting data into GL Interaface table - '
                         || substr(sqlerrm, 1, 300);
            g_retcode := g_retcode_error;

         UPDATE xxgenai_gl_cda_detail
            SET
                status = 'ERROR',
                error_message = g_errbuff,
                last_update_date = sysdate,
                last_updated_by = g_user_id
            WHERE
                    1 = 1
                AND accounting_period = g_period
                AND status = g_in_process
                AND ledger_id = nvl(g_ledger_id, ledger_id);

            UPDATE xxgenai_gl_cda_summary
            SET
                status = 'ERROR',
                error_message = g_errbuff,
                last_update_date = sysdate,
                last_updated_by = g_user_id
            WHERE
                    1 = 1
                AND ledger_id = nvl(g_ledger_id, ledger_id)
                AND status = g_new
                AND accounting_period = g_period;

            UPDATE xxgenai_gl_cda_lh_int
            SET
                batcherror = g_validated,
                last_update_date = sysdate,
                last_updated_by = g_user_id
            WHERE
                    1 = 1
                AND batcherror = g_in_process
                AND upper(period) = g_period
                AND legal_entity IN (
                    SELECT
                        gle.flex_segment_value
                    FROM
                        xxgenai_gl_legal_entities_bsvs gle, xxgenai_business_units         hou
                    WHERE
                            1 = 1
                        AND gle.legal_entity_id = hou.default_legal_context_id
                        AND hou.set_of_books_id = nvl(g_ledger_id, hou.set_of_books_id)
                        AND gle.flex_segment_value = legal_entity
                    GROUP BY
                        gle.flex_segment_value
                );

            UPDATE xxgenai_gl_sipp_cost_stg
            SET
                batch_status = g_v,
                last_update_date = sysdate,
                last_updated_by = g_user_id
            WHERE
                    1 = 1
                AND batch_status = g_in_process
                AND upper(period) = g_period
                AND region IN (
                    SELECT
                        flv.lookup_code
                    FROM
                        xxgenai_fah_fnd_lookup_values flv
                    WHERE
                            1 = 1
                        AND flv.lookup_code = region
                        AND flv.description = nvl(to_char(g_ledger_id),
                                                  flv.description)
                        AND flv.enabled_flag = g_enabled_flag
                        );

            COMMIT;
    END insert_xxgenai_gl_interface;

 PROCEDURE reset_val_mode (
        p_ledger_id       IN NUMBER,
        p_oic_instance_id IN NUMBER
        ,
        p_created_by      IN VARCHAR2,
        g_errbuff         OUT VARCHAR2,
        g_retcode         OUT VARCHAR2
    ) IS

        x_det_cnt   NUMBER := 0;
        x_summ_cnt  NUMBER := 0;
        g_ledger_id NUMBER := p_ledger_id;
        g_user_id   VARCHAR2(120) := p_created_by;
    BEGIN
    dbms_output.put_line('Verify if there are any unprocessed data in CDA Detail and CDA Summary table');
        SELECT
            upper(xgc.period)
        INTO g_period
        FROM
            xxgenai_gl_cda_lh_int    xgc,
            xxgenai_gl_sipp_cost_stg xgsc
        WHERE
                1 = 1
            AND xgsc.sipp_code = xgc.sipp_code
            AND upper(xgsc.period) = upper(xgc.period)
            AND xgc.batcherror = g_validated
            AND xgsc.batch_status = g_validated
        GROUP BY
            xgc.period;

        SELECT
            COUNT(1)
        INTO x_det_cnt
        FROM
            xxgenai_gl_cda_detail
        WHERE
                1 = 1
            AND status IN ( 'IN_PROCESS', 'ERROR' )
            AND accounting_period = nvl(g_period, accounting_period)
            AND ledger_id = nvl(g_ledger_id, ledger_id);

        SELECT
            COUNT(1)
        INTO x_summ_cnt
        FROM
            xxgenai_gl_cda_summary
        WHERE
                1 = 1
            AND status = g_new
            AND accounting_period = nvl(g_period, accounting_period)
            AND ledger_id = nvl(g_ledger_id, ledger_id);

        IF x_det_cnt >= 1 OR x_summ_cnt >= 1 THEN
         dbms_output.put_line('Clears CDA Detail and CDA Summary data');
            DELETE FROM xxgenai_gl_cda_detail
            WHERE
                    1 = 1
                AND status IN ( 'IN_PROCESS', 'ERROR' )
                AND accounting_period = nvl(g_period, accounting_period)
                AND ledger_id = nvl(g_ledger_id, ledger_id);

            dbms_output.put_line(SQL%rowcount || ' records cleared from CDA Detail table');
            DELETE FROM xxgenai_gl_cda_summary
            WHERE
                    1 = 1
                AND status = g_new
                AND accounting_period = nvl(g_period, accounting_period)
                AND ledger_id = nvl(g_ledger_id, ledger_id);

            dbms_output.put_line(SQL%rowcount || ' records cleared from CDA Summary table');
            UPDATE xxgenai_gl_cda_lh_int
            SET
                batcherror = g_validated,
                last_update_date = sysdate,
                last_updated_by = g_user_id
            WHERE
                    1 = 1
                AND batcherror = g_in_process
                AND upper(period) = upper(nvl(g_period, period))
                AND legal_entity IN (
                    SELECT
                        gle.flex_segment_value
                    FROM
                        xxgenai_gl_legal_entities_bsvs gle, xxgenai_business_units         hou
                    WHERE
                            1 = 1
                        AND gle.legal_entity_id = hou.default_legal_context_id
                        AND hou.set_of_books_id = nvl(g_ledger_id, hou.set_of_books_id)
                        AND gle.flex_segment_value = legal_entity
                    GROUP BY
                        gle.flex_segment_value
                );

            dbms_output.put_line(SQL%rowcount || ' records updated back to VALIDATED status in GL_INT_398 table');
            UPDATE xxgenai_gl_sipp_cost_stg
            SET
                batch_status = g_v,
                last_update_date = sysdate,
                last_updated_by = g_user_id
            WHERE
                    1 = 1
                AND batch_status = g_in_process
                AND upper(period) = upper(nvl(g_period, period))
                AND region IN (
                    SELECT
                        flv.lookup_code
                    FROM
                        xxgenai_fah_fnd_lookup_values flv
                    WHERE
                            1 = 1
                        AND flv.lookup_code = region
                        AND flv.description = nvl(to_char(g_ledger_id),
                                                  flv.description)
                        AND flv.enabled_flag = g_enabled_flag
                       );

            dbms_output.put_line(SQL%rowcount || ' records updated back to VALIDATED status in INT_400 table');
        ELSE
            dbms_output.put_line('No data is pending processing in CDA Detail and CDA Summary tables in reset mode');
        END IF;

        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
            g_errbuff := 'Unexpected error in procedure - reset_val_mode - '
                         || substr(sqlerrm, 1, 300);
            g_retcode := g_retcode_error;

      UPDATE xxgenai_gl_cda_detail
            SET
                status = 'ERROR',
                error_message = g_errbuff,
                last_update_date = sysdate,
                last_updated_by = g_user_id
            WHERE
                    1 = 1
                AND accounting_period = nvl(g_period, accounting_period)
                AND status = g_in_process
                AND ledger_id = nvl(g_ledger_id, ledger_id);

            UPDATE xxgenai_gl_cda_summary
            SET
                status = 'ERROR',
                error_message = g_errbuff,
                last_update_date = sysdate,
                last_updated_by = g_user_id
            WHERE
                    1 = 1
                AND ledger_id = nvl(g_ledger_id, ledger_id)
                AND status = g_new
                AND accounting_period = nvl(g_period, accounting_period);

            UPDATE xxgenai_gl_cda_lh_int
            SET
                batcherror = g_validated,
                last_update_date = sysdate,
                last_updated_by = g_user_id
            WHERE
                    1 = 1
                AND batcherror = g_in_process
                AND upper(period) = upper(nvl(g_period,period))
                AND legal_entity IN (
                    SELECT
                        gle.flex_segment_value
                    FROM
                        xxgenai_gl_legal_entities_bsvs gle, xxgenai_business_units         hou
                    WHERE
                            1 = 1
                        AND gle.legal_entity_id = hou.default_legal_context_id
                        AND hou.set_of_books_id = nvl(g_ledger_id, hou.set_of_books_id)
                        AND gle.flex_segment_value = legal_entity
                    GROUP BY
                        gle.flex_segment_value
                );

            UPDATE xxgenai_gl_sipp_cost_stg
            SET
                batch_status = g_v,
                last_update_date = sysdate,
                last_updated_by = g_user_id
            WHERE
                    1 = 1
                AND batch_status = g_in_process
                AND upper(period) = upper(nvl(g_period,period))
                AND region IN (
                    SELECT
                        flv.lookup_code
                    FROM
                        xxgenai_fah_fnd_lookup_values flv
                    WHERE
                            1 = 1
                        AND flv.lookup_code = region
                        AND flv.description = nvl(to_char(g_ledger_id),
                                                  flv.description)
                        AND flv.enabled_flag = g_enabled_flag
                        );

            COMMIT;
    END reset_val_mode;

   PROCEDURE update_status (
        p_err_detail_type IN x_err_detail_type,
        p_process_flag    IN VARCHAR2,
        p_failed_status   IN VARCHAR2,
        p_last_updated_by IN VARCHAR2,
        p_group_id        IN VARCHAR2,
        p_total_rec_count OUT NUMBER,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    ) IS

        x_array_size          NUMBER := 10000;
        CURSOR c_sipp_cost_update_recs IS
        SELECT
            gscs.sipp_code,
            gscs.period,
            gscs.region,
            gscs.cost,
            gcd.status,
            gcd.journal_batch,
            gscs.oic_instance_id, 
            gcd.last_updated_by
        FROM
            xxgenai_gl_cda_detail    gcd,
            xxgenai_gl_sipp_cost_stg gscs
        WHERE
                1 = 1
            AND gcd.status IN ( 'PROCESSED', 'ERROR' )
            AND gscs.batch_status = 'VALIDATED'
            AND gcd.accounting_period = upper(gscs.period)
            AND gcd.sipp_code = gscs.sipp_code
            AND gcd.oic_instance_id = gscs.source_instance_id  
        GROUP BY
            gscs.sipp_code,
            gscs.period,
            gscs.region,
            gscs.cost,
            gcd.status,
            gcd.journal_batch,
            gscs.oic_instance_id,   
            gcd.last_updated_by;

        CURSOR c_lh_int_update_recs IS
        SELECT
            gli.legal_entity,
            gli.location_id,
            gli.sipp_code,
            gli.car_days,
            gcd.status,
            gcd.journal_batch,
            gli.oic_instance_id,  
            gcd.last_updated_by
        FROM
            xxgenai_gl_cda_detail gcd,
            xxgenai_gl_cda_lh_int gli
        WHERE
                1 = 1
            AND gcd.status IN ( 'PROCESSED', 'ERROR' )
            AND gli.batcherror = 'VALIDATED'
            AND gcd.accounting_period = upper(gli.period)
            AND gcd.legal_entity = gli.legal_entity
            AND gcd.location_unique_id = gli.location_id
            AND gcd.car_days = gli.car_days
            AND gcd.sipp_code = gli.sipp_code
            AND gcd.oic_instance_id = gli.source_instance_id  
        GROUP BY
            gli.legal_entity,
            gli.location_id,
            gli.sipp_code,
            gli.car_days,
            gcd.status,
            gcd.journal_batch,
            gli.oic_instance_id,  
            gcd.last_updated_by;

        TYPE t_lh_int_update_tab IS
            TABLE OF c_lh_int_update_recs%rowtype INDEX BY BINARY_INTEGER;
        lh_int_update         t_lh_int_update_tab;
        TYPE t_sipp_cost_update_tab IS
            TABLE OF c_sipp_cost_update_recs%rowtype INDEX BY BINARY_INTEGER;
        sipp_cost_update      t_sipp_cost_update_tab;
        x_err_detail_rec_type x_err_detail_type;
        x_counter             NUMBER;
        l_err_rec_cnt         NUMBER;
        x_process_flag        VARCHAR2(20);
        TYPE x_stg_err_det_rec_type IS RECORD (
            import_status xxgenai_gl_interface.import_status%TYPE,
            error_message xxgenai_gl_interface.error_message%TYPE,
            je_batch_id   xxgenai_gl_interface.je_batch_id%TYPE,
            ledger_id     xxgenai_gl_interface.ledger_id%TYPE
        );
        TYPE x_stg_err_det_table IS
            TABLE OF x_stg_err_det_rec_type;
        x_stg_err_det_rec     x_stg_err_det_table := x_stg_err_det_table();
     TYPE gl_interface_tab_t IS
            TABLE OF xxgenai_gl_interface%rowtype INDEX BY BINARY_INTEGER;
        gl_interface_update   gl_interface_tab_t;
      BEGIN
        x_err_detail_rec_type := p_err_detail_type;
        l_err_rec_cnt := p_err_detail_type.count;
        x_counter := 0;
        x_process_flag := '';
        SELECT
            COUNT(1)
        INTO p_total_rec_count
        FROM
            xxgenai_gl_interface
        WHERE
            interface_group_id = p_group_id;
			IF l_err_rec_cnt > 0 THEN
          x_process_flag := p_process_flag;
            FOR i IN x_err_detail_rec_type.first..x_err_detail_rec_type.last LOOP
          x_counter := x_counter + 1;
                x_stg_err_det_rec.extend;
                x_stg_err_det_rec(x_counter).import_status := x_err_detail_rec_type(i).rec_status;
                x_stg_err_det_rec(x_counter).error_message := nvl(x_err_detail_rec_type(i).error_message, '');

                x_stg_err_det_rec(x_counter).je_batch_id := x_err_detail_rec_type(i).je_batch_id;
                x_stg_err_det_rec(x_counter).ledger_id := x_err_detail_rec_type(i).ledger_id;
            END LOOP;     
          IF x_stg_err_det_rec(x_counter).import_status = 'SUCCESS' THEN
                gl_interface_update(x_counter).je_batch_id := x_stg_err_det_rec(x_counter).je_batch_id;
                gl_interface_update(x_counter).status := 'PROCESSED';
                gl_interface_update(x_counter).ledger_id := x_stg_err_det_rec(x_counter).ledger_id;
                gl_interface_update(x_counter).process_flag := x_process_flag;
                gl_interface_update(x_counter).error_code := 'IMPORTED';
                gl_interface_update(x_counter).interface_group_id := p_group_id;
                gl_interface_update(x_counter).import_status := 'SUCCESS';
                gl_interface_update(x_counter).last_updated_by := p_last_updated_by;
            ELSE
                gl_interface_update(x_counter).status := 'ERROR';
                gl_interface_update(x_counter).ledger_id := x_stg_err_det_rec(x_counter).ledger_id;
                gl_interface_update(x_counter).process_flag := p_failed_status;
                gl_interface_update(x_counter).error_code := 'FAILED';
                gl_interface_update(x_counter).interface_group_id := p_group_id;
                gl_interface_update(x_counter).error_message := x_stg_err_det_rec(x_counter).error_message;
                gl_interface_update(x_counter).import_status := 'ERROR';
                gl_interface_update(x_counter).last_updated_by := p_last_updated_by;
            END IF;

            FOR i IN gl_interface_update.first..gl_interface_update.last LOOP
                UPDATE xxgenai_gl_interface
                SET
                    process_flag = gl_interface_update(i).process_flag,
                    error_code = gl_interface_update(i).error_code,
                    je_batch_id = gl_interface_update(i).je_batch_id,
                    status = gl_interface_update(i).status,
                    error_message = gl_interface_update(i).error_message,
                    import_status = gl_interface_update(i).import_status,
                    last_updated_by = gl_interface_update(x_counter).last_updated_by
                WHERE
                        interface_group_id = p_group_id
                    AND ledger_id = gl_interface_update(x_counter).ledger_id;

            END LOOP;

            FORALL i IN gl_interface_update.first..gl_interface_update.last
                UPDATE xxgenai_gl_cda_summary
                SET
                    journal_batch = gl_interface_update(i).je_batch_id,
                    status = gl_interface_update(i).status,
                    last_updated_by = gl_interface_update(x_counter).last_updated_by
                WHERE
                        1 = 1
                    AND status = 'NEW'
                    AND ledger_id = gl_interface_update(x_counter).ledger_id;

            COMMIT;
            FORALL i IN gl_interface_update.first..gl_interface_update.last
                UPDATE xxgenai_gl_cda_detail
                SET
                    journal_batch = gl_interface_update(i).je_batch_id,
                    status = gl_interface_update(i).status,
                    last_updated_by = gl_interface_update(x_counter).last_updated_by
                WHERE
                        1 = 1
                    AND status = 'IN_PROCESS'
                    AND ledger_id = gl_interface_update(x_counter).ledger_id;

            COMMIT;
            OPEN c_sipp_cost_update_recs;
            LOOP
                FETCH c_sipp_cost_update_recs
                BULK COLLECT INTO sipp_cost_update LIMIT x_array_size;
                IF sipp_cost_update.count > 0 THEN
            FOR i IN sipp_cost_update.first..sipp_cost_update.last LOOP
                        UPDATE xxgenai_gl_sipp_cost_stg
                        SET
                            batch_status = sipp_cost_update(i).status,
                            je_batch_id = sipp_cost_update(i).journal_batch,
                            last_updated_by = sipp_cost_update(i).last_updated_by
                        WHERE
                                1 = 1
                            AND sipp_code = sipp_cost_update(i).sipp_code
                            AND region = sipp_cost_update(i).region
                            AND cost = sipp_cost_update(i).cost
                            AND oic_instance_id = sipp_cost_update(i).oic_instance_id;

                    END LOOP;

                END IF;

                EXIT WHEN c_sipp_cost_update_recs%notfound;
            END LOOP;

            CLOSE c_sipp_cost_update_recs;
            COMMIT;
            
            OPEN c_lh_int_update_recs;
            LOOP
                FETCH c_lh_int_update_recs
                BULK COLLECT INTO lh_int_update LIMIT x_array_size;
                IF lh_int_update.count > 0 THEN
                    FOR i IN lh_int_update.first..lh_int_update.last LOOP
                        UPDATE xxgenai_gl_cda_lh_int
                        SET
                            batcherror = lh_int_update(i).status,
                            je_batch_id = lh_int_update(i).journal_batch,
                            last_updated_by = lh_int_update(i).last_updated_by
                        WHERE
                                1 = 1
                            AND legal_entity = lh_int_update(i).legal_entity
                            AND location_id = lh_int_update(i).location_id
                            AND sipp_code = lh_int_update(i).sipp_code
                            AND car_days = lh_int_update(i).car_days
                            AND oic_instance_id = lh_int_update(i).oic_instance_id;

                    END LOOP;

                END IF;

                EXIT WHEN c_lh_int_update_recs%notfound;
            END LOOP;

            CLOSE c_lh_int_update_recs;
            COMMIT;
        END IF;

        COMMIT;
        p_status_out := 'S';
    EXCEPTION
        WHEN OTHERS THEN
            p_status_out := 'E';
            p_err_msg_out := sqlerrm;
    END update_status;

   PROCEDURE batch_creation (
        p_instance_id IN VARCHAR2,
        p_status_out  OUT VARCHAR2,
        p_err_msg_out OUT VARCHAR2
    ) IS

        CURSOR cur_batching IS
        SELECT
            record_id
        FROM
            genai_custom.xxgenai_gl_interface
        WHERE
                oic_instance_id = p_instance_id
          AND process_flag = 'N';

        TYPE tbl_type_batching IS
            TABLE OF cur_batching%rowtype INDEX BY BINARY_INTEGER;
        tbl_batching   tbl_type_batching;
        v_batch_number NUMBER;
        BEGIN
        v_batch_number := 1;
        OPEN cur_batching;
        LOOP
            FETCH cur_batching
            BULK COLLECT INTO tbl_batching LIMIT 10000;
            FORALL i IN tbl_batching.first..tbl_batching.last
                UPDATE genai_custom.xxgenai_gl_interface
                SET
                    batch_id = v_batch_number
                WHERE
                    record_id = tbl_batching(i).record_id;

            EXIT WHEN cur_batching%notfound;
            v_batch_number := v_batch_number + 1;
        END LOOP;

        CLOSE cur_batching;
        COMMIT;
        p_status_out := 'S';
    EXCEPTION
        WHEN OTHERS THEN
            p_status_out := 'E';
            p_err_msg_out := sqlerrm;
    END batch_creation;
  PROCEDURE assign_batch (
        p_instance_id IN VARCHAR2,
        p_status_out  OUT VARCHAR2,
        p_err_msg_out OUT VARCHAR2
    ) IS

        CURSOR cur_batching IS
        SELECT
            record_id
        FROM
            genai_custom.xxgenai_gl_cda_detail
        WHERE
                oic_instance_id = p_instance_id
          AND status = 'NEW';

        TYPE tbl_type_batching IS
            TABLE OF cur_batching%rowtype INDEX BY BINARY_INTEGER;
        tbl_batching   tbl_type_batching;
        v_batch_number NUMBER;
       BEGIN
        dbms_output.put_line(' At Start: ' || current_timestamp);
        v_batch_number := 1;
        OPEN cur_batching;
        LOOP
            FETCH cur_batching
            BULK COLLECT INTO tbl_batching LIMIT 10000;
            dbms_output.put_line(' tbl_batching.count: ' || tbl_batching.count);
            FORALL i IN tbl_batching.first..tbl_batching.last
                UPDATE genai_custom.xxgenai_gl_cda_detail
                SET
                    batch_id = v_batch_number
                WHERE
                    record_id = tbl_batching(i).record_id;

            EXIT WHEN cur_batching%notfound;
            v_batch_number := v_batch_number + 1;
        END LOOP;

        dbms_output.put_line(' At End: ' || current_timestamp);
        CLOSE cur_batching;
        COMMIT;
        p_status_out := 'S';
    EXCEPTION
        WHEN OTHERS THEN
            p_status_out := 'E';
            p_err_msg_out := sqlerrm;
    END assign_batch;

END xxgenai_gl_cda_ext_pkg;