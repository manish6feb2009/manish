create or replace PACKAGE BODY xxgenai_fa_reins_pkg AS
PROCEDURE main (
        p_oic_instance_id IN NUMBER,
        p_file_name       IN VARCHAR,
        p_updated_by      IN VARCHAR,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    ) IS

        v_reinstatement_date DATE;
        v_last_retired_date  DATE;
        x_status_out         VARCHAR2(120);
        x_error_message      VARCHAR2(120);
        x_error_code         VARCHAR2(120);
        x_asset_number_count NUMBER;
        x_asset_book_count   NUMBER;
        x_status             VARCHAR2(50) := 'Not Ready for Reinstatement';
        CURSOR c_rein_extract IS
        SELECT
            *
        FROM
            xxgenai_fa_veh_reinstatements_stg
        WHERE
                oic_instance_id = p_oic_instance_id
            AND file_name = p_file_name;

    BEGIN
        dbms_output.put_line('Begin ');
        FOR fa_rein IN c_rein_extract LOOP
            x_asset_number_count := 0;
            x_status_out := NULL;
            x_error_message := NULL;
            x_error_code := NULL;
            x_asset_book_count := 0;

		dbms_output.put_line('1 ');
            SELECT
                COUNT(asset_number)        
            INTO x_asset_number_count
            FROM
                xxgenai_fa_veh_reinstatements_stg
            WHERE
                    oic_instance_id = p_oic_instance_id
                AND file_name = p_file_name
                AND asset_number = fa_rein.asset_number
                AND record_id = fa_rein.record_id
            GROUP BY
                asset_number;
       IF x_asset_number_count < 1 THEN
                x_status_out := 'E';
                x_error_message := x_error_message
                                   || '|'
                                   || 'ASSET NUMEBR IS NULL';
                x_error_code := 'DATA VALIDATION ERROR'; 
            END IF; 
            dbms_output.put_line('2 ');
            SELECT
                COUNT(asset_book)
            INTO x_asset_book_count
            FROM
                xxgenai_fa_veh_reinstatements_stg
            WHERE
                    oic_instance_id = p_oic_instance_id
                AND file_name = p_file_name
                AND vin_number = fa_rein.vin_number
                AND record_id = fa_rein.record_id
            GROUP BY
                asset_book;
            IF
                x_asset_book_count < 1
                AND x_asset_number_count < 1
            THEN
                x_status_out := 'E';
                x_error_message := x_error_message
                                   || '|'
                                   || 'INVALID VIN';
                x_error_code := 'DATA VALIDATION ERROR';
            END IF; 
        dbms_output.put_line('3 ');
            SELECT
                nvl(trunc(reinstatement_date),
                    '01-JAN-99')
            INTO v_reinstatement_date
            FROM
                xxgenai_fa_veh_reinstatements_stg
            WHERE
                    oic_instance_id = p_oic_instance_id
                AND file_name = p_file_name
                AND vin_number = fa_rein.vin_number
                AND record_id = fa_rein.record_id
            GROUP BY
                reinstatement_date;

            IF v_reinstatement_date = '01-JAN-99' THEN
                x_status_out := 'E';
                x_error_message := x_error_message
                                   || '|'
                                   || 'REINSTATEMENT DATE IS NULL';
                x_error_code := 'DATA VALIDATION ERROR';
            END IF;

            dbms_output.put_line('4 ');
            SELECT
                nvl(trunc(last_retired_date),
                    '01-JAN-99')
            INTO v_last_retired_date
            FROM
                xxgenai_fa_veh_reinstatements_stg
            WHERE
                    oic_instance_id = p_oic_instance_id
                AND file_name = p_file_name
                AND vin_number = fa_rein.vin_number
                AND record_id = fa_rein.record_id
            GROUP BY
                last_retired_date;

            IF v_reinstatement_date <= v_last_retired_date THEN
                x_status_out := 'E';
                x_error_message := x_error_message
                                   || '|'
                                   || 'REINSTATEMENT DATE SHOULD BE GREATER THAN OR EQUAL TO LAST RETIREMENT DATE';
                x_error_code := 'DATA VALIDATION ERROR';
            END IF;

            dbms_output.put_line('5 ');
            IF x_status_out = 'E' THEN
                UPDATE xxgenai_fa_veh_reinstatements_stg
                SET
                    process_flag = x_status_out,
                    error_message = x_error_message,
                    error_code = x_error_code,
                    last_updated_by = p_updated_by,
                    last_update_date = sysdate,
                    status = x_status
                WHERE
                        oic_instance_id = p_oic_instance_id
                    AND vin_number = fa_rein.vin_number
                    AND record_id = fa_rein.record_id
                    AND reinstatement_reason = fa_rein.reinstatement_reason
                    AND reinstatement_type = fa_rein.reinstatement_type;

                dbms_output.put_line('6 ');
            END IF;

            COMMIT;
        END LOOP;

        p_status_out := 'S';
    EXCEPTION
        WHEN OTHERS THEN
            p_status_out := 'E';
            p_err_msg_out := substr(x_error_message
                                    || '|'
                                    || sqlerrm, 1, 250);
    END main;

PROCEDURE assign_batchid (
        p_oic_instance_id IN VARCHAR2,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    ) AS
 
        x_batch_size NUMBER := 900;
        x_count      NUMBER;
        x_from_seq   NUMBER := 0;
        x_to_seq     NUMBER := 0;
        x_batch_id   NUMBER;
    BEGIN
        SELECT
            MIN(record_id)
        INTO x_from_seq
        FROM
            xxgenai_fa_veh_reinstatements_stg
        WHERE
                oic_instance_id = p_oic_instance_id         
            AND source = 'EAM';
 
        SELECT
            MAX(record_id)
        INTO x_to_seq
        FROM
            xxgenai_fa_veh_reinstatements_stg
        WHERE
                oic_instance_id = p_oic_instance_id
            AND source = 'EAM';
 
        WHILE x_from_seq <= x_to_seq LOOP
            x_batch_id := xxgenai_fa_veh_reins_s1.nextval;
            FOR i IN 0..x_batch_size LOOP
                UPDATE xxgenai_fa_veh_reinstatements_stg
                SET
                    batch_id = x_batch_id
                WHERE
                        record_id = x_from_seq
                    AND oic_instance_id = p_oic_instance_id
                    AND source = 'EAM';
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

END xxgenai_fa_reins_pkg;