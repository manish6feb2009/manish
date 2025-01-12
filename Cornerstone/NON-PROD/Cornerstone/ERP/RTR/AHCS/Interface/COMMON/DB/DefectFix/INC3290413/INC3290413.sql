create table wsc_gl_legal_entities_t_bkp_INC3290413 as select * from wsc_gl_legal_entities_t where flex_segment_value=5071;
update  wsc_gl_legal_entities_t set legal_entity_name='Rahi Systems Ltd. (UK)',legal_entity_id='300000392000919' where flex_segment_value=5071;
commit;
/