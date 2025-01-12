SET DEFINE OFF;
/*=====================================================*/
      /* PROCEDURE XX_SNOW_TICKET_CREATE */
/*=====================================================*/
create or replace PROCEDURE  "XX_SNOW_TICKET_CREATE" (p_short_desc IN VARCHAR2,    
                                                  p_impact   IN VARCHAR2,    
                                                  p_desc       IN VARCHAR2,    
                                                  p_job_type   IN VARCHAR2,    
                                                  p_urgent   IN VARCHAR2,     
                                                  p_incident   OUT varchar2) IS    
    l_clob      varchar2(32767);    
    l_body      varchar2(32767);    
    l_feature_count  pls_integer;    
   j APEX_JSON.t_values;     
  -- SNOW_INSTANCE_DOWN EXCEPTION;     
   --p_incident     varchar2(32767);    
BEGIN    
        
    l_body := ' {    
 	"short_description":  "'||p_short_desc||'" ,    
    "comments": "'||p_job_type||'",    
    "caller_id":  "62826bf03710200044e0bfc8bcbe5df1" ,    
    "severity" : "'||p_short_desc||'" ,    
     "description" : "'||p_desc||'" ,    
     "urgency" : "'||p_urgent||'",    
     "impact"    : "'||p_impact||'"    
        
}';    
       
     dbms_output.put_line(l_body);    
     BEGIN    
    l_clob := apex_web_service.make_rest_request(    
        p_url => 'https://dev86372.service-now.com/api/now/v1/table/incident?number=INC0010002',    
        p_http_method => 'POST',    
        p_username => 'admin',    
        p_password => 'ypTv8MnCR1Bt',    
        p_body => l_body);    
        dbms_output.put_line(l_clob);    
       APEX_JSON.parse(j,l_clob);    
       apex_json.parse(p_source =>l_clob);    
            l_feature_count := apex_json.get_count( 'result' );    
        --dbms_output.put_line('l_clob: '||l_clob);    
       p_incident := APEX_JSON.GET_VARCHAR2(p_path=>'result.number',p_values=>j);    
       EXCEPTION    
       WHEN OTHERS THEN    
       dbms_output.put_line('SNOW Instance down');    
       END;    
            
end;    
/
