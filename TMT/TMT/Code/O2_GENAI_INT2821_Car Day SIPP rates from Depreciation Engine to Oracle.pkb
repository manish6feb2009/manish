create or replace PACKAGE BODY xxgenai_gl_inv_sipp_cost_depr_pkg AS

 g_flag_yes       VARCHAR2(1) := 'Y';
    g_array_size_num CONSTANT NUMBER := 10000;
PROCEDURE assign_batchid (
        p_oic_instance_id IN VARCHAR2,
        p_file_name       IN VARCHAR2,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    ) AS

        x_batch_size NUMBER := 1000;
        x_count      NUMBER;
        x_from_seq   NUMBER := 0;
        x_to_seq     NUMBER := 0;
        x_batch_id   NUMBER;
    BEGIN
        SELECT
            MIN(record_id)
        INTO x_from_seq
        FROM
            xxgenai_gl_sipp_cost_stg
        WHERE
            oic_instance_id = p_oic_instance_id;

        SELECT
            MAX(record_id)
        INTO x_to_seq
        FROM
            xxgenai_gl_sipp_cost_stg
        WHERE
            oic_instance_id = p_oic_instance_id;

        WHILE x_from_seq <= x_to_seq LOOP
            x_batch_id := xxgenai_assign_batchid_s1.nextval;
            FOR i IN 1..x_batch_size LOOP
                UPDATE xxgenai_gl_sipp_cost_stg
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

  PROCEDURE purge_data (
        p_oic_instance_id IN VARCHAR2,
        p_validated_flag  IN VARCHAR2,
        p_error_flag      IN VARCHAR2,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    ) IS

        x_validated_flag VARCHAR2(20) := p_validated_flag;
        x_error_flag     VARCHAR2(20) := p_error_flag;
        x_err_stat       VARCHAR2(1) := 'E';
        x_suc_stat       VARCHAR2(1) := 'S';
        x_error_message  VARCHAR2(240) := p_err_msg_out;
    BEGIN
        DELETE FROM xxgenai_gl_sipp_cost_stg
        WHERE
                1 = 1
            AND batch_status IN ( x_validated_flag, x_error_flag );

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
    END purge_data;
  PROCEDURE validate_records_proc (
        p_oic_instance_id  IN VARCHAR2,
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

        x_filename       VARCHAR2(100) := p_filename;
        x_batchid        NUMBER := p_batchid;
        x_initial_flag   VARCHAR2(1) := p_intial_flag;
        x_err_stat       VARCHAR2(1) := 'E';
        x_suc_stat       VARCHAR2(1) := 'S';

		CURSOR c_duplicate IS
        SELECT
            COUNT(*),period,region,sipp_code,brand,product

        FROM
            xxgenai_gl_sipp_cost_stg stg
        WHERE
            stg.oic_instance_id = p_oic_instance_id
        GROUP BY
            period,region,sipp_code,brand,product
        HAVING
            COUNT(*) > 1;

        TYPE c_duplicate_type IS
            TABLE OF c_duplicate%rowtype INDEX BY BINARY_INTEGER;
        v_duplicate c_duplicate_type;

        CURSOR c_rec_val IS
        SELECT
            oic_instance_id,
            batch_id,
            record_id,
            file_id,
            sipp_code,
            brand,
            product,
            period,
            region,
            cost,
            batch_status,
            line_status,
            period_flag,
            creation_date,
            created_by,
            last_update_date,
            last_updated_by,
            load_status,
            error_message,
            file_name,
            record_num,
            error_code,
            error_scope
        FROM
            xxgenai_gl_sipp_cost_stg
        WHERE
                1 = 1
            AND oic_instance_id = p_oic_instance_id
            AND load_status = x_initial_flag
            AND batch_id = x_batchid
            AND file_name = x_filename;

        TYPE x_rec_val_table_type IS
            TABLE OF c_rec_val%rowtype INDEX BY BINARY_INTEGER;
        x_rec_val_table  x_rec_val_table_type;
        x_batch_err_flag VARCHAR2(10) := NULL;
        x_line_err_flag  VARCHAR2(20) := NULL;
        x_err_msg        VARCHAR2(2000) := NULL;
        x_period_name    VARCHAR2(15) := NULL;
        x_sipp_code      VARCHAR2(10) := NULL;
        x_batch_error    VARCHAR2(15) := NULL;
        x_batch_status   VARCHAR2(15) := NULL;
        x_rec_count      NUMBER default NULL;
        x_count_sipp     NUMBER := 0;
        x_count_brand    NUMBER := 0;
        x_count_product  NUMBER := 0;
        x_count_region   NUMBER := 0;
        x_cost_count     NUMBER := 0;
        x_duplicate_rec  NUMBER := 0;
        x_region         VARCHAR2(100) := NULL;
    BEGIN
        x_batch_error := p_validated_flag;
        x_batch_status := p_flag_valid;
        OPEN c_rec_val;
        LOOP
            FETCH c_rec_val
            BULK COLLECT INTO x_rec_val_table LIMIT g_array_size_num;
            IF x_rec_val_table.count > 0 THEN
                x_rec_count := x_rec_val_table.count;
                FOR indx IN 1..x_rec_val_table.count LOOP
                    BEGIN
                        x_rec_val_table(indx).load_status := p_flag_valid;
                        x_rec_val_table(indx).line_status := p_validated_flag;
                        x_rec_val_table(indx).error_message := NULL;
                        x_err_msg := NULL;

      IF x_rec_val_table(indx).period IS NULL THEN
                            x_rec_val_table(indx).line_status := p_error_flag;
                            x_err_msg := x_err_msg || 'Mandatory Field Not Populated : Period; ';
                        ELSE
                            BEGIN
                                IF x_rec_val_table(indx).period_flag = 'Y' THEN
                                    x_period_name := x_rec_val_table(indx).period;
                                ELSE
                                    x_err_msg := x_err_msg || 'Period is not OPEN; ';
                                    x_rec_val_table(indx).line_status := p_error_flag;
                                END IF;

                            EXCEPTION
                                WHEN no_data_found THEN
                                    x_err_msg := x_err_msg || 'Period not open; ';
                                    x_rec_val_table(indx).line_status := p_error_flag;
                                WHEN OTHERS THEN
                                    x_err_msg := x_err_msg
                                                 || 'Unexpected Error while validating: GL Open Period '
                                                 || dbms_utility.format_error_backtrace;
                                    x_rec_val_table(indx).line_status := p_error_flag;
                            END;
                        END IF;

     IF x_rec_val_table(indx).sipp_code IS NOT NULL THEN
                            SELECT
                                COUNT(*)
                            INTO x_count_sipp
                            FROM
                                xxgenai_fah_fnd_lookup_values
                            WHERE
                                    lookup_code = x_rec_val_table(indx).sipp_code
                                AND lookup_type = 'XX_GL_CDA_SIPP_CODES'
                                AND enabled_flag = g_flag_yes
                                AND ( end_date_active IS NULL
                                      OR trunc(end_date_active) > trunc(sysdate) );

                        END IF;

                        IF x_rec_val_table(indx).sipp_code IS NULL THEN
                            x_rec_val_table(indx).line_status := p_error_flag;
                            x_err_msg := x_err_msg || 'Mandatory Field Not Populated : SIPP Code; ';
                        END IF;

                        IF x_count_sipp = 0 THEN
                            x_rec_val_table(indx).line_status := p_error_flag;
                            x_err_msg := x_err_msg || 'Invalid SIPP Code; ';
                        END IF;

        IF x_rec_val_table(indx).brand IS NOT NULL THEN
                            SELECT
                                COUNT(*)
                            INTO x_count_brand
                            FROM
                                xxgenai_fah_fnd_flex_values
                            WHERE
                                    flex_value = x_rec_val_table(indx).brand
                                AND flex_value_set_name = 'HERTZ_GLOBAL_GL_BRAND'
                                AND enabled_flag = g_flag_yes
                                AND ( end_date_active IS NULL
                                      OR trunc(end_date_active) > trunc(sysdate) );

                        END IF;

                        IF x_rec_val_table(indx).brand IS NULL THEN
                            x_rec_val_table(indx).line_status := p_error_flag;
                            x_err_msg := x_err_msg || 'Mandatory Field Not Populated : Brand; ';
                        END IF;

                        IF x_count_brand = 0 THEN
                            x_rec_val_table(indx).line_status := p_error_flag;
                            x_err_msg := x_err_msg || 'Invalid Brand; ';
                        END IF;

              IF x_rec_val_table(indx).product IS NOT NULL THEN
                            SELECT
                                COUNT(*)
                            INTO x_count_product
                            FROM
                                xxgenai_fah_fnd_flex_values
                            WHERE
                                    flex_value = x_rec_val_table(indx).product
                                AND flex_value_set_name = 'HERTZ_GLOBAL_GL_PRODUCT'
                                AND enabled_flag = g_flag_yes
                                AND ( end_date_active IS NULL
                                      OR trunc(end_date_active) > trunc(sysdate) );

                        END IF;

                        IF x_rec_val_table(indx).product IS NULL THEN
                            x_rec_val_table(indx).line_status := p_error_flag;
                            x_err_msg := x_err_msg || 'Mandatory Field Not Populated : Product; ';
                        END IF;

                        IF x_count_product = 0 THEN
                            x_rec_val_table(indx).line_status := p_error_flag;
                            x_err_msg := x_err_msg || 'Invalid product; ';
                        END IF;

          IF x_rec_val_table(indx).region IS NOT NULL THEN
                            SELECT
                                COUNT(*)
                            INTO x_count_region
                            FROM
                                xxgenai_fah_fnd_lookup_values
                            WHERE
                                    lookup_code = x_rec_val_table(indx).region
                                AND lookup_type = 'XX_GL_CDA_REGION'
                                AND enabled_flag = g_flag_yes
                                AND ( end_date_active IS NULL
                                      OR trunc(end_date_active) > trunc(sysdate) );

                            IF x_count_region = 0 THEN
                                x_rec_val_table(indx).line_status := p_error_flag;
                                x_err_msg := x_err_msg || 'Invalid Region ; ';
                            END IF;

                        END IF;

                        IF x_rec_val_table(indx).region IS NULL THEN
                            x_rec_val_table(indx).line_status := p_error_flag;
                            x_err_msg := x_err_msg || 'Mandatory Field Not Populated : Region; ';
                        END IF;

             IF x_rec_val_table(indx).cost IS NOT NULL THEN
                            SELECT DISTINCT
                                cost
                            INTO x_cost_count
                            FROM
                                xxgenai_gl_sipp_cost_stg
                            WHERE
                                cost = x_rec_val_table(indx).cost;

                        END IF;

                        IF x_rec_val_table(indx).cost < 0 THEN
                            x_rec_val_table(indx).line_status := p_error_flag;
                            x_err_msg := x_err_msg || 'Negative Cost ; ';
                        END IF;

                        IF x_rec_val_table(indx).cost IS NULL THEN
                            x_rec_val_table(indx).line_status := p_error_flag;
                            x_err_msg := x_err_msg || 'Mandatory Field Not Populated :Cost;';
                        END IF;

                        x_rec_val_table(indx).error_message := x_err_msg;
                        IF x_rec_val_table(indx).line_status = p_error_flag THEN
                            x_rec_val_table(indx).load_status := p_flag_err;
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
                    FORALL i IN INDICES OF x_rec_val_table
                        UPDATE xxgenai_gl_sipp_cost_stg
                        SET
                            load_status = x_batch_status,
                            batch_status = x_batch_error,
                            line_status = x_rec_val_table(i).line_status,
                            error_message = x_rec_val_table(i).error_message
                        WHERE
                                record_id = x_rec_val_table(i).record_id
                            AND oic_instance_id = p_oic_instance_id;

                EXCEPTION
                    WHEN OTHERS THEN
                        p_status_out := x_err_stat;
                        p_err_msg_out := p_err_msg_out || sqlerrm;
                END;

            END IF;

            EXIT WHEN c_rec_val%notfound;
        END LOOP;

        COMMIT;
        CLOSE c_rec_val;

		 BEGIN
        OPEN c_duplicate;
        FETCH c_duplicate BULK COLLECT INTO v_duplicate;
        CLOSE c_duplicate;
        IF v_duplicate.count > 0 THEN

                UPDATE xxgenai_gl_sipp_cost_stg
                SET
                    batch_status = 'ERROR'
                WHERE
                    1 = 1
                    AND oic_instance_id = p_oic_instance_id;
            COMMIT;

            FORALL i IN 1..v_duplicate.count
                UPDATE xxgenai_gl_sipp_cost_stg
                SET
                    line_status = 'ERROR',
                    error_message = 'Duplicate Record '
                WHERE
                    1 = 1
                    AND oic_instance_id = p_oic_instance_id
					and period=v_duplicate(i).period
					and region=v_duplicate(i).region
					and sipp_code=v_duplicate(i).sipp_code
					and brand=v_duplicate(i).brand
					and product=v_duplicate(i).product;



            COMMIT;
        END IF;

  END;

    EXCEPTION
        WHEN OTHERS THEN
            p_status_out := x_err_stat;
            p_err_msg_out := p_err_msg_out || sqlerrm;
    END validate_records_proc;	

	PROCEDURE update_status_proc (
        p_oic_instance_id  IN VARCHAR2,
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
        UPDATE xxgenai_gl_sipp_cost_stg
        SET
            load_status = x_initial_flag,
            batch_status = NULL,
            line_status = NULL,
            last_updated_by = p_last_updated_by,
            last_update_date = p_last_update_date,
            error_message = NULL
        WHERE
                1 = 1
            AND oic_instance_id <> p_oic_instance_id
            AND batch_status <> p_validated_flag
            AND period_flag = 'Y';

        p_status_out := x_suc_stat;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_status_out := x_err_stat;
            p_err_msg_out := sqlerrm;
    END update_status_proc;

END xxgenai_gl_inv_sipp_cost_depr_pkg;