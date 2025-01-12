create or replace PACKAGE BODY xxgenai_gl_je_reseng_int_pkg AS
G_FLAG_E 				CONSTANT VARCHAR2(1) := 'E';
	G_FLAG_S 				CONSTANT VARCHAR2(1) := 'S';
	G_FLAG_N 				CONSTANT VARCHAR2(1) := 'N';
	G_FLAG_V 				CONSTANT VARCHAR2(1) := 'V';
	G_FLAG_F 				CONSTANT VARCHAR2(1) := 'F';
	G_FLAG_Y 				CONSTANT VARCHAR2(1) := 'Y';
	G_RESERVE_ENGINE 		CONSTANT VARCHAR2(14) := 'RESERVE_ENGINE';
	G_DFF_CONTEXT_NAME  	CONSTANT VARCHAR2(16) := 'XX_GL_RESENG_SEQ';
	G_ERROR_CODES_LOOKUP 	CONSTANT VARCHAR2(22) := 'XX_GL_JRNL_ERROR_CODES';
	G_FLEET_LEDGERS_LKP		CONSTANT VARCHAR2(18) := 'XXGL_FLEET_LEDGERS';

PROCEDURE insert_file_data
(
	p_file_recs IN t_file_recs,
	p_oic_instance_id IN VARCHAR2,
	p_user IN VARCHAR2,
	p_file_name IN VARCHAR2,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
) IS
	l_record_index			NUMBER DEFAULT 0;
	l_rec_cnt				NUMBER DEFAULT 0;
	l_rec_ins_cnt			NUMBER;
BEGIN
	p_status_out := G_FLAG_S;
	p_err_msg_out := NULL;

	l_rec_cnt := p_file_recs.count;
	IF l_rec_cnt > 0 
	THEN
		BEGIN
			l_rec_ins_cnt := 0;
			FORALL l_record_index IN p_file_recs.first..p_file_recs.last				
				INSERT INTO xxgenai_gl_je_reseng_int_stg
				(
					oic_instance_id,
					file_name,
					record_id,
					status,
					ledger_id,
					accounting_date,
					user_je_source_name,
					user_je_category_name,
					currency_code,
					date_created,
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
					converted_dr,
					converted_cr,
					journal_batch_name,
					journal_batch_description,
					journal_entry_name,
					journal_entry_description,
					journal_entry_line_description,
					currency_conversion_type,
					currency_conversion_date,
					currency_conversion_rate,
					context_line_dff,
					context_line_attribute1,
					context_line_attribute2,
					context_line_attribute3,
					context_line_attribute4,
					ledger_name,
					recon_reference,
					period_name,
					load_status,
					record_status,
					created_by,
					creation_date,
					last_updated_by,
					last_update_date,
					group_id
				)
				VALUES
				(
					p_oic_instance_id,
					p_file_name,
					xxgenai_gl_je_reseng_s1.NEXTVAL,
					p_file_recs(l_record_index).status,
					p_file_recs(l_record_index).ledger_id,
					p_file_recs(l_record_index).accounting_date,
					p_file_recs(l_record_index).user_je_source_name,
					p_file_recs(l_record_index).user_je_category_name,
					p_file_recs(l_record_index).currency_code,
					TO_CHAR(SYSDATE,'YYYY/MM/DD'),
					p_file_recs(l_record_index).actual_flag,
					p_file_recs(l_record_index).segment1,
					p_file_recs(l_record_index).segment2,
					p_file_recs(l_record_index).segment3,
					p_file_recs(l_record_index).segment4,
					p_file_recs(l_record_index).segment5,
					p_file_recs(l_record_index).segment6,
					p_file_recs(l_record_index).segment7,
					p_file_recs(l_record_index).segment8,
					p_file_recs(l_record_index).segment9,
					p_file_recs(l_record_index).segment10,
					p_file_recs(l_record_index).entered_dr,
					p_file_recs(l_record_index).entered_cr,
					p_file_recs(l_record_index).converted_dr,
					p_file_recs(l_record_index).converted_cr,
					p_file_recs(l_record_index).journal_batch_name,
					p_file_recs(l_record_index).journal_batch_description,
					p_file_recs(l_record_index).journal_entry_name,
					p_file_recs(l_record_index).journal_entry_description,
					p_file_recs(l_record_index).journal_entry_line_description,
					p_file_recs(l_record_index).currency_conversion_type,
					p_file_recs(l_record_index).currency_conversion_date,
					p_file_recs(l_record_index).currency_conversion_rate,
					p_file_recs(l_record_index).context_line_dff,
					p_file_recs(l_record_index).context_line_attribute1,
					p_file_recs(l_record_index).context_line_attribute2,
					p_file_recs(l_record_index).context_line_attribute3,
					p_file_recs(l_record_index).context_line_attribute4,
					p_file_recs(l_record_index).ledger_name,
					p_file_recs(l_record_index).recon_reference,
					p_file_recs(l_record_index).period_name,
					G_FLAG_N,
					'NEW',
					p_user,
					SYSDATE,
					p_user,
					SYSDATE,
					SUBSTR(TO_CHAR(p_oic_instance_id),-3)||TO_CHAR(p_file_recs(l_record_index).ledger_id)
				);

			l_rec_ins_cnt := SQL%rowcount;
			COMMIT;
			p_err_msg_out  := l_rec_ins_cnt || ' records inserted';

		EXCEPTION WHEN OTHERS THEN
			p_status_out := G_FLAG_E;
			p_err_msg_out := SUBSTR(SQLERRM,1,200);
		END;
	END IF;	

EXCEPTION WHEN OTHERS THEN
	p_status_out := G_FLAG_E;
	p_err_msg_out := SUBSTR(SQLERRM,1,200);	

END insert_file_data;

PROCEDURE assign_batch_id
(
	p_oic_instance_id IN VARCHAR2,
	p_file_name IN VARCHAR2,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
)
IS
	x_batch_size CONSTANT NUMBER := 5000;

BEGIN
	p_status_out := G_FLAG_S;
	p_err_msg_out := NULL;

	UPDATE 
		xxgenai_gl_je_reseng_int_stg
	SET 
		batch_id = CEIL(ROWNUM / x_batch_size)
	WHERE 1=1
		AND oic_instance_id = p_oic_instance_id
		AND load_status = G_FLAG_N
		AND file_name = p_file_name
	;

	COMMIT;

EXCEPTION WHEN OTHERS THEN
	p_status_out := G_FLAG_E;
	p_err_msg_out := SUBSTR(SQLERRM,1,200);	

END assign_batch_id;

PROCEDURE validate_records_proc
(
	p_oic_instance_id IN VARCHAR2,
	p_batch_id IN NUMBER,
	p_file_name IN VARCHAR2,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
)
IS
	CURSOR c_je_recs IS
	SELECT
		*
	FROM
		xxgenai_gl_je_reseng_int_stg
	WHERE 1=1
		AND oic_instance_id = p_oic_instance_id
		AND batch_id = p_batch_id
		AND file_name = p_file_name
	;

	CURSOR c_je_entry IS
	SELECT
		journal_entry_name
	FROM
		xxgenai_gl_je_reseng_int_stg
	WHERE 1=1
		AND oic_instance_id = p_oic_instance_id
		AND file_name = p_file_name
	GROUP BY
		journal_entry_name
	HAVING
		SUM(entered_dr) <> SUM(entered_cr)
	;

	CURSOR c_je_batch IS
	SELECT
		journal_batch_name
	FROM
		xxgenai_gl_je_reseng_int_stg
	WHERE 1=1
		AND oic_instance_id = p_oic_instance_id
		AND file_name = p_file_name
	GROUP BY
		journal_batch_name
	HAVING
		SUM(entered_dr) <> SUM(entered_cr)
	;

	TYPE t_je_recs IS TABLE OF c_je_recs%ROWTYPE INDEX BY BINARY_INTEGER;
	x_je_recs t_je_recs;

	TYPE t_je_tbl IS TABLE OF xxgenai_gl_je_reseng_int_stg%ROWTYPE INDEX BY BINARY_INTEGER;
	x_update_tbl t_je_tbl;

	TYPE r_journal_identifier IS RECORD
	(
		journal_identifier		xxgenai_gl_je_reseng_int_stg.journal_entry_name%TYPE
	);

	TYPE t_journal_identifier IS TABLE OF r_journal_identifier INDEX BY BINARY_INTEGER;

	x_journal_identifier t_journal_identifier;

	x_load_status VARCHAR2(1);
	x_err_msg VARCHAR2(2400);
	x_ledger_id NUMBER;
	x_currency_code VARCHAR2(20);
	x_period_name VARCHAR2(20);
	x_journal_dr_amt NUMBER;
	x_journal_cr_amt NUMBER;

BEGIN
	p_status_out := G_FLAG_S;
	p_err_msg_out := NULL;

	OPEN c_je_recs;
	FETCH c_je_recs BULK COLLECT INTO x_je_recs;
	CLOSE c_je_recs;

	IF x_je_recs.COUNT > 0
	THEN

		dbms_output.put_line('before validation loop: '||SYSTIMESTAMP);

		FOR i IN x_je_recs.FIRST..x_je_recs.LAST
		LOOP
			x_load_status := G_FLAG_V;
			x_err_msg := NULL;
			x_ledger_id := NULL;
			x_currency_code := NULL;
			x_period_name := NULL;
			x_journal_dr_amt := NULL;
			x_journal_cr_amt := NULL;

			IF x_je_recs(i).ledger_id IS NULL
			THEN
				x_load_status := G_FLAG_E;
				x_err_msg := x_err_msg || 'Ledger ID is NULL' || ' - ';
			ELSIF x_je_recs(i).ledger_name IS NULL
			THEN
				x_load_status := G_FLAG_E;
				x_err_msg := x_err_msg || 'Ledger Name is NULL' || ' - ';
			ELSE	
				BEGIN
					SELECT
						 gl.ledger_id
						,gl.currency_code
					INTO
						 x_ledger_id
						,x_currency_code
					FROM
						 xxgenai_gl_ledgers gl
						,xxgenai_fah_fnd_lookup_values flv
					WHERE 1=1
						AND gl.ledger_id = x_je_recs(i).ledger_id
						AND gl.name = x_je_recs(i).ledger_name
						AND flv.lookup_type = G_FLEET_LEDGERS_LKP
						AND flv.enabled_flag = G_FLAG_Y
						AND SYSDATE BETWEEN NVL(flv.start_date_active,SYSDATE) AND NVL(flv.end_date_active,SYSDATE)
						AND flv.meaning = gl.name
						AND UPPER(flv.tag) = 'YES'
					;

				EXCEPTION WHEN NO_DATA_FOUND THEN
					x_load_status := G_FLAG_E;
					x_err_msg := x_err_msg || 'Invalid Ledger ID/Name' || ' - ';
				WHEN OTHERS THEN
					x_load_status := G_FLAG_E;
					x_err_msg := x_err_msg || 'Error while validating Ledger ID/Name' || ' - ';

				END;

				IF x_currency_code <> x_je_recs(i).currency_code
				THEN
					x_load_status := G_FLAG_E;
					x_err_msg := x_err_msg || 'Invalid Currency Code for the Ledger' || ' - ';

				END IF;

			END IF;

			IF x_je_recs(i).accounting_date IS NULL
			THEN
				x_load_status := G_FLAG_E;
				x_err_msg := x_err_msg || 'Accounting Date is NULL' || ' - ';
			END IF;

			IF x_je_recs(i).user_je_source_name <> G_RESERVE_ENGINE
			THEN
				x_load_status := G_FLAG_E;
				x_err_msg := x_err_msg || 'Invalid Journal Source' || ' - ';

			END IF;

			IF x_je_recs(i).user_je_category_name <> G_RESERVE_ENGINE
			THEN
				x_load_status := G_FLAG_E;
				x_err_msg := x_err_msg || 'Invalid Journal Category' || ' - ';

			END IF;

			IF x_je_recs(i).period_name IS NULL
			THEN
				x_load_status := G_FLAG_E;
				x_err_msg := x_err_msg || 'Period Name is NULL' || ' - ';
			ELSE
				BEGIN
					SELECT
						period_name
					INTO
						x_period_name
					FROM
						xxgenai_gl_period_statuses
					WHERE 1=1
						AND application_id = 101 
						AND ledger_id = x_je_recs(i).ledger_id
						AND closing_status = 'O'
						AND period_name = x_je_recs(i).period_name
					;

				EXCEPTION WHEN NO_DATA_FOUND THEN
					x_load_status := G_FLAG_E;
					x_err_msg := x_err_msg || 'Invalid/Closed Period' || ' - ';
				WHEN OTHERS THEN
					x_load_status := G_FLAG_E;
					x_err_msg := x_err_msg || 'Error while validating Period' || ' - ';

				END;

			END IF;

			x_update_tbl(i).record_id := x_je_recs(i).record_id;
			x_update_tbl(i).load_status := x_load_status;
			x_update_tbl(i).error_message := x_err_msg;

		END LOOP;

		dbms_output.put_line('after validation loop: '||SYSTIMESTAMP);

		FORALL i IN x_update_tbl.FIRST..x_update_tbl.LAST
			UPDATE
				xxgenai_gl_je_reseng_int_stg
			SET
				last_update_date = SYSDATE,
				load_status = x_update_tbl(i).load_status,
				error_message = x_update_tbl(i).error_message,
				error_scope = DECODE(x_update_tbl(i).load_status,G_FLAG_E,'VALIDATION',NULL),
				record_status = DECODE(x_update_tbl(i).load_status,G_FLAG_E,'ERROR',G_FLAG_V,'VALIDATED'),
				context_line_dff = NVL(context_line_dff,G_DFF_CONTEXT_NAME)
			WHERE 1=1
				AND oic_instance_id = p_oic_instance_id
				AND batch_id = p_batch_id
				AND record_id = x_update_tbl(i).record_id
				AND file_name = p_file_name
			;
		COMMIT;

		dbms_output.put_line('after forall update: '||SYSTIMESTAMP);

	END IF;

	x_journal_identifier := t_journal_identifier();

	OPEN c_je_entry;
	FETCH c_je_entry BULK COLLECT INTO x_journal_identifier;
	CLOSE c_je_entry;

	IF x_journal_identifier.COUNT > 0
	THEN
		FORALL i IN x_journal_identifier.FIRST..x_journal_identifier.LAST
			UPDATE
				xxgenai_gl_je_reseng_int_stg
			SET
				last_update_date = SYSDATE,
				load_status = G_FLAG_E,
				error_message = error_message||'Unbalanced amount for Journal Entry: '||x_journal_identifier(i).journal_identifier||' - ',
				error_scope = 'VALIDATION',
				record_status = 'ERROR'
			WHERE 1=1
				AND oic_instance_id = p_oic_instance_id
				AND batch_id = p_batch_id
				AND journal_entry_name = x_journal_identifier(i).journal_identifier
				AND file_name = p_file_name
			;
		COMMIT;

	END IF;

	dbms_output.put_line('after journal entry update: '||SYSTIMESTAMP);

	x_journal_identifier.DELETE;

	OPEN c_je_batch;
	FETCH c_je_batch BULK COLLECT INTO x_journal_identifier;
	CLOSE c_je_batch;

	IF x_journal_identifier.COUNT > 0
	THEN
		FORALL i IN x_journal_identifier.FIRST..x_journal_identifier.LAST
			UPDATE
				xxgenai_gl_je_reseng_int_stg
			SET
				last_update_date = SYSDATE,
				load_status = G_FLAG_E,
				error_message = error_message||'Unbalanced amount for Journal Batch: '||x_journal_identifier(i).journal_identifier||' - ',
				error_scope = 'VALIDATION',
				record_status = 'ERROR'
			WHERE 1=1
				AND oic_instance_id = p_oic_instance_id
				AND batch_id = p_batch_id
				AND journal_batch_name = x_journal_identifier(i).journal_identifier
				AND file_name = p_file_name
			;
		COMMIT;

	END IF;

	dbms_output.put_line('after journal batch update: '||SYSTIMESTAMP);

EXCEPTION WHEN OTHERS THEN
	p_status_out := G_FLAG_E;
	p_err_msg_out := SUBSTR(SQLERRM,1,200);	

END validate_records_proc;

PROCEDURE update_import_status
(
	p_error_recs IN t_error_recs,
	p_oic_instance_id IN VARCHAR2,
	p_ledger_id IN NUMBER,
	p_load_status IN VARCHAR2,
	p_error_message IN VARCHAR2,
	p_error_scope IN VARCHAR2,
	p_record_status IN VARCHAR2,
	p_type IN VARCHAR2,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
)
IS

	TYPE r_err_updates IS RECORD
	(
		record_id 		xxgenai_gl_je_reseng_int_stg.record_id%TYPE,
		error_code 		xxgenai_gl_je_reseng_int_stg.error_code%TYPE,
		error_message 	xxgenai_gl_je_reseng_int_stg.error_message%TYPE
	);

	TYPE t_err_updates IS TABLE OF r_err_updates;

	x_err_updates t_err_updates := t_err_updates();
	x_counter NUMBER := 0;
	x_error_message xxgenai_gl_je_reseng_int_stg.error_message%TYPE;

BEGIN
	p_status_out := G_FLAG_S;
	p_err_msg_out := NULL;

	IF p_type = 'NO_BI'
	THEN

		UPDATE
			xxgenai_gl_je_reseng_int_stg
		SET
			last_update_date = SYSDATE,
			load_status = p_load_status,
			error_message = p_error_message,
			error_scope = p_error_scope,
			record_status = p_record_status
		WHERE 1=1
			AND oic_instance_id = p_oic_instance_id
			AND ledger_id = p_ledger_id
			AND load_status = G_FLAG_V
		;

	ELSE
		IF p_error_recs.COUNT > 0
		THEN
			FOR i IN p_error_recs.FIRST..p_error_recs.LAST
			LOOP
				x_error_message := NULL;
				BEGIN
					SELECT
						LISTAGG(description,'; ')
					INTO
						x_error_message
					FROM
						xxgenai_fah_fnd_lookup_values
					WHERE 1=1
						AND lookup_type = G_ERROR_CODES_LOOKUP
						AND meaning IN (
								SELECT REGEXP_SUBSTR(str, '[^,]+', 1, LEVEL) AS error_codes
								FROM (SELECT p_error_recs(i).status str FROM dual)
								CONNECT BY LEVEL <= LENGTH(REGEXP_REPLACE(str, '[^,]+')) + 1
							)
					;

				EXCEPTION WHEN OTHERS THEN
					x_error_message := NULL;

				END;

				x_counter := x_counter + 1;
				x_err_updates.extend();
				x_err_updates(x_counter).record_id := p_error_recs(i).attribute3;
				x_err_updates(x_counter).error_code := REPLACE(p_error_recs(i).status,',','; ');
				x_err_updates(x_counter).error_message := x_error_message;

			END LOOP;

			FORALL i IN x_err_updates.FIRST..x_err_updates.LAST
				UPDATE xxgenai_gl_je_reseng_int_stg
				SET
					last_update_date = SYSDATE,
					load_status = p_load_status,
					record_status = p_record_status,
					error_code = x_err_updates(i).error_code,
					error_message = x_err_updates(i).error_message,
					error_scope = p_error_scope
				WHERE 1=1
					AND oic_instance_id = p_oic_instance_id
					AND ledger_id = p_ledger_id
					AND record_id = x_err_updates(i).record_id
				;

			COMMIT;

		END IF;
	END IF;

	COMMIT;


EXCEPTION WHEN OTHERS THEN
	p_status_out := G_FLAG_E;
	p_err_msg_out := SUBSTR(SQLERRM,1,200);	

END update_import_status;

PROCEDURE reprocess_records
(
	p_oic_instance_id IN VARCHAR2,
	p_file_name IN VARCHAR2,
	p_reprocess_days IN NUMBER,
	p_status_out OUT VARCHAR2,
	p_err_msg_out OUT VARCHAR2
)
IS
	x_oic_instance_id xxgenai_gl_je_reseng_int_stg.oic_instance_id%TYPE;

BEGIN
	p_status_out := G_FLAG_S;
	p_err_msg_out := NULL;

	IF p_file_name IS NOT NULL
	THEN
		BEGIN
			SELECT
				oic_instance_id
			INTO
				x_oic_instance_id
			FROM
				xxgenai_gl_je_reseng_int_stg
			WHERE 1=1
				AND file_name = p_file_name
				AND last_update_date = (SELECT MAX(last_update_date) FROM xxgenai_gl_je_reseng_int_stg WHERE file_name = p_file_name)
			GROUP BY
				oic_instance_id
			;
		EXCEPTION WHEN OTHERS THEN
			x_oic_instance_id := NULL;

		END;

		UPDATE
			xxgenai_gl_je_reseng_int_stg
		SET
			last_update_date = SYSDATE,
			load_status = G_FLAG_N,
			record_status = 'NEW',
			error_message = NULL,
			error_scope = NULL,
			error_code = NULL,
			oic_instance_id = p_oic_instance_id
		WHERE 1=1
			AND oic_instance_id = x_oic_instance_id
			AND file_name = p_file_name
			AND load_status IN (G_FLAG_E,G_FLAG_V,G_FLAG_N)
		;

		COMMIT;

	ELSE
		UPDATE
			xxgenai_gl_je_reseng_int_stg
		SET
			last_update_date = SYSDATE,
			load_status = G_FLAG_N,
			record_status = 'NEW',
			error_message = NULL,
			error_scope = NULL,
			error_code = NULL,
			oic_instance_id = p_oic_instance_id
		WHERE 1=1
			AND load_status IN (G_FLAG_E,G_FLAG_V,G_FLAG_N)
			AND last_update_date > TRUNC(SYSDATE) - p_reprocess_days
		;

		COMMIT;

	END IF;

EXCEPTION WHEN OTHERS THEN
	p_status_out := G_FLAG_E;
	p_err_msg_out := SUBSTR(SQLERRM,1,200);	

END reprocess_records;

END xxgenai_gl_je_reseng_int_pkg;