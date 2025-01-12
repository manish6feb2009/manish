SET DEFINE OFF;
/*=====================================================*/
    /* PACKAGE BODY XX_APEX_SOAP_SERVICE_CALL_PKG */
/*=====================================================*/
create or replace PACKAGE BODY  "XX_APEX_SOAP_SERVICE_CALL_PKG"  
AS    
    
      
   /* Procedure to log common error messages */    
       
   PROCEDURE error_log ( x_procedure_name VARCHAR2,    
                         x_err_msg        VARCHAR2    
					   )	    
   AS    
   BEGIN    
   INSERT INTO xx_common_err_log_tbl ( error_in_procedure    
                                     , error_message    
									 , error_log_date    
									 )    
							VALUES   ( x_procedure_name    
                                     , x_err_msg    
                                     , SYSDATE    
                                     );									     
    COMMIT;       
       
   END;    
      
  /* Function to convert base64 encoded clob data into blob */    
    
  FUNCTION base64DecodeClobAsBlob(p_data_cl CLOB)     
  RETURN BLOB IS    
      
    x_out_bl         BLOB;    
    x_clob_size      NUMBER;    
    x_pos            NUMBER;    
    x_charbuff       VARCHAR2(32767);    
    x_dbuffer        RAW(32767);    
    x_readsize_nr    NUMBER;    
    x_line_nr        NUMBER;    
	x_proc_name      VARCHAR2(200):= 'xx_apex_soap_service_call_pkg.base64DecodeClobAsBlob';    
    x_err_msg        VARCHAR2(1000);    
      
  BEGIN    
      
    dbms_lob.createTemporary(x_out_bl, TRUE, dbms_lob.CALL);    
    x_line_nr    := GREATEST(65,INSTR(p_data_cl,CHR(10)),INSTR(p_data_cl,CHR(13)));    
    x_readsize_nr:= FLOOR(32767/x_line_nr)*x_line_nr;    
    x_clob_size  := dbms_lob.getLength(p_data_cl);    
    x_pos := 1;    
      
    WHILE (x_pos < x_clob_size)     
	      
	  LOOP    
	      
      dbms_lob.READ(p_data_cl, x_readsize_nr, x_pos, x_charbuff);    
      x_dbuffer := utl_encode.base64_decode(utl_raw.cast_to_raw(x_charbuff));    
      dbms_lob.writeAppend(x_out_bl,utl_raw.LENGTH(x_dbuffer),x_dbuffer);    
      x_pos := x_pos + x_readsize_nr;    
          
	  END LOOP;    
        
	RETURN x_out_bl;    
    dbms_lob.freetemporary(x_out_bl);    
      
  EXCEPTION    
    WHEN OTHERS    
      THEN    
		x_err_msg :=SQLCODE||SQLERRM;    
	    error_log(x_proc_name,x_err_msg);    
		RETURN NULL;    
  END base64DecodeClobAsBlob;    
      
  /* Procedure to convert blob data into xmltype data */    
      
  PROCEDURE convert_blob_to_xmltype( p_blob_in IN BLOB    
                                   , p_proc_name IN VARCHAR2    
								   )    
  AS    
      
  x_clob      CLOB;    
  x_varchar   VARCHAR2(32767);    
  x_start     PLS_INTEGER := 1;    
  x_buffer    PLS_INTEGER := 32767;    
  x_blob_in   BLOB;    
  x_out       XMLTYPE;    
  x_proc_name VARCHAR2(200) :='xx_apex_soap_service_call_pkg.convert_blob_to_xmltype';    
  x_err_msg   VARCHAR2(1000);    
      
  BEGIN    
   dbms_lob.createtemporary(x_clob, TRUE);    
       
   x_blob_in := p_blob_in;    
       
   FOR i IN 1 .. CEIL(dbms_lob.getlength(x_blob_in) / x_buffer)     
       
     LOOP    
       
     x_varchar := utl_raw.cast_to_varchar2(dbms_lob.SUBSTR(x_blob_in,    
                                                           x_buffer,    
                                                           x_start));    
       
     dbms_lob.writeappend(x_clob, LENGTH(x_varchar), x_varchar);    
       
     x_start := x_start + x_buffer;    
       
     END LOOP;    
       
     x_out := xmltype.createxml(x_clob);    
         
	 BEGIN    
       
     IF p_proc_name = 'xx_apex_soap_service_call_pkg.main'    
	 THEN    
       
     DELETE FROM xx_interm_xml_output;    
       
     INSERT INTO xx_interm_xml_output values(x_out);    
         
	 COMMIT;    
	     
	 ELSIF p_proc_name = 'xx_apex_soap_service_call_pkg.parameter_main'    
	 THEN    
	     
	 DELETE FROM xx_interm_parameter;    
       
     INSERT INTO xx_interm_parameter values(x_out);    
	     
	 COMMIT;    
	     
	 END IF;    
    	     
	 EXCEPTION     
	  WHEN OTHERS    
	     THEN    
		   x_err_msg:=SQLCODE||SQLERRM;    
		   error_log(x_err_msg,x_proc_name);    
	 END;    
       
     dbms_lob.freetemporary( x_clob );    
     
 END convert_blob_to_xmltype;    
    
    
       
  /* Main Procedure is called which internally call other function and insert the data in staging table */    
      
  PROCEDURE main (p_user_name VARCHAR2)    
  AS    
    x_envelope       CLOB;    
    x_encrypt_output CLOB;    
    x_encrypt_blob   BLOB;    
    x_xml            XMLTYPE;    
    x_xml_output     XMLTYPE;    
	x_query_job_name VARCHAR2(4000);    
	x_status         VARCHAR2(100):='SUCCEEDED';    
	x_job_status     VARCHAR2(100);    
	x_max_date       DATE;    
	x_job_date       VARCHAR2(100);    
	x_full_query     VARCHAR2(4000);    
	x_job_name       VARCHAR2(4000);    
	x_wicer_id       VARCHAR2(100);    
	x_track          VARCHAR2(100);    
	x_err_msg        VARCHAR2(4000);    
	x_proc_name      VARCHAR2(100):= 'xx_apex_soap_service_call_pkg.main';    
	x_err_flag       VARCHAR2(1):='N';    
	x_user_name      VARCHAR2(100);    
    x_password       VARCHAR2(100);    
    x_url            VARCHAR2(1000);    
	x_date_syntx     VARCHAR2(100);    
	x_req_seq        NUMBER;    
	    
    x_query    VARCHAR2(1000):= 'Select to_char(a.processstart,''dd-mon-yyyy HH24:MI:SS'') startdate,to_char(a.processend,''dd-mon-yyyy HH24:MI:SS'') enddate,a.* from request_history a where a.name in (';    
	x_date_query VARCHAR2(1000):= ' and to_date(to_char(processend,''dd-mm-yyyy HH24:MI:SS''),''dd-mm-yyyy HH24:MI:SS'') &gt; ';    
      
    BEGIN    
		    
	BEGIN	    
		    
	SELECT listagg(job_name, ''',''') within GROUP (ORDER BY job_name)     
	  INTO x_job_name     
	  FROM xx_imd_job_master_t     
	 WHERE job_type = 'C';    
	     
	EXCEPTION    
      WHEN no_data_found    
       THEN	     
	     x_err_msg:= 'No critical job records found in master table: xx_imd_job_master_t:'||SQLCODE||SQLERRM;    
         error_log(x_proc_name,x_err_msg);       
	     x_err_flag:='Y';    
	  WHEN OTHERS    
        THEN    
         x_err_msg:= SQLCODE||SQLERRM;    
         error_log(x_proc_name,x_err_msg);       
	     x_err_flag:='Y'; 		    
    END;     
    
    BEGIN    
	    
	 SELECT MAX(created_date)    
	   INTO x_max_date    
	   FROM xx_imd_job_run_t;    
	       
	EXCEPTION    
      WHEN no_data_found    
       THEN	     
	     x_err_msg:= 'Error fetching maximum created_date from table xx_imd_job_run_t :'||SQLCODE||SQLERRM;    
         error_log(x_proc_name,x_err_msg);       
	     x_err_flag:='Y';    
	  WHEN OTHERS    
        THEN    
         x_err_msg:= SQLCODE||SQLERRM;    
         error_log(x_proc_name,x_err_msg);       
	     x_err_flag:='Y';   	    
    END;     
	    
	BEGIN    
	      
	  SELECT user_name    
	       , password    
		   , url    
		INTO x_user_name    
		   , x_password    
		   , x_url    
		FROM xx_imd_details    
	   WHERE ROWNUM=1;    
	    
	EXCEPTION    
	  WHEN no_data_found    
       THEN	     
	     x_err_msg:= 'Provide valid username/password/instance url details in table xx_imd_details :'||SQLCODE||SQLERRM;    
         error_log(x_proc_name,x_err_msg);       
	     x_err_flag:='Y';    
	  WHEN OTHERS    
        THEN    
         x_err_msg:= SQLCODE||SQLERRM;    
         error_log(x_proc_name,x_err_msg);       
	     x_err_flag:='Y';       
	END;    
	    
	 IF x_err_flag = 'N'    
	 THEN    
	    
	 x_query_job_name := ''''||x_job_name||''''||')';    
	 x_job_status:= ''''||x_status||'''';    
	 x_job_date:= ''''||TO_CHAR(x_max_date,'DD-MM-YYYY HH24:MI:SS')||'''';    
	 x_date_syntx := ''''||'DD-MM-YYYY HH24:MI:SS'||'''';    
--	 x_full_query := x_query||x_query_job_name||' and executable_status != '||x_job_status||x_date_query||x_job_date;    
	 x_full_query := x_query||x_query_job_name||' and executable_status != '||x_job_status||x_date_query||'to_date('||x_job_date||','||x_date_syntx||')';    
    
      
    --Assigning SOAP Enevelope value    
    x_envelope := '<soap:Envelope xmlns:pub="http://xmlns.oracle.com/oxp/service/PublicReportService" xmlns:soap="http://www.w3.org/2003/05/soap-envelope">    
       <soap:Header/>    
       <soap:Body>    
          <pub:runReport>    
             <pub:reportRequest>    
                <pub:attributeFormat>xml</pub:attributeFormat>    
                                               <pub:parameterNameValues>    
                   <!--Zero or more repetitions:-->    
                    <pub:item>	    
                      <pub:name>query1</pub:name>    
                     <pub:values>    
                         <!--Zero or more repetitions:-->    
                         <pub:item>'||x_full_query||'</pub:item>    
                      </pub:values>    
                   </pub:item>    
                </pub:parameterNameValues>     
                <pub:reportAbsolutePath>/Custom/QueryCloud/QueryCloudReport.xdo</pub:reportAbsolutePath>    
                <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload>    
             </pub:reportRequest>    
             <pub:userID>'||x_user_name||'</pub:userID>    
             <pub:password>'||x_password||'</pub:password>    
          </pub:runReport>    
       </soap:Body>    
    </soap:Envelope>';    
      
       x_xml := apex_web_service.make_request( p_url      =>  x_url,    
                                               p_action   =>  'http://xmlns.oracle.com/oxp/service/PublicReportService/runReportRequest',    
                                               p_username =>  x_user_name,    
                                               p_password =>  x_password,    
                                               p_envelope =>  x_envelope     
  										   );    
  	    
  	    
  	   x_encrypt_output := apex_web_service.parse_xml_clob( p_xml   => x_xml,    
                                                            p_xpath => ' //runReportResponse/runReportReturn/reportBytes/text()',    
                                                            p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'    
  											              );     
          
      
       x_encrypt_blob:= base64DecodeClobAsBlob(x_encrypt_output);    
  	    
  	   convert_blob_to_xmltype(x_encrypt_blob,x_proc_name);    
  	    
  	BEGIN    
	    
  	SELECT xml_output     
  	  INTO x_xml_output     
  	  FROM xx_interm_xml_output      
  	 WHERE ROWNUM=1;    
  	    
    EXCEPTION    
      WHEN OTHERS    
	   THEN    
	    x_xml_output:= NULL;    
    END;    
    
    x_req_seq := xx_req_seq.NEXTVAL; 	    
  	    
      FOR cur_rec IN (    
      SELECT xt.*    
      FROM   XMLTABLE('/ROWSET/ROW'    
               PASSING x_xml_output    
               COLUMNS     
                 REQUESTID     VARCHAR2(100) PATH 'REQUESTID',    
                 NAME          VARCHAR2(100) PATH 'NAME',     
                 STARTDATE     VARCHAR2(100) PATH 'STARTDATE',    
				 ENDDATE       VARCHAR2(100) PATH 'ENDDATE',    
				 EXECUTABLE_STATUS VARCHAR2(100) PATH 'EXECUTABLE_STATUS',    
				 REDIRECTEDOUTPUTFILE VARCHAR2(1000) PATH 'REDIRECTEDOUTPUTFILE',    
				 SUBMITTER  VARCHAR2(100) PATH 'SUBMITTER',    
				 PROCESSPHASE VARCHAR2(100) PATH 'PROCESSPHASE'    
               ) xt)    
      LOOP    
	  	      
	  BEGIN    
	      
	  SELECT track    
	       , wicer_id    
	    INTO x_track    
		   , x_wicer_id    
	    FROM xx_imd_job_master_t    
	   WHERE job_name = cur_rec.name    
	     AND ROWNUM=1;    
	       
	   EXCEPTION    
	     WHEN OTHERS     
		  THEN    
		   x_track    := NULL;    
		   x_wicer_id := NULL;    
           
	   END;    
    
       INSERT INTO xx_imd_job_run_t( request_id    
	                               , program_name    
                                   , actual_start_date    
                                   , actual_end_date    
                                   , status    
								   , log_file_path    
								   , submitted_by    
								   , track    
								   , job_type    
								   , phase_code    
								   , wicer_id    
								   , req_sequence    
								   , created_date    
								   , updated_date    
								   , created_by    
								   , updated_by    
								   )     
	                        VALUES(  cur_rec.requestid    
  	                              ,  cur_rec.name    
                                  ,  TO_DATE(cur_rec.startdate,'DD-MM-YYYY HH24:MI:SS')    
			                      ,  TO_DATE(cur_rec.enddate,'DD-MM-YYYY HH24:MI:SS')    
			                      ,  cur_rec.executable_status    
			                      ,  cur_rec.redirectedoutputfile    
			                      ,  cur_rec.submitter    
			                      ,  x_track    
			                      ,  'C'    
			                      ,  cur_rec.processphase    
			                      ,  x_wicer_id    
								  ,  x_req_seq    
			                      ,  SYSDATE    
			                      ,  SYSDATE    
								  ,  p_user_name    
								  ,  p_user_name    
			                      );    
      COMMIT;    
    END LOOP;	    
END IF;	    
END main;    
    
PROCEDURE parameter_main( p_user_name VARCHAR2    
                       --  , p_request_id NUMBER    
						  )    
AS    
    x_envelope       CLOB;    
    x_encrypt_output CLOB;    
    x_encrypt_blob   BLOB;    
    x_xml            XMLTYPE;    
    x_xml_output     XMLTYPE;    
	x_request_id_cnt NUMBER;    
	x_max_req_seq    NUMBER;    
	x_parent_job_seq NUMBER;    
	x_full_query     VARCHAR2(4000);    
	x_err_msg        VARCHAR2(4000);    
	x_proc_name      VARCHAR2(100):= 'xx_apex_soap_service_call_pkg.parameter_main';    
	x_err_flag       VARCHAR2(1):='N';    
	x_user_name      VARCHAR2(100);    
    x_password       VARCHAR2(100);    
    x_url            VARCHAR2(1000);    
    x_query          VARCHAR2(1000):= 'Select name,requestid,value from fusion_ora_ess.request_property_view where value is not null and name like ';    
	x_sub_query      VARCHAR2(1000):= 'submit.argument%';    
	x_reqst_query    VARCHAR2(1000):= ' and requestid in(';    
	x_request_strng  VARCHAR2(4000);    
    
    
    BEGIN    
	    
	BEGIN    
	      
	  SELECT user_name    
	       , password    
		   , url    
		INTO x_user_name    
		   , x_password    
		   , x_url    
		FROM xx_imd_details    
	   WHERE ROWNUM=1;    
	    
	EXCEPTION    
	  WHEN no_data_found    
       THEN	     
	     x_err_msg:= 'Provide valid username/password/instance url details in table xx_imd_details :'||SQLCODE||SQLERRM;    
         error_log(x_proc_name,x_err_msg);       
	     x_err_flag:='Y';    
	  WHEN OTHERS    
        THEN    
         x_err_msg:= SQLCODE||SQLERRM;    
         error_log(x_proc_name,x_err_msg);       
	     x_err_flag:='Y';       
	END;    
	      
	  SELECT MAX(req_sequence)    
		INTO x_max_req_seq    
		FROM xx_imd_job_run_t;    
		    
	  SELECT MAX(parent_job_seq)    
	    INTO x_parent_job_seq    
	    FROM xx_interm_job_parameter;    
		    
    IF x_max_req_seq = x_parent_job_seq    
    THEN    
      NULL;    
    ELSE	      
	      
	   SELECT listagg(request_id, ''',''') within GROUP (ORDER BY request_id)    
	     INTO x_request_strng     
	     FROM xx_imd_job_run_t     
	    WHERE req_sequence = x_max_req_seq;    
	    
	 IF x_err_flag = 'N'    
	 THEN    
	    
	 x_full_query := x_query||''''||x_sub_query||''''||x_reqst_query||''''||x_request_strng||''''||')';    
    
      
    --Assigning SOAP Enevelope value    
    x_envelope := '<soap:Envelope xmlns:pub="http://xmlns.oracle.com/oxp/service/PublicReportService" xmlns:soap="http://www.w3.org/2003/05/soap-envelope">    
       <soap:Header/>    
       <soap:Body>    
          <pub:runReport>    
             <pub:reportRequest>    
                <pub:attributeFormat>xml</pub:attributeFormat>    
                                               <pub:parameterNameValues>    
                   <!--Zero or more repetitions:-->    
                    <pub:item>	    
                      <pub:name>query1</pub:name>    
                     <pub:values>    
                         <!--Zero or more repetitions:-->    
                         <pub:item>'||x_full_query||'</pub:item>    
                      </pub:values>    
                   </pub:item>    
                </pub:parameterNameValues>     
                <pub:reportAbsolutePath>/Custom/QueryCloud/QueryCloudReport.xdo</pub:reportAbsolutePath>    
                <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload>    
             </pub:reportRequest>    
             <pub:userID>'||x_user_name||'</pub:userID>    
             <pub:password>'||x_password||'</pub:password>    
          </pub:runReport>    
       </soap:Body>    
    </soap:Envelope>';    
      
       x_xml := apex_web_service.make_request( p_url      =>  x_url,    
                                               p_action   =>  'http://xmlns.oracle.com/oxp/service/PublicReportService/runReportRequest',    
                                               p_username =>  x_user_name,    
                                               p_password =>  x_password,    
                                               p_envelope =>  x_envelope     
  										   );    
  	    
  	    
  	   x_encrypt_output := apex_web_service.parse_xml_clob( p_xml   => x_xml,    
                                                            p_xpath => ' //runReportResponse/runReportReturn/reportBytes/text()',    
                                                            p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'    
  											              );     
          
      
       x_encrypt_blob:= base64DecodeClobAsBlob(x_encrypt_output);    
  	    
  	   convert_blob_to_xmltype(x_encrypt_blob,x_proc_name);    
  	    
  	BEGIN    
	    
  	SELECT xml_output     
  	  INTO x_xml_output     
  	  FROM xx_interm_parameter      
  	 WHERE ROWNUM=1;    
  	    
    EXCEPTION    
      WHEN OTHERS    
	   THEN    
	    x_xml_output:= NULL;    
    END;	    
      
  /*  SELECT COUNT(*)    
	  INTO x_request_id_cnt    
	  FROM xx_interm_job_parameter    
	  WHERE requestid = p_request_id;    
	      
	  IF x_request_id_cnt =0    
	  THEN   */    
      
      FOR cur_rec IN (    
      SELECT xt.*    
      FROM   XMLTABLE('/ROWSET/ROW'    
               PASSING x_xml_output    
               COLUMNS     
                 NAME      VARCHAR2(1000) PATH 'NAME',    
                 REQUESTID VARCHAR2(100)  PATH 'REQUESTID',     
                 VALUE     VARCHAR2(100)  PATH 'VALUE'    
               ) xt)    
      LOOP    
          
      INSERT INTO xx_interm_job_parameter (name,    
	                                       requestid,    
                                           value,    
										   parent_job_seq,    
										   creation_date,    
										   last_update_date,    
										   created_by    
								          )     
	  VALUES(cur_rec.name,    
  	         cur_rec.requestid,    
			 cur_rec.value,    
			 x_max_req_seq,    
			 sysdate,    
			 sysdate,    
			 p_user_name    
			 );    
      COMMIT;    
        
    END LOOP;    
 --END IF;	    
END IF;	    
    
END IF;     
END parameter_main;    
    
END xx_apex_soap_service_call_pkg;
/