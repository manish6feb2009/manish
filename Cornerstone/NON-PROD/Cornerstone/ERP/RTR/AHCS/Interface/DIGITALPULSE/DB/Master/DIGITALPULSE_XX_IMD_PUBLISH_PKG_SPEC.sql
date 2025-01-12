SET DEFINE OFF;
/*=====================================================*/
 /* PACKAGE SPECIFICATION XX_IMD_PUBLISH_PKG */
/*=====================================================*/
create or replace PACKAGE  "XX_IMD_PUBLISH_PKG" as    
    
PROCEDURE publishIntegration(p_payload IN CLOB, p_status OUT VARCHAR2);    

end;
/