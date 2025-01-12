create or replace Package BODY "WSC_AHCS_INT_ERROR_LOGGING" AS
    
Procedure "ERROR_LOGGING"(BATCH_ID   VARCHAR2,
                        RICE_ID     VARCHAR2,
                        P_APPLICATION VARCHAR2,
                        ERROR_MSG VARCHAR2) IS
                        
  l_body    VARCHAR2(500);  
  l_clob    CLOB;
  x_user_name   VARCHAR2(80);
  x_password    VARCHAR2(200);
  x_url         VARCHAR2(400);
  x_err_flag    VARCHAR2(5):='N';
  L_FILE_NAME     VARCHAR2(100);
  P_BATCH_ID      VARCHAR2(100) :=BATCH_ID;  
  LV_ERROR_MSG   VARCHAR2(500)  := Replace(ERROR_MSG,'"','');

BEGIN

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

  BEGIN
    Select file_name
    INTO L_FILE_NAME 
    from wsc_ahcs_int_control_t 
    where TO_CHAR(batch_id)=P_BATCH_ID;
  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
         Select file_name
        INTO L_FILE_NAME 
        from wsc_gen_int_control_t 
        where TO_CHAR(batch_id)=P_BATCH_ID;
       EXCEPTION
        WHEN OTHERS THEN
        L_FILE_NAME := sqlerrm;
       END; 
  END;   

IF x_err_flag!='Y' THEN   

--l_body := '{ "STAGE" : "ERROR", "RICE_ID" : "'||RICE_ID||'", "STATUS" : "ERROR", "FILE_NAME" : "'||L_FILE_NAME||'", "COMMENTS" : "'||ERROR_MSG||'", "ERROR_MESSAGE" : "'||ERROR_MSG||'","RUN_IDENTIFIER":"'||BATCH_ID||'", "ERROR_TYPE" : "'||'DB_ERROR'||'"}';

l_body := '{ "RUN_IDENTIFIER" : "'||BATCH_ID||'", "RICE_ID" : "'||RICE_ID||'", "STATUS" : "ERROR", "FILE_NAME" : "'||L_FILE_NAME||'", "COMMENTS" : "'||LV_ERROR_MSG||'", "ERROR_MESSAGE" : "'||LV_ERROR_MSG||'", "ERROR_TYPE" : "DB_ERROR" }';

  apex_web_service.g_request_headers.delete();   
        apex_web_service.g_request_headers(1).name := 'Content-Type';   
        apex_web_service.g_request_headers(1).value := 'application/json';

 l_clob := apex_web_service.make_rest_request(   
        p_url => x_url || ':443/ic/api/integration/v1/flows/rest/WSC_AHCS_ERROR_NOTIFY/1.0/WSC_AHCS_ERROR_NOTIFY',   
        p_http_method => 'POST',   
        p_username => x_user_name,   
        p_password => x_password,   
        p_body => l_body); 


 END IF; 
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
Procedure "ERROR_LOGGING_PURGING_NOTIFICATION"(BATCH_ID   VARCHAR2,
                        RICE_ID     VARCHAR2,
                        P_APPLICATION VARCHAR2,
                        ERROR_MSG VARCHAR2) IS

  l_body    VARCHAR2(500);  
  l_clob    CLOB;
  x_user_name   VARCHAR2(80);
  x_password    VARCHAR2(200);
  x_url         VARCHAR2(400);
  x_err_flag    VARCHAR2(5):='N';
  L_FILE_NAME     VARCHAR2(100);
  P_BATCH_ID      VARCHAR2(100) :=BATCH_ID;  
  LV_ERROR_MSG   VARCHAR2(500)  := Replace(ERROR_MSG,'"','');

BEGIN

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



IF x_err_flag!='Y' THEN   


l_body := '{ "RUN_IDENTIFIER" : "'||BATCH_ID||'", "RICE_ID" : "'||RICE_ID||'", "STATUS" : "ERROR", "FILE_NAME" : "'||L_FILE_NAME||'", "COMMENTS" : "'||LV_ERROR_MSG||'", "ERROR_MESSAGE" : "'||LV_ERROR_MSG||'", "ERROR_TYPE" : "DB_ERROR" }';

  apex_web_service.g_request_headers.delete();   
        apex_web_service.g_request_headers(1).name := 'Content-Type';   
        apex_web_service.g_request_headers(1).value := 'application/json';

 l_clob := apex_web_service.make_rest_request(   
        p_url => x_url || ':443/ic/api/integration/v1/flows/rest/WSC_AHCS_ERROR_NOTIFY/1.0/WSC_AHCS_ERROR_NOTIFY',   
        p_http_method => 'POST',   
        p_username => x_user_name,   
        p_password => x_password,   
        p_body => l_body); 


 END IF; 
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END; 
END;
/