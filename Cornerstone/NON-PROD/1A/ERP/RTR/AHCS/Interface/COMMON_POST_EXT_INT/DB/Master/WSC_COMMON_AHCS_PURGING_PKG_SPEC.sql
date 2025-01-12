create or replace PACKAGE wsc_ahcs_purging_pkg IS
	
    PROCEDURE PURGE_RECORDS ( 
        p_success_days IN NUMBER,
        p_error_days in  number
    ) ;

    PROCEDURE PURGE_RECORDS_ASYNC ( 
        p_success_days IN NUMBER,
        p_error_days in  number
    ) ;


end wsc_ahcs_purging_pkg    ;
/