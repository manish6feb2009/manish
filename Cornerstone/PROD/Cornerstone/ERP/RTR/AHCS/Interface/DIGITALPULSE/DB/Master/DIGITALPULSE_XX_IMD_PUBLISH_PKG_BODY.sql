SET DEFINE OFF;
/*=====================================================*/
 /* PACKAGE BODY XX_IMD_PUBLISH_PKG */
/*=====================================================*/
create or replace PACKAGE BODY  "XX_IMD_PUBLISH_PKG"  
IS    
  PROCEDURE publishIntegration(    
      p_payload IN CLOB,    
      p_status OUT VARCHAR2)    
  AS    
    l_numcols NUMBER;    
    --p_payload   clob := '{"ricew_code":"FIN-INT-100","link_name":"ABC.txt","touchpoint_name":"ODI","touchpoint_status":"RUNNING","integration_status":"RUNNING","run_id":"ODI-111","activity_name":"Read File","activity_desc":"File started reading","additional_info":[{"key":"filename","value":"ABC.txt"},{"key":"No of Records","value":"100"}]}';    
    l_master_id   NUMBER;    
    l_instance_id NUMBER;    
    l_int_run_id  NUMBER;    
    l_activity_id NUMBER;    
    l_clob CLOB;    
    l_blob BLOB;    
    l_long_desc VARCHAR2(2000);   
    l_short_desc VARCHAR2(2000);   
    p_incident       VARCHAR2(100);      
  BEGIN    
   -- insert into test_hm values (p_payload);    
	--commit;    
    dbms_output.put_line('parsing');
    apex_json.parse (p_payload); 
    dbms_output.put_line('parsed');
    l_master_id:=0;    
    BEGIN    
      SELECT id,description    
      INTO l_master_id ,l_short_desc   
      FROM XX_IMD_INTEGRATION_MASTER_T    
      WHERE rice_code=apex_json.get_varchar2 ('rice_code');    

    EXCEPTION    
    WHEN NO_DATA_FOUND THEN    
      /*SELECT XX_IMD_INTEG_MASTER_T_SEQ.nextval INTO l_master_id FROM dual;    
      INSERT    
      INTO XX_IMD_INTEGRATION_MASTER_T    
        (    
          ID,    
          INTEGRATION_CODE,    
          DESCRIPTION,    
          INTEGRATION_TYPE,    
          RICE_CODE    
        )    
        VALUES    
        (    
          l_master_id ,    
          apex_json.get_varchar2 ('integration_code') ,    
          apex_json.get_varchar2 ('integration_desc') ,    
          apex_json.get_varchar2 ('integration_type') ,    
          apex_json.get_varchar2 ('ricew_code')    
        );*/    
        p_status :=p_status||':'|| sqlerrm;
        dbms_output.put_line('51');
        WHEN OTHERS THEN    
         p_status :=p_status||':'|| sqlerrm; 
         dbms_output.put_line('54');
    END;    
    BEGIN    

      SELECT id    
      INTO l_int_run_id    
      FROM XX_IMD_INTEGRATION_RUN_T    
      WHERE run_identifier        =apex_json.get_varchar2 ('run_identifier')    
      AND integration_master_id=l_master_id;    

    EXCEPTION    
    WHEN NO_DATA_FOUND THEN    
      SELECT XX_IMD_INTEG_RUN_T_SEQ.nextval INTO l_int_run_id FROM dual; 
      dbms_output.put_line('67');

BEGIN  
insert into tbl_time_t values(apex_json.get_varchar2('end_time'),sysdate,99999);
      INSERT    	   
      INTO XX_IMD_INTEGRATION_RUN_T    
        (    
          ID,    
          INTEGRATION_STATUS,    
          START_TIME,    
          END_TIME,  
          RECON_ID,  
          INTEGRATION_MASTER_ID,    
          RUN_IDENTIFIER    
        )    
        VALUES    
        (    
          l_int_run_id ,    
          apex_json.get_varchar2 ('integration_status') ,    
          --DECODE(apex_json.get_varchar2 ('integration_status'),'RUNNING',NULL,NVL2(apex_json.get_varchar2 ('start_time'),to_date('12/03/2020','DD/MM/YYYY'),systimestamp)),  
          DECODE(apex_json.get_varchar2 ('integration_status'),'RUNNING',NULL,NVL2(apex_json.get_varchar2 ('start_time'),TO_CHAR(TO_DATE(substr(replace(apex_json.get_varchar2 ('start_time'),'T',' '),1,19),'RRRR-MM-DD HH24:MI:SS'),'DD-MON-RR HH:MI:SS AM') ,systimestamp)),  
          DECODE(apex_json.get_varchar2 ('integration_status'),'RUNNING',NULL,NVL2(apex_json.get_varchar2 ('end_time'),TO_CHAR(TO_DATE(substr(replace(apex_json.get_varchar2 ('end_time'),'T',' '),1,19),'RRRR-MM-DD HH24:MI:SS'),'DD-MON-RR HH:MI:SS AM') ,systimestamp)) ,   
          apex_json.get_varchar2 ('run_recon_id')  ,  
          l_master_id ,    
          apex_json.get_varchar2 ('run_identifier')    
        );   
        COMMIT;  
	  EXCEPTION  
	  WHEN OTHERS THEN    
         p_status :=p_status||':'|| sqlerrm;
         dbms_output.put_line('96');

	  END;  
         WHEN OTHERS THEN    
         p_status :=p_status||':'|| sqlerrm;
         dbms_output.put_line('101');


    END;    
    BEGIN    
    insert into tbl_time_t values ('before update' || l_int_run_id || apex_json.get_varchar2 ('integration_status'),sysdate,1);
    commit;

    --select systimestamp into p_status from dual;   
      UPDATE XX_IMD_INTEGRATION_RUN_T    
      SET end_time        = DECODE(apex_json.get_varchar2 ('integration_status'),'RUNNING',NULL,NVL2(apex_json.get_varchar2 ('end_time'),TO_CHAR(TO_DATE(substr(replace(apex_json.get_varchar2 ('end_time'),'T',' '),1,19),'RRRR-MM-DD HH24:MI:SS'),'DD-MON-RR HH:MI:SS AM') ,systimestamp)),
        INTEGRATION_STATUS=apex_json.get_varchar2 ('integration_status'),    
        run_identifier        =apex_json.get_varchar2 ('run_identifier')      
      WHERE id            =l_int_run_id;    
	  COMMIT;  

      insert into tbl_time_t values ('after update' || l_int_run_id || apex_json.get_varchar2 ('integration_status'),sysdate,1);
    commit;
    EXCEPTION    
    WHEN OTHERS THEN    
      p_status :=p_status||':'|| sqlerrm;
      dbms_output.put_line('122');
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
          apex_json.get_varchar2 ('activity_name') ,    
          apex_json.get_varchar2 ('touchpoint_name') ,    
          DECODE(apex_json.get_varchar2 ('integration_status'),'RUNNING',NULL,NVL2(apex_json.get_varchar2 ('end_time'),TO_CHAR(TO_DATE(substr(replace(apex_json.get_varchar2 ('end_time'),'T',' '),1,19),'RRRR-MM-DD HH24:MI:SS'),'DD-MON-RR HH:MI:SS AM') ,systimestamp)),    
          apex_json.get_varchar2 ('integration_status')   
        );    
        COMMIT;  
    EXCEPTION    
    WHEN NO_DATA_FOUND THEN    
      p_status :=p_status||':'|| sqlerrm;
      dbms_output.put_line('150');
       WHEN OTHERS THEN    
         p_status :=p_status||':'|| sqlerrm;
         dbms_output.put_line('153');
    END;   
    begin   
    l_numcols := APEX_JSON.get_count (p_path => 'additional_info');    
    dbms_output.put_line('l_numcols : '||l_numcols);    

    IF l_numcols > 1 THEN    
      FOR i IN 1 .. l_numcols    
      LOOP    
        dbms_output.put_line    
        (    
          '*********************************'    
        )    
        ;    
        dbms_output.put_line('vadditionaldetails : '||apex_json.get_varchar2 ('additional_info[%d].key',i));    
        dbms_output.put_line('vadditionaldetails2 : '||apex_json.get_varchar2 ('additional_info[%d].value',i));    

        dbms_output.put_line('*********************************');    


        INSERT    
        INTO XX_IMD_ADDITIONAL_INFO_T    
          (    
            ID ,    
            KEYNAME ,    
            VALUE ,    
            INTEGRATION_ACTIVITY_ID    
          )    
          VALUES    
          (    
            XX_IMD_ADDNINFO_T_SEQ.nextval,    
            apex_json.get_varchar2 ('additional_info[%d].key',i),    
            substr(apex_json.get_varchar2 ('additional_info[%d].value',i),1,1900),    
            l_activity_id    
          );    
          COMMIT;  
      END LOOP;    
	ELSIF   l_numcols = 1 THEN  

		 dbms_output.put_line    
        (    
          '*********************************'    
        )    
        ;    
        dbms_output.put_line('vadditionaldetails : '||apex_json.get_varchar2 ('additional_info.gl.key'));    
        dbms_output.put_line('vadditionaldetails2 : '||apex_json.get_varchar2 ('additional_info.gl.value'));    

        dbms_output.put_line('*********************************');    


        INSERT    
        INTO XX_IMD_ADDITIONAL_INFO_T    
          (    
            ID ,    
            KEYNAME ,    
            VALUE ,    
            INTEGRATION_ACTIVITY_ID    
          )    
          VALUES    
          (    
            XX_IMD_ADDNINFO_T_SEQ.nextval,    
            apex_json.get_varchar2 ('additional_info.gl.key'),    
            apex_json.get_varchar2 ('additional_info.gl.value'),    
            l_activity_id    
          );    
          COMMIT;  

    END IF;    
    COMMIT;    
    EXCEPTION   
    WHEN OTHERS THEN   
      p_status :=p_status||':'|| sqlerrm;  
      dbms_output.put_line('225');
    END;   

    /*BEGIN   
    IF apex_json.get_varchar2 ('integration_status')='ERROR'   
    THEN   
      xx_snow_ticket_create( 'Integration Run for :'||apex_json.get_varchar2 ('rice_code')||'-'||l_short_desc||' has failed',    
                             3,                                
                             'Activity Name :'||apex_json.get_varchar2 ('activity_name')||', Touchpoint Name : ' || apex_json.get_varchar2 ('touchpoint_name'),   
                             'Integration Run for :'||apex_json.get_varchar2 ('rice_code')||'-'||l_short_desc||' has failed',    
                             3,    
                             p_incident    
                             );    
      update XX_IMD_INTEGRATION_RUN_T set ticket_number=p_incident  WHERE id            =l_int_run_id;    
    END IF;   
    END;*/   


    p_status := p_status||'SUCCESS';    
    EXCEPTION    
    WHEN OTHERS THEN    
    p_status := sqlerrm;    
    dbms_output.put_line(sqlerrm);
END publishIntegration;    
END XX_IMD_PUBLISH_PKG;
/