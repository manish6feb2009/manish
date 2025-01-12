--------------Total Objects#4-----------------------
/*=====================================================*/
       /* TRIGGER BI_XX_IMD_INTEGRATION_ACTIVITY */
/*=====================================================*/
create or replace TRIGGER  "BI_XX_IMD_INTEGRATION_ACTIVITY"  
  before insert on "XX_IMD_INTEGRATION_ACTIVITY_T"                   
  for each row      
begin       
  if :NEW."ID" is null then     
    select "XX_IMD_INTEG_ACTIVITY_T_SEQ".nextval into :NEW."ID" from sys.dual;     
  end if;     
end; 
/

/*=====================================================*/
         /* TRIGGER BI_XX_IMD_INTEGRATION_MASTER_T */
/*=====================================================*/
create or replace TRIGGER  "BI_XX_IMD_INTEGRATION_MASTER_T"  
  before insert on "XX_IMD_INTEGRATION_MASTER_T"                   
  for each row      
begin       
  if :NEW."ID" is null then     
    select "XX_IMD_INTEG_MASTER_T_SEQ".nextval into :NEW."ID" from sys.dual;     
  end if;     
end;  
/


/*=====================================================*/
          /* TRIGGER BI_XX_IMD_INTEGRATION_RUN_T */
/*=====================================================*/
create or replace TRIGGER  "BI_XX_IMD_INTEGRATION_RUN_T"  
  before insert on "XX_IMD_INTEGRATION_RUN_T"                   
  for each row      
begin       
  if :NEW."ID" is null then     
    select "XX_IMD_INTEG_RUN_T_SEQ".nextval into :NEW."ID" from sys.dual;     
  end if;     
end;  
/

/*=====================================================*/
          /* TRIGGER BI_XX_IMD_ROLE_MAPPING_T */
/*=====================================================*/
create or replace TRIGGER  "BI_XX_IMD_ROLE_MAPPING_T"  
  before insert on "XX_IMD_ROLE_MAPPINGS_T"                   
  for each row      
begin       
  if :NEW."ID" is null then     
    select "XX_IMD_ROLE_MAPPING_SEQ".nextval into :NEW."ID" from sys.dual;     
  end if;     
end;   
/