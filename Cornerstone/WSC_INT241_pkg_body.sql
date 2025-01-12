create or replace PACKAGE BODY wsc_mfjti_pkg AS

    PROCEDURE wsc_jtiinv_header_p (
        in_wsc_jtiinv_header IN wsc_jti_mfinv_header_t_type_table
    ) AS
        err_msg VARCHAR2(2000);
    BEGIN
        FORALL i IN 1..in_wsc_jtiinv_header.count
            INSERT INTO wsc_ahcs_mfinv_txn_header_t (
                batch_id,
                header_id,
                interface_id,
                amount,
                amount_in_cust_curr,
                tax_invc_i,
                gaap_amount,
                gaap_amount_in_cust_curr,
                local_inv_total,
                accrued_qty,
                freight_factor,
                invoice_date,
                invoice_due_date,
                adjustment_date,
                account_date,
                document_date,
                continent,
                po_type,
                location,
                invoice_type,
                customer_type,
                invoice_currency,
                customer_currency,
                ship_type,
                export_type,
                record_error_code,
                non_ra_credit_type,
                emea_flag,
                item_uom_c,
                ib30_reason_c,
                receiver_loc,
                ra_loc,
                final_dest,
                journal_source_c,
                kava_f,
                division,
                source_system,
                customer_nbr,
                business_unit,
                ship_from_loc,
                freight_vendor_nbr,
                freight_invoice_nbr,
                cash_batch_nbr,
                gl_div_headqtr_loc,
                gl_div_hq_loc_bu,
                ship_from_loc_bu,
                ps_affiliate_bu,
                receiver_nbr,
                fiscal_date,
                business_segment,
                sales_order_nbr,
                payment_terms,
                freight_terms,
                ra_nbr,
                sales_rep,
                catalog_nbr,
                reel_nbr,
                product_class,
                vendor_part_nbr,
                trans_id,
                receipt_type,
                ra_customer_nbr,
                gl_transfer,
                invoice_nbr,
                freight_bill_nbr,
                hdr_seq_nbr,
                customer_name,
                cust_po,
                transaction_type,
                ib30_memo,
                transaction_number,
                ledger_name,
                file_name,
                interface_desc_en,
                interface_desc_frn,
                inv_total,
                purchase_code_hdr,
				INVOICE_TOTAL,
				TOT_FOREIGN_AMT,
				PURCHASE_CODE
            ) VALUES (
                in_wsc_jtiinv_header(i).batch_id,
                wsc_mfinv_header_t_s1.NEXTVAL,---in_wsc_jtiinv_header(i).header_id,
                TRIM(in_wsc_jtiinv_header(i).interface_id),
                TRIM(to_number(in_wsc_jtiinv_header(i).amount)),
                TRIM(to_number(in_wsc_jtiinv_header(i).amount_in_cust_curr)),
                TRIM(to_number(in_wsc_jtiinv_header(i).tax_invc_i)),
                TRIM(to_number(in_wsc_jtiinv_header(i).gaap_amount)),
                TRIM(to_number(in_wsc_jtiinv_header(i).gaap_amount_in_cust_curr)),
                TRIM(to_number(in_wsc_jtiinv_header(i).local_inv_total)),
                TRIM(to_number(in_wsc_jtiinv_header(i).accrued_qty)),
                TRIM(to_number(in_wsc_jtiinv_header(i).freight_factor)),
                TRIM(to_date(TRIM(in_wsc_jtiinv_header(i).invoice_date), 'yyyy-mm-dd')), ---to_date(TRIM(p_jti_mfar_header_t(i).invoice_date), 'yyyy-mm-dd')
                TRIM(to_date(TRIM(in_wsc_jtiinv_header(i).invoice_due_date), 'yyyy-mm-dd')),
                TRIM(to_date(TRIM(in_wsc_jtiinv_header(i).adjustment_date), 'yyyy-mm-dd')),
                TRIM(to_date(TRIM(in_wsc_jtiinv_header(i).account_date), 'yyyy-mm-dd')),
                TRIM(to_date(TRIM(in_wsc_jtiinv_header(i).document_date), 'yyyy-mm-dd')),
                TRIM(in_wsc_jtiinv_header(i).continent),
                TRIM(in_wsc_jtiinv_header(i).po_type),
                TRIM(in_wsc_jtiinv_header(i).location),
                TRIM(in_wsc_jtiinv_header(i).invoice_type),
                TRIM(in_wsc_jtiinv_header(i).customer_type),
                TRIM(in_wsc_jtiinv_header(i).invoice_currency),
                TRIM(in_wsc_jtiinv_header(i).customer_currency),
                TRIM(in_wsc_jtiinv_header(i).ship_type),
                TRIM(in_wsc_jtiinv_header(i).export_type),
                TRIM(in_wsc_jtiinv_header(i).record_error_code),
                TRIM(in_wsc_jtiinv_header(i).non_ra_credit_type),
                TRIM(in_wsc_jtiinv_header(i).emea_flag),
                TRIM(in_wsc_jtiinv_header(i).item_uom_c),
                TRIM(in_wsc_jtiinv_header(i).ib30_reason_c),
                TRIM(in_wsc_jtiinv_header(i).receiver_loc),
                TRIM(in_wsc_jtiinv_header(i).ra_loc),
                TRIM(in_wsc_jtiinv_header(i).final_dest),
                TRIM(in_wsc_jtiinv_header(i).journal_source_c),
                TRIM(in_wsc_jtiinv_header(i).kava_f),
                TRIM(in_wsc_jtiinv_header(i).division),
                TRIM(in_wsc_jtiinv_header(i).source_system),
                TRIM(in_wsc_jtiinv_header(i).customer_nbr),
                TRIM(in_wsc_jtiinv_header(i).business_unit),
                TRIM(in_wsc_jtiinv_header(i).ship_from_loc),
                TRIM(in_wsc_jtiinv_header(i).freight_vendor_nbr),
                TRIM(in_wsc_jtiinv_header(i).freight_invoice_nbr),
                TRIM(in_wsc_jtiinv_header(i).cash_batch_nbr),
                TRIM(in_wsc_jtiinv_header(i).gl_div_headqtr_loc),
                TRIM(in_wsc_jtiinv_header(i).gl_div_hq_loc_bu),
                TRIM(in_wsc_jtiinv_header(i).ship_from_loc_bu),
                TRIM(in_wsc_jtiinv_header(i).ps_affiliate_bu),
                TRIM(in_wsc_jtiinv_header(i).receiver_nbr),
                TRIM(to_date(TRIM(in_wsc_jtiinv_header(i).fiscal_date), 'yyyy-mm-dd')), --- in_wsc_jtiinv_header(i).fiscal_date,
                TRIM(in_wsc_jtiinv_header(i).business_segment),
                TRIM(in_wsc_jtiinv_header(i).sales_order_nbr),
                TRIM(in_wsc_jtiinv_header(i).payment_terms),
                TRIM(in_wsc_jtiinv_header(i).freight_terms),
                TRIM(in_wsc_jtiinv_header(i).ra_nbr),
                TRIM(in_wsc_jtiinv_header(i).sales_rep),
                TRIM(in_wsc_jtiinv_header(i).catalog_nbr),
                TRIM(in_wsc_jtiinv_header(i).reel_nbr),
                TRIM(in_wsc_jtiinv_header(i).product_class),
                TRIM(in_wsc_jtiinv_header(i).vendor_part_nbr),
                TRIM(in_wsc_jtiinv_header(i).trans_id),
                TRIM(in_wsc_jtiinv_header(i).receipt_type),
                TRIM(in_wsc_jtiinv_header(i).ra_customer_nbr),
                TRIM(in_wsc_jtiinv_header(i).gl_transfer),
                TRIM(in_wsc_jtiinv_header(i).invoice_nbr),
                TRIM(in_wsc_jtiinv_header(i).freight_bill_nbr),
                TRIM(in_wsc_jtiinv_header(i).hdr_seq_nbr),
                TRIM(in_wsc_jtiinv_header(i).customer_name),
                TRIM(in_wsc_jtiinv_header(i).cust_po),
                TRIM(in_wsc_jtiinv_header(i).transaction_type),
                TRIM(in_wsc_jtiinv_header(i).ib30_memo),
                TRIM(in_wsc_jtiinv_header(i).transaction_number),
                TRIM(in_wsc_jtiinv_header(i).ledger_name),
                TRIM(in_wsc_jtiinv_header(i).file_name),
                TRIM(in_wsc_jtiinv_header(i).interface_desc_en),
                TRIM(in_wsc_jtiinv_header(i).interface_desc_frn),
                TRIM(to_number(in_wsc_jtiinv_header(i).inv_total)),
                TRIM(in_wsc_jtiinv_header(i).purchase_code_hdr),
				TRIM(to_number(in_wsc_jtiinv_header(i).INVOICE_TOTAL)),
				TRIM(to_number(in_wsc_jtiinv_header(i).TOT_FOREIGN_AMT)),
				TRIM(in_wsc_jtiinv_header(i).PURCHASE_CODE)
            );

        COMMIT;
--    EXCEPTION
--        WHEN OTHERS THEN
--            err_msg := substr(sqlerrm, 1, 200);
--            logging_insert('JTI_MFINV', NULL, 1.1, 'Error while Inserting in JTI_MFINV Header Table Proc', sqlerrm,
--                          sysdate);
    END wsc_jtiinv_header_p;

    PROCEDURE wsc_jtiinv_line_p (
        in_wsc_jtiinv_line IN wsc_jti_mfinv_line_t_type_table
    ) AS
        err_msg VARCHAR2(2000);
    BEGIN
        FORALL i IN 1..in_wsc_jtiinv_line.count
            INSERT INTO wsc_ahcs_mfinv_txn_line_t (
                batch_id,
                line_id,
                header_id,
                line_seq_number,
                amount,
                amount_in_cust_curr,
                unit_price,
                shipped_quantity,
                uom_cnvrn_factor,
                billed_qty,
                avg_unit_cost,
                std_unit_cost,
                qty_on_hand_before,
                adjustment_qty,
                qty_on_hand_after,
                cur_cost_before,
                adj_cost_local,
                adj_cost_foreign,
                fx_rate,
                cur_cost_after,
                gl_amount_in_loc_curr,
                gl_amnt_in_foriegn_curr,
                quantity,
                uom_conv_factor,
                unit_cost,
                ext_cost,
                avg_unit_cost_a,
                amt_local_curr,
                amt_foreign_curr,
                received_qty,
                received_unit_cost,
                po_unit_cost,
                transaction_amount,
                foreign_ex_rate,
                base_amount,
                invoice_date,
                receipt_date,
                line_updated_date,
                matching_date,
                pc_flag,
                vendor_indicator,
                continent,
                db_cr_flag,
                interface_id,
                line_type,
                amount_type,
                line_nbr,
                lrd_ship_from,
                uom_c,
                invoice_currency,
                customer_currency,
                gaap_f,
                gl_division,
                local_currency,
                foreign_currency,
                po_line_nbr,
                leg_division,
                transaction_curr_cd,
                base_curr_cd,
                transaction_type,
                location,
                mig_sig,
                business_unit,
                payment_code,
                vendor_nbr,
                receiver_nbr,
                unit_of_measure,
                gl_account,
                gl_dept_id,
                adjustment_user_i,
                gl_axe_vendor,
                gl_project,
                gl_axe_loc,
                gl_currency_cd,
                ps_affiliate_bu,
                cash_ar50_comments,
                vendor_abbrev_c,
                qty_cost_reason,
                qty_cost_reason_cd,
                acct_desc,
                acct_nbr,
                loc_code,
                dept_code,
                gl_location,
                gl_vendor,
                buyer_code,
                gl_business_unit,
                gl_department,
                gl_vendor_nbr_full,
                affiliate,
                accounting_date,
                receiver_line_nbr,
                vendor_part_nbr,
                error_type,
                error_code,
                gl_legal_entity,
                gl_acct,
                gl_oper_grp,
                gl_dept,
                gl_site,
                gl_ic,
                gl_projects,
                gl_fut_1,
                gl_fut_2,
                subledger_nbr,
                batch_nbr,
                order_id,
                invoice_nbr,
                product_class,
                part_nbr,
                vendor_item_nbr,
                po_nbr,
                matching_key,
                vendor_name,
                hdr_seq_nbr,
                item_nbr,
                subledger_name,
                line_updated_by,
                vendor_stk_nbr,
                lsi_line_descr,
                creation_date,
                last_update_date,
                created_by,
                last_updated_by,
                leg_coa,
                target_coa,
                statement_id,
                gl_allcon_comments,
                attribute6,
                attribute7,
                attribute8,
                attribute9,
                attribute10,
                attribute11,
                attribute12,
                attribute1,
                attribute2,
                attribute3,
                attribute4,
                attribute5,
                default_amount,
                acc_amount,
                acc_currency,
                default_currency,
                leg_location_ln,
                leg_acct,
                leg_dept,
                location_ln,
                leg_vendor,
                trd_partner_name,
                reason_code,
                transaction_number,
                leg_seg_1_4,
                leg_seg_5_7,
                trd_partner_nbr,
                leg_acct_desc,
                leg_bu,
                leg_loc,
                leg_affiliate,
                ps_location,
                axe_vendor,
                leg_loc_sr,
                product_class_ln,
                leg_bu_ln,
                leg_account,
                leg_department,
                leg_affiliate_ln,
                quantity_dai,
                vendor_part_nbr_ln,
                po_nbr_ln,
                leg_project,
                leg_division_ln,
                record_type
            ) VALUES (
                in_wsc_jtiinv_line(i).batch_id,
                wsc_mfinv_line_s1.NEXTVAL,---in_wsc_jtiinv_line(i).line_id,
                in_wsc_jtiinv_line(i).header_id,
                in_wsc_jtiinv_line(i).line_seq_number,
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).amount)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).amount_in_cust_curr)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).unit_price)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).shipped_quantity)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).uom_cnvrn_factor)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).billed_qty)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).avg_unit_cost)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).std_unit_cost)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).qty_on_hand_before)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).adjustment_qty)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).qty_on_hand_after)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).cur_cost_before)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).adj_cost_local)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).adj_cost_foreign)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).fx_rate)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).cur_cost_after)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).gl_amount_in_loc_curr)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).gl_amnt_in_foriegn_curr)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).quantity)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).uom_conv_factor)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).unit_cost)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).ext_cost)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).avg_unit_cost_a)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).amt_local_curr)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).amt_foreign_curr)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).received_qty)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).received_unit_cost)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).po_unit_cost)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).transaction_amount)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).foreign_ex_rate)),
                TO_NUMBER(TRIM(in_wsc_jtiinv_line(i).base_amount)),
                TRIM(in_wsc_jtiinv_line(i).invoice_date),
                TRIM(in_wsc_jtiinv_line(i).receipt_date),
                TRIM(in_wsc_jtiinv_line(i).line_updated_date),
                TRIM(in_wsc_jtiinv_line(i).matching_date),
                TRIM(in_wsc_jtiinv_line(i).pc_flag),
                TRIM(in_wsc_jtiinv_line(i).vendor_indicator),
                TRIM(in_wsc_jtiinv_line(i).continent),
                TRIM(in_wsc_jtiinv_line(i).db_cr_flag),
                TRIM(in_wsc_jtiinv_line(i).interface_id),
                TRIM(in_wsc_jtiinv_line(i).line_type),
                TRIM(in_wsc_jtiinv_line(i).amount_type),
                TRIM(in_wsc_jtiinv_line(i).line_nbr),
                TRIM(in_wsc_jtiinv_line(i).lrd_ship_from),
                TRIM(in_wsc_jtiinv_line(i).uom_c),
                TRIM(in_wsc_jtiinv_line(i).invoice_currency),
                TRIM(in_wsc_jtiinv_line(i).customer_currency),
                TRIM(in_wsc_jtiinv_line(i).gaap_f),
                TRIM(in_wsc_jtiinv_line(i).gl_division),
                TRIM(in_wsc_jtiinv_line(i).local_currency),
                TRIM(in_wsc_jtiinv_line(i).foreign_currency),
                TRIM(in_wsc_jtiinv_line(i).po_line_nbr),
                TRIM(in_wsc_jtiinv_line(i).leg_division),
                TRIM(in_wsc_jtiinv_line(i).transaction_curr_cd),
                TRIM(in_wsc_jtiinv_line(i).base_curr_cd),
                TRIM(in_wsc_jtiinv_line(i).transaction_type),
                TRIM(in_wsc_jtiinv_line(i).location),
                TRIM(in_wsc_jtiinv_line(i).mig_sig),
                TRIM(in_wsc_jtiinv_line(i).business_unit),
                TRIM(in_wsc_jtiinv_line(i).payment_code),
                TRIM(in_wsc_jtiinv_line(i).vendor_nbr),
                TRIM(in_wsc_jtiinv_line(i).receiver_nbr),
                TRIM(in_wsc_jtiinv_line(i).unit_of_measure),
                TRIM(in_wsc_jtiinv_line(i).gl_account),
                TRIM(in_wsc_jtiinv_line(i).gl_dept_id),
                TRIM(in_wsc_jtiinv_line(i).adjustment_user_i),
                TRIM(in_wsc_jtiinv_line(i).gl_axe_vendor),
                TRIM(in_wsc_jtiinv_line(i).gl_project),
                TRIM(in_wsc_jtiinv_line(i).gl_axe_loc),
                TRIM(in_wsc_jtiinv_line(i).gl_currency_cd),
                TRIM(in_wsc_jtiinv_line(i).ps_affiliate_bu),
                TRIM(in_wsc_jtiinv_line(i).cash_ar50_comments),
                TRIM(in_wsc_jtiinv_line(i).vendor_abbrev_c),
                TRIM(in_wsc_jtiinv_line(i).qty_cost_reason),
                TRIM(in_wsc_jtiinv_line(i).qty_cost_reason_cd),
                TRIM(in_wsc_jtiinv_line(i).acct_desc),
                TRIM(in_wsc_jtiinv_line(i).acct_nbr),
                TRIM(in_wsc_jtiinv_line(i).loc_code),
                TRIM(in_wsc_jtiinv_line(i).dept_code),
                TRIM(in_wsc_jtiinv_line(i).gl_location),
                TRIM(in_wsc_jtiinv_line(i).gl_vendor),
                TRIM(in_wsc_jtiinv_line(i).buyer_code),
                TRIM(in_wsc_jtiinv_line(i).gl_business_unit),
                TRIM(in_wsc_jtiinv_line(i).gl_department),
                TRIM(in_wsc_jtiinv_line(i).gl_vendor_nbr_full),
                TRIM(in_wsc_jtiinv_line(i).affiliate),
                TRIM(in_wsc_jtiinv_line(i).accounting_date),
                TRIM(in_wsc_jtiinv_line(i).receiver_line_nbr),
                TRIM(in_wsc_jtiinv_line(i).vendor_part_nbr),
                TRIM(in_wsc_jtiinv_line(i).error_type),
                TRIM(in_wsc_jtiinv_line(i).error_code),
                TRIM(in_wsc_jtiinv_line(i).gl_legal_entity),
                TRIM(in_wsc_jtiinv_line(i).gl_acct),
                TRIM(in_wsc_jtiinv_line(i).gl_oper_grp),
                TRIM(in_wsc_jtiinv_line(i).gl_dept),
                TRIM(in_wsc_jtiinv_line(i).gl_site),
                TRIM(in_wsc_jtiinv_line(i).gl_ic),
                TRIM(in_wsc_jtiinv_line(i).gl_projects),
                TRIM(in_wsc_jtiinv_line(i).gl_fut_1),
                TRIM(in_wsc_jtiinv_line(i).gl_fut_2),
                TRIM(in_wsc_jtiinv_line(i).subledger_nbr),
                TRIM(in_wsc_jtiinv_line(i).batch_nbr),
                TRIM(in_wsc_jtiinv_line(i).order_id),
                TRIM(in_wsc_jtiinv_line(i).invoice_nbr),
                TRIM(in_wsc_jtiinv_line(i).product_class),
                TRIM(in_wsc_jtiinv_line(i).part_nbr),
                TRIM(in_wsc_jtiinv_line(i).vendor_item_nbr),
                TRIM(in_wsc_jtiinv_line(i).po_nbr),
                TRIM(in_wsc_jtiinv_line(i).matching_key),
                TRIM(in_wsc_jtiinv_line(i).vendor_name),
                TRIM(in_wsc_jtiinv_line(i).hdr_seq_nbr),
                TRIM(in_wsc_jtiinv_line(i).item_nbr),
                TRIM(in_wsc_jtiinv_line(i).subledger_name),
                TRIM(in_wsc_jtiinv_line(i).line_updated_by),
                TRIM(in_wsc_jtiinv_line(i).vendor_stk_nbr),
                TRIM(in_wsc_jtiinv_line(i).lsi_line_descr),
                TRIM(in_wsc_jtiinv_line(i).creation_date),
                TRIM(in_wsc_jtiinv_line(i).last_update_date),
                TRIM(in_wsc_jtiinv_line(i).created_by),
                TRIM(in_wsc_jtiinv_line(i).last_updated_by),
                TRIM(in_wsc_jtiinv_line(i).leg_coa),
                TRIM(in_wsc_jtiinv_line(i).target_coa),
                TRIM(in_wsc_jtiinv_line(i).statement_id),
                TRIM(in_wsc_jtiinv_line(i).gl_allcon_comments),
                TRIM(in_wsc_jtiinv_line(i).attribute6),
                TRIM(in_wsc_jtiinv_line(i).attribute7),
                TRIM(in_wsc_jtiinv_line(i).attribute8),
                TRIM(in_wsc_jtiinv_line(i).attribute9),
                TRIM(in_wsc_jtiinv_line(i).attribute10),
                TRIM(in_wsc_jtiinv_line(i).attribute11),
                TRIM(in_wsc_jtiinv_line(i).attribute12),
                TRIM(in_wsc_jtiinv_line(i).attribute1),
                TRIM(in_wsc_jtiinv_line(i).attribute2),
                TRIM(in_wsc_jtiinv_line(i).attribute3),
                TRIM(in_wsc_jtiinv_line(i).attribute4),
                TRIM(in_wsc_jtiinv_line(i).attribute5),
                TRIM(in_wsc_jtiinv_line(i).default_amount),
                TRIM(in_wsc_jtiinv_line(i).acc_amount),
                TRIM(in_wsc_jtiinv_line(i).acc_currency),
                TRIM(in_wsc_jtiinv_line(i).default_currency),
                TRIM(in_wsc_jtiinv_line(i).leg_location_ln),
                TRIM(in_wsc_jtiinv_line(i).leg_acct),
                TRIM(in_wsc_jtiinv_line(i).leg_dept),
                TRIM(in_wsc_jtiinv_line(i).location_ln),
                TRIM(in_wsc_jtiinv_line(i).leg_vendor),
                TRIM(in_wsc_jtiinv_line(i).trd_partner_name),
                TRIM(in_wsc_jtiinv_line(i).reason_code),
                TRIM(in_wsc_jtiinv_line(i).transaction_number),
                TRIM(in_wsc_jtiinv_line(i).leg_seg_1_4),
                TRIM(in_wsc_jtiinv_line(i).leg_seg_5_7),
                TRIM(in_wsc_jtiinv_line(i).trd_partner_nbr),
                TRIM(in_wsc_jtiinv_line(i).leg_acct_desc),
                TRIM(in_wsc_jtiinv_line(i).leg_bu),
                TRIM(in_wsc_jtiinv_line(i).leg_loc),
                TRIM(in_wsc_jtiinv_line(i).leg_affiliate),
                TRIM(in_wsc_jtiinv_line(i).ps_location),
                TRIM(in_wsc_jtiinv_line(i).axe_vendor),
                TRIM(in_wsc_jtiinv_line(i).leg_loc_sr),
                TRIM(in_wsc_jtiinv_line(i).product_class_ln),
                TRIM(in_wsc_jtiinv_line(i).leg_bu_ln),
                TRIM(in_wsc_jtiinv_line(i).leg_account),
                TRIM(in_wsc_jtiinv_line(i).leg_department),
                TRIM(in_wsc_jtiinv_line(i).leg_affiliate_ln),
                TRIM(in_wsc_jtiinv_line(i).quantity_dai),
                TRIM(in_wsc_jtiinv_line(i).vendor_part_nbr_ln),
                TRIM(in_wsc_jtiinv_line(i).po_nbr_ln),
                TRIM(in_wsc_jtiinv_line(i).leg_project),
                TRIM(in_wsc_jtiinv_line(i).leg_division_ln),
                TRIM(in_wsc_jtiinv_line(i).record_type)
            );

        COMMIT;
--    EXCEPTION
--        WHEN OTHERS THEN
--            err_msg := substr(sqlerrm, 2, 200);
--            logging_insert('JTI_MFINV', NULL, 2.1, 'Error while Inserting in JTI_MFINV Line Table Proc', sqlerrm,
--                          sysdate);
    END wsc_jtiinv_line_p;

    PROCEDURE wsc_jti_mfinv_async_process_update_validate_transform_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    ) AS
        err_msg      VARCHAR2(2000);
        p_error_flag VARCHAR2(2);
    BEGIN
        logging_insert('JTI_MFINV', p_batch_id, 1, 'Starts ASYNC DB Scheduler for MF JTI', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'VALIDATION_SUCCESS'
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        dbms_scheduler.create_job(job_name => 'INVOKE_WSC_MF_INV_JTI_INSERT_DATA_IN_GL_STATUS_P' || p_batch_id, job_type => 'PLSQL_BLOCK',
        job_action => 'DECLARE
                                    p_error_flag VARCHAR2(2);
        BEGIN                              
         wsc_mfjti_pkg.WSC_JTI_MFINV_INSERT_DATA_IN_GL_STATUS_P('
                                                                                                                                         ||
                                                                                                                                         p_batch_id
                                                                                                                                         ||
                                                                                                                                         ','''
                                                                                                                                         ||
                                                                                                                                         p_application_name
                                                                                                                                         ||
                                                                                                                                         ''','''
                                                                                                                                         ||
                                                                                                                                         p_file_name
                                                                                                                                         ||
                                                                                                                                         ''',
                                                p_error_flag
                                                               );
        if p_error_flag = '
                                                                                                                                         ||
                                                                                                                                         '''0'''
                                                                                                                                         ||
                                                                                                                                         ' then       
        wsc_ahcs_mfinv_validation_transformation_pkg.leg_coa_transformation_JTI_MFINV('
                                                                                                                                         ||
                                                                                                                                         p_batch_id
                                                                                                                                         ||
                                                                                                                                         ');
        end if;                                   
        END;', enabled => true, auto_drop => true,
                                 comments => 'Async steps to update, insert into WSC_AHCS_INT_STATUS_T and call Validate and Transform procedure');

    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('JTI_MFINV', p_batch_id, 101, 'Error in Async DB Proc', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            COMMIT;
            dbms_output.put_line(sqlerrm);
    END wsc_jti_mfinv_async_process_update_validate_transform_p;

    PROCEDURE wsc_jti_mfinv_insert_data_in_gl_status_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2,
        p_error_flag       OUT VARCHAR2
    ) IS
        lv_count NUMBER;
        err_msg  VARCHAR2(2000);
	    lv_file_name VARCHAR2(100);

		CURSOR fetch_file_name_ctrl_tbl_cur (
		p_batch_id         NUMBER         
		) IS
		
		SELECT FILE_NAME 
		FROM wsc_ahcs_int_control_t WHERE
                     batch_id = p_batch_id;
					 
		
    BEGIN
        logging_insert('JTI_MFINV', p_batch_id, 2, 'Updating INV Line Table with header id starts', NULL,
                      sysdate);
		
     --initialise p_error_flag with 0
        BEGIN
            p_error_flag := '0';
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('JTI_MFINV', p_batch_id, 1.1, 'value of error flag', sqlerrm,
                              sysdate);
        END;

        UPDATE wsc_ahcs_mfinv_txn_line_t line
        SET
            (header_id,hdr_seq_nbr) = (
                SELECT  /*+ index(hdr WSC_AHCS_MFINV_TXN_HEADER_HDR_SEQ_NBR_I) */
                    hdr.header_id,
                    hdr.hdr_seq_nbr
                FROM
                    wsc_ahcs_mfinv_txn_header_t hdr
                WHERE
                        line.transaction_number = hdr.transaction_number
                    AND line.batch_id = hdr.batch_id
            )
        --and rownum =1)
        WHERE
            batch_id = p_batch_id;
        COMMIT;
		
	BEGIN
	  OPEN fetch_file_name_ctrl_tbl_cur(p_batch_id);
	  FETCH fetch_file_name_ctrl_tbl_cur  INTO lv_file_name;
	  UPDATE wsc_ahcs_mfinv_txn_header_t hdr
        SET
            file_name = lv_file_name
        WHERE
            batch_id = p_batch_id;
        COMMIT;
	  
	  CLOSE fetch_file_name_ctrl_tbl_cur;
	END;
		
		
        logging_insert('JTI_MFINV', p_batch_id, 3, 'Updating MF INV Line table with header id ends', NULL,
                      sysdate);
        logging_insert('JTI_MFINV', p_batch_id, 4, 'Inserting records in status table starts', NULL,
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
            attribute2,
            attribute11,
            interface_id,
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
                'VALIDATION_SUCCESS',
                nvl(line.db_cr_flag,
                    CASE
                        WHEN line.amount >= 0 THEN
                            'DR'
                        WHEN line.amount < 0  THEN
                            'CR'
                    END
                ),---line.db_cr_flag,
                line.local_currency,
                line.amount,
                line.leg_coa,
                line.hdr_seq_nbr,
                line.line_seq_number,
                line.transaction_number,
                'VALIDATION_SUCCESS',
                hdr.account_date,
                line.interface_id,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
                wsc_ahcs_mfinv_txn_line_t   line,
                wsc_ahcs_mfinv_txn_header_t hdr
            WHERE
                    line.batch_id = p_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id;

        COMMIT;
        logging_insert('JTI_MFINV', p_batch_id, 5, 'Inserting records in status table ends', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            p_error_flag := '1';
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('JTI_MFINV', p_batch_id, 102, 'Error in WSC_JTI_MFINV_INSERT_DATA_IN_GL_STATUS_P proc', sqlerrm,
                          sysdate);
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT241', 'JTI_MFINV', sqlerrm);
            dbms_output.put_line(sqlerrm);
    END wsc_jti_mfinv_insert_data_in_gl_status_p;

    PROCEDURE wsc_jti_mfap_header_p (
        in_wsc_jti_mfap_header IN wsc_jti_mfap_header_t_type_table
    ) AS
    BEGIN
        FORALL i IN 1..in_wsc_jti_mfap_header.count
            INSERT INTO wsc_ahcs_mfap_txn_header_t (
                transaction_type,
               -- ledger_name,
                transaction_date,
                transaction_number,
                file_name,
                interface_id,
                hdr_seq_nbr,
                continent,
                invoice_type,
                gaap_amount,
                fiscal_date,
                business_unit,
                location,
                freight_terms,
                interfc_desc_t,
                interfc_desc_loc_lang,
                purchase_order_nbr,
                vendor_nbr,
                local_inv_total,
                refer_invoice,
                check_amount,
                check_date,
                check_stock,
                check_payment_type,
                void_code,
                cross_border_flag,
                batch_number,
                account_currency,
                invoice_total,
                line_type_header_jti,
                business_segment,
                vendor_abbrev,
                accrued_qty,
                division,
                head_office_loc,
                vendor_currency_code,
                due_date,
                frt_bill_pro_ref_nbr,
                spc_inv_code,
                void_date,
                userid,
                contra_reason,
                document_date,
                voucher_nbr,
                gaap_amount_in_cust_curr,
                statement_amount,
               -- gl_transfer,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                batch_id,
                header_id,
                record_type
            ) VALUES (
                TRIM(in_wsc_jti_mfap_header(i).transaction_type),
              --TRIM(in_wsc_jti_mfap_header(i).ledger_name),
                to_date(TRIM(in_wsc_jti_mfap_header(i).transaction_date),'yyyy-mm-dd'),
                TRIM(in_wsc_jti_mfap_header(i).transaction_number),
                TRIM(in_wsc_jti_mfap_header(i).file_name),
                TRIM(in_wsc_jti_mfap_header(i).interface_id),
                TRIM(in_wsc_jti_mfap_header(i).hdr_seq_nbr),
                TRIM(in_wsc_jti_mfap_header(i).continent),
                TRIM(in_wsc_jti_mfap_header(i).invoice_type),
                to_number(TRIM(in_wsc_jti_mfap_header(i).gaap_amount)),
                TRIM(in_wsc_jti_mfap_header(i).fiscal_date),
                TRIM(in_wsc_jti_mfap_header(i).business_unit),
                TRIM(in_wsc_jti_mfap_header(i).location),
                TRIM(in_wsc_jti_mfap_header(i).freight_terms),
                TRIM(in_wsc_jti_mfap_header(i).interfc_desc_t),
                TRIM(in_wsc_jti_mfap_header(i).interfc_desc_loc_lang),
                TRIM(in_wsc_jti_mfap_header(i).purchase_order_nbr),
                TRIM(in_wsc_jti_mfap_header(i).vendor_nbr),
                to_number(TRIM(in_wsc_jti_mfap_header(i).local_inv_total)),
                TRIM(in_wsc_jti_mfap_header(i).refer_invoice),
                to_number(TRIM(in_wsc_jti_mfap_header(i).check_amount)),
                to_date(TRIM(in_wsc_jti_mfap_header(i).check_date),'yyyy-mm-dd'),
                TRIM(in_wsc_jti_mfap_header(i).check_stock),
                TRIM(in_wsc_jti_mfap_header(i).check_payment_type),
                TRIM(in_wsc_jti_mfap_header(i).void_code),
                TRIM(in_wsc_jti_mfap_header(i).cross_border_flag),
                TRIM(in_wsc_jti_mfap_header(i).batch_number),
                TRIM(in_wsc_jti_mfap_header(i).account_currency),
                to_number(TRIM(in_wsc_jti_mfap_header(i).invoice_total)),
                TRIM(in_wsc_jti_mfap_header(i).line_type_header_jti),
                TRIM(in_wsc_jti_mfap_header(i).business_segment),
                TRIM(in_wsc_jti_mfap_header(i).vendor_abbrev),
                to_number(TRIM(in_wsc_jti_mfap_header(i).accrued_qty)),
                TRIM(in_wsc_jti_mfap_header(i).division),
                TRIM(in_wsc_jti_mfap_header(i).head_office_loc),
                TRIM(in_wsc_jti_mfap_header(i).vendor_currency_code),
                to_date(TRIM(in_wsc_jti_mfap_header(i).due_date),'yyyy-mm-dd'),
                TRIM(in_wsc_jti_mfap_header(i).frt_bill_pro_ref_nbr),
                TRIM(in_wsc_jti_mfap_header(i).spc_inv_code),
                to_date(TRIM(in_wsc_jti_mfap_header(i).void_date), 'yyyy-mm-dd'),
                TRIM(in_wsc_jti_mfap_header(i).userid),
                TRIM(in_wsc_jti_mfap_header(i).contra_reason),
                to_date(TRIM(in_wsc_jti_mfap_header(i).document_date),'yyyy-mm-dd'),
                TRIM(in_wsc_jti_mfap_header(i).voucher_nbr),
                to_number(TRIM(in_wsc_jti_mfap_header(i).gaap_amount_in_cust_curr)),
                to_number(TRIM(in_wsc_jti_mfap_header(i).statement_amount)),
                --TRIM(in_wsc_jti_mfap_header(i).gl_transfer),
                TRIM(in_wsc_jti_mfap_header(i).created_by),
                sysdate,
                TRIM(in_wsc_jti_mfap_header(i).last_updated_by),
                sysdate,
                TRIM(in_wsc_jti_mfap_header(i).batch_id),
                TRIM(wsc_mfap_header_t_s1.NEXTVAL),
                TRIM(in_wsc_jti_mfap_header(i).record_type)
            );

    END wsc_jti_mfap_header_p;

    PROCEDURE wsc_jti_mfap_line_p (
        in_wsc_jti_mfap_line IN wsc_jti_mfap_line_t_type_table
    ) AS
    BEGIN
        FORALL i IN 1..in_wsc_jti_mfap_line.count
            INSERT INTO wsc_ahcs_mfap_txn_line_t (
                transaction_number,
                hdr_seq_nbr,
                interface_id,
                gl_amnt_in_foriegn_curr,
                foreign_currency,
                leg_seg_1_4,
                leg_seg_5_7,
                gl_legal_entity,
                gl_oper_grp,
                gl_acct,
                gl_dept,
                gl_site,
                gl_ic,
                gl_projects,
                gl_fut_1,
                gl_fut_2,
                leg_bu,
                leg_loc,
                leg_acct,
                leg_dept,
                leg_affiliate,
                gl_amount_in_loc_curr,
                local_currency,
                db_cr_flag,
                line_seq_number,
                line_type,
                amount_type,
                part_nbr,
                quantity,
                unit_of_measure,
                uom_conv_factor,
                fx_rate,
                product_class,
                unit_cost,
                avg_unit_cost_a,
                ext_cost,
                invoice_nbr,
                statement_id,
                trd_partner_nbr,
                gl_project,
                gl_division,
                leg_vendor,
                po_line_nbr,
                receiver_nbr,
                gaap_f,
                vendor_item_nbr,
                trd_partner_name_jti,
                order_id,
                transaction_type,
                updated_date,
                updated_by,
                gl_allcon_comments,
                matching_date,
                matching_key,
                trans_ref_jti,
                invoice_date,
                check_nbr_jti,
                leg_loc_sr_jti,
                attribute3,
                batch_id,
                header_id,
                line_id,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                record_type
            ) VALUES (
                TRIM(in_wsc_jti_mfap_line(i).transaction_number),
                TRIM(in_wsc_jti_mfap_line(i).hdr_seq_nbr),
                TRIM(in_wsc_jti_mfap_line(i).interface_id),
                to_number(TRIM(in_wsc_jti_mfap_line(i).gl_amnt_in_foriegn_curr)),
                TRIM(in_wsc_jti_mfap_line(i).foreign_currency),
                TRIM(in_wsc_jti_mfap_line(i).leg_seg_1_4),
                TRIM(in_wsc_jti_mfap_line(i).leg_seg_5_7),
                TRIM(in_wsc_jti_mfap_line(i).gl_legal_entity),
                TRIM(in_wsc_jti_mfap_line(i).gl_oper_grp),
                TRIM(in_wsc_jti_mfap_line(i).gl_acct),
                TRIM(in_wsc_jti_mfap_line(i).gl_dept),
                TRIM(in_wsc_jti_mfap_line(i).gl_site),
                TRIM(in_wsc_jti_mfap_line(i).gl_ic),
                TRIM(in_wsc_jti_mfap_line(i).gl_projects),
                TRIM(in_wsc_jti_mfap_line(i).gl_fut_1),
                TRIM(in_wsc_jti_mfap_line(i).gl_fut_2),
                TRIM(in_wsc_jti_mfap_line(i).leg_bu),
                TRIM(in_wsc_jti_mfap_line(i).leg_loc),
                TRIM(in_wsc_jti_mfap_line(i).leg_acct),
                TRIM(in_wsc_jti_mfap_line(i).leg_dept),
                TRIM(in_wsc_jti_mfap_line(i).leg_affiliate),
                to_number(TRIM(in_wsc_jti_mfap_line(i).gl_amount_in_loc_curr)),
                TRIM(in_wsc_jti_mfap_line(i).local_currency),
                TRIM(in_wsc_jti_mfap_line(i).db_cr_flag),
                to_number(TRIM(in_wsc_jti_mfap_line(i).line_seq_number)),
                TRIM(in_wsc_jti_mfap_line(i).line_type),
                TRIM(in_wsc_jti_mfap_line(i).amount_type),
                TRIM(in_wsc_jti_mfap_line(i).part_nbr),
                to_number(TRIM(in_wsc_jti_mfap_line(i).quantity)),
                TRIM(in_wsc_jti_mfap_line(i).unit_of_measure),
                to_number(TRIM(in_wsc_jti_mfap_line(i).uom_conv_factor)),
                to_number(TRIM(in_wsc_jti_mfap_line(i).fx_rate)),
                TRIM(in_wsc_jti_mfap_line(i).product_class),
                to_number(TRIM(in_wsc_jti_mfap_line(i).unit_cost)),
                to_number(TRIM(in_wsc_jti_mfap_line(i).avg_unit_cost_a)),
                to_number(TRIM(in_wsc_jti_mfap_line(i).ext_cost)),
                TRIM(in_wsc_jti_mfap_line(i).invoice_nbr),
                TRIM(in_wsc_jti_mfap_line(i).statement_id),
                TRIM(in_wsc_jti_mfap_line(i).trd_partner_nbr),
                TRIM(in_wsc_jti_mfap_line(i).gl_project),
                TRIM(in_wsc_jti_mfap_line(i).gl_division),
                TRIM(in_wsc_jti_mfap_line(i).leg_vendor),
                TRIM(in_wsc_jti_mfap_line(i).po_line_nbr),
                TRIM(in_wsc_jti_mfap_line(i).receiver_nbr),
                TRIM(in_wsc_jti_mfap_line(i).gaap_f),
                TRIM(in_wsc_jti_mfap_line(i).vendor_item_nbr),
                TRIM(in_wsc_jti_mfap_line(i).trd_partner_name_jti),
                TRIM(in_wsc_jti_mfap_line(i).order_id),
                TRIM(in_wsc_jti_mfap_line(i).transaction_type),
                to_date(TRIM(in_wsc_jti_mfap_line(i).updated_date),'yyyy-mm-dd'),
                TRIM(in_wsc_jti_mfap_line(i).updated_by),
                TRIM(in_wsc_jti_mfap_line(i).gl_allcon_comments),
                to_date(TRIM(in_wsc_jti_mfap_line(i).matching_date),'yyyy-mm-dd'),
                TRIM(in_wsc_jti_mfap_line(i).matching_key),
                TRIM(in_wsc_jti_mfap_line(i).trans_ref_jti),
                to_date(TRIM(in_wsc_jti_mfap_line(i).invoice_date),'yyyy-mm-dd'),
                TRIM(in_wsc_jti_mfap_line(i).check_nbr_jti),
                TRIM(in_wsc_jti_mfap_line(i).leg_loc_sr_jti),
                TRIM(in_wsc_jti_mfap_line(i).attribute3),
                TRIM(in_wsc_jti_mfap_line(i).batch_id),
                TRIM(in_wsc_jti_mfap_line(i).header_id),
                wsc_mfap_line_s1.NEXTVAL,
                TRIM(in_wsc_jti_mfap_line(i).created_by),
                sysdate,
                TRIM(in_wsc_jti_mfap_line(i).last_updated_by),
                sysdate,
                TRIM(in_wsc_jti_mfap_line(i).record_type)
            );

    END wsc_jti_mfap_line_p;

    PROCEDURE wsc_jti_mfap_insert_data_in_gl_status_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2,
        p_error_flag       OUT VARCHAR2
    ) IS
        lv_count NUMBER;
        err_msg  VARCHAR2(2000);
    BEGIN
        logging_insert('JTI MF AP', p_batch_id, 2, 'Updating AP Line table with header id starts', NULL,
                      sysdate);
 --initialise p_error_flag with 0
        BEGIN
            p_error_flag := '0';
        EXCEPTION
            WHEN OTHERS THEN
                logging_insert('MF AP', p_batch_id, 1.1, 'value of error flag', sqlerrm,
                              sysdate);
        END;

        UPDATE wsc_ahcs_mfap_txn_line_t line
        SET
            ( header_id,
              leg_coa,hdr_seq_nbr ) = (
                SELECT  /*+ index(hdr WSC_AHCS_MFAP_TXN_HEADER_HDR_SEQ_NBR_I) */
                    hdr.header_id,
                    leg_coa,hdr.hdr_seq_nbr
                FROM
                    wsc_ahcs_mfap_txn_header_t hdr
                WHERE
                        line.transaction_number = hdr.transaction_number
                    AND line.batch_id = hdr.batch_id
            )
        --and rownum =1)
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        logging_insert('JTI MF AP', p_batch_id, 3, 'Updating MF AP Line table with header id ends', NULL,
                      sysdate);
        logging_insert('JTI MF AP', p_batch_id, 4, 'Inserting records in status table starts', NULL,
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
            attribute2,
            attribute11,
            interface_id,
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
                'VALIDATION_SUCCESS',              
                nvl(line.db_cr_flag,
                    CASE
                        WHEN line.gl_amount_in_loc_curr >= 0 THEN
                            'DR'
                        WHEN line.gl_amount_in_loc_curr < 0  THEN
                            'CR'
                    END
                ),
                line.local_currency,
                line.gl_amount_in_loc_curr,
                line.leg_coa,
                line.hdr_seq_nbr,
                line.line_seq_number,
                line.transaction_number,
                'VALIDATION_SUCCESS',
                hdr.transaction_date,
                line.interface_id,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
                wsc_ahcs_mfap_txn_line_t   line,
                wsc_ahcs_mfap_txn_header_t hdr
            WHERE
                    line.batch_id = p_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id;

        COMMIT;
        logging_insert('JTI MF AP', p_batch_id, 5, 'Inserting records in status table ends', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            p_error_flag := '1';
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('MF AP', p_batch_id, 102, 'Error in WSC_JTI_MFAP_INSERT_DATA_IN_GL_STATUS_P proc', sqlerrm,
                          sysdate);
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT241', 'JTI_MFAP', sqlerrm);
            dbms_output.put_line(sqlerrm);
    END wsc_jti_mfap_insert_data_in_gl_status_p;

    PROCEDURE wsc_jti_mfap_async_process_update_validate_transform_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    ) AS
        err_msg      VARCHAR2(2000);
        p_error_flag VARCHAR2(2);
    BEGIN
        logging_insert('JTI MF AP', p_batch_id, 1, 'Starts ASYNC DB Scheduler', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'VALIDATION_SUCCESS'
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        dbms_scheduler.create_job(job_name => 'INVOKE_WSC_JTI_MFAP_INSERT_DATA_IN_GL_STATUS_P' || p_batch_id, job_type => 'PLSQL_BLOCK',
        job_action => 'DECLARE
                                    p_error_flag VARCHAR2(2);
                                             BEGIN                              
          WSC_MFJTI_PKG.WSC_JTI_MFAP_INSERT_DATA_IN_GL_STATUS_P('
                                                                                                                                       ||
                                                                                                                                       p_batch_id
                                                                                                                                       ||
                                                                                                                                       ','''
                                                                                                                                       ||
                                                                                                                                       p_application_name
                                                                                                                                       ||
                                                                                                                                       ''','''
                                                                                                                                       ||
                                                                                                                                       p_file_name
                                                                                                                                       ||
                                                                                                                                       ''',
                                                p_error_flag
                                                );
        if p_error_flag = '
                                                                                                                                       ||
                                                                                                                                       '''0'''
                                                                                                                                       ||
                                                                                                                                       ' then       
         wsc_ahcs_mfap_validation_transformation_pkg.leg_coa_transformation_JTI_MFAP('
                                                                                                                                       ||
                                                                                                                                       p_batch_id
                                                                                                                                       ||
                                                                                                                                       ');
        end if;                                   
       END;', enabled => true, auto_drop => true,
                                 comments => 'Async steps to update, insert into WSC_AHCS_INT_STATUS_T and call Validate and Transform procedure');
    --dbms_scheduler.run_job (job_name => 'INVOKE_WSC_AP_INSERT_DATA_IN_GL_STATUS_P');

    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('JTI MF AP', p_batch_id, 101, 'Error in Async DB Proc', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            COMMIT;
            dbms_output.put_line(sqlerrm);
    END wsc_jti_mfap_async_process_update_validate_transform_p;

    PROCEDURE wsc_jti_mfar_insert_data_to_hdr (
        p_batch_id          IN NUMBER,
        p_jti_mfar_header_t IN wsc_jti_mfar_hdr_t_type_table
    ) AS
    BEGIN
        FORALL i IN 1..p_jti_mfar_header_t.count
            INSERT INTO wsc_ahcs_mfar_txn_header_t (
                header_id,
                batch_id,
                transaction_date,
                transaction_type,
                transaction_number,
                record_type,
                hdr_seq_nbr,
                interface_id,
                location,
                invoice_nbr,
                invoice_type,
                sale_order_nbr,
                customer_nbr,
                customer_name,
                continent,
                customer_type,
                payment_terms,
                invoice_date,
                invoice_due_date,
                invc_loc_iso_cntry,
                invoice_loc_div,
                ship_to_nbr,
                invoice_currency,
                customer_currency,
                fx_rate_on_invoice,
                ship_type,
                export_type,
                record_error_code,
                credit_type,
                non_ra_credit_type,
                ci_profile_type,
                amount_type,
                amount,
                amount_in_cust_curr,
                business_unit,
                ship_from_location,
                tax_invc_i,
                freight_vendor_nbr,
                freight_invoice_nbr,
                freight_terms,
                freight_invoice_date,
                cash_date,
                cash_batch_nbr,
                cash_code,
                cash_fx_rate,
                cash_check_nbr,
                cash_entry_date,
                cash_lockbox_id,
                gl_div_headqtr_loc,
                gl_div_hq_loc_bu,
                ship_from_loc_bu,
                ps_affiliate_bu,
                emea_flag,
                account_date,
                interface_desc_en,
                interface_desc_frn,
                cust_po,
                cust_credit_pref,
                bank_deposit_date,
                vendor_abbrev_c,
                item_uom_c,
                ib30_reason_c,
                ib30_memo,
                receiver_loc,
                receiver_nbr,
                ra_loc,
                ra_nbr,
                sales_rep,
                freight_bill_nbr,
                final_dest,
                freight_vendor_name,
                fiscal_date,
                matching_key,
                matching_date,
                gaap_amount,
                gaap_amount_in_cust_curr,
                journal_source_c,
                kava_f,
                error_type,
                error_code,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date
            ) VALUES (
                wsc_mfar_header_s1.NEXTVAL,
                p_batch_id,
                to_date(TRIM(p_jti_mfar_header_t(i).transaction_date), 'yyyy-mm-dd'),
                TRIM(p_jti_mfar_header_t(i).transaction_type),
                TRIM(p_jti_mfar_header_t(i).transaction_number),
                TRIM(p_jti_mfar_header_t(i).record_type),
                TRIM(p_jti_mfar_header_t(i).hdr_seq_nbr),
                TRIM(p_jti_mfar_header_t(i).interface_id),
                TRIM(p_jti_mfar_header_t(i).location),
                TRIM(p_jti_mfar_header_t(i).invoice_nbr),
                TRIM(p_jti_mfar_header_t(i).invoice_type),
                TRIM(p_jti_mfar_header_t(i).sale_order_nbr),
                TRIM(p_jti_mfar_header_t(i).customer_nbr),
                TRIM(p_jti_mfar_header_t(i).customer_name),
                TRIM(p_jti_mfar_header_t(i).continent),
                TRIM(p_jti_mfar_header_t(i).customer_type),
                TRIM(p_jti_mfar_header_t(i).payment_terms),
                to_date(TRIM(p_jti_mfar_header_t(i).invoice_date), 'yyyy-mm-dd'),
                to_date(TRIM(p_jti_mfar_header_t(i).invoice_due_date), 'yyyy-mm-dd'),
                TRIM(p_jti_mfar_header_t(i).invc_loc_iso_cntry),
                TRIM(p_jti_mfar_header_t(i).invoice_loc_div),
                TRIM(p_jti_mfar_header_t(i).ship_to_nbr),
                TRIM(p_jti_mfar_header_t(i).invoice_currency),
                TRIM(p_jti_mfar_header_t(i).customer_currency),
                to_number(TRIM(p_jti_mfar_header_t(i).fx_rate_on_invoice)),
                TRIM(p_jti_mfar_header_t(i).ship_type),
                TRIM(p_jti_mfar_header_t(i).export_type),
                TRIM(p_jti_mfar_header_t(i).record_error_code),
                TRIM(p_jti_mfar_header_t(i).credit_type),
                TRIM(p_jti_mfar_header_t(i).non_ra_credit_type),
                TRIM(p_jti_mfar_header_t(i).ci_profile_type),
                TRIM(p_jti_mfar_header_t(i).amount_type),
                to_number(TRIM(p_jti_mfar_header_t(i).amount)),
                to_number(TRIM(p_jti_mfar_header_t(i).amount_in_cust_curr)),
                TRIM(p_jti_mfar_header_t(i).business_unit),
                TRIM(p_jti_mfar_header_t(i).ship_from_location),
                to_number(TRIM(p_jti_mfar_header_t(i).tax_invc_i)),
                TRIM(p_jti_mfar_header_t(i).freight_vendor_nbr),
                TRIM(p_jti_mfar_header_t(i).freight_invoice_nbr),
                TRIM(p_jti_mfar_header_t(i).freight_terms),
                to_date(TRIM(p_jti_mfar_header_t(i).freight_invoice_date), 'yyyy-mm-dd'),
                to_date(TRIM(p_jti_mfar_header_t(i).cash_date), 'yyyy-mm-dd'),
                TRIM(p_jti_mfar_header_t(i).cash_batch_nbr),
                TRIM(p_jti_mfar_header_t(i).cash_code),
                to_number(TRIM(p_jti_mfar_header_t(i).cash_fx_rate)),
                TRIM(p_jti_mfar_header_t(i).cash_check_nbr),
                to_date(TRIM(p_jti_mfar_header_t(i).cash_entry_date), 'yyyy-mm-dd'),
                TRIM(p_jti_mfar_header_t(i).cash_lockbox_id),
                TRIM(p_jti_mfar_header_t(i).gl_div_headqtr_loc),
                TRIM(p_jti_mfar_header_t(i).gl_div_hq_loc_bu),
                TRIM(p_jti_mfar_header_t(i).ship_from_loc_bu),
                TRIM(p_jti_mfar_header_t(i).ps_affiliate_bu),
                TRIM(p_jti_mfar_header_t(i).emea_flag),
                to_date(TRIM(p_jti_mfar_header_t(i).account_date), 'yyyy-mm-dd'),
                TRIM(p_jti_mfar_header_t(i).interface_desc_en),
                TRIM(p_jti_mfar_header_t(i).interface_desc_frn),
                TRIM(p_jti_mfar_header_t(i).cust_po),
                TRIM(p_jti_mfar_header_t(i).cust_credit_pref),
                to_date(TRIM(p_jti_mfar_header_t(i).bank_deposit_date), 'yyyy-mm-dd'),
                TRIM(p_jti_mfar_header_t(i).vendor_abbrev_c),
                TRIM(p_jti_mfar_header_t(i).item_uom_c),
                TRIM(p_jti_mfar_header_t(i).ib30_reason_c),
                TRIM(p_jti_mfar_header_t(i).ib30_memo),
                TRIM(p_jti_mfar_header_t(i).receiver_loc),
                TRIM(p_jti_mfar_header_t(i).receiver_nbr),
                TRIM(p_jti_mfar_header_t(i).ra_loc),
                TRIM(p_jti_mfar_header_t(i).ra_nbr),
                TRIM(p_jti_mfar_header_t(i).sales_rep),
                TRIM(p_jti_mfar_header_t(i).freight_bill_nbr),
                TRIM(p_jti_mfar_header_t(i).final_dest),
                TRIM(p_jti_mfar_header_t(i).freight_vendor_name),
                TRIM(p_jti_mfar_header_t(i).fiscal_date),
                TRIM(p_jti_mfar_header_t(i).matching_key),
                to_date(TRIM(p_jti_mfar_header_t(i).matching_date), 'yyyy-mm-dd'),
                to_number(TRIM(p_jti_mfar_header_t(i).gaap_amount)),
                to_number(TRIM(p_jti_mfar_header_t(i).gaap_amount_in_cust_curr)),
                TRIM(p_jti_mfar_header_t(i).journal_source_c),
                TRIM(p_jti_mfar_header_t(i).kava_f),
                TRIM(p_jti_mfar_header_t(i).error_type),
                TRIM(p_jti_mfar_header_t(i).error_code),
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            );

        COMMIT;
    END wsc_jti_mfar_insert_data_to_hdr;

    PROCEDURE wsc_jti_mfar_insert_data_to_line (
        p_batch_id        IN NUMBER,
        p_jti_mfar_line_t IN wsc_jti_mfar_line_t_type_table
    ) AS
    BEGIN
        FORALL i IN 1..p_jti_mfar_line_t.count
            INSERT INTO wsc_ahcs_mfar_txn_line_t (
                line_id,
                batch_id,
                transaction_number,
                record_type,
                hdr_seq_nbr,
                interface_id,
                leg_location,
                invoice_nbr,
                line_seq_number,
                line_type,
                amount_type,
                amount,
                amount_in_cust_curr,
                line_nbr,
                item_nbr,
                product_class,
                unit_price,
                shipped_quantity,
                mig_sig,
                lrd_ship_from,
                db_cr_flag,
                leg_bu,
                leg_acct,
                leg_dept,
                leg_vendor,
                leg_project,
                leg_loc,
                gl_currency_cd,
                leg_affiliate,
                cash_ar50_comments,
                payment_code,
                uom_c,
                uom_cnvrn_factor,
                po_nbr,
                vendor_stk_nbr,
                billed_qty,
                avg_unit_cost,
                std_unit_cost,
                pc_flag,
                lsi_line_descr,
                invoice_currency,
                customer_currency,
                vendor_abbrev_c,
                vendor_nbr,
                vendor_name,
                gaap_f,
                leg_division,
                error_type,
                error_code,
                leg_coa,
                target_coa,
                gl_legal_entity,
                gl_acct,
                gl_oper_grp,
                gl_dept,
                gl_site,
                gl_ic,
                gl_projects,
                gl_fut_1,
                gl_fut_2,
                invoice_date,
                gl_allcon_comments,
                line_updated_by,
                line_updated_date,
                matching_key,
                matching_date,
                transaction_type,
                order_id,
                customer_name,
                customer_nbr,
                cash_check_nbr,
                fx_rate_on_invoice,
                leg_seg_1_4,
                leg_seg_5_7,
                leg_loc_sr,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date
            ) VALUES (
                wsc_mfar_line_s1.NEXTVAL,
                p_batch_id,
                TRIM(p_jti_mfar_line_t(i).transaction_number),
                TRIM(p_jti_mfar_line_t(i).record_type),
                TRIM(p_jti_mfar_line_t(i).hdr_seq_nbr),
                TRIM(p_jti_mfar_line_t(i).interface_id),
                TRIM(p_jti_mfar_line_t(i).leg_location),
                TRIM(p_jti_mfar_line_t(i).invoice_nbr),
                TRIM(p_jti_mfar_line_t(i).line_seq_number),
                TRIM(p_jti_mfar_line_t(i).line_type),
                TRIM(p_jti_mfar_line_t(i).amount_type),
                to_number(TRIM(p_jti_mfar_line_t(i).amount)),
                to_number(TRIM(p_jti_mfar_line_t(i).amount_in_cust_curr)),
                TRIM(p_jti_mfar_line_t(i).line_nbr),
                TRIM(p_jti_mfar_line_t(i).item_nbr),
                TRIM(p_jti_mfar_line_t(i).product_class),
                to_number(TRIM(p_jti_mfar_line_t(i).unit_price)),
                to_number(TRIM(p_jti_mfar_line_t(i).shipped_quantity)),
                TRIM(p_jti_mfar_line_t(i).mig_sig),
                TRIM(p_jti_mfar_line_t(i).lrd_ship_from),
                TRIM(p_jti_mfar_line_t(i).db_cr_flag),
                TRIM(p_jti_mfar_line_t(i).leg_bu),
                TRIM(p_jti_mfar_line_t(i).leg_acct),
                TRIM(p_jti_mfar_line_t(i).leg_dept),
                TRIM(p_jti_mfar_line_t(i).leg_vendor),
                TRIM(p_jti_mfar_line_t(i).leg_project),
                TRIM(p_jti_mfar_line_t(i).leg_loc),
                TRIM(p_jti_mfar_line_t(i).gl_currency_cd),
                TRIM(p_jti_mfar_line_t(i).leg_affiliate),
                TRIM(p_jti_mfar_line_t(i).cash_ar50_comments),
                TRIM(p_jti_mfar_line_t(i).payment_code),
                TRIM(p_jti_mfar_line_t(i).uom_c),
                to_number(TRIM(p_jti_mfar_line_t(i).uom_cnvrn_factor)),
                TRIM(p_jti_mfar_line_t(i).po_nbr),
                TRIM(p_jti_mfar_line_t(i).vendor_stk_nbr),
                to_number(TRIM(p_jti_mfar_line_t(i).billed_qty)),
                to_number(TRIM(p_jti_mfar_line_t(i).avg_unit_cost)),
                to_number(TRIM(p_jti_mfar_line_t(i).std_unit_cost)),
                TRIM(p_jti_mfar_line_t(i).pc_flag),
                TRIM(p_jti_mfar_line_t(i).lsi_line_descr),
                TRIM(p_jti_mfar_line_t(i).invoice_currency),
                TRIM(p_jti_mfar_line_t(i).customer_currency),
                TRIM(p_jti_mfar_line_t(i).vendor_abbrev_c),
                TRIM(p_jti_mfar_line_t(i).vendor_nbr),
                TRIM(p_jti_mfar_line_t(i).vendor_name),
                TRIM(p_jti_mfar_line_t(i).gaap_f),
                TRIM(p_jti_mfar_line_t(i).leg_division),
                TRIM(p_jti_mfar_line_t(i).error_type),
                TRIM(p_jti_mfar_line_t(i).error_code),
                TRIM(p_jti_mfar_line_t(i).leg_bu)
                || '.'
                || TRIM(p_jti_mfar_line_t(i).leg_loc)
                || '.'
                || TRIM(p_jti_mfar_line_t(i).leg_dept)
                || '.'
                || TRIM(p_jti_mfar_line_t(i).leg_acct)
                || '.'
                || TRIM(p_jti_mfar_line_t(i).leg_vendor)
                || '.'
                || nvl(TRIM(p_jti_mfar_line_t(i).leg_affiliate), '00000'),
                TRIM(p_jti_mfar_line_t(i).gl_legal_entity)
                || '.'
                || TRIM(p_jti_mfar_line_t(i).gl_acct)
                || '.'
                || TRIM(p_jti_mfar_line_t(i).gl_oper_grp)
                || '.'
                || TRIM(p_jti_mfar_line_t(i).gl_dept)
                || '.'
                || TRIM(p_jti_mfar_line_t(i).gl_site)
                || '.'
                || TRIM(p_jti_mfar_line_t(i).gl_ic)
                || '.'
                || TRIM(p_jti_mfar_line_t(i).gl_projects)
                || '.'
                || TRIM(p_jti_mfar_line_t(i).gl_fut_1)
                || '.'
                || TRIM(p_jti_mfar_line_t(i).gl_fut_2),
                TRIM(p_jti_mfar_line_t(i).gl_legal_entity),
                TRIM(p_jti_mfar_line_t(i).gl_acct),
                TRIM(p_jti_mfar_line_t(i).gl_oper_grp),
                TRIM(p_jti_mfar_line_t(i).gl_dept),
                TRIM(p_jti_mfar_line_t(i).gl_site),
                TRIM(p_jti_mfar_line_t(i).gl_ic),
                TRIM(p_jti_mfar_line_t(i).gl_projects),
                TRIM(p_jti_mfar_line_t(i).gl_fut_1),
                TRIM(p_jti_mfar_line_t(i).gl_fut_2),
                to_date(TRIM(p_jti_mfar_line_t(i).invoice_date), 'yyyy-mm-dd'),
                TRIM(p_jti_mfar_line_t(i).gl_allcon_comments),
                TRIM(p_jti_mfar_line_t(i).line_updated_by),
                to_date(TRIM(p_jti_mfar_line_t(i).line_updated_date), 'yyyy-mm-dd'),
                TRIM(p_jti_mfar_line_t(i).matching_key),
                to_date(TRIM(p_jti_mfar_line_t(i).matching_date), 'yyyy-mm-dd'),
                TRIM(p_jti_mfar_line_t(i).transaction_type),
                TRIM(p_jti_mfar_line_t(i).order_id),
                TRIM(p_jti_mfar_line_t(i).customer_name),
                TRIM(p_jti_mfar_line_t(i).customer_nbr),
                TRIM(p_jti_mfar_line_t(i).cash_check_nbr),
                to_number(TRIM(p_jti_mfar_line_t(i).fx_rate_on_invoice)),
                TRIM(p_jti_mfar_line_t(i).leg_seg_1_4),
                TRIM(p_jti_mfar_line_t(i).leg_seg_5_7),
                TRIM(p_jti_mfar_line_t(i).leg_loc_sr),
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            );

        COMMIT;
    END wsc_jti_mfar_insert_data_to_line;

    PROCEDURE wsc_jti_mfar_insert_data_in_gl_status_p (
        p_batch_id         IN NUMBER,
        p_application_name IN VARCHAR2,
        p_file_name        IN VARCHAR2,
        p_error_flag       OUT VARCHAR2
    ) AS
        err_msg VARCHAR2(4000);
    BEGIN
        p_error_flag := '0';
        logging_insert('JTI MF AR', p_batch_id, 2, 'Updating AR Line table with header id starts', NULL,
                      sysdate);
        UPDATE wsc_ahcs_mfar_txn_line_t line
        SET
            ( header_id,hdr_seq_nbr ) = (
                SELECT  /*+ index(hdr WSC_AHCS_MFAR_TXN_HEADER_HDR_SEQ_NBR_I) */
                    hdr.header_id,
                    hdr.hdr_seq_nbr
                FROM
                    wsc_ahcs_mfar_txn_header_t hdr
                WHERE
                        line.transaction_number = hdr.transaction_number
                    AND line.batch_id = hdr.batch_id
            )
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        logging_insert('JTI MF AR', p_batch_id, 3, 'Updating MF AR Line table with header id ends', NULL,
                      sysdate);
        logging_insert('JTI MF AR', p_batch_id, 4, 'Inserting records in status table starts', NULL,
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
            attribute2,
            attribute3,
            attribute11,
            interface_id,
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
                'VALIDATION_SUCCESS',
                nvl(line.db_cr_flag,
                    CASE
                        WHEN line.amount >= 0 THEN
                            'DR'
                        WHEN line.amount < 0  THEN
                            'CR'
                    END
                ),
                line.invoice_currency,
                line.amount,
                line.leg_coa,
                line.hdr_seq_nbr,
                line.line_seq_number,
                'VALIDATION_SUCCESS',
                line.transaction_number,
                hdr.account_date,
                line.interface_id,
                'FIN_INT',
                sysdate,
                'FIN_INT',
                sysdate
            FROM
                wsc_ahcs_mfar_txn_line_t   line,
                wsc_ahcs_mfar_txn_header_t hdr
            WHERE
                    line.batch_id = p_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id;

        COMMIT;
        logging_insert('JTI MF AR', p_batch_id, 5, 'Inserting records in status table ends', NULL,
                      sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            p_error_flag := '1';
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('JTI MF AR', p_batch_id, 200, 'Error While updating Line table with Header ID/inserting data in status table',
            sqlerrm,
                          sysdate);
            wsc_ahcs_int_error_logging.error_logging(p_batch_id, 'INT241_MFAR', 'JTI MF AR', err_msg);
    END wsc_jti_mfar_insert_data_in_gl_status_p;

    PROCEDURE wsc_jti_mfar_async_process_update_validate_transform_p (
        p_batch_id         NUMBER,
        p_application_name VARCHAR2,
        p_file_name        VARCHAR2
    ) AS
        err_msg VARCHAR2(2000);
    BEGIN
        logging_insert('JTI MF AR', p_batch_id, 1, 'Starts ASYNC DB Scheduler', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;

        COMMIT;
        dbms_scheduler.create_job(job_name => 'INVOKE_WSC_JTI_MFAR_INSERT_DATA_IN_GL_STATUS_P' || p_batch_id, job_type => 'PLSQL_BLOCK',
        job_action => '
                                    DECLARE
                                        p_error_flag VARCHAR2(2);
                                    BEGIN
         WSC_MFJTI_PKG.wsc_jti_mfar_insert_data_in_gl_status_p('
                                                                                                                                       ||
                                                                                                                                       p_batch_id
                                                                                                                                       ||
                                                                                                                                       ','''
                                                                                                                                       ||
                                                                                                                                       p_application_name
                                                                                                                                       ||
                                                                                                                                       ''','''
                                                                                                                                       ||
                                                                                                                                       p_file_name
                                                                                                                                       ||
                                                                                                                                       ''',
                                                p_error_flag
                                                );
        if p_error_flag = '
                                                                                                                                       ||
                                                                                                                                       '''0'''
                                                                                                                                       ||
                                                                                                                                       ' then 
         wsc_ahcs_mfar_validation_transformation_pkg.leg_coa_transformation_jti_mfar('
                                                                                                                                       ||
                                                                                                                                       p_batch_id
                                                                                                                                       ||
                                                                                                                                   ');
        end if; 
       END;', enabled => true, auto_drop => true,
                                 comments => 'Async steps to update, insert into WSC_AHCS_INT_STATUS_T and call Validate and Transform procedure');

    EXCEPTION
        WHEN OTHERS THEN
            err_msg := substr(sqlerrm, 1, 200);
            logging_insert('JTI MF AR', p_batch_id, 101, 'Error in Async DB Proc', sqlerrm,
                          sysdate);
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;

            COMMIT;
            dbms_output.put_line(sqlerrm);
    END wsc_jti_mfar_async_process_update_validate_transform_p;

END wsc_mfjti_pkg;
/