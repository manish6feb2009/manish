create or replace Package BODY WSC_DISABLED_COA_HANDLE_PKG as

Procedure WSC_DISABLED_COA_HANDLE_PRC(P_SEG1 VARCHAR2,
                                      P_SEG2 VARCHAR2,
                                      P_SEG3 VARCHAR2,
                                      P_SEG4 VARCHAR2,
                                      P_SEG5 VARCHAR2,
                                      P_SEG6 VARCHAR2,
                                      P_SEG7 VARCHAR2,
                                      P_SEG8 VARCHAR2,
                                      P_SEG9 VARCHAR2,
                                      P_SEG10 VARCHAR2,
                                      P_RULE_ID VARCHAR2) IS


Begin
--     insert into tbl_time_t values ('IN PKG' ||P_SEG1 ||P_SEG8 ||P_RULE_ID,sysdate,1);
commit;

  UPDATE WSC_GL_CCID_MAPPING_T 
  Set Enable_Flag='N',
      LAST_UPDATE_DATE=Sysdate,
      Version=WSC_GL_COA_DISABLE_VER_SEQ.nextval
  where 1=1
  AND (SOURCE_SEGMENT1 = P_SEG1 OR P_SEG1 IS NULL)
  AND (SOURCE_SEGMENT2=P_SEG2 OR P_SEG2 IS NULL)
  AND (SOURCE_SEGMENT3 =P_SEG3 OR P_SEG3 IS NULL)
  AND (SOURCE_SEGMENT4 =P_SEG4 OR P_SEG4 IS NULL)
  AND (SOURCE_SEGMENT5 =P_SEG5 OR P_SEG5 IS NULL)
  AND (SOURCE_SEGMENT6=P_SEG6 OR P_SEG6 IS NULL)
  AND (SOURCE_SEGMENT7 =P_SEG7 OR P_SEG7 IS NULL)
  AND (SOURCE_SEGMENT8 =P_SEG8 OR P_SEG8 IS NULL)
  AND (SOURCE_SEGMENT9=P_SEG9 OR P_SEG9 IS NULL)
  AND (SOURCE_SEGMENT10=P_SEG10 OR P_SEG10 IS NULL)
  AND COA_MAP_ID IN (SELECT COA_MAP_ID FROM WSC_GL_COA_MAPPING_RULES_T where rule_id=P_RULE_ID)
  AND Enable_Flag='Y';          
  Commit; 
  
--  insert into tbl_time_t values ('IN PKG' ||P_SEG2 ||P_RULE_ID,sysdate,1);
commit;
END;

Procedure WSC_DISABLED_CCID_HANDLE_PRC(P_SOURCE_SEGMENT VARCHAR2,
                                       P_COA_MAP_ID VARCHAR2) IS


Begin
--insert into tbl_time_t values ('IN PKG' || P_SOURCE_SEGMENT || '-' || P_COA_MAP_ID,sysdate,3);
commit;
     
  UPDATE WSC_GL_CCID_MAPPING_T 
  Set Enable_Flag='N',
      LAST_UPDATE_DATE=Sysdate,
      Version=WSC_GL_COA_DISABLE_VER_SEQ.nextval
  where 1=1
  AND SOURCE_SEGMENT = TRIM(P_SOURCE_SEGMENT) 
  AND COA_MAP_ID = P_COA_MAP_ID
  AND Enable_Flag='Y'
  AND UI_FLAG = 'N';          
  Commit;
--  insert into tbl_time_t values ('IN PKG AFTER' || P_SOURCE_SEGMENT,sysdate,4);
commit;
END;
--

Procedure wsc_sync_ccid_coa_prc is
BEGIN
    MERGE INTO WSC_GL_CCID_MAPPING_T WGM
    USING (select distinct WGCM.CCID_VALUE_ID from WSC_GL_CCID_MAPPING_T WGCM,
    wsc_gl_coa_segment_value_t wgcs
    where 1=1
    AND ((WGCM.source_segment1=wgcs.source_segment1 OR wgcs.source_segment1 is NULL) and wgcs.flag='N' and WGCM.enable_flag='Y')
    AND ((WGCM.source_segment2=wgcs.source_segment2 OR wgcs.source_segment2 is NULL) and wgcs.flag='N' and WGCM.enable_flag='Y')
    AND ((WGCM.source_segment3=wgcs.source_segment3 OR wgcs.source_segment3 is NULL) and wgcs.flag='N' and WGCM.enable_flag='Y')
    AND ((WGCM.source_segment4=wgcs.source_segment4 OR wgcs.source_segment4 is NULL) and wgcs.flag='N' and WGCM.enable_flag='Y')
    AND ((WGCM.source_segment5=wgcs.source_segment5 OR wgcs.source_segment5 is NULL) and wgcs.flag='N' and WGCM.enable_flag='Y')
    AND ((WGCM.source_segment6=wgcs.source_segment6 OR wgcs.source_segment6 is NULL) and wgcs.flag='N' and WGCM.enable_flag='Y')
    AND ((WGCM.source_segment7=wgcs.source_segment7 OR wgcs.source_segment7 is NULL) and wgcs.flag='N' and WGCM.enable_flag='Y')
    AND ((WGCM.source_segment8=wgcs.source_segment8 OR wgcs.source_segment8 is NULL) and wgcs.flag='N' and WGCM.enable_flag='Y')
    AND ((WGCM.source_segment9=wgcs.source_segment9 OR wgcs.source_segment9 is NULL) and wgcs.flag='N' and WGCM.enable_flag='Y')
    AND ((WGCM.source_segment10=wgcs.source_segment10 OR wgcs.source_segment10 is NULL) and wgcs.flag='N' and WGCM.enable_flag='Y')) WVIEW
    ON (WGM.CCID_VALUE_ID=WVIEW.CCID_VALUE_ID )
    WHEN MATCHED then update set WGM.ENABLE_FLAG='N',
                                Version=WSC_GL_COA_DISABLE_VER_SEQ.nextval;
   
EXCEPTION
WHEN OTHERS THEN
      NULL;
END;


END WSC_DISABLED_COA_HANDLE_PKG;


--create or replace Package BODY WSC_DISABLED_COA_HANDLE_PKG as
--
--Procedure WSC_DISABLED_COA_HANDLE_PRC(P_SEG1 VARCHAR2,
--                                      P_SEG2 VARCHAR2,
--                                      P_SEG3 VARCHAR2,
--                                      P_SEG4 VARCHAR2,
--                                      P_SEG5 VARCHAR2,
--                                      P_SEG6 VARCHAR2,
--                                      P_SEG7 VARCHAR2,
--                                      P_SEG8 VARCHAR2,
--                                      P_SEG9 VARCHAR2,
--                                      P_SEG10 VARCHAR2,
--                                      P_RULE_ID VARCHAR2) IS
--Begin
--insert into WSC_TBL_TIME_T (a) values ('After Update on WSC_DISABLED_COA_HANDLE_PRC Start------');
--commit;
--  UPDATE WSC_GL_CCID_MAPPING_T 
--  Set Enable_Flag='N',
--      LAST_UPDATE_DATE=Sysdate
--  where 1=1
--  AND (substr(SOURCE_SEGMENT,1,instr(SOURCE_SEGMENT,'.',1,1)-1) = P_SEG1 OR P_SEG1 IS NULL)
--  AND (substr(SOURCE_SEGMENT,instr(SOURCE_SEGMENT,'.',1,1)+1,instr(SOURCE_SEGMENT,'.',1,2)-1-instr(SOURCE_SEGMENT,'.',1,1))=P_SEG2 OR P_SEG2 IS NULL)
--  AND (substr(SOURCE_SEGMENT,instr(SOURCE_SEGMENT,'.',1,2)+1,instr(SOURCE_SEGMENT,'.',1,3)-1-instr(SOURCE_SEGMENT,'.',1,2)) =P_SEG3 OR P_SEG3 IS NULL)
--  AND (substr(SOURCE_SEGMENT,instr(SOURCE_SEGMENT,'.',1,3)+1,instr(SOURCE_SEGMENT,'.',1,4)-1-instr(SOURCE_SEGMENT,'.',1,3)) =P_SEG4 OR P_SEG4 IS NULL)
--  AND (substr(SOURCE_SEGMENT,instr(SOURCE_SEGMENT,'.',1,4)+1,instr(SOURCE_SEGMENT,'.',1,5)-1-instr(SOURCE_SEGMENT,'.',1,4)) =P_SEG5 OR P_SEG5 IS NULL)
--  AND (substr(SOURCE_SEGMENT,instr(SOURCE_SEGMENT,'.',1,5)+1,instr(SOURCE_SEGMENT,'.',1,6)-1-instr(SOURCE_SEGMENT,'.',1,5)) =P_SEG6 OR P_SEG6 IS NULL)
--  AND (substr(SOURCE_SEGMENT,instr(SOURCE_SEGMENT,'.',1,6)+1,instr(SOURCE_SEGMENT,'.',1,7)-1-instr(SOURCE_SEGMENT,'.',1,6)) =P_SEG7 OR P_SEG7 IS NULL)
--  AND (substr(SOURCE_SEGMENT,instr(SOURCE_SEGMENT,'.',1,7)+1,instr(SOURCE_SEGMENT,'.',1,8)-1-instr(SOURCE_SEGMENT,'.',1,7)) =P_SEG8 OR P_SEG8 IS NULL)
--  AND (substr(SOURCE_SEGMENT,instr(SOURCE_SEGMENT,'.',1,8)+1)=P_SEG9 OR P_SEG9 IS NULL)
--  AND COA_MAP_ID IN (SELECT COA_MAP_ID FROM WSC_GL_COA_MAPPING_RULES_T where rule_id=P_RULE_ID)
--  AND Enable_Flag='Y';          
--  Commit;
--  insert into WSC_TBL_TIME_T (a) values ('After Update on WSC_DISABLED_COA_HANDLE_PRC end------');
--commit;
--END;
--
--Procedure WSC_DISABLED_CCID_HANDLE_PRC(P_SOURCE_SEGMENT VARCHAR2,
--                                       P_COA_MAP_ID VARCHAR2) IS
--
--
--Begin
--  UPDATE WSC_GL_CCID_MAPPING_T 
--  Set Enable_Flag='N',
--      LAST_UPDATE_DATE=Sysdate
--  where 1=1
--  AND SOURCE_SEGMENT = TRIM(P_SOURCE_SEGMENT) 
--  AND COA_MAP_ID = P_COA_MAP_ID
--  AND Enable_Flag='Y'
--  AND UI_FLAG = 'N';          
--  Commit;
--END;
--
--END WSC_DISABLED_COA_HANDLE_PKG;
/