SET DEFINE OFF;
/*=====================================================*/
    /* PACKAGE BODY XX_APEX_GET_ESS_DET_SEC_PKG */
/*=====================================================*/
create or replace PACKAGE BODY  "XX_APEX_GET_ESS_DET_SEC_PKG" as   

 
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

procedure get_reqID (   
   p_arg1 in varchar2 default null,   
   p_arg2 in number   default null)   
IS    
  cursor c1 is select * from XX_IMD_JOB_MASTER_T where enable_flag = 'Y' and job_type = 'L';   
  v_query CLOB := NULL;   
  x_xml_output XMLTYPE;   
  v_max_time DATE;   

	x_max_date       DATE;   
	x_job_date       VARCHAR2(100);   
	x_date_syntx     VARCHAR2(100);       
	p_incident       VARCHAR2(100);    
	x_req_seq        NUMBER;   
    V_IMPACT         VARCHAR2(1) ;  
    V_PRIORITY       VARCHAR2(1) ;  
    V_WEEKDAY        VARCHAR2(1) ;  
    V_WEEKEND        VARCHAR2(1) ;  
    V_MONTHEND        VARCHAR2(1) ;  
    v_weekday_end     VARCHAR2(10);  
    V_DIFF            NUMBER;  
    v_long_desc       VARCHAR2(1000);  

   l_clob      CLOB;   
   l_body      varchar2(32767);   
   l_feature_count  pls_integer;   
   j APEX_JSON.t_values;   
   x_encrypt_blob BLOB; 
   l_xml_result clob; 

   	x_err_flag       VARCHAR2(1):='N';   
	x_user_name      VARCHAR2(100);   
    x_password       VARCHAR2(100);   
    x_url            VARCHAR2(1000);   
	x_err VARCHAR2(2000);

BEGIN   
--DBMS_OUTPUT.PUT_LINE('Hi');   
   /* select max(SUBMIT_TIME)   
    INTO v_max_time   
    FROM XX_IMD_JOB_RUN_T a, XX_IMD_JOB_MASTER_T b  WHERE b.JOB_TYPE='L' AND a.program_name = b.job_name ;    */

    select max(START_TIME)   
    INTO v_max_time   
    FROM XX_IMD_JOB_RUN_T a WHERE a.JOB_TYPE='L';	

    v_max_time := NVL(v_max_time, sysdate -1);   
    x_job_date:= TO_CHAR(v_max_time,'DD-MM-YYYY HH24:MI:SS');   
    x_date_syntx := ''''||'DD-MM-YYYY HH24:MI:SS'||'''';   
    DBMS_OUTPUT.PUT_LINE('x_job_date: '||x_job_date);   

   /* for i in c1 loop   
      v_query := v_query||' SELECT SUBMITTER, executable_status, to_char(PROCESSEND,''dd-mon-yyyy HH24:MI:SS'') PROCESSEND, to_char(processstart,''dd-mon-yyyy HH24:MI:SS'') processstart,to_char(REQUESTEDSTART,''dd-mon-yyyy HH24:MI:SS'')  REQUESTEDSTART,  round((cast(PROCESSEND as date) - cast(PROCESSSTART as date))* 24 * 60) diff_minutes, definition, requestid FROM ess_request_history WHERE to_date(to_char(REQUESTEDSTART,''dd-mm-yyyy HH24:MI:SS''),''dd-mm-yyyy HH24:MI:SS'') > to_date('||x_job_date||','||x_date_syntx||') AND round((cast(PROCESSEND as date) - cast(PROCESSSTART as date))* 24 * 60) >= '||i.threshold||' AND definition = '''||i.job_name||''' UNION ALL';   
    end LOOP;   
    v_query := v_query ||' SELECT null, null, null, null, null, null, null, null FROM dual';   
    v_query := 'SELECT * FROM ('||v_query||') WHERE requestid IS NOT NULL';  */ 

    --DBMS_OUTPUT.PUT_LINE(v_query);   


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

     l_body := '{ "p_reportName":"LongRunningJobs", "p_date":"'|| x_job_date||'" ,"p_jobname":"'||v_query||'"}'; 
  -- l_body := '{ "p_reportName":"LongRunningJobs", "p_date":"'||'12-01-2022 00:00:00'||'" ,"p_jobname":"'||v_query||'"}'; 
      

     --dbms_output.put_line(l_body);   

        apex_web_service.g_request_headers.delete();   
        apex_web_service.g_request_headers(1).name := 'Content-Type';   
        apex_web_service.g_request_headers(1).value := 'application/json';   

        l_clob := apex_web_service.make_rest_request(   
        p_url => x_url || ':443/ic/api/integration/v1/flows/rest/WESC_WSC_GBL_DP_JOB_REPO_INTER/1.0/runDpReport',   
        p_http_method => 'POST',   
        p_username => x_user_name,   
        p_password => x_password,   
        p_body => l_body);   
        dbms_output.put_line(l_clob);   

   apex_json.parse (l_clob);   

   l_xml_result := apex_json.get_varchar2 ('p_result');   

      x_encrypt_blob:= base64DecodeClobAsBlob(l_xml_result);  

  	   convert_blob_to_xmltype(x_encrypt_blob,x_xml_output); 

    /*XX_APEX_GEN_RUN_REP_PKG.main(v_query,x_xml_output);  */ 


    EXCEPTION   
      WHEN OTHERS   
	   THEN   
	    x_xml_output:= NULL;   
    END;  	   

       x_req_seq := xx_req_seq.NEXTVAL;   

      FOR cur_rec IN (   
      SELECT xt.*   
      FROM   XMLTABLE('/DATA_DS/G_1'   
               PASSING x_xml_output   
               COLUMNS    
                 EXECUTABLE_STATUS VARCHAR2(100) PATH 'EXECUTABLE_STATUS',   
                 PROCESSEND VARCHAR2(100) PATH 'PROCESSEND',   
                 PROCESSSTART VARCHAR2(100) PATH 'PROCESSSTART',   
                 REQUESTEDSTART VARCHAR2(100) PATH 'REQUESTEDSTART',   
                 DIFF_MINUTES     VARCHAR2(100) PATH 'DIFF_MINUTES',   
                 DEFINITION          VARCHAR2(100) PATH 'DEFINITION',    
                 REQUESTID     VARCHAR2(100) PATH 'REQUESTID',    
                 SUBMITTER     VARCHAR2(100) PATH 'SUBMITTER', 
                 PROGRAMNAME VARCHAR2(1000) PATH 'PROGRAMNAME',				 
				 ATTRIBUTE1 VARCHAR2(100) PATH 'ATTRIBUTE1',
                 ATTRIBUTE2 VARCHAR2(100) PATH 'ATTRIBUTE2'
               ) xt)   
      LOOP   


      /* BEGIN  

       SELECT WEEKDAY_PRIORITY,WEEKEND_PRIORITY,MONTHEND_PRIORITY  
         INTO V_WEEKDAY,V_WEEKEND,V_MONTHEND  
         FROM XX_IMD_JOB_MASTER_T  
        WHERE JOB_NAME =  cur_rec.DEFINITION;  

        /*SELECT NVL(description, NULL) INTO v_long_desc FROM XX_IMD_JOB_MASTER_T where JOB_NAME = cur_rec.DEFINITION;  */


      /* EXCEPTION  
       WHEN OTHERS THEN  
       V_IMPACT:='3';  
       V_PRIORITY:='3'; 
       v_long_desc := NULL; 
       END;    
       dbms_output.put_line(V_IMPACT||':'||V_PRIORITY) ;     

       SELECT TO_CHAR(TO_DATE(cur_rec.REQUESTEDSTART,'DD-MM-YYYY HH24:MI:SS'), 'DY') day   
         INTO v_weekday_end  
        FROM DUAL;   

        IF v_weekday_end IN ('SAT','SUN') THEN  
       V_IMPACT:=  V_WEEKEND;  
       V_PRIORITY:= V_WEEKEND;    
       ELSE  
       V_IMPACT:=  V_WEEKDAY;  
       V_PRIORITY:= V_WEEKDAY;  
        END IF;  

        SELECT (SYSDATE - LAST_DAY(TO_DATE(cur_rec.REQUESTEDSTART,'DD-MM-YYYY HH24:MI:SS')) ) INTO V_DIFF FROM DUAL;  

        IF V_DIFF = 0 OR V_DIFF = -1 THEN  

         V_IMPACT:=  V_MONTHEND;  
         V_PRIORITY:= V_MONTHEND;  
        END IF;  




        dbms_output.put_line(cur_rec.DEFINITION||':'||cur_rec.DIFF_MINUTES||cur_rec.REQUESTID) ;     

     /*  xx_snow_ticket_create( 'Program :'||v_long_desc||' is running for '||cur_rec.DIFF_MINUTES||' mins',  
                             V_IMPACT,                              
                             'Program :'||v_long_desc||' with request ID:'||cur_rec.REQUESTID||' is running for '||cur_rec.DIFF_MINUTES||' mins',  
                             'Long Running Job',  
                             V_PRIORITY,  
                             p_incident  
                             ); */ 

       -- dbms_output.put_line(V_IMPACT||':'||V_PRIORITY) ;                      

      /* INSERT INTO xx_imd_job_run_t( request_id   
                                   , START_TIME   
                                   , END_TIME   
                                   , status   
                                   , SUBMIT_TIME   
                                   , PROGRAM_NAME   
                                   , SUBMITTED_BY   
                                   , TICKET_NUMBER  
								   , req_sequence  
								   )    
	                        VALUES(  cur_rec.REQUESTID   
                                  ,  TO_DATE(cur_rec.PROCESSSTART,'DD-MM-YYYY HH24:MI:SS')   
			                      ,  TO_DATE(cur_rec.PROCESSEND  ,'DD-MM-YYYY HH24:MI:SS')   
			                      ,  cur_rec.EXECUTABLE_STATUS   
                                  ,  TO_DATE(cur_rec.REQUESTEDSTART,'DD-MM-YYYY HH24:MI:SS')   
                                  ,  cur_rec.DEFINITION   
                                  ,  cur_rec.SUBMITTER   
                                  ,  p_incident  
                                  ,  x_req_seq  
			                      );  */

      INSERT INTO xx_imd_job_run_t( request_id   
                                   , START_TIME   
                                   , END_TIME   
                                   , status   
                                   , SUBMIT_TIME   
                                   , PROGRAM_NAME   
                                   , SUBMITTED_BY   
                                   , TICKET_NUMBER  
								   , req_sequence  
                                   , JOB_TYPE
                                   , TRACK
                                   , PHASE_CODE
								   )    
	                        VALUES(  cur_rec.REQUESTID   
                                  ,  TO_DATE(cur_rec.PROCESSSTART,'DD-MM-YYYY HH24:MI:SS')   
			                      ,  TO_DATE(cur_rec.PROCESSEND  ,'DD-MM-YYYY HH24:MI:SS')   
			                      ,  cur_rec.EXECUTABLE_STATUS   
                                  ,  TO_DATE(cur_rec.REQUESTEDSTART,'DD-MM-YYYY HH24:MI:SS')   
                                  ,  cur_rec.PROGRAMNAME   
                                  ,  cur_rec.SUBMITTER   
                                  ,  p_incident  
                                  ,  x_req_seq  
                                  ,'L'
                                  ,  cur_rec.ATTRIBUTE2   
                                  ,  cur_rec.ATTRIBUTE1
			                      );   								  

      COMMIT;   
    END LOOP;	   

/*	FOR cur_req IN (SELECT DISTINCT REQUEST_ID FROM xx_imd_job_run_t)   
	LOOP   
		NULL;  
        XX_APEX_GEN_RUN_REP_PKG.parameter_main(p_arg1);   
	END LOOP;*/   
	
	exception
    when others then
    x_err:=sqlerrm;

END get_reqID;    



procedure get_reqID_crit (   
   p_arg1 in varchar2 default null,   
   p_arg2 in number   default null)   
IS    
  cursor c1 is select * from XX_IMD_JOB_MASTER_T where enable_flag = 'Y' and job_type = 'C';   
  v_query CLOB := 'TEST';   
  x_xml_output XMLTYPE;   
  v_max_time DATE;   
  x_err VARCHAR2(2000);
	x_max_date       DATE;   
	x_job_date       VARCHAR2(100);   
	x_date_syntx     VARCHAR2(100);       
	p_incident       VARCHAR2(100);    
	x_req_seq        NUMBER;   
    V_IMPACT         VARCHAR2(1) ;  
    V_PRIORITY       VARCHAR2(1) ;  
    V_WEEKDAY        VARCHAR2(1) ;  
    V_WEEKEND        VARCHAR2(1) ;  
    V_MONTHEND        VARCHAR2(1) ;  
    v_weekday_end     VARCHAR2(10);  
    V_DIFF            NUMBER;  
    v_long_desc       VARCHAR2(1000);  


   l_clob      CLOB;   
   l_body      varchar2(32767);   
   l_feature_count  pls_integer;   
   j APEX_JSON.t_values;   
   x_encrypt_blob BLOB; 
   l_xml_result clob; 

   	x_err_flag       VARCHAR2(1):='N';   
	x_user_name      VARCHAR2(100);   
    x_password       VARCHAR2(100);   
    x_url            VARCHAR2(1000);   


BEGIN   
--DBMS_OUTPUT.PUT_LINE('Hi');   
    /*select max(SUBMIT_TIME)   
    INTO v_max_time   
    FROM XX_IMD_JOB_RUN_T a, XX_IMD_JOB_MASTER_T b  WHERE b.JOB_TYPE='C' AND a.job_id = b.id ;    */

   /* select max(SUBMIT_TIME)   
    INTO v_max_time   
    FROM XX_IMD_JOB_RUN_T a WHERE a.JOB_TYPE='C';   */ 
	
	select max(START_TIME)   
    INTO v_max_time   
    FROM XX_IMD_JOB_RUN_T a WHERE a.JOB_TYPE='C'; 

    v_max_time := NVL(v_max_time, sysdate - 1);   
    x_job_date:= TO_CHAR(v_max_time,'DD-MM-YYYY HH24:MI:SS');   
    x_date_syntx := ''''||'DD-MM-YYYY HH24:MI:SS'||'''';   
    DBMS_OUTPUT.PUT_LINE('x_job_date: '||x_job_date);   

    /*for i in c1 loop   
      v_query := v_query||' SELECT SUBMITTER, executable_status, to_char(PROCESSEND,''dd-mon-yyyy HH24:MI:SS'') PROCESSEND, to_char(processstart,''dd-mon-yyyy HH24:MI:SS'') processstart,to_char(REQUESTEDSTART,''dd-mon-yyyy HH24:MI:SS'')  REQUESTEDSTART,  round((cast(PROCESSEND as date) - cast(PROCESSSTART as date))* 24 * 60) diff_minutes, definition, requestid FROM ess_request_history WHERE to_date(to_char(REQUESTEDSTART,''dd-mm-yyyy HH24:MI:SS''),''dd-mm-yyyy HH24:MI:SS'') > to_date('||x_job_date||','||x_date_syntx||') AND executable_status = ''ERROR'' AND definition = '''||i.job_name||''' UNION ALL';   
    end LOOP;   
    v_query := v_query ||' SELECT null, null, null, null, null, null, null, null FROM dual';   
    v_query := 'SELECT * FROM ('||v_query||') WHERE requestid IS NOT NULL';   
    DBMS_OUTPUT.PUT_LINE(v_query);  */ 


   /* for i in c1 loop   
      v_query := v_query||i.job_name||',' ;   
    end LOOP;   
    v_query := v_query ||'null'; 
    DBMS_OUTPUT.PUT_LINE(v_query); */  



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
     l_body := '{ "p_reportName":"CriticalJobs", "p_date":"'|| x_job_date||'" ,"p_jobname":"'||v_query||'"}';   
	 
	--l_body := '{ "p_reportName":"CriticalJobs", "p_date":"'|| '07-07-2022 17:00:12'||'" ,"p_jobname":"'||v_query||'"}';   
     
     apex_web_service.g_request_headers.delete();   
        apex_web_service.g_request_headers(1).name := 'Content-Type';   
        apex_web_service.g_request_headers(1).value := 'application/json';   

        l_clob := apex_web_service.make_rest_request(   
        p_url => x_url || ':443/ic/api/integration/v1/flows/rest/WESC_WSC_GBL_DP_JOB_REPO_INTER/1.0/runDpReport',   
        p_http_method => 'POST',   
        p_username => x_user_name,   
        p_password => x_password,   
        p_body => l_body);   

        apex_json.parse (l_clob);   



   l_xml_result := apex_json.GET_VARCHAR2('p_result');   

     x_encrypt_blob:= base64DecodeClobAsBlob(l_xml_result);  


  	   convert_blob_to_xmltype(x_encrypt_blob,x_xml_output); 


  EXCEPTION   
      WHEN OTHERS   
	   THEN   
	    x_xml_output:= NULL;   
        x_err:=sqlerrm;

    END;   

       x_req_seq := xx_req_seq.NEXTVAL;   

      FOR cur_rec IN (   
      SELECT xt.*   
      FROM   XMLTABLE('/DATA_DS/G_1'   
               PASSING x_xml_output   
               COLUMNS    
                 EXECUTABLE_STATUS VARCHAR2(100) PATH 'EXECUTABLE_STATUS',   
                 PROCESSEND VARCHAR2(100) PATH 'PROCESSEND',   
                 PROCESSSTART VARCHAR2(100) PATH 'PROCESSSTART',   
                 REQUESTEDSTART VARCHAR2(100) PATH 'REQUESTEDSTART',   
                 DIFF_MINUTES     VARCHAR2(100) PATH 'DIFF_MINUTES',   
                 DEFINITION          VARCHAR2(1000) PATH 'DEFINITION',    
                 REQUESTID     VARCHAR2(100) PATH 'REQUESTID',    
                 SUBMITTER     VARCHAR2(100) PATH 'SUBMITTER',
                      PROGRAMNAME VARCHAR2(1000) PATH 'PROGRAMNAME',
                      ATTRIBUTE1 VARCHAR2(100) PATH 'ATTRIBUTE1',
                      ATTRIBUTE2 VARCHAR2(100) PATH 'ATTRIBUTE2'
               ) xt)   
      LOOP   


       INSERT INTO xx_imd_job_run_t( request_id   
                                   , START_TIME   
                                   , END_TIME   
                                   , status   
                                   , SUBMIT_TIME   
                                   , PROGRAM_NAME   
                                   , SUBMITTED_BY   
                                   , TICKET_NUMBER  
								   , req_sequence  
                                   , JOB_TYPE
                                   , TRACK
                                   , PHASE_CODE
								   )    
	                        VALUES(  cur_rec.REQUESTID   
                                  ,  TO_DATE(cur_rec.PROCESSSTART,'DD-MM-YYYY HH24:MI:SS')   
			                      ,  TO_DATE(cur_rec.PROCESSEND  ,'DD-MM-YYYY HH24:MI:SS')   
			                      ,  cur_rec.EXECUTABLE_STATUS   
                                  ,  TO_DATE(cur_rec.REQUESTEDSTART,'DD-MM-YYYY HH24:MI:SS')   
                                  ,  cur_rec.PROGRAMNAME   
                                  ,  cur_rec.SUBMITTER   
                                  ,  p_incident  
                                  ,  x_req_seq  
                                  ,'C'
                                  ,  cur_rec.ATTRIBUTE2   
                                  ,  cur_rec.ATTRIBUTE1
			                      );   

      COMMIT;   
    END LOOP;	   

	/*FOR cur_req IN (SELECT DISTINCT REQUEST_ID FROM xx_imd_job_run_t)   
	LOOP   
		NULL;  
        XX_APEX_GEN_RUN_REP_PKG.parameter_main(p_arg1);   
	END LOOP;  */ 
exception
when others then

    x_err:=sqlerrm;

END get_reqID_crit;   


--procedure get_reqID_outbound (   
--   p_arg1 in varchar2 default null,   
--   p_arg2 in number   default null)   
--IS    
--  cursor c1 is select * from XX_IMD_JOB_MASTER_T where enable_flag = 'Y' and job_type = 'O';   
--  v_query CLOB := NULL;   
--  x_xml_output XMLTYPE;   
--  v_max_time DATE;   
--
--	x_max_date       DATE;   
--	x_job_date       VARCHAR2(100);   
--	x_date_syntx     VARCHAR2(100);       
--	p_incident       VARCHAR2(100);    
--	x_req_seq        NUMBER;   
--    V_IMPACT         VARCHAR2(1) ;  
--    V_PRIORITY       VARCHAR2(1) ;  
--    V_WEEKDAY        VARCHAR2(1) ;  
--    V_WEEKEND        VARCHAR2(1) ;  
--    V_MONTHEND        VARCHAR2(1) ;  
--    v_weekday_end     VARCHAR2(10);  
--    V_DIFF            NUMBER;  
--    v_long_desc       VARCHAR2(1000);  
--    l_master_id       NUMBER; 
--    l_short_desc      VARCHAR2(1000);  
--    L_INT_RUN_ID NUMBER; 
--    L_ACTIVITY_ID NUMBER; 
--    p_status VARCHAR2(2000); 
--
--     l_clob      CLOB;   
--    l_body      varchar2(32767);   
--    l_feature_count  pls_integer;   
--   j APEX_JSON.t_values;   
--   x_encrypt_blob BLOB; 
--   l_xml_result clob; 
--   v_value apex_json.t_value;
--   x_err_msg  VARCHAR2(1000);   
--
--   	x_err_flag       VARCHAR2(1):='N';   
--	x_user_name      VARCHAR2(100);   
--    x_password       VARCHAR2(100);   
--    x_url            VARCHAR2(1000);   
--
--
--BEGIN   
----DBMS_OUTPUT.PUT_LINE('Hi');   
--    select max(a.START_TIME)   
--    INTO v_max_time   
--    FROM xx_imd_integration_run_t a, XX_IMD_JOB_MASTER_T b ,XX_IMD_INTEGRATION_MASTER_T xximd 
--    WHERE b.JOB_TYPE='O' AND xximd.job_id = b.id and xximd.id = a.integration_master_id ;    
--
--    v_max_time := NVL(v_max_time, sysdate -2);   
--    x_job_date:=TO_CHAR(v_max_time,'DD-MM-YYYY HH24:MI:SS');   
--    x_date_syntx := ''''||'DD-MM-YYYY HH24:MI:SS'||'''';   
--    DBMS_OUTPUT.PUT_LINE('x_job_date: '||x_job_date);   
--
--
--
--
--   /* for i in c1 loop   
--      v_query := v_query||' SELECT essp.value,essr.SUBMITTER, DECODE(essr.executable_status,''SUCCEEDED'',''SUCCESS'',essr.executable_status) executable_status , to_char(essr.PROCESSEND,''dd-mon-yyyy HH24:MI:SS'') PROCESSEND, to_char(essr.processstart,''dd-mon-yyyy HH24:MI:SS'') processstart,to_char(essr.REQUESTEDSTART,''dd-mon-yyyy HH24:MI:SS'')  REQUESTEDSTART,  round((cast(essr.PROCESSEND as date) - cast(essr.PROCESSSTART as date))* 24 * 60) diff_minutes, essr.definition, essr.requestid FROM ess_request_history essr,fusion_ora_ess.request_property_view essp WHERE essr.requestid = essp.requestid and to_date(to_char(REQUESTEDSTART,''dd-mm-yyyy HH24:MI:SS''),''dd-mm-yyyy HH24:MI:SS'') > to_date('||x_job_date||','||x_date_syntx||') AND essp.value = '''||i.job_name||''' UNION ALL';   
--    end LOOP;   
--    v_query := v_query ||' SELECT null, null, null, null, null, null, null, null, null FROM dual';   
--    v_query := 'SELECT * FROM ('||v_query||') WHERE requestid IS NOT NULL';  */ 
--
--    for i in c1 loop   
--      v_query := v_query||i.job_name||',' ;   
--    end LOOP;   
--    v_query := v_query ||'null'; 
--    DBMS_OUTPUT.PUT_LINE(v_query);   
--
--
--    BEGIN  
--
--	  SELECT user_name  
--	       ,(replace(password, '&', '&amp;')) 
--	       --, password  
--		   , url  
--		INTO x_user_name  
--		   , x_password  
--		   , x_url  
--		FROM xx_imd_details  
--	   WHERE ROWNUM=1;  
--
--	EXCEPTION  
--	  WHEN no_data_found  
--       THEN	   
--	     x_err_flag:='Y';  
--	  WHEN OTHERS  
--        THEN  
--	     x_err_flag:='Y';     
--	END;  
--
--
--    BEGIN   
--
--     l_body := '{ "p_reportName":"OutboundJobs", "p_date":"'|| x_job_date||'" ,"p_jobname":"'||v_query||'"}';   
--
--     dbms_output.put_line(l_body);   
--
--
--     apex_web_service.g_request_headers.delete();   
--        apex_web_service.g_request_headers(1).name := 'Content-Type';   
--        apex_web_service.g_request_headers(1).value := 'application/json';   
--
--         l_clob := apex_web_service.make_rest_request(   
--        p_url => x_url || ':443/ic/api/integration/v1/flows/rest/AXE_DP_SCHEDU_RPT_INT/1.0/runDpReport',   
--        p_http_method => 'POST',   
--        p_username => x_user_name,   
--        p_password => x_password,   
--        p_body => l_body);   
--
--
--   apex_json.parse (l_clob);   
--
--    v_value := apex_json.get_value ('p_result');   
--
--   l_xml_result := v_value.varchar2_value;
--   if l_xml_result is null then
--       l_xml_result := v_value.clob_value;
--   end if;
--
--   --apex_json.get_varchar2 ('p_result');   
--
--
--
--      x_encrypt_blob:= base64DecodeClobAsBlob(l_xml_result); 
--
--
--  	   convert_blob_to_xmltype(x_encrypt_blob,x_xml_output); 
--
--    EXCEPTION   
--      WHEN OTHERS   
--	   THEN   
--	    x_xml_output:= NULL;  
--        x_err_msg := sqlerrm;
--
--    END;	   
--
--       x_req_seq := xx_req_seq.NEXTVAL;   
--
--      FOR cur_rec IN (   
--      SELECT xt.*   
--      FROM   XMLTABLE('/DATA_DS/G_1'   
--               PASSING x_xml_output   
--               COLUMNS    
--                 VALUE VARCHAR2(2000) PATH 'VALUE',   
--                 EXECUTABLE_STATUS VARCHAR2(100) PATH 'EXECUTABLE_STATUS',   
--                 PROCESSEND VARCHAR2(100) PATH 'PROCESSEND',   
--                 PROCESSSTART VARCHAR2(100) PATH 'PROCESSSTART',   
--                 REQUESTEDSTART VARCHAR2(100) PATH 'REQUESTEDSTART',   
--                 DIFF_MINUTES     VARCHAR2(100) PATH 'DIFF_MINUTES',   
--                 DEFINITION          VARCHAR2(100) PATH 'DEFINITION',    
--                 REQUESTID     VARCHAR2(100) PATH 'REQUESTID',    
--                 SUBMITTER     VARCHAR2(100) PATH 'SUBMITTER',
--                 FLOWTASKNAME     VARCHAR2(100) PATH 'FLOWTASKNAME' ,    
--                 FLOWINSTANCENAME     VARCHAR2(100) PATH 'FLOWINSTANCENAME' ,    
--                 ERRORMSG     VARCHAR2(100) PATH 'ERRORMSG' 				 
--               ) xt)   
--      LOOP   
--
--            l_master_id:=0;   
--            BEGIN   
--              SELECT XXIMT.id,XXIMT.description   
--              INTO l_master_id ,l_short_desc  
--              FROM XX_IMD_INTEGRATION_MASTER_T xximt  , XX_IMD_JOB_MASTER_T xxj 
--              WHERE xximt.job_id = xxj.id 
--                and (xxj.JOB_NAME = cur_rec.DEFINITION OR xxj.JOB_NAME = cur_rec.VALUE);   
--
--            EXCEPTION   
--            WHEN NO_DATA_FOUND THEN   
--
--                p_status :=p_status||':'|| sqlerrm;   
--                WHEN OTHERS THEN   
--                 p_status :=p_status||':'|| sqlerrm;  
--            END;   
--            BEGIN   
--
--             SELECT XX_IMD_INTEG_RUN_T_SEQ.nextval INTO l_int_run_id FROM dual;   
--              INSERT   
--              INTO XX_IMD_INTEGRATION_RUN_T   
--                (   
--                  ID,   
--                  INTEGRATION_STATUS,   
--                  START_TIME,   
--                  END_TIME, 
--                  INTEGRATION_MASTER_ID,   
--                  RUN_IDENTIFIER ,
--               --     FLOWTASKNAME,
--                 --   FLOWINSTANCENAME,
--                    REQUEST_ID
--                )   
--                VALUES   
--                (   
--                  l_int_run_id ,   
--                  cur_rec.EXECUTABLE_STATUS,   
--                  TO_DATE(cur_rec.PROCESSSTART,'DD-MM-YYYY HH24:MI:SS')    , 
--                  TO_DATE(cur_rec.PROCESSEND,'DD-MM-YYYY HH24:MI:SS')    ,   
--                  l_master_id ,   
--                  NULL  ,
--                 --   cur_rec.FLOWTASKNAME,
--                --    cur_rec.FLOWINSTANCENAME ,
--                    cur_rec.REQUESTID
--                );  
--
--
--            EXCEPTION   
--              WHEN OTHERS THEN   
--                 p_status :=p_status||':'|| sqlerrm;  
--            END;   
--
--
--
--            BEGIN   
--              SELECT XX_IMD_INTEG_ACTIVITY_T_SEQ.nextval INTO l_activity_id FROM dual;   
--              INSERT   
--              INTO XX_IMD_INTEGRATION_ACTIVITY_T   
--                (   
--                  ID ,   
--                  INTEGRATION_RUN_ID ,   
--                  ACTIVITY_NAME ,   
--                  TOUCHPOINT_NAME,   
--                  ACTIVITY_DATE,   
--                  ACTIVITY_STATUS   
--                )   
--                VALUES   
--                (   
--                  l_activity_id ,   
--                  l_int_run_id , 
--                    DECODE(cur_rec.FLOWTASKNAME, NULL, cur_rec.FLOWINSTANCENAME,  cur_rec.FLOWTASKNAME),
--                 -- 'Outbound',   
--                  'BI Report' ,   
--                  sysdate,   
--                  cur_rec.EXECUTABLE_STATUS   
--                );   
--
--              commit; 
--
--              INSERT INTO XX_IMD_ADDITIONAL_INFO_T   
--					  (   
--						ID ,   
--						KEYNAME ,   
--						VALUE ,   
--						INTEGRATION_ACTIVITY_ID   
--					  )   
--					  VALUES   
--					  (   
--						XX_IMD_ADDNINFO_T_SEQ.nextval,   
--						'ERROR REASON',   
--						cur_rec.ERRORMSG,   
--						l_activity_id   
--					  ); 
--
--
--            EXCEPTION   
--            WHEN NO_DATA_FOUND THEN   
--              p_status :=p_status||':'|| sqlerrm;   
--               WHEN OTHERS THEN   
--                 p_status :=p_status||':'|| sqlerrm;  
--            END; 
--
--       ---------------- 
--
--
--      COMMIT;   
--    END LOOP;	   
--
--	/*FOR cur_req IN (SELECT DISTINCT REQUEST_ID FROM xx_imd_job_run_t)   
--	LOOP   
--		NULL;  
--        XX_APEX_GEN_RUN_REP_PKG.parameter_main(p_arg1);   
--	END LOOP;  */ 
--
--END get_reqID_outbound;    


procedure get_reqID_outbound (   
   p_arg1 in varchar2 default null,   
   p_arg2 in number   default null)   
IS    
  cursor c1 is select * from XX_IMD_JOB_MASTER_T where enable_flag = 'Y' and job_type = 'O';   
  v_query CLOB := NULL;   
  x_xml_output XMLTYPE;   
  v_max_time DATE;   

	x_max_date       DATE;   
	x_job_date       VARCHAR2(100);   
	x_date_syntx     VARCHAR2(100);       
	p_incident       VARCHAR2(100);    
	x_req_seq        NUMBER;   
    V_IMPACT         VARCHAR2(1) ;  
    V_PRIORITY       VARCHAR2(1) ;  
    V_WEEKDAY        VARCHAR2(1) ;  
    V_WEEKEND        VARCHAR2(1) ;  
    V_MONTHEND        VARCHAR2(1) ;  
    v_weekday_end     VARCHAR2(10);  
    V_DIFF            NUMBER;  
    v_long_desc       VARCHAR2(1000);  
    l_master_id       NUMBER; 
    l_short_desc      VARCHAR2(1000);  
    L_INT_RUN_ID NUMBER; 
    L_ACTIVITY_ID NUMBER; 
    p_status VARCHAR2(2000); 

     l_clob      CLOB;   
    l_body      varchar2(32767);   
    l_feature_count  pls_integer;   
   j APEX_JSON.t_values;   
   x_encrypt_blob BLOB; 
   l_xml_result clob; 
   v_value apex_json.t_value;
   x_err_msg  VARCHAR2(1000);   

   	x_err_flag       VARCHAR2(1):='N';   
	x_user_name      VARCHAR2(100);   
    x_password       VARCHAR2(100);   
    x_url            VARCHAR2(1000);   
    x_err VARCHAR2(2000);
BEGIN   
--DBMS_OUTPUT.PUT_LINE('Hi');   
/*
    select max(a.START_TIME)   
    INTO v_max_time   
    FROM xx_imd_integration_run_t a, XX_IMD_JOB_MASTER_T b ,XX_IMD_INTEGRATION_MASTER_T xximd 
    WHERE b.JOB_TYPE='O' AND xximd.job_id = b.id and xximd.id = a.integration_master_id ;    
*/
	select max(START_TIME)   
    INTO v_max_time   
    FROM XX_IMD_JOB_RUN_T a WHERE a.JOB_TYPE='O';	

    v_max_time := NVL(v_max_time, sysdate -2);   
    x_job_date:=TO_CHAR(v_max_time,'DD-MM-YYYY HH24:MI:SS');   
    x_date_syntx := ''''||'DD-MM-YYYY HH24:MI:SS'||'''';   
    DBMS_OUTPUT.PUT_LINE('x_job_date: '||x_job_date);   




   /* for i in c1 loop   
      v_query := v_query||' SELECT essp.value,essr.SUBMITTER, DECODE(essr.executable_status,''SUCCEEDED'',''SUCCESS'',essr.executable_status) executable_status , to_char(essr.PROCESSEND,''dd-mon-yyyy HH24:MI:SS'') PROCESSEND, to_char(essr.processstart,''dd-mon-yyyy HH24:MI:SS'') processstart,to_char(essr.REQUESTEDSTART,''dd-mon-yyyy HH24:MI:SS'')  REQUESTEDSTART,  round((cast(essr.PROCESSEND as date) - cast(essr.PROCESSSTART as date))* 24 * 60) diff_minutes, essr.definition, essr.requestid FROM ess_request_history essr,fusion_ora_ess.request_property_view essp WHERE essr.requestid = essp.requestid and to_date(to_char(REQUESTEDSTART,''dd-mm-yyyy HH24:MI:SS''),''dd-mm-yyyy HH24:MI:SS'') > to_date('||x_job_date||','||x_date_syntx||') AND essp.value = '''||i.job_name||''' UNION ALL';   
    end LOOP;   
    v_query := v_query ||' SELECT null, null, null, null, null, null, null, null, null FROM dual';   
    v_query := 'SELECT * FROM ('||v_query||') WHERE requestid IS NOT NULL';  */ 
/*
    for i in c1 loop   
      v_query := v_query||i.job_name||',' ;   
    end LOOP;   
    v_query := v_query ||'null'; 
    DBMS_OUTPUT.PUT_LINE(v_query);   
*/

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

    l_body := '{ "p_reportName":"OutboundJobs", "p_date":"'|| x_job_date||'" ,"p_jobname":"'||v_query||'"}';   
    ---l_body := '{ "p_reportName":"OutboundJobs", "p_date":"'|| '01-02-2022 00:00:00'||'" ,"p_jobname":"'||v_query||'"}'; 

     dbms_output.put_line(l_body);   


     apex_web_service.g_request_headers.delete();   
        apex_web_service.g_request_headers(1).name := 'Content-Type';   
        apex_web_service.g_request_headers(1).value := 'application/json';   

         l_clob := apex_web_service.make_rest_request( 
		p_url => x_url || ':443/ic/api/integration/v1/flows/rest/WESC_WSC_GBL_DP_JOB_REPO_INTER/1.0/runDpReport',   
        --p_url => x_url || ':443/ic/api/integration/v1/flows/rest/AXE_DP_SCHEDU_RPT_INT/1.0/runDpReport',   
        p_http_method => 'POST',   
        p_username => x_user_name,   
        p_password => x_password,   
        p_body => l_body);   


   apex_json.parse (l_clob);   

    v_value := apex_json.get_value ('p_result');   

   l_xml_result := v_value.varchar2_value;
   if l_xml_result is null then
       l_xml_result := v_value.clob_value;
   end if;

   --apex_json.get_varchar2 ('p_result');   



      x_encrypt_blob:= base64DecodeClobAsBlob(l_xml_result); 


  	   convert_blob_to_xmltype(x_encrypt_blob,x_xml_output); 

    EXCEPTION   
      WHEN OTHERS   
	   THEN   
	    x_xml_output:= NULL;  
        x_err_msg := sqlerrm;

    END;	   

       x_req_seq := xx_req_seq.NEXTVAL;   

      FOR cur_rec IN (   
      SELECT xt.*   
      FROM   XMLTABLE('/DATA_DS/G_1'   
               PASSING x_xml_output   
               COLUMNS    
                 VALUE VARCHAR2(2000) PATH 'VALUE',   
                 EXECUTABLE_STATUS VARCHAR2(100) PATH 'EXECUTABLE_STATUS',   
                 PROCESSEND VARCHAR2(100) PATH 'PROCESSEND',   
                 PROCESSSTART VARCHAR2(100) PATH 'PROCESSSTART',   
                 REQUESTEDSTART VARCHAR2(100) PATH 'REQUESTEDSTART',   
                 DIFF_MINUTES     VARCHAR2(100) PATH 'DIFF_MINUTES',   
                 DEFINITION          VARCHAR2(100) PATH 'DEFINITION',    
                 REQUESTID     VARCHAR2(100) PATH 'REQUESTID',    
                 SUBMITTER     VARCHAR2(100) PATH 'SUBMITTER',
                 FLOWTASKNAME     VARCHAR2(100) PATH 'FLOWTASKNAME' ,    
                 FLOWINSTANCENAME     VARCHAR2(100) PATH 'FLOWINSTANCENAME' ,    
                 ERRORMSG     VARCHAR2(100) PATH 'ERRORMSG',
				 PROGRAMNAME VARCHAR2(1000) PATH 'PROGRAMNAME',				 
				 ATTRIBUTE1 VARCHAR2(100) PATH 'ATTRIBUTE1',
                 ATTRIBUTE2 VARCHAR2(100) PATH 'ATTRIBUTE2'				 
               ) xt)   
      LOOP   
/*
            l_master_id:=0;   
            BEGIN   
              SELECT XXIMT.id,XXIMT.description   
              INTO l_master_id ,l_short_desc  
              FROM XX_IMD_INTEGRATION_MASTER_T xximt  , XX_IMD_JOB_MASTER_T xxj 
              WHERE xximt.job_id = xxj.id 
                and (xxj.JOB_NAME = cur_rec.DEFINITION OR xxj.JOB_NAME = cur_rec.VALUE);   

            EXCEPTION   
            WHEN NO_DATA_FOUND THEN   

                p_status :=p_status||':'|| sqlerrm;   
                WHEN OTHERS THEN   
                 p_status :=p_status||':'|| sqlerrm;  
            END;   
            BEGIN   

             SELECT XX_IMD_INTEG_RUN_T_SEQ.nextval INTO l_int_run_id FROM dual;   
              INSERT   
              INTO XX_IMD_INTEGRATION_RUN_T   
                (   
                  ID,   
                  INTEGRATION_STATUS,   
                  START_TIME,   
                  END_TIME, 
                  INTEGRATION_MASTER_ID,   
                  RUN_IDENTIFIER ,
               --     FLOWTASKNAME,
                 --   FLOWINSTANCENAME,
                    REQUEST_ID
                )   
                VALUES   
                (   
                  l_int_run_id ,   
                  cur_rec.EXECUTABLE_STATUS,   
                  TO_DATE(cur_rec.PROCESSSTART,'DD-MM-YYYY HH24:MI:SS')    , 
                  TO_DATE(cur_rec.PROCESSEND,'DD-MM-YYYY HH24:MI:SS')    ,   
                  l_master_id ,   
                  NULL  ,
                 --   cur_rec.FLOWTASKNAME,
                --    cur_rec.FLOWINSTANCENAME ,
                    cur_rec.REQUESTID
                );  


            EXCEPTION   
              WHEN OTHERS THEN   
                 p_status :=p_status||':'|| sqlerrm;  
            END;   



            BEGIN   
              SELECT XX_IMD_INTEG_ACTIVITY_T_SEQ.nextval INTO l_activity_id FROM dual;   
              INSERT   
              INTO XX_IMD_INTEGRATION_ACTIVITY_T   
                (   
                  ID ,   
                  INTEGRATION_RUN_ID ,   
                  ACTIVITY_NAME ,   
                  TOUCHPOINT_NAME,   
                  ACTIVITY_DATE,   
                  ACTIVITY_STATUS   
                )   
                VALUES   
                (   
                  l_activity_id ,   
                  l_int_run_id , 
                    DECODE(cur_rec.FLOWTASKNAME, NULL, cur_rec.FLOWINSTANCENAME,  cur_rec.FLOWTASKNAME),
                 -- 'Outbound',   
                  'BI Report' ,   
                  sysdate,   
                  cur_rec.EXECUTABLE_STATUS   
                );   

              commit; 

              INSERT INTO XX_IMD_ADDITIONAL_INFO_T   
					  (   
						ID ,   
						KEYNAME ,   
						VALUE ,   
						INTEGRATION_ACTIVITY_ID   
					  )   
					  VALUES   
					  (   
						XX_IMD_ADDNINFO_T_SEQ.nextval,   
						'ERROR REASON',   
						cur_rec.ERRORMSG,   
						l_activity_id   
					  ); 


            EXCEPTION   
            WHEN NO_DATA_FOUND THEN   
              p_status :=p_status||':'|| sqlerrm;   
               WHEN OTHERS THEN   
                 p_status :=p_status||':'|| sqlerrm;  
            END; 

       ---------------- 
*/
		INSERT INTO xx_imd_job_run_t( request_id   
			   , START_TIME   
			   , END_TIME   
			   , status   
			   , SUBMIT_TIME   
			   , PROGRAM_NAME   
			   , SUBMITTED_BY   
			   , TICKET_NUMBER  
			   , req_sequence  
			   , JOB_TYPE
			   , TRACK
               , PHASE_CODE
			   , FLOWTASKNAME
			   , FLOWINSTANCENAME
			   )    
		VALUES(  cur_rec.REQUESTID   
			  ,  TO_DATE(cur_rec.PROCESSSTART,'DD-MM-YYYY HH24:MI:SS')   
			  ,  TO_DATE(cur_rec.PROCESSEND  ,'DD-MM-YYYY HH24:MI:SS')   
			  ,  cur_rec.EXECUTABLE_STATUS   
			  ,  TO_DATE(cur_rec.REQUESTEDSTART,'DD-MM-YYYY HH24:MI:SS')   
			  ,  cur_rec.PROGRAMNAME   
			  ,  cur_rec.SUBMITTER   
			  ,  p_incident  
			  ,  x_req_seq  
			  ,  'O'
			  ,  cur_rec.ATTRIBUTE2   
              ,  cur_rec.ATTRIBUTE1
			  ,  cur_rec.FLOWTASKNAME   
			  ,  cur_rec.FLOWINSTANCENAME
			  );   								  

      COMMIT;   
        COMMIT;   
    END LOOP;	   

	/*FOR cur_req IN (SELECT DISTINCT REQUEST_ID FROM xx_imd_job_run_t)   
	LOOP   
		NULL;  
        XX_APEX_GEN_RUN_REP_PKG.parameter_main(p_arg1);   
	END LOOP;  */ 

	exception
		when others then
		x_err:=sqlerrm;

END get_reqID_outbound;    



procedure get_reqID_long_extracts (   
   p_arg1 in varchar2 default null,   
   p_arg2 in number   default null)   
IS    
  cursor c1 is select * from XX_IMD_JOB_MASTER_T where enable_flag = 'Y' and job_type = 'O' and threshold IS NOT NULL;   
  v_query CLOB := NULL;   
  x_xml_output XMLTYPE;   
  v_max_time DATE;   

	x_max_date       DATE;   
	x_job_date       VARCHAR2(100);   
	x_date_syntx     VARCHAR2(100);       
	p_incident       VARCHAR2(100):= NULL;    
	x_req_seq        NUMBER;   
    V_IMPACT         VARCHAR2(1) ;  
    V_PRIORITY       VARCHAR2(1) ;  
    V_WEEKDAY        VARCHAR2(1) ;  
    V_WEEKEND        VARCHAR2(1) ;  
    V_MONTHEND        VARCHAR2(1) ;  
    v_weekday_end     VARCHAR2(10);  
    V_DIFF            NUMBER;  
    v_long_desc       VARCHAR2(1000);  

	l_master_id       NUMBER; 
    l_short_desc      VARCHAR2(1000);  
    L_INT_RUN_ID NUMBER; 
    L_ACTIVITY_ID NUMBER; 
    p_status VARCHAR2(2000); 

     l_clob      CLOB;   
    l_body      varchar2(32767);   
    l_feature_count  pls_integer;   
   j APEX_JSON.t_values;   
   x_encrypt_blob BLOB; 
   l_xml_result clob; 
   v_value apex_json.t_value;
   x_err_msg  VARCHAR2(1000);   

   	x_err_flag       VARCHAR2(1):='N';   
	x_user_name      VARCHAR2(100);   
    x_password       VARCHAR2(100);   
    x_url            VARCHAR2(1000);   

BEGIN   



--DBMS_OUTPUT.PUT_LINE('Hi');   
    select max(SUBMIT_TIME)   
    INTO v_max_time   
    FROM XX_IMD_JOB_RUN_T a, XX_IMD_JOB_MASTER_T b  WHERE b.JOB_TYPE='O' AND a.program_name = b.job_name and threshold IS NOT NULL;   

    v_max_time := NVL(v_max_time, sysdate -2);   
    x_job_date:=TO_CHAR(v_max_time,'DD-MM-YYYY HH24:MI:SS');   
    x_date_syntx := ''''||'DD-MM-YYYY HH24:MI:SS'||'''';   
    DBMS_OUTPUT.PUT_LINE('x_job_date: '||x_job_date);   

    /*for i in c1 loop  

          v_query := v_query||' SELECT essr.SUBMITTER, DECODE(essr.executable_status,''SUCCEEDED'',''SUCCESS'',essr.executable_status) executable_status , to_char(essr.PROCESSEND,''dd-mon-yyyy HH24:MI:SS'') PROCESSEND, to_char(essr.processstart,''dd-mon-yyyy HH24:MI:SS'') processstart,to_char(essr.REQUESTEDSTART,''dd-mon-yyyy HH24:MI:SS'')  REQUESTEDSTART,  round((cast(essr.PROCESSEND as date) - cast(essr.PROCESSSTART as date))* 24 * 60) diff_minutes, essp.value definition, essr.requestid FROM ess_request_history essr,fusion_ora_ess.request_property_view essp WHERE essr.requestid = essp.requestid  AND round((cast(PROCESSEND as date) - cast(PROCESSSTART as date))* 24 * 60) >= '||i.threshold||' and to_date(to_char(REQUESTEDSTART,''dd-mm-yyyy HH24:MI:SS''),''dd-mm-yyyy HH24:MI:SS'') > to_date('||x_job_date||','||x_date_syntx||') AND essp.value = '''||i.job_name||''' UNION ALL';   


     -- v_query := v_query||' SELECT SUBMITTER, executable_status, to_char(PROCESSEND,''dd-mon-yyyy HH24:MI:SS'') PROCESSEND, to_char(processstart,''dd-mon-yyyy HH24:MI:SS'') processstart,to_char(REQUESTEDSTART,''dd-mon-yyyy HH24:MI:SS'')  REQUESTEDSTART,  round((cast(PROCESSEND as date) - cast(PROCESSSTART as date))* 24 * 60) diff_minutes, definition, requestid FROM ess_request_history WHERE to_date(to_char(REQUESTEDSTART,''dd-mm-yyyy HH24:MI:SS''),''dd-mm-yyyy HH24:MI:SS'') > to_date('||x_job_date||','||x_date_syntx||') AND round((cast(PROCESSEND as date) - cast(PROCESSSTART as date))* 24 * 60) >= '||i.threshold||' AND definition = '''||i.job_name||''' UNION ALL';   
    end LOOP;   */

	for i in c1 loop   
      v_query := v_query||i.job_name||',' ;   
    end LOOP;   
    v_query := v_query ||'null'; 
    DBMS_OUTPUT.PUT_LINE(v_query);  

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
	 /* XX_APEX_GEN_RUN_REP_PKG.main(v_query,x_xml_output);   */
  	 l_body := '{ "p_reportName":"LongRunningJobs", "p_date":"'|| x_job_date||'" ,"p_jobname":"'||v_query||'"}';   

     dbms_output.put_line(l_body);   


     apex_web_service.g_request_headers.delete();   
        apex_web_service.g_request_headers(1).name := 'Content-Type';   
        apex_web_service.g_request_headers(1).value := 'application/json';   

         l_clob := apex_web_service.make_rest_request(   
        p_url => x_url || ':443/ic/api/integration/v1/flows/rest/AXE_DP_SCHEDU_RPT_INT/1.0/runDpReport',   
        p_http_method => 'POST',   
        p_username => x_user_name,   
        p_password => x_password,   
        p_body => l_body);   


   apex_json.parse (l_clob);   


    v_value := apex_json.get_value ('p_result');   


   l_xml_result := v_value.varchar2_value;
   if l_xml_result is null then
       l_xml_result := v_value.clob_value;
   end if;


   --apex_json.get_varchar2 ('p_result');   

      x_encrypt_blob:= base64DecodeClobAsBlob(l_xml_result); 

      convert_blob_to_xmltype(x_encrypt_blob,x_xml_output); 

    EXCEPTION   
      WHEN OTHERS   
	   THEN   
	    x_xml_output:= NULL;   
		x_err_msg := sqlerrm;
    END;	   

       x_req_seq := xx_req_seq.NEXTVAL;   

      FOR cur_rec IN (   
      SELECT xt.*   
      FROM   XMLTABLE('/DATA_DS/G_1'   
               PASSING x_xml_output   
               COLUMNS    
                 EXECUTABLE_STATUS VARCHAR2(100) PATH 'EXECUTABLE_STATUS',   
                 PROCESSEND VARCHAR2(100) PATH 'PROCESSEND',   
                 PROCESSSTART VARCHAR2(100) PATH 'PROCESSSTART',   
                 REQUESTEDSTART VARCHAR2(100) PATH 'REQUESTEDSTART',   
                 DIFF_MINUTES     VARCHAR2(100) PATH 'DIFF_MINUTES',   
                 DEFINITION          VARCHAR2(100) PATH 'DEFINITION',    
                 REQUESTID     VARCHAR2(100) PATH 'REQUESTID',    
                 SUBMITTER     VARCHAR2(100) PATH 'SUBMITTER'   
               ) xt)   
      LOOP   

	   BEGIN  

       SELECT WEEKDAY_PRIORITY,WEEKEND_PRIORITY,MONTHEND_PRIORITY  
         INTO V_WEEKDAY,V_WEEKEND,V_MONTHEND  
         FROM XX_IMD_JOB_MASTER_T  
        WHERE JOB_NAME =  cur_rec.DEFINITION;  
       EXCEPTION  
       WHEN OTHERS THEN  
       V_IMPACT:='3';  
       V_PRIORITY:='3';  
       END;    
       dbms_output.put_line(V_IMPACT||':'||V_PRIORITY) ;     

       SELECT TO_CHAR(TO_DATE(cur_rec.REQUESTEDSTART,'DD-MM-YYYY HH24:MI:SS'), 'DY') day   
         INTO v_weekday_end  
        FROM DUAL;   

        IF v_weekday_end IN ('SAT','SUN') THEN  
       V_IMPACT:=  V_WEEKEND;  
       V_PRIORITY:= V_WEEKEND;    
       ELSE  
       V_IMPACT:=  V_WEEKDAY;  
       V_PRIORITY:= V_WEEKDAY;  
        END IF;  

        /*SELECT (SYSDATE - LAST_DAY(TO_DATE(cur_rec.REQUESTEDSTART,'DD-MM-YYYY HH24:MI:SS')) ) INTO V_DIFF FROM DUAL;  */

        IF V_DIFF = 0 OR V_DIFF = -1 THEN  

         V_IMPACT:=  V_MONTHEND;  
         V_PRIORITY:= V_MONTHEND;  
        END IF;  

        --SELECT NVL(description, NULL) INTO v_long_desc FROM XX_IMD_JOB_MASTER_T where JOB_NAME = cur_rec.DEFINITION;  



      /* xx_snow_ticket_create( 'Program :'||v_long_desc||' is running for '||cur_rec.DIFF_MINUTES||' mins',  
                             V_IMPACT,                              
                             'Program :'||v_long_desc||' with request ID:'||cur_rec.REQUESTID||' is running for '||cur_rec.DIFF_MINUTES||' mins',  
                             'Long Running Job',  
                             V_PRIORITY,  
                             p_incident  
                             );  
                             */
        dbms_output.put_line(V_IMPACT||':'||V_PRIORITY) ;                      

       INSERT INTO xx_imd_job_run_t( request_id   
                                   , START_TIME   
                                   , END_TIME   
                                   , status   
                                   , SUBMIT_TIME   
                                   , PROGRAM_NAME   
                                   , SUBMITTED_BY   
                                   , TICKET_NUMBER  
								   , req_sequence  
								   )    
	                        VALUES(  cur_rec.REQUESTID   
                                  ,  TO_DATE(cur_rec.PROCESSSTART,'DD-MM-YYYY HH24:MI:SS')   
			                      ,  TO_DATE(cur_rec.PROCESSEND  ,'DD-MM-YYYY HH24:MI:SS')   
			                      ,  cur_rec.EXECUTABLE_STATUS   
                                  ,  TO_DATE(cur_rec.REQUESTEDSTART,'DD-MM-YYYY HH24:MI:SS')   
                                  ,  cur_rec.DEFINITION   
                                  ,  cur_rec.SUBMITTER   
                                  ,  p_incident  
                                  ,  x_req_seq  
			                      );   

       /*INSERT INTO xx_crit_job_main( DIFF_MINUTES   
	                               , REQUESTID   
                                   , DEFINITION   
								   )    
	                        VALUES(  cur_rec.DIFF_MINUTES   
  	                              ,  cur_rec.REQUESTID   
			                      ,  cur_rec.DEFINITION   
			                      );*/   
      COMMIT;   
    END LOOP;	   

	--FOR cur_req IN (SELECT DISTINCT REQUEST_ID FROM xx_imd_job_run_t)   
--	LOOP   
		--NULL;  
        /*XX_APEX_GEN_RUN_REP_PKG.parameter_main(p_arg1);   */
	--END LOOP;   
exception
when others then
null;

END get_reqID_long_extracts;   

procedure get_reqID_crit_extracts (   
   p_arg1 in varchar2 default null,   
   p_arg2 in number   default null)   
IS    
  --cursor c1 is select * from XX_IMD_JOB_MASTER_T where enable_flag = 'Y' and job_type = 'C';   
  cursor c1 is select * from XX_IMD_JOB_MASTER_T where enable_flag = 'Y' and job_type = 'C';   

  v_query CLOB := NULL;   
  x_xml_output XMLTYPE;   
  v_max_time DATE;   

	x_max_date       DATE;   
	x_job_date       VARCHAR2(100);   
	x_date_syntx     VARCHAR2(100);       
	p_incident       VARCHAR2(100);    
	x_req_seq        NUMBER;   
    V_IMPACT         VARCHAR2(1) ;  
    V_PRIORITY       VARCHAR2(1) ;  
    V_WEEKDAY        VARCHAR2(1) ;  
    V_WEEKEND        VARCHAR2(1) ;  
    V_MONTHEND        VARCHAR2(1) ;  
    v_weekday_end     VARCHAR2(10);  
    V_DIFF            NUMBER;  
    v_long_desc       VARCHAR2(1000); 
    v_error    VARCHAR2(1000);

	l_master_id       NUMBER; 
    l_short_desc      VARCHAR2(1000);  
    L_INT_RUN_ID NUMBER; 
    L_ACTIVITY_ID NUMBER; 
    p_status VARCHAR2(2000); 
     x_err_msg VARCHAR2(2000);
     l_clob      CLOB;   
    l_body      varchar2(32767);   
    l_feature_count  pls_integer;   
   j APEX_JSON.t_values;   
   x_encrypt_blob BLOB; 
   l_xml_result clob; 
   v_value apex_json.t_value;

   	x_err_flag       VARCHAR2(1):='N';   
	x_user_name      VARCHAR2(100);   
    x_password       VARCHAR2(100);   
    x_url            VARCHAR2(1000);   
BEGIN   

	select max(SUBMIT_TIME)   
    INTO v_max_time   
    FROM XX_IMD_JOB_RUN_T a, XX_IMD_JOB_MASTER_T b  WHERE b.JOB_TYPE='C' AND a.program_name = b.job_name ;    



	v_max_time := NVL(v_max_time, sysdate -2);   
    x_job_date:=TO_CHAR(v_max_time,'DD-MM-YYYY HH24:MI:SS');   
    x_date_syntx := ''''||'DD-MM-YYYY HH24:MI:SS'||'''';   
    DBMS_OUTPUT.PUT_LINE('x_job_date: '||x_job_date);   


	for i in c1 loop   
      v_query := v_query||i.job_name||',' ;   
    end LOOP;   
    v_query := v_query ||'null'; 
    DBMS_OUTPUT.PUT_LINE(v_query);  

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
	 /* XX_APEX_GEN_RUN_REP_PKG.main(v_query,x_xml_output);   */
  	 l_body := '{ "p_reportName":"CriticalJobs", "p_date":"'|| x_job_date||'" ,"p_jobname":"'||v_query||'"}';   
     /*l_body := '{ "p_reportName":"OutboundJobs", "p_date":"'|| x_job_date||'" ,"p_jobname":"'||v_query||'"}';   */


     dbms_output.put_line(l_body);   

     apex_web_service.g_request_headers.delete();   
        apex_web_service.g_request_headers(1).name := 'Content-Type';   
        apex_web_service.g_request_headers(1).value := 'application/json';   

     l_clob := apex_web_service.make_rest_request(   
        p_url => x_url || ':443/ic/api/integration/v1/flows/rest/AXE_DP_SCHEDU_RPT_INT/1.0/runDpReport',   
        p_http_method => 'POST',   
        p_username => x_user_name,   
        p_password => x_password,   
        p_body => l_body);   


   apex_json.parse (l_clob);   

    v_value := apex_json.get_value ('p_result');   

   l_xml_result := v_value.varchar2_value;
   if l_xml_result is null then
       l_xml_result := v_value.clob_value;
   end if;

   --apex_json.get_varchar2 ('p_result');   

      x_encrypt_blob:= base64DecodeClobAsBlob(l_xml_result); 

  	   convert_blob_to_xmltype(x_encrypt_blob,x_xml_output); 

    EXCEPTION   
      WHEN OTHERS   
	   THEN   
	    x_err_msg := sqlerrm;

    END;	   

	x_req_seq := xx_req_seq.NEXTVAL;   

      FOR cur_rec IN (   
      SELECT xt.*   
      FROM   XMLTABLE('/DATA_DS/G_1'   
               PASSING x_xml_output   
               COLUMNS    
                 EXECUTABLE_STATUS VARCHAR2(1000) PATH 'EXECUTABLE_STATUS',   
                 PROCESSEND VARCHAR2(1000) PATH 'PROCESSEND',   
                 PROCESSSTART VARCHAR2(1000) PATH 'PROCESSSTART',   
                 REQUESTEDSTART VARCHAR2(1000) PATH 'REQUESTEDSTART',   
                 DIFF_MINUTES     VARCHAR2(1000) PATH 'DIFF_MINUTES',   
                 DEFINITION          VARCHAR2(1000) PATH 'DEFINITION',    
                 REQUESTID     VARCHAR2(1000) PATH 'REQUESTID',    
                 SUBMITTER     VARCHAR2(1000) PATH 'SUBMITTER'   
               ) xt)   
      LOOP   
	  	     DBMS_OUTPUT.PUT_LINE(cur_rec.REQUESTID);
	  /*BEGIN   

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

	   END;*/   
       BEGIN  

       SELECT WEEKDAY_PRIORITY,WEEKEND_PRIORITY,MONTHEND_PRIORITY  
         INTO V_WEEKDAY,V_WEEKEND,V_MONTHEND  
         FROM XX_IMD_JOB_MASTER_T  
        WHERE JOB_NAME =  cur_rec.DEFINITION;  
       EXCEPTION  
       WHEN OTHERS THEN  
       V_IMPACT:='3';  
       V_PRIORITY:='3';  
       END;    
       dbms_output.put_line(V_IMPACT||':'||V_PRIORITY) ;     

       SELECT TO_CHAR(TO_DATE(cur_rec.REQUESTEDSTART,'DD-MM-YYYY HH24:MI:SS'), 'DY') day   
         INTO v_weekday_end  
        FROM DUAL;   

        IF v_weekday_end IN ('SAT','SUN') THEN  
       V_IMPACT:=  V_WEEKEND;  
       V_PRIORITY:= V_WEEKEND;    
       ELSE  
       V_IMPACT:=  V_WEEKDAY;  
       V_PRIORITY:= V_WEEKDAY;  
        END IF;  

        /*SELECT (SYSDATE - LAST_DAY(TO_DATE(cur_rec.REQUESTEDSTART,'DD-MM-YYYY HH24:MI:SS')) ) INTO V_DIFF FROM DUAL;  */

        IF V_DIFF = 0 OR V_DIFF = -1 THEN  

         V_IMPACT:=  V_MONTHEND;  
         V_PRIORITY:= V_MONTHEND;  
        END IF;  

    --SELECT description INTO v_long_desc FROM XX_IMD_JOB_MASTER_T where JOB_NAME = cur_rec.DEFINITION;  

        dbms_output.put_line(cur_rec.DEFINITION||':'||cur_rec.DIFF_MINUTES||cur_rec.REQUESTID) ;     


        dbms_output.put_line(V_IMPACT||':'||V_PRIORITY) ;                      

       INSERT INTO xx_imd_job_run_t( request_id   
                                   , START_TIME   
                                   , END_TIME   
                                   , status   
                                   , SUBMIT_TIME   
                                   , PROGRAM_NAME   
                                   , SUBMITTED_BY   
                                   , TICKET_NUMBER  
								   , req_sequence  
								   )    
	                        VALUES(  cur_rec.REQUESTID   
                                  ,  TO_DATE(cur_rec.PROCESSSTART,'DD-MM-YYYY HH24:MI:SS')   
			                      ,  TO_DATE(cur_rec.PROCESSEND  ,'DD-MM-YYYY HH24:MI:SS')   
			                      ,  cur_rec.EXECUTABLE_STATUS   
                                  ,  TO_DATE(cur_rec.REQUESTEDSTART,'DD-MM-YYYY HH24:MI:SS')   
                                  ,  cur_rec.DEFINITION   
                                  ,  cur_rec.SUBMITTER   
                                  ,  p_incident  
                                  ,  x_req_seq  
			                      );   

       /*INSERT INTO xx_crit_job_main( DIFF_MINUTES   
	                               , REQUESTID   
                                   , DEFINITION   
								   )    
	                        VALUES(  cur_rec.DIFF_MINUTES   
  	                              ,  cur_rec.REQUESTID   
			                      ,  cur_rec.DEFINITION   
			                      );*/   
      COMMIT;   
    END LOOP;	   

	--FOR cur_req IN (SELECT DISTINCT REQUEST_ID FROM xx_imd_job_run_t)   
	--LOOP   
		--NULL;  
        XX_APEX_GEN_RUN_REP_PKG.parameter_main(p_arg1);   
	--END LOOP;   

END get_reqID_crit_extracts; 





Procedure INSERT_REC_OUTBOUNDJOBS(P_INS_VAL WSC_OUTBOUNDJOBS_OUTPUT_T_TAB,
	P_ERR_MSG OUT VARCHAR2,
	P_ERR_CODE OUT VARCHAR2) IS
    
    x_req_seq number;
    p_incident       VARCHAR2(100); 
	--L_ERR_MSG VARCHAR2(2000);
	--L_ERR_CODE VARCHAR2(2);
BEGIN
    x_req_seq := xx_req_seq.NEXTVAL;
    FOR i in P_INS_VAL.FIRST..P_INS_VAL.LAST LOOP
        Begin
            INSERT INTO xx_imd_job_run_t( request_id   
                   , START_TIME   
                   , END_TIME   
                   , status   
                   , SUBMIT_TIME   
                   , PROGRAM_NAME   
                   , SUBMITTED_BY   
                   , TICKET_NUMBER  
                   , req_sequence  
                   , JOB_TYPE
                   , TRACK
                   , PHASE_CODE
                   , FLOWTASKNAME
                   , FLOWINSTANCENAME
                   )    
            VALUES(  P_INS_VAL(i).REQUESTID   
                  ,  TO_DATE(P_INS_VAL(i).PROCESSSTART,'DD-MM-YYYY HH24:MI:SS')   
                  ,  TO_DATE(P_INS_VAL(i).PROCESSEND  ,'DD-MM-YYYY HH24:MI:SS')   
                  ,  P_INS_VAL(i).EXECUTABLE_STATUS   
                  ,  TO_DATE(P_INS_VAL(i).REQUESTEDSTART,'DD-MM-YYYY HH24:MI:SS')   
                  ,  P_INS_VAL(i).PROGRAMNAME   
                  ,  P_INS_VAL(i).SUBMITTER   
                  ,  p_incident  
                  ,  x_req_seq  
                  ,  'O'
                  ,  P_INS_VAL(i).ATTRIBUTE2   
                  ,  P_INS_VAL(i).ATTRIBUTE1
                  ,  P_INS_VAL(i).FLOWTASKNAME   
                  ,  P_INS_VAL(i).FLOWINSTANCENAME
                  );   
        Commit;
        Exception
            WHEN OTHERS THEN
                P_ERR_MSG := P_ERR_MSG ||' . ' ||SQLERRM; 
                P_ERR_CODE := SQLCODE;
        END;       
    END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		P_ERR_MSG := 'Error while inserting ' ||' . ' || P_ERR_MSG ;
		P_ERR_CODE := 2; 
END;



Procedure INSERT_REC_LONGRUNNINGJOBS(P_INS_VAL WSC_LONGRUNNINGJOBS_OUTPUT_T_TAB,
	P_ERR_MSG OUT VARCHAR2,
	P_ERR_CODE OUT VARCHAR2) IS
	
    x_req_seq number;
    p_incident       VARCHAR2(100); 
	--L_ERR_MSG VARCHAR2(2000);
	--L_ERR_CODE VARCHAR2(2);
BEGIN
    x_req_seq := xx_req_seq.NEXTVAL;
    FOR i in P_INS_VAL.FIRST..P_INS_VAL.LAST LOOP
        Begin
            INSERT INTO xx_imd_job_run_t( request_id   
                   , START_TIME   
                   , END_TIME   
                   , status   
                   , SUBMIT_TIME   
                   , PROGRAM_NAME   
                   , SUBMITTED_BY   
                   , TICKET_NUMBER  
                   , req_sequence  
                   , JOB_TYPE
                   , TRACK
                   , PHASE_CODE
                   )    
            VALUES(  P_INS_VAL(i).REQUESTID   
                  ,  TO_DATE(P_INS_VAL(i).PROCESSSTART,'DD-MM-YYYY HH24:MI:SS')   
                  ,  TO_DATE(P_INS_VAL(i).PROCESSEND  ,'DD-MM-YYYY HH24:MI:SS')   
                  ,  P_INS_VAL(i).EXECUTABLE_STATUS   
                  ,  TO_DATE(P_INS_VAL(i).REQUESTEDSTART,'DD-MM-YYYY HH24:MI:SS')   
                  ,  P_INS_VAL(i).PROGRAMNAME   
                  ,  P_INS_VAL(i).SUBMITTER   
                  ,  p_incident  
                  ,  x_req_seq  
                  ,'L'
                  ,  P_INS_VAL(i).ATTRIBUTE2   
                  ,  P_INS_VAL(i).ATTRIBUTE1
                  );  
        Commit;
        Exception
            WHEN OTHERS THEN
                P_ERR_MSG := P_ERR_MSG ||' . ' ||SQLERRM; 
                P_ERR_CODE := SQLCODE;
        END;       
    END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		P_ERR_MSG := 'Error while inserting ' ||' . ' || P_ERR_MSG ;
		P_ERR_CODE := 2; 
END;




Procedure INSERT_REC_CRITICALJOBS(P_INS_VAL WSC_CRITICALJOBS_OUTPUT_T_TAB,
	P_ERR_MSG OUT VARCHAR2,
	P_ERR_CODE OUT VARCHAR2) IS
	
    x_req_seq number;
    p_incident       VARCHAR2(100); 
	--L_ERR_MSG VARCHAR2(2000);
	--L_ERR_CODE VARCHAR2(2);
BEGIN
    x_req_seq := xx_req_seq.NEXTVAL;
    FOR i in P_INS_VAL.FIRST..P_INS_VAL.LAST LOOP
        Begin
            INSERT INTO xx_imd_job_run_t( request_id   
                   , START_TIME   
                   , END_TIME   
                   , status   
                   , SUBMIT_TIME   
                   , PROGRAM_NAME   
                   , SUBMITTED_BY   
                   , TICKET_NUMBER  
                   , req_sequence  
                   , JOB_TYPE
                   , TRACK
                   , PHASE_CODE
                   )    
            VALUES(  P_INS_VAL(i).REQUESTID   
                  ,  TO_DATE(P_INS_VAL(i).PROCESSSTART,'DD-MM-YYYY HH24:MI:SS')   
                  ,  TO_DATE(P_INS_VAL(i).PROCESSEND  ,'DD-MM-YYYY HH24:MI:SS')   
                  ,  P_INS_VAL(i).EXECUTABLE_STATUS   
                  ,  TO_DATE(P_INS_VAL(i).REQUESTEDSTART,'DD-MM-YYYY HH24:MI:SS')   
                  ,  P_INS_VAL(i).PROGRAMNAME   
                  ,  P_INS_VAL(i).SUBMITTER   
                  ,  p_incident  
                  ,  x_req_seq  
                  ,'C'
                  ,  P_INS_VAL(i).ATTRIBUTE2   
                  ,  P_INS_VAL(i).ATTRIBUTE1
                  );   
        Commit;
        Exception
            WHEN OTHERS THEN
                P_ERR_MSG := P_ERR_MSG ||' . ' ||SQLERRM; 
                P_ERR_CODE := SQLCODE;
        END;       
    END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		P_ERR_MSG := 'Error while inserting ' ||' . ' || P_ERR_MSG ;
		P_ERR_CODE := 2; 
END;


END XX_APEX_GET_ESS_DET_SEC_PKG;
/