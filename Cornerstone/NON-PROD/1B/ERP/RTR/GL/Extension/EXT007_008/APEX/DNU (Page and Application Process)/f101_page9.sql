prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- ORACLE Application Express (APEX) export file
--
-- You should run the script connected to SQL*Plus as the Oracle user
-- APEX_210100 or as the owner (parsing schema) of the application.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_api.import_begin (
 p_version_yyyy_mm_dd=>'2021.04.15'
,p_release=>'21.1.0'
,p_default_workspace_id=>1701052144005286
,p_default_application_id=>101
,p_default_id_offset=>29579689224955998307
,p_default_owner=>'FININT'
);
end;
/
 
prompt APPLICATION 101 - Upload and Download COA Value Segment and CCID  Mapping
--
-- Application Export:
--   Application:     101
--   Name:            Upload and Download COA Value Segment and CCID  Mapping
--   Date and Time:   06:19 Tuesday January 31, 2023
--   Exported By:     WESCO_DEV_DEVELOPER
--   Flashback:       0
--   Export Type:     Page Export
--   Manifest
--     PAGE: 9
--   Manifest End
--   Version:         21.1.0
--   Instance ID:     696797807250078
--

begin
null;
end;
/
prompt --application/pages/delete_00009
begin
wwv_flow_api.remove_page (p_flow_id=>wwv_flow.g_flow_id, p_page_id=>9);
end;
/
prompt --application/pages/page_00009
begin
wwv_flow_api.create_page(
 p_id=>9
,p_user_interface_id=>wwv_flow_api.id(29581573747695996843)
,p_name=>'CCID Mismatch Report'
,p_alias=>'CCID-MISMATCH-REPORT'
,p_step_title=>'CCID Mismatch Report'
,p_autocomplete_on_off=>'OFF'
,p_page_template_options=>'#DEFAULT#'
,p_page_is_public_y_n=>'Y'
,p_last_updated_by=>'WESCO_DEV_DEVELOPER'
,p_last_upd_yyyymmddhh24miss=>'20230124062103'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(5426114714532105)
,p_plug_name=>'CCID Map ID'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>wwv_flow_api.id(29581499813915996782)
,p_plug_display_sequence=>10
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(6756830474543322)
,p_plug_name=>'Report'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>wwv_flow_api.id(29581499813915996782)
,p_plug_display_sequence=>20
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(7807512102495322)
,p_plug_name=>'Mismatch Header'
,p_parent_plug_id=>wwv_flow_api.id(6756830474543322)
,p_region_template_options=>'#DEFAULT#'
,p_component_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(29581498636133996781)
,p_plug_display_sequence=>40
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select coa_name, status , CCID_STATUS, TOTAL_COUNT,',
'COMPLETE_COUNT,',
'-- REMAINING_COUNT, TOTAL_MISMATCH , USERNAME InitiatedBy, case when status = ''Success'' and TOTAL_MISMATCH > 0 then ''Download'' else null end as Download ',
'REMAINING_COUNT, TOTAL_MISMATCH , USERNAME InitiatedBy, case when status = ''Success'' then ''Download'' end as Download',
' ,',
'case when CCID_STATUS = ''Action Required'' then ',
'''<span class="t-Button t-Button--small t-Button--primary t-Button--stretch view-error-action"> Update </span>'' ',
'-- -- ''Update''',
' end ',
' as Update_Cache',
'-- ''Update'' as Update_cache',
'-- , ''test123'' as test123',
'from WSC_CCID_MISMATCH_DATA_HDR_T'))
,p_plug_source_type=>'NATIVE_IR'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_prn_content_disposition=>'ATTACHMENT'
,p_prn_document_header=>'APEX'
,p_prn_units=>'INCHES'
,p_prn_paper_size=>'LETTER'
,p_prn_width=>11
,p_prn_height=>8.5
,p_prn_orientation=>'HORIZONTAL'
,p_prn_page_header=>'Mismatch Header'
,p_prn_page_header_font_color=>'#000000'
,p_prn_page_header_font_family=>'Helvetica'
,p_prn_page_header_font_weight=>'normal'
,p_prn_page_header_font_size=>'12'
,p_prn_page_footer_font_color=>'#000000'
,p_prn_page_footer_font_family=>'Helvetica'
,p_prn_page_footer_font_weight=>'normal'
,p_prn_page_footer_font_size=>'12'
,p_prn_header_bg_color=>'#EEEEEE'
,p_prn_header_font_color=>'#000000'
,p_prn_header_font_family=>'Helvetica'
,p_prn_header_font_weight=>'bold'
,p_prn_header_font_size=>'10'
,p_prn_body_bg_color=>'#FFFFFF'
,p_prn_body_font_color=>'#000000'
,p_prn_body_font_family=>'Helvetica'
,p_prn_body_font_weight=>'normal'
,p_prn_body_font_size=>'10'
,p_prn_border_width=>.5
,p_prn_page_header_alignment=>'CENTER'
,p_prn_page_footer_alignment=>'CENTER'
,p_prn_border_color=>'#666666'
);
wwv_flow_api.create_worksheet(
 p_id=>wwv_flow_api.id(7807693501495323)
,p_max_row_count=>'1000000'
,p_pagination_type=>'ROWS_X_TO_Y'
,p_pagination_display_pos=>'BOTTOM_RIGHT'
,p_report_list_mode=>'TABS'
,p_lazy_loading=>false
,p_show_detail_link=>'N'
,p_show_notify=>'Y'
,p_download_formats=>'CSV:HTML:XLSX:PDF:RTF:EMAIL'
,p_owner=>'WESCO_DEV_DEVELOPER'
,p_internal_uid=>7807693501495323
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(7807750202495324)
,p_db_column_name=>'COA_NAME'
,p_display_order=>10
,p_column_identifier=>'A'
,p_column_label=>'Coa Name'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(7807804464495325)
,p_db_column_name=>'STATUS'
,p_display_order=>20
,p_column_identifier=>'B'
,p_column_label=>'Status'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(7807904651495326)
,p_db_column_name=>'CCID_STATUS'
,p_display_order=>30
,p_column_identifier=>'C'
,p_column_label=>'Ccid Status'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(7808042688495327)
,p_db_column_name=>'TOTAL_COUNT'
,p_display_order=>40
,p_column_identifier=>'D'
,p_column_label=>'Total Count'
,p_column_type=>'NUMBER'
,p_column_alignment=>'RIGHT'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(7808140885495328)
,p_db_column_name=>'COMPLETE_COUNT'
,p_display_order=>50
,p_column_identifier=>'E'
,p_column_label=>'Completed Count'
,p_column_type=>'NUMBER'
,p_column_alignment=>'RIGHT'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(7808217277495329)
,p_db_column_name=>'REMAINING_COUNT'
,p_display_order=>60
,p_column_identifier=>'F'
,p_column_label=>'Remaining Count'
,p_column_type=>'NUMBER'
,p_column_alignment=>'RIGHT'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(7808333309495330)
,p_db_column_name=>'TOTAL_MISMATCH'
,p_display_order=>70
,p_column_identifier=>'G'
,p_column_label=>'Total Mismatch'
,p_column_type=>'NUMBER'
,p_column_alignment=>'RIGHT'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(7808427009495331)
,p_db_column_name=>'INITIATEDBY'
,p_display_order=>80
,p_column_identifier=>'H'
,p_column_label=>'Initiated By'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(7808533449495332)
,p_db_column_name=>'DOWNLOAD'
,p_display_order=>90
,p_column_identifier=>'I'
,p_column_label=>'Download'
,p_column_link=>'f?p=&APP_ID.:9:&SESSION.:APPLICATION_PROCESS=WSC_MISMATCH_CACHE_DOWNLOAD:&DEBUG.:CR,:P_COA_MAP_ID:#COA_NAME#'
,p_column_linktext=>'#DOWNLOAD#'
,p_column_type=>'STRING'
);
wwv_flow_api.create_worksheet_column(
 p_id=>wwv_flow_api.id(7809623723495343)
,p_db_column_name=>'UPDATE_CACHE'
,p_display_order=>100
,p_column_identifier=>'J'
,p_column_label=>'Update Cache'
,p_column_link=>'f?p=&APP_ID.:9:&SESSION.:APPLICATION_PROCESS=WSC_MISMATCH_CACHE_UPDATE:&DEBUG.:CR,:P_COA_MAP_ID:#COA_NAME#'
,p_column_linktext=>'#UPDATE_CACHE#'
,p_column_type=>'STRING'
,p_display_text_as=>'WITHOUT_MODIFICATION'
,p_format_mask=>'PCT_GRAPH:::'
);
wwv_flow_api.create_worksheet_rpt(
 p_id=>wwv_flow_api.id(7918216488037749)
,p_application_user=>'APXWS_DEFAULT'
,p_report_seq=>10
,p_report_alias=>'79183'
,p_status=>'PUBLIC'
,p_is_default=>'Y'
,p_report_columns=>'COA_NAME:STATUS:CCID_STATUS:TOTAL_COUNT:COMPLETE_COUNT:REMAINING_COUNT:TOTAL_MISMATCH:INITIATEDBY:DOWNLOAD:UPDATE_CACHE'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(5426261722532106)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_api.id(5426114714532105)
,p_button_name=>'Extract'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(29581551877927996815)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Initiate Process'
,p_button_position=>'BELOW_BOX'
,p_warn_on_unsaved_changes=>null
,p_button_condition=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- select 1 from WSC_CCID_MISMATCH_DATA_HDR_T where batch_id = :P_BATCH_ID',
'-- and status = ''In Process''',
'',
'select 1 from WSC_CCID_MISMATCH_DATA_HDR_T a, wsc_gl_coa_map_t b where b.coa_map_id = :CCID_MAP_ID and a.coa_name = b.coa_map_name',
'and status = ''In Process''',
'union all',
'select 1 from WSC_CCID_MISMATCH_DATA_HDR_T  where :CCID_MAP_ID = 99',
'and status = ''In Process'''))
,p_button_condition_type=>'NOT_EXISTS'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(6755084150543304)
,p_button_sequence=>30
,p_button_plug_id=>wwv_flow_api.id(5426114714532105)
,p_button_name=>'Refresh'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(29581551877927996815)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Refresh'
,p_button_position=>'BELOW_BOX'
,p_warn_on_unsaved_changes=>null
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(6755160422543305)
,p_button_sequence=>40
,p_button_plug_id=>wwv_flow_api.id(5426114714532105)
,p_button_name=>'CACHEUPDATE'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(29581551877927996815)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Update Cache Table'
,p_button_position=>'BELOW_BOX'
,p_warn_on_unsaved_changes=>null
,p_button_condition=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- select 1 from WSC_CCID_MISMATCH_DATA_HDR_T where batch_id = :P_BATCH_ID',
'-- and status = ''Success'' and ccid_status <> ''Success''',
'',
'--WORKING AS EXPECTED',
'-- select 1 from WSC_CCID_MISMATCH_DATA_HDR_T where status = ''Success'' and ccid_status = ''Action Required''',
'-- and (select count(1) from WSC_CCID_MISMATCH_DATA_HDR_T where status = ''In Process'') = 0',
'',
'',
'SELECT 1 FROM DUAL WHERE 1=2'))
,p_button_condition_type=>'EXISTS'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(5426351242532107)
,p_name=>'CCID_MAP_ID'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(5426114714532105)
,p_prompt=>'CCID Map ID'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_lov=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select ''All'' a, 99 b from dual ',
'union all',
'select  coa_map_name a, coa_map_id b from wsc_gl_coa_map_t',
'WHERE COA_MAP_ID <> 5'))
,p_lov_display_null=>'YES'
,p_cHeight=>1
,p_field_template=>wwv_flow_api.id(29581551449508996813)
,p_item_template_options=>'#DEFAULT#'
,p_lov_display_extra=>'YES'
,p_attribute_01=>'NONE'
,p_attribute_02=>'N'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(5426421779532108)
,p_name=>'New'
,p_event_sequence=>10
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_api.id(5426261722532106)
,p_bind_type=>'bind'
,p_bind_event_type=>'click'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(5426587404532109)
,p_event_id=>wwv_flow_api.id(5426421779532108)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_EXECUTE_PLSQL_CODE'
,p_attribute_01=>wwv_flow_string.join(wwv_flow_t_varchar2(
'declare',
'    batch_id number := WSC_CCID_MISMATCH_BATCH_ID.nextval;',
'begin',
'    :P_BATCH_ID := batch_id;',
'    BEGIN',
'    -- insert into wsc_tbl_time_t (a,b,c) values (TO_CHAR(:P_BATCH_ID)||''_''||to_char(:P_USER_NAME),sysdate,123456789);',
'    -- commit;',
'',
'    if (:CCID_MAP_ID <> 99) then',
'',
'    -- insert into wsc_tbl_time_t (a,b,c) values (TO_CHAR(:CCID_MAP_ID)||''_''||to_char(:P_USER_NAME),sysdate,123456789);',
'    -- commit;',
'',
'    dbms_scheduler.create_job (',
'    job_name   =>  ''WSC_CCID_MISMATCH_REPORT''||batch_id,',
'    job_type   => ''PLSQL_BLOCK'',',
'    job_action => ',
'        ''DECLARE',
'        L_ERR_MSG VARCHAR2(2000);',
'        L_ERR_CODE VARCHAR2(2);',
'        BEGIN ',
'            WSC_CCID_MISMATCH_REPORT.WSC_CCID(''||:CCID_MAP_ID||'',''||batch_id||'',''''''||:P_USER_NAME||'''''');',
'        END;'',',
'    enabled   =>  TRUE,  ',
'    auto_drop =>  TRUE, ',
'    comments  =>  ''WSC_CCID_MISMATCH_REPORT'');',
'    else',
'        BEGIN ',
'            WSC_CCID_MISMATCH_REPORT.WSC_CCID_ALL(:CCID_MAP_ID, :P_USER_NAME);',
'        END;',
'    end if;',
'    END;  ',
'',
'    -- WSC_CCID_MISMATCH_REPORT.WSC_CCID(:CCID_MAP_ID,batch_id);',
'end;'))
,p_attribute_05=>'PLSQL'
,p_wait_for_result=>'Y'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(5426609538532110)
,p_event_id=>wwv_flow_api.id(5426421779532108)
,p_event_result=>'TRUE'
,p_action_sequence=>20
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_SUBMIT_PAGE'
,p_attribute_02=>'Y'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(6755756608543311)
,p_name=>'New_1'
,p_event_sequence=>20
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_api.id(6755084150543304)
,p_bind_type=>'bind'
,p_bind_event_type=>'click'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(6755841472543312)
,p_event_id=>wwv_flow_api.id(6755756608543311)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_SUBMIT_PAGE'
,p_attribute_02=>'Y'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(6755952440543313)
,p_name=>'New_2'
,p_event_sequence=>30
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_api.id(6755160422543305)
,p_bind_type=>'bind'
,p_bind_event_type=>'click'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(6756289270543316)
,p_event_id=>wwv_flow_api.id(6755952440543313)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_CONFIRM'
,p_attribute_01=>'Do you want to update the cache table?'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(6756099966543314)
,p_event_id=>wwv_flow_api.id(6755952440543313)
,p_event_result=>'TRUE'
,p_action_sequence=>20
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_EXECUTE_PLSQL_CODE'
,p_attribute_01=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- BEGIN',
'--     WSC_CCID_MISMATCH_REPORT.WSC_CCID_UPDATE;',
'-- end;',
'declare',
'    batch_id number := WSC_CCID_MISMATCH_BATCH_ID.nextval;',
'BEGIN',
'    dbms_scheduler.create_job (',
'    job_name   =>  ''WSC_CCID_MISMATCH_REPORT''||batch_id,',
'    job_type   => ''PLSQL_BLOCK'',',
'    job_action => ',
'        ''DECLARE',
'        L_ERR_MSG VARCHAR2(2000);',
'        L_ERR_CODE VARCHAR2(2);',
'        BEGIN ',
'            WSC_CCID_MISMATCH_REPORT.WSC_CCID_UPDATE(''''''||:P_USER_NAME||'''''');',
'        END;'',',
'    enabled   =>  TRUE,  ',
'    auto_drop =>  TRUE, ',
'    comments  =>  ''WSC_CCID_MISMATCH_REPORT'');',
'    END;  '))
,p_attribute_05=>'PLSQL'
,p_wait_for_result=>'Y'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(6756144418543315)
,p_event_id=>wwv_flow_api.id(6755952440543313)
,p_event_result=>'TRUE'
,p_action_sequence=>30
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_SUBMIT_PAGE'
,p_attribute_02=>'Y'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(7808608080495333)
,p_name=>'New_4'
,p_event_sequence=>50
,p_triggering_element_type=>'ITEM'
,p_triggering_element=>'CCID_MAP_ID'
,p_bind_type=>'bind'
,p_bind_event_type=>'change'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(7808793396495334)
,p_event_id=>wwv_flow_api.id(7808608080495333)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_SUBMIT_PAGE'
,p_attribute_02=>'Y'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(7372737878194427)
,p_process_sequence=>10
,p_process_point=>'AFTER_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'New'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- declare',
'-- lv_batch_id number;',
'-- lv_show_hide number;',
'-- begin',
'--     select batch_id into lv_batch_id from WSC_CCID_MISMATCH_DATA_HDR_T;',
'--     :P_BATCH_ID  := lv_batch_id;',
'    ',
'--     select  case when status <> ''In Process'' then 1 else 0 end into lv_show_hide  from WSC_CCID_MISMATCH_DATA_HDR_T;',
'--     :SHOW_HIDE :=  lv_show_hide;',
'-- end;',
'',
'-- begin',
'-- null;',
'-- end;',
'',
'declare',
'username varchar2(200) := APEX_UTIL.GET_SESSION_STATE(''USER_NAME'');',
'begin :P_USER_NAME := username; end;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(7806125182495308)
,p_process_sequence=>10
,p_process_point=>'BEFORE_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'New_1'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'DECLARE',
'v_user_name varchar2(200);',
'v_jwt_token  varchar2(4000);',
'',
'BEGIN',
'',
'-- APEX_CUSTOM_AUTH.SET_USER(''WESCO_USER'');',
'-- APEX_UTIL.SET_SESSION_STATE(''USER_NAME'',''WESCO_USER'');',
'',
'IF  APEX_UTIL.GET_SESSION_STATE(''USER_NAME'') IS NULL THEN',
'   ',
'  xx_apex_user_security_pkg.main(v_jwt_token,v_user_name,null);  ',
'  ',
'  APEX_UTIL.SET_SESSION_STATE(''USER_NAME'',v_user_name);',
'    APEX_UTIL.SET_SESSION_STATE(''JWT_TOKEN'',v_jwt_token);',
'   ',
'    IF APEX_UTIL.GET_SESSION_STATE(''USER_NAME'') IS NULL THEN',
'        APEX_UTIL.REDIRECT_URL(''f?p=&APP_ID.:9999:&APP_SESSION.'');',
'   ELSE',
'        APEX_CUSTOM_AUTH.SET_USER(APEX_UTIL.GET_SESSION_STATE(''USER_NAME''));',
'        ',
'   END IF;',
'   ',
'ELSE',
'   APEX_CUSTOM_AUTH.SET_USER(APEX_UTIL.GET_SESSION_STATE(''USER_NAME''));  ',
'   ',
'END IF;',
'',
'END;',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
end;
/
prompt --application/end_environment
begin
wwv_flow_api.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false));
commit;
end;
/
set verify on feedback on define on
prompt  ...done
