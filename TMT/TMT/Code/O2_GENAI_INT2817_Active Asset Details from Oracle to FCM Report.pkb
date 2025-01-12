create or replace PACKAGE BODY XXgenai_FA_ACT_VEH_DTLS_FCM_PKG
AS
   PROCEDURE main
              (
                  p_record_type     IN x_veh_det_table
                , p_last_updated_by IN VARCHAR2
                , p_oic_instance_id IN VARCHAR2
                , p_status_out OUT     VARCHAR2
                , p_err_msg_out OUT    VARCHAR2
              )
IS
    l_record_index NUMBER DEFAULT 0;
    x_veh_det_type x_veh_det_table;
BEGIN
    x_veh_det_type :=p_record_type;
    p_err_msg_out:=x_veh_det_type.count||'x_veh_det_type.count ';
    IF x_veh_det_type.count != 0 THEN
        BEGIN
            FOR l_record_index IN x_veh_det_type.first..x_veh_det_type.last
            LOOP
                BEGIN
					INSERT INTO XXgenai_FA_ACT_VEH_DTLS_FCM_STG
						( OIC_INSTANCE_ID		
                        ,BATCH_ID		
                        ,TRANSACTION_ID		
                        ,ORIGINATING_SYSTEM_ID		
                        ,REG_NO		
                        ,VIN		
                        ,VENDOR_DESCRIPTION		
                        ,THIRD_PARTY_ID		
                        ,THIRD_PARTY_VEH_STATUS		
                        ,ODOMETER_READING		
                        ,DATE_OF_REGISTRATION		
                        ,IN_FLEET_DATE		
                        ,MANUFACTURER		
                        ,MODEL		
                        ,MANUFACTURER_MODEL_CODE		
                        ,DERIVATIVE		
                        ,DESCRIPTION		
                        ,VEHICLETYPE		
                        ,ENGINESIZECC		
                        ,FUELTYPE		
                        ,MODELYEAR		
                        ,COLOUR_DESCRIPTION		
                        ,TRIM_DESCRIPTION		
                        ,OCN		
                        ,OWNER_AREA_NUMBER		
                        ,PURCHASE_TYPE		
                        ,BOOKVALUE		
                        ,DEPRECIATION_RATE		
                        ,PURCHASE_ORDER_NUMBER		
                        ,LIST_PRICE		
                        ,ATTRIBUTE1		
                        ,ATTRIBUTE2		
                        ,ATTRIBUTE3		
                        ,ATTRIBUTE4		
                        ,ATTRIBUTE5		
                        ,IMPORT_UPDATE_FLAG		
                        ,RUN_TIMESTAMP		
                        ,CREATION_DATE		
                        ,CREATED_BY		
                        ,LAST_UPDATE_DATE		
                        ,LAST_UPDATED_BY		
                        ,LOAD_STATUS		
                        ,RECORD_STATUS		
                        ,ERROR_CODE		
                        ,ERROR_SCOPE	
                        ,FCM_PAYLOAD		
                        ,FCM_ACK_STATUS		
                        ,FCM_ACK_MESSAGE		
                        ,FCM_RESPONSE		
                        ,ERROR_MESSAGE		                 
						)
						VALUES
						( x_veh_det_type(l_record_index).OIC_INSTANCE_ID		
                        ,x_veh_det_type(l_record_index).BATCH_ID		
                        ,x_veh_det_type(l_record_index).TRANSACTION_ID		
                        ,x_veh_det_type(l_record_index).ORIGINATING_SYSTEM_ID		
                        ,x_veh_det_type(l_record_index).REG_NO		
                        ,x_veh_det_type(l_record_index).VIN		
                        ,x_veh_det_type(l_record_index).VENDOR_DESCRIPTION		
                        ,x_veh_det_type(l_record_index).THIRD_PARTY_ID		
                        ,x_veh_det_type(l_record_index).THIRD_PARTY_VEH_STATUS		
                        ,x_veh_det_type(l_record_index).ODOMETER_READING		
                        ,x_veh_det_type(l_record_index).DATE_OF_REGISTRATION		
                        ,x_veh_det_type(l_record_index).IN_FLEET_DATE		
                        ,x_veh_det_type(l_record_index).MANUFACTURER		
                        ,x_veh_det_type(l_record_index).MODEL		
                        ,x_veh_det_type(l_record_index).MANUFACTURER_MODEL_CODE		
                        ,x_veh_det_type(l_record_index).DERIVATIVE		
                        ,x_veh_det_type(l_record_index).DESCRIPTION		
                        ,x_veh_det_type(l_record_index).VEHICLETYPE		
                        ,x_veh_det_type(l_record_index).ENGINESIZECC		
                        ,x_veh_det_type(l_record_index).FUELTYPE		
                        ,x_veh_det_type(l_record_index).MODELYEAR		
                        ,x_veh_det_type(l_record_index).COLOUR_DESCRIPTION		
                        ,x_veh_det_type(l_record_index).TRIM_DESCRIPTION		
                        ,x_veh_det_type(l_record_index).OCN		
                        ,x_veh_det_type(l_record_index).OWNER_AREA_NUMBER		
                        ,x_veh_det_type(l_record_index).PURCHASE_TYPE		
                        ,x_veh_det_type(l_record_index).BOOKVALUE		
                        ,x_veh_det_type(l_record_index).DEPRECIATION_RATE		
                        ,x_veh_det_type(l_record_index).PURCHASE_ORDER_NUMBER		
                        ,x_veh_det_type(l_record_index).LIST_PRICE		
                        ,x_veh_det_type(l_record_index).ATTRIBUTE1		
                        ,x_veh_det_type(l_record_index).ATTRIBUTE2		
                        ,x_veh_det_type(l_record_index).ATTRIBUTE3		
                        ,x_veh_det_type(l_record_index).ATTRIBUTE4		
                        ,x_veh_det_type(l_record_index).ATTRIBUTE5		
                        ,x_veh_det_type(l_record_index).IMPORT_UPDATE_FLAG		
                        ,x_veh_det_type(l_record_index).RUN_TIMESTAMP		
                        ,x_veh_det_type(l_record_index).CREATION_DATE		
                        ,x_veh_det_type(l_record_index).CREATED_BY		
                        ,x_veh_det_type(l_record_index).LAST_UPDATE_DATE		
                        ,x_veh_det_type(l_record_index).LAST_UPDATED_BY		
                        ,x_veh_det_type(l_record_index).LOAD_STATUS		
                        ,x_veh_det_type(l_record_index).RECORD_STATUS		
                        ,x_veh_det_type(l_record_index).ERROR_CODE		
                        ,x_veh_det_type(l_record_index).ERROR_SCOPE
                        ,x_veh_det_type(l_record_index).FCM_PAYLOAD		
                        ,x_veh_det_type(l_record_index).FCM_ACK_STATUS		
                        ,x_veh_det_type(l_record_index).FCM_ACK_MESSAGE		
                        ,x_veh_det_type(l_record_index).FCM_RESPONSE		
                        ,x_veh_det_type(l_record_index).ERROR_MESSAGE		
						)
					;

				EXCEPTION
				WHEN OTHERS THEN
					p_status_out  := 'EI';
					p_err_msg_out := 'Error occured while inserting the BIP data';
				END;
            END LOOP;
        EXCEPTION
        WHEN OTHERS THEN
            p_status_out  := 'EA';
            p_err_msg_out := substr(sqlerrm,1,200);
        END;
    END IF;
EXCEPTION
WHEN OTHERS THEN
    p_status_out  := 'ES';
    p_err_msg_out := substr(sqlerrm,1,200);
END main;
	PROCEDURE ASSIGN_BATCHID( p_oic_instance_id  IN  VARCHAR2,
							  p_load_status		 IN	 VARCHAR2,
							  p_vi_batch_size	 IN	 NUMBER,
							  p_vu_batch_size	 IN	 NUMBER,
							  p_status_out       OUT VARCHAR2,
							  p_err_msg_out      OUT VARCHAR2)
	IS

    CURSOR c_stage
	IS
        SELECT VENDOR_DESCRIPTION
		  FROM XXgenai_FA_ACT_VEH_DTLS_FCM_STG avdf 
		 WHERE avdf.oic_instance_id = p_oic_instance_id 		   
		   AND avdf.load_status = p_load_status 
		 GROUP BY VENDOR_DESCRIPTION;

		x_vi_batch_size NUMBER := p_vi_batch_size;
		x_vu_batch_size NUMBER := p_vu_batch_size;
        x_from_seq_import   NUMBER := 0;
        x_to_seq_import     NUMBER := 0;
		x_from_seq_upd   NUMBER := 0;
        x_to_seq_upd     NUMBER := 0;
        x_batch_id   NUMBER := 0;

    BEGIN
     FOR rec_stg IN c_stage
		LOOP
        SELECT
            MIN(record_id), MAX(record_id)
        INTO x_from_seq_import, x_to_seq_import
        FROM
            XXgenai_FA_ACT_VEH_DTLS_FCM_STG
        WHERE
            oic_instance_id = p_oic_instance_id
			AND load_status = p_load_status
			AND import_update_flag = 'VI'
            AND VENDOR_DESCRIPTION = rec_stg.VENDOR_DESCRIPTION;

        SELECT
            MIN(record_id), MAX(record_id)
        INTO x_from_seq_upd, x_to_seq_upd
        FROM
            XXgenai_FA_ACT_VEH_DTLS_FCM_STG
        WHERE
            oic_instance_id = p_oic_instance_id
			AND load_status = p_load_status
			AND import_update_flag = 'VU'
            AND VENDOR_DESCRIPTION = rec_stg.VENDOR_DESCRIPTION;

        WHILE x_from_seq_import <= x_to_seq_import LOOP
            x_batch_id := x_batch_id + 1;
            FOR i IN 1..x_vi_batch_size LOOP
                UPDATE XXgenai_FA_ACT_VEH_DTLS_FCM_STG
                SET
                    batch_id = x_batch_id
                WHERE
                        record_id = x_from_seq_import
                    AND oic_instance_id = p_oic_instance_id
					AND import_update_flag = 'VI'
					AND load_status = p_load_status
                    AND VENDOR_DESCRIPTION = rec_stg.VENDOR_DESCRIPTION;

                x_from_seq_import := x_from_seq_import + 1;
                EXIT WHEN x_from_seq_import > x_to_seq_import;
            END LOOP;

        END LOOP;

		WHILE x_from_seq_upd <= x_to_seq_upd LOOP
            x_batch_id := x_batch_id + 1;
            FOR i IN 1..x_vu_batch_size LOOP
                UPDATE XXgenai_FA_ACT_VEH_DTLS_FCM_STG
                SET
                    batch_id = x_batch_id
                WHERE
                        record_id = x_from_seq_upd
                    AND oic_instance_id = p_oic_instance_id
					AND import_update_flag = 'VU'
					AND load_status = p_load_status
                    AND VENDOR_DESCRIPTION = rec_stg.VENDOR_DESCRIPTION;

                x_from_seq_upd := x_from_seq_upd + 1;				
                EXIT WHEN x_from_seq_upd > x_to_seq_upd;
            END LOOP;

        END LOOP;
     END LOOP;
        COMMIT;
        p_status_out := 'S';
    EXCEPTION
        WHEN OTHERS THEN
            p_status_out := 'E';
            p_err_msg_out := sqlerrm;

	END ASSIGN_BATCHID;
 PROCEDURE VALIDATE_VI_VU_DATA(p_oic_instance_id 	IN 	 VARCHAR2,									
								  p_load_status		IN	 VARCHAR2,
								  p_status_out		OUT	 VARCHAR2,
								  p_err_msg_out       OUT  VARCHAR2)
    IS

	CURSOR c_stage
	IS
        SELECT *
          FROM XXgenai_FA_ACT_VEH_DTLS_FCM_STG
         WHERE oic_instance_id = p_oic_instance_id
           AND load_status = p_load_status
         ORDER BY record_id;

		TYPE act_veh_stg_type IS
            TABLE OF c_stage%rowtype INDEX BY BINARY_INTEGER;
        act_veh_stg_detail_tbl act_veh_stg_type;
        TYPE act_veh_update_type IS
            TABLE OF XXgenai_FA_ACT_VEH_DTLS_FCM_STG%rowtype INDEX BY BINARY_INTEGER;
        act_veh_val_rec_stg_table  act_veh_update_type;
        xx_error_update_table  act_veh_update_type;  

		x_error_flag           VARCHAR2(5) := NULL;
        x_error_message        VARCHAR2(400) := NULL;

	BEGIN

		OPEN c_stage;
        LOOP
            act_veh_stg_detail_tbl.DELETE;
            act_veh_val_rec_stg_table.DELETE;
            xx_error_update_table.DELETE;
            FETCH c_stage
            BULK COLLECT INTO act_veh_stg_detail_tbl;
            EXIT WHEN act_veh_stg_detail_tbl.count = 0;


			FOR i IN 1..act_veh_stg_detail_tbl.count LOOP
                BEGIN

					x_error_flag := NULL;
                    x_error_message := NULL;

					IF act_veh_stg_detail_tbl(i).originating_system_id IS NULL THEN
							x_error_flag := G_INT_STATUS_ERROR;
							x_error_message := x_error_message
											|| 'Mandatory field value is Null : originatingSystemID  '
											|| '-';
					END IF;

					IF act_veh_stg_detail_tbl(i).reg_no IS NULL THEN
							x_error_flag := G_INT_STATUS_ERROR;
							x_error_message := x_error_message
											|| 'Mandatory field value is Null : regNo  '
											|| '-';
					END IF;

					IF act_veh_stg_detail_tbl(i).vendor_description IS NULL THEN
							x_error_flag := G_INT_STATUS_ERROR;
							x_error_message := x_error_message
											|| 'Mandatory field value is Null : vendorDescription  '
											|| '-';
					END IF;

					IF x_error_flag IS NULL THEN                        
                        act_veh_val_rec_stg_table(i).load_status := 'V';                        
                        act_veh_val_rec_stg_table(i).record_status := 'VALIDATED';	
						act_veh_val_rec_stg_table(i).error_message := NULL;
						act_veh_val_rec_stg_table(i).error_code := NULL;						
					ELSE
                        act_veh_val_rec_stg_table(i).load_status := x_error_flag;
                        act_veh_val_rec_stg_table(i).record_status := 'ERROR';
						act_veh_val_rec_stg_table(i).error_message := x_error_message;
						act_veh_val_rec_stg_table(i).error_code := 'CUSTOM_VALIDATION';
                    END IF;

					act_veh_val_rec_stg_table(i).record_id := act_veh_stg_detail_tbl(i).record_id;
                    act_veh_val_rec_stg_table(i).oic_instance_id := act_veh_stg_detail_tbl(i).oic_instance_id;
					act_veh_val_rec_stg_table(i).vin := act_veh_stg_detail_tbl(i).vin;                    

				EXCEPTION
                    WHEN OTHERS THEN
                        dbms_output.put_line(' Error during validation'
                                             || substr(sqlerrm, 1, 200));
                        p_status_out := 'E';
                        p_err_msg_out := substr(sqlerrm, 1, 500);
                END;
            END LOOP;
             BEGIN
                FORALL x_stg_update IN 1..act_veh_val_rec_stg_table.count SAVE EXCEPTIONS
                    UPDATE XXgenai_FA_ACT_VEH_DTLS_FCM_STG
                    SET
                        load_status = act_veh_val_rec_stg_table(x_stg_update).load_status,
                        record_status = act_veh_val_rec_stg_table(x_stg_update).record_status,
						error_code = act_veh_val_rec_stg_table(x_stg_update).error_code,
						error_message = act_veh_val_rec_stg_table(x_stg_update).error_message
                    WHERE
                            record_id = act_veh_val_rec_stg_table(x_stg_update).record_id
                        AND oic_instance_id = p_oic_instance_id
						AND vin = act_veh_val_rec_stg_table(x_stg_update).vin
						AND load_status = p_load_status;

            EXCEPTION
                WHEN OTHERS THEN
                    dbms_output.put_line('Count of error records while updating staging table' || SQL%bulk_exceptions.count);
                    FOR i IN 1..SQL%bulk_exceptions.count LOOP
                        xx_error_update_table(i).error_message := act_veh_val_rec_stg_table(i).error_message
                                                                  || ' '
                                                                  || substr(sqlerrm(SQL%bulk_exceptions(i).error_code), 1, 200);

                        xx_error_update_table(i).record_id := act_veh_val_rec_stg_table(i).record_id;
				END LOOP;

            END;

            FORALL p IN 1..xx_error_update_table.count
                UPDATE XXgenai_FA_ACT_VEH_DTLS_FCM_STG
                SET
                    load_status = G_INT_STATUS_ERROR,
                    error_message = xx_error_update_table(p).error_message
                WHERE
                    record_id = xx_error_update_table(p).record_id
					AND oic_instance_id = p_oic_instance_id
					AND load_status = p_load_status;

        END LOOP;

        CLOSE c_stage;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_status_out := 'E';
            p_err_msg_out := substr(sqlerrm, 1, 500);		

	END VALIDATE_VI_VU_DATA;

END XXgenai_FA_ACT_VEH_DTLS_FCM_PKG;