/*====================================*/
    /* USER AUTHENTICATION PL SQL */
/*====================================*/

DECLARE
v_user_name varchar2(200);
v_jwt_token  varchar2(4000);

BEGIN

 /*APEX_CUSTOM_AUTH.SET_USER('AHSERP');
 APEX_UTIL.SET_SESSION_STATE('USER_NAME',APEX_CUSTOM_AUTH.GET_USER());
*/
 IF  APEX_UTIL.GET_SESSION_STATE('USER_NAME') IS NULL THEN
   
  xx_apex_user_security_pkg.main(v_jwt_token,v_user_name,null);  

   
    APEX_UTIL.SET_SESSION_STATE('USER_NAME',v_user_name);
    APEX_UTIL.SET_SESSION_STATE('JWT_TOKEN',v_jwt_token);
   
    IF APEX_UTIL.GET_SESSION_STATE('USER_NAME') IS NULL THEN
        APEX_UTIL.REDIRECT_URL('f?p=&APP_ID.:9999:&APP_SESSION.');
   ELSE
        APEX_CUSTOM_AUTH.SET_USER(APEX_UTIL.GET_SESSION_STATE('USER_NAME'));
   END IF;
   
ELSE
   APEX_CUSTOM_AUTH.SET_USER(APEX_UTIL.GET_SESSION_STATE('USER_NAME'));  
   
END IF;

END;
/