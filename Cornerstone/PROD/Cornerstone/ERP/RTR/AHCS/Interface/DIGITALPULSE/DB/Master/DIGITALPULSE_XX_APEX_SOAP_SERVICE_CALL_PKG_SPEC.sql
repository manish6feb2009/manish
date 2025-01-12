SET DEFINE OFF;
/*=====================================================*/
 /* PACKAGE SPECIFICATION XX_APEX_SOAP_SERVICE_CALL_PKG */
/*=====================================================*/
create or replace PACKAGE  "XX_APEX_SOAP_SERVICE_CALL_PKG"  
AS    
PROCEDURE main(p_user_name VARCHAR2);    
PROCEDURE parameter_main( p_user_name VARCHAR2    
                      --  , p_request_id NUMBER    
						);    
                            
END xx_apex_soap_service_call_pkg;
/