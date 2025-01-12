declare
p_clob_file_data1 CLOB := '77u/TEVER0VSLFRSQU5TQUNUSU9OX05VTUJFUixUUkFOU0FDVElPTl9EQVRFLFRSQU5TQUNUSU9OX1JFVkVSU0FMX0ZMQUcsSU5WQUxJRF9IRUFERVIsTElORV9OVU1CRVIsRVJST1JfTUVTU0FHRQ0K';

p_mime_type varchar2(100) := 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

x_out_bl BLOB;
x_clob_size NUMBER;
x_pos NUMBER;
x_charbuff VARCHAR2(32767);
x_dbuffer RAW(32767);
x_readsize_nr NUMBER;
x_line_nr NUMBER;
x_err_msg VARCHAR2(1000);



BEGIN

dbms_lob.createTemporary(x_out_bl, TRUE, dbms_lob.CALL);
x_line_nr := GREATEST(65,INSTR(p_clob_file_data1,CHR(10)),INSTR(p_clob_file_data1,CHR(13)));
x_readsize_nr:= FLOOR(32767/x_line_nr)*x_line_nr;
x_clob_size := dbms_lob.getLength(p_clob_file_data1);
x_pos := 1;

WHILE (x_pos < x_clob_size)

LOOP

dbms_lob.READ(p_clob_file_data1, x_readsize_nr, x_pos, x_charbuff);
x_dbuffer := utl_encode.base64_decode(utl_raw.cast_to_raw(x_charbuff));
dbms_lob.writeAppend(x_out_bl,utl_raw.LENGTH(x_dbuffer),x_dbuffer);
x_pos := x_pos + x_readsize_nr;

END LOOP;

delete from WSC_AHCS_PURGE_DATA_TEMPLATE_T where id = 1;
commit;

insert into WSC_AHCS_PURGE_DATA_TEMPLATE_T(ID)values(1);

UPDATE WSC_AHCS_PURGE_DATA_TEMPLATE_T
SET BLOB_DATA = x_out_bl ,
MIME_TYPE = p_mime_type
WHERE ID = 1;
COMMIT;


EXCEPTION
WHEN OTHERS
THEN
x_err_msg :=SQLCODE||SQLERRM;
DBMS_OUTPUT.PUT_LINE(x_err_msg);


END ;
/