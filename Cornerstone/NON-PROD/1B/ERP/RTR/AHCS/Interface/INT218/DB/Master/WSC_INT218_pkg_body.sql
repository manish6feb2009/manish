create or replace PACKAGE BODY wsc_mfap_pkg AS
    PROCEDURE "WSC_MFAP_INSERT_DATA_TEMP_P" (
        in_wsc_mainframeap_stage IN WSC_MFAP_TMP_T_TYPE_TABLE
    ) AS
    BEGIN
        FORALL i IN 1..in_wsc_mainframeap_stage.count
            INSERT INTO WSC_AHCS_MFAP_TXN_TMP_T (
                batch_id,
                rice_id,
                data_string
            ) VALUES (
                in_wsc_mainframeap_stage(i).batch_id,
                in_wsc_mainframeap_stage(i).rice_id,
                REPLACE(in_wsc_mainframeap_stage(i).data_string,'"',' ')
            );

    END "WSC_MFAP_INSERT_DATA_TEMP_P";

    PROCEDURE "WSC_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P" (
        p_batch_id          IN  NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2
    ) AS
        err_msg VARCHAR2(4000);
        p_error_flag varchar2(2);
    BEGIN
        logging_insert('MF AP', p_batch_id, 1, 'Starts ASYNC DB Scheduler job for MF AP', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;

        COMMIT;
         dbms_scheduler.create_job(job_name => 'INVOKE_WSC_PROCESS_MFAP_TEMP_TO_HEADER_LINE' || p_batch_id,
                                 job_type => 'PLSQL_BLOCK',
                                 job_action => '
                                 DECLARE
                                    p_error_flag VARCHAR2(2);
                                 BEGIN                                
         WSC_MFAP_PKG.WSC_PROCESS_MFAP_TEMP_TO_HEADER_LINE_P('
                                               || p_batch_id
                                               || ','''
                                               || p_application_name
                                               || ''','''
                                               || p_file_name
                                               || ''',
                                                p_error_flag
                                                );
        if p_error_flag = '||'''0'''||' then                                   
         wsc_ahcs_mfap_validation_transformation_pkg.data_validation('
                                               || p_batch_id
                                               || ');
                                               
          end if;                                   
       END;',
                                 enabled => true,
                                 auto_drop => true,
                                 comments => 'Async steps to split the data from temp table and insert into header and line tables. Also, update line table, insert into WSC_AHCS_INT_STATUS_T and call Validation and Transformation procedure');

logging_insert('MF AP', p_batch_id, 10, 'End Async', NULL, sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('MF AP', p_batch_id, 5.1, 'Error in Async DB Proc', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            COMMIT;
            dbms_output.put_line(sqlerrm);
    END "WSC_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P";  

PROCEDURE "WSC_PROCESS_MFAP_TEMP_TO_HEADER_LINE_P" (
        p_batch_id IN NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2,
        p_error_flag OUT VARCHAR2
) IS

    v_error_msg            VARCHAR2(200);
    v_stage                VARCHAR2(200);
    
    lv_count  NUMBER;
    err_msg   VARCHAR2(2000);
    l_system  VARCHAR2(200);
    
    CURSOR mfap_stage_hdr_data_cur (
        p_batch_id NUMBER
    ) IS
    SELECT
        *
    FROM
        WSC_AHCS_MFAP_TXN_TMP_T
    WHERE
            batch_id = p_batch_id
        AND TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 1, NULL,
                                   1))= 'H';

    CURSOR mfap_stage_line_data_cur (
        p_batch_id NUMBER
    ) IS
    SELECT
        *
    FROM
        WSC_AHCS_MFAP_TXN_TMP_T
    WHERE
            batch_id = p_batch_id
        AND TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 1, NULL,
                                   1)) = 'D';

    TYPE mfap_stage_hdr_type IS
        TABLE OF mfap_stage_hdr_data_cur%rowtype;
    lv_mfap_stg_hdr_type   mfap_stage_hdr_type;
    TYPE mfap_stage_line_type IS
        TABLE OF mfap_stage_line_data_cur%rowtype;
    lv_mfap_stg_line_type  mfap_stage_line_type;
    BEGIN
   --initialise p_error_flag with 0
    begin
    p_error_flag := '0';

    exception 
    when others then
        logging_insert ('MF AP',p_batch_id,1.1,'value of error flag',sqlerrm,sysdate);
    end; 
--fetch source system name
      BEGIN
            SELECT
                attribute3
            INTO l_system
            FROM
                wsc_ahcs_int_control_t c
            WHERE
                c.batch_id = p_batch_id;

            dbms_output.put_line(l_system);
        END;
    dbms_output.put_line(' Begin segregration of header line data');
    /********** PROCESS UNSTRUCTURED STAGE TABLE DATA TO HEADER TABLE DATA - START *************/
    logging_insert ('MF AP',p_batch_id,2,'STAGE TABLE DATA TO HEADER TABLE DATA - START',null,sysdate);
    
    OPEN mfap_stage_hdr_data_cur(p_batch_id);
    LOOP
        FETCH mfap_stage_hdr_data_cur BULK COLLECT INTO lv_mfap_stg_hdr_type LIMIT 400;
        EXIT WHEN lv_mfap_stg_hdr_type.count = 0;
        
        FORALL i IN 1..lv_mfap_stg_hdr_type.count
        
            INSERT INTO WSC_AHCS_MFAP_TXN_HEADER_T (
                batch_id,
                header_id,
                hdr_seq_nbr,
                interface_id,
                vendor_nbr,
                invoice_nbr,
               invoice_date,
                continent,
                business_unit,
                division,
                location,
                net_total,
                loc_inv_net_total,
                invoice_total,
                local_inv_total,
                refer_invoice,
                purchase_order_nbr,
                po_type,
                invoice_type,
                fx_rate,
                check_nbr,
                check_amount,
                check_date,
                check_stock,
                check_payment_type,
                vendor_payment_type,
                void_code,
                cross_border_flag,
                batch_number,
                batch_date,
                batch_posted_flag,
                pay_from_account,
                transref,
                third_party_intfc_flag,
                payment_ref_id,
                head_office_loc,
                sales_loc,
                third_party_invoice_id,
                vendor_currency_code,
                employee_id,
                vendor_name,
                accounting_date,
                business_segment,
                interfc_desc_t,
                interfc_desc_loc_lang,
               due_date,
                vendor_abbrev,
                frt_bill_pro_ref_nbr,
                spc_inv_code,
                void_date,
                matching_key,
               matching_date,
                updated_user,
                userid,
                contra_reason,
                accrued_qty,
               document_date,
                freight_terms,
                voucher_nbr,
                fiscal_date,
                concur_sae_batch_id,
                fiscal_week_nbr,
                gaap_amount,
                gaap_amount_in_cust_curr,
                journal_source_c,
                error_type,
                error_code,
               transaction_date,
                transaction_number,
--ledger_name,
                --transaction_type,
                creation_date,
                created_by,
                last_update_date,
                last_updated_by,
                record_type
            ) VALUES (
                p_batch_id, -- batch_id
                wsc_mfap_header_t_s1.NEXTVAL,   -- header_id
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)), -- hdr_seq_nbr
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)),  --interface_id
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL, 1)), --vendor_nbr
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL, 1)),  --invoice_nbr
               to_date(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL, 1)), 'mm/dd/yyyy'),      --invoice_date                  
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL, 1)),  --continent
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL, 1)),  --business_unit
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL, 1)),  --division
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL, 1)),   --location
                to_number(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1))),  --net_total
                to_number(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1))),  --loc_inv_net_total
                to_number(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1))),    --invoice_total
                to_number(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1))),    --local_inv_total
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1)),  --refer_invoice
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL, 1)),  --purchase_order_nbr
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL, 1)),  --po_type
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1)),    --invoice_type
                to_number(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL, 1))),   --fx_rate
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1)),   --check_nbr
                to_number(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL, 1))),   --check_amount
               to_date(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1)), 'mm/dd/yyyy'),   --check_date                    
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL, 1)),  --check_date
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)),  --check_payment_type
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)),  --vendor_payment_type
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1)), ---void_code
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL, 1)),
               to_date(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 29, NULL, 1)), 'mm/dd/yyyy'),                       
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 30, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 31, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 32, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 33, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 34, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 36, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 37, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 38, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 39, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 40, NULL, 1)),
               to_date(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 41, NULL, 1)), 'mm/dd/yyyy'),    --ACCOUNTING_DATE                 
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 42, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 43, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 44, NULL, 1)),
               to_date(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 45, NULL, 1)), 'mm/dd/yyyy'),    --DUE_DATE                  
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 46, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 47, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 48, NULL, 1)),
              to_date(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 49, NULL, 1)), 'mm/dd/yyyy'),  --VOID_DATE                    
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 50, NULL, 1)),
               to_date(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 51, NULL, 1)), 'mm/dd/yyyy'),    --MATCHING_DATE                  
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 52, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 53, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 54, NULL, 1)),
                to_number(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL, 1))),
               to_date(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 56, NULL, 1)), 'mm/dd/yyyy'),   --DOCUMENT_DATE                   
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 57, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 58, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 59, NULL, 1)),     --FISCAL_DATE                    
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 60, NULL, 1)),
                to_number(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 61, NULL, 1))),
                to_number(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 62, NULL, 1))),
                to_number(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 63, NULL, 1))),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 64, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 65, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 66, NULL, 1)),
               to_date(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 41, NULL, 1)), 'mm/dd/yyyy'),      --TRANSACTION_DATE                 
                SUBSTR(TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)),1,3)|| TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) , --transaction_number
               -- TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1))|| TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)),
--ledger_name,
                    /*CASE
                            WHEN TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'APIN' THEN
                                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1))
                            WHEN TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'ADIN' THEN
                                  CASE
                                  WHEN TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)) = 'CHK' OR TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)) = 'ACH' OR TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)) = 'WIR' OR TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)) = 'SPC'  THEN
                                       'AXE_ADIN_PAYMENTS'
                                  ELSE TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)',  1, 26, NULL, 1))  
                                  END
                            WHEN TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'CAIN' THEN
                                'AXE_CAIN_INVOICES'
                            WHEN TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'AQIN' THEN
                                'AXE_AQIN_IC_INVOICES'  
                                --LSI logic pending
                            ELSE    'AXE_LSIN_LSI' 
                        END,    */            
                sysdate,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                TRIM(regexp_substr(lv_mfap_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL, 1))
            );
            
           
/********** PROCESS UNSTRUCTURED STAGE TABLE DATA TO HEADER TABLE DATA - END *************/
    END LOOP;
   /* logging_insert('MF AP', p_batch_id, 2.3, 'value of error flag', p_error_flag,sysdate);
    CLOSE mfap_stage_hdr_data_cur;
    EXCEPTION
        WHEN OTHERS THEN
            p_error_flag := '1';
             err_msg := substr(sqlerrm, 1, 200);
             wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT218'
                                                    || '_'
                                                    || l_system,
                                                    'MF AP',
                                                    sqlerrm); */

   -- END;
   -- logging_insert('MF AP', p_batch_id, 2.4, 'value of error flag at header level', p_error_flag, sysdate);
    dbms_output.put_line('HEADER exit');
    COMMIT;
    logging_insert ('MF AP',p_batch_id,3,'STAGE TABLE DATA TO HEADER TABLE DATA - END',null,sysdate);
 
 
 /********** PROCESS UNSTRUCTURED STAGE TABLE DATA TO LINE TABLE DATA - START *************/
    dbms_output.put_line(' Begin segregration of line data');
    logging_insert ('MF AP',p_batch_id,4,'STAGE TABLE DATA TO LINE TABLE DATA - START',null,sysdate);
   
    OPEN mfap_stage_line_data_cur(p_batch_id);
    LOOP
        FETCH mfap_stage_line_data_cur BULK COLLECT INTO lv_mfap_stg_line_type LIMIT 400;
        EXIT WHEN lv_mfap_stg_line_type.count = 0;
        FORALL i IN 1..lv_mfap_stg_line_type.count
            INSERT INTO WSC_AHCS_MFAP_TXN_LINE_T (
                batch_id,
                line_id,
--HEADER_ID,
                hdr_seq_nbr,
                interface_id,
                vendor_nbr,
                invoice_nbr,
                invoice_date,
                continent,
                line_seq_number,
                amount_type,
                db_cr_flag,
                LEG_ACCT,
                LEG_LOC,
                LEG_BU,
                LEG_DEPT,
                LEG_VENDOR,
                gl_project,
                gl_amount_in_loc_curr,
                gl_amnt_in_foriegn_curr,
                local_currency,
                foreign_currency,
                gl_division,
                LEG_AFFILIATE,
                po_line_nbr,
                part_nbr,
                receiver_nbr,
                quantity,
                unit_of_measure,
                uom_conv_factor,
                unit_cost,
                ext_cost,
                fx_rate,
                vendor_item_nbr,
                product_class,
                avg_unit_cost_a,
                gaap_f,
                error_type,
                error_code,
                transaction_number,
                trd_partner_nbr,
                leg_seg_1_4,
                leg_seg_5_7,
                creation_date,
                created_by,
                last_update_date,
                last_updated_by,
                leg_coa,
                record_type
            ) VALUES (
                p_batch_id,
                wsc_mfap_line_s1.NEXTVAL,
                            --HEADER_ID,
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)), --hdr_seq_nbr
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)), --interface_id
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL, 1)), --vendor_nbr
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL, 1)), --invoice_nbr
               to_date(TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL, 1)), 'mm/dd/yyyy'),                     --invoice_date  
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL, 1)), --continent
                to_number(TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL, 1))), --line_seq_number
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL, 1)),  --amount_type
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL, 1)),  --db_cr_flag
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1)),  --LEG_ACCT
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1)),  --LEG_LOC
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)),  --LEG_BU
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1)),  --LEG_DEPT
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1)),  --LEG_VENDOR
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL, 1)),  --gl_project
                to_number(TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL, 1))),  --gl_amount_in_loc_curr
                to_number(TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1))),  --gl_amnt_in_foriegn_curr
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL, 1)),  --local_currency
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1)),  --foreign_currency
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL, 1)),  --gl_division
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1)),   --LEG_AFFILIATE
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)),
                to_number(TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1))),
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL, 1)),
                to_number(TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL, 1))),
                to_number(TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 29, NULL, 1))),
                to_number(TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 30, NULL, 1))),
                to_number(TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 31, NULL, 1))),
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 32, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 33, NULL, 1)),
                to_number(TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 34, NULL, 1))),
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 36, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 37, NULL, 1)),
                SUBSTR(TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)),1,3)|| TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)),  --transaction_number
               -- TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1))|| TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)),
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL, 1))|| TRIM(regexp_substr(lv_mfap_stg_line_type(
                i).data_string, '([^|]*)(\||$)', 1, 7, NULL, 1)),  --trd_partner_nbr
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1))
                || '.'
                || TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1))
                || '.'
                || TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1))
                || '.'
                || TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1)),  --leg_seg_1_4
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1))
                || '.'
                || TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1)),  --leg_seg_5_7
                sysdate,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1))
                || '.'
                || TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1))
                || '.'
                || TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1))
                || '.'
                || TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1))
                || '.'
                || TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1))
                || '.'
                || nvl(TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1)),'00000'),   --leg_coa,
                TRIM(regexp_substr(lv_mfap_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL, 1))
                  );
/********** PROCESS UNSTRUCTURED STAGE TABLE DATA TO LINE TABLE DATA - END *************/
    END LOOP;
 /*logging_insert('MF AP', p_batch_id, 2.5, 'value of error flag', p_error_flag,
      sysdate);
    CLOSE mfap_stage_line_data_cur;
    EXCEPTION
        WHEN OTHERS THEN
            p_error_flag := '1';
            err_msg := substr(sqlerrm, 1, 200);
             wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT218'
                                                    || '_'
                                                    || l_system,
                                                    'MF AP',
                                                    sqlerrm);  */

   -- END;
  --  logging_insert('MF AP', p_batch_id, 2.6, 'value of error flag at line level', p_error_flag,sysdate);
    dbms_output.put_line('LINE exit');
    COMMIT;
    logging_insert ('MF AP',p_batch_id,5,'STAGE TABLE DATA TO LINE TABLE DATA - END',null,sysdate);
    
    logging_insert('MF AP', p_batch_id, 6, 'Updating MF AP Line table with header id starts', NULL,
                      sysdate);
      

        UPDATE WSC_AHCS_MFAP_TXN_LINE_T line
        SET
            ( header_id,
              leg_coa ) = (
                SELECT  /*+ index(hdr WSC_AHCS_MFAP_TXN_HEADER_HDR_SEQ_NBR_I) */
                    hdr.header_id,
                    leg_coa
                FROM
                    WSC_AHCS_MFAP_TXN_HEADER_T hdr
                WHERE
                        line.hdr_seq_nbr = hdr.hdr_seq_nbr
                    AND line.batch_id = hdr.batch_id
            )
        --and rownum =1)
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        logging_insert('MF AP', p_batch_id, 7, 'Updating MF AP Line table with header id ends', NULL,
                      sysdate);
        logging_insert('MF AP', p_batch_id, 8, 'Inserting records in status table starts', NULL,
                      sysdate);
        INSERT INTO wsc_ahcs_int_status_t (
            header_id,
            line_id,
            application,
            file_name,
            batch_id,
            status,
            cr_dr_indicator,
            currency,
            value,
            source_coa,
            legacy_header_id,
            legacy_line_number,
            attribute3,
            attribute11,
            INTERFACE_ID,
            created_by,
            created_date,
            last_updated_by,
            last_updated_date
        )
            SELECT
                line.header_id,
                line.line_id,
                p_application_name,
                p_file_name,
                p_batch_id,
                'NEW',
                line.db_cr_flag,
                line.local_currency,
                line.gl_amount_in_loc_curr,
                line.leg_coa,
                line.hdr_seq_nbr,
                line.line_seq_number,
                line.transaction_number,             
                hdr.accounting_date, 
                 line.INTERFACE_ID,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
                WSC_AHCS_MFAP_TXN_LINE_T    line,
                WSC_AHCS_MFAP_TXN_HEADER_T  hdr
            WHERE
                    line.batch_id = p_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id;

        COMMIT;
        logging_insert('MF AP', p_batch_id, 9, 'Inserting records in status table ends', NULL,
                      sysdate);    
    EXCEPTION
        WHEN OTHERS THEN
           p_error_flag := '1';
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('MF AP', p_batch_id, 9.1,
                          'Error in WSC_PROCESS_MFAP_STAGE_TO_HEADER_LINE proc',
                          sqlerrm,
                          sysdate);
            wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                    'INT218'
                                                    || '_'
                                                    || l_system,
                                                    'MF AP',
                                                    sqlerrm);

            dbms_output.put_line(sqlerrm);
    END "WSC_PROCESS_MFAP_TEMP_TO_HEADER_LINE_P";
  
  
    end wsc_mfap_pkg;
/	