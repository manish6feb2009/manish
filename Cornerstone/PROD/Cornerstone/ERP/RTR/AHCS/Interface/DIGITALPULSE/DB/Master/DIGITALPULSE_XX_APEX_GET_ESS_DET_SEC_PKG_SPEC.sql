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

Procedure INSERT_REC_OUTBOUNDJOBS(P_INS_VAL WSC_OUTBOUNDJOBS_OUTPUT_T_TAB,
	P_ERR_MSG OUT VARCHAR2,
	P_ERR_CODE OUT VARCHAR2);

Procedure INSERT_REC_LONGRUNNINGJOBS(P_INS_VAL WSC_LONGRUNNINGJOBS_OUTPUT_T_TAB,
	P_ERR_MSG OUT VARCHAR2,
	P_ERR_CODE OUT VARCHAR2);

Procedure INSERT_REC_CRITICALJOBS(P_INS_VAL WSC_CRITICALJOBS_OUTPUT_T_TAB,
	P_ERR_MSG OUT VARCHAR2,
	P_ERR_CODE OUT VARCHAR2);
    
end;
/