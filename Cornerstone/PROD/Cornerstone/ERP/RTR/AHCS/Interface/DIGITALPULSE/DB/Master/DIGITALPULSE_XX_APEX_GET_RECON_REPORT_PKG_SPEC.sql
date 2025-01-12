SET DEFINE OFF;
/*=====================================================*/
 /* PACKAGE SPECIFICATION XX_APEX_GET_RECON_REPORT_PKG */
/*=====================================================*/
create or replace PACKAGE  "XX_APEX_GET_RECON_REPORT_PKG" as    
    
procedure get_recon_report (    
   p_integration_run_id in number default null,    
   p_integration_activity_id in number   default null,    
   p_integration_master_id in number   default null,    
   p_request_id in varchar2   default null);    
     
procedure get_recon_report_file (    
   p_recon_id in number,  
   p_clob_file_data in CLOB,  
   p_mime_type in varchar2  
   );    
     
    
end;
/