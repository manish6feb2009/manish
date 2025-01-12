create or replace PACKAGE  "XX_APEX_USER_SECURITY_PKG"  
AS    
PROCEDURE main(x_out_jwt_token out VARCHAR2 ,x_out_user_name out VARCHAR2,p_user_name varchar2 ) ;    
    
end ;
/