create or replace Package WSC_AHCS_DASHBOARD As

Function get_STAGED_AMOUNT(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER;
Function get_PROCESSED_RECORDS(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER;

Function get_PROCESSED_AMOUNT(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER;                              

Function get_ERROR_REEXTRACT_RECORDS(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER;                               

Function get_ERROR_REEXTRACT_AMOUNT(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER;   

Function get_ERROR_REPROCESS_RECORDS(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER;  

Function get_ERROR_REPROCESS_AMOUNT(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER;                               

Function get_SKIPPED_RECORDS(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER;                                

Function get_SKIPPED_AMOUNT(BID varchar2,
                              Fname varchar2,
                              Apps varchar2) return NUMBER; 

PROCEDURE wsc_ahcs_dashboard_error(o_Clobdata OUT CLOB,
                                    P_APPLICATION IN VARCHAR2,
                                    P_STATUS IN VARCHAR2,
                                    P_ACC_STATUS IN VARCHAR2,
                                    P_ACCOUNTING_PERIOD varchar2);
                             
END WSC_AHCS_DASHBOARD;
/