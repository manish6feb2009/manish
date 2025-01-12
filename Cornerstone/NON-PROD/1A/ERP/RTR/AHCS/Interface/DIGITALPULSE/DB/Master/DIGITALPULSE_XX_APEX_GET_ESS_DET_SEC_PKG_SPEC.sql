SET DEFINE OFF;
/*=====================================================*/
 /* PACKAGE SPECIFICATION XX_APEX_GET_ESS_DET_SEC_PKG */
/*=====================================================*/

create or replace PACKAGE  "XX_APEX_GET_ESS_DET_SEC_PKG" as   
   
procedure get_reqID (   
   p_arg1 in varchar2 default null,   
   p_arg2 in number   default null);   

procedure get_reqID_crit (   
   p_arg1 in varchar2 default null,   
   p_arg2 in number   default null);   

procedure get_reqID_outbound (   
   p_arg1 in varchar2 default null,   
   p_arg2 in number   default null);      

procedure get_reqID_crit_extracts (   
   p_arg1 in varchar2 default null,   
   p_arg2 in number   default null);      

procedure get_reqID_long_extracts (   
   p_arg1 in varchar2 default null,   
   p_arg2 in number   default null);


end;
/