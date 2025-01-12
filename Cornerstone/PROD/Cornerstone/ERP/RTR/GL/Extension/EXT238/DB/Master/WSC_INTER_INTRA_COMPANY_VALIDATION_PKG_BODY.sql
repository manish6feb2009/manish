create or replace PACKAGE BODY        WSC_INTER_INTRA_COMPANY_VALIDATION_PKG IS

    
Procedure WSC_GL_IC_DB_INSERT_USERNAME(P_INS_VAL WSC_USER_DATA_ACCESS_T_TAB,
	P_ERR_MSG OUT VARCHAR2,
	P_ERR_CODE OUT VARCHAR2) IS
					 
BEGIN
	FOR i in P_INS_VAL.FIRST..P_INS_VAL.LAST LOOP
		Begin
			insert into WSC_USER_DATA_ACCESS_T (LEDGER_INTER_ORG_NAME,
                LEDGER_INTER_ORG_ID,
                LEGAL_ENTITY_ID,
                ACTIVE_FLAG,
                USERNAME,
                ENTITY_TYPE,
                COMPLETION_DATE)
            values (
                P_INS_VAL(i).LEDGER_INTER_ORG_NAME,
                P_INS_VAL(i).LEDGER_INTER_ORG_ID,
                P_INS_VAL(i).LEGAL_ENTITY_ID,
                P_INS_VAL(i).ACTIVE_FLAG,
                P_INS_VAL(i).USERNAME,
                P_INS_VAL(i).ENTITY_TYPE,
                P_INS_VAL(i).COMPLETION_DATE
            );
        Commit;
		Exception
			WHEN OTHERS THEN
				P_ERR_MSG := P_ERR_MSG ||' . ' ||SQLERRM; 
				P_ERR_CODE := SQLCODE;
		END;       
	END LOOP;

	EXCEPTION
		WHEN OTHERS THEN
			P_ERR_MSG := 'Error while inserting ' ||' . ' || P_ERR_MSG ;
			P_ERR_CODE := 2; 
	END;

	PROCEDURE wsc_gl_ic_validation(p_batch_id IN number) as

        l_clob      varchar2(32767);   
        l_body      varchar2(32767); 
        x_url            VARCHAR2(1000);  
        v_user_name     VARCHAR2(4000) := NULL;   
        l_xml_result clob; 
        l_http_status_code VARCHAR2(2000); 
        x_user_name      VARCHAR2(100);   
        x_password       VARCHAR2(100);   

        CURSOR cur_transaction_currency IS
        SELECT
            TRANSACTION_CURRENCY
        FROM
            wsc_inter_intra_company_file_line_t
        WHERE
                batch_id = P_BATCH_ID
            AND ic_partner_identifier <> 'INTRA'
        group by TRANSACTION_CURRENCY;

        CURSOR cur_ledger_name_intra IS
        SELECT
             ledger_name
        FROM
            wsc_inter_intra_company_file_line_t
        WHERE
                batch_id = P_BATCH_ID
            AND ic_partner_identifier = 'INTRA'
        group by ledger_name;


        cursor cur_exclude_intra_data (P_TRANSACTION_CURRENCY varchar2,P_PROVIDER varchar2) is 
        select ic_partner_identifier, le, abs(sum(nvl(ENTERED_DEBIT,0) - nvl(ENTERED_CREDIT,0)))  sum_data
            from wsc_inter_intra_company_file_line_t
            where TRANSACTION_CURRENCY = P_TRANSACTION_CURRENCY and le = P_PROVIDER and ic_partner_identifier <> 'INTRA' 
            and batch_id = P_BATCH_ID
            group by ic_partner_identifier, le;

        cursor cur_exclude_intra_data_not_provider (P_TRANSACTION_CURRENCY varchar2,P_PROVIDER varchar2, P_IC_PAR_ID VARCHAR2, P_LE VARCHAR2) is
        select ic_partner_identifier, le, abs(sum(nvl(ENTERED_DEBIT,0) - nvl(ENTERED_CREDIT,0)))  sum_data
            from wsc_inter_intra_company_file_line_t
            where TRANSACTION_CURRENCY = P_TRANSACTION_CURRENCY and le <> P_PROVIDER and ic_partner_identifier <> 'INTRA' 
            and batch_id = P_BATCH_ID and ic_partner_identifier = P_LE and le = P_IC_PAR_ID
            group by ic_partner_identifier, le;

        cursor cur_provider is select PROVIDER from wsc_inter_intra_company_file_hdr_t where batch_id = P_BATCH_ID;

        cursor cur_intra_sum_check is select TRANSACTION_CURRENCY, 
            sum(nvl(ENTERED_DEBIT,0) + nvl(ENTERED_CREDIT*(-1),0))  sum_data,
            le, LEDGER_NAME
            from wsc_inter_intra_company_file_line_t
            where batch_id = P_BATCH_ID and ic_partner_identifier = 'INTRA'
            group by LE, TRANSACTION_CURRENCY, LEDGER_NAME;


        cursor cur_insert_inter_data (P_TRANSACTION_CURRENCY varchar2,P_PROVIDER varchar2) is 
            select ic_partner_identifier, le, case 
            when (sum(nvl(ENTERED_DEBIT,0))  - sum(nvl(ENTERED_CREDIT,0))) > 0
            then (sum(nvl(ENTERED_DEBIT,0))  - sum(nvl(ENTERED_CREDIT,0))) 
            else null
            end ENTERED_DEBIT
            ,
            case 
            when (sum(nvl(ENTERED_CREDIT,0))  - sum(nvl(ENTERED_DEBIT,0))) > 0
            then (sum(nvl(ENTERED_CREDIT,0))  - sum(nvl(ENTERED_DEBIT,0)))
            else null
            end ENTERED_CREDIT,
            LEGAL_ENTITY_NAME
            from wsc_inter_intra_company_file_line_t,
            WSC_GL_LEGAL_ENTITIES_T
            where TRANSACTION_CURRENCY = P_TRANSACTION_CURRENCY and le = P_PROVIDER and ic_partner_identifier <> 'INTRA' 
            and batch_id = P_BATCH_ID
            and FLEX_SEGMENT_VALUE = ic_partner_identifier
            group by ic_partner_identifier, le, LEGAL_ENTITY_NAME;

        cursor cur_insert_inter_line_data_le_eq_pro (p_le varchar2,p_ic_partner_identifier varchar2,P_TRANSACTION_CURRENCY varchar2) is
            select * from wsc_inter_intra_company_file_line_t
            where ic_partner_identifier <> 'INTRA' 
            and TRANSACTION_CURRENCY = P_TRANSACTION_CURRENCY
            and le = p_le
            and ic_partner_identifier = p_ic_partner_identifier
            and batch_id = p_batch_id
            and status = 'UA_PASS';

        cursor cur_insert_inter_line_data_le_not_eq_pro (p_le varchar2,p_ic_partner_identifier varchar2,P_TRANSACTION_CURRENCY varchar2) is
            select * from wsc_inter_intra_company_file_line_t
            where ic_partner_identifier <> 'INTRA' 
            and TRANSACTION_CURRENCY = P_TRANSACTION_CURRENCY
            and le = p_ic_partner_identifier
            and ic_partner_identifier = p_le
            and batch_id = p_batch_id
            and status = 'UA_PASS';

        CURSOR cur_qv_fail_c IS
            SELECT
                COUNT(1)
            FROM
                wsc_inter_intra_company_file_line_t
            WHERE
                    batch_id = P_BATCH_ID
                AND status = 'QV_FAIL';

        CURSOR cur_drcr_fail_c IS
            SELECT
                COUNT(1)
            FROM
                wsc_inter_intra_company_file_line_t
            WHERE
                    batch_id = P_BATCH_ID
                AND status = 'DRCR_FAIL';

        CURSOR cur_ua_fail_c IS
            SELECT
                COUNT(1)
            FROM
                wsc_inter_intra_company_file_line_t
            WHERE
                    batch_id = P_BATCH_ID
                AND status = 'UA_FAIL';    

        cursor cur_min_value is 
        select min(FILE_LEVEL_LINE_NUMBER) from WSC_INTER_IC_MAPPING_T where batch_id = p_batch_id;
        min_value number;
        lv_provider varchar2(30);

        lv_ic_partner_identifier varchar2(10) := null;
        lv_le varchar(10) := null;
        lv_sum_data number := 0;

        lv_qv_fail_c number := 0;
        lv_drcr_fail_c number := 0;
        lv_ua_fail_c number := 0;
        error_cur VARCHAR2(10);

        lv_gl_header_id number := 0;
        lv_tran_level_line_h_num number := 0;
        lv_tran_level_line_l_i_num number := 0;
        lv_tran_level_line_l_r_num number := 0;
        lv_tran_level_line_b_num number := 0;

        cursor cur_user_name_data is select USER_NAME from WSC_INTER_INTRA_COMPANY_FILE_HDR_T where batch_id = p_batch_id;
        lv_user_name_data varchar2(50);

        cursor cur_entity_id_data(p_provider NUMBER) is 
        select LEGAL_ENTITY_ID from WSC_GL_LEGAL_ENTITIES_T where FLEX_SEGMENT_VALUE = p_provider;
        lv_entity_id_data varchar2(50);

        cursor cur_hdr_status_data is 
        select status from WSC_INTER_INTRA_COMPANY_FILE_HDR_T where batch_id = p_batch_id;
        lv_hdr_status_data varchar2(50);

        cursor cur_ic_total_count is select count(1) from wsc_inter_ic_mapping_t
        where batch_id = p_batch_id;
        lv_ic_total_count number;

        cursor cur_gl_total_count is select count(1) from wsc_intra_gl_mapping_t
        where batch_id = p_batch_id;
        lv_gl_total_count number;

        CURSOR cur_hdr_data is select ACCOUNTING_DATE, JOURNAL_CATAGORY, CONVERSION_RATE_TYPE
        from WSC_INTER_INTRA_COMPANY_FILE_HDR_T where batch_id = p_batch_id;
        LV_ACCOUNTING_DATE DATE; 
        LV_JOURNAL_CATAGORY VARCHAR2(50 BYTE); 
        LV_CONVERSION_RATE_TYPE VARCHAR2(30 BYTE);
        LV_ERR_MSG_SQLERRM VARCHAR2(1000 BYTE);


        cursor cur_ic_line_total_count is select count(1) from wsc_inter_intra_company_file_line_t
        where batch_id = p_batch_id and IC_PARTNER_IDENTIFIER <> 'INTRA' ;
        lv_ic_line_total_count number;

        CURSOR cur_line_data_count is select count(1) from wsc_inter_intra_company_file_line_t
        where batch_id = p_batch_id;

        line_data_count number;

    BEGIN

        open cur_line_data_count;
        fetch cur_line_data_count into line_data_count;
        close cur_line_data_count ;

        if (line_data_count = 0) then
            line_data_count := 0;
            update wsc_inter_intra_company_file_hdr_t
                set status = 'BV_FAIL',
                ERROR_MESSAGE = 'Empty file detected. Please recheck the file and reupload.' where batch_id = P_BATCH_ID;       
                commit;
        else

        open cur_provider;
        fetch cur_provider into lv_provider;
        close cur_provider;

        UPDATE wsc_inter_intra_company_file_line_t
        SET
            status = 'QV_PASS'
        WHERE
                batch_id = P_BATCH_ID
            AND ic_partner_identifier = 'INTRA';
        COMMIT;

        update wsc_inter_intra_company_file_line_t
        SET
            status = 'QV_PASS'
        WHERE
                batch_id = P_BATCH_ID
                AND ic_partner_identifier <> 'INTRA'
                and ((le = lv_provider
                and ic_partner_identifier <> lv_provider)
                or (le <> lv_provider
                and ic_partner_identifier = lv_provider));
        commit;

        update wsc_inter_intra_company_file_line_t
        SET
            status = 'QV_FAIL',
            error_message = 'Provider mismatch with legal entity or ic partner identifier.'
        WHERE
                batch_id = P_BATCH_ID and
                status is null;
        commit;

        open cur_qv_fail_c;
        fetch cur_qv_fail_c into lv_qv_fail_c;
        close cur_qv_fail_c;

        if( lv_qv_fail_c > 0) then 
            update wsc_inter_intra_company_file_hdr_t
            set status = 'QV_FAIL',
            error_message = 'Provider mismatch with legal entity or ic partner identifier.'
            where batch_id = P_BATCH_ID;            
        else
            update wsc_inter_intra_company_file_line_t line
            SET
                ledger_name = (select ledger_name from wsc_gl_legal_entities_t where flex_segment_value = line.le)
            WHERE
                    batch_id = P_BATCH_ID
                    and ic_partner_identifier = 'INTRA';
            commit;

            for lv_failed_cur IN cur_intra_sum_check
            loop
                if(lv_failed_cur.sum_data = 0) then
                    UPDATE wsc_inter_intra_company_file_line_t
                    SET
                        status = 'DRCR_PASS'
                    WHERE
                        status = 'QV_PASS'
                        AND batch_id = P_BATCH_ID
                        AND ic_partner_identifier = 'INTRA'
                        and TRANSACTION_CURRENCY = lv_failed_cur.TRANSACTION_CURRENCY
                        and le = lv_failed_cur.le
                        and LEDGER_NAME = lv_failed_cur.LEDGER_NAME;
                else
                    UPDATE wsc_inter_intra_company_file_line_t
                    SET
                        status = 'DRCR_FAIL',
                        error_message = 'Debit credit mismatch for the given legal entity, ledger and currency.'
                    WHERE
                        status = 'QV_PASS'
                        AND batch_id = P_BATCH_ID
                        AND ic_partner_identifier = 'INTRA'
                        and TRANSACTION_CURRENCY = lv_failed_cur.TRANSACTION_CURRENCY
                        and le = lv_failed_cur.le
                        and LEDGER_NAME = lv_failed_cur.LEDGER_NAME;
                commit;
                end if;
            end loop;

            begin
                FOR lv_transaction_currency IN cur_transaction_currency
                LOOP
                    FOR lv_inter_data IN cur_exclude_intra_data(lv_transaction_currency.TRANSACTION_CURRENCY,lv_provider)
                    LOOP
                        lv_ic_partner_identifier  := null;
                        lv_le  := null;
                        lv_sum_data  := 0;

                        open cur_exclude_intra_data_not_provider (lv_transaction_currency.TRANSACTION_CURRENCY,lv_provider, lv_inter_data.ic_partner_identifier, lv_inter_data.le);
                        fetch cur_exclude_intra_data_not_provider into lv_ic_partner_identifier, lv_le, lv_sum_data;
                        close cur_exclude_intra_data_not_provider;

                        if(lv_sum_data = lv_inter_data.sum_data) then
                            UPDATE wsc_inter_intra_company_file_line_t
                            SET
                                status = 'DRCR_PASS'
                            WHERE
                                status = 'QV_PASS'
                                AND batch_id = P_BATCH_ID
                                AND ic_partner_identifier <> 'INTRA'
                                AND ((IC_PARTNER_IDENTIFIER = lv_ic_partner_identifier and le = lv_le)
                                or (le = lv_ic_partner_identifier and IC_PARTNER_IDENTIFIER = lv_le))
                                and TRANSACTION_CURRENCY = lv_transaction_currency.TRANSACTION_CURRENCY;
                            COMMIT;
                            else
                                UPDATE wsc_inter_intra_company_file_line_t
                            SET
                                status = 'DRCR_FAIL',
                                error_message = 'Debit credit mismatch for the given legal entity, ledger and currency.'
                            WHERE
                                status = 'QV_PASS'
                                AND batch_id = P_BATCH_ID
                                AND ic_partner_identifier <> 'INTRA'
                                AND ((IC_PARTNER_IDENTIFIER = lv_ic_partner_identifier and le = lv_le)
                                or (le = lv_ic_partner_identifier and IC_PARTNER_IDENTIFIER = lv_le))
                                and TRANSACTION_CURRENCY = lv_transaction_currency.TRANSACTION_CURRENCY;
                                commit;
                        end if;
                    end loop;

                END LOOP;

            end;

            open cur_drcr_fail_c;
            fetch cur_drcr_fail_c into lv_drcr_fail_c;
            close cur_drcr_fail_c;

            if( lv_drcr_fail_c <> 0) then 
                update wsc_inter_intra_company_file_hdr_t
                set status = 'DRCR_FAIL',
                error_message = 'Debit credit mismatch for the given legal entity, ledger and currency.'
                where batch_id = P_BATCH_ID;            
            else
                open cur_user_name_data;
                fetch cur_user_name_data into lv_user_name_data;
                close cur_user_name_data;

                UPDATE wsc_inter_intra_company_file_line_t line
                SET
                    line.status = 'UA_PASS'
                WHERE
                        line.status = 'DRCR_PASS'
                    and line.batch_id = P_BATCH_ID
                    AND line.ic_partner_identifier = 'INTRA'
                    and exists (select 1 from WSC_USER_DATA_ACCESS_T uda
                    where line.LEDGER_NAME = uda.LEDGER_INTER_ORG_NAME
                    and line.status = 'DRCR_PASS'
                    and line.batch_id = P_BATCH_ID
                    AND line.ic_partner_identifier = 'INTRA'
                    and uda.USERNAME = lv_user_name_data);
                COMMIT;

                update wsc_inter_intra_company_file_line_t
                    set status = 'UA_FAIL',ERROR_MESSAGE = 'User Access Validation Failed'
                    where batch_id = P_BATCH_ID
                    and status = 'DRCR_PASS'
                    and ic_partner_identifier = 'INTRA';  
                commit;
 
                open cur_entity_id_data(lv_provider);
                fetch cur_entity_id_data into lv_entity_id_data;
                close cur_entity_id_data;

                UPDATE wsc_inter_intra_company_file_hdr_t hdr
                SET
                    hdr.status = 'UA_PASS'
                WHERE
                    hdr.batch_id = P_BATCH_ID
                    and exists (select 1 from WSC_USER_DATA_ACCESS_T uda
                    where UDA.LEGAL_ENTITY_ID = lv_entity_id_data
                    and hdr.batch_id = P_BATCH_ID
                    and uda.USERNAME = lv_user_name_data
                    AND UDA.ENTITY_TYPE = 'IC_ACCESS');
                commit;

                open cur_hdr_status_data;
                fetch cur_hdr_status_data into lv_hdr_status_data;
                close cur_hdr_status_data;

                if(lv_hdr_status_data = 'UA_PASS') then
                    update wsc_inter_intra_company_file_line_t
                    SET
                        status = 'UA_PASS'
                    WHERE
                        status = 'DRCR_PASS'
                    and batch_id = P_BATCH_ID
                    and ic_partner_identifier <> 'INTRA';
                    commit;
                else
                    update wsc_inter_intra_company_file_line_t
                    SET
                        status = 'UA_FAIL',
                        ERROR_MESSAGE = 'User Access Validation Failed'
                    WHERE
                        status = 'DRCR_PASS'
                    and batch_id = P_BATCH_ID
                    and ic_partner_identifier <> 'INTRA';
                    commit;
                end if;

                open cur_ua_fail_c;
                fetch cur_ua_fail_c into lv_ua_fail_c;
                close cur_ua_fail_c;

                if( lv_ua_fail_c <> 0) then 
                    update wsc_inter_intra_company_file_hdr_t
                    set status = 'UA_FAIL',ERROR_MESSAGE = 'User Access Validation Failed' where batch_id = P_BATCH_ID;            
                else

                FOR lv_ledger_name IN cur_ledger_name_intra
                loop
                    lv_gl_header_id := WSC_INTER_INTRA_COMPANY_HDR_SEQ_S1.nextval;
                    OPEN cur_hdr_data;
                    FETCH cur_hdr_data INTO LV_ACCOUNTING_DATE, LV_JOURNAL_CATAGORY, LV_CONVERSION_RATE_TYPE;
                    CLOSE cur_hdr_data;
                    insert into WSC_INTRA_GL_MAPPING_T(BATCH_ID,
                        LINE_ID,
                        HEADER_ID,
                        GL_LE,
                        GL_OP_GROUP,
                        GL_ACCOUNT,
                        GL_DEPT,
                        GL_SITE,
                        GL_IC,
                        GL_PROJECT,
                        GL_FUTURE1,
                        GL_FUTURE2,
                        ENTERED_DEBIT,
                        ENTERED_CREDIT,
                        ENTERED_CURRENCY,
                        STATUS,
                        ledger_id,
                        ACCOUNTING_DATE,
                        JOURNAL_SOURCE,
                        JOURNAL_CATAGORY,
                        CONVERSION_RATE_TYPE,
                        line_description,
                        ACCOUNTED_DEBIT,
                        ACCOUNTEED_CREDIT)                
                    (select p_batch_id,
                        LINE_ID,
                        lv_gl_header_id, 
                        LE,
                        OP_GROUP,
                        ACCOUNT,
                        DEPT,
                        SITE,
                        IC,
                        PROJECT,
                        FUTURE1,
                        FUTURE2,
                        ENTERED_DEBIT,
                        ENTERED_CREDIT,
                        TRANSACTION_CURRENCY,
                        'NEW',
                        (select ledger_id from wsc_gl_legal_entities_t where flex_segment_value = LE),
                        LV_ACCOUNTING_DATE, 
                        'WSC Intra Spreadsheet',
                        LV_JOURNAL_CATAGORY , 
                        LV_CONVERSION_RATE_TYPE,
                        LINE_DESCRIPTION,
                        ACCOUNTED_DEBIT,
                        ACCOUNTED_CREDIT
                    from wsc_inter_intra_company_file_line_t
                    where IC_PARTNER_IDENTIFIER = 'INTRA'
                    and status = 'UA_PASS'
                    and batch_id = p_batch_id
                    and LEDGER_NAME = lv_ledger_name.LEDGER_NAME);
                    commit;
                end loop;

                open cur_ic_line_total_count;
                fetch cur_ic_line_total_count into lv_ic_line_total_count;
                close cur_ic_line_total_count;

                if(lv_ic_line_total_count > 0 ) then

                insert into WSC_INTER_IC_MAPPING_T (BATCH_ID, FILE_LEVEL_LINE_NUMBER, FILE_LINE_TYPE_CODE, SOURCE_NAME)
                values(p_batch_id,WSC_FILE_LINE_TYPE_CODE_SEQ_S1.nextval,'C','Global Intercompany');
                lv_tran_level_line_b_num := 0;
                FOR lv_transaction_currency IN cur_transaction_currency
                loop
                    lv_tran_level_line_h_num := 0;
                    lv_tran_level_line_b_num := lv_tran_level_line_b_num + 1;
                    insert into WSC_INTER_IC_MAPPING_T	 (
                        BATCH_ID, 
                        PROVIDER_LE,
                        IC_TRX_TYPE,
                        IC_BATCH_DATE,
                        ACCOUNTING_DATE,
                        TRANSACTION_CURRENCY,
                        FILE_LEVEL_LINE_NUMBER, 
                        FILE_LINE_TYPE_CODE, 
                        SOURCE_NAME,
                        CONVERSION_RATE_TYPE
                        )
                    values(
                        p_batch_id,
                        lv_provider, 
                        (select IC_TRANSACTION_TYPE from WSC_INTER_INTRA_COMPANY_FILE_HDR_T where batch_id = p_batch_id), 
                        (select IC_BATCH_DATE from WSC_INTER_INTRA_COMPANY_FILE_HDR_T where batch_id = p_batch_id), 
                        (select ACCOUNTING_DATE from WSC_INTER_INTRA_COMPANY_FILE_HDR_T where batch_id = p_batch_id), 
                        lv_transaction_currency.TRANSACTION_CURRENCY, 
                        WSC_FILE_LINE_TYPE_CODE_SEQ_S1.nextval,
                        'B',
                        'Global Intercompany', 
                        (select CONVERSION_RATE_TYPE from WSC_INTER_INTRA_COMPANY_FILE_HDR_T where batch_id = p_batch_id) 
                    );
                    commit;
                    FOR lv_inter_data IN cur_insert_inter_data(lv_transaction_currency.TRANSACTION_CURRENCY,lv_provider)
                    loop
                        lv_tran_level_line_h_num := lv_tran_level_line_h_num + 1;
                        lv_tran_level_line_l_i_num := 0;
                        lv_tran_level_line_l_r_num := 0;
                        insert into WSC_INTER_IC_MAPPING_T (
                            BATCH_ID, 
                            HEADER_ID,
                            FILE_LEVEL_LINE_NUMBER,
                            FILE_LINE_TYPE_CODE,
                            TRANSACTION_LEVEL_LINE_NUMBER,
                            RECEIVER_LE_NAME,
                            ENTERED_CR,
                            ENTERED_DR,
                            TRANSACTION_CURRENCY
                        )
                        values(
                            p_batch_id,
                            WSC_INTER_INTRA_COMPANY_HDR_IC_SEQ_S1.nextval,
                            WSC_FILE_LINE_TYPE_CODE_SEQ_S1.nextval,
                            'H',
                            lv_tran_level_line_h_num,
                            lv_inter_data.ic_partner_identifier,
                            lv_inter_data.ENTERED_DEBIT ,
                            lv_inter_data.ENTERED_CREDIT, 
                            lv_transaction_currency.TRANSACTION_CURRENCY 
                        );
                        for lv_inter_line_data IN cur_insert_inter_line_data_le_eq_pro(lv_inter_data.le,lv_inter_data.ic_partner_identifier,lv_transaction_currency.TRANSACTION_CURRENCY)
                        loop
                            lv_tran_level_line_l_i_num := lv_tran_level_line_l_i_num+1;
                            insert into WSC_INTER_IC_MAPPING_T(
                                BATCH_ID,
                                LINE_ID,
                                DESCRIPTION,
                                LE,
                                OP_GROUP,
                                ACCOUNT,
                                DEPT,
                                SITE,
                                IC,
                                PROJECT,
                                FUTURE1,
                                FUTURE2,
                                FILE_LEVEL_LINE_NUMBER,
                                FILE_LINE_TYPE_CODE,
                                TRANSACTION_LEVEL_LINE_NUMBER,
                                TRANSACTION__LINE_TYPE_CODE,
                                ENTERED_DR,
                                ENTERED_CR
                            )
                            values(
                                p_batch_id,
                                WSC_INTER_INTRA_COMPANY_LINE_IC_SEQ_S1.nextval, 
                                lv_inter_line_data.LINE_DESCRIPTION,
                                lv_inter_line_data.LE,
                                lv_inter_line_data.OP_GROUP,
                                lv_inter_line_data.ACCOUNT,
                                lv_inter_line_data.DEPT,
                                lv_inter_line_data.SITE,
                                lv_inter_line_data.IC,
                                lv_inter_line_data.PROJECT,
                                lv_inter_line_data.FUTURE1,
                                lv_inter_line_data.FUTURE2,
                                WSC_FILE_LINE_TYPE_CODE_SEQ_S1.nextval,
                                'L',
                                lv_tran_level_line_l_i_num, 
                                'I',
                                lv_inter_line_data.ENTERED_DEBIT,
                                lv_inter_line_data.ENTERED_CREDIT
                            );
                        end loop;
                        for lv_inter_line_data IN cur_insert_inter_line_data_le_not_eq_pro(lv_inter_data.le,lv_inter_data.ic_partner_identifier,lv_transaction_currency.TRANSACTION_CURRENCY)
                        loop
                            lv_tran_level_line_l_r_num := lv_tran_level_line_l_r_num+1;
                            insert into WSC_INTER_IC_MAPPING_T(
                                BATCH_ID,
                                LINE_ID,
                                DESCRIPTION,
                                LE,
                                OP_GROUP,
                                ACCOUNT,
                                DEPT,
                                SITE,
                                IC,
                                PROJECT,
                                FUTURE1,
                                FUTURE2,
                                FILE_LEVEL_LINE_NUMBER,
                                FILE_LINE_TYPE_CODE,
                                TRANSACTION_LEVEL_LINE_NUMBER,
                                TRANSACTION__LINE_TYPE_CODE,
                                ENTERED_DR,
                                ENTERED_CR
                            )
                            values(
                                p_batch_id,
                                WSC_INTER_INTRA_COMPANY_LINE_IC_SEQ_S1.nextval, 
							    lv_inter_line_data.LINE_DESCRIPTION, --- OC-232
                                lv_inter_line_data.LE,
                                lv_inter_line_data.OP_GROUP,
                                lv_inter_line_data.ACCOUNT,
                                lv_inter_line_data.DEPT,
                                lv_inter_line_data.SITE,
                                lv_inter_line_data.IC,
                                lv_inter_line_data.PROJECT,
                                lv_inter_line_data.FUTURE1,
                                lv_inter_line_data.FUTURE2,
                                WSC_FILE_LINE_TYPE_CODE_SEQ_S1.nextval,
                                'L',
                                lv_tran_level_line_l_r_num, 
                                'R',
                                lv_inter_line_data.ENTERED_DEBIT,
                                lv_inter_line_data.ENTERED_CREDIT
                            );
                        end loop;

                    end loop;

                end loop;


                end if;
                open cur_min_value;
                fetch cur_min_value into min_value;
                close cur_min_value;

                update WSC_INTER_IC_MAPPING_T set FILE_LEVEL_LINE_NUMBER = (FILE_LEVEL_LINE_NUMBER - min_value) + 1
                where batch_id = p_batch_id;
                commit;

                BEGIN  
                  SELECT user_name  
                       ,(replace(password, '&', '&amp;')) 
                       , url  
                    INTO x_user_name  
                       , x_password  
                       , x_url  
                    FROM xx_imd_details  
                   WHERE ROWNUM=1;  
                EXCEPTION    
                  WHEN OTHERS  
                    THEN  
                        null;
                END;  

                open cur_gl_total_count;
                fetch cur_gl_total_count into lv_gl_total_count;
                close cur_gl_total_count;

                if(lv_gl_total_count > 0 ) then
                    BEGIN
                        l_body := '{ "batch_ID":"'|| p_batch_id||'" }';    
                        dbms_output.put_line(l_body);   

                        apex_web_service.g_request_headers.delete();   
                        apex_web_service.g_request_headers(1).name := 'Content-Type';   
                        apex_web_service.g_request_headers(1).value := 'application/json';   

                        l_clob := apex_web_service.make_rest_request(   
                            p_url => x_url || ':443/ic/api/integration/v1/flows/rest/WES_AXE_GBL_GL_EXT_DB_TO_ERP_CLO/1.0/trigger/rest',   
                            p_http_method => 'POST',   
                            p_username => x_user_name,   
                            p_password => x_password,   
                            p_body => l_body
                        );   

                        apex_json.parse (l_clob);   

                     EXCEPTION   
                        WHEN OTHERS   
                        THEN   
                            l_xml_result:= NULL;   
                            l_http_status_code := '500'; 
                    END;   
                END IF;

                open cur_ic_total_count;
                fetch cur_ic_total_count into lv_ic_total_count;
                close cur_ic_total_count;

                if(lv_ic_total_count > 1 ) then
                    BEGIN
                        l_body := '{ "batch_ID":"'|| p_batch_id||'" }';   
                        dbms_output.put_line(l_body);   

                        apex_web_service.g_request_headers.delete();   
                        apex_web_service.g_request_headers(1).name := 'Content-Type';   
                        apex_web_service.g_request_headers(1).value := 'application/json';   

                        l_clob := apex_web_service.make_rest_request(   
                            p_url => x_url || ':443/ic/api/integration/v1/flows/rest/WES_AXE_GBL_IC_EXT_DB_TO_ERP_CLO/1.0/trigger/rest',   
                            p_http_method => 'POST',   
                            p_username => x_user_name,   
                            p_password => x_password,   
                            p_body => l_body
                        );   

                        apex_json.parse (l_clob);   

                     EXCEPTION   
                        WHEN OTHERS   
                        THEN   
                            l_xml_result:= NULL;   
                            l_http_status_code := '500'; 
                    END;   
                end if;
                end if;  
            end if; 
        end if; 
    end if;
        EXCEPTION   
            WHEN OTHERS   
            THEN
            LV_ERR_MSG_SQLERRM := SQLERRM;
                update wsc_inter_intra_company_file_hdr_t
                set status = 'QV_FAIL',
                ERROR_MESSAGE = LV_ERR_MSG_SQLERRM where batch_id = P_BATCH_ID;       
                commit;
    end wsc_gl_ic_validation;

end WSC_INTER_INTRA_COMPANY_VALIDATION_PKG;
/