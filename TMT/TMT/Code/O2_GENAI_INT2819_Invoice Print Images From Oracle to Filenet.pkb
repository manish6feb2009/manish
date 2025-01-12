create or replace PACKAGE BODY xxgenai_ap_inv_print_images_to_filenet_pkg AS	
 g_flag_e  CONSTANT VARCHAR2(1) := 'E';
    g_flag_v  CONSTANT VARCHAR2(1) := 'V';
    g_errbuff VARCHAR2(4000) := NULL;
    g_and_sym VARCHAR2(4) := '&';

PROCEDURE validate_invoice_records (
        p_oic_instance_id IN NUMBER,
        p_record_status   IN VARCHAR2,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    ) IS

        x_error_flag           VARCHAR2(5) := NULL;
        x_error_message        VARCHAR2(400) := NULL;
        x_process_flag         VARCHAR2(4) := NULL;
        x_filenet_url          VARCHAR2(2000) := NULL;
	CURSOR c_inv_rec_stg_dtls IS
        SELECT
            *
        FROM
            xxgenai_ap_inv_print_images_to_filenet_stg stg
        WHERE
                1 = 1
            AND record_status = 'N'
            AND oic_instance_id = p_oic_instance_id;

        TYPE inv_rec_stg_type IS
            TABLE OF c_inv_rec_stg_dtls%rowtype INDEX BY BINARY_INTEGER;
        inv_rec_stg_detail_tbl inv_rec_stg_type;
        TYPE inv_rec_update_type IS
            TABLE OF xxgenai_ap_inv_print_images_to_filenet_stg%rowtype INDEX BY BINARY_INTEGER;
        inv_val_rec_stg_table  inv_rec_update_type;
        xx_error_update_table  inv_rec_update_type;
    BEGIN
        OPEN c_inv_rec_stg_dtls;
        LOOP
            inv_rec_stg_detail_tbl.DELETE;
            inv_val_rec_stg_table.DELETE;
            xx_error_update_table.DELETE;
            FETCH c_inv_rec_stg_dtls
            BULK COLLECT INTO inv_rec_stg_detail_tbl;
            EXIT WHEN inv_rec_stg_detail_tbl.count = 0;
            FOR i IN 1..inv_rec_stg_detail_tbl.count LOOP
                BEGIN
                    x_error_flag := NULL;
                    x_error_message := NULL;
                    x_filenet_url := NULL;
			IF length(inv_rec_stg_detail_tbl(i).vin) <> 17 THEN
                        x_error_flag := g_flag_e;
                        x_error_message := x_error_message
                                           || 'Incorrect Length of VIN  '
                                           || '-';
                    END IF;
                    
                     IF inv_rec_stg_detail_tbl(i).vin is NULL THEN
                        x_error_flag := g_flag_e;
                        x_error_message := x_error_message
                                           || 'Null value of VIN.'
                                           || '-';
                    END IF;

                    IF x_error_flag IS NULL THEN
                        BEGIN
                            IF inv_rec_stg_detail_tbl(i).invoice_region = 'NA' THEN
                                x_filenet_url := 'https://trustedinterface.dev.filenet.hertz.io/FNOILinkP8/HertzResult_P8.aspx?lib=HERTZ_OS1'
                                                 || g_and_sym
                                                 || 'cfs=false'
                                                 || g_and_sym
                                                 || 'class=Vehicle_History'
                                                 || g_and_sym
                                                 || 'SerialNum8='
                                                 || substr(inv_rec_stg_detail_tbl(i).vin, 10, 8);
                            END IF;

                            IF inv_rec_stg_detail_tbl(i).invoice_region = 'EMEA' OR inv_rec_stg_detail_tbl(i).invoice_region = 'APAC'
                            THEN
                                x_filenet_url := 'https://trustedinterface.dev.filenet.hertz.io/FNOILinkP8/HertzResult_P8.aspx?lib=HERTZ_OS1'
                                                 || g_and_sym
                                                 || 'cfs=false'
                                                 || g_and_sym
                                                 || 'class=Vehicle_History'
                                                 || g_and_sym
                                                 || 'SerialNum8='
                                                 || substr(inv_rec_stg_detail_tbl(i).vin, 10, 8);

                            END IF;

                        END;
                    END IF;

                    IF x_error_flag = g_flag_e THEN
                        x_process_flag := g_flag_e;
                        g_errbuff := x_error_message;
                    ELSE
                        x_process_flag := g_flag_v;
                        x_error_message := NULL;
                    END IF;

                    inv_val_rec_stg_table(i).record_id := inv_rec_stg_detail_tbl(i).record_id;
                    inv_val_rec_stg_table(i).oic_instance_id := inv_rec_stg_detail_tbl(i).oic_instance_id;
                    inv_val_rec_stg_table(i).file_net_url := x_filenet_url;
                    inv_val_rec_stg_table(i).record_status := x_process_flag;
                    inv_val_rec_stg_table(i).error_message := x_error_message;
                EXCEPTION
                    WHEN OTHERS THEN
                        dbms_output.put_line(' Error during validation'
                                             || substr(sqlerrm, 1, 200));
                        p_status_out := 'E';
                        p_err_msg_out := substr(sqlerrm, 1, 500);
                END;
            END LOOP;


	      BEGIN
                FORALL x_stg_update IN 1..inv_val_rec_stg_table.count SAVE EXCEPTIONS
                    UPDATE xxgenai_ap_inv_print_images_to_filenet_stg
                    SET
                        record_status = inv_val_rec_stg_table(x_stg_update).record_status,
                        error_message = inv_val_rec_stg_table(x_stg_update).error_message,
                        file_net_url = inv_val_rec_stg_table(x_stg_update).file_net_url
                    WHERE
                            record_id = inv_val_rec_stg_table(x_stg_update).record_id
                        AND oic_instance_id = p_oic_instance_id;

            EXCEPTION
                WHEN OTHERS THEN
                    dbms_output.put_line('Count of error records while updating staging table' || SQL%bulk_exceptions.count);
                    FOR i IN 1..SQL%bulk_exceptions.count LOOP
                        xx_error_update_table(i).error_message := inv_val_rec_stg_table(i).error_message
                                                                  || ' '
                                                                  || substr(sqlerrm(SQL%bulk_exceptions(i).error_code), 1, 200);

                        xx_error_update_table(i).record_id := inv_val_rec_stg_table(i).record_id;
                    END LOOP;

            g_errbuff := 'Failed to update validation status in customer staging table';
            END;

            FORALL p IN 1..xx_error_update_table.count
                UPDATE xxgenai_ap_inv_print_images_to_filenet_stg
                SET
                    record_status = g_flag_e,
                    error_message = xx_error_update_table(p).error_message
                WHERE
                    record_id = xx_error_update_table(p).record_id;

        END LOOP;

        CLOSE c_inv_rec_stg_dtls;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_status_out := 'E';
            p_err_msg_out := substr(sqlerrm, 1, 500);
    END validate_invoice_records;

PROCEDURE assign_batch_id (
        p_instance_id IN NUMBER,
        p_status_out  OUT VARCHAR2,
        p_err_msg_out OUT VARCHAR2
    ) AS

        x_batch_size NUMBER := 100;
        x_count      NUMBER;
        x_from_seq   NUMBER := 0;
        x_to_seq     NUMBER := 0;
        x_batch_id   NUMBER;
    BEGIN
        SELECT
            MIN(record_id)
        INTO x_from_seq
        FROM
            xxgenai_ap_inv_print_images_to_filenet_stg
        WHERE
            oic_instance_id = p_instance_id;

        SELECT
            MAX(record_id)
        INTO x_to_seq
        FROM
            xxgenai_ap_inv_print_images_to_filenet_stg
        WHERE
            oic_instance_id = p_instance_id;

        WHILE x_from_seq <= x_to_seq LOOP
            x_batch_id := xxgenai_inv_print_images_to_filenet_batch_rec_id_s.nextval;
            FOR i IN 1..x_batch_size LOOP
                UPDATE xxgenai_ap_inv_print_images_to_filenet_stg
                SET
                    batch_id = x_batch_id
                WHERE
                        record_id = x_from_seq
                    AND oic_instance_id = p_instance_id;

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
    END assign_batch_id;

END xxgenai_ap_inv_print_images_to_filenet_pkg;