create or replace PACKAGE BODY xxgenai_po_chrysler_ignition_updates_pkg AS 
	G_FLAG_S CONSTANT VARCHAR2(1) := 'S';
	G_FLAG_N CONSTANT VARCHAR2(1) := 'N';
	G_FLAG_E CONSTANT VARCHAR2(1) := 'E';
	G_FLAG_V CONSTANT VARCHAR2(1) := 'V';

PROCEDURE populate_main_stg
(
	p_oic_instance_id IN NUMBER,
	p_file_oic_instance_id IN NUMBER,
	p_file_name IN VARCHAR2,
	p_source in VARCHAR2,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
) IS

CURSOR c_po_extract_rec IS
        SELECT
            invoice_record
          , file_name
          , last_updated_by
		  FROM
            xxgenai_ap_oem_invoice_inbound_stg
        WHERE 1=1
            AND oic_instance_id = p_file_oic_instance_id
			AND file_name = p_file_name
			and invoice_record IS NOT NULL;
			TYPE po_rec_tbl
IS
    TABLE OF c_po_extract_rec%rowtype;
TYPE x_po_stg_tab_typ
IS
    TABLE OF XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG%rowtype INDEX BY PLS_INTEGER;	

    po_rec po_rec_tbl := po_rec_tbl();
    l_rec_cnt NUMBER DEFAULT 0;
    x_po_idx PLS_INTEGER DEFAULT 0;
    x_po_stg_tab x_po_stg_tab_typ;

BEGIN

	p_status_out := G_FLAG_S;
	p_err_msg_out := NULL;

	OPEN c_po_extract_rec;
    FETCH c_po_extract_rec BULK COLLECT
    INTO po_rec;
	CLOSE c_po_extract_rec;

	l_rec_cnt := po_rec.count;
    FOR i IN po_rec.first..po_rec.last
	LOOP
	        x_po_idx                                      						:= x_po_idx + 1;
			x_po_stg_tab(x_po_idx).oic_instance_id       						:= p_oic_instance_id;
			x_po_stg_tab(x_po_idx).file_name       								:= po_rec(i).file_name;
		    x_po_stg_tab(x_po_idx).VEHICLE_ORDER_NUMBER                         := trim(substr(po_rec(i).invoice_record,29,8));
			x_po_stg_tab(x_po_idx).IGNITION_KEY_CODE				       		:= trim(substr(po_rec(i).invoice_record,49,10));
			x_po_stg_tab(x_po_idx).VIN_NUMBER  						       		:= trim(substr(po_rec(i).invoice_record,8,17));
			x_po_stg_tab(x_po_idx).TRUNK_KEY  						       		:= trim(substr(po_rec(i).invoice_record,59,10));	
			x_po_stg_tab(x_po_idx).created_by     								:= po_rec(i).last_updated_by;
			x_po_stg_tab(x_po_idx).creation_date   								:= SYSDATE;
			x_po_stg_tab(x_po_idx).last_updated_by 								:= po_rec(i).last_updated_by;
			x_po_stg_tab(x_po_idx).last_update_date								:= SYSDATE;
			x_po_stg_tab(x_po_idx).load_status     								:= G_FLAG_N;
            dbms_output.put_line(x_po_stg_tab(x_po_idx).PO_NUMBER );
	END LOOP;

	FORALL i IN x_po_stg_tab.first..x_po_stg_tab.last
	INSERT INTO XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG
	(
		oic_instance_id,
		file_name,
		VEHICLE_ORDER_NUMBER,
		IGNITION_KEY_CODE,
		VIN_NUMBER,
		TRUNK_KEY,
		created_by,
		creation_date,
		last_updated_by,
		last_update_date,
		load_status
	)
	VALUES
	(
		x_po_stg_tab(i).oic_instance_id,
		x_po_stg_tab(i).file_name,
		x_po_stg_tab(i).VEHICLE_ORDER_NUMBER,
		x_po_stg_tab(i).IGNITION_KEY_CODE,
		x_po_stg_tab(i).VIN_NUMBER,
		x_po_stg_tab(i).TRUNK_KEY,
		x_po_stg_tab(i).created_by,
		x_po_stg_tab(i).creation_date,
		x_po_stg_tab(i).last_updated_by,
		x_po_stg_tab(i).last_update_date,
		x_po_stg_tab(i).load_status
	);
EXCEPTION WHEN OTHERS THEN
	p_status_out 	:= G_FLAG_E;
	p_err_msg_out 	:= SUBSTR(SQLERRM,1,200);
dbms_output.put_line(p_status_out);
dbms_output.put_line(p_err_msg_out);
END populate_main_stg;

PROCEDURE update_run_time_error
(
	p_instance_id   IN    NUMBER,
	p_update_status IN    VARCHAR2,
	p_error_scope   IN    VARCHAR2,
	p_error_message IN    VARCHAR2,		
	p_batch_id      IN    NUMBER,
	p_file_name		IN	  VARCHAR2,
	p_status_out    OUT   VARCHAR2,
	p_err_msg_out   OUT   VARCHAR2
)

IS

BEGIN
	p_status_out := G_FLAG_S;
	p_err_msg_out := NULL;

	UPDATE XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG
	SET
		load_status = p_update_status,
		error_message = p_error_message,
		error_scope = p_error_scope,
		last_update_date = SYSDATE
	WHERE 1=1
		AND oic_instance_id = p_instance_id
		AND batch_id = NVL(p_batch_id,batch_id)
		AND file_name = NVL(p_file_name,file_name)
	;

	COMMIT;

EXCEPTION WHEN OTHERS THEN	
	p_status_out := G_FLAG_E;
	p_err_msg_out := SUBSTR(SQLERRM,1,200);
END update_run_time_error;

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
            XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG
        WHERE
            oic_instance_id = p_instance_id;

        SELECT
            MAX(record_id)
        INTO x_to_seq
        FROM
            XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG
        WHERE
            oic_instance_id = p_instance_id;

        WHILE x_from_seq <= x_to_seq LOOP
            x_batch_id := XXgenai_PO_CHRYSLER_IGNITION_KEY_CODE_UPDATE_TBL_SEQ1.nextval;
            FOR i IN 1..x_batch_size LOOP
                UPDATE XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG
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
PROCEDURE populate_po_dtls_stg
(
	p_po_data_recs IN t_po_data_tbl,
	p_oic_instance_id IN NUMBER,
	p_user IN VARCHAR2,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
)
IS
	l_record_index			NUMBER DEFAULT 0;
	l_po_rec_cnt			NUMBER DEFAULT 0;
	l_po_rec_ins_cnt		NUMBER;

BEGIN

	p_status_out := G_FLAG_S;
	p_err_msg_out := NULL;
    l_po_rec_cnt := p_po_data_recs.count;
	IF l_po_rec_cnt > 0 
	THEN
		BEGIN
			l_po_rec_ins_cnt := 0;
			FORALL l_record_index IN p_po_data_recs.first..p_po_data_recs.last SAVE EXCEPTIONS
				INSERT INTO XXgenai_PO_CHRYSLER_KEY_UPDATES_PO_DTLS_STG 
				(
					OIC_INSTANCE_ID,
					PO_NUMBER,
					VEHICLE_ORDER_NUMBER,
					PO_LINE_NUMBER,
					PO_SCHEDULE_NUMBER,
					PO_HEADER_ID,
					PO_LINE_ID,
					PO_LINE_LOCATION_ID,
					VIN,
					VEHICLE_COLOR,
					CREATED_BY,
					CREATION_DATE,
					LAST_UPDATED_BY,
					LAST_UPDATE_DATE
				)
				VALUES
				(
					p_oic_instance_id,
					p_po_data_recs(l_record_index).PO_NUMBER,
					p_po_data_recs(l_record_index).VEHICLE_ORDER_NUMBER,
					p_po_data_recs(l_record_index).PO_LINE_NUMBER,
					p_po_data_recs(l_record_index).PO_SCHEDULE_NUMBER,
					p_po_data_recs(l_record_index).PO_HEADER_ID,
					p_po_data_recs(l_record_index).PO_LINE_ID,
					p_po_data_recs(l_record_index).PO_LINE_LOCATION_ID,
					p_po_data_recs(l_record_index).VIN,
					p_po_data_recs(l_record_index).VEHICLE_COLOR,
					p_user,
					SYSDATE,
					p_user,
					SYSDATE
				);

			l_po_rec_ins_cnt := SQL%rowcount;
			COMMIT;
			p_err_msg_out  := l_po_rec_ins_cnt || ' records inserted';
		EXCEPTION WHEN OTHERS THEN
			p_status_out := G_FLAG_E;
			p_err_msg_out := SUBSTR(SQLERRM,1,200);
		END;
	END IF;	

END populate_po_dtls_stg;

PROCEDURE assign_rest_batches
(
	p_oic_instance_id IN NUMBER,
	p_batch_size IN NUMBER,
	p_po_header_id IN NUMBER,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
)
IS
	BEGIN

	p_status_out := G_FLAG_S;
	p_err_msg_out := NULL;

	UPDATE XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG
    SET rest_api_batch_id = CEIL(ROWNUM / p_batch_size)
	WHERE 1=1
	AND oic_instance_id = p_oic_instance_id
	AND load_status = 'V'
	AND po_id = p_po_header_id
	;

    COMMIT;


EXCEPTION WHEN OTHERS THEN

	p_status_out := G_FLAG_E;
	p_err_msg_out := SUBSTR(SQLERRM,1,200);

END assign_rest_batches;
PROCEDURE validate_records_proc
(
	p_oic_instance_id IN NUMBER,
	p_batch_id IN NUMBER,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
)
IS

	x_head_err_flag              VARCHAR2 (10);
    x_head_err_msg               VARCHAR2 (2000);
	x_array_limit                NUMBER := 10000;
	x_po_header_id 				 XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG.po_id%type := NULL;
	x_po_line_id 				 XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG.po_line_id%type := NULL;
	x_po_line_location_id 		 XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG.po_line_location_id%type := NULL;
	x_po_number 				 XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG.po_number%type:= NULL;
	x_po_line_number 			 XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG.po_line_number%type:= NULL;
	x_po_schedule_number 		 XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG.po_schedule_number%type:= NULL;
	x_vin       				 XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG.VIN_NUMBER%type:= NULL;
	x_ignition_key_code  		 XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG.IGNITION_KEY_CODE%type:= NULL;
	x_trunk_key      			 XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG.TRUNK_KEY%type:= NULL;
	x_is_alphanum                XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG.load_status%type:= NULL; 
	x_load_status 				 VARCHAR2(1) := NULL;
	e_unexpected_validation_error EXCEPTION;
	e_incorrect_vin				 EXCEPTION;

	CURSOR c_po_recs IS
		SELECT * 
		FROM
			XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG
		WHERE
				1=1
			AND	oic_instance_id = p_oic_instance_id
			AND batch_id = p_batch_id
			AND load_status = G_FLAG_N
			AND VIN_NUMBER IS NOT NULL
	;



	TYPE po_recs_tbl_type IS TABLE OF c_po_recs%rowtype INDEX BY BINARY_INTEGER;
    po_recs_select_table po_recs_tbl_type;

	TYPE po_recs_update_type IS TABLE OF XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG%rowtype INDEX BY BINARY_INTEGER;
    po_recs_update_table po_recs_update_type;
	xx_error_update_table po_recs_update_type;

BEGIN

	p_status_out := G_FLAG_S;
	p_err_msg_out := NULL;

	OPEN c_po_recs;

	LOOP
		po_recs_select_table.DELETE;
		po_recs_update_table.DELETE;

		FETCH c_po_recs BULK COLLECT INTO po_recs_select_table LIMIT x_array_limit;
dbms_output.put_line(po_recs_select_table.COUNT );
		EXIT WHEN po_recs_select_table.COUNT = 0;

		FOR i IN 1..po_recs_select_table.COUNT
		LOOP
			BEGIN

				x_head_err_flag := G_FLAG_V;
				x_head_err_msg := NULL;
				x_po_header_id := NULL;
				x_po_line_id := NULL;
				x_po_line_location_id := NULL;
				x_po_number := NULL;
				x_po_line_number := NULL;
				x_po_schedule_number := NULL;
	            x_vin        := NULL;			
				x_ignition_key_code  := NULL;
				x_trunk_key := NULL;
				x_load_status := NULL;
				x_is_alphanum:=NULL;


				IF po_recs_select_table(i).vin_number IS NOT NULL
				THEN
				BEGIN
				   IF LENGTH(po_recs_select_table(i).vin_number) <> 17
					   THEN
						RAISE e_incorrect_vin;
					END IF;			
				EXCEPTION WHEN e_incorrect_vin THEN
					x_head_err_flag := G_FLAG_E;
					x_head_err_msg := x_head_err_msg || 'VIN is not of LENGTH 17 characters ' || ' - '; 
				WHEN OTHERS THEN
					x_head_err_flag := G_FLAG_E;
					x_head_err_msg := x_head_err_msg || 'VIN Validation Failed' || ' - '; 
				END;
				END IF;


				BEGIN
				dbms_output.put_line('417');
            SELECT 'Y'
              INTO x_is_alphanum
              FROM DUAL
             WHERE REGEXP_INSTR ( po_recs_select_table(i).vin_number, '[0-9]+') <> 0
               AND (REGEXP_INSTR ( po_recs_select_table(i).vin_number, '[a-z]+') <> 0
                 OR REGEXP_INSTR ( po_recs_select_table(i).vin_number, '[A-Z]+') <> 0
                   )
               AND NOT REGEXP_LIKE ( po_recs_select_table(i).vin_number, '[^a-zA-Z0-9]');

            IF x_is_alphanum IS NULL
            THEN
              x_head_err_flag := G_FLAG_E;
              x_head_err_msg  := x_head_err_msg || ' VIN is not in alphanumeric format ' || '-';
            END IF;

          EXCEPTION
            WHEN OTHERS
            THEN
              x_head_err_flag := G_FLAG_E;
              x_head_err_msg  := x_head_err_msg || ' Error while validating VIN for alphanumeric characters ' || '-';
          END;
          BEGIN
				dbms_output.put_line(po_recs_select_table(i).VIN_NUMBER );
					SELECT distinct 
						VIN_NUMBER	
					INTO
						x_vin
					FROM
						XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG
					WHERE
							1=1
						AND VIN_NUMBER = po_recs_select_table(i).VIN_NUMBER
						AND oic_instance_id= p_oic_instance_id;	
                  dbms_output.put_line(x_vin );
				EXCEPTION WHEN NO_DATA_FOUND THEN
					x_head_err_flag := G_FLAG_E;
					x_head_err_msg := x_head_err_msg || 'VIN Number is Not present in file' || ' - ';
				WHEN OTHERS THEN
					x_head_err_flag := G_FLAG_E;
					x_head_err_msg := x_head_err_msg || 'Error while fecthing VIN Number' || ' - ';
				END;

				IF x_vin IS NOT NULL
				THEN
				BEGIN
				dbms_output.put_line('466');
						SELECT
							vin
						INTO
							x_vin
						FROM
						  XXgenai_PO_CHRYSLER_KEY_UPDATES_PO_DTLS_STG 
							WHERE
								1=1
							AND VEHICLE_ORDER_NUMBER = po_recs_select_table(i).VEHICLE_ORDER_NUMBER
							AND VIN=po_recs_select_table(i).VIN_NUMBER
							AND oic_instance_id= p_oic_instance_id;
								 dbms_output.put_line('480');

						 IF x_vin IS NOT NULL
						    THEN
						    SELECT PO_LINE_NUMBER,
						    PO_SCHEDULE_NUMBER,
						    PO_HEADER_ID,
						    PO_LINE_ID,
						    PO_LINE_LOCATION_ID, 
							PO_NUMBER
						    INTO 
						    x_po_line_number,
						    x_po_schedule_number,
						    x_po_header_id,
				            x_po_line_id ,
				            x_po_line_location_id,
							x_po_number
						    FROM 
							XXgenai_PO_CHRYSLER_KEY_UPDATES_PO_DTLS_STG 
						    WHERE 
						    1=1
						        AND VIN=po_recs_select_table(i).VIN_NUMBER
								AND VEHICLE_ORDER_NUMBER = po_recs_select_table(i).VEHICLE_ORDER_NUMBER
								AND oic_instance_id= p_oic_instance_id;
								 dbms_output.put_line('506');
						END IF;

						EXCEPTION WHEN NO_DATA_FOUND
						THEN
						dbms_output.put_line('511');
                        x_head_err_flag := G_FLAG_E;
						x_head_err_msg := x_head_err_msg || 'VIN is not present in cloud for the PO' || ' - ';
					    WHEN OTHERS THEN
						x_head_err_flag := G_FLAG_E;
						x_head_err_msg := x_head_err_msg || 'Error while fecthing PO details' || ' - ';

					END;

				END IF;

				IF x_head_err_flag = G_FLAG_E
					THEN 
						x_load_status := G_FLAG_E;
					ELSE
						x_load_status := G_FLAG_V;
						x_head_err_msg := NULL;
				END IF;

				            po_recs_update_table(i).po_line_number := x_po_line_number;
						        po_recs_update_table(i).po_schedule_number := x_po_schedule_number;
						        po_recs_update_table(i).po_id := x_po_header_id;
				                po_recs_update_table(i).po_line_id := x_po_line_id;
				                po_recs_update_table(i).po_line_location_id := x_po_line_location_id;
								po_recs_update_table(i).po_number :=x_po_number;
				                po_recs_update_table(i).load_status := x_load_status;
				                po_recs_update_table(i).error_message := x_head_err_msg;
				                po_recs_update_table(i).record_id := po_recs_select_table(i).record_id;
								

			EXCEPTION WHEN OTHERS THEN
				p_status_out := G_FLAG_E;
				p_err_msg_out := 'Exception occurred during validation - ' || SUBSTR(SQLERRM,1,200);
				RAISE e_unexpected_validation_error;
			END;

		END LOOP;

		BEGIN
			FORALL x_po_update IN po_recs_update_table.FIRST..po_recs_update_table.LAST SAVE EXCEPTIONS
				UPDATE XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG
				SET
				po_line_number=po_recs_update_table(x_po_update).po_line_number,
				po_schedule_number=po_recs_update_table(x_po_update).po_schedule_number,
					po_id = po_recs_update_table(x_po_update).po_id,
					po_line_id = po_recs_update_table(x_po_update).po_line_id,
					po_line_location_id = po_recs_update_table(x_po_update).po_line_location_id,
					po_number=po_recs_update_table(x_po_update).po_number,
					load_status = po_recs_update_table(x_po_update).load_status,
					error_message = po_recs_update_table(x_po_update).error_message,
					last_update_date = SYSDATE
					WHERE
					record_id = po_recs_update_table(x_po_update).record_id
					AND oic_instance_id= p_oic_instance_id;	
		EXCEPTION WHEN OTHERS THEN
			FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
			LOOP
				xx_error_update_table(i).error_message := po_recs_update_table(i).error_message||' '||SUBSTR(SQLERRM(sql%bulk_exceptions(i).error_code),1,200);
				xx_error_update_table(i).record_id := po_recs_update_table(i).record_id;
			END LOOP;
		END;

		FORALL p IN 1 .. xx_error_update_table.COUNT
			UPDATE XXgenai_PO_CHRYSLER_IGNITION_UPDATES_INT_STG
			SET
				load_status = G_FLAG_E,
				error_message = xx_error_update_table(p).error_message
			WHERE
				oic_instance_id = p_oic_instance_id
				AND record_id = xx_error_update_table(p).record_id
			;
	END LOOP;

	CLOSE c_po_recs;

	COMMIT;

EXCEPTION WHEN e_unexpected_validation_error THEN
	p_status_out := G_FLAG_E;
	p_err_msg_out := 'Unexcpected error during record validation - ' || SUBSTR(SQLERRM,1,200);

WHEN OTHERS THEN
	p_status_out := G_FLAG_E;
	p_err_msg_out := 'Unexcpected error during validation - ' || SUBSTR(SQLERRM,1,200);

END validate_records_proc;

END xxgenai_po_chrysler_ignition_updates_pkg;