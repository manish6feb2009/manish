SET DEFINE OFF;
/*=====================================================*/
    /* PACKAGE SPECIFICATION XX_APEX_GEN_RUN_REP_PKG*/
/*=====================================================*/
create or replace PACKAGE  "XX_APEX_GEN_RUN_REP_PKG"  
AS    
PROCEDURE main(p_full_query in CLOB,x_xml_data_out OUT XMLTYPE);    
PROCEDURE parameter_main( p_user_name VARCHAR2    
                      --  , p_request_id NUMBER    
						);    
END ;
/