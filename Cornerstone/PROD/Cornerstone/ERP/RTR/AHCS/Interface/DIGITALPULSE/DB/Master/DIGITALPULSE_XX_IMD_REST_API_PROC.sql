SET DEFINE OFF;
/*=====================================================*/
      /* PROCEDURE XX_IMD_REST_API */
/*=====================================================*/
create or replace PROCEDURE  "XX_IMD_REST_API" (p_body clob) as  
/*p_payload  BLOB ;*/  
p_status  VARCHAR2(200);  
  
l_xml SYS.XMLTYPE := sys.xmltype(p_body);  
p_clob CLOB;  
  
begin  
--p_payload := p_body ;  
  
  
--p_clob := wwv_flow_utilities.blob_to_clob(/*p_payload*/p_body);  
  
APEX_JSON.initialize_clob_output;  
  
  APEX_JSON.write(l_xml);  
  
  DBMS_OUTPUT.put_line(APEX_JSON.get_clob_output);  
    
XX_IMD_PUBLISH_PKG.publishIntegration(/*p_clob*/APEX_JSON.get_clob_output,p_status);  
  
  APEX_JSON.free_output;  
    
end;
/