SET DEFINE OFF;

create or replace PACKAGE BODY  "XX_APEX_USER_SECURITY_PKG"  
AS   
 
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
	    --error_log(x_proc_name,x_err_msg);  
		RETURN NULL;  
  END base64DecodeClobAsBlob;  
    
  /* Procedure to convert blob data into xmltype data */  
    
  PROCEDURE convert_blob_to_xmltype( p_blob_in IN BLOB,x_xml_out OUT XMLTYPE )  
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
     
    x_xml_out := x_out ; 
     /*DELETE FROM xx_interm_xml_output;  
     
     INSERT INTO xx_interm_xml_output values(x_out);  
       
	 COMMIT; */ 
	   
	 EXCEPTION   
	  WHEN OTHERS  
	     THEN  
		   x_err_msg:=SQLCODE||SQLERRM;  
--		   error_log(x_err_msg,x_proc_name);  
	 END;  
     
     dbms_lob.freetemporary( x_clob );  
   
 END convert_blob_to_xmltype;  
 
PROCEDURE main(x_out_jwt_token out VARCHAR2 ,x_out_user_name out VARCHAR2,p_user_name varchar2 )    
AS   
    x_envelope       CLOB;   
    x_encrypt_output CLOB;   
    x_encrypt_blob   BLOB;   
    x_xml            CLOB;   
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
    x_instance_url   VARCHAR2(1000); 
       
v_name varchar2(200);   
v_jwt_token  varchar2(4000) := null;   
v_user_name     VARCHAR2(4000) := NULL;   
V_QUERY CLOB := NULL;   
v_err_flag VARCHAR2(20):= 'N'; 
l_http_status_code VARCHAR2(2000); 
 
l_jwt_arr    APEX_APPLICATION_GLOBAL.VC_ARR2; 
l_prn_json varchar2(2000); 
l_clob      varchar2(32767);   
   l_body      varchar2(32767);   
   l_feature_count  pls_integer;   
   j APEX_JSON.t_values;   
   l_xml_result clob; 
   v_sqlerror VARCHAR2(100); 
    
begin   
 
   
BEGIN   
  select    
     DECODE ( instr(owa_util.get_cgi_env('QUERY_STRING'),'jwt=',1),0,null,  
         substr(owa_util.get_cgi_env('QUERY_STRING'),instr(owa_util.get_cgi_env('QUERY_STRING'),'jwt=',1)+4,length(owa_util.get_cgi_env('QUERY_STRING'))) )   
  into v_jwt_token    
  from dual;   
       
       
  l_jwt_arr:= APEX_UTIL.STRING_TO_TABLE(v_jwt_token, '.');     
   
  l_prn_json := UTL_ENCODE.TEXT_DECODE(l_jwt_arr(2), 'UTF8', UTL_ENCODE.BASE64); 
  APEX_JSON.PARSE (l_prn_json); 
  v_user_name := APEX_JSON.get_varchar2 (p_path => 'prn'); 
       
  x_out_jwt_token := v_jwt_token;   
  x_out_user_name := v_user_name;   
      
     
EXCEPTION   
 WHEN OTHERS THEN   
     x_out_jwt_token := NULL;   
     x_out_user_name := NULL;   
     v_err_flag := 'Y';   
     v_sqlerror := sqlerrm; 
      
END;  
 

 
 if v_user_name is not null then
BEGIN  
	    
	  SELECT user_name  
	       ,(replace(password, '&', '&amp;')) 
	       --, password  
		   , url  
		INTO x_user_name  
		   , x_password  
		   , x_url  
		FROM xx_imd_details  
	   WHERE ROWNUM=1;  
	  
      
	EXCEPTION  
	  WHEN no_data_found  
       THEN	   
	     x_err_flag:='Y';  
	  WHEN OTHERS  
        THEN  
	     x_err_flag:='Y';     
	END;  
 
 
IF v_err_flag = 'N' THEN     
   BEGIN   
     
     l_body := '{ "p_username":"'|| upper(v_user_name) ||'", "p_token":"Bearer '|| v_jwt_token ||'" }';   
 
     dbms_output.put_line(l_body);   
      
     apex_web_service.g_request_headers.delete();   
        apex_web_service.g_request_headers(1).name := 'Content-Type';   
        apex_web_service.g_request_headers(1).value := 'application/json';   
      
      
    l_clob := apex_web_service.make_rest_request(   
        p_url => x_url || ':443/ic/api/integration/v1/flows/rest/WESCO_WSC_GBL_DP_USER_AUTHE/1.0/authUser',   
        p_http_method => 'POST',   
        p_username => x_user_name,   
        p_password => x_password,   
        p_body => l_body);   
     
        apex_json.parse (l_clob);   
    
   l_xml_result := apex_json.get_varchar2 ('P_ROLE');   
   l_http_status_code := apex_json.get_varchar2 ('P_Status');   
    
      
     EXCEPTION   
      WHEN OTHERS   
	   THEN   
	    l_xml_result:= NULL;   
        l_http_status_code := '500'; 
         
    END;   
    
 
        
        if l_http_status_code = '500' then 
            x_out_user_name := null; 
            x_out_jwt_token := null;
             
        elsif l_http_status_code = '200' then 
                x_out_user_name := v_user_name;   
           
   
           
				IF v_user_name IS NOT NULL THEN   
					BEGIN   
		   
				   x_encrypt_blob:= base64DecodeClobAsBlob(l_xml_result);  
  	  
				   convert_blob_to_xmltype(x_encrypt_blob,x_xml_output); 

		   
                       DELETE FROM XX_IMD_USER_ROLE_DETAILS_T WHERE upper(USERNAME) = upper(v_user_name);   
                        COMMIT;   
			   
					
					EXCEPTION   
					  WHEN OTHERS   
					   THEN   
						x_xml_output:= NULL;   
					END;	  
					   
				    
					   
				   FOR cur_rec IN (   
					  SELECT xt.*   
					  FROM   XMLTABLE('/DATA_DS/G_1'   
							   PASSING x_xml_output   
							   COLUMNS    
								 USERNAME VARCHAR2(100) PATH 'USERNAME',   
								 FULL_NAME VARCHAR2(100) PATH 'FULL_NAME',   
								 EMAIL_ADDRESS VARCHAR2(100) PATH 'EMAIL_ADDRESS',   
								 ROLE_NAME VARCHAR2(100) PATH 'ROLE_NAME'                    
							   ) xt)   
					  LOOP   
		   
					  INSERT INTO  XX_IMD_USER_ROLE_DETAILS_T   
						  (USERNAME,   
						   ROLE,   
						   EMAIL_ADDRESS,   
						   FULL_NAME   
						   )   
					  VALUES (cur_rec.USERNAME,cur_rec.ROLE_NAME,cur_rec.EMAIL_ADDRESS,cur_rec.FULL_NAME);   
		   
		   
					  COMMIT;   
					 END LOOP;   
			 END IF;   
	  
     ELSE 
         x_out_user_name := NULL;   
     END IF; 
	  
END IF;   
END IF;
   
EXCEPTION    
WHEN OTHERS THEN   
NULL;   
end main;   
   
end ;
/