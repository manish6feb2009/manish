create or replace PACKAGE BODY xxgenai_gl_cda_lh_int_pkg AS
	g_array_size_num CONSTANT NUMBER := 10000;

    PROCEDURE assign_batchid (
        p_oic_instance_id IN NUMBER,
        p_file_name       IN VARCHAR2,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    ) AS

        x_batch_size NUMBER := 2000;
        x_count      NUMBER;
        x_from_seq   NUMBER := 0;
        x_to_seq     NUMBER := 0;
        x_batch_id   NUMBER;
    BEGIN
        SELECT
            MIN(record_id)
        INTO x_from_seq
        FROM
            xxgenai_gl_cda_lh_int
        WHERE
            oic_instance_id = p_oic_instance_id;

        SELECT
            MAX(record_id)
        INTO x_to_seq
        FROM
            xxgenai_gl_cda_lh_int
        WHERE
            oic_instance_id = p_oic_instance_id;

        WHILE x_from_seq <= x_to_seq LOOP
            x_batch_id := XXgenai_GL_CDA_UPDATE_TBL_SEQ1.nextval;
            FOR i IN 1..x_batch_size LOOP
                UPDATE xxgenai_gl_cda_lh_int
                SET
                    batch_id = x_batch_id
                WHERE
                        record_id = x_from_seq
                    AND oic_instance_id = p_oic_instance_id
                    AND file_name = p_file_name;

                x_from_seq := x_from_seq + 1;
                EXIT WHEN x_from_seq > x_to_seq;
            END LOOP;

        END LOOP;

        COMMIT;
        p_status_out := 'S';
    EXCEPTION
        WHEN OTHERS THEN
            p_status_out := 'E';
            p_err_msg_out := sqlerrm;
    END assign_batchid;

    PROCEDURE purge_rec_proc (
        p_oic_instance_id IN NUMBER,
        p_validated_flag  IN VARCHAR2 
        ,
        p_error_flag      IN VARCHAR2 
        ,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    ) IS

        x_validated_flag VARCHAR2(20) := p_validated_flag;
        x_error_flag     VARCHAR2(20) := p_error_flag;
        x_err_stat       VARCHAR2(1) := 'E';
        x_suc_stat       VARCHAR2(1) := 'S';
    BEGIN
        DELETE FROM xxgenai_gl_cda_lh_int stg
        WHERE
                1 = 1
            AND batcherror IN ( x_validated_flag, x_error_flag )
            AND oic_instance_id != p_oic_instance_id
            p_status_out := x_suc_stat;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            p_status_out := x_err_stat;
            UPDATE xxgenai_gl_cda_lh_int
            SET
                load_status = 'E'
            WHERE
                oic_instance_id = p_oic_instance_id;

            p_err_msg_out := sqlerrm;
    END purge_rec_proc;

    PROCEDURE update_status_proc (
        p_oic_instance_id  IN NUMBER,
        p_intial_flag      IN VARCHAR2,
        p_validated_flag   IN VARCHAR2,
        p_last_updated_by  IN VARCHAR2,
        p_last_update_date IN DATE,
        p_status_out       OUT VARCHAR2,
        p_err_msg_out      OUT VARCHAR2
    ) IS

        x_initial_flag VARCHAR2(1) := p_intial_flag;
        x_err_stat     VARCHAR2(1) := 'E';
        x_suc_stat     VARCHAR2(1) := 'S';
    BEGIN
        UPDATE xxgenai_gl_cda_lh_int stg
        SET
            load_status = x_initial_flag,
            batcherror = NULL,
            lineerror = NULL,
            legal_entity = NULL,
            oic_instance_id = p_oic_instance_id,
            last_updated_by = p_last_updated_by,
            last_update_date = p_last_update_date
        WHERE
                1 = 1
            AND oic_instance_id <> p_oic_instance_id
            AND batcherror <> p_validated_flag
            AND period_flag = 'Y';

        p_status_out := x_suc_stat;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_status_out := x_err_stat;
            p_err_msg_out := sqlerrm;
    END update_status_proc;

    PROCEDURE populate_ledger_id (
        p_oic_instance_id IN NUMBER,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    ) IS

        x_err_stat           VARCHAR2(1) := 'E';
        x_suc_stat           VARCHAR2(1) := 'S';
        x_ledgerid           VARCHAR2(100) := NULL;
        x_error_legal_entity VARCHAR2(10) := NULL;
        CURSOR c_ledger IS
        SELECT
            legal_entity
        FROM
            xxgenai_gl_cda_lh_int
        WHERE
            oic_instance_id = p_oic_instance_id
        GROUP BY
            legal_entity;

    BEGIN
        FOR rec_cur_ledger IN c_ledger LOOP
            x_ledgerid := NULL;
            SELECT
                gl.ledger_id
            INTO x_ledgerid
            FROM
                xxgenai_gl_ledgers gl
            WHERE
                    1 = 1
                AND EXISTS (
                    SELECT
                        1
                    FROM
                        xxgenai_business_units      hou,
                        xxgenai_xle_entity_profiles xe
                    WHERE
                            1 = 1
                        AND xe.legal_entity_id = hou.default_legal_context_id
                        AND gl.ledger_id = hou.set_of_books_id
                        AND EXISTS (
                            SELECT
                                1
                            FROM
                                xxgenai_gl_legal_entities_bsvs gle
                            WHERE
                                    1 = 1
                                AND gle.flex_segment_value = rec_cur_ledger.legal_entity
                                AND gle.legal_entity_id = xe.legal_entity_id
                        )
                )
            GROUP BY
                ledger_id;

            IF x_ledgerid IS NOT NULL THEN
                UPDATE xxgenai_gl_cda_lh_int
                SET
                    ledger_id = x_ledgerid
                WHERE
                        oic_instance_id = p_oic_instance_id
                    AND load_status = 'N'
                    AND legal_entity = rec_cur_ledger.legal_entity;

            ELSE
                p_err_msg_out := 'Unable to derive ledger ID';
                p_status_out := x_err_stat;
            END IF;

            x_error_legal_entity := rec_cur_ledger.legal_entity;
        END LOOP;

        COMMIT;
    EXCEPTION
        WHEN no_data_found THEN
            UPDATE xxgenai_gl_cda_lh_int
            SET
                load_status = 'E',
                lineerror = 'ERROR',
                batcherror = 'ERROR',
                error_message = 'Incorrect legal_entity'
            WHERE
                    oic_instance_id = p_oic_instance_id
                AND legal_entity = x_error_legal_entity;

            p_status_out := x_err_stat;
        WHEN OTHERS THEN
            p_status_out := x_err_stat;
            p_err_msg_out := p_err_msg_out || sqlerrm;
    END populate_ledger_id;

    PROCEDURE validate_records_proc (
        p_oic_instance_id  IN NUMBER,
        p_batchid          IN NUMBER,
        p_intial_flag      IN VARCHAR2,
        p_validated_flag   IN VARCHAR2,
        p_error_flag       IN VARCHAR2,
        p_last_updated_by  IN VARCHAR2,
        p_last_update_date IN DATE,
        p_status_out       OUT VARCHAR2,
        p_err_msg_out      OUT VARCHAR2,
        p_flag_valid       IN VARCHAR2,
        p_flag_err         IN VARCHAR2,
        p_filename         IN VARCHAR2
    ) IS

        x_filename            VARCHAR2(100) := p_filename;
        x_batchid             NUMBER := p_batchid;
        x_initial_flag        VARCHAR2(1) := p_intial_flag;
        x_err_stat            VARCHAR2(1) := 'E';
        x_suc_stat            VARCHAR2(1) := 'S';
		CURSOR c_duplicate IS
        SELECT
            COUNT(*),period,legal_entity,location_id,sipp_code

        FROM
            xxgenai_gl_cda_lh_int stg
        WHERE
            stg.oic_instance_id = p_oic_instance_id
            
		GROUP BY
            period,legal_entity,location_id,sipp_code
        HAVING
            COUNT(*) > 1;

        TYPE c_duplicate_type IS
            TABLE OF c_duplicate%rowtype INDEX BY BINARY_INTEGER;
        v_duplicate c_duplicate_type;

        CURSOR c_cda_trx IS
        SELECT
            period,
            legal_entity,
            ledger_id,
            period_flag,
            location_id,
            sipp_code,
            car_days,
            lineerror,
            batcherror,
            error_message,
            load_status,
            record_id,
            attribute1,
            attribute16,
            cloud_period_name,
            count_gl_je_headers
        FROM
            xxgenai_gl_cda_lh_int
        WHERE
                1 = 1
            AND oic_instance_id = p_oic_instance_id
            AND batch_id = x_batchid
            AND file_name = x_filename;

        TYPE x_cda_trx_table_type IS
            TABLE OF c_cda_trx%rowtype INDEX BY BINARY_INTEGER;
        x_cda_trx_table       x_cda_trx_table_type;
        x_batch_err_flag      VARCHAR2(10) := NULL;
        x_line_err_flag       VARCHAR2(20) := NULL;
        x_err_msg             VARCHAR2(2000) := NULL;
        x_period_name         VARCHAR2(15) := NULL;
        x_sipp_code           VARCHAR2(10) := NULL;
        x_batch_error         VARCHAR2(15) := NULL;
        x_batch_status        VARCHAR2(15) := NULL;
        x_duplicate_rec       NUMBER := 0;
        x_legal_entity_id     NUMBER := 0;
        x_location_id         NUMBER := 0;
        x_ledger_id           NUMBER := 0;
        x_rec_count           NUMBER default NULL;
        x_process_rec         NUMBER := 0;
        x_reverse_journal_cnt NUMBER := 0;
        x_count_sipp          NUMBER := 0;
        x_legal_entity        VARCHAR2(100) := NULL;
        x_valid_location_id   VARCHAR2(100) := NULL;
        x_valid_legal_entity  VARCHAR2(100) := NULL;
    BEGIN
        x_batch_error := p_validated_flag;
        x_batch_status := p_flag_valid;
        OPEN c_cda_trx;
        LOOP
            FETCH c_cda_trx
            BULK COLLECT INTO x_cda_trx_table LIMIT g_array_size_num;
            IF x_cda_trx_table.count > 0 THEN
                x_rec_count := x_cda_trx_table.count;
                FOR indx IN 1..x_cda_trx_table.count LOOP
                    BEGIN
                        x_cda_trx_table(indx).load_status := p_flag_valid;
                        x_cda_trx_table(indx).lineerror := p_validated_flag;
                        x_cda_trx_table(indx).error_message := NULL;
                        x_err_msg := NULL;
                        BEGIN
                            x_ledger_id := x_cda_trx_table(indx).ledger_id;
                        EXCEPTION
                            WHEN no_data_found THEN
                                x_err_msg := x_err_msg || 'Unexpected Error while updating IC Lessee; ';
                                x_cda_trx_table(indx).lineerror := p_error_flag;
                            WHEN OTHERS THEN
                                x_err_msg := x_err_msg
                                             || 'Unexpected Error while Derving Ledger; ';
                                x_cda_trx_table(indx).lineerror := p_error_flag;
                        END;

                        IF x_cda_trx_table(indx).sipp_code IS NOT NULL THEN
                            SELECT
                                COUNT(*)
                            INTO x_count_sipp
                            FROM
                                xxgenai_fah_fnd_lookup_values
                            WHERE
                                    lookup_code = x_cda_trx_table(indx).sipp_code
                                AND lookup_type = 'XX_GL_CDA_SIPP_CODES'
                                AND enabled_flag = 'Y'
                                AND ( end_date_active IS NULL
                                      OR trunc(end_date_active) > trunc(sysdate) );

                        END IF;

                        IF x_cda_trx_table(indx).sipp_code IS NULL THEN
                            x_cda_trx_table(indx).lineerror := p_error_flag;
                            x_err_msg := x_err_msg || 'Mandatory Field Not Pupulated : SIPP Code; ';
                        END IF;

                        IF x_count_sipp = 0 THEN
                            x_cda_trx_table(indx).lineerror := p_error_flag;
                            x_err_msg := x_err_msg || 'Invalid SIPP Code; ';
                        END IF;

                        IF x_cda_trx_table(indx).period IS NULL THEN
                            x_cda_trx_table(indx).lineerror := p_error_flag;
                            x_err_msg := x_err_msg || 'Mandatory Field Not Populated : period; ';
                        ELSE
                            BEGIN
                                IF x_cda_trx_table(indx).period_flag = 'Y' THEN
                                    x_period_name := x_cda_trx_table(indx).period;
                                ELSE
                                    x_cda_trx_table(indx).load_status := p_flag_err;
                                    x_err_msg := x_err_msg || 'Period is not OPEN; ';
                                    x_cda_trx_table(indx).lineerror := p_error_flag;
                                END IF;

                            EXCEPTION
                                WHEN no_data_found THEN
                                    x_err_msg := x_err_msg || 'period not open; ';
                                    x_cda_trx_table(indx).lineerror := p_error_flag;
                                WHEN OTHERS THEN
                                    x_err_msg := x_err_msg
                                                 || 'Unexpected Error while validating: GL Open period; ';
                                    x_cda_trx_table(indx).lineerror := p_error_flag;
                            END;
                        END IF;

                        IF x_cda_trx_table(indx).legal_entity IS NOT NULL THEN
                            BEGIN
                                x_valid_legal_entity := NULL;
                                SELECT
                                    attribute7
                                INTO x_valid_legal_entity
                                FROM
                                    xxgenai_hr_locations_all
                                WHERE
                                    internal_location_code = x_cda_trx_table(indx).location_id;

                            EXCEPTION
                                WHEN no_data_found THEN
                                    x_cda_trx_table(indx).lineerror := p_error_flag;
                                    x_err_msg := x_err_msg || 'Invalid legal_entity; ';
                            END;

                            IF x_valid_legal_entity != x_cda_trx_table(indx).legal_entity THEN
                                x_cda_trx_table(indx).lineerror := p_error_flag;
                                x_err_msg := x_err_msg || 'Invalid legal_entity; ';
                            END IF;

                        END IF;

                        IF x_cda_trx_table(indx).location_id IS NULL THEN
                            x_cda_trx_table(indx).lineerror := p_error_flag;
                            x_err_msg := x_err_msg || 'Mandatory Field Not Pupulated : Location ID; ';
                        ELSIF x_cda_trx_table(indx).location_id IS NOT NULL THEN
                            BEGIN
                                x_valid_location_id := NULL;
                                SELECT
                                    internal_location_code
                                INTO x_valid_location_id
                                FROM
                                    xxgenai_hr_locations_all
                                WHERE
                                    internal_location_code = x_cda_trx_table(indx).location_id;

                            EXCEPTION
                                WHEN no_data_found THEN
                                    x_cda_trx_table(indx).lineerror := p_error_flag;
                                    x_err_msg := x_err_msg || 'Invalid Location ID; ';
                            END;
                        END IF;

                        IF x_cda_trx_table(indx).car_days IS NULL THEN
                            x_cda_trx_table(indx).lineerror := p_error_flag;
                            x_err_msg := x_err_msg || 'Field Car Days: NULL; ';
                        END IF;

                        IF x_cda_trx_table(indx).car_days < 0 THEN
                            x_cda_trx_table(indx).lineerror := p_error_flag;
                            x_err_msg := x_err_msg || 'Negative Value ; ';
                        END IF;


                        x_cda_trx_table(indx).error_message := x_err_msg;
                        IF x_cda_trx_table(indx).lineerror = p_error_flag THEN
                            x_cda_trx_table(indx).load_status := p_flag_err;
                            x_batch_error := p_error_flag;
                            x_batch_status := p_flag_err;
                        END IF;

                    EXCEPTION
                        WHEN OTHERS THEN
                            p_status_out := x_err_stat;
                            p_err_msg_out := p_err_msg_out || sqlerrm;
                    END;
                END LOOP;

                BEGIN
                    FORALL i IN INDICES OF x_cda_trx_table
                        UPDATE xxgenai_gl_cda_lh_int
                        SET
                            load_status = x_batch_status,
                            batcherror = x_batch_error,
                            lineerror = x_cda_trx_table(i).lineerror,
                            error_message = x_cda_trx_table(i).error_message
                        WHERE
                                record_id = x_cda_trx_table(i).record_id
                            AND oic_instance_id = p_oic_instance_id;

                EXCEPTION
                    WHEN OTHERS THEN
                        p_status_out := x_err_stat;
                        p_err_msg_out := p_err_msg_out || sqlerrm;
                END;

            END IF;

            EXIT WHEN c_cda_trx%notfound;
        END LOOP;

        COMMIT;
        CLOSE c_cda_trx;



    BEGIN
        OPEN c_duplicate;
        FETCH c_duplicate BULK COLLECT INTO v_duplicate;
        CLOSE c_duplicate;
        IF v_duplicate.count > 0 THEN

                UPDATE xxgenai_gl_cda_lh_int
                SET
                    BATCHERROR = 'ERROR'
                WHERE
                    1 = 1
                    AND oic_instance_id = p_oic_instance_id;
            COMMIT;

            FORALL i IN 1..v_duplicate.count
                UPDATE xxgenai_gl_cda_lh_int
                SET
                    lineerror = 'ERROR',
                    error_message = 'Duplicate Record '
                WHERE
                    1 = 1
                    AND oic_instance_id = p_oic_instance_id
                    and period=v_duplicate(i).period
					and legal_entity=v_duplicate(i).legal_entity
					and location_id=v_duplicate(i).location_id
					and sipp_code=v_duplicate(i).sipp_code;



            COMMIT;
        END IF;

  END;

    EXCEPTION
        WHEN OTHERS THEN
            p_status_out := x_err_stat;
            p_err_msg_out := p_err_msg_out || sqlerrm;
    END validate_records_proc;

    PROCEDURE populate_legal_entity (
        p_oic_instance_id IN NUMBER,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    ) IS

        x_err_stat     VARCHAR2(1) := 'E';
        x_suc_stat     VARCHAR2(1) := 'S';
        x_legal_entity VARCHAR2(15) := NULL;
        CURSOR c_location IS
        SELECT
            location_id
        FROM
            xxgenai_gl_cda_lh_int
        WHERE
                oic_instance_id = p_oic_instance_id
            AND legal_entity IS NULL
        GROUP BY
            location_id;

    BEGIN
        FOR rec_cur_location IN c_location LOOP
            x_legal_entity := NULL;
            BEGIN
                SELECT
                    attribute9
                INTO x_legal_entity
                FROM
                    xxgenai_hr_locations_all hr
                WHERE
                    internal_location_code = rec_cur_location.location_id;

            EXCEPTION
                WHEN no_data_found THEN
                    SELECT 
                        flv.attribute1
                    INTO x_legal_entity
                    FROM
                        xxgenai_fah_fnd_lookup_values flv,
                        xxgenai_hr_locations_all      hr
                    WHERE
                            1 = 1
                        AND flv.lookup_type = 'XX_GL_COUNTRY_HQ_LOC'
                        AND flv.meaning = hr.country
                        AND hr.internal_location_code = rec_cur_location.location_id
                        AND flv.attribute_category = 'HERTZ_COUNTRY_HQ_LOC'
                        AND flv.enabled_flag = 'Y'
                        AND sysdate BETWEEN nvl(start_date_active, sysdate - 1) AND nvl(end_date_active, sysdate + 1)
						group by  flv.attribute1;
                   END;

            IF x_legal_entity IS NOT NULL THEN
                UPDATE xxgenai_gl_cda_lh_int
                SET
                    legal_entity = x_legal_entity
                WHERE
                        oic_instance_id = p_oic_instance_id
					AND location_id = rec_cur_location.location_id
                    AND legal_entity IS NULL;

            ELSE
                p_err_msg_out := 'Error while populating legal_entity';
                p_status_out := x_err_stat;
            END IF;

        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            p_status_out := x_err_stat;
            p_err_msg_out := p_err_msg_out || sqlerrm;
    END populate_legal_entity;

    PROCEDURE populate_reverse_journal_count (
        p_journal_count_recs IN xxgenai_gl_cda_lh_int_t,
        p_oic_instance_id    IN NUMBER,
        p_batchid            IN NUMBER,
        p_validated_flag     IN VARCHAR2,
        p_error_flag         IN VARCHAR2,
        p_status_out         OUT VARCHAR2,
        p_err_msg_out        OUT VARCHAR2,
        p_flag_valid         IN VARCHAR2,
        p_flag_err           IN VARCHAR2,
        p_filename           IN VARCHAR2
    ) IS

        PRAGMA autonomous_transaction;
        l_journal_index NUMBER DEFAULT 0;
        p_batch_status  VARCHAR2(10);
        x_err_stat      VARCHAR2(1) := 'E';
    BEGIN
        FORALL l_journal_index IN p_journal_count_recs.first..p_journal_count_recs.last SAVE EXCEPTIONS
            UPDATE xxgenai_gl_cda_lh_int
            SET
                count_gl_je_headers = p_journal_count_recs(l_journal_index).count_gl_je_headers
            WHERE
                    ledger_id = p_journal_count_recs(l_journal_index).ledger_id
                AND oic_instance_id = p_oic_instance_id
                AND file_name = p_filename
                AND batch_id = p_batchid;

        IF p_journal_count_recs(l_journal_index).count_gl_je_headers >= 1 THEN
            p_batch_status := 'E';
        END IF;

        UPDATE xxgenai_gl_cda_lh_int
        SET
            error_message = ' There should be reverse journal entry for combination',
            lineerror = 'ERROR'
        WHERE
                oic_instance_id = p_oic_instance_id
            AND file_name = p_filename
            AND batch_id = p_batchid
            AND count_gl_je_headers >= 1;

        IF p_batch_status = 'E' THEN
            UPDATE xxgenai_gl_cda_lh_int
            SET
                batcherror = 'ERROR',
                load_status = 'E'
            WHERE
                    oic_instance_id = p_oic_instance_id
                AND file_name = p_filename;

        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            p_status_out := x_err_stat;
            p_err_msg_out := p_err_msg_out || sqlerrm;
    END populate_reverse_journal_count;

END xxgenai_gl_cda_lh_int_pkg;