create or replace PACKAGE BODY WSC_MFINV_PKG AS

    /*** WSC_MFINV_INSERT_DATA_TEMP_P PROCEDURE STARTS***/
    PROCEDURE "WSC_MFINV_INSERT_DATA_TEMP_P" (
        in_wsc_mainframeinv_stage IN WSC_MFINV_TMP_T_TYPE_TABLE
    ) AS
    BEGIN
	logging_insert('MF INV', NULL, 1.0, 'MF INV - Temp Table Insertion Started', NULL,SYSDATE);
        FORALL i IN 1..in_wsc_mainframeinv_stage.COUNT
            INSERT INTO WSC_AHCS_MFINV_TXN_TMP_T (
                batch_id,
                rice_id,
                data_string
            ) VALUES (
                in_wsc_mainframeinv_stage(i).batch_id,
                in_wsc_mainframeinv_stage(i).rice_id,
				REPLACE(in_wsc_mainframeinv_stage(i).data_string,'"',' ')
            );
    logging_insert('MF INV', NULL, 1.0, 'MF INV - Temp Table Insertion Started', NULL,SYSDATE);
    END "WSC_MFINV_INSERT_DATA_TEMP_P";
	/*** WSC_MFINV_INSERT_DATA_TEMP_P PROCEDURE COMPLETED***/
	
	 
    /*** WSC_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P PROCEDURE STARTS***/
     PROCEDURE "WSC_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P" (
        p_batch_id          IN  NUMBER,
        p_application_name  IN  VARCHAR2,
        p_file_name         IN  VARCHAR2
    ) AS
        err_msg VARCHAR2(4000);
        p_error_flag varchar2(2);
		
    BEGIN
        logging_insert('MF INV', p_batch_id, 1, 'MF INV - Async DB Scheduler Job Started', NULL,SYSDATE);
		
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'ASYNC DATA PROCESS'
        WHERE
            batch_id = p_batch_id;
        COMMIT;
		
        dbms_scheduler.create_job(job_name => 'INVOKE_WSC_PROCESS_MFINV_TEMP_TO_HEADER_LINE' || p_batch_id,
                                 job_type => 'PLSQL_BLOCK',
                                 job_action => '
                                 DECLARE
                                    p_error_flag VARCHAR2(2);
        BEGIN                                
        WSC_MFINV_PKG.WSC_PROCESS_MFINV_TEMP_TO_HEADER_LINE_P('
                                               || p_batch_id
                                               || ','''
                                               || p_application_name
                                               || ''','''
                                               || p_file_name
                                               || ''',
                                                p_error_flag
                                                );
        if p_error_flag = '||'''0'''||' then                                   
        wsc_ahcs_mfinv_validation_transformation_pkg.data_validation('
                                             || p_batch_id
                                             || ');
        end if;                     
        END;', 
		                        enabled => true,
                                auto_drop => true,
                                comments => 'Async Steps to Split the Data from Temp Table and Insert into Header and Line Tables. Also, Update Line Table, Insert into WSC_AHCS_INT_STATUS_T and Call Validation and Transformation Procedure');
        logging_insert('MF INV', p_batch_id, 10, 'MF INV - Async DB Scheduler Job Completed', NULL, sysdate);
    EXCEPTION
        WHEN OTHERS THEN
        err_msg := substr(sqlerrm, 1, 200);
        logging_insert('MF INV', p_batch_id, 5.1, 'Error in Async DB Proc', sqlerrm,sysdate);
		
            UPDATE wsc_ahcs_int_control_t
            SET
                status = err_msg
            WHERE
                batch_id = p_batch_id;
            COMMIT;
            dbms_output.put_line(sqlerrm);
    END "WSC_ASYNC_PROCESS_UPDATE_VALIDATE_TRANSFORM_P";  
	
	PROCEDURE "WSC_PROCESS_MFINV_TEMP_TO_HEADER_LINE_P" (
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
    lv_business_unit   VARCHAR2(50):=NULL;
	lv_location VARCHAR2(50):=NULL;
	lv_vendor VARCHAR2(50):=NULL;
	l_mfinv_subsystem VARCHAR2(50):=NULL;
	
	CURSOR mfinv_stage_hdr_data_cur (
        p_batch_id NUMBER
    ) IS
    SELECT * FROM
        WSC_AHCS_MFINV_TXN_TMP_T
        WHERE
        batch_id = p_batch_id
        AND TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 1, NULL,1))= 'H';
								   
	CURSOR mfinv_stage_line_data_cur (
        p_batch_id NUMBER
    ) IS
    SELECT * FROM
        WSC_AHCS_MFINV_TXN_TMP_T
        WHERE
        batch_id = p_batch_id
        AND TRIM(regexp_substr(data_string, '([^|]*)(\||$)', 1, 1, NULL,1)) = 'D'; 
		
		
	/*CURSOR mfinv_fetch_stage_hdr_data_cur (p_header_id NUMBER
    ) IS
	SELECT BUSINESS_UNIT,PS_LOCATION,VENDOR_NBR FROM WSC_AHCS_MFINV_TXN_HEADER_T H 
	WHERE H.header_id=p_header_id and h.batch_id=p_batch_id ; */
       			
	TYPE mfinv_stage_hdr_type IS
        TABLE OF mfinv_stage_hdr_data_cur%ROWTYPE;
        lv_mfinv_stg_hdr_type   mfinv_stage_hdr_type;
		
    TYPE mfinv_stage_line_type IS
       TABLE OF mfinv_stage_line_data_cur%ROWTYPE;
       lv_mfinv_stg_line_type  mfinv_stage_line_type; 
	   
BEGIN
	/*Variable Initialization p_error_flag with 0*/
    BEGIN
    p_error_flag := '0';
    EXCEPTION 
    WHEN OTHERS THEN
    logging_insert ('MF INV',p_batch_id,1.1,'value of error flag',SQLERRM,SYSDATE);
    END; 
	
	/*Fetching Source System Name*/
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
	
	/*Extracting RICE_ID/INTERFACE_ID from Temp Table*/
	BEGIN
	SELECT distinct SUBSTR(RICE_ID,8,4) INTO l_mfinv_subsystem FROM wsc_ahcs_mfinv_txn_tmp_t WHERE batch_id=p_batch_id;
	END;
 
    /* For Systems AIIB(AII),IFRT(FII),OFRT(FTI),IBIN(IBI),INTR(ICI),INVT(ISI),SPEC(SPC) */
	IF l_mfinv_subsystem IN ('AIIB','IFRT','OFRT','IBIN','INTR','INVT','SPEC')
	THEN  
	
	/********** PROCESS UNSTRUCTURED TEMP/STAGE TABLE DATA TO HEADER AND LINE TABLES DATA - START *************/
	
	--logging_insert ('MF INV',p_batch_id,2,'TEMP/STAGE TABLE DATA TO HEADER TABLE DATA INSERT - START',NULL,SYSDATE);  
	logging_insert ('MF INV',p_batch_id,2,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Header Table Data Insertion Started',NULL,SYSDATE);  
	
	OPEN mfinv_stage_hdr_data_cur(p_batch_id);
    LOOP
        FETCH mfinv_stage_hdr_data_cur BULK COLLECT INTO lv_mfinv_stg_hdr_type LIMIT 400;
        EXIT WHEN lv_mfinv_stg_hdr_type.COUNT = 0;
        FORALL i IN 1..lv_mfinv_stg_hdr_type.COUNT
			
		INSERT INTO FININT.WSC_AHCS_MFINV_TXN_HEADER_T 
		(
		   BATCH_ID,  ---1  
		   HEADER_ID,  ---2
		   AMOUNT, ---3
		   AMOUNT_IN_CUST_CURR, ---4
		   FX_RATE_ON_INVOICE, ---5
		   TAX_INVC_I, ---6
		   GAAP_AMOUNT, ---7  
		   GAAP_AMOUNT_IN_CUST_CURR, ---8 
		   CASH_FX_RATE, ---9
		   UOM_CONV_FACTOR, ---10 
		   NET_TOTAL, ---11
		   LOC_INV_NET_TOTAL, ---12
		   INVOICE_TOTAL, ---13
		   LOCAL_INV_TOTAL, ---14
		   FX_RATE, ---15
		   CHECK_AMOUNT, ---16
		   ACCRUED_QTY, ---17
		   FISCAL_WEEK_NBR, ---18
		   TOT_LOCAL_AMT, ---19
		   TOT_FOREIGN_AMT, ---20
		   FREIGHT_FACTOR, ---21
		   INVOICE_DATE, ---22
		   INVOICE_DUE_DATE, ---23
		   FREIGHT_INVOICE_DATE, ---24
		   CASH_DATE, ---25
		   CASH_ENTRY_DATE, ---26
		   ACCOUNT_DATE, ---27  
		   BANK_DEPOSIT_DATE, ---28
		   MATCHING_DATE, ---29
		   ADJUSTMENT_DATE, ---30 
		   ACCOUNTING_DATE, ---31 
		   CHECK_DATE, ---32
		   BATCH_DATE, ---33
		   DUE_DATE, ---34
		   VOID_DATE, ---35
		   DOCUMENT_DATE, ---36 
		   RECEIVER_CREATE_DATE, ---37
		   TRANSACTION_DATE, ----38 
		   CONTINENT, ---39  
		   CONT_C, ---40 
		   PO_TYPE, ---41 
		   CHECK_PAYMENT_TYPE, ---42
		   VOID_CODE, ---43
		   CROSS_BORDER_FLAG, ---44
		   BATCH_POSTED_FLAG, ---45
		   INTERFACE_ID, ---46 
		   LOCATION, ---47   
		   INVOICE_TYPE, ---48 
		   CUSTOMER_TYPE, ---49
		   INVOICE_LOC_ISO_CNTRY, ---50
		   INVOICE_LOC_DIV, ---51
		   SHIP_TO_NBR, ---52
		   INVOICE_CURRENCY, ---53 
		   CUSTOMER_CURRENCY, ---54
		   SHIP_TYPE, ---55
		   EXPORT_TYPE, ---56
		   RECORD_ERROR_CODE, ---57
		   CREDIT_TYPE, ---58
		   NON_RA_CREDIT_TYPE, ---59
		   CI_PROFILE_TYPE, ---60
		   AMOUNT_TYPE, ---61
		   CASH_CODE, ---62
		   EMEA_FLAG, ---63
		   CUST_CREDIT_PREF, ---64
		   ITEM_UOM_C, ---65
		   IB30_REASON_C, ---66
		   RECEIVER_LOC, ---67 
		   RA_LOC, ---68
		   FINAL_DEST, ---69
		   JOURNAL_SOURCE_C, ---70
		   KAVA_F, ---71
		   DIVISION, ---72
		   CHECK_STOCK, ---73
		   SALES_LOC, ---74
		   THIRD_PARTY_INTFC_FLAG, ---75
		   VENDOR_PAYMENT_TYPE, ---76
		   VENDOR_CURRENCY_CODE, ---77
		   SPC_INV_CODE, ---78
		   SOURCE_SYSTEM, --- 79 
		   LEG_DIVISION_HDR, --- 80 
		   RECORD_TYPE, ---81 
		   CUSTOMER_NBR, ---82
		   BUSINESS_UNIT, ---83 
		   SHIP_FROM_LOC, ---84
		   FREIGHT_VENDOR_NBR, ---85
		   FREIGHT_INVOICE_NBR, ---86
		   CASH_BATCH_NBR, ---87
		   GL_DIV_HEADQTR_LOC, ---88
		   GL_DIV_HQ_LOC_BU, ---89
		   SHIP_FROM_LOC_BU, ---90
		   PS_AFFILIATE_BU, ---91
		   RECEIVER_NBR, ---92
		   FISCAL_DATE, ---93 
		   VENDOR_NBR, ---94 
		   BATCH_NUMBER, ---95
		   HEAD_OFFICE_LOC, ---96
		   EMPLOYEE_ID, ---97
		   BUSINESS_SEGMENT, ---98
		   UPDATED_USER, ---99
		   USERID, ---100
		   LEG_BU_HDR, --- 101 
		   SALES_ORDER_NBR, ---102
		   CHECK_NBR, ---103
		   VENDOR_ABBREV, ---104 
		   CONCUR_SAE_BATCH_ID, ---105
		   PAYMENT_TERMS, ---106
		   FREIGHT_TERMS, ---107 
		   VENDOR_ABBREV_C, ---108
		   RA_NBR, ---109 
		   SALES_REP, ---110
		   PURCHASE_ORDER_NBR, ---111
		   CATALOG_NBR, ---112  
		   REEL_NBR, ---113 
		   PS_LOCATION, ---114 
		   LOCAL_CURRENCY, ---115 
		   FOREIGN_CURRENCY, ---116 
		   PO_NBR, ---117 
		   PRODUCT_CLASS, ---118 
		   UNIT_OF_MEASURE, ---119 
		   VENDOR_PART_NBR, ---120 
		   RECEIVER_I, ---121 
		   ITEM_I, ---122 
		   TRANS_ID, ---123 
		   INVOICE_I, ---124 
		   RECEIPT_TYPE, ---125
		   COUNTRY_CODE, ---126
		   RA_CUSTOMER_NBR, ---127
		   RA_CUSTOMER_NAME, ---128
		   PURCHASE_CODE, ---129
		   INTERFC_DESC_LOC,---130
		   RECEIVER_NBR_HDR, ---131 
		   PRODUCT_CLASS_HDR, --132 
		   VENDOR_PART_NBR_HDR, --133 
		   GL_TRANSFER, ---134 
		   LEG_TRANS_TYPE, ---135 
		   LEG_LOCATION_HDR, --- 136 
		   INVOICE_NBR, ---137 
		   REFER_INVOICE, ---138
		   VOUCHER_NBR, ---139
		   CASH_CHECK_NBR, ---140
		   FREIGHT_BILL_NBR, ---141
		   FRT_BILL_PRO_REF_NBR, ---142
		   VENDOR_NAME, ---143 
		   PAYMENT_REF_ID, ---144
		   MATCHING_KEY, ---145
		   PAY_FROM_ACCOUNT, ---146
		   INTERFC_DESC_T, ---147
		   INTERFC_DESC_LOC_LANG, ---148
		   HDR_SEQ_NBR, ---149 
		   CUSTOMER_NAME, ---150
		   CASH_LOCKBOX_ID, ---151
		   CUST_PO, ---152
		   FREIGHT_VENDOR_NAME, ---153
		   TRANSACTION_TYPE, --- 154 
		   THIRD_PARTY_INVOICE_ID, ---155
		   CONTRA_REASON, ---156
		   TRANSREF, ---157
		   IB30_MEMO, ---158 
		   TRANSACTION_NUMBER, --- 159 
           LEDGER_NAME,     --- 160  
           FILE_NAME,  --- 161 
		   INTERFACE_DESC_EN, ---162
		   INTERFACE_DESC_FRN, ---163 
		   HEADER_DESC, --- 164 
           HEADER_DESC_LOCAL_LAN, --- 165 
		   CREATION_DATE, ---166
		   LAST_UPDATE_DATE, ---167
		   CREATED_BY, ---168
		   LAST_UPDATED_BY, ---169
		   ATTRIBUTE6, ---170
		   ATTRIBUTE7, ---171
		   ATTRIBUTE8, ---172
		   ATTRIBUTE9, ---173
		   ATTRIBUTE10, ---174
		   ATTRIBUTE11, ---175
		   ATTRIBUTE12, ---176
		   ATTRIBUTE1, ---177
		   ATTRIBUTE2, ---178
		   ATTRIBUTE3, ---179
		   ATTRIBUTE4, ---180
		   ATTRIBUTE5, ---181
		   ACCRUED_QUANTITY_DAI, --- 182
           LEG_DIVISION, --- 183
           TRD_PARTNER_NBR_HDR, --- 184
           TRD_PARTNER_NAME_HDR, --- 185
           INVOCIE_DATE,  --- 186
           HEADER_AMOUNT, --- 187
           LEG_AFFILIATE, --- 188
           UOM_C_HDR, --- 189
           INV_TOTAL, --- 190
           PURCHASE_CODE_HDR, --- 191
           USER_I, --- 192
           REASON_CODE_HDR --- 193
		   ) 
		   VALUES 
		   (
		   p_batch_id,  ---1
		   wsc_mfinv_header_t_s1.NEXTVAL,  ---2
		   TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL, 1))), ---3 
		   TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 29, NULL, 1))), ---4 
		   TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1))), ---5 
		   TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 32, NULL, 1))), ---6
		   TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 70, NULL, 1))), -- 7
		   TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 71, NULL, 1))), -- 8
		   TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 40, NULL, 1))), ---9 
		   NULL, ---10 
		   NULL, ---11 
		   NULL, ---12
		   NULL,---13
		   NULL, ---14 
		   NULL, ---15 
		   NULL, ---16 
		   NULL, ---17
		   NULL, ---18
		   NULL, ---19
		   NULL, ---20 
		   NULL, ---21 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL,1)),'mm/dd/yyyy'), --22 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL,1)),'mm/dd/yyyy'), ---23 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 36, NULL,1)),'mm/dd/yyyy'), ---24 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 37, NULL,1)),'mm/dd/yyyy'), ---25 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 42, NULL,1)),'mm/dd/yyyy'), ---26 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 49, NULL,1)),'mm/dd/yyyy'), ---27 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 54, NULL,1)),'mm/dd/yyyy'), ---28
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 69, NULL,1)),'mm/dd/yyyy'), ---29
		   NULL, ---30 
		   NULL,---31
		   NULL, --32
		   NULL, ---33
		   NULL, ---34
		   NULL, ---35
		   NULL, ---36
		   NULL, ---37 
		   NULL, --- 38
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL, 1)), ---39 
		   NULL, ---40 
		   NULL, --- 41
		   NULL, --- 42
		   NULL, ---43
		   NULL, --44
		   NULL, ---45
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)), --46 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL, 1)),----47
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL, 1)),  --48 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1)), ---49 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1)), ---50 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL, 1)), ---51 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL, 1)), ---52 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1)),  --53 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL, 1)), ---54 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL, 1)), ---55 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1)), ---56 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL, 1)), ---57 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)), ---58 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)), ---59 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1)), ---60 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL, 1)), ---61 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 39, NULL, 1)), ---62
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 48, NULL, 1)), ---63 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 53, NULL, 1)), ---64
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 56, NULL, 1)), ---65 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 57, NULL, 1)), ---66 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 59, NULL, 1)), ---67
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 61, NULL, 1)), ---68
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 65, NULL, 1)), ---69
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 72, NULL, 1)), ---70
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 73, NULL, 1)), ---71
		   NULL, --72
		   NULL, ---73
		   NULL, ---74
		   NULL, ---75
		   NULL, ---76
		   NULL, --- 77
		   NULL, ---78
		   NULL, --- 79
		   NULL, --- 80
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL, 1)), ---81 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL, 1)),---82 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 30, NULL, 1)), ---83 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 31, NULL, 1)), ---84 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 33, NULL, 1)), ---85 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 34, NULL, 1)), ---86 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 38, NULL, 1)), ---87 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 44, NULL, 1)), ---88 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 45, NULL, 1)), ---89 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 46, NULL, 1)), ---90 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 47, NULL, 1)), ---91 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 60, NULL, 1)), --- 92 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 67, NULL, 1)), --- 93
		   NULL, --- 94
		   NULL, ---95
		   NULL, ---96
		   NULL, ---97
		   NULL, ---98
		   NULL, ---99
		   NULL, ---100
		   NULL, --- 101
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL, 1)), ---102 
		   NULL,  --- 103
		   NULL, --104
		   NULL, ---105
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1)), ---106 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL, 1)), ---107  
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL, 1)), ---108 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 62, NULL, 1)), --109 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 63, NULL, 1)), ---110
		   NULL,  --- 111
		   NULL , ---112 
		   NULL ,  ---113 
		   NULL, ---114
		   NULL, ---115
		   NULL, ---116
		   NULL, ---117
		   NULL, ---118 
		   NULL, ---119 
		   NULL, ---120  
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL, 1)), ---121 
		   NULL, ---122   
		   NULL, ---123 
		   NULL, ---124 
		   NULL, ---125 
		   NULL, ---126
		   NULL,  ---127
		   NULL,  ---128
		   NULL,  ---129
		   NULL,  ---130
		   NULL, --- 131
		   NULL, ---132
		   NULL, ---133
		   NULL, ---134 
		   NULL, ---135
		   NULL, ---136
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL, 1)), ---137 
		   NULL, ---138
		   NULL, ---139
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 41, NULL, 1)), ---140 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 64, NULL, 1)), ---141 
		   NULL, ---142
		   NULL, ---143
		   NULL, ---144
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 68, NULL, 1)), ---145
		   NULL, ---146
		   NULL, ---147
		   NULL, --- 148
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)), --149 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL, 1)), ---150 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 43, NULL, 1)), ---151 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 52, NULL, 1)), ---152
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 66, NULL, 1)), ---153 
		   NULL, ---154
		   NULL, ---155
		   NULL, ---156
		   NULL, ---157
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 58, NULL, 1)), ---158
		   CASE 
		   WHEN TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'AIIB'
		   THEN 'AII' || TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1))
		   WHEN TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'IFRT' 
		   THEN 'FII' || TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) 
		   WHEN TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'OFRT'
		   THEN 'FTI' || TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) 
		   WHEN TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'IBIN'
		   THEN 'IBI' || TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) 
		   WHEN TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'INTR'
		   THEN 'ICI' || TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) 
		   WHEN TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'INVT'
		   THEN 'ISI' || TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) 
		   WHEN TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'SPEC'
		   THEN 'SPC' || TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) 
		   --TRANSACTION NUMBER = INTREFACE_ID+HDR_SEQ_NBR ---159 
		   END,
		   NULL, ---160 
		   p_file_name, ---161 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 50, NULL, 1)), --162 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 51, NULL, 1)), --163
		   NULL, --164
		   NULL,--165
		   SYSDATE, ---166
		   SYSDATE, ---167
		   'FIN_INT', ---168
		   'FIN_INT', ---169
		   NULL, ---170
		   NULL, ---171
		   NULL, ---172
		   NULL, ---173
		   NULL, ---174
		   SYSDATE, ---175
		   SYSDATE, ---176
		   NULL, ---177
		   NULL, ---178
		   NULL, ---179
		   NULL, ---180
		   NULL, ---181
		   NULL, ---182
		   NULL, ---183
		   NULL, ---184
		   NULL, ---185
		   NULL, ---186
		   NULL, ---187
		   NULL, ---188
		   NULL, ---189
		   NULL, ---190
		   NULL, ---191
		   NULL,---192
		   NULL--193
		   );
    END LOOP;
	CLOSE mfinv_stage_hdr_data_cur;
    dbms_output.put_line('HEADER exit');
    COMMIT;
    --logging_insert ('MF INV',p_batch_id,3,'STAGE TABLE DATA TO HEADER TABLE DATA INSERT - END',NULL,SYSDATE);
	logging_insert ('MF INV',p_batch_id,3,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Header Table Data Insertion Completed',NULL,SYSDATE); 
   /* EXCEPTION 
   WHEN OTHERS THEN
   Logging_insert ('MF INV',p_batch_id,2.1,'Error while Insert Into Header Table',SQLERRM,SYSDATE);
   END;*/
   
	/********** PROCESS UNSTRUCTURED STAGE TABLE DATA TO LINE TABLE DATA - START *************/
	dbms_output.put_line(' Begin segregration of line data');
    --logging_insert ('MF INV',p_batch_id,4,'STAGE/TEMP TABLE DATA TO LINE TABLE DATA INSERT - START',NULL,SYSDATE);
	logging_insert ('MF INV',p_batch_id,4,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Line Table Data Insertion Started',NULL,SYSDATE); 
	
	OPEN mfinv_stage_line_data_cur(p_batch_id);
    LOOP
    FETCH mfinv_stage_line_data_cur BULK COLLECT INTO lv_mfinv_stg_line_type LIMIT 400;
    EXIT WHEN lv_mfinv_stg_line_type.COUNT = 0;
    FORALL i IN 1..lv_mfinv_stg_line_type.COUNT
   
    INSERT INTO FININT.WSC_AHCS_MFINV_TXN_LINE_T
    (	
    BATCH_ID ,   --- 1
	LINE_ID ,   ---2 
	HEADER_ID ,  ---3 
	LINE_SEQ_NUMBER, ---4
	AMOUNT , ---5   
	AMOUNT_IN_CUST_CURR , ---6 
	UNIT_PRICE , ---7
	SHIPPED_QUANTITY , ---8
	UOM_CNVRN_FACTOR , ---9 
	BILLED_QTY , ---10
	AVG_UNIT_COST , ---11
	STD_UNIT_COST , ---12
	QTY_ON_HAND_BEFORE , ---13 
	ADJUSTMENT_QTY ,  ---14 
	QTY_ON_HAND_AFTER ,  ---15 
	CUR_COST_BEFORE , ---16 
	ADJ_COST_LOCAL , ---17   
	ADJ_COST_FOREIGN , ---18 
	FX_RATE , ---19 
	CUR_COST_AFTER , ---20 
	GL_AMOUNT_IN_LOC_CURR , ---21
	GL_AMNT_IN_FORIEGN_CURR , ---22
	QUANTITY , ---23 
	UOM_CONV_FACTOR , ---24
	UNIT_COST , ---25
	EXT_COST , ---26
	AVG_UNIT_COST_A , ---27 
	AMT_LOCAL_CURR , ---28
	AMT_FOREIGN_CURR , ---29
	RECEIVED_QTY , ---30
	RECEIVED_UNIT_COST , ---31
	PO_UNIT_COST , ---32
	TRANSACTION_AMOUNT , ---33
	FOREIGN_EX_RATE , ---34
	BASE_AMOUNT , ---35
	INVOICE_DATE , ---36
	RECEIPT_DATE , ---37
	LINE_UPDATED_DATE , ---38
	MATCHING_DATE , ---39
	PC_FLAG , ---40
	VENDOR_INDICATOR , ---41 
	CONTINENT, ---42
	DB_CR_FLAG , ---43 
	INTERFACE_ID , ---44 
	LINE_TYPE , ---45
	AMOUNT_TYPE , ---46 
	LINE_NBR , ---47
	LRD_SHIP_FROM , ---48
	UOM_C , ---49 
	INVOICE_CURRENCY , ---50
	CUSTOMER_CURRENCY , ---51
	GAAP_F , ---52 
	GL_DIVISION , ---53
	LOCAL_CURRENCY , ---54 
	FOREIGN_CURRENCY , ---55 
	PO_LINE_NBR , ---56
	LEG_DIVISION , ---57                /*Updated on OCT 21*/
	TRANSACTION_CURR_CD , ---58
	BASE_CURR_CD , ---59
	TRANSACTION_TYPE , ---60
	LOCATION , ---61 
	MIG_SIG , ---62
	BUSINESS_UNIT , ---63
	PAYMENT_CODE , ---64
	VENDOR_NBR , ---65
	RECEIVER_NBR , ---66
	UNIT_OF_MEASURE , ---67
	GL_ACCOUNT , ---68
	GL_DEPT_ID , ---69
	ADJUSTMENT_USER_I , ---70 
	GL_AXE_VENDOR , ---71
	GL_PROJECT , ---72
	GL_AXE_LOC , ---73
	GL_CURRENCY_CD , ---74
	PS_AFFILIATE_BU , ---75
	CASH_AR50_COMMENTS , ---76
	VENDOR_ABBREV_C , ---77 
	QTY_COST_REASON , ---78 
	QTY_COST_REASON_CD , ---79 
	ACCT_DESC , ---80 
	ACCT_NBR , ---81 
	LOC_CODE , ---82 
	DEPT_CODE , ---83 
	GL_LOCATION , ---84 
	GL_VENDOR , ---85
	BUYER_CODE , ---86 
	GL_BUSINESS_UNIT , ---87
	GL_DEPARTMENT ,  ---88
	GL_VENDOR_NBR_FULL , ---89
	AFFILIATE , ---90
	ACCOUNTING_DATE , ---91
	RECEIVER_LINE_NBR , ---92
	VENDOR_PART_NBR , ---93
	ERROR_TYPE , ---94
	ERROR_CODE , ---95
	GL_LEGAL_ENTITY , ---96 
	GL_ACCT , ---97 
	GL_OPER_GRP , ---98 
	GL_DEPT , ---99 
	GL_SITE , ---100 
	GL_IC , ---101 
	GL_PROJECTS , ---102 
	GL_FUT_1 , ---103 
	GL_FUT_2 , ---104 
	SUBLEDGER_NBR , ---105
	BATCH_NBR , ---106
	ORDER_ID , ---107
	INVOICE_NBR , ---108
	PRODUCT_CLASS , ---109
	PART_NBR ,  ---110
	VENDOR_ITEM_NBR , ---111
	PO_NBR , ---112 
	MATCHING_KEY , ---113
	VENDOR_NAME , ---114
	HDR_SEQ_NBR , ---115 
	ITEM_NBR , ---116 
	SUBLEDGER_NAME , ---117
	LINE_UPDATED_BY , ---118
	VENDOR_STK_NBR , ---119
	LSI_LINE_DESCR , ---120
	CREATION_DATE , ---121
	LAST_UPDATE_DATE , ---122
	CREATED_BY , ---123
	LAST_UPDATED_BY , ---124
	LEG_COA , ---125 
	TARGET_COA , ---126 
	STATEMENT_ID , ---127
	GL_ALLCON_COMMENTS , ---128
	ATTRIBUTE6 , ---129
	ATTRIBUTE7 , ---130
	ATTRIBUTE8 , ---131
	ATTRIBUTE9 , ---132
	ATTRIBUTE10 , ---133
	ATTRIBUTE11 , ---134
	ATTRIBUTE12 , ---135
	ATTRIBUTE1 , ---136 
	ATTRIBUTE2 , ---137
	ATTRIBUTE3 , ---138
	ATTRIBUTE4 , ---139
	ATTRIBUTE5 ,---140
	DEFAULT_AMOUNT, --- 141
    ACC_AMOUNT,  --- 142 
    ACC_CURRENCY,  --- 143
    DEFAULT_CURRENCY,  --- 144 
    LEG_LOCATION_LN,  --- 145 
    LEG_ACCT,  --- 146 
    LEG_DEPT,  --- 147
    LOCATION_LN,  --- 148 
    LEG_VENDOR,  --- 149 
    TRD_PARTNER_NAME,  --- 150
    REASON_CODE,  --- 151
    TRANSACTION_NUMBER, --- 152 
    LEG_SEG_1_4,  --- 153 
    LEG_SEG_5_7,  --- 154 
    TRD_PARTNER_NBR, --- 155 
    LEG_ACCT_DESC,  --- 156 
	LEG_BU, --- 157 
    LEG_LOC, --- 158 
    LEG_AFFILIATE, --159
	PS_LOCATION,  ---160 
    AXE_VENDOR,  ---161
    LEG_LOC_SR,  ---162
    PRODUCT_CLASS_LN,  --163
	LEG_BU_LN, --164
    LEG_ACCOUNT, --165
    LEG_DEPARTMENT, --166
    LEG_AFFILIATE_LN, --167
    QUANTITY_DAI, --168
    VENDOR_PART_NBR_LN, --169
    PO_NBR_LN, --170
    LEG_PROJECT, --171
    LEG_DIVISION_LN, --172
	RECORD_TYPE --- 173
	
	)
    VALUES
   (
    p_batch_id,   ---1 
    wsc_mfinv_line_s1.NEXTVAL, ---2 
    NULL,	---3 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL, 1))),	---4 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL, 1))),---5  
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL, 1))), ---6 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1))), ---7
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1))), ---8
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 30, NULL, 1))), ---9
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 33, NULL, 1))),---10
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 34, NULL, 1))),---11
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL, 1))),---12
    NULL,---13 
    NULL,---14 
    NULL,---15 
    NULL,---16 
    NULL,---17
    NULL,---18 
    NULL,---19 
    NULL,---20 
    NULL, --- 21
    NULL, --- 22
    NULL, --- 23
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 30, NULL, 1))),---24 
    NULL, --- 25
    NULL, --- 26
    NULL, --- 27
    NULL,---28 
    NULL,---29 
    NULL,---30 
    NULL,---31 
    NULL,---32 
    NULL,---33
    NULL,---34
    NULL,---35
    NULL, --- 36
    NULL,---37 
    NULL,---38 
    NULL,---39
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 36, NULL, 1)), ---40 
    NULL, ---41
    NULL,
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1)), ---43 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)), ---44 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL, 1)), ---45
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL, 1)), ---46 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1)), ---47
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL, 1)), ---48 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 29, NULL, 1)), ---49
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 38, NULL, 1)), ---50
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 39, NULL, 1)), ---51
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 43, NULL, 1)), ---52 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 44, NULL, 1)), ---53
    NULL, ---54
    NULL, ---55
    NULL, ---56
    NULL, ---57
    NULL, ---58
    NULL, ---59
    NULL, ---60
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL, 1)), ---61 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL, 1)), ---62 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL, 1)), ---63 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL, 1)), ---64
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 41, NULL, 1)), ---65
    NULL, ---66
    NULL, ---67 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1)), ---68
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL, 1)), ---69
    NULL, ---70  
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1)), ---71
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL, 1)), ---72
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)), ---73
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)), ---74
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1)), ---75
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL, 1)), ---76
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 40, NULL, 1)),---77 
    NULL, ---78 
    NULL, ---79 
    NULL, ---80 
    NULL, ---81 
    NULL, ---82 
    NULL, ---83 
    NULL, ---84
    NULL, ---85 
    NULL, ---86 
    NULL, ---87
    NULL, ---88
    NULL, ---89
    NULL, ---90
    NULL, ---91 
    NULL, ---92 
    NULL, ---93 
    NULL, ---94
    NULL, ---95
    NULL, --96  
    NULL, ---97
    NULL, ---98
    NULL, ---99
    NULL, ---100
    NULL, ---101
    NULL, ---102
    NULL, ---103
    NULL, ---104
    NULL, ---105
    NULL, ---106
    NULL, ---107
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL, 1)), ---108
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)), ---109 
    NULL, ---110
    NULL, ---111
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 31, NULL, 1)), ---112
    NULL, ---113
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 42, NULL, 1)), ---114
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)), ---115 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1)), ---116 
    NULL, ---117
    NULL, ---118
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 32, NULL, 1)), ---119
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 37, NULL, 1)), ---120
    SYSDATE,---121
    SYSDATE, ---122
    'FIN_INT',  ---123
    'FIN_INT',  ---124
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL, 1)) 
    || '.'
    || TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1))
    || '.'
    || TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL, 1))
    || '.'
    || TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1))
    || '.'
    || TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1))
    || '.'
    || NVL(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1)),'00000'), --LEG_COA --- LEG_BU-LEG_LOC-LEG_DEPT-LEG_ACCT-LEG_VENDOR-LEG_AFFILIATE,  ---125  
    NULL,  ---126  
    NULL,  ---127
    NULL,  ---128
    NULL,  ---129
    NULL,  ---130
    NULL,  ---131
    NULL,  ---132
    NULL,  ---133
    NULL,  ---134
    NULL,  ---135  
    NULL,  ---136
    NULL,  ---137
    NULL,  ---138
    NULL,  ---139
    NULL,  ---140
    NULL, ---141
    NULL,  ---142
    NULL,  ---143
    NULL,  ---144 
    NULL,  ---145
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1)),  ---146 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL, 1)),  ---147 
    NULL,  ---148
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1)),  ---149 
    NULL,  ---150
    NULL,  ---151
	CASE
	WHEN TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'AIIB'
	THEN 'AII'|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) 
	WHEN TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'IFRT'
	THEN 'FII'|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) 
	WHEN TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'OFRT'
	THEN 'FTI'|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) 
	WHEN TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'IBIN'
	THEN 'IBI'|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) 
	WHEN TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'INTR'
	THEN 'ICI'|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) 
	WHEN TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'INVT'
	THEN 'ISI'|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) 
	WHEN TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'SPEC'
	THEN 'SPC'|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) 
	END, ---152
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL, 1)) 
    || '.'
    || TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1))
    || '.'
    || TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1))
    || '.'
    || TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL, 1)),  ---153 LEG_BU_LN,LEG_LOCATION_LN,LEG_ACCOUNT,LEG_DEPARTMENT
	CASE
	WHEN 
	TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) IN ('AIIB','INVT','INTR')
	THEN
	TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1)) || '.' || NULL
	WHEN
	TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) IN ('IFRT','OFRT','IBIN','SPEC')
	THEN
	TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1)) ||'.'||TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1))
	END, --- 154 --- LEG_SEG_5_7
    NULL,  ---155
    NULL,   ---156
	TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL, 1)), --- 157 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)), --- 158
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1)),  ---159
	NULL,   --160 
	NULL,   --161
	NULL,   -- 162
	NULL,   --163
	NULL,  ---164
    NULL,  ---165
    NULL,  ---166
    NULL,  ---167
    NULL,  ---168
    NULL,  ---169
    NULL,  ---170
    NULL,  ---171
    NULL,  ---172
	TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL, 1)) --- 173
   );
   END LOOP;
   CLOSE mfinv_stage_line_data_cur;
   COMMIT; 

---logging_insert ('MF INV',p_batch_id,5,'STAGE/TEMP TABLE DATA TO LINE TABLE DATA INSERT - END',NULL,SYSDATE);
   logging_insert ('MF INV',p_batch_id,5,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Line Table Data Insertion Completed',NULL,SYSDATE);  

   /*******************FOR SYSTEM COQI(CQI)***********/
   ELSIF l_mfinv_subsystem IN ('COQI') THEN
   
   --logging_insert ('MF INV',p_batch_id,2,'TEMP/STAGE TABLE DATA TO HEADER TABLE DATA INSERT - START',NULL,SYSDATE);  
   logging_insert ('MF INV',p_batch_id,2,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Header Table Data Insertion Started',NULL,SYSDATE); 

OPEN mfinv_stage_hdr_data_cur(p_batch_id);
    LOOP
        FETCH mfinv_stage_hdr_data_cur BULK COLLECT INTO lv_mfinv_stg_hdr_type LIMIT 400;
        EXIT WHEN lv_mfinv_stg_hdr_type.COUNT = 0;
        FORALL i IN 1..lv_mfinv_stg_hdr_type.COUNT
		
		INSERT INTO FININT.WSC_AHCS_MFINV_TXN_HEADER_T 
		(
		   BATCH_ID,  ---1 
		   HEADER_ID,  ---2
		   AMOUNT, ---3
		   AMOUNT_IN_CUST_CURR, ---4
		   FX_RATE_ON_INVOICE, ---5
		   TAX_INVC_I, ---6
		   GAAP_AMOUNT, ---7 
		   GAAP_AMOUNT_IN_CUST_CURR, ---8 
		   CASH_FX_RATE, ---9
		   UOM_CONV_FACTOR, ---10
		   NET_TOTAL, ---11
		   LOC_INV_NET_TOTAL, ---12
		   INVOICE_TOTAL, ---13
		   LOCAL_INV_TOTAL, ---14
		   FX_RATE, ---15
		   CHECK_AMOUNT, ---16
		   ACCRUED_QTY, ---17
		   FISCAL_WEEK_NBR, ---18
		   TOT_LOCAL_AMT, ---19
		   TOT_FOREIGN_AMT, ---20
		   FREIGHT_FACTOR, ---21
		   INVOICE_DATE, ---22
		   INVOICE_DUE_DATE, ---23
		   FREIGHT_INVOICE_DATE, ---24
		   CASH_DATE, ---25
		   CASH_ENTRY_DATE, ---26
		   ACCOUNT_DATE, ---27  
		   BANK_DEPOSIT_DATE, ---28
		   MATCHING_DATE, ---29
		   ADJUSTMENT_DATE, ---30
		   ACCOUNTING_DATE, ---31 
		   CHECK_DATE, ---32
		   BATCH_DATE, ---33
		   DUE_DATE, ---34
		   VOID_DATE, ---35
		   DOCUMENT_DATE, ---36 
		   RECEIVER_CREATE_DATE, ---37
		   TRANSACTION_DATE, ----38 
		   CONTINENT, ---39 
		   CONT_C, ---40 
		   PO_TYPE, ---41 
		   CHECK_PAYMENT_TYPE, ---42
		   VOID_CODE, ---43
		   CROSS_BORDER_FLAG, ---44
		   BATCH_POSTED_FLAG, ---45
		   INTERFACE_ID, ---46 
		   LOCATION, ---47   
		   INVOICE_TYPE, ---48 
		   CUSTOMER_TYPE, ---49
		   INVOICE_LOC_ISO_CNTRY, ---50
		   INVOICE_LOC_DIV, ---51
		   SHIP_TO_NBR, ---52
		   INVOICE_CURRENCY, ---53 
		   CUSTOMER_CURRENCY, ---54
		   SHIP_TYPE, ---55
		   EXPORT_TYPE, ---56
		   RECORD_ERROR_CODE, ---57
		   CREDIT_TYPE, ---58
		   NON_RA_CREDIT_TYPE, ---59
		   CI_PROFILE_TYPE, ---60
		   AMOUNT_TYPE, ---61
		   CASH_CODE, ---62
		   EMEA_FLAG, ---63
		   CUST_CREDIT_PREF, ---64
		   ITEM_UOM_C, ---65
		   IB30_REASON_C, ---66
		   RECEIVER_LOC, ---67 
		   RA_LOC, ---68
		   FINAL_DEST, ---69
		   JOURNAL_SOURCE_C, ---70
		   KAVA_F, ---71
		   DIVISION, ---72 
		   CHECK_STOCK, ---73
		   SALES_LOC, ---74
		   THIRD_PARTY_INTFC_FLAG, ---75
		   VENDOR_PAYMENT_TYPE, ---76
		   VENDOR_CURRENCY_CODE, ---77
		   SPC_INV_CODE, ---78
		   SOURCE_SYSTEM, --- 79
		   LEG_DIVISION_HDR, --- 80 
		   RECORD_TYPE, ---81 
		   CUSTOMER_NBR, ---82
		   BUSINESS_UNIT, ---83 
		   SHIP_FROM_LOC, ---84
		   FREIGHT_VENDOR_NBR, ---85
		   FREIGHT_INVOICE_NBR, ---86
		   CASH_BATCH_NBR, ---87
		   GL_DIV_HEADQTR_LOC, ---88
		   GL_DIV_HQ_LOC_BU, ---89
		   SHIP_FROM_LOC_BU, ---90
		   PS_AFFILIATE_BU, ---91
		   RECEIVER_NBR, ---92
		   FISCAL_DATE, ---93 
		   VENDOR_NBR, ---94 
		   BATCH_NUMBER, ---95
		   HEAD_OFFICE_LOC, ---96
		   EMPLOYEE_ID, ---97
		   BUSINESS_SEGMENT, ---98
		   UPDATED_USER, ---99
		   USERID, ---100
		   LEG_BU_HDR, --- 101 
		   SALES_ORDER_NBR, ---102
		   CHECK_NBR, ---103
		   VENDOR_ABBREV, ---104 
		   CONCUR_SAE_BATCH_ID, ---105
		   PAYMENT_TERMS, ---106
		   FREIGHT_TERMS, ---107 
		   VENDOR_ABBREV_C, ---108
		   RA_NBR, ---109 
		   SALES_REP, ---110
		   PURCHASE_ORDER_NBR, ---111
		   CATALOG_NBR, ---112 
		   REEL_NBR, ---113 
		   PS_LOCATION, ---114 
		   LOCAL_CURRENCY, ---115 
		   FOREIGN_CURRENCY, ---116 
		   PO_NBR, ---117
		   PRODUCT_CLASS, ---118 
		   UNIT_OF_MEASURE, ---119 
		   VENDOR_PART_NBR, ---120 
		   RECEIVER_I, ---121 
		   ITEM_I, ---122 
		   TRANS_ID, ---123 
		   INVOICE_I, ---124 
		   RECEIPT_TYPE, ---125
		   COUNTRY_CODE, ---126
		   RA_CUSTOMER_NBR, ---127
		   RA_CUSTOMER_NAME, ---128
		   PURCHASE_CODE, ---129
		   INTERFC_DESC_LOC,---130
		   RECEIVER_NBR_HDR, ---131 
		   PRODUCT_CLASS_HDR, --132 
		   VENDOR_PART_NBR_HDR, --133 
		   GL_TRANSFER, ---134
		   LEG_TRANS_TYPE, ---135 
		   LEG_LOCATION_HDR, --- 136 
		   INVOICE_NBR, ---137 
		   REFER_INVOICE, ---138
		   VOUCHER_NBR, ---139
		   CASH_CHECK_NBR, ---140
		   FREIGHT_BILL_NBR, ---141
		   FRT_BILL_PRO_REF_NBR, ---142
		   VENDOR_NAME, ---143 
		   PAYMENT_REF_ID, ---144
		   MATCHING_KEY, ---145
		   PAY_FROM_ACCOUNT, ---146
		   INTERFC_DESC_T, ---147
		   INTERFC_DESC_LOC_LANG, ---148
		   HDR_SEQ_NBR, ---149 
		   CUSTOMER_NAME, ---150
		   CASH_LOCKBOX_ID, ---151
		   CUST_PO, ---152
		   FREIGHT_VENDOR_NAME, ---153
		   TRANSACTION_TYPE, --- 154 
		   THIRD_PARTY_INVOICE_ID, ---155
		   CONTRA_REASON, ---156
		   TRANSREF, ---157
		   IB30_MEMO, ---158 
		   TRANSACTION_NUMBER, --- 159
           LEDGER_NAME,     --- 160
           FILE_NAME,  --- 161 
		   INTERFACE_DESC_EN, ---162 
		   INTERFACE_DESC_FRN, ---163 
		   HEADER_DESC, --- 164 
           HEADER_DESC_LOCAL_LAN, --- 165 
		   CREATION_DATE, ---166
		   LAST_UPDATE_DATE, ---167
		   CREATED_BY, ---168
		   LAST_UPDATED_BY, ---169
		   ATTRIBUTE6, ---170
		   ATTRIBUTE7, ---171
		   ATTRIBUTE8, ---172
		   ATTRIBUTE9, ---173
		   ATTRIBUTE10, ---174
		   ATTRIBUTE11, ---175
		   ATTRIBUTE12, ---176
		   ATTRIBUTE1, ---177
		   ATTRIBUTE2, ---178
		   ATTRIBUTE3, ---179
		   ATTRIBUTE4, ---180
		   ATTRIBUTE5, ---181
		   ACCRUED_QUANTITY_DAI, --- 182
           LEG_DIVISION, --- 183
           TRD_PARTNER_NBR_HDR, --- 184
           TRD_PARTNER_NAME_HDR, --- 185
           INVOCIE_DATE,  --- 186
           HEADER_AMOUNT, --- 187
           LEG_AFFILIATE, --- 188
           UOM_C_HDR, --- 189
           INV_TOTAL, --- 190
           PURCHASE_CODE_HDR, --- 191
           USER_I, --- 192
           REASON_CODE_HDR --- 193
		   ) 
		   VALUES 
		   (
		   p_batch_id,  ---1
		   wsc_mfinv_header_t_s1.NEXTVAL,  ---2
		   NULL, ---3
		   NULL, ---4
		   NULL, ---5
		   NULL, ---6
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 31, NULL, 1)), ---7 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 32, NULL, 1)), ---8 
		   NULL, ---9
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)), ---10 
		   NULL, ---11
		   NULL, ---12
		   NULL, ---13
		   NULL, ---14
		   NULL, ---15
		   NULL, ---16
		   NULL, ---17
		   NULL, ---18
		   NULL, ---19
		   NULL, ---20
		   NULL, ---21
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL,1)),'mm/dd/yyyy'), ---22
		   NULL, ---23
		   NULL, ---24
		   NULL, ---25
		   NULL, ---26
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL,1)),'mm/dd/yyyy'), ---27 
		   NULL, ---28
		   NULL, ---29
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1,14,NULL,1)),'mm/dd/yyyy'), ---30 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL,1)),'mm/dd/yyyy'),--31
		   NULL, ---32
		   NULL, ---33
		   NULL, ---34
		   NULL, ---35
		   NULL, ---36
		   NULL, ---37
		   NULL, --- 38
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL, 1)), ---39 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL, 1)), ---40 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1)), ---41 
		   NULL, ---42
		   NULL, ---43
		   NULL, ---44
		   NULL, ---45
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)), ---46
 		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL, 1)), ---47 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL, 1)), ---48 
		   NULL, ---49
		   NULL, ---50
		   NULL, ---51
		   NULL, ---52
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL, 1)),--53
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1)), ---54
		   NULL, ---55
		   NULL, ---56
		   NULL, ---57
		   NULL, ---58
		   NULL, ---59
		   NULL, ---60
		   NULL, ---61
		   NULL, ---62
		   NULL, ---63
		   NULL, ---64
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)), ---65
		   NULL, ---66
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL, 1)), ---67 
		   NULL, ---68
		   NULL, ---69
		   NULL, ---70
		   NULL, ---71
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL, 1)), ---72 
		   NULL, ---73
		   NULL, ---74
		   NULL, ---75
		   NULL, ---76
		   NULL, ---77
		   NULL, ---78
		   SUBSTR(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)),1,3), --- 79 
		   NULL, --- 80
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL, 1)), ---81 
		   NULL, ---82
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL, 1)), ---83 
		   NULL, ---84
		   NULL, ---85
		   NULL, ---86
		   NULL, ---87
		   NULL, ---88
		   NULL, ---89
		   NULL, ---90
		   NULL, ---91
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL, 1)), ---92
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1)), ---93 
           REPLACE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL, 1)),chr(9),''), ---94 
		   NULL, ---95
		   NULL, ---96
		   NULL, ---97
		   NULL, ---98
		   NULL, ---99
		   NULL, ---100
		   NULL, --- 101
		   NULL, ---102
		   NULL, ---103
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL, 1)), ---104 
		   NULL, ---105
		   NULL, ---106
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1)), ---107 
		   NULL, ---108
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1)), ---109 
		   NULL, ---110
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)), ---111
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL, 1)) , ---112 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL, 1)) , ---113 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL, 1)), ---114
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL, 1)), ---115 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1)), ---116 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)), ---117 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL, 1)), ---118 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)), ---119 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1)), ---120 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL, 1)), ---121 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 29, NULL, 1)), ---122 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 30, NULL, 1)), ---123 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL, 1)), ---124 
		   NULL, ---125
		   NULL, ---126
		   NULL, ---127
		   NULL, ---128
		   NULL, ---129
		   NULL, ---130
		   NULL, --- 131
		   NULL, ---132
		   NULL, ---133
		   NULL, ---134 
		   NULL, ---135
		   NULL, ---136
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL, 1)), ---137
		   NULL, ---138
		   NULL, ---139
		   NULL, ---140
		   NULL, ---141
		   NULL, ---142
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1)), ---143
		   NULL, ---144
		   NULL, ---145
		   NULL, ---146
		   NULL, ---147
		   NULL, --- 148
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)),  ---149
		   NULL, ---150
		   NULL, ---151
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)), ---152
		   NULL, ---153
		   NULL, ---154
		   NULL, ---155
		   NULL, ---156
		   NULL, ---157
		   NULL, ---158
		   CASE
		   WHEN TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'COQI'
		   THEN 'CQI' || TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) ---159 TRANSACTION NUMBER = INTREFACE_ID+HDR_SEQ_NBR
		   END,
		   NULL, ---160
		   p_file_name, ---161 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 33, NULL, 1)), --162
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 34, NULL, 1)), --163
		   NULL, --164
		   NULL,--165
		   SYSDATE, ---166
		   SYSDATE, ---167
		   'FIN_INT', ---168
		   'FIN_INT', ---169
		   NULL, ---170
		   NULL, ---171
		   NULL, ---172
		   NULL, ---173
		   NULL, ---174
		   SYSDATE, ---175
		   SYSDATE, ---176
		   NULL, ---177
		   NULL, ---178
		   NULL, ---179
		   NULL, ---180
		   NULL, ---181
		   NULL, ---182
		   NULL, ---183
		   NULL, ---184
		   NULL, ---185
		   NULL, ---186
		   NULL, ---187
		   NULL, ---188
		   NULL, ---189
		   NULL, ---190
		   NULL, ---191
		   NULL,---192
		   NULL--193
		   );
    END LOOP;
	CLOSE mfinv_stage_hdr_data_cur;
    dbms_output.put_line('HEADER Exit');
    COMMIT;
   ---logging_insert ('MF INV',p_batch_id,3,'STAGE/TEMP TABLE DATA TO HEADER TABLE DATA - END',NULL,SYSDATE);
   logging_insert ('MF INV',p_batch_id,3,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Header Table Data Insertion Completed',NULL,SYSDATE); 
   /*EXCEPTION 
   WHEN OTHERS THEN
   Logging_insert ('MF INV',p_batch_id,2.1,'value of error flag',SQLERRM,SYSDATE);
   END;*/
   
	/********** PROCESS UNSTRUCTURED STAGE TABLE DATA TO LINE TABLE DATA - START *************/
    dbms_output.put_line(' Begin segregration of line data');
	
	/*BEGIN
	  OPEN mfinv_fetch_stage_hdr_data_cur(wsc_mfinv_header_t_s1.CURRVAL);
	  FETCH mfinv_fetch_stage_hdr_data_cur  INTO lv_business_unit,lv_location,lv_vendor;
	  CLOSE mfinv_fetch_stage_hdr_data_cur;
	END;*/
	
	---logging_insert ('MF INV',p_batch_id,4,'STAGE/TEMP TABLE DATA TO LINE TABLE DATA - START',NULL,SYSDATE);
	logging_insert ('MF INV',p_batch_id,4,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Line Table Data Insertion Started',NULL,SYSDATE);  
	
	OPEN mfinv_stage_line_data_cur(p_batch_id);
    LOOP
    FETCH mfinv_stage_line_data_cur BULK COLLECT INTO lv_mfinv_stg_line_type LIMIT 400;
    EXIT WHEN lv_mfinv_stg_line_type.COUNT = 0;
    FORALL i IN 1..lv_mfinv_stg_line_type.COUNT
   
    INSERT INTO FININT.WSC_AHCS_MFINV_TXN_LINE_T
    (	
    BATCH_ID ,   --- 1 
	LINE_ID ,   ---2   
	HEADER_ID ,  ---3  
	LINE_SEQ_NUMBER, ---4 
	AMOUNT , ---5   
	AMOUNT_IN_CUST_CURR , ---6 
	UNIT_PRICE , ---7
	SHIPPED_QUANTITY , ---8
	UOM_CNVRN_FACTOR , ---9 
	BILLED_QTY , ---10
	AVG_UNIT_COST , ---11
	STD_UNIT_COST , ---12
	QTY_ON_HAND_BEFORE , ---13 
	ADJUSTMENT_QTY ,  ---14 
	QTY_ON_HAND_AFTER ,  ---15 
	CUR_COST_BEFORE , ---16 
	ADJ_COST_LOCAL , ---17 
	ADJ_COST_FOREIGN , ---18 
	FX_RATE , ---19 
	CUR_COST_AFTER , ---20
	GL_AMOUNT_IN_LOC_CURR , ---21
	GL_AMNT_IN_FORIEGN_CURR , ---22
	QUANTITY , ---23 
	UOM_CONV_FACTOR , ---24
	UNIT_COST , ---25
	EXT_COST , ---26
	AVG_UNIT_COST_A , ---27 
	AMT_LOCAL_CURR , ---28
	AMT_FOREIGN_CURR , ---29
	RECEIVED_QTY , ---30
	RECEIVED_UNIT_COST , ---31
	PO_UNIT_COST , ---32
	TRANSACTION_AMOUNT , ---33
	FOREIGN_EX_RATE , ---34
	BASE_AMOUNT , ---35
	INVOICE_DATE , ---36
	RECEIPT_DATE , ---37
	LINE_UPDATED_DATE , ---38
	MATCHING_DATE , ---39
	PC_FLAG , ---40
	VENDOR_INDICATOR , ---41
	CONTINENT, ---42
	DB_CR_FLAG , ---43 
	INTERFACE_ID , ---44
	LINE_TYPE , ---45
	AMOUNT_TYPE , ---46 
	LINE_NBR , ---47
	LRD_SHIP_FROM , ---48
	UOM_C , ---49 
	INVOICE_CURRENCY , ---50
	CUSTOMER_CURRENCY , ---51
	GAAP_F , ---52 
	GL_DIVISION , ---53
	LOCAL_CURRENCY , ---54 
	FOREIGN_CURRENCY , ---55 
	PO_LINE_NBR , ---56
	LEG_DIVISION , ---57
	TRANSACTION_CURR_CD , ---58
	BASE_CURR_CD , ---59
	TRANSACTION_TYPE , ---60
	LOCATION , ---61 
	MIG_SIG , ---62
	BUSINESS_UNIT , ---63
	PAYMENT_CODE , ---64
	VENDOR_NBR , ---65
	RECEIVER_NBR , ---66 
	UNIT_OF_MEASURE , ---67
	GL_ACCOUNT , ---68
	GL_DEPT_ID , ---69
	ADJUSTMENT_USER_I , ---70 
	GL_AXE_VENDOR , ---71
	GL_PROJECT , ---72
	GL_AXE_LOC , ---73
	GL_CURRENCY_CD , ---74
	PS_AFFILIATE_BU , ---75
	CASH_AR50_COMMENTS , ---76
	VENDOR_ABBREV_C , ---77 
	QTY_COST_REASON , ---78 
	QTY_COST_REASON_CD , ---79 
	ACCT_DESC , ---80 
	ACCT_NBR , ---81 
	LOC_CODE , ---82 
	DEPT_CODE , ---83 
	GL_LOCATION , ---84 
	GL_VENDOR , ---85
	BUYER_CODE , ---86 
	GL_BUSINESS_UNIT , ---87
	GL_DEPARTMENT ,  ---88
	GL_VENDOR_NBR_FULL , ---89
	AFFILIATE , ---90
	ACCOUNTING_DATE , ---91
	RECEIVER_LINE_NBR , ---92
	VENDOR_PART_NBR , ---93
	ERROR_TYPE , ---94
	ERROR_CODE , ---95
	GL_LEGAL_ENTITY , ---96 
	GL_ACCT , ---97 
	GL_OPER_GRP , ---98 
	GL_DEPT , ---99 
	GL_SITE , ---100 
	GL_IC , ---101 
	GL_PROJECTS , ---102 
	GL_FUT_1 , ---103 
	GL_FUT_2 , ---104 
	SUBLEDGER_NBR , ---105
	BATCH_NBR , ---106
	ORDER_ID , ---107
	INVOICE_NBR , ---108
	PRODUCT_CLASS , ---109
	PART_NBR ,  ---110
	VENDOR_ITEM_NBR , ---111
	PO_NBR , ---112 
	MATCHING_KEY , ---113
	VENDOR_NAME , ---114
	HDR_SEQ_NBR , ---115  
	ITEM_NBR , ---116 
	SUBLEDGER_NAME , ---117
	LINE_UPDATED_BY , ---118
	VENDOR_STK_NBR , ---119
	LSI_LINE_DESCR , ---120
	CREATION_DATE , ---121
	LAST_UPDATE_DATE , ---122
	CREATED_BY , ---123
	LAST_UPDATED_BY , ---124
	LEG_COA , ---125
	TARGET_COA , ---126 
	STATEMENT_ID , ---127
	GL_ALLCON_COMMENTS , ---128
	ATTRIBUTE6 , ---129
	ATTRIBUTE7 , ---130
	ATTRIBUTE8 , ---131
	ATTRIBUTE9 , ---132
	ATTRIBUTE10 , ---133
	ATTRIBUTE11 , ---134
	ATTRIBUTE12 , ---135
	ATTRIBUTE1 , ---136 
	ATTRIBUTE2 , ---137
	ATTRIBUTE3 , ---138
	ATTRIBUTE4 , ---139
	ATTRIBUTE5 ,---140
	DEFAULT_AMOUNT, --- 141
    ACC_AMOUNT,  --- 142 
    ACC_CURRENCY,  --- 143 
    DEFAULT_CURRENCY,  --- 144
    LEG_LOCATION_LN,  --- 145 
    LEG_ACCT,  --- 146
    LEG_DEPT,  --- 147 
    LOCATION_LN,  --- 148 
    LEG_VENDOR,  --- 149 
    TRD_PARTNER_NAME,  --- 150 
    REASON_CODE,  --- 151 
    TRANSACTION_NUMBER, --- 152 
    LEG_SEG_1_4,  --- 153 
    LEG_SEG_5_7,  --- 154 
    TRD_PARTNER_NBR, --- 155 
    LEG_ACCT_DESC,  --- 156 
	LEG_BU, --- 157 
    LEG_LOC, --- 158 
    LEG_AFFILIATE, --159
	PS_LOCATION,  ---160 
    AXE_VENDOR,  ---161
    LEG_LOC_SR,  ---162
    PRODUCT_CLASS_LN,  --163
	LEG_BU_LN, --164
    LEG_ACCOUNT, --165
    LEG_DEPARTMENT, --166
    LEG_AFFILIATE_LN, --167
    QUANTITY_DAI, --168
    VENDOR_PART_NBR_LN, --169
    PO_NBR_LN, --170
    LEG_PROJECT, --171
    LEG_DIVISION_LN, --172
	RECORD_TYPE
	)
    VALUES
   (
    p_batch_id,   ---1 
    wsc_mfinv_line_s1.NEXTVAL,	---2 
    NULL,	---3 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL, 1))),	---4
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1))),	---5 --Defect Fix -CTPFS-12705-Oct-21
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1))),  ---6
    NULL, ---7
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL, 1))), ---8
    NULL, ---9
    NULL,---10
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1))),---11
    NULL,---12
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL, 1)))	,---13 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL, 1)))	,---14 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL, 1))),---15 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL, 1)))	,---16
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1)))	,---17
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1))),---18 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)))	,---19 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1)))	,---20 
    NULL,---21
    NULL,---22
    NULL,---23
    NULL,---24
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1))),---25
    NULL,---26
    NULL,---27
    NULL,---28
    NULL,---29
    NULL,---30
    NULL,---31
    NULL,---32
    NULL,---33
    NULL,---34
    NULL,---35
    NULL,---36
    NULL,---37
    NULL,---38
    NULL,---39
    NULL, ---40
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL, 1)), ---41 
    NULL, ---42
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL, 1)), ---43 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)), ---44
    NULL, ---45
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL, 1)), ---46 
    NULL, ---47
    NULL, ---48
    NULL, ---49
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL, 1)), ---50
     TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)), ---51
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL, 1)), ---52 
    NULL, ---53
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL, 1)), ---54 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)), ---55 
    NULL, ---56
    NULL, ---57
    NULL, ---58
    NULL, ---59
    NULL, ---60
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)), ---61 
    NULL, ---62
    NULL,---lv_business_unit, ---63 
    NULL, ---64
    NULL, ---65
    NULL, ---66
    NULL, ---67
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1)), ---68
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1)), ---69
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1)), ---70  
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1)), ---71 removed 00000000 on 2/20
    NULL, ---72
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)), ---73
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL, 1)), ---74
    NULL, ---75
    NULL, ---76
    NULL,---77 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1))	, ---78
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL, 1)), ---79 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL, 1)), ---80 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1)), ---81 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL, 1)), ---82 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1)), ---83 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)), ---84 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1)), ---85 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL, 1)), ---86 
    NULL, ---87
    NULL, ---88
    NULL, ---89
    NULL, ---90
    NULL, ---91
    NULL, ---92
    NULL, ---93
    NULL, ---94
    NULL, ---95
    NULL,  --96  
    NULL, ---97
    NULL, ---98
    NULL, ---99
    NULL, ---100
    NULL, ---101
    NULL, ---102
    NULL, ---103
    NULL, ---104
    NULL, ---105
    NULL, ---106
    NULL, ---107
    NULL, ---108
    NULL, ---109
    NULL, ---110
    NULL, ---111
    NULL, ---112
    NULL, ---113
    NULL, ---114
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)), ---115 
    NULL, ---116
    NULL, ---117
    NULL, ---118
    NULL, ---119
    NULL, ---120
    SYSDATE,---121
    SYSDATE, ---122
    'FIN_INT',  ---123
    'FIN_INT',  ---124
   -- lv_business_unit 
    --|| '.'
    --|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1))
    --|| '.'
    --|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1))
    --|| '.'
    --|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1))
    --|| '.'
    --|| NVL(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1)),'00000000')
    --|| '.'
    --|| nvl(NULL,'00000')
	NULL,  ---125  --- LEG_COA --- LEG_BU-LEG_LOC-LEG_DEPT-LEG_ACCT-LEG_VENDOR-LEG_AFFILIATE
    NULL,  ---126  
    NULL,  ---127
    NULL,  ---128
    NULL,  ---129
    NULL,  ---130
    NULL,  ---131
    NULL,  ---132
    NULL,  ---133
    NULL,  ---134
    NULL,  ---135  
    NULL,  ---136
    NULL,  ---137
    NULL,  ---138
    NULL,  ---139
    NULL,  ---140,
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL, 1))), ---141 
    NULL,  ---142
    NULL,  ---143
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)),  ---144 
    NULL,  ---145
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1)),  ---146 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1)),  ---147 
    NULL,  ---148
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1)),  ---149 removed 00000000 on 2/20
    NULL,  ---150
    NULL,  ---151
	CASE
    WHEN TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'COQI'
	THEN 'CQI'|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1))   ---152 
	END,
   -- lv_business_unit        
    --|| '.'
    ---|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1))
    --|| '.'
    --|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1))
    ---|| '.'
    --|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1))
	NULL,  ---153 --- LEG_SEG_1_4 --- LEG_BU_HDR(LEG_BU),LEG_LOCATION_LN(LEG_LOC),LEG_ACCOUNT(LEG_ACCT),LEG_DEPARTMENT(LEG_DEPT)
    '00000'|| '.' ||TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1)), ---154 --LEG_SEG_5_7--Vendor-Affiliate
    NULL,  ---155
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL, 1)),   ---156
	NULL,---lv_business_unit,---157
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)), ---158
    '00000',    ---159
	TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)),   --160 
	NULL,   --161
	NULL,   -- 162
	NULL,    --163
	NULL,  ---164
    NULL,  ---165
    NULL,  ---166
    NULL,  ---167
    NULL,  ---168
    NULL,  ---169
    NULL,  ---170
    NULL,  ---171
    NULL,  ---172,
	TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL, 1))
   );
  END LOOP;
  CLOSE mfinv_stage_line_data_cur;
  COMMIT;
 -- logging_insert ('MF INV',p_batch_id,5,'STAGE TABLE DATA TO LINE TABLE DATA INSERT - END',NULL,SYSDATE);
 logging_insert ('MF INV',p_batch_id,5,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Line Table Data Insertion Completed',NULL,SYSDATE);  

  
  /*** For System DAIN ***/

   ELSIF l_mfinv_subsystem IN ('DAIN') THEN

    ---logging_insert ('MF INV',p_batch_id,2,'STAGE/TEMP TABLE DATA TO HEADER TABLE DATA INSERT - START',NULL,SYSDATE);
    logging_insert ('MF INV',p_batch_id,2,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Header Table Data Insertion Started',NULL,SYSDATE);  

   OPEN mfinv_stage_hdr_data_cur(p_batch_id);
    LOOP
        FETCH mfinv_stage_hdr_data_cur BULK COLLECT INTO lv_mfinv_stg_hdr_type LIMIT 400;
        EXIT WHEN lv_mfinv_stg_hdr_type.COUNT = 0;
        FORALL i IN 1..lv_mfinv_stg_hdr_type.COUNT
		
		INSERT INTO FININT.WSC_AHCS_MFINV_TXN_HEADER_T 
		(
		   BATCH_ID,  ---1  
		   HEADER_ID,  ---2
		   AMOUNT, ---3
		   AMOUNT_IN_CUST_CURR, ---4
		   FX_RATE_ON_INVOICE, ---5
		   TAX_INVC_I, ---6
		   GAAP_AMOUNT, ---7  
		   GAAP_AMOUNT_IN_CUST_CURR, ---8 
		   CASH_FX_RATE, ---9
		   UOM_CONV_FACTOR, ---10 
		   NET_TOTAL, ---11
		   LOC_INV_NET_TOTAL, ---12
		   INVOICE_TOTAL, ---13
		   LOCAL_INV_TOTAL, ---14
		   FX_RATE, ---15
		   CHECK_AMOUNT, ---16
		   ACCRUED_QTY, ---17
		   FISCAL_WEEK_NBR, ---18
		   TOT_LOCAL_AMT, ---19
		   TOT_FOREIGN_AMT, ---20
		   FREIGHT_FACTOR, ---21
		   INVOICE_DATE, ---22
		   INVOICE_DUE_DATE, ---23
		   FREIGHT_INVOICE_DATE, ---24
		   CASH_DATE, ---25
		   CASH_ENTRY_DATE, ---26
		   ACCOUNT_DATE, ---27  
		   BANK_DEPOSIT_DATE, ---28
		   MATCHING_DATE, ---29
		   ADJUSTMENT_DATE, ---30 
		   ACCOUNTING_DATE, ---31 
		   CHECK_DATE, ---32
		   BATCH_DATE, ---33
		   DUE_DATE, ---34
		   VOID_DATE, ---35
		   DOCUMENT_DATE, ---36 
		   RECEIVER_CREATE_DATE, ---37
		   TRANSACTION_DATE, ----38 
		   CONTINENT, ---39  
		   CONT_C, ---40 
		   PO_TYPE, ---41 
		   CHECK_PAYMENT_TYPE, ---42
		   VOID_CODE, ---43
		   CROSS_BORDER_FLAG, ---44
		   BATCH_POSTED_FLAG, ---45
		   INTERFACE_ID, ---46 
		   LOCATION, ---47   
		   INVOICE_TYPE, ---48 
		   CUSTOMER_TYPE, ---49
		   INVOICE_LOC_ISO_CNTRY, ---50
		   INVOICE_LOC_DIV, ---51
		   SHIP_TO_NBR, ---52
		   INVOICE_CURRENCY, ---53 
		   CUSTOMER_CURRENCY, ---54
		   SHIP_TYPE, ---55
		   EXPORT_TYPE, ---56
		   RECORD_ERROR_CODE, ---57
		   CREDIT_TYPE, ---58
		   NON_RA_CREDIT_TYPE, ---59
		   CI_PROFILE_TYPE, ---60
		   AMOUNT_TYPE, ---61
		   CASH_CODE, ---62
		   EMEA_FLAG, ---63
		   CUST_CREDIT_PREF, ---64
		   ITEM_UOM_C, ---65
		   IB30_REASON_C, ---66
		   RECEIVER_LOC, ---67 
		   RA_LOC, ---68
		   FINAL_DEST, ---69
		   JOURNAL_SOURCE_C, ---70
		   KAVA_F, ---71
		   DIVISION, ---72
		   CHECK_STOCK, ---73
		   SALES_LOC, ---74
		   THIRD_PARTY_INTFC_FLAG, ---75
		   VENDOR_PAYMENT_TYPE, ---76
		   VENDOR_CURRENCY_CODE, ---77
		   SPC_INV_CODE, ---78
		   SOURCE_SYSTEM, --- 79 
		   LEG_DIVISION_HDR, --- 80 
		   RECORD_TYPE, ---81 
		   CUSTOMER_NBR, ---82
		   BUSINESS_UNIT, ---83 
		   SHIP_FROM_LOC, ---84
		   FREIGHT_VENDOR_NBR, ---85
		   FREIGHT_INVOICE_NBR, ---86
		   CASH_BATCH_NBR, ---87
		   GL_DIV_HEADQTR_LOC, ---88
		   GL_DIV_HQ_LOC_BU, ---89
		   SHIP_FROM_LOC_BU, ---90
		   PS_AFFILIATE_BU, ---91
		   RECEIVER_NBR, ---92
		   FISCAL_DATE, ---93 
		   VENDOR_NBR, ---94 
		   BATCH_NUMBER, ---95
		   HEAD_OFFICE_LOC, ---96
		   EMPLOYEE_ID, ---97
		   BUSINESS_SEGMENT, ---98
		   UPDATED_USER, ---99
		   USERID, ---100
		   LEG_BU_HDR, --- 101 
		   SALES_ORDER_NBR, ---102
		   CHECK_NBR, ---103
		   VENDOR_ABBREV, ---104 
		   CONCUR_SAE_BATCH_ID, ---105
		   PAYMENT_TERMS, ---106
		   FREIGHT_TERMS, ---107 
		   VENDOR_ABBREV_C, ---108
		   RA_NBR, ---109 
		   SALES_REP, ---110
		   PURCHASE_ORDER_NBR, ---111
		   CATALOG_NBR, ---112  
		   REEL_NBR, ---113 
		   PS_LOCATION, ---114 
		   LOCAL_CURRENCY, ---115 
		   FOREIGN_CURRENCY, ---116 
		   PO_NBR, ---117 --- CQI
		   PRODUCT_CLASS, ---118 
		   UNIT_OF_MEASURE, ---119 
		   VENDOR_PART_NBR, ---120 
		   RECEIVER_I, ---121 
		   ITEM_I, ---122 
		   TRANS_ID, ---123 
		   INVOICE_I, ---124 
		   RECEIPT_TYPE, ---125
		   COUNTRY_CODE, ---126
		   RA_CUSTOMER_NBR, ---127
		   RA_CUSTOMER_NAME, ---128
		   PURCHASE_CODE, ---129
		   INTERFC_DESC_LOC,---130
		   RECEIVER_NBR_HDR, ---131 
		   PRODUCT_CLASS_HDR, --132 
		   VENDOR_PART_NBR_HDR, --133 
		   GL_TRANSFER, ---134 
		   LEG_TRANS_TYPE, ---135 
		   LEG_LOCATION_HDR, --- 136 
		   INVOICE_NBR, ---137 
		   REFER_INVOICE, ---138
		   VOUCHER_NBR, ---139
		   CASH_CHECK_NBR, ---140
		   FREIGHT_BILL_NBR, ---141
		   FRT_BILL_PRO_REF_NBR, ---142
		   VENDOR_NAME, ---143 
		   PAYMENT_REF_ID, ---144
		   MATCHING_KEY, ---145
		   PAY_FROM_ACCOUNT, ---146
		   INTERFC_DESC_T, ---147
		   INTERFC_DESC_LOC_LANG, ---148
		   HDR_SEQ_NBR, ---149 
		   CUSTOMER_NAME, ---150
		   CASH_LOCKBOX_ID, ---151
		   CUST_PO, ---152
		   FREIGHT_VENDOR_NAME, ---153
		   TRANSACTION_TYPE, --- 154 
		   THIRD_PARTY_INVOICE_ID, ---155
		   CONTRA_REASON, ---156
		   TRANSREF, ---157
		   IB30_MEMO, ---158 
		   TRANSACTION_NUMBER, --- 159 
           LEDGER_NAME,     --- 160  
           FILE_NAME,  --- 161 
		   INTERFACE_DESC_EN, ---162
		   INTERFACE_DESC_FRN, ---163 
		   HEADER_DESC, --- 164 
           HEADER_DESC_LOCAL_LAN, --- 165 
		   CREATION_DATE, ---166
		   LAST_UPDATE_DATE, ---167
		   CREATED_BY, ---168
		   LAST_UPDATED_BY, ---169
		   ATTRIBUTE6, ---170
		   ATTRIBUTE7, ---171
		   ATTRIBUTE8, ---172
		   ATTRIBUTE9, ---173
		   ATTRIBUTE10, ---174
		   ATTRIBUTE11, ---175
		   ATTRIBUTE12, ---176
		   ATTRIBUTE1, ---177
		   ATTRIBUTE2, ---178
		   ATTRIBUTE3, ---179
		   ATTRIBUTE4, ---180
		   ATTRIBUTE5, ---181
		   ACCRUED_QUANTITY_DAI, --- 182
           LEG_DIVISION, --- 183
           TRD_PARTNER_NBR_HDR, --- 184
           TRD_PARTNER_NAME_HDR, --- 185
           INVOCIE_DATE,  --- 186
           HEADER_AMOUNT, --- 187
           LEG_AFFILIATE, --- 188
           UOM_C_HDR, --- 189
           INV_TOTAL, --- 190
           PURCHASE_CODE_HDR, --- 191
           USER_I, --- 192
           REASON_CODE_HDR --- 193
		   )
		   VALUES 
		   (
		   p_batch_id,  ---1
		   wsc_mfinv_header_t_s1.NEXTVAL,  ---2
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1)), ---3
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)), ---4
		   NULL, ---5
		   NULL, ---6
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 62, NULL, 1)), ---7 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 63, NULL, 1)), ---8 
		   NULL, ---9
		   NULL, ---10 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1)), ---11 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1)), ---12 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)), ---13 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1)), ---14 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL, 1)), ---15 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL, 1)), ---16 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL, 1)), ---17 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 61, NULL, 1)), ---18 
		   NULL, ---19
		   NULL, ---20
		   NULL, ---21
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1,6,NULL,1)),'mm/dd/yyyy'), ---22 
		   NULL, ---23
		   NULL, ---24
		   NULL, ---25
		   NULL, ---26
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 41, NULL,1)),'mm/dd/yyyy'), ---27  
		   NULL, ---28
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 41, NULL,1)),'mm/dd/yyyy'), ---29
		   NULL, ---30 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 41, NULL,1)),'mm/dd/yyyy'),--31 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL,1)),'mm/dd/yyyy'), ---32 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 29, NULL,1)),'mm/dd/yyyy'), ---33 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 29, NULL,1)),'mm/dd/yyyy'), ---34 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 49, NULL,1)),'mm/dd/yyyy'), ---35 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL,1)),'mm/dd/yyyy'), ---36
		   NULL, ---37
		   NULL, --- 38
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL, 1)), ---39 
		   NULL, ---40 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL, 1)), ---41
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)), ---42 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1)), ---43 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL, 1)), ---44 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 30, NULL, 1)), ---45 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)), --46 
 		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL, 1)), ---47 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1)), ---48 
		   NULL, ---49 
		   NULL, ---50
		   NULL, ---51
		   NULL, ---52
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 38, NULL, 1)),--53
		   NULL, ---54
		   NULL, ---55
		   NULL, ---56
		   NULL, ---57
		   NULL, ---58
		   NULL, ---59
		   NULL, ---60
		   NULL, ---61
		   NULL, ---62
		   NULL, ---63
		   NULL, ---64
		   NULL, ---65
		   NULL, ---66
		   NULL, ---67
		   NULL, ---68
		   NULL, ---69
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 64, NULL, 1)), ---70
		   NULL, ---71
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL, 1)), ---72 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL, 1)), ---73 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 36, NULL, 1)), ---74 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 33, NULL, 1)), ---75 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)), ---76 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 38, NULL, 1)), ---77 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 48, NULL, 1)), ---78 
		   NULL, --- 79
		   NULL, --- 80
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL, 1)), ---81
		   NULL, ---82
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL, 1)), ---83 
		   NULL, ---84
		   NULL, ---85
		   NULL, ---86
		   NULL, ---87
		   NULL, ---88
		   NULL, ---89
		   NULL, ---90
		   NULL, ---91
		   NULL, ---92
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 59, NULL, 1)), ---93 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL, 1)), ---94 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL, 1)), ---95 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL, 1)), ---96
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 39, NULL, 1)), ---97
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 42, NULL, 1)), ---98 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 52, NULL, 1)), ---99 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 53, NULL, 1)), ---100
		   NULL, --- 101
		   NULL, ---102
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1)), ---103 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 46, NULL, 1)), ---104 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 60, NULL, 1)), ---105 
		   NULL, ---106
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 57, NULL, 1)), ---107 
		   NULL, ---108
		   NULL, ---109 
		   NULL, ---110
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL, 1)), ---111 
		   NULL , ---112 
		   NULL ,  ---113 
		   NULL, ---114
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 38, NULL, 1)), ---115 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 38, NULL, 1)), ---116 
		   NULL, ---117 
		   NULL, ---118 
		   NULL, ---119 
		   NULL, ---120  
		   NULL, ---121 
		   NULL, ---122   
		   NULL, ---123 
		   NULL, ---124 
		   NULL, ---125
		   NULL, ---126
		   NULL, ---127
		   NULL, ---128
		   NULL, ---129
		   NULL, ---130
		   NULL, --- 131
		   NULL, ---132
		   NULL, ---133
		   NULL, ---134 
		   NULL, ---135
		   NULL, ---136
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL, 1)), ---137 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1)), ---138 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 58, NULL, 1)), ---139 
		   NULL, ---140
		   NULL, ---141
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 47, NULL, 1)), ---142
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 40, NULL, 1)), ---143 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 34, 15, NULL, 1)), ---144
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 50, 15, NULL, 1)), ---145 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 31, NULL, 1)), ---146
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 43, NULL, 1)), ---147
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 44, NULL, 1)), --- 148
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)), --149 
		   NULL, ---150
		   NULL, ---151
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL, 1)), ---152
		   NULL, ---153
		   NULL, ---154
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 37, NULL, 1)), ---155 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 54, NULL, 1)), ---156 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 32, NULL, 1)), ---157 
		   NULL, ---158
		   CASE
           WHEN TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'DAIN'
		   THEN 'DAI' || TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) 
           END,  ---159 TRANSACTION NUMBER = INTREFACE_ID+HDR_SEQ_NBR, ---159 
		   NULL, ---160 
		   p_file_name, ---161 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 43, NULL, 1)), --162
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 44, NULL, 1)), --163
		   NULL, --164
		   NULL,--165
		   SYSDATE, ---166
		   SYSDATE, ---167
		   'FIN_INT', ---168
		   'FIN_INT', ---169
		   NULL, ---170
		   NULL, ---171
		   NULL, ---172
		   NULL, ---173
		   NULL, ---174
		   SYSDATE, ---175
		   SYSDATE, ---176
		   NULL, ---177
		   NULL, ---178
		   NULL, ---179
		   NULL, ---180
		   NULL, ---181
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 55, NULL, 1)), ---182
		   NULL, ---183
		   NULL, ---184
		   NULL, ---185
		   NULL, ---186
		   NULL, ---187
		   NULL, ---188
		   NULL, ---189
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)), ---190
		   NULL, ---191
		   NULL,---192
		   NULL--193
		   
		   );
    END LOOP;
	CLOSE mfinv_stage_hdr_data_cur;
    dbms_output.put_line('HEADER exit');
    COMMIT;
   --- logging_insert ('MF INV',p_batch_id,3,'STAGE/TEMP TABLE DATA TO HEADER TABLE DATA - END',NULL,SYSDATE);
   logging_insert ('MF INV',p_batch_id,3,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Header Table Data Insertion Completed',NULL,SYSDATE);  
  /* EXCEPTION 
   WHEN OTHERS THEN
   Logging_insert ('MF INV',p_batch_id,2.1,'value of error flag',SQLERRM,SYSDATE);
   END;*/
   
	/********** PROCESS UNSTRUCTURED STAGE TABLE DATA TO LINE TABLE DATA - START *************/
    dbms_output.put_line(' Begin segregration of line data');
  ---  logging_insert ('MF INV',p_batch_id,4,'STAGE/TEMP TABLE DATA TO LINE TABLE DATA - START',NULL,SYSDATE);
   logging_insert ('MF INV',p_batch_id,4,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Line Table Data Insertion Started',NULL,SYSDATE);  
	
	OPEN mfinv_stage_line_data_cur(p_batch_id);
    LOOP
    FETCH mfinv_stage_line_data_cur BULK COLLECT INTO lv_mfinv_stg_line_type LIMIT 400;
    EXIT WHEN lv_mfinv_stg_line_type.COUNT = 0;
    FORALL i IN 1..lv_mfinv_stg_line_type.COUNT
   
    INSERT INTO FININT.WSC_AHCS_MFINV_TXN_LINE_T
    (	
    BATCH_ID ,   --- 1
	LINE_ID ,   ---2 
	HEADER_ID ,  ---3 
	LINE_SEQ_NUMBER, ---4
	AMOUNT , ---5   
	AMOUNT_IN_CUST_CURR , ---6 
	UNIT_PRICE , ---7
	SHIPPED_QUANTITY , ---8
	UOM_CNVRN_FACTOR , ---9 
	BILLED_QTY , ---10
	AVG_UNIT_COST , ---11
	STD_UNIT_COST , ---12
	QTY_ON_HAND_BEFORE , ---13 
	ADJUSTMENT_QTY ,  ---14 
	QTY_ON_HAND_AFTER ,  ---15 
	CUR_COST_BEFORE , ---16 
	ADJ_COST_LOCAL , ---17   
	ADJ_COST_FOREIGN , ---18 
	FX_RATE , ---19 
	CUR_COST_AFTER , ---20 
	GL_AMOUNT_IN_LOC_CURR , ---21
	GL_AMNT_IN_FORIEGN_CURR , ---22
	QUANTITY , ---23 
	UOM_CONV_FACTOR , ---24
	UNIT_COST , ---25
	EXT_COST , ---26
	AVG_UNIT_COST_A , ---27 
	AMT_LOCAL_CURR , ---28
	AMT_FOREIGN_CURR , ---29
	RECEIVED_QTY , ---30
	RECEIVED_UNIT_COST , ---31
	PO_UNIT_COST , ---32
	TRANSACTION_AMOUNT , ---33
	FOREIGN_EX_RATE , ---34
	BASE_AMOUNT , ---35
	INVOICE_DATE , ---36
	RECEIPT_DATE , ---37
	LINE_UPDATED_DATE , ---38
	MATCHING_DATE , ---39
	PC_FLAG , ---40
	VENDOR_INDICATOR , ---41 
	CONTINENT, ---42
	DB_CR_FLAG , ---43 
	INTERFACE_ID , ---44 
	LINE_TYPE , ---45
	AMOUNT_TYPE , ---46 
	LINE_NBR , ---47
	LRD_SHIP_FROM , ---48
	UOM_C , ---49 
	INVOICE_CURRENCY , ---50
	CUSTOMER_CURRENCY , ---51
	GAAP_F , ---52 
	GL_DIVISION , ---53
	LOCAL_CURRENCY , ---54 
	FOREIGN_CURRENCY , ---55 
	PO_LINE_NBR , ---56
	LEG_DIVISION , ---57
	TRANSACTION_CURR_CD , ---58
	BASE_CURR_CD , ---59
	TRANSACTION_TYPE , ---60
	LOCATION , ---61 
	MIG_SIG , ---62
	BUSINESS_UNIT , ---63
	PAYMENT_CODE , ---64
	VENDOR_NBR , ---65
	RECEIVER_NBR , ---66
	UNIT_OF_MEASURE , ---67
	GL_ACCOUNT , ---68
	GL_DEPT_ID , ---69
	ADJUSTMENT_USER_I , ---70 
	GL_AXE_VENDOR , ---71
	GL_PROJECT , ---72
	GL_AXE_LOC , ---73
	GL_CURRENCY_CD , ---74
	PS_AFFILIATE_BU , ---75
	CASH_AR50_COMMENTS , ---76
	VENDOR_ABBREV_C , ---77 
	QTY_COST_REASON , ---78 
	QTY_COST_REASON_CD , ---79 
	ACCT_DESC , ---80 
	ACCT_NBR , ---81 
	LOC_CODE , ---82 
	DEPT_CODE , ---83 
	GL_LOCATION , ---84 
	GL_VENDOR , ---85
	BUYER_CODE , ---86 
	GL_BUSINESS_UNIT , ---87
	GL_DEPARTMENT ,  ---88
	GL_VENDOR_NBR_FULL , ---89
	AFFILIATE , ---90
	ACCOUNTING_DATE , ---91
	RECEIVER_LINE_NBR , ---92
	VENDOR_PART_NBR , ---93
	ERROR_TYPE , ---94
	ERROR_CODE , ---95
	GL_LEGAL_ENTITY , ---96 
	GL_ACCT , ---97 
	GL_OPER_GRP , ---98 
	GL_DEPT , ---99 
	GL_SITE , ---100 
	GL_IC , ---101 
	GL_PROJECTS , ---102 
	GL_FUT_1 , ---103 
	GL_FUT_2 , ---104 
	SUBLEDGER_NBR , ---105
	BATCH_NBR , ---106
	ORDER_ID , ---107
	INVOICE_NBR , ---108
	PRODUCT_CLASS , ---109
	PART_NBR ,  ---110
	VENDOR_ITEM_NBR , ---111
	PO_NBR , ---112 
	MATCHING_KEY , ---113
	VENDOR_NAME , ---114
	HDR_SEQ_NBR , ---115 
	ITEM_NBR , ---116 
	SUBLEDGER_NAME , ---117
	LINE_UPDATED_BY , ---118
	VENDOR_STK_NBR , ---119
	LSI_LINE_DESCR , ---120
	CREATION_DATE , ---121
	LAST_UPDATE_DATE , ---122
	CREATED_BY , ---123
	LAST_UPDATED_BY , ---124
	LEG_COA , ---125 
	TARGET_COA , ---126 
	STATEMENT_ID , ---127
	GL_ALLCON_COMMENTS , ---128
	ATTRIBUTE6 , ---129
	ATTRIBUTE7 , ---130
	ATTRIBUTE8 , ---131
	ATTRIBUTE9 , ---132
	ATTRIBUTE10 , ---133
	ATTRIBUTE11 , ---134
	ATTRIBUTE12 , ---135
	ATTRIBUTE1 , ---136 
	ATTRIBUTE2 , ---137
	ATTRIBUTE3 , ---138
	ATTRIBUTE4 , ---139
	ATTRIBUTE5 ,---140
	DEFAULT_AMOUNT, --- 141 
    ACC_AMOUNT,  --- 142   
    ACC_CURRENCY,  --- 143
    DEFAULT_CURRENCY,  --- 144 
    LEG_LOCATION_LN,  --- 145 
    LEG_ACCT,  --- 146 
    LEG_DEPT,  --- 147 
    LOCATION_LN,  --- 148 
    LEG_VENDOR,  --- 149 
    TRD_PARTNER_NAME,  --- 150 
    REASON_CODE,  --- 151 
    TRANSACTION_NUMBER, --- 152 
    LEG_SEG_1_4,  --- 153  
    LEG_SEG_5_7,  --- 154 
    TRD_PARTNER_NBR, --- 155 
    LEG_ACCT_DESC,  --- 156 
	LEG_BU, --- 157 
    LEG_LOC, --- 158 
    LEG_AFFILIATE, --159
	PS_LOCATION,  ---160 
    AXE_VENDOR,  ---161
    LEG_LOC_SR,  ---162
    PRODUCT_CLASS_LN,  --163
	LEG_BU_LN, --164
    LEG_ACCOUNT, --165
    LEG_DEPARTMENT, --166
    LEG_AFFILIATE_LN, --167
    QUANTITY_DAI, --168
    VENDOR_PART_NBR_LN, --169
    PO_NBR_LN, --170
    LEG_PROJECT, --171
    LEG_DIVISION_LN, --172
	RECORD_TYPE --- 173
	)
    VALUES
   (
    p_batch_id,   ---1 
    wsc_mfinv_line_s1.NEXTVAL, ---2 
    NULL,	---3 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL, 1))),	---4 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL, 1))),	---5 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1))),  ---6
    NULL, ---7
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1))), ---8
    NULL, ---9
    NULL,---10
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 34, NULL, 1))),---11
    NULL,---12
    NULL,---13 
    NULL,---14 
    NULL,---15 
    NULL,---16 
    NULL,---17
    NULL,---18 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 31, NULL, 1))),---19
    NULL,---20 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL, 1))),---21
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1))),---22 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1))),---23 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL, 1))),---24 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 29, NULL, 1))),---25 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 30, NULL, 1))),---26 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 34, NULL, 1))),---27 
    NULL,---28
    NULL,---29
    NULL,---30
    NULL,---31
    NULL,---32
    NULL,---33
    NULL,---34
    NULL,---35
    TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL,1)),'mm/dd/yyyy'),---36
    NULL,---37
    NULL,---38
    NULL,---39
    NULL, ---40
    NULL, ---41
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL, 1)), ---42 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL, 1)), ---43
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)), ---44 
    NULL, ---45
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL, 1)), ---46
    NULL, ---47
    NULL, ---48
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL, 1)), ---49
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL, 1)), ---50
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1)), ---51
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL, 1)), ---52 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL, 1)), ---53 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL, 1)), ---54 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1)), ---55 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL, 1)), ---56 
    NULL, ---57
    NULL, ---58
    NULL, ---59
    NULL, ---60
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1)), ---61 
    NULL, ---62
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)), ---63 
    NULL, ---64
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL, 1)), ---65 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)), ---66 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL, 1)), ---67 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1)), ---68 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1)), ---69
    NULL, ---70  
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1)), ---71
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL, 1)), ---72 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1)), ---73
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL, 1)), ---74
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1)), ---75
    NULL, ---76
    NULL,---77 
    NULL, ---78 
    NULL, ---79 
    NULL, ---80 
    NULL, ---81 
    NULL, ---82 
    NULL, ---83 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1)), ---84
    NULL, ---85 
    NULL, ---86 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)), ---87
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1)), ---88
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1)), ---89
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1)), ---90 
    NULL, ---91
    NULL, ---92
    NULL, ---93
    NULL, ---94
    NULL, ---95
    NULL, --96  
    NULL, ---97
    NULL, ---98
    NULL, ---99
    NULL, ---100
    NULL, ---101
    NULL, ---102
    NULL, ---103
    NULL, ---104
    NULL, ---105
    NULL, ---106
    NULL, ---107
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL, 1)), ---108
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 33, NULL, 1)), ---109
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)), ---110 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 32, NULL, 1)), ---111
    NULL, ---112
    NULL, ---113
    NULL, ---114
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)), ---115 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)), ---116
    NULL, ---117
    NULL, ---118
    NULL, ---119
    NULL, ---120
    SYSDATE,---121
    SYSDATE, ---122
    'FIN_INT',  ---123
    'FIN_INT',  ---124
     TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)) 
    || '.'
    || TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1))
    || '.'
    || TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1))
    || '.'
    || TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1))
    || '.'
    || TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1)) --- removed 00000000 on 2/20
    || '.'
    || nvl(NULL,'00000'),  ---125  --- LEG_COA --- LEG_BU-LEG_LOC-LEG_DEPT-LEG_ACCT-LEG_VENDOR-LEG_AFFILIATE,  ---125  
    NULL,  ---126  
    NULL,  ---127
    NULL,  ---128
    NULL,  ---129
    NULL,  ---130
    NULL,  ---131
    NULL,  ---132
    NULL,  ---133
    NULL,  ---134
    NULL,  ---135  
    NULL,  ---136
    NULL,  ---137
    NULL,  ---138
    NULL,  ---139
    NULL,  ---140
    NULL, ---141
    NULL,  ---142
    NULL,  ---143
    NULL,  ---144 
    NULL,  ---145
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1)),  ---146 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1)),  ---147 
    NULL,  ---148
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1)),  ---149 
    NULL,  ---150
    NULL,  ---151
	CASE
	WHEN TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'DAIN'
	THEN 'DAI'|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)) 
    END,	---152 --- TRANSACTION NUMBER
      TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1))
	||'.'
	||TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1))
	||'.'
	||TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1))
	||'.'
	||TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1)),  ---153 LEG_BU_LN,LEG_LOCATION_LN,LEG_ACCO,LEG_DEPT
     TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1))
	 ||'.'
	 ||NVL(NULL,'00000'), ---154 LEG_VENDOR, LEG_AFFILIATE_LN
    NULL,  ---155
    NULL,   ---156
	TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)), --- 157 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1)), --- 158
    '00000',  ---159
	NULL,   --160 
	NULL,   --161
	NULL,   -- 162
	NULL,    --163
	NULL,  ---164
    NULL,  ---165
    NULL,  ---166
    NULL,  ---167
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1))),  ---168
    NULL,  ---169
    NULL,  ---170
    NULL,  ---171
    NULL, ---172
	TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL, 1))
   );
  END LOOP;
  CLOSE mfinv_stage_line_data_cur;
  COMMIT; 
 --- logging_insert ('MF INV',p_batch_id,5,'STAGE/TEMP TABLE DATA TO LINE TABLE DATA - END',NULL,SYSDATE);
  logging_insert ('MF INV',p_batch_id,5,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Line Table Data Insertion Completed',NULL,SYSDATE);  
  
   /* For System IRIN */

  ELSIF l_mfinv_subsystem IN ('IRIN') THEN

   ---logging_insert ('MF INV',p_batch_id,2,'TEMP/STAGE TABLE DATA TO HEADER TABLE DATA INSERT - START',NULL,SYSDATE);  
   logging_insert ('MF INV',p_batch_id,2,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Header Table Data Insertion Started',NULL,SYSDATE);  
   -- BEGIN
   OPEN mfinv_stage_hdr_data_cur(p_batch_id);
    LOOP
        FETCH mfinv_stage_hdr_data_cur BULK COLLECT INTO lv_mfinv_stg_hdr_type LIMIT 400;
        EXIT WHEN lv_mfinv_stg_hdr_type.COUNT = 0;
        FORALL i IN 1..lv_mfinv_stg_hdr_type.COUNT
		
		INSERT INTO FININT.WSC_AHCS_MFINV_TXN_HEADER_T 
		(
		   BATCH_ID,  ---1  
		   HEADER_ID,  ---2
		   AMOUNT, ---3
		   AMOUNT_IN_CUST_CURR, ---4
		   FX_RATE_ON_INVOICE, ---5
		   TAX_INVC_I, ---6
		   GAAP_AMOUNT, ---7  
		   GAAP_AMOUNT_IN_CUST_CURR, ---8 
		   CASH_FX_RATE, ---9
		   UOM_CONV_FACTOR, ---10 
		   NET_TOTAL, ---11
		   LOC_INV_NET_TOTAL, ---12
		   INVOICE_TOTAL, ---13
		   LOCAL_INV_TOTAL, ---14
		   FX_RATE, ---15
		   CHECK_AMOUNT, ---16
		   ACCRUED_QTY, ---17
		   FISCAL_WEEK_NBR, ---18
		   TOT_LOCAL_AMT, ---19
		   TOT_FOREIGN_AMT, ---20
		   FREIGHT_FACTOR, ---21
		   INVOICE_DATE, ---22
		   INVOICE_DUE_DATE, ---23
		   FREIGHT_INVOICE_DATE, ---24
		   CASH_DATE, ---25
		   CASH_ENTRY_DATE, ---26
		   ACCOUNT_DATE, ---27  
		   BANK_DEPOSIT_DATE, ---28
		   MATCHING_DATE, ---29
		   ADJUSTMENT_DATE, ---30 
		   ACCOUNTING_DATE, ---31 
		   CHECK_DATE, ---32
		   BATCH_DATE, ---33
		   DUE_DATE, ---34
		   VOID_DATE, ---35
		   DOCUMENT_DATE, ---36 
		   RECEIVER_CREATE_DATE, ---37
		   TRANSACTION_DATE, ----38 
		   CONTINENT, ---39  
		   CONT_C, ---40 
		   PO_TYPE, ---41 
		   CHECK_PAYMENT_TYPE, ---42
		   VOID_CODE, ---43
		   CROSS_BORDER_FLAG, ---44
		   BATCH_POSTED_FLAG, ---45
		   INTERFACE_ID, ---46 
		   LOCATION, ---47   
		   INVOICE_TYPE, ---48 
		   CUSTOMER_TYPE, ---49
		   INVOICE_LOC_ISO_CNTRY, ---50
		   INVOICE_LOC_DIV, ---51
		   SHIP_TO_NBR, ---52
		   INVOICE_CURRENCY, ---53 
		   CUSTOMER_CURRENCY, ---54
		   SHIP_TYPE, ---55
		   EXPORT_TYPE, ---56
		   RECORD_ERROR_CODE, ---57
		   CREDIT_TYPE, ---58
		   NON_RA_CREDIT_TYPE, ---59
		   CI_PROFILE_TYPE, ---60
		   AMOUNT_TYPE, ---61
		   CASH_CODE, ---62
		   EMEA_FLAG, ---63
		   CUST_CREDIT_PREF, ---64
		   ITEM_UOM_C, ---65
		   IB30_REASON_C, ---66
		   RECEIVER_LOC, ---67 
		   RA_LOC, ---68
		   FINAL_DEST, ---69
		   JOURNAL_SOURCE_C, ---70
		   KAVA_F, ---71
		   DIVISION, ---72
		   CHECK_STOCK, ---73
		   SALES_LOC, ---74
		   THIRD_PARTY_INTFC_FLAG, ---75
		   VENDOR_PAYMENT_TYPE, ---76
		   VENDOR_CURRENCY_CODE, ---77
		   SPC_INV_CODE, ---78
		   SOURCE_SYSTEM, --- 79 
		   LEG_DIVISION_HDR, --- 80 
		   RECORD_TYPE, ---81 
		   CUSTOMER_NBR, ---82
		   BUSINESS_UNIT, ---83 
		   SHIP_FROM_LOC, ---84
		   FREIGHT_VENDOR_NBR, ---85
		   FREIGHT_INVOICE_NBR, ---86
		   CASH_BATCH_NBR, ---87
		   GL_DIV_HEADQTR_LOC, ---88
		   GL_DIV_HQ_LOC_BU, ---89
		   SHIP_FROM_LOC_BU, ---90
		   PS_AFFILIATE_BU, ---91
		   RECEIVER_NBR, ---92
		   FISCAL_DATE, ---93 
		   VENDOR_NBR, ---94 
		   BATCH_NUMBER, ---95
		   HEAD_OFFICE_LOC, ---96
		   EMPLOYEE_ID, ---97
		   BUSINESS_SEGMENT, ---98
		   UPDATED_USER, ---99
		   USERID, ---100
		   LEG_BU_HDR, --- 101 
		   SALES_ORDER_NBR, ---102
		   CHECK_NBR, ---103
		   VENDOR_ABBREV, ---104 
		   CONCUR_SAE_BATCH_ID, ---105
		   PAYMENT_TERMS, ---106
		   FREIGHT_TERMS, ---107 
		   VENDOR_ABBREV_C, ---108
		   RA_NBR, ---109 
		   SALES_REP, ---110
		   PURCHASE_ORDER_NBR, ---111
		   CATALOG_NBR, ---112  
		   REEL_NBR, ---113 
		   PS_LOCATION, ---114 
		   LOCAL_CURRENCY, ---115 
		   FOREIGN_CURRENCY, ---116 
		   PO_NBR, ---117 
		   PRODUCT_CLASS, ---118 
		   UNIT_OF_MEASURE, ---119 
		   VENDOR_PART_NBR, ---120 
		   RECEIVER_I, ---121 
		   ITEM_I, ---122 
		   TRANS_ID, ---123 
		   INVOICE_I, ---124 
		   RECEIPT_TYPE, ---125
		   COUNTRY_CODE, ---126
		   RA_CUSTOMER_NBR, ---127
		   RA_CUSTOMER_NAME, ---128
		   PURCHASE_CODE, ---129
		   INTERFC_DESC_LOC,---130
		   RECEIVER_NBR_HDR, ---131 
		   PRODUCT_CLASS_HDR, --132 
		   VENDOR_PART_NBR_HDR, --133 
		   GL_TRANSFER, ---134 
		   LEG_TRANS_TYPE, ---135 
		   LEG_LOCATION_HDR, --- 136 
		   INVOICE_NBR, ---137 
		   REFER_INVOICE, ---138
		   VOUCHER_NBR, ---139
		   CASH_CHECK_NBR, ---140
		   FREIGHT_BILL_NBR, ---141
		   FRT_BILL_PRO_REF_NBR, ---142
		   VENDOR_NAME, ---143 
		   PAYMENT_REF_ID, ---144
		   MATCHING_KEY, ---145
		   PAY_FROM_ACCOUNT, ---146
		   INTERFC_DESC_T, ---147
		   INTERFC_DESC_LOC_LANG, ---148
		   HDR_SEQ_NBR, ---149 
		   CUSTOMER_NAME, ---150
		   CASH_LOCKBOX_ID, ---151
		   CUST_PO, ---152
		   FREIGHT_VENDOR_NAME, ---153
		   TRANSACTION_TYPE, --- 154 
		   THIRD_PARTY_INVOICE_ID, ---155
		   CONTRA_REASON, ---156
		   TRANSREF, ---157
		   IB30_MEMO, ---158 
		   TRANSACTION_NUMBER, --- 159 
           LEDGER_NAME,     --- 160  
           FILE_NAME,  --- 161 
		   INTERFACE_DESC_EN, ---162
		   INTERFACE_DESC_FRN, ---163 
		   HEADER_DESC, --- 164 
           HEADER_DESC_LOCAL_LAN, --- 165 
		   CREATION_DATE, ---166
		   LAST_UPDATE_DATE, ---167
		   CREATED_BY, ---168
		   LAST_UPDATED_BY, ---169
		   ATTRIBUTE6, ---170
		   ATTRIBUTE7, ---171
		   ATTRIBUTE8, ---172
		   ATTRIBUTE9, ---173
		   ATTRIBUTE10, ---174
		   ATTRIBUTE11, ---175
		   ATTRIBUTE12, ---176
		   ATTRIBUTE1, ---177
		   ATTRIBUTE2, ---178
		   ATTRIBUTE3, ---179
		   ATTRIBUTE4, ---180
		   ATTRIBUTE5, ---181
		   ACCRUED_QUANTITY_DAI, --- 182
           LEG_DIVISION, --- 183
           TRD_PARTNER_NBR_HDR, --- 184
           TRD_PARTNER_NAME_HDR, --- 185
           INVOCIE_DATE,  --- 186
           HEADER_AMOUNT, --- 187
           LEG_AFFILIATE, --- 188
           UOM_C_HDR, --- 189
           INV_TOTAL, --- 190
           PURCHASE_CODE_HDR, --- 191
           USER_I, --- 192
           REASON_CODE_HDR --- 193
		   ) 
		   VALUES 
		   (
		   p_batch_id,  ---1
		   wsc_mfinv_header_t_s1.NEXTVAL,  ---2
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)), ---3
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)), ---4
		   NULL, ---5
		   NULL, ---6
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 34, NULL, 1)), ---7 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 35, NULL, 1)), ---8 
		   NULL, ---9
		   NULL, ---10 
		   NULL, ---11 
		   NULL, ---12
		   NULL,---13
		   NULL, ---14 
		   NULL, ---15 
		   NULL, ---16 
		   NULL, ---17
		   NULL, ---18
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)), ---19 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)), ---20 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 33, NULL, 1)), ---21 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 30, NULL,1)),'mm/dd/yyyy'), --22
		   NULL, ---23
		   NULL, ---24
		   NULL, ---25
		   NULL, ---26
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL,1)),'mm/dd/yyyy'), ---27  
		   NULL, ---28
		   NULL, ---29
		   NULL, ---30 
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL,1)),'mm/dd/yyyy'),--31 
		   NULL, --32
		   NULL, ---33
		   NULL, ---34
		   NULL, ---35
		   NULL, ---36
		   TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 30, NULL,1)),'mm/dd/yyyy'), ---37
		   NULL, --- 38
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL, 1)), ---39
		   NULL, ---40 
		   NULL, --- 41
		   NULL, --- 42
		   NULL, ---43
		   NULL, --44
		   NULL, ---45
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)), --46 
 		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1)), ---47
		   NULL,  --48
		   NULL, ---49 
		   NULL, ---50
		   NULL, ---51
		   NULL, ---52
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)),--53
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1)), ---54
		   NULL, ---55
		   NULL, ---56
		   NULL, ---57
		   NULL, ---58
		   NULL, ---59
		   NULL, ---60
		   NULL, ---61
		   NULL, ---62
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1)), ---63 
		   NULL, ---64
		   NULL, ---65
		   NULL, ---66
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL, 1)), ---67 
		   NULL, ---68
		   NULL, ---69
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 36, NULL, 1)), ---70 
		   NULL, ---71
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL, 1)), ---72
		   NULL, ---73
		   NULL, ---74
		   NULL, ---75
		   NULL, ---76
		   NULL, --- 77
		   NULL, ---78
		   NULL, --- 79
		   NULL, --- 80
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL, 1)), ---81 
		   NULL, ---82
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1)), ---83
		   NULL, ---84
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL, 1)), ---85 
		   NULL, ---86
		   NULL, ---87
		   NULL, ---88
		   NULL, ---89
		   NULL, ---90
		   NULL, ---91
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL, 1)), ---92 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 29, NULL, 1)), ---93
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL, 1)), ---94
		   NULL, ---95
		   NULL, ---96
		   NULL, ---97
		   NULL, ---98
		   NULL, ---99
		   NULL, ---100
		   NULL, --- 101
		   NULL, ---102
		   NULL,  --- 103
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 31, NULL, 1)), ---104
		   NULL, ---105
		   NULL, ---106
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1)), ---107
		   NULL, ---108
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL, 1)), ---109 
		   NULL, ---110
		   NULL,  --- 111
		   NULL , ---112 
		   NULL ,  ---113 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1)), ---114 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)), ---115 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1)), ---116 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1)), ---117 
		   NULL, ---118 
		   NULL, ---119 
		   NULL, ---120  
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL, 1)), ---121 
		   NULL, ---122   
		   NULL, ---123 
		   NULL, ---124 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL, 1)), ---125 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL, 1)), ---126 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL, 1)), ---127 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1)), ---128 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL, 1)), ---129  
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL, 1)), ---130 
		   NULL, --- 131
		   NULL, ---132
		   NULL, ---133
		   NULL, ---134 
		   NULL, ---135
		   NULL, ---136
		   NULL, ---137
		   NULL, ---138
		   NULL, ---139
		   NULL, ---140
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 32, NULL, 1)), ---141 
		   NULL, ---142
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1)), ---143 
		   NULL, ---144
		   NULL, ---145
		   NULL, ---146
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL, 1)), ---147 
		   NULL, --- 148
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)), --149 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1)), ---150
		   NULL, ---151
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1)), ---152
		   NULL, ---153
		   NULL, ---154
		   NULL, ---155
		   NULL, ---156
		   NULL, ---157
		   NULL, ---158
		   CASE
		   WHEN 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1))='IRIN'
		   THEN 'IRI' || TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1))
		   END,---159 
		   NULL, ---160 
		   p_file_name, ---161 
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL, 1)), --162
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 28, NULL, 1)), --163
		   NULL, --164
		   NULL,--165
		   SYSDATE, ---166
		   SYSDATE, ---167
		   'FIN_INT', ---168
		   'FIN_INT', ---169
		   NULL, ---170
		   NULL, ---171
		   NULL, ---172
		   NULL, ---173
		   NULL, ---174
		   SYSDATE, ---175
		   SYSDATE, ---176
		   NULL, ---177
		   NULL, ---178
		   NULL, ---179
		   NULL, ---180
		   NULL, ---181
		   NULL, ---182
		   NULL, ---183
		   NULL, ---184
		   NULL, ---185
		   NULL, ---186
		   NULL, ---187
		   NULL, ---188
		   NULL, ---189
		   NULL, ---190
		   TRIM(regexp_substr(lv_mfinv_stg_hdr_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL, 1)), ---191
		   NULL,---192
		   NULL--193
		   );
    END LOOP;
	CLOSE mfinv_stage_hdr_data_cur;
    dbms_output.put_line('HEADER Exit');
    COMMIT;
   ---logging_insert ('MF INV',p_batch_id,3,'STAGE/TEMP TABLE DATA TO HEADER TABLE DATA - END',NULL,SYSDATE);
    logging_insert ('MF INV',p_batch_id,3,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Header Table Data Insertion Completed',NULL,SYSDATE);  
   /*EXCEPTION 
   WHEN OTHERS THEN
   Logging_insert ('MF INV',p_batch_id,2.1,'value of error flag',SQLERRM,SYSDATE);
   END;*/
   
	/********** PROCESS UNSTRUCTURED STAGE TABLE DATA TO LINE TABLE DATA - START *************/
    dbms_output.put_line(' Begin segregration of line data');
	
   /* BEGIN
	  OPEN mfinv_fetch_stage_hdr_data_cur(wsc_mfinv_header_t_s1.CURRVAL);
	  FETCH mfinv_fetch_stage_hdr_data_cur  INTO lv_business_unit,lv_location,lv_vendor;
	  CLOSE mfinv_fetch_stage_hdr_data_cur;
	END; */
	
BEGIN
    --logging_insert ('MF INV',p_batch_id,4,'STAGE/TEMP TABLE DATA TO LINE TABLE DATA INSERT - START',NULL,SYSDATE);
	 logging_insert ('MF INV',p_batch_id,4,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Line Table Data Insertion Started',NULL,SYSDATE);  
	OPEN mfinv_stage_line_data_cur(p_batch_id);
    LOOP
    FETCH mfinv_stage_line_data_cur BULK COLLECT INTO lv_mfinv_stg_line_type LIMIT 400;
    EXIT WHEN lv_mfinv_stg_line_type.COUNT = 0;
    FORALL i IN 1..lv_mfinv_stg_line_type.COUNT
   
    INSERT INTO FININT.WSC_AHCS_MFINV_TXN_LINE_T
    (	
    BATCH_ID ,   --- 1	
	LINE_ID ,   ---2 
	HEADER_ID ,  ---3 
	LINE_SEQ_NUMBER, ---4
	AMOUNT , ---5   
	AMOUNT_IN_CUST_CURR , ---6 
	UNIT_PRICE , ---7
	SHIPPED_QUANTITY , ---8
	UOM_CNVRN_FACTOR , ---9 
	BILLED_QTY , ---10
	AVG_UNIT_COST , ---11
	STD_UNIT_COST , ---12
	QTY_ON_HAND_BEFORE , ---13 
	ADJUSTMENT_QTY ,  ---14 
	QTY_ON_HAND_AFTER ,  ---15 
	CUR_COST_BEFORE , ---16 
	ADJ_COST_LOCAL , ---17   
	ADJ_COST_FOREIGN , ---18 
	FX_RATE , ---19 
	CUR_COST_AFTER , ---20 
	GL_AMOUNT_IN_LOC_CURR , ---21
	GL_AMNT_IN_FORIEGN_CURR , ---22
	QUANTITY , ---23 
	UOM_CONV_FACTOR , ---24
	UNIT_COST , ---25
	EXT_COST , ---26
	AVG_UNIT_COST_A , ---27 
	AMT_LOCAL_CURR , ---28
	AMT_FOREIGN_CURR , ---29
	RECEIVED_QTY , ---30
	RECEIVED_UNIT_COST , ---31
	PO_UNIT_COST , ---32
	TRANSACTION_AMOUNT , ---33
	FOREIGN_EX_RATE , ---34
	BASE_AMOUNT , ---35
	INVOICE_DATE , ---36
	RECEIPT_DATE , ---37
	LINE_UPDATED_DATE , ---38
	MATCHING_DATE , ---39
	PC_FLAG , ---40
	VENDOR_INDICATOR , ---41 
	CONTINENT, ---42
	DB_CR_FLAG , ---43 
	INTERFACE_ID , ---44 
	LINE_TYPE , ---45
	AMOUNT_TYPE , ---46 
	LINE_NBR , ---47
	LRD_SHIP_FROM , ---48
	UOM_C , ---49 
	INVOICE_CURRENCY , ---50
	CUSTOMER_CURRENCY , ---51
	GAAP_F , ---52 
	GL_DIVISION , ---53
	LOCAL_CURRENCY , ---54 
	FOREIGN_CURRENCY , ---55 
	PO_LINE_NBR , ---56
	LEG_DIVISION , ---57
	TRANSACTION_CURR_CD , ---58
	BASE_CURR_CD , ---59
	TRANSACTION_TYPE , ---60
	LOCATION , ---61 
	MIG_SIG , ---62
	BUSINESS_UNIT , ---63
	PAYMENT_CODE , ---64
	VENDOR_NBR , ---65
	RECEIVER_NBR , ---66
	UNIT_OF_MEASURE , ---67
	GL_ACCOUNT , ---68
	GL_DEPT_ID , ---69
	ADJUSTMENT_USER_I , ---70 
	GL_AXE_VENDOR , ---71
	GL_PROJECT , ---72
	GL_AXE_LOC , ---73
	GL_CURRENCY_CD , ---74
	PS_AFFILIATE_BU , ---75
	CASH_AR50_COMMENTS , ---76
	VENDOR_ABBREV_C , ---77 
	QTY_COST_REASON , ---78 
	QTY_COST_REASON_CD , ---79 
	ACCT_DESC , ---80 
	ACCT_NBR , ---81 
	LOC_CODE , ---82 
	DEPT_CODE , ---83 
	GL_LOCATION , ---84 
	GL_VENDOR , ---85
	BUYER_CODE , ---86 
	GL_BUSINESS_UNIT , ---87
	GL_DEPARTMENT ,  ---88
	GL_VENDOR_NBR_FULL , ---89
	AFFILIATE , ---90
	ACCOUNTING_DATE , ---91
	RECEIVER_LINE_NBR , ---92
	VENDOR_PART_NBR , ---93
	ERROR_TYPE , ---94
	ERROR_CODE , ---95
	GL_LEGAL_ENTITY , ---96 
	GL_ACCT , ---97 
	GL_OPER_GRP , ---98 
	GL_DEPT , ---99 
	GL_SITE , ---100 
	GL_IC , ---101 
	GL_PROJECTS , ---102 
	GL_FUT_1 , ---103 
	GL_FUT_2 , ---104 
	SUBLEDGER_NBR , ---105
	BATCH_NBR , ---106
	ORDER_ID , ---107
	INVOICE_NBR , ---108
	PRODUCT_CLASS , ---109
	PART_NBR ,  ---110
	VENDOR_ITEM_NBR , ---111
	PO_NBR , ---112 
	MATCHING_KEY , ---113
	VENDOR_NAME , ---114
	HDR_SEQ_NBR , ---115 
	ITEM_NBR , ---116 
	SUBLEDGER_NAME , ---117
	LINE_UPDATED_BY , ---118
	VENDOR_STK_NBR , ---119
	LSI_LINE_DESCR , ---120
	CREATION_DATE , ---121
	LAST_UPDATE_DATE , ---122
	CREATED_BY , ---123
	LAST_UPDATED_BY , ---124
	LEG_COA , ---125 
	TARGET_COA , ---126 
	STATEMENT_ID , ---127
	GL_ALLCON_COMMENTS , ---128
	ATTRIBUTE6 , ---129
	ATTRIBUTE7 , ---130
	ATTRIBUTE8 , ---131
	ATTRIBUTE9 , ---132
	ATTRIBUTE10 , ---133
	ATTRIBUTE11 , ---134
	ATTRIBUTE12 , ---135
	ATTRIBUTE1 , ---136 
	ATTRIBUTE2 , ---137
	ATTRIBUTE3 , ---138
	ATTRIBUTE4 , ---139
	ATTRIBUTE5 ,---140
	DEFAULT_AMOUNT, --- 141
    ACC_AMOUNT,  --- 142  
    ACC_CURRENCY,  --- 143 
    DEFAULT_CURRENCY,  --- 144 
    LEG_LOCATION_LN,  --- 145 
    LEG_ACCT,  --- 146 
    LEG_DEPT,  --- 147 
    LOCATION_LN,  --- 148 
    LEG_VENDOR,  --- 149 
    TRD_PARTNER_NAME,  --- 150 
    REASON_CODE,  --- 151 
    TRANSACTION_NUMBER, --- 152 
    LEG_SEG_1_4,  --- 153  
    LEG_SEG_5_7,  --- 154 
    TRD_PARTNER_NBR, --- 155  
    LEG_ACCT_DESC,  --- 156  
	LEG_BU, --- 157  
    LEG_LOC, --- 158  
    LEG_AFFILIATE, --159 
	PS_LOCATION,  ---160  
    AXE_VENDOR,  ---161 
    LEG_LOC_SR,  ---162 
    PRODUCT_CLASS_LN,  --163 
	LEG_BU_LN, --164
    LEG_ACCOUNT, --165 
    LEG_DEPARTMENT, --166 
    LEG_AFFILIATE_LN, --167
    QUANTITY_DAI, --168
    VENDOR_PART_NBR_LN, --169
    PO_NBR_LN, --170
    LEG_PROJECT, --171
    LEG_DIVISION_LN, --172
	RECORD_TYPE
	)
    VALUES
   (
    p_batch_id,   ---1 
    wsc_mfinv_line_s1.NEXTVAL, ---2 
    NULL,	---3 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 5, NULL, 1))),	---4 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL, 1))),---5 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL, 1))), ---6
    NULL, ---7
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1))), ---8
    NULL, ---9
    NULL,---10
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1))),---11
    NULL,---12
    NULL,---13 
    NULL,---14 
    NULL,---15 
    NULL,---16 
    NULL,---17
    NULL,---18 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 10, NULL, 1))),---19 
    NULL,---20 
    NULL, --- 21
    NULL, --- 22
    NULL, --- 23
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 18, NULL, 1))),---24 
    NULL, --- 25
    NULL, --- 26
    NULL, --- 27
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 8, NULL, 1))),---28 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 9, NULL, 1))),---29  
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 14, NULL, 1))),---30 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 15, NULL, 1))),---31 
    TO_NUMBER(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 16, NULL, 1))),---32 
    NULL,---33
    NULL,---34
    NULL,---35
    NULL, --- 36
    TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 21, NULL,1)),'mm/dd/yyyy'),---37 
    NULL,---38 
    NULL,---39
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 26, NULL, 1)), ---40 
    NULL, ---41
    NULL,
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 6, NULL, 1)), ---43 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)), ---44 
    NULL, ---45
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 7, NULL, 1)), ---46 
    NULL, ---47
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 25, NULL, 1)), ---48 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL, 1)), ---49
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL, 1)), ---50
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)), ---51
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 27, NULL, 1)), ---52 
    NULL, ---53
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL, 1)), ---54 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 24, NULL, 1)), ---55 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 11, NULL, 1)), ---56 
    NULL, ---57
    NULL, ---58
    NULL, ---59
    NULL, ---60
    NULL,---lv_location, ---61 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 19, NULL, 1)), ---62 
    NULL,--lv_business_unit, ---63 
    NULL, ---64
    NULL, ---65
    NULL, ---66
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 17, NULL, 1)), ---67 
    NULL, ---68
    NULL, ---69
    NULL, ---70  
    NULL, ---71
    NULL,   ---72
    NULL,---lv_location, ---73
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 23, NULL, 1)), ---74
    NULL, ---75
    NULL, ---76
    NULL,---77 
    NULL, ---78 
    NULL, ---79 
    NULL, ---80 
    NULL, ---81 
    NULL, ---82 
    NULL, ---83 
    NULL,---lv_location, ---84
    NULL, ---85 
    NULL, ---86 
    NULL, ----87
    NULL, ---88
    NULL, ---89
    NULL, ---90
    TO_DATE(TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 4, NULL,1)),'mm/dd/yyyy'), ---91 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 12, NULL, 1)), ---92  
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 22, NULL, 1)), ---93  
    NULL, ---94
    NULL, ---95
    NULL, --96  
    NULL, ---97
    NULL, ---98
    NULL, ---99
    NULL, ---100
    NULL, ---101
    NULL, ---102
    NULL, ---103
    NULL, ---104
    NULL, ---105
    NULL, ---106
    NULL, ---107
    NULL, ---108
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 20, NULL, 1)), ---109 
    NULL, ---110
    NULL, ---111
    NULL, ---112
    NULL, ---113
    NULL, ---114
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1)), ---115 
    TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 13, NULL, 1)), ---116 
    NULL, ---117
    NULL, ---118
    NULL, ---119
    NULL, ---120
    SYSDATE,---121
    SYSDATE, ---122
    'FIN_INT',  ---123
    'FIN_INT',  ---124
    --lv_business_unit 
    --|| '.'
    --|| lv_location
    --|| '.'
    --|| NULL
    --|| '.'
    --|| NULL
    ---|| '.'
    --|| lv_vendor
    --|| '.'
    --|| nvl(NULL,'00000')
	NULL,  --- LEG_COA --- LEG_BU-LEG_LOC-LEG_DEPT-LEG_ACCT-LEG_VENDOR-LEG_AFFILIATE,  ---125  
    NULL,  ---126  
    NULL,  ---127
    NULL,  ---128
    NULL,  ---129
    NULL,  ---130
    NULL,  ---131
    NULL,  ---132
    NULL,  ---133
    NULL,  ---134
    NULL,  ---135  
    NULL,  ---136
    NULL,  ---137
    NULL,  ---138
    NULL,  ---139
    NULL,  ---140
    NULL, ---141
    NULL,  ---142
    NULL,  ---143
    NULL,  ---144 
    NULL,  ---145
    NULL,  ---146 
    NULL,  ---147 
    NULL,  ---148
    NULL,  ---149 
    NULL,  ---150
    NULL,  ---151
	CASE
	WHEN TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 3, NULL, 1)) = 'IRIN'
	THEN 'IRI'|| TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 2, NULL, 1))
    END,  ---152
    --lv_business_unit
	--||'.'
	--||lv_location
	--||'.'
	--||'.'
	NULL,  ---153 ---LEG_BU_HDR,LEG_LOCATION_HDR
    --lv_vendor
	--||'.'
	--|| nvl(NULL,'00000')
	NULL, ---154  --- LEG_VENDOR,LEG_AFFILIATE
    NULL,  ---155
    NULL,   ---156
	NULL,--lv_business_unit, --- 157 
    NULL,---lv_location, --- 158
    NULL,  ---159
	NULL,   --160 
	NULL,   --161
	NULL,   -- 162
	NULL,    --163
	NULL,  ---164
    NULL,  ---165
    NULL,  ---166
    NULL,  ---167
    NULL,  ---168
    NULL,  ---169
    NULL,  ---170
    NULL,  ---171
    NULL,  ---172
	TRIM(regexp_substr(lv_mfinv_stg_line_type(i).data_string, '([^|]*)(\||$)', 1, 1, NULL, 1))
   );
   END LOOP;
     CLOSE mfinv_stage_line_data_cur;
   COMMIT; 
   
   ---logging_insert ('MF INV',p_batch_id,5,'STAGE/TEMP TABLE DATA TO LINE TABLE DATA INSERT - END',NULL,SYSDATE);
     logging_insert ('MF INV',p_batch_id,5,'MF INV'||' '||l_mfinv_subsystem || '- Stage/Temp Table Data To Line Table Data Insertion Completed',NULL,SYSDATE); 
   EXCEPTION 
    WHEN OTHERS THEN
    Logging_insert ('MF INV',p_batch_id,1.1,'value of error flag',sqlerrm,sysdate);
    END;
END IF;

 /*EXCEPTION 
   WHEN OTHERS THEN
   Logging_insert ('MF INV',p_batch_id,1.1,'value of error flag',sqlerrm,sysdate);
   END;*/

 ---   logging_insert('MF INV', p_batch_id, 6, 'Updating MF INV Line Table With Header Id Starts', NULL,SYSDATE);
  logging_insert ('MF INV',p_batch_id,6,'MF INV'||' '||l_mfinv_subsystem || '- Updating Line Table With Header Id Started',NULL,SYSDATE);  
	
	IF l_mfinv_subsystem = 'IRIN' THEN			  
	UPDATE WSC_AHCS_MFINV_TXN_LINE_T line
        SET
            ( header_id,BUSINESS_UNIT,LEG_BU,LOCATION,GL_AXE_LOC,GL_LOCATION,LEG_LOC,VENDOR_NBR,LEG_COA,LEG_SEG_1_4,LEG_SEG_5_7 ) = (
                SELECT  /*+ index(hdr WSC_AHCS_MFINV_TXN_HEADER_HDR_SEQ_NBR_I) */
                  hdr.header_id,
				  hdr.BUSINESS_UNIT,
				  hdr.BUSINESS_UNIT,
				  hdr.PS_LOCATION,
				  hdr.PS_LOCATION,
				  hdr.PS_LOCATION,
				  hdr.PS_LOCATION,
				  hdr.VENDOR_NBR,
				  hdr.BUSINESS_UNIT || '.' || hdr.PS_LOCATION || '.' || NULL || '.' || NULL || '.' || hdr.VENDOR_NBR || '.' || nvl(NULL,'00000'),
				  hdr.BUSINESS_UNIT || '.' || hdr.PS_LOCATION || '.' || '.',
				  '.' 
				  
              FROM
                    WSC_AHCS_MFINV_TXN_HEADER_T hdr
                WHERE
                        line.hdr_seq_nbr = hdr.hdr_seq_nbr
                    AND line.batch_id = hdr.batch_id
	--				AND ROWNUM=1
            )
        WHERE
            batch_id = p_batch_id;
        COMMIT;
   --- logging_insert('MF INV', p_batch_id, 7, 'Updating MF INV Line Table With Header Id Ends', NULL,SYSDATE);
    logging_insert ('MF INV',p_batch_id,7,'MF INV'||' '||l_mfinv_subsystem || '- Updating Line Table With Header Id Completed',NULL,SYSDATE); 
	    --CONTINUE;
	    END IF;
		
		logging_insert ('MF INV',p_batch_id,6,'MF INV'||' '||l_mfinv_subsystem || '- Updating Line Table With Header Id Started',NULL,SYSDATE); 
		IF l_mfinv_subsystem = 'COQI' THEN			  
	    UPDATE WSC_AHCS_MFINV_TXN_LINE_T line
        SET
            ( header_id,BUSINESS_UNIT,LEG_BU,LEG_COA,LEG_SEG_1_4) = (
                SELECT  /*+ index(hdr WSC_AHCS_MFINV_TXN_HEADER_HDR_SEQ_NBR_I) */
                  hdr.header_id,
				  hdr.BUSINESS_UNIT,
				  hdr.BUSINESS_UNIT,
				  hdr.BUSINESS_UNIT || '.' || line.GL_AXE_LOC || '.' || line.LEG_DEPT || '.' || line.LEG_ACCT || '.' || line.GL_VENDOR || '.' || nvl(NULL,'00000'),
				  hdr.BUSINESS_UNIT || '.' || line.GL_AXE_LOC || '.' || line.LEG_ACCT || '.' || line.LEG_DEPT 
				  
              FROM
                    WSC_AHCS_MFINV_TXN_HEADER_T hdr
                WHERE
                        line.hdr_seq_nbr = hdr.hdr_seq_nbr
                    AND line.batch_id = hdr.batch_id
		--			AND ROWNUM=1
            )
        WHERE
            batch_id = p_batch_id;
        COMMIT;
   --- logging_insert('MF INV', p_batch_id, 7, 'Updating MF INV Line Table With Header Id Ends', NULL,SYSDATE);
   logging_insert ('MF INV',p_batch_id,7,'MF INV'||' '||l_mfinv_subsystem || '- Updating Line Table With Header Id Completed',NULL,SYSDATE); 
	    --CONTINUE;
	    END IF;
		
	--	logging_insert ('MF INV',p_batch_id,6,'MF INV'||' '||l_mfinv_subsystem || '- Updating Line Table With Header Id Started',NULL,SYSDATE);
		UPDATE WSC_AHCS_MFINV_TXN_LINE_T line
        SET
            ( header_id ) = (
                SELECT  /*+ index(hdr WSC_AHCS_MFINV_TXN_HEADER_HDR_SEQ_NBR_I) */
                  hdr.header_id
					
              FROM
                    WSC_AHCS_MFINV_TXN_HEADER_T hdr
                WHERE
                        line.hdr_seq_nbr = hdr.hdr_seq_nbr
                    AND line.batch_id = hdr.batch_id
				--	AND ROWNUM=1
            )
        WHERE
            batch_id = p_batch_id;
        COMMIT;
    -- logging_insert('MF INV', p_batch_id, 7, 'Updating MF INV Line Table With Header Id Ends', NULL,SYSDATE);
	logging_insert ('MF INV',p_batch_id,7,'MF INV'||' '||l_mfinv_subsystem || '- Updating Line Table With Header Id Completed',NULL,SYSDATE); 
					  
	---logging_insert('MF INV', p_batch_id, 8, 'Inserting Records In Status Table Starts', NULL,SYSDATE);
	logging_insert ('MF INV',p_batch_id,8,'MF INV'||' '||l_mfinv_subsystem || '- Inserting Records Into Status Table Started',NULL,SYSDATE); 
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
                'NEW',
               /* nvl(line.db_cr_flag,
                    CASE
                        WHEN line.amount >= 0 THEN
                            'DR'
                        WHEN line.amount < 0  THEN
                            'CR'
                    END
                ),---line.db_cr_flag, */
				nvl(line.db_cr_flag,
                    CASE
                        WHEN hdr.interface_id = 'AIIB' and line.amount >= 0 THEN 'CR'
						WHEN hdr.interface_id = 'AIIB' and line.amount < 0 THEN 'DR'
						WHEN line.amount >= 0 THEN 'DR'
						WHEN line.amount < 0  THEN 'CR'
				    END
                    ),---line.db_cr_flag,
                line.invoice_currency,---line.local_currency,
                line.amount,--- line.adj_cost_local,
                line.leg_coa,
                line.hdr_seq_nbr,
                line.line_seq_number,
                line.transaction_number,   
                hdr.account_date,---hdr.accounting_date, 
                line.interface_id,
                'FIN_INT',
                SYSDATE,
                'FIN_INT',
                SYSDATE
            FROM
                WSC_AHCS_MFINV_TXN_LINE_T    line,
                WSC_AHCS_MFINV_TXN_HEADER_T  hdr
            WHERE
                    line.batch_id = p_batch_id
                AND hdr.header_id (+) = line.header_id
                AND hdr.batch_id (+) = line.batch_id;
        COMMIT;
   --- logging_insert('MF INV', p_batch_id, 9, 'Inserting Records In Status Table Ends', NULL,SYSDATE);      
    logging_insert ('MF INV',p_batch_id,9,'MF INV'||' '||l_mfinv_subsystem || '- Inserting Records Into Status Table Completed',NULL,SYSDATE); 	
	EXCEPTION
    WHEN OTHERS THEN
        p_error_flag := '1';
        err_msg := SUBSTR(SQLERRM, 1, 200);
    logging_insert('MF INV', p_batch_id, 9.1,'Error In WSC_PROCESS_MFINV_STAGE_TO_HEADER_LINE Proc',SQLERRM,SYSDATE);
        wsc_ahcs_int_error_logging.error_logging(p_batch_id,
                                                 'INT222'
                                                  || '_'
                                                  || l_system,
                                                  'MF INV',
                                                  SQLERRM);
        dbms_output.put_line(SQLERRM); 
	END WSC_PROCESS_MFINV_TEMP_TO_HEADER_LINE_P;
END WSC_MFINV_PKG;
/