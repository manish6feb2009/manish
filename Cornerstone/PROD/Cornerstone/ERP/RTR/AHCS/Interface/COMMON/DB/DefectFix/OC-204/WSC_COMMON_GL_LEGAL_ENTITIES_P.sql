create or replace PROCEDURE WSC_GL_LEGAL_ENTITIES_P (
        p_wsc_gl_legal_entity_value_insert   IN     wsc_gl_legal_entities_value_t_type_table,
        p_rice_code                          IN     VARCHAR2,
        p_error_code                     OUT VARCHAR2,
        p_error_message                  OUT VARCHAR2)
    IS
        lv_error_code      VARCHAR2 (4000) := NULL;
        lv_error_message   VARCHAR2 (4000) := NULL;
        
    BEGIN
        BEGIN
            IF p_wsc_gl_legal_entity_value_insert.COUNT > 0
            THEN
                FORALL wsc_gl_le_insert_new_rec
                    IN p_wsc_gl_legal_entity_value_insert.FIRST ..
                       p_wsc_gl_legal_entity_value_insert.LAST
                       SAVE EXCEPTIONS
                       MERGE INTO wsc_gl_legal_entities_t  a
                           USING (SELECT p_wsc_gl_legal_entity_value_insert(wsc_gl_le_insert_new_rec).flex_segment_value  flex_segment_value,
                                         p_wsc_gl_legal_entity_value_insert(wsc_gl_le_insert_new_rec).legal_entity_id  legal_entity_id,
                                         p_wsc_gl_legal_entity_value_insert(wsc_gl_le_insert_new_rec).legal_entity_name  legal_entity_name,
                                         p_wsc_gl_legal_entity_value_insert(wsc_gl_le_insert_new_rec).ledger_id  ledger_id,
                                         p_wsc_gl_legal_entity_value_insert(wsc_gl_le_insert_new_rec).ledger_name  ledger_name,
                                         p_wsc_gl_legal_entity_value_insert(wsc_gl_le_insert_new_rec).currency_code  currency_code
                                         FROM DUAL) b
                                    ON (a.flex_segment_value = b.flex_segment_value)
                                    WHEN NOT MATCHED 
                                    THEN 
                       INSERT          (
                                    a.flex_segment_value,
									a.legal_entity_id,
									a.legal_entity_name,
									a.ledger_id,
									a.ledger_name,
									a.currency_code)
                             VALUES (
                                        b.flex_segment_value,
                                        b.legal_entity_id,
                                        b.legal_entity_name,
                                        b.ledger_id,
                                        b.ledger_name,
                                        b.currency_code
									)
									WHEN MATCHED THEN 
									UPDATE  SET
									a.legal_entity_id=b.legal_entity_id, 
									a.legal_entity_name=b.legal_entity_name, 
									a.ledger_id=b.ledger_id,
									a.ledger_name=b.ledger_name,
								    a.currency_code=b.currency_code 
									WHERE a.flex_segment_value = b.flex_segment_value; --- OC-204 (Update Statement added)
					END IF;
        COMMIT;
	-----UPDATE RERESH TABLE WITH LAST UPDATED DATE----	
		Update WSC_AHCS_REFRESH_T 
        Set LAST_REFRESH_DATE=Sysdate,
        LAST_UPDATE_DATE=Sysdate,
        LAST_UPDATED_BY='GL LE Extract Program'
        WHERE DATA_ENTITY_NAME='WSC_COMMON_GL_LE_EXTRACT';
        COMMIT;
    END;
    EXCEPTION
    WHEN OTHERS
    THEN
        p_error_code:=lv_error_code;
        p_error_message:= lv_error_message; 
         wsc_ahcs_recon_records_pkg.vlog (
               p_error_message
            || SUBSTR (SQLERRM, 1,500),
            p_error_code);
    END WSC_GL_LEGAL_ENTITIES_P;
/