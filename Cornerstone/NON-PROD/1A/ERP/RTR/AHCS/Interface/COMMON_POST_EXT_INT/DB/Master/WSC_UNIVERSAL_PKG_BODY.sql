create or replace PACKAGE BODY WSC_UNIVERSAL_PKG IS
FUNCTION  "WSC_CCID_DUPLICATE" ( 
    P_COA_MAP_NAME VARCHAR2,
    P_source_segment VARCHAR2
)RETURN NUMBER IS 
    v_ret_count NUMBER := 0;
begin
 select count(*) into v_ret_count from WSC_GL_CCID_MAPPING_T
where nvl(UPPER(COA_MAP_NAME),'1') = nvl(trim(UPPER(P_COA_MAP_NAME)),'1')
and nvl(SOURCE_SEGMENT,'1') = nvl(trim(P_source_segment),'1')
and enable_flag = 'Y';

    IF v_ret_count > 0 THEN 
        RETURN 1; 
    ELSE 
        RETURN 0; 
    END IF; 
EXCEPTION 
    WHEN no_data_found THEN 
        RETURN 0; 
    WHEN OTHERS THEN 
        RETURN 0;
    end;
    FUNCTION  "WSC_CCID_EXIST_COA_MAP_NAME" ( 
    i_value VARCHAR2  
) RETURN NUMBER IS v_ret_count NUMBER; 
BEGIN 
    SELECT COUNT(*) 
    INTO v_ret_count 
    FROM WSC_GL_COA_MAP_T
    WHERE UPPER(COA_MAP_NAME) = UPPER(TRIM(i_value)); 
	IF v_ret_count > 0 THEN RETURN 1; 
	ELSE RETURN 0; 
	END IF; 
EXCEPTION 
    WHEN no_data_found THEN RETURN 0; 
    WHEN OTHERS THEN RETURN 0; 
END;
FUNCTION  "WSC_COA_VALUE_SEGMENT_EXISTS_RULE_NAME" ( 
    i_value VARCHAR2 
) RETURN NUMBER IS v_ret_count NUMBER; 
BEGIN 
    SELECT COUNT(*) 
    INTO v_ret_count 
    FROM WSC_GL_COA_MAPPING_RULES_T
    WHERE UPPER(RULE_NAME) = UPPER(TRIM(i_value)); 
	IF v_ret_count > 0 THEN RETURN 1; 
	ELSE RETURN 0; 
	END IF; 
EXCEPTION 
    WHEN no_data_found THEN RETURN 0; 
    WHEN OTHERS THEN RETURN 0; 
END;
FUNCTION  "WSC_COA_VALUE_SEG_DUPLICATE" ( 
    rule_nameV VARCHAR2,
    source_segment1V VARCHAR2,
    source_segment2V VARCHAR2,
    source_segment3V VARCHAR2,
    source_segment4V VARCHAR2,
    source_segment5V VARCHAR2,
    source_segment6V VARCHAR2,
    source_segment7V VARCHAR2,
    source_segment8V VARCHAR2,
    source_segment9V VARCHAR2,
    source_segment10V VARCHAR2



)RETURN NUMBER IS 
    v_ret_count NUMBER;
    begin
 v_ret_count:= 0;
 select count(*) into v_ret_count from WSC_GL_COA_SEGMENT_VALUE_T
where nvl(rule_name,1) = nvl(rule_nameV,1)
and nvl(SOURCE_SEGMENT1,1) = nvl(source_segment1V,1)
and nvl(SOURCE_SEGMENT2,1) = nvl(source_segment2V,1)
and nvl(SOURCE_SEGMENT3,1) = nvl(source_segment3V,1)
and nvl(SOURCE_SEGMENT4,1) = nvl(source_segment4V,1)
and nvl(SOURCE_SEGMENT5,1) = nvl(source_segment5V,1)
and nvl(SOURCE_SEGMENT6,1) = nvl(source_segment6V,1)
and nvl(SOURCE_SEGMENT7,1) = nvl(source_segment7V,1)
and nvl(SOURCE_SEGMENT8,1) = nvl(source_segment8V,1)
and nvl(SOURCE_SEGMENT9,1) = nvl(source_segment9V,1)
and nvl(SOURCE_SEGMENT10,1) = nvl(source_segment10V,1)
and flag = 'Y';
    IF v_ret_count > 0 THEN 

        RETURN 1; 
    ELSE 

        RETURN 0; 
    END IF; 
EXCEPTION 
    WHEN no_data_found THEN 
        RETURN 0; 
    WHEN OTHERS THEN 
        RETURN 0;
    end;
    FUNCTION  "WSC_COA_VALUE_SEG_IS_NUMBER" ( 
    p_string varchar2 
) RETURN NUMBER IS 
 p_num number;
BEGIN 
    p_num := to_number(p_string);
    if p_string is not null then
--        if p_num >= 0 or p_num < 0 then
            return 1;
--        end if;
    else
        return 0;
    end if;
    exception
        when others then
            return 0;
END;
FUNCTION  "WSC_USER_MAPPING_EXIT_COA_MAP_NAME" ( 
    i_value in VARCHAR2

) 
RETURN NUMBER IS 
    v_ret_count NUMBER;
 begin
select count(*) into v_ret_count from wsc_gl_coa_map_t where COA_MAP_NAME = i_value;

if(v_ret_count > 0)then
-- insert into XX_EMP_DEMO(EMP_NAME) values ('abc');
Return 1;
else
-- insert into XX_EMP_DEMO(EMP_ID,EMP_NAME) values ('v_ret_count','def');
Return 0;
End IF;
COMMIT;
Exception
when no_data_found then
return 0;
WHEN OTHERS THEN 
RETURN 0; 
end;
PROCEDURE wsc_ccid_map_name(o_Clobdata OUT CLOB , P_CCID_MAP_NAME IN Number) IS 
  l_Blob         BLOB; 
  l_Clob         CLOB; 

BEGIN 

  Dbms_Lob.Createtemporary(Lob_Loc => l_Clob, 
                           Cache   => TRUE, 
                           Dur     => Dbms_Lob.Call); 
  SELECT Clob_Val INTO l_Clob 
    FROM (SELECT Xmlcast(Xmlagg(Xmlelement(e, 
                                           Col_Value || Chr(13) || 
                                           Chr(10))) AS CLOB) AS Clob_Val, 
                 COUNT(*) AS Number_Of_Rows 
            FROM (SELECT 'coa_map_name, SOURCE_SEGMENT,TARGET_SEGMENT,Flag' AS Col_Value 
                    FROM Dual 
                  UNION ALL 
                  SELECT coa_map_name||','||SOURCE_SEGMENT||','||TARGET_SEGMENT||','||ENABLE_FLAG AS Col_Value 
                    FROM (SELECT
    values1.coa_map_name,
    values1.COA_MAP_ID,   
    values1.SOURCE_SEGMENT,
    values1.TARGET_SEGMENT,
	values1.ENABLE_FLAG
FROM
    WSC_GL_CCID_MAPPING_T values1
WHERE
    ui_flag = 'Y'
    and values1.coa_map_id = nvl(P_CCID_MAP_NAME,values1.coa_map_id)))); 

  o_Clobdata := l_Clob; 
EXCEPTION 
  WHEN OTHERS THEN 
    NULL; 
END;
PROCEDURE wsc_tranform_coa_user_mapping(o_Clobdata OUT CLOB,P_USER_NAME IN VARCHAR2) IS 
  l_Blob         BLOB; 
  l_Clob         CLOB; 
  l_status       varchar2(100);
  errm  varchar2(1000);
BEGIN 
  Dbms_Lob.Createtemporary(Lob_Loc => l_Clob, 
                           Cache   => TRUE, 
                           Dur     => Dbms_Lob.Call); 
    select status into l_status from WSC_GL_USER_COA_MAPPING_H where user_name = P_USER_NAME ;
if(l_status = 'Success')then

  SELECT Clob_Val 
    INTO l_Clob 
    FROM (SELECT Xmlcast(Xmlagg(Xmlelement(e, 
                                           Col_Value || Chr(13) || 
                                           Chr(10))) AS CLOB) AS Clob_Val, 
                 COUNT(*) AS Number_Of_Rows 
            FROM (SELECT 'COA_MAP_NAME,SOURCE_SEGMENT1, SOURCE_SEGMENT2,SOURCE_SEGMENT3, SOURCE_SEGMENT4,SOURCE_SEGMENT5,SOURCE_SEGMENT6, SOURCE_SEGMENT7,SOURCE_SEGMENT8,SOURCE_SEGMENT9,SOURCE_SEGMENT10,TARGET_SEGMENT1,TARGET_SEGMENT2,TARGET_SEGMENT3, TARGET_SEGMENT4,TARGET_SEGMENT5,TARGET_SEGMENT6,TARGET_SEGMENT7,TARGET_SEGMENT8,TARGET_SEGMENT9,TARGET_SEGMENT10,ERROR_MESSAGE'AS Col_Value FROM Dual 
 UNION ALL SELECT COA_MAP_NAME||',' ||SOURCE_SEGMENT1||','||SOURCE_SEGMENT2||','||SOURCE_SEGMENT3||','||SOURCE_SEGMENT4||','||SOURCE_SEGMENT5||','||SOURCE_SEGMENT6||','||SOURCE_SEGMENT7||','||SOURCE_SEGMENT8||','||SOURCE_SEGMENT9||','||SOURCE_SEGMENT10||','||TARGET_SEGMENT1||','||TARGET_SEGMENT2||','||TARGET_SEGMENT3||','||TARGET_SEGMENT4||','||TARGET_SEGMENT5||','||TARGET_SEGMENT6||','||TARGET_SEGMENT7||','||TARGET_SEGMENT8||','||TARGET_SEGMENT9||','||TARGET_SEGMENT10||','||ERROR_MESSAGE AS Col_Value 
FROM (SELECT COA_MAP_NAME,
SOURCE_SEGMENT1, 
SOURCE_SEGMENT2,
SOURCE_SEGMENT3, 
SOURCE_SEGMENT4,
SOURCE_SEGMENT5,
SOURCE_SEGMENT6, 
SOURCE_SEGMENT7,
SOURCE_SEGMENT8,
SOURCE_SEGMENT9,
SOURCE_SEGMENT10,
TARGET_SEGMENT1,
TARGET_SEGMENT2,
TARGET_SEGMENT3, 
TARGET_SEGMENT4,
TARGET_SEGMENT5,
TARGET_SEGMENT6,
TARGET_SEGMENT7,
TARGET_SEGMENT8,
TARGET_SEGMENT9,
TARGET_SEGMENT10,
ERROR_MESSAGE from
WSC_GL_USER_COA_MAPPING_T where user_name = P_USER_NAME order by LINE_ID))); 

  o_Clobdata := l_Clob;
  else
  SELECT Clob_Val 
INTO l_Clob 
FROM (SELECT Xmlcast(Xmlagg(Xmlelement(e, 
                                           Col_Value || Chr(13) || 
                                           Chr(10))) AS CLOB) AS Clob_Val, 
                 COUNT(*) AS Number_Of_Rows 
FROM (SELECT 'COA_MAP_NAME,SOURCE_SEGMENT1, SOURCE_SEGMENT2,SOURCE_SEGMENT3, SOURCE_SEGMENT4,SOURCE_SEGMENT5,SOURCE_SEGMENT6, SOURCE_SEGMENT7,SOURCE_SEGMENT8,SOURCE_SEGMENT9,SOURCE_SEGMENT10,TARGET_SEGMENT1,TARGET_SEGMENT2,TARGET_SEGMENT3, TARGET_SEGMENT4,TARGET_SEGMENT5,TARGET_SEGMENT6,TARGET_SEGMENT7,TARGET_SEGMENT8,TARGET_SEGMENT9,TARGET_SEGMENT10,ERROR_MESSAGE'AS Col_Value FROM Dual)); 
o_Clobdata := l_Clob;
end if;
EXCEPTION 
  WHEN OTHERS THEN 
  errm:= sqlerrm;
    -- insert into tbl_time_t values (errm,sysdate,1);
    -- commit;

END;
PROCEDURE wsc_user_coa_map_name(o_Clobdata OUT CLOB , P_COA_MAP_NAME IN Number) IS 
  l_Blob         BLOB; 
  l_Clob         CLOB; 

BEGIN 

  Dbms_Lob.Createtemporary(Lob_Loc => l_Clob, 
                           Cache   => TRUE, 
                           Dur     => Dbms_Lob.Call); 
  SELECT Clob_Val 
    INTO l_Clob 
    FROM (SELECT Xmlcast(Xmlagg(Xmlelement(e, 
                                           Col_Value || Chr(13) || 
                                           Chr(10))) AS CLOB) AS Clob_Val, 
                 COUNT(*) AS Number_Of_Rows 
            FROM (SELECT 'RULE_NAME, SOURCE_SEGMENT1, SOURCE_SEGMENT2,SOURCE_SEGMENT3, SOURCE_SEGMENT4, SOURCE_SEGMENT5,SOURCE_SEGMENT6,SOURCE_SEGMENT7,SOURCE_SEGMENT8,SOURCE_SEGMENT9,SOURCE_SEGMENT10,TARGET_SEGMENT,Flag' AS Col_Value 
                    FROM Dual 
                  UNION ALL 
                  SELECT RULE_NAME||','||SOURCE_SEGMENT1||','||SOURCE_SEGMENT2||','||SOURCE_SEGMENT3||','||SOURCE_SEGMENT4||','||SOURCE_SEGMENT5||','||SOURCE_SEGMENT6||','||SOURCE_SEGMENT7||','||SOURCE_SEGMENT8||','||SOURCE_SEGMENT9||','||SOURCE_SEGMENT10||','||TARGET_SEGMENT||','||Flag AS Col_Value 
                    FROM (SELECT
    values1.VALUE_ID,
    values1.RULE_NAME,
    values1.RULE_ID,   
    values1.SOURCE_SEGMENT1,
    values1.SOURCE_SEGMENT2,
    values1.SOURCE_SEGMENT3,
    values1.SOURCE_SEGMENT4,
    values1.SOURCE_SEGMENT5,
    values1.SOURCE_SEGMENT6,
    values1.SOURCE_SEGMENT7,
    values1.SOURCE_SEGMENT8,
    values1.SOURCE_SEGMENT9,
    values1.SOURCE_SEGMENT10,
    values1.TARGET_SEGMENT,
	values1.Flag
FROM
    WSC_GL_COA_SEGMENT_VALUE_T values1,
    WSC_GL_COA_MAPPING_RULES_T mapping1
WHERE
    values1.rule_name = mapping1.rule_name
    and mapping1.coa_map_id = nvl(P_COA_MAP_NAME,mapping1.coa_map_id)))); 

  o_Clobdata := l_Clob; 
EXCEPTION 
  WHEN OTHERS THEN 
    NULL; 
END;
PROCEDURE WSC_USER_COA_MAP_TEMPLATE(o_Clobdata OUT CLOB) IS 
  l_Blob         BLOB; 
  l_Clob         CLOB; 
  l_status       varchar2(100);
BEGIN 
  Dbms_Lob.Createtemporary(Lob_Loc => l_Clob, 
                           Cache   => TRUE, 
                           Dur     => Dbms_Lob.Call); 
    SELECT Clob_Val 
INTO l_Clob 
FROM (SELECT Xmlcast(Xmlagg(Xmlelement(e, 
                                           Col_Value || Chr(13) || 
                                           Chr(10))) AS CLOB) AS Clob_Val, 
                 COUNT(*) AS Number_Of_Rows 
FROM (SELECT 'COA_MAP_NAME,SOURCE_SEGMENT1, SOURCE_SEGMENT2,SOURCE_SEGMENT3, SOURCE_SEGMENT4,SOURCE_SEGMENT5,SOURCE_SEGMENT6, SOURCE_SEGMENT7,SOURCE_SEGMENT8,SOURCE_SEGMENT9,SOURCE_SEGMENT10'AS Col_Value FROM Dual));SELECT Clob_Val 
INTO l_Clob 
FROM (SELECT Xmlcast(Xmlagg(Xmlelement(e, 
                                           Col_Value || Chr(13) || 
                                           Chr(10))) AS CLOB) AS Clob_Val, 
                 COUNT(*) AS Number_Of_Rows 
FROM (SELECT 'COA_MAP_NAME,SOURCE_SEGMENT1, SOURCE_SEGMENT2,SOURCE_SEGMENT3, SOURCE_SEGMENT4,SOURCE_SEGMENT5,SOURCE_SEGMENT6, SOURCE_SEGMENT7,SOURCE_SEGMENT8,SOURCE_SEGMENT9,SOURCE_SEGMENT10'AS Col_Value FROM Dual
union all
SELECT 'WESCO to Cloud,,,,,,,,,,' FROM Dual
union all
SELECT 'Anixter to Cloud,,,,,,,,,,' FROM Dual
union all
SELECT 'POC to Cloud,,,,,,,,,,' FROM Dual
union all
SELECT 'Central to Cloud,,,,,,,,,,' FROM Dual
));


o_Clobdata := l_Clob;


EXCEPTION 
  WHEN OTHERS THEN 
    NULL; 
END;
PROCEDURE WSC_VALUE_SEG_CAHE_DOWNLOAD(o_Clobdata OUT CLOB , P_COA_MAP_NAME IN Number) IS 
  l_Blob         BLOB; 
  l_Clob         CLOB; 

BEGIN 

  Dbms_Lob.Createtemporary(Lob_Loc => l_Clob, 
                           Cache   => TRUE, 
                           Dur     => Dbms_Lob.Call); 
  SELECT Clob_Val INTO l_Clob 
    FROM (SELECT Xmlcast(Xmlagg(Xmlelement(e, 
                                           Col_Value || Chr(13) || 
                                           Chr(10))) AS CLOB) AS Clob_Val, 
                 COUNT(*) AS Number_Of_Rows 
            FROM (SELECT 'COA_MAP_NAME, SOURCE_SEGMENT,TARGET_SEGMENT,ENABLE_FLAG,UI_FLAG,CREATION_DATE,LAST_UPDATE_DATE' AS Col_Value 
                    FROM Dual 
                  UNION ALL 
                  SELECT coa_map_name||','||SOURCE_SEGMENT||','||TARGET_SEGMENT||','||ENABLE_FLAG||','||UI_FLAG||','||CREATION_DATE||','||LAST_UPDATE_DATE AS Col_Value 
                    FROM (SELECT
    cache.COA_MAP_NAME,
    values1.COA_MAP_ID,   
    values1.SOURCE_SEGMENT,
    values1.TARGET_SEGMENT,
	values1.ENABLE_FLAG,
    values1.UI_FLAG,
    to_char(values1.creation_date, 'dd-mon-yyyy hh24:mi:ss') as CREATION_DATE, 
    to_char(values1.LAST_UPDATE_DATE, 'dd-mon-yyyy hh24:mi:ss') as LAST_UPDATE_DATE
FROM
    WSC_GL_CCID_MAPPING_T values1, wsc_gl_coa_map_t cache
    where   cache.COA_MAP_ID = values1.COA_MAP_ID
    and values1.coa_map_id = nvl(P_COA_MAP_NAME,values1.coa_map_id)  
    order by LAST_UPDATE_DATE desc))); 

  o_Clobdata := l_Clob; 
EXCEPTION 
  WHEN OTHERS THEN 
    NULL; 
END;
PROCEDURE wsc_value_seg_coa_map_name(o_Clobdata OUT CLOB , P_COA_MAP_NAME IN Number) IS 
  l_Blob         BLOB; 
  l_Clob         CLOB; 

BEGIN 

  Dbms_Lob.Createtemporary(Lob_Loc => l_Clob, 
                           Cache   => TRUE, 
                           Dur     => Dbms_Lob.Call); 
  SELECT Clob_Val 
    INTO l_Clob 
    FROM (SELECT Xmlcast(Xmlagg(Xmlelement(e, 
                                           Col_Value || Chr(13) || 
                                           Chr(10))) AS CLOB) AS Clob_Val, 
                 COUNT(*) AS Number_Of_Rows 
            FROM (SELECT 'RULE_NAME, SOURCE_SEGMENT1, SOURCE_SEGMENT2,SOURCE_SEGMENT3, SOURCE_SEGMENT4, SOURCE_SEGMENT5,SOURCE_SEGMENT6,SOURCE_SEGMENT7,SOURCE_SEGMENT8,SOURCE_SEGMENT9,SOURCE_SEGMENT10,TARGET_SEGMENT,Flag' AS Col_Value 
                    FROM Dual 
                  UNION ALL 
                  SELECT RULE_NAME||','||SOURCE_SEGMENT1||','||SOURCE_SEGMENT2||','||SOURCE_SEGMENT3||','||SOURCE_SEGMENT4||','||SOURCE_SEGMENT5||','||SOURCE_SEGMENT6||','||SOURCE_SEGMENT7||','||SOURCE_SEGMENT8||','||SOURCE_SEGMENT9||','||SOURCE_SEGMENT10||','||TARGET_SEGMENT||','||Flag AS Col_Value 
                    FROM (SELECT
    values1.VALUE_ID,
    values1.RULE_NAME,
    values1.RULE_ID,   
    values1.SOURCE_SEGMENT1,
    values1.SOURCE_SEGMENT2,
    values1.SOURCE_SEGMENT3,
    values1.SOURCE_SEGMENT4,
    values1.SOURCE_SEGMENT5,
    values1.SOURCE_SEGMENT6,
    values1.SOURCE_SEGMENT7,
    values1.SOURCE_SEGMENT8,
    values1.SOURCE_SEGMENT9,
    values1.SOURCE_SEGMENT10,
    values1.TARGET_SEGMENT,
	values1.Flag
FROM
    WSC_GL_COA_SEGMENT_VALUE_T values1,
    WSC_GL_COA_MAPPING_RULES_T mapping1
WHERE
    values1.rule_name = mapping1.rule_name
    and mapping1.coa_map_id = nvl(P_COA_MAP_NAME,mapping1.coa_map_id)))); 

  o_Clobdata := l_Clob; 
EXCEPTION 
  WHEN OTHERS THEN 
    NULL; 
END;
end WSC_UNIVERSAL_PKG;

/