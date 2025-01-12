SET DEFINE OFF;
/*=====================================================*/
    /* PACKAGE BODY XX_APEX_GET_RECON_REPORT_PKG */
/*=====================================================*/
create or replace PACKAGE BODY  "XX_APEX_GET_RECON_REPORT_PKG" IS    
    
procedure get_recon_report (    
   p_integration_run_id in number default null,    
   p_integration_activity_id in number   default null,    
   p_integration_master_id in number   default null,    
   p_request_id in varchar2   default null)     
   IS    
    
  x_xml_output XMLTYPE;    
  v_max_time DATE;    
  v_count NUMBER;    
      
	x_max_date       DATE;    
	x_job_date       VARCHAR2(100);    
	x_date_syntx     VARCHAR2(100);    
        
V_QUERY CLOB := NULL;    
    
CURSOR c_check_recon_data_exist is    
select count(1) from     
XX_IMD_RECON_REPORT_DATA_T    
where nvl(integration_run_id,-1) = nvl(p_integration_run_id,-1) /*OR nvl(integration_activity_id,-1) = nvl(p_integration_activity_id,-1)*/;    
    
    
CURSOR c_check_recon_report_query is    
select replace(query||QUERY1||QUERY2,'v_request_id',''''||p_request_id || '''') from     
XX_IMD_RECON_REPORT_MASTER_T    
where integration_master_id = p_integration_master_id;    
    
BEGIN    
  
  
  IF p_request_id IS NOT NULL THEN       
    OPEN c_check_recon_data_exist ;    
        FETCH c_check_recon_data_exist INTO v_count;    
    CLOSE c_check_recon_data_exist;    
            
    IF (v_count = 0 ) THEN    
        
            OPEN c_check_recon_report_query ;    
                FETCH c_check_recon_report_query INTO V_QUERY;    
            CLOSE c_check_recon_report_query;    
        
             
            BEGIN    
    
            /*SELECT xml_output     
              INTO x_xml_output     
              FROM xx_interm_xml_output      
             WHERE ROWNUM=1;  */  
              XX_APEX_GEN_RUN_REP_PKG.main(V_QUERY,x_xml_output);    
    
            EXCEPTION    
              WHEN OTHERS    
               THEN    
                x_xml_output:= NULL;    
            END;	   
        
   FOR cur_rec IN (    
      SELECT xt.*    
      FROM   XMLTABLE('/ROWSET/ROW'    
               PASSING x_xml_output    
               COLUMNS     
                 RECORD_STATUS VARCHAR2(100) PATH 'RECORD_STATUS',    
                 ATTRIBUTE1 VARCHAR2(100) PATH 'ATTRIBUTE1',    
                 ATTRIBUTE2 VARCHAR2(100) PATH 'ATTRIBUTE2',    
                 ATTRIBUTE3 VARCHAR2(100) PATH 'ATTRIBUTE3',    
                 ATTRIBUTE4     VARCHAR2(100) PATH 'ATTRIBUTE4',    
                 ATTRIBUTE5          VARCHAR2(100) PATH 'ATTRIBUTE5',     
                 ATTRIBUTE6     VARCHAR2(100) PATH 'ATTRIBUTE6',          
                 ATTRIBUTE7     VARCHAR2(100) PATH 'ATTRIBUTE7',     
                 ATTRIBUTE8     VARCHAR2(100) PATH 'ATTRIBUTE8',    
                 ATTRIBUTE9     VARCHAR2(100) PATH 'ATTRIBUTE9',    
                 ATTRIBUTE10     VARCHAR2(100) PATH 'ATTRIBUTE10',    
                 ATTRIBUTE11     VARCHAR2(100) PATH 'ATTRIBUTE11',    
                 ATTRIBUTE12     VARCHAR2(100) PATH 'ATTRIBUTE12',    
                 ATTRIBUTE13     VARCHAR2(100) PATH 'ATTRIBUTE13',    
                 ATTRIBUTE14     VARCHAR2(100) PATH 'ATTRIBUTE14',    
                 ATTRIBUTE15     VARCHAR2(100) PATH 'ATTRIBUTE15',    
                 ATTRIBUTE16     VARCHAR2(100) PATH 'ATTRIBUTE16',    
                 ATTRIBUTE17     VARCHAR2(100) PATH 'ATTRIBUTE17',    
                 ATTRIBUTE18     VARCHAR2(100) PATH 'ATTRIBUTE18',    
                 ATTRIBUTE19     VARCHAR2(100) PATH 'ATTRIBUTE19',    
                 ATTRIBUTE20     VARCHAR2(100) PATH 'ATTRIBUTE20',    
                 ATTRIBUTE21     VARCHAR2(100) PATH 'ATTRIBUTE21',    
                 ATTRIBUTE22     VARCHAR2(100) PATH 'ATTRIBUTE22',    
                 ATTRIBUTE23     VARCHAR2(100) PATH 'ATTRIBUTE23',    
                 ATTRIBUTE24     VARCHAR2(100) PATH 'ATTRIBUTE24',    
                 ATTRIBUTE25     VARCHAR2(100) PATH 'ATTRIBUTE25',    
                 ATTRIBUTE26     VARCHAR2(100) PATH 'ATTRIBUTE26',         
                 ATTRIBUTE27     VARCHAR2(100) PATH 'ATTRIBUTE27',         
                 ATTRIBUTE28     VARCHAR2(100) PATH 'ATTRIBUTE28',         
                 ATTRIBUTE29     VARCHAR2(100) PATH 'ATTRIBUTE29',              
                 ERROR_DESCRIPTION VARCHAR2(1000) PATH 'ERROR_DESCRIPTION'    
               ) xt)    
      LOOP    
	  	      
	  INSERT INTO  XX_IMD_RECON_REPORT_DATA_T    
          (ID,    
           INTEGRATION_RUN_ID,    
           RECORD_STATUS,ATTRIBUTE1 ,ATTRIBUTE2 ,ATTRIBUTE3 ,ATTRIBUTE4 ,ATTRIBUTE5 ,ATTRIBUTE6 ,    
           ATTRIBUTE7 ,ATTRIBUTE8 ,ATTRIBUTE9 ,ATTRIBUTE10 ,ATTRIBUTE11 ,ATTRIBUTE12 ,ATTRIBUTE13 ,ATTRIBUTE14 ,ATTRIBUTE15 ,ATTRIBUTE16 ,    
           ATTRIBUTE17,ATTRIBUTE18 ,ATTRIBUTE19 ,ATTRIBUTE20 ,ATTRIBUTE21 ,ATTRIBUTE22 ,ATTRIBUTE23 ,ATTRIBUTE24 ,ATTRIBUTE25 ,ATTRIBUTE26 ,ATTRIBUTE27 ,ATTRIBUTE28 ,    
           ATTRIBUTE29,CREATED_BY,CREATED_DATE,UPDATED_BY,UPDATED_DATE ,REQUEST_ID, ERROR_DESCRIPTION)    
      VALUES (XX_IMD_RECON_REPORT_DATA_S.NEXTVAL,p_integration_run_id,cur_rec.RECORD_STATUS,cur_rec.ATTRIBUTE1,cur_rec.ATTRIBUTE2,cur_rec.ATTRIBUTE3,cur_rec.ATTRIBUTE4,    
			cur_rec.ATTRIBUTE5,cur_rec.ATTRIBUTE6,cur_rec.ATTRIBUTE7,cur_rec.ATTRIBUTE8,cur_rec.ATTRIBUTE9,cur_rec.ATTRIBUTE10,cur_rec.ATTRIBUTE11,cur_rec.ATTRIBUTE12,cur_rec.ATTRIBUTE13,cur_rec.ATTRIBUTE14,cur_rec.ATTRIBUTE15,cur_rec.ATTRIBUTE16,cur_rec.ATTRIBUTE17,cur_rec.ATTRIBUTE18,  
              cur_rec.ATTRIBUTE19,cur_rec.ATTRIBUTE20,cur_rec.ATTRIBUTE21,cur_rec.ATTRIBUTE22,cur_rec.ATTRIBUTE23,cur_rec.ATTRIBUTE24,cur_rec.ATTRIBUTE25,cur_rec.ATTRIBUTE26,cur_rec.ATTRIBUTE27,cur_rec.ATTRIBUTE28,cur_rec.ATTRIBUTE29,  
              'xx03357',SYSDATE,'xx03357',sysdate,p_request_id, cur_rec.ERROR_DESCRIPTION);    
          
           
      COMMIT;    
     END LOOP;    
         
    END IF;    
    END IF;    
EXCEPTION  
WHEN OTHERS THEN  
NULL;  
END get_recon_report;    
  
procedure get_recon_report_file (    
   p_recon_id in number,  
   p_clob_file_data in CLOB,  
   p_mime_type in varchar2  
   ) IS   
     x_out_bl         BLOB;   
    x_clob_size      NUMBER;   
    x_pos            NUMBER;   
    x_charbuff       VARCHAR2(32767);   
    x_dbuffer        RAW(32767);   
    x_readsize_nr    NUMBER;   
    x_line_nr        NUMBER;   
    x_err_msg        VARCHAR2(1000);   
     
  
  
  BEGIN   
     
    dbms_lob.createTemporary(x_out_bl, TRUE, dbms_lob.CALL);   
    x_line_nr    := GREATEST(65,INSTR(p_clob_file_data,CHR(10)),INSTR(p_clob_file_data,CHR(13)));   
    x_readsize_nr:= FLOOR(32767/x_line_nr)*x_line_nr;   
    x_clob_size  := dbms_lob.getLength(p_clob_file_data);   
    x_pos := 1;   
     
    WHILE (x_pos < x_clob_size)    
	     
	  LOOP   
	     
      dbms_lob.READ(p_clob_file_data, x_readsize_nr, x_pos, x_charbuff);   
      x_dbuffer := utl_encode.base64_decode(utl_raw.cast_to_raw(x_charbuff));   
      dbms_lob.writeAppend(x_out_bl,utl_raw.LENGTH(x_dbuffer),x_dbuffer);   
      x_pos := x_pos + x_readsize_nr;   
         
	  END LOOP;   
       
  
  
    UPDATE XX_IMD_INTEGRATION_RUN_T   
       SET FILE_DATA = x_out_bl ,  
           MIME_TYPE = p_mime_type,  
           LINK_NAME = id || '.zip'  
     WHERE RECON_ID = p_recon_id   
         ;   
        COMMIT;  
  
     
  EXCEPTION   
    WHEN OTHERS   
      THEN   
		x_err_msg :=SQLCODE||SQLERRM;   
	    DBMS_OUTPUT.PUT_LINE(x_err_msg);  
		  
    
END get_recon_report_file;    
     
  
    
END XX_APEX_GET_RECON_REPORT_PKG;
/