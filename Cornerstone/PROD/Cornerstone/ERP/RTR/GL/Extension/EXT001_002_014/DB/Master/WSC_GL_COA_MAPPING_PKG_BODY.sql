create or replace PACKAGE BODY wsc_gl_coa_mapping_pkg IS

    FUNCTION  ccid_match ( 
        src_sgt IN varchar2,
        P_COA_MAP_ID in  number
    ) RETURN VARCHAR2 IS
        f_tgt_sgt varchar2(1000);
        cursor tgt_sgt is select TARGET_SEGMENT from wsc_gl_ccid_mapping_t
        where SOURCE_SEGMENT = src_sgt and COA_MAP_ID = P_COA_MAP_ID  and ENABLE_FLAG = 'Y';
    BEGIN  
        open tgt_sgt;
        fetch tgt_sgt into f_tgt_sgt;
        close tgt_sgt;
        return f_tgt_sgt;
    EXCEPTION 
        WHEN no_data_found THEN 
            RETURN null; 
        WHEN OTHERS THEN 
            RETURN null; 
    END ccid_match;
    
    FUNCTION coa_mapping(
		src_system VARCHAR2,
		tgt_system VARCHAR2,
		segment_value1 VARCHAR2,
		segment_value2 VARCHAR2,
		segment_value3 VARCHAR2,
		segment_value4 VARCHAR2,
		segment_value5 VARCHAR2,
		segment_value6 VARCHAR2,
		segment_value7 VARCHAR2,
		segment_value8 VARCHAR2,
		segment_value9 VARCHAR2,
		segment_value10 VARCHAR2
	)
	RETURN varchar2 IS 
	
		lv_src_system VARCHAR2(100) := src_system;
		lv_tgt_system VARCHAR2(100) := tgt_system;
		lv_segment_value1 VARCHAR2(10):= segment_value1;
		lv_segment_value2 VARCHAR2(10):= segment_value2;
		lv_segment_value3 VARCHAR2(10):= segment_value3;
		lv_segment_value4 VARCHAR2(10):= segment_value4;
		lv_segment_value5 VARCHAR2(10):= segment_value5;
		lv_segment_value6 VARCHAR2(10):= segment_value6;
		lv_segment_value7 VARCHAR2(10):= segment_value7;
		lv_segment_value8 VARCHAR2(100):= segment_value8;
		lv_segment_value9 VARCHAR2(10):= segment_value9;
		lv_segment_value10 VARCHAR2(10):= segment_value10;

		lv_tgt_value VARCHAR2(100);
		lv_tgt_value_final VARCHAR2(300);
        lv_error_flag VARCHAR2(100) := 'False';
        lv_error_flag_final VARCHAR2(100) := 'False';
	    lv_error_msg VARCHAR2(1000) := null;
        lv_error_msg_final VARCHAR2(1000) := null;
        lv_seg_name varchar2(100) := null;
		lv_coa_map_id number;

		CURSOR cur_coa_map_id IS
		select COA_MAP_ID 
		from WSC_GL_COA_MAP_T WHERE SOURCE_SYSTEM = lv_src_system AND TARGET_SYSTEM = lv_tgt_system;

		CURSOR cur_segment_name IS
		SELECT SEGMENT_NAME
		FROM WSC_GL_COA_SEGMENT_DEFINITIONS_T
		WHERE SYSTEM_NAME = lv_tgt_system
		ORDER BY DISPLAY_SEQUENCE;

		CURSOR cur_mapping_rule(cur_p_segment_name VARCHAR2, cur_p_coa_map_id number) IS 
		SELECT RULE_PRIORITY, RULE_ID FROM WSC_GL_COA_MAPPING_RULES_T
		WHERE SOURCE_SYSTEM = lv_src_system AND TARGET_SYSTEM = lv_tgt_system 
        AND TARGET_SEGMENT = cur_p_segment_name and COA_MAP_ID = cur_p_coa_map_id and DEFAULT_VALUE is NULL
		ORDER BY RULE_PRIORITY;

		CURSOR cur_def_tgt_val(cur_p_segment_name varchar2, cur_p_coa_map_id number) IS
		select default_value
		from WSC_GL_COA_MAPPING_RULES_T WHERE SOURCE_SYSTEM = lv_src_system 
        AND TARGET_SYSTEM = lv_tgt_system AND TARGET_SEGMENT = cur_p_segment_name 
        and COA_MAP_ID = cur_p_coa_map_id and DEFAULT_VALUE is not null;

        CURSOR cur_segment_desc(cur_p_sgt_name varchar2, cur_p_tgt_system varchar2) is
        select SEGMENT_DESC
        from WSC_GL_COA_SEGMENT_DEFINITIONS_T
        where SEGMENT_NAME = cur_p_sgt_name and SYSTEM_NAME = cur_p_tgt_system;

		CURSOR cur_tgt_val(cur_p_r_id varchar2, cur_p_segment_name varchar2, cur_p_coa_map_id number) IS
        select values_table.TARGET_SEGMENT 
		FROM WSC_GL_COA_MAPPING_RULES_T mapping_table, WSC_GL_COA_SEGMENT_VALUE_T values_table
		where
		COA_MAP_ID = cur_p_coa_map_id
		and 
		values_table.FLAG = 'Y'
		AND 
		(values_table.SOURCE_SEGMENT1 = lv_segment_value1 OR (values_table.SOURCE_SEGMENT1 IS  null and mapping_table.SOURCE_SEGMENT1 IS  null))
		AND 
		(values_table.SOURCE_SEGMENT2 = lv_segment_value2  OR (values_table.SOURCE_SEGMENT2 IS  null and mapping_table.SOURCE_SEGMENT2 IS  null))
		AND 
		(values_table.SOURCE_SEGMENT3 = lv_segment_value3 OR (values_table.SOURCE_SEGMENT3 IS  null and mapping_table.SOURCE_SEGMENT3 IS  null))
		AND 
		(values_table.SOURCE_SEGMENT4 = lv_segment_value4  OR (values_table.SOURCE_SEGMENT4 IS  null and mapping_table.SOURCE_SEGMENT4 IS  null))
        AND 
		(values_table.SOURCE_SEGMENT5 = lv_segment_value5 OR (values_table.SOURCE_SEGMENT5 IS  null and mapping_table.SOURCE_SEGMENT5 IS  null))
        AND 
		(values_table.SOURCE_SEGMENT6 = lv_segment_value6 OR (values_table.SOURCE_SEGMENT6 IS  null and mapping_table.SOURCE_SEGMENT6 IS  null))
        AND 
		(values_table.SOURCE_SEGMENT7 = lv_segment_value7 OR (values_table.SOURCE_SEGMENT7 IS  null and mapping_table.SOURCE_SEGMENT7 IS  null))
        AND 
		(values_table.SOURCE_SEGMENT8 = lv_segment_value8 OR (values_table.SOURCE_SEGMENT8 IS  null and mapping_table.SOURCE_SEGMENT8 IS  null))
        AND 
		(values_table.SOURCE_SEGMENT9 = lv_segment_value9 OR (values_table.SOURCE_SEGMENT9 IS  null and mapping_table.SOURCE_SEGMENT9 IS  null))
        AND 
		(values_table.SOURCE_SEGMENT10 = lv_segment_value10 OR (values_table.SOURCE_SEGMENT10 IS  null and mapping_table.SOURCE_SEGMENT10 IS  null))
        and mapping_table.TARGET_SEGMENT = cur_p_segment_name 
        and mapping_table.rule_id = values_table.rule_id
        AND 
		mapping_table.rule_id = cur_p_r_id;
        
--		select values_table.TARGET_SEGMENT
--		FROM WSC_GL_COA_MAPPING_RULES_T mapping_table, WSC_GL_COA_SEGMENT_VALUE_T values_table
--		where
--		COA_MAP_ID = cur_p_coa_map_id
--		and 
--		values_table.FLAG = 'Y'
--		and
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT1='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT1 = segment_value1) OR mapping_table.SOURCE_SEGMENT1 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT2='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT2 = segment_value2) OR mapping_table.SOURCE_SEGMENT2 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT3='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT3 = segment_value3) OR mapping_table.SOURCE_SEGMENT3 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT4='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT4 = segment_value4) OR mapping_table.SOURCE_SEGMENT4 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT5='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT5 = segment_value5) OR mapping_table.SOURCE_SEGMENT5 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT6='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT6 = segment_value6) OR mapping_table.SOURCE_SEGMENT6 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT7='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT7 = segment_value7) OR mapping_table.SOURCE_SEGMENT7 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT8='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT8 = segment_value8) OR mapping_table.SOURCE_SEGMENT8 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT9='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT9 = segment_value8) OR mapping_table.SOURCE_SEGMENT9 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT10='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT10 = segment_value10) OR mapping_table.SOURCE_SEGMENT10 IS  null) 
--		AND 
--		mapping_table.rule_id = cur_p_r_id;


	BEGIN

		open cur_coa_map_id;
		fetch cur_coa_map_id INTO lv_coa_map_id;
		close cur_coa_map_id;

--        dbms_output.put_line('1 '||lv_coa_map_id);
		for sgt_name in cur_segment_name
		loop
            lv_tgt_value := null;

			for mapping_rule in cur_mapping_rule(sgt_name.SEGMENT_NAME,lv_coa_map_id)
			loop
        		-- dbms_output.put('RULE_PRIORITY : ');
				-- dbms_output.put_line(mapping_rule.RULE_PRIORITY);
--                dbms_output.put_line('2 ' || mapping_rule.RULE_ID ||'.'||sgt_name.SEGMENT_NAME ||'.' ||lv_coa_map_id);

				open cur_tgt_val(mapping_rule.RULE_ID, sgt_name.SEGMENT_NAME, lv_coa_map_id);
				fetch cur_tgt_val INTO lv_tgt_value;
				close cur_tgt_val;
--                dbms_output.put_line('2.1 ' ||lv_tgt_value);

				if lv_tgt_value is not null then

					exit;
				end if;
			end loop; 
--dbms_output.put_line('3');
			IF lv_tgt_value IS NULL THEN
				open cur_def_tgt_val(sgt_name.SEGMENT_NAME, lv_coa_map_id);
				fetch cur_def_tgt_val INTO lv_tgt_value;
				close cur_def_tgt_val;
--                dbms_output.put_line('4 '||lv_tgt_value);

				IF lv_tgt_value IS NULL THEN 
                    open cur_segment_desc(sgt_name.SEGMENT_NAME, lv_tgt_system);
                    fetch cur_segment_desc INTO lv_seg_name;
                    close cur_segment_desc;
--                    dbms_output.put_line('5 '||lv_seg_name);

--					select SEGMENT_DESC into lv_seg_name
--					from WSC_GL_COA_SEGMENT_DEFINITIONS_T
--					where SEGMENT_NAME = sgt_name.SEGMENT_NAME and SYSTEM_NAME = lv_tgt_system;
					lv_error_flag := 'True';
                    lv_error_msg := lv_error_msg || lv_seg_name || ' not found ';
--dbms_output.put_line('6 '||lv_error_msg);
					-- IF lv_error_msg IS NULL THEN
					--     lv_error_msg := sgt_name.SEGMENT_NAME;
					-- ELSE
					--     lv_error_msg := lv_error_msg || '.' ||sgt_name.SEGMENT_NAME;
					-- END IF;

				end if;
			end if;

			IF sgt_name.SEGMENT_NAME = 'segment1' THEN
				lv_tgt_value_final := lv_tgt_value;
			ELSE
				lv_tgt_value_final := lv_tgt_value_final || '.' ||lv_tgt_value;
			END IF;

			-- dbms_output.put_line(lv_tgt_value);
			-- dbms_output.put_line('---');


		end loop;

		IF (lv_error_flag = 'True') THEN
			lv_tgt_value_final :=  lv_error_msg;
		ELSE
			lv_tgt_value_final := lv_tgt_value_final;
		END IF;

		RETURN lv_tgt_value_final; 

	END coa_mapping; 

--	FUNCTION coa_mapping(
--		src_system VARCHAR2,
--		tgt_system VARCHAR2,
--		segment_value1 VARCHAR2,
--		segment_value2 VARCHAR2,
--		segment_value3 VARCHAR2,
--		segment_value4 VARCHAR2,
--		segment_value5 VARCHAR2,
--		segment_value6 VARCHAR2,
--		segment_value7 VARCHAR2,
--		segment_value8 VARCHAR2,
--		segment_value9 VARCHAR2,
--		segment_value10 VARCHAR2
--	)
--	RETURN varchar2 IS 
--
--		lv_tgt_value VARCHAR2(100);
--		lv_tgt_value_final VARCHAR2(300);
--        lv_error_flag VARCHAR2(100) := 'False';
--        lv_error_flag_final VARCHAR2(100) := 'False';
--	    lv_error_msg VARCHAR2(1000) := null;
--        lv_error_msg_final VARCHAR2(1000) := null;
--        lv_seg_name varchar2(100) := null;
--		lv_coa_map_id number;
--
--		CURSOR cur_coa_map_id IS
--		select COA_MAP_ID 
--		from WSC_GL_COA_MAP_T WHERE SOURCE_SYSTEM = src_system AND TARGET_SYSTEM = tgt_system;
--
--		CURSOR cur_segment_name IS
--		SELECT SEGMENT_NAME
--		FROM WSC_GL_COA_SEGMENT_DEFINITIONS_T
--		WHERE SYSTEM_NAME = tgt_system
--		ORDER BY DISPLAY_SEQUENCE;
--
--		CURSOR cur_mapping_rule(cur_p_segment_name VARCHAR2, cur_p_coa_map_id number) IS 
--		SELECT RULE_PRIORITY, RULE_ID FROM WSC_GL_COA_MAPPING_RULES_T
--		WHERE SOURCE_SYSTEM = src_system AND TARGET_SYSTEM = tgt_system 
--        AND TARGET_SEGMENT = cur_p_segment_name and COA_MAP_ID = cur_p_coa_map_id and DEFAULT_VALUE is NULL
--		ORDER BY RULE_PRIORITY;
--
--		CURSOR cur_def_tgt_val(cur_p_segment_name varchar2, cur_p_coa_map_id number) IS
--		select default_value
--		from WSC_GL_COA_MAPPING_RULES_T WHERE SOURCE_SYSTEM = src_system 
--        AND TARGET_SYSTEM = tgt_system AND TARGET_SEGMENT = cur_p_segment_name 
--        and COA_MAP_ID = cur_p_coa_map_id and DEFAULT_VALUE is not null;
--
--        CURSOR cur_segment_desc(cur_p_sgt_name varchar2, cur_p_tgt_system varchar2) is
--        select SEGMENT_DESC
--        from WSC_GL_COA_SEGMENT_DEFINITIONS_T
--        where SEGMENT_NAME = cur_p_sgt_name and SYSTEM_NAME = cur_p_tgt_system;
--
--		CURSOR cur_tgt_val(cur_p_r_id varchar2, cur_p_segment_name varchar2, cur_p_coa_map_id number) IS
--        select values_table.TARGET_SEGMENT 
--		FROM WSC_GL_COA_MAPPING_RULES_T mapping_table, WSC_GL_COA_SEGMENT_VALUE_T values_table
--		where
--		COA_MAP_ID = cur_p_coa_map_id
--		and 
--		values_table.FLAG = 'Y'
--		AND 
--		(values_table.SOURCE_SEGMENT1 = segment_value1 OR values_table.SOURCE_SEGMENT1 IS  null)
--		AND 
--		(values_table.SOURCE_SEGMENT2 = segment_value2  OR values_table.SOURCE_SEGMENT2 IS  null)
--		AND 
--		(values_table.SOURCE_SEGMENT3 = segment_value3 OR values_table.SOURCE_SEGMENT3 IS  null)
--		AND 
--		(values_table.SOURCE_SEGMENT4 = segment_value4  OR values_table.SOURCE_SEGMENT4 IS  null)
--        AND 
--		(values_table.SOURCE_SEGMENT5 = segment_value5 OR values_table.SOURCE_SEGMENT5 IS  null)
--        AND 
--		(values_table.SOURCE_SEGMENT6 = segment_value6 OR values_table.SOURCE_SEGMENT6 IS  null)
--        AND 
--		(values_table.SOURCE_SEGMENT7 = segment_value7 OR values_table.SOURCE_SEGMENT7 IS  null)
--        AND 
--		(values_table.SOURCE_SEGMENT8 = segment_value8 OR values_table.SOURCE_SEGMENT8 IS  null)
--        AND 
--		(values_table.SOURCE_SEGMENT9 = segment_value9 OR values_table.SOURCE_SEGMENT9 IS  null)
--        AND 
--		(values_table.SOURCE_SEGMENT10 = segment_value10 OR values_table.SOURCE_SEGMENT10 IS  null)
--        and mapping_table.TARGET_SEGMENT = cur_p_segment_name 
--        and mapping_table.rule_id = values_table.rule_id
--        AND 
--		mapping_table.rule_id = cur_p_r_id;
--        
----		select values_table.TARGET_SEGMENT
----		FROM WSC_GL_COA_MAPPING_RULES_T mapping_table, WSC_GL_COA_SEGMENT_VALUE_T values_table
----		where
----		COA_MAP_ID = cur_p_coa_map_id
----		and 
----		values_table.FLAG = 'Y'
----		and
----		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT1='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT1 = segment_value1) OR mapping_table.SOURCE_SEGMENT1 IS  null) 
----		AND 
----		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT2='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT2 = segment_value2) OR mapping_table.SOURCE_SEGMENT2 IS  null) 
----		AND 
----		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT3='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT3 = segment_value3) OR mapping_table.SOURCE_SEGMENT3 IS  null) 
----		AND 
----		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT4='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT4 = segment_value4) OR mapping_table.SOURCE_SEGMENT4 IS  null) 
----		AND 
----		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT5='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT5 = segment_value5) OR mapping_table.SOURCE_SEGMENT5 IS  null) 
----		AND 
----		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT6='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT6 = segment_value6) OR mapping_table.SOURCE_SEGMENT6 IS  null) 
----		AND 
----		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT7='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT7 = segment_value7) OR mapping_table.SOURCE_SEGMENT7 IS  null) 
----		AND 
----		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT8='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT8 = segment_value8) OR mapping_table.SOURCE_SEGMENT8 IS  null) 
----		AND 
----		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT9='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT9 = segment_value8) OR mapping_table.SOURCE_SEGMENT9 IS  null) 
----		AND 
----		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT10='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT10 = segment_value10) OR mapping_table.SOURCE_SEGMENT10 IS  null) 
----		AND 
----		mapping_table.rule_id = cur_p_r_id;
--
--
--	BEGIN
--
--		open cur_coa_map_id;
--		fetch cur_coa_map_id INTO lv_coa_map_id;
--		close cur_coa_map_id;
--
----        dbms_output.put_line('1 '||lv_coa_map_id);
--		for sgt_name in cur_segment_name
--		loop
--            lv_tgt_value := null;
--
--			for mapping_rule in cur_mapping_rule(sgt_name.SEGMENT_NAME,lv_coa_map_id)
--			loop
--        		-- dbms_output.put('RULE_PRIORITY : ');
--				-- dbms_output.put_line(mapping_rule.RULE_PRIORITY);
----                dbms_output.put_line('2 ' || mapping_rule.RULE_ID ||'.'||sgt_name.SEGMENT_NAME ||'.' ||lv_coa_map_id);
--
--				open cur_tgt_val(mapping_rule.RULE_ID, sgt_name.SEGMENT_NAME, lv_coa_map_id);
--				fetch cur_tgt_val INTO lv_tgt_value;
--				close cur_tgt_val;
----                dbms_output.put_line('2.1 ' ||lv_tgt_value);
--
--				if lv_tgt_value is not null then
--
--					exit;
--				end if;
--			end loop; 
----dbms_output.put_line('3');
--			IF lv_tgt_value IS NULL THEN
--				open cur_def_tgt_val(sgt_name.SEGMENT_NAME, lv_coa_map_id);
--				fetch cur_def_tgt_val INTO lv_tgt_value;
--				close cur_def_tgt_val;
----                dbms_output.put_line('4 '||lv_tgt_value);
--
--				IF lv_tgt_value IS NULL THEN 
--                    open cur_segment_desc(sgt_name.SEGMENT_NAME, tgt_system);
--                    fetch cur_segment_desc INTO lv_seg_name;
--                    close cur_segment_desc;
----                    dbms_output.put_line('5 '||lv_seg_name);
--
----					select SEGMENT_DESC into lv_seg_name
----					from WSC_GL_COA_SEGMENT_DEFINITIONS_T
----					where SEGMENT_NAME = sgt_name.SEGMENT_NAME and SYSTEM_NAME = tgt_system;
--					lv_error_flag := 'True';
--                    lv_error_msg := lv_error_msg || lv_seg_name || ' not found ';
----dbms_output.put_line('6 '||lv_error_msg);
--					-- IF lv_error_msg IS NULL THEN
--					--     lv_error_msg := sgt_name.SEGMENT_NAME;
--					-- ELSE
--					--     lv_error_msg := lv_error_msg || '.' ||sgt_name.SEGMENT_NAME;
--					-- END IF;
--
--				end if;
--			end if;
--
--			IF sgt_name.SEGMENT_NAME = 'segment1' THEN
--				lv_tgt_value_final := lv_tgt_value;
--			ELSE
--				lv_tgt_value_final := lv_tgt_value_final || '.' ||lv_tgt_value;
--			END IF;
--
--			-- dbms_output.put_line(lv_tgt_value);
--			-- dbms_output.put_line('---');
--
--
--		end loop;
--
--		IF (lv_error_flag = 'True') THEN
--			lv_tgt_value_final :=  lv_error_msg;
--		ELSE
--			lv_tgt_value_final := lv_tgt_value_final;
--		END IF;
--
--		RETURN lv_tgt_value_final; 
--
--	END coa_mapping; 

--
-- Procedure populate_mapped_coa(
--		src_system varchar2,
--		tgt_system varchar2
--		) IS
--
--	TYPE COA_SEGMENTS IS RECORD
--		(
--			SEGMENT1	VARCHAR2(10),
--			SEGMENT2	VARCHAR2(10),
--			SEGMENT3	VARCHAR2(10),
--			SEGMENT4	VARCHAR2(10),
--			SEGMENT5	VARCHAR2(10),
--			SEGMENT6	VARCHAR2(10),
--			SEGMENT7	VARCHAR2(10),
--			CONCAT_SEG	VARCHAR2(80)
--		);
--
--	TYPE V_COA_SEGMENTS IS TABLE OF COA_SEGMENTS;
--
--	L_COA_SEGMENTS	V_COA_SEGMENTS;
--
--	c_limit PLS_INTEGER := 10000;
--
--    l_error_count NUMBER;
--
--    messag varchar2(1000);
--
--	Cursor C1 is 
--	SELECT SOURCE_SEGMENT1 SEGMENT1,SOURCE_SEGMENT2 SEGMENT2,
--	SOURCE_SEGMENT3 SEGMENT3,SOURCE_SEGMENT4 SEGMENT4,
--	SOURCE_SEGMENT5 SEGMENT5,SOURCE_SEGMENT6 SEGMENT6,
--	SOURCE_SEGMENT7 SEGMENT7,(SOURCE_SEGMENT1||'.'||SOURCE_SEGMENT2||'.'||SOURCE_SEGMENT3||'.'||SOURCE_SEGMENT4||'.'||SOURCE_SEGMENT5||'.'||SOURCE_SEGMENT6||'.'||SOURCE_SEGMENT1) CONCAT_SEG FROM WSC_AHCS_COA_CONCAT_SEGMENT;
--
--BEGIN
--
-- insert into timer values(systimestamp,null);
-- commit;
--
--	OPEN C1;
--
--	LOOP
--	  FETCH C1
--      BULK COLLECT INTO L_COA_SEGMENTS
--      LIMIT 400;
--
--	  EXIT WHEN L_COA_SEGMENTS.COUNT = 0;
--      BEGIN
--	  FORALL indx IN 1 .. L_COA_SEGMENTS.COUNT SAVE EXCEPTIONS
--         Insert into LC_GL_CCID_MAPPING_T(COA_MAP_ID,ENABLE_FLAG,SOURCE_SEGMENT,TARGET_SEGMENT,CREATION_DATE,LAST_UPDATE_DATE) 
--		 VALUES (1,'Y',L_COA_SEGMENTS(indx).CONCAT_SEG, WSC_GL_COA_MAPPING_PKG.COA_MAPPING(src_system,tgt_system,L_COA_SEGMENTS(indx).SEGMENT1,L_COA_SEGMENTS(indx).SEGMENT2,L_COA_SEGMENTS(indx).SEGMENT3,L_COA_SEGMENTS(indx).SEGMENT4,L_COA_SEGMENTS(indx).SEGMENT5,L_COA_SEGMENTS(indx).SEGMENT6,L_COA_SEGMENTS(indx).SEGMENT7,null,null,null),SYSDATE,SYSDATE); 
--     EXCEPTION
--       WHEN OTHERS THEN
--          l_error_count := SQL%BULK_EXCEPTIONS.count;
--           DBMS_OUTPUT.put_line('Number of failures: ' || l_error_count);
--
--		  FOR i IN 1 .. l_error_count LOOP
--         --   DBMS_OUTPUT.put_line('Error: ' || i || 
--        --  ' Array Index: ' || SQL%BULK_EXCEPTIONS(i).error_index ||
--      --    ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
--      messag :=SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
--          Insert into Err_Desc values('Error: ' || i || substr(messag,1,999));
--
--       END LOOP;
--       Commit;
--       END;
--
--    END LOOP;
--     Commit;
--
--     update timer set end_time=systimestamp;
--     commit;
--
--EXCEPTION
--    WHEN OTHERS THEN
--       DBMS_OUTPUT.put_line('ERROR IN populate_mapped_coa procedure'); 
--END;      

END wsc_gl_coa_mapping_pkg;
/
--create or replace PACKAGE BODY wsc_gl_coa_mapping_pkg IS
--
--    FUNCTION  ccid_match ( 
--        src_sgt IN varchar2,
--        P_COA_MAP_ID in  number
--    ) RETURN VARCHAR2 IS
--        f_tgt_sgt varchar2(1000);
--        cursor tgt_sgt is select TARGET_SEGMENT from wsc_gl_ccid_mapping_t
--        where SOURCE_SEGMENT = src_sgt and COA_MAP_ID = P_COA_MAP_ID  and ENABLE_FLAG = 'Y';
--    BEGIN  
--        open tgt_sgt;
--        fetch tgt_sgt into f_tgt_sgt;
--        close tgt_sgt;
--        return f_tgt_sgt;
--    EXCEPTION 
--        WHEN no_data_found THEN 
--            RETURN null; 
--        WHEN OTHERS THEN 
--            RETURN null; 
--    END ccid_match;
--
--	FUNCTION coa_mapping(
--		src_system VARCHAR2,
--		tgt_system VARCHAR2,
--		segment_value1 VARCHAR2,
--		segment_value2 VARCHAR2,
--		segment_value3 VARCHAR2,
--		segment_value4 VARCHAR2,
--		segment_value5 VARCHAR2,
--		segment_value6 VARCHAR2,
--		segment_value7 VARCHAR2,
--		segment_value8 VARCHAR2,
--		segment_value9 VARCHAR2,
--		segment_value10 VARCHAR2
--	)
--	RETURN varchar2 IS 
--
--		lv_tgt_value VARCHAR2(100);
--		lv_tgt_value_final VARCHAR2(300);
--        lv_error_flag VARCHAR2(100) := 'False';
--        lv_error_flag_final VARCHAR2(100) := 'False';
--	    lv_error_msg VARCHAR2(1000) := null;
--        lv_error_msg_final VARCHAR2(1000) := null;
--        lv_seg_name varchar2(100) := null;
--		lv_coa_map_id number;
--
--		CURSOR cur_coa_map_id IS
--		select COA_MAP_ID 
--		from WSC_GL_COA_MAP_T WHERE SOURCE_SYSTEM = src_system AND TARGET_SYSTEM = tgt_system;
--
--		CURSOR cur_segment_name IS
--		SELECT SEGMENT_NAME
--		FROM WSC_GL_COA_SEGMENT_DEFINITIONS_T
--		WHERE SYSTEM_NAME = tgt_system
--		ORDER BY DISPLAY_SEQUENCE;
--
--		CURSOR cur_mapping_rule(cur_p_segment_name VARCHAR2, cur_p_coa_map_id number) IS 
--		SELECT RULE_PRIORITY, RULE_ID FROM WSC_GL_COA_MAPPING_RULES_T
--		WHERE SOURCE_SYSTEM = src_system AND TARGET_SYSTEM = tgt_system 
--        AND TARGET_SEGMENT = cur_p_segment_name and COA_MAP_ID = cur_p_coa_map_id and DEFAULT_VALUE is NULL
--		ORDER BY RULE_PRIORITY;
--
--		CURSOR cur_def_tgt_val(cur_p_segment_name varchar2, cur_p_coa_map_id number) IS
--		select default_value
--		from WSC_GL_COA_MAPPING_RULES_T WHERE SOURCE_SYSTEM = src_system 
--        AND TARGET_SYSTEM = tgt_system AND TARGET_SEGMENT = cur_p_segment_name 
--        and COA_MAP_ID = cur_p_coa_map_id and DEFAULT_VALUE is not null;
--
--        CURSOR cur_segment_desc(cur_p_sgt_name varchar2, cur_p_tgt_system varchar2) is
--        select SEGMENT_DESC
--        from WSC_GL_COA_SEGMENT_DEFINITIONS_T
--        where SEGMENT_NAME = cur_p_sgt_name and SYSTEM_NAME = cur_p_tgt_system;
--
--		CURSOR cur_tgt_val(cur_p_r_id varchar2, cur_p_segment_name varchar2, cur_p_coa_map_id number) IS 
--		select values_table.TARGET_SEGMENT
--		FROM WSC_GL_COA_MAPPING_RULES_T mapping_table, WSC_GL_COA_SEGMENT_VALUE_T values_table
--		where
--		COA_MAP_ID = cur_p_coa_map_id
--		and 
--		values_table.FLAG = 'Y'
--		and
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT1='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT1 = segment_value1) OR mapping_table.SOURCE_SEGMENT1 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT2='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT2 = segment_value2) OR mapping_table.SOURCE_SEGMENT2 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT3='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT3 = segment_value3) OR mapping_table.SOURCE_SEGMENT3 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT4='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT4 = segment_value4) OR mapping_table.SOURCE_SEGMENT4 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT5='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT5 = segment_value5) OR mapping_table.SOURCE_SEGMENT5 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT6='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT6 = segment_value6) OR mapping_table.SOURCE_SEGMENT6 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT7='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT7 = segment_value7) OR mapping_table.SOURCE_SEGMENT7 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT8='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT8 = segment_value8) OR mapping_table.SOURCE_SEGMENT8 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT9='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT9 = segment_value9) OR mapping_table.SOURCE_SEGMENT9 IS  null) 
--		AND 
--		((mapping_table.TARGET_SEGMENT = cur_p_segment_name and mapping_table.SOURCE_SEGMENT10='Y' and mapping_table.rule_id = values_table.rule_id and values_table.SOURCE_SEGMENT10 = segment_value10) OR mapping_table.SOURCE_SEGMENT10 IS  null) 
--		AND 
--		mapping_table.rule_id = cur_p_r_id;
--
--
--	BEGIN
--
--		open cur_coa_map_id;
--		fetch cur_coa_map_id INTO lv_coa_map_id;
--		close cur_coa_map_id;
--
----        dbms_output.put_line('1 '||lv_coa_map_id);
--		for sgt_name in cur_segment_name
--		loop
--            lv_tgt_value := null;
--
--			for mapping_rule in cur_mapping_rule(sgt_name.SEGMENT_NAME,lv_coa_map_id)
--			loop
--        		-- dbms_output.put('RULE_PRIORITY : ');
--				-- dbms_output.put_line(mapping_rule.RULE_PRIORITY);
----                dbms_output.put_line('2 ' || mapping_rule.RULE_ID ||'.'||sgt_name.SEGMENT_NAME ||'.' ||lv_coa_map_id);
--
--				open cur_tgt_val(mapping_rule.RULE_ID, sgt_name.SEGMENT_NAME, lv_coa_map_id);
--				fetch cur_tgt_val INTO lv_tgt_value;
--				close cur_tgt_val;
----                dbms_output.put_line('2.1 ' ||lv_tgt_value);
--
--				if lv_tgt_value is not null then
--
--					exit;
--				end if;
--			end loop; 
----dbms_output.put_line('3');
--			IF lv_tgt_value IS NULL THEN
--				open cur_def_tgt_val(sgt_name.SEGMENT_NAME, lv_coa_map_id);
--				fetch cur_def_tgt_val INTO lv_tgt_value;
--				close cur_def_tgt_val;
----                dbms_output.put_line('4 '||lv_tgt_value);
--
--				IF lv_tgt_value IS NULL THEN 
--                    open cur_segment_desc(sgt_name.SEGMENT_NAME, tgt_system);
--                    fetch cur_segment_desc INTO lv_seg_name;
--                    close cur_segment_desc;
----                    dbms_output.put_line('5 '||lv_seg_name);
--
----					select SEGMENT_DESC into lv_seg_name
----					from WSC_GL_COA_SEGMENT_DEFINITIONS_T
----					where SEGMENT_NAME = sgt_name.SEGMENT_NAME and SYSTEM_NAME = tgt_system;
--					lv_error_flag := 'True';
--                    lv_error_msg := lv_error_msg || lv_seg_name || ' not found ';
----dbms_output.put_line('6 '||lv_error_msg);
--					-- IF lv_error_msg IS NULL THEN
--					--     lv_error_msg := sgt_name.SEGMENT_NAME;
--					-- ELSE
--					--     lv_error_msg := lv_error_msg || '.' ||sgt_name.SEGMENT_NAME;
--					-- END IF;
--
--				end if;
--			end if;
--
--			IF sgt_name.SEGMENT_NAME = 'segment1' THEN
--				lv_tgt_value_final := lv_tgt_value;
--			ELSE
--				lv_tgt_value_final := lv_tgt_value_final || '.' ||lv_tgt_value;
--			END IF;
--
--			-- dbms_output.put_line(lv_tgt_value);
--			-- dbms_output.put_line('---');
--
--
--		end loop;
--
--		IF (lv_error_flag = 'True') THEN
--			lv_tgt_value_final :=  lv_error_msg;
--		ELSE
--			lv_tgt_value_final := lv_tgt_value_final;
--		END IF;
--
--		RETURN lv_tgt_value_final; 
--
--	END coa_mapping; 
--
----
---- Procedure populate_mapped_coa(
----		src_system varchar2,
----		tgt_system varchar2
----		) IS
----
----	TYPE COA_SEGMENTS IS RECORD
----		(
----			SEGMENT1	VARCHAR2(10),
----			SEGMENT2	VARCHAR2(10),
----			SEGMENT3	VARCHAR2(10),
----			SEGMENT4	VARCHAR2(10),
----			SEGMENT5	VARCHAR2(10),
----			SEGMENT6	VARCHAR2(10),
----			SEGMENT7	VARCHAR2(10),
----			CONCAT_SEG	VARCHAR2(80)
----		);
----
----	TYPE V_COA_SEGMENTS IS TABLE OF COA_SEGMENTS;
----
----	L_COA_SEGMENTS	V_COA_SEGMENTS;
----
----	c_limit PLS_INTEGER := 10000;
----
----    l_error_count NUMBER;
----
----    messag varchar2(1000);
----
----	Cursor C1 is 
----	SELECT SOURCE_SEGMENT1 SEGMENT1,SOURCE_SEGMENT2 SEGMENT2,
----	SOURCE_SEGMENT3 SEGMENT3,SOURCE_SEGMENT4 SEGMENT4,
----	SOURCE_SEGMENT5 SEGMENT5,SOURCE_SEGMENT6 SEGMENT6,
----	SOURCE_SEGMENT7 SEGMENT7,(SOURCE_SEGMENT1||'.'||SOURCE_SEGMENT2||'.'||SOURCE_SEGMENT3||'.'||SOURCE_SEGMENT4||'.'||SOURCE_SEGMENT5||'.'||SOURCE_SEGMENT6||'.'||SOURCE_SEGMENT1) CONCAT_SEG FROM WSC_AHCS_COA_CONCAT_SEGMENT;
----
----BEGIN
----
---- insert into timer values(systimestamp,null);
---- commit;
----
----	OPEN C1;
----
----	LOOP
----	  FETCH C1
----      BULK COLLECT INTO L_COA_SEGMENTS
----      LIMIT 400;
----
----	  EXIT WHEN L_COA_SEGMENTS.COUNT = 0;
----      BEGIN
----	  FORALL indx IN 1 .. L_COA_SEGMENTS.COUNT SAVE EXCEPTIONS
----         Insert into LC_GL_CCID_MAPPING_T(COA_MAP_ID,ENABLE_FLAG,SOURCE_SEGMENT,TARGET_SEGMENT,CREATION_DATE,LAST_UPDATE_DATE) 
----		 VALUES (1,'Y',L_COA_SEGMENTS(indx).CONCAT_SEG, WSC_GL_COA_MAPPING_PKG.COA_MAPPING(src_system,tgt_system,L_COA_SEGMENTS(indx).SEGMENT1,L_COA_SEGMENTS(indx).SEGMENT2,L_COA_SEGMENTS(indx).SEGMENT3,L_COA_SEGMENTS(indx).SEGMENT4,L_COA_SEGMENTS(indx).SEGMENT5,L_COA_SEGMENTS(indx).SEGMENT6,L_COA_SEGMENTS(indx).SEGMENT7,null,null,null),SYSDATE,SYSDATE); 
----     EXCEPTION
----       WHEN OTHERS THEN
----          l_error_count := SQL%BULK_EXCEPTIONS.count;
----           DBMS_OUTPUT.put_line('Number of failures: ' || l_error_count);
----
----		  FOR i IN 1 .. l_error_count LOOP
----         --   DBMS_OUTPUT.put_line('Error: ' || i || 
----        --  ' Array Index: ' || SQL%BULK_EXCEPTIONS(i).error_index ||
----      --    ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
----      messag :=SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
----          Insert into Err_Desc values('Error: ' || i || substr(messag,1,999));
----
----       END LOOP;
----       Commit;
----       END;
----
----    END LOOP;
----     Commit;
----
----     update timer set end_time=systimestamp;
----     commit;
----
----EXCEPTION
----    WHEN OTHERS THEN
----       DBMS_OUTPUT.put_line('ERROR IN populate_mapped_coa procedure'); 
----END;      
--
--END wsc_gl_coa_mapping_pkg;