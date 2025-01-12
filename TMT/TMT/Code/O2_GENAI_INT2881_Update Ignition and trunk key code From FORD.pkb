create or replace PACKAGE BODY XXgenai_FORD_IGNITION_KEY_UPDATE_PKG  AS 
    G_FLAG_S CONSTANT VARCHAR2(1) := 'S';
	G_FLAG_N CONSTANT VARCHAR2(1) := 'N';
	G_FLAG_E CONSTANT VARCHAR2(1) := 'E';
	G_FLAG_V CONSTANT VARCHAR2(1) := 'V';
	PROCEDURE populate_main_stg
		(
			p_oic_instance_id IN NUMBER,
			p_file_name IN VARCHAR2,
			p_status_out OUT VARCHAR2,
			p_err_msg_out OUT VARCHAR2
		)
		IS
			CURSOR c_po_extract_rec IS
			SELECT
				input_file_data
			, 	file_name
			,created_by
			, 	last_updated_by
			FROM
				XXgenai_FORD_IGNITION_CODE_INBOUND_FILE_TBL
			WHERE 1=1
				AND oic_instance_id = p_oic_instance_id
				AND file_name = p_file_name
			;

			TYPE po_rec_tbl
			IS
				TABLE OF c_po_extract_rec%rowtype;
			

				po_rec po_rec_tbl := po_rec_tbl();
				l_rec_cnt NUMBER DEFAULT 0;


			BEGIN

				p_status_out := G_FLAG_S;
				p_err_msg_out := NULL;

				OPEN c_po_extract_rec;
				FETCH c_po_extract_rec BULK COLLECT
				INTO po_rec;
				CLOSE c_po_extract_rec;

				l_rec_cnt := po_rec.count;
				dbms_output.put_line(l_rec_cnt);
				FORALL i IN po_rec.first..po_rec.last

				Insert into XXgenai_FORD_IGNITION_CODE_STG_TBL
				(OIC_INSTANCE_ID,
				vin ,
				ignition_code, 
				trunk_code ,
				LOAD_STATUS	,
				FILE_NAME	,
				CREATED_BY ,
				CREATION_DATE, 
				LAST_UPDATED_BY ,
				LAST_UPDATE_DATE,
				bip_count)
				VALUES
				(p_oic_instance_id,
				trim(substr(po_rec(i).input_file_data,1,17)),
				trim(substr(po_rec(i).input_file_data,18,7)),
				trim(substr(po_rec(i).input_file_data,25,7)),
				G_FLAG_N,
				po_rec(i).file_name,
				po_rec(i).created_by,
				sysdate,
				po_rec(i).last_updated_by,
				sysdate,
				0);	
				Update
				XXgenai_FORD_IGNITION_CODE_STG_TBL
				set 
				Load_status=G_FLAG_E,
				error_message='No Vin entered for this record'
				where  oic_instance_id = p_oic_instance_id		
				and vin is null

				AND file_name = p_file_name;

				commit;




			EXCEPTION WHEN OTHERS THEN
				p_status_out 	:= G_FLAG_E;
				p_err_msg_out 	:= SUBSTR(SQLERRM,1,200);

			END populate_main_stg;
	PROCEDURE assign_batch_id (
        p_oic_instance_id IN NUMBER,
        p_status_out  OUT VARCHAR2,
        p_err_msg_out OUT VARCHAR2
		)
	IS
	v_batch_size number:=200;
	BEGIN
	UPDATE
			XXgenai_FORD_IGNITION_CODE_STG_TBL 
		SET
			batch_id = CEIL(ROWNUM / v_batch_size)
		WHERE
			1 = 1 
			AND oic_instance_id = p_oic_instance_id;
			EXCEPTION WHEN OTHERS THEN
				p_status_out 	:= G_FLAG_E;
				p_err_msg_out 	:= SUBSTR(SQLERRM,1,200);
	end assign_batch_id; 
	PROCEDURE assign_rest_batch_id (
        p_oic_instance_id IN NUMBER,
		p_po_id IN NUMBER,
        p_status_out  OUT VARCHAR2,
        p_err_msg_out OUT VARCHAR2
		)
	IS
	v_batch_size number:=200;
	BEGIN
	UPDATE
			XXgenai_FORD_IGNITION_CODE_STG_TBL 
		SET
			rest_batch_id = CEIL(ROWNUM / v_batch_size)
		WHERE
			1 = 1 
			AND oic_instance_id = p_oic_instance_id
			AND po_header_id=p_po_id;
			EXCEPTION WHEN OTHERS THEN
				p_status_out 	:= G_FLAG_E;
				p_err_msg_out 	:= SUBSTR(SQLERRM,1,200);
	end assign_rest_batch_id;

PROCEDURE enter_po_data (
	p_po_rec IN t_po_stg_tbl,
	p_batch IN NUMBER,
        p_oic_instance_id IN NUMBER,
        p_status_out  OUT VARCHAR2,
        p_err_msg_out OUT VARCHAR2
		)
		IS
		BEGIN
		FORALL i IN p_po_rec.first..p_po_rec.last SAVE EXCEPTIONS
		UPDATE
		XXgenai_FORD_IGNITION_CODE_STG_TBL
		set 
		po_header_id		=p_po_rec(i).po_header_id		,
		po_line_id			=p_po_rec(i).po_line_id			,
		po_line_location_id	=p_po_rec(i).po_line_location_id,	
		bip_count=bip_count+1
		where  oic_instance_id = p_oic_instance_id
		AND batch_id = p_batch
		AND vin=p_po_rec(i).vin;
		commit;
		Update
		XXgenai_FORD_IGNITION_CODE_STG_TBL
		set 
		Load_status=G_FLAG_E,
		error_message='Multiple Schedules located for this record'
		where  oic_instance_id = p_oic_instance_id
		AND batch_id = p_batch
		and bip_count>1;
		Update
		XXgenai_FORD_IGNITION_CODE_STG_TBL
		set 
		Load_status=G_FLAG_E,
		error_message='No Unique Schedule could be determined for this record'
		where  oic_instance_id = p_oic_instance_id
		AND batch_id = p_batch
		and bip_count=0 or bip_count is null;
		Update
		XXgenai_FORD_IGNITION_CODE_STG_TBL
		set 
		Load_status=G_FLAG_V
		where  oic_instance_id = p_oic_instance_id
		AND batch_id = p_batch
		AND Load_status=G_FLAG_N;
		commit;
		EXCEPTION WHEN OTHERS THEN
				p_status_out 	:= G_FLAG_E;
				p_err_msg_out 	:= SUBSTR(SQLERRM,1,200);
		end enter_po_data;
		PROCEDURE reprocess
		(
			p_oic_instance_id IN NUMBER,
			p_reprocess_id IN NUMBER,
			p_file_name IN VARCHAR2,
			p_status_out OUT VARCHAR2,
			p_err_msg_out OUT VARCHAR2
		)
IS 
BEGIN
update XXgenai_FORD_IGNITION_CODE_STG_TBL set load_status='N', Record_status='',error_message='',oic_instance_id=p_oic_instance_id 
where  oic_instance_id=nvl(p_reprocess_id,oic_instance_id) and file_name=nvl(p_file_name,file_name);
EXCEPTION WHEN OTHERS THEN
				p_status_out 	:= G_FLAG_E;
				p_err_msg_out 	:= SUBSTR(SQLERRM,1,200);
end reprocess;


end XXgenai_FORD_Ignition_key_UPDATE_PKG;