create or replace Package WSC_DISABLED_COA_HANDLE_PKG as

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
                                      P_RULE_ID VARCHAR2);

Procedure WSC_DISABLED_CCID_HANDLE_PRC(P_SOURCE_SEGMENT VARCHAR2,
                                       P_COA_MAP_ID VARCHAR2) ;   
                                       
Procedure wsc_sync_ccid_coa_prc;                                       

END WSC_DISABLED_COA_HANDLE_PKG;
/