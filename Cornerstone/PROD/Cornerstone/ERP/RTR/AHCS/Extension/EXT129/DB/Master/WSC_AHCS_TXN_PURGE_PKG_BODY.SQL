create or replace PACKAGE BODY WSC_AHCS_TXN_PURGE_PKG AS

    PROCEDURE delete_data_system (
        p_batch_id NUMBER
    ) IS

        lv_batch_id            NUMBER;
        line_sql               VARCHAR2(1000);
        status_sql             VARCHAR2(1000);
        hdr_sql                VARCHAR2(1000);
        purge_line_refcur      SYS_REFCURSOR;
        lv_transaction_number  VARCHAR2(100);
        lv_transaction_date    DATE;
        lv_ledger              VARCHAR2(100);
        lv_subledger           VARCHAR2(10);
        line_sql_data          VARCHAR2(1000);
        table_name             VARCHAR2(10);
        lv_sqlerrm             VARCHAR(2000);
    BEGIN
    lv_batch_id := p_batch_id;
        
    logging_insert('PURGE', lv_batch_id, 1, 'Purge Start', NULL, sysdate);
        SELECT DISTINCT
            subledger
        INTO lv_subledger
        FROM
            wsc_ahcs_txn_purge_hdr_t
        WHERE
            batch_id = lv_batch_id;
    logging_insert('PURGE', lv_batch_id, 2, 'lv_subledger: '||lv_subledger, NULL, sysdate);
    
        IF lv_subledger = 'CENTRAL' THEN
            table_name := 'CENTRAL';
        ELSIF lv_subledger = 'CLOUDPAY' THEN
            table_name := 'CP';
        ELSIF lv_subledger = 'CONCUR' THEN
            table_name := 'CNCR';
        ELSIF lv_subledger = 'EBS AP' THEN
            table_name := 'AP';
        ELSIF lv_subledger = 'EBS AR' THEN
            table_name := 'AR';
        ELSIF lv_subledger = 'EBS FA' THEN
            table_name := 'FA';
        ELSIF lv_subledger = 'ECLIPSE' THEN
            table_name := 'ECLIPSE';
        ELSIF lv_subledger = 'ERP_POC' THEN
            table_name := 'POC';
        ELSIF lv_subledger = 'LEASES' THEN
            table_name := 'LHIN';
        ELSIF lv_subledger = 'MF AP' THEN
            table_name := 'MFAP';
        ELSIF lv_subledger = 'MF AR' THEN
            table_name := 'MFAR';
        ELSIF lv_subledger = 'MF INV' THEN
            table_name := 'MFINV';
        ELSIF lv_subledger = 'PS FA' THEN
            table_name := 'PSFA';
        ELSIF lv_subledger = 'SXE' THEN
            table_name := 'SXE';
        ELSIF lv_subledger = 'TW' THEN
            table_name := 'TW';
        END IF;
logging_insert('PURGE', lv_batch_id, 3, 'Table: '||table_name, NULL, sysdate);
    
        dbms_output.put_line(lv_subledger);
        dbms_output.put_line(table_name);
        dbms_output.put_line('----------------------------------');
        
/*added NVL condition for defect (CTPFS-30362) to handle null ledger name in validation and transform failed records*/
        line_sql_data := 'SELECT
            pline.TRANSACTION_NUMBER as TRANSACTION_NUMBER,
            pline.TRANSACTION_DATE as TRANSACTION_DATE,
            pline.LEDGER as LEDGER,
            pline.subledger as subledger	
        FROM
            wsc_ahcs_int_status_t status,
            WSC_AHCS_TXN_PURGE_LINE_T pline,
            wsc_ahcs_'
                         || table_name
                         || '_txn_header_t header
        WHERE
                header.batch_id = status.batch_id
            AND header.header_id = status.header_id
            AND nvl(header.ledger_name,''NA'') = nvl(pline.ledger,''NA'')
            and status.application = pline.subledger
            AND status.attribute3 = pline.transaction_number
            AND trunc(status.attribute11) = pline.transaction_date
            AND (status.accounting_status = ''CRE_ACC_SUCCESS'')
            and pline.batch_id = '
                         || p_batch_id
                         || '
        group by pline.TRANSACTION_NUMBER ,
            pline.TRANSACTION_DATE ,
            pline.LEDGER ,
            pline.subledger ';
    logging_insert('PURGE', lv_batch_id, 4.1, 'N Purge Eligibility CRE_ACC_SUCCESS Start', NULL, sysdate);
        
        OPEN purge_line_refcur FOR line_sql_data;

        LOOP
            FETCH purge_line_refcur INTO
                lv_transaction_number,
                lv_transaction_date,
                lv_ledger,
                lv_subledger;
            EXIT WHEN purge_line_refcur%notfound;
            dbms_output.put_line(lv_transaction_number
                                 || ','
                                 || lv_transaction_date
                                 || ','
                                 || lv_ledger
                                 || ','
                                 || lv_subledger);

            UPDATE wsc_ahcs_txn_purge_line_t
            SET
                purge_eligible = 'N',
--            purge_status_message = 'Transaction record(s) are in CRE_ACC_SUCCESS',
            purge_status_message = 'Transaction can’t be purged as its successfully accounted in AHCS',
            purge_status = 'ERROR'
            WHERE
                    batch_id = p_batch_id
                AND ledger = lv_ledger
                AND transaction_number = lv_transaction_number
                AND transaction_date = lv_transaction_date
                AND subledger = lv_subledger;

        END LOOP;

        CLOSE purge_line_refcur;
/*added NVL condition for defect (CTPFS-30362) to handle null ledger name in validation and transform failed records*/        
        line_sql_data := 'SELECT
            pline.TRANSACTION_NUMBER as TRANSACTION_NUMBER,
            pline.TRANSACTION_DATE as TRANSACTION_DATE,
            pline.LEDGER as LEDGER,
            pline.subledger as subledger	
        FROM
            wsc_ahcs_int_status_t status,
            WSC_AHCS_TXN_PURGE_LINE_T pline,
            wsc_ahcs_'
                         || table_name
                         || '_txn_header_t header
        WHERE
                header.batch_id = status.batch_id
            AND header.header_id = status.header_id
            AND nvl(header.ledger_name,''NA'') = nvl(pline.ledger,''NA'')
            and status.application = pline.subledger
            AND status.attribute3 = pline.transaction_number
            AND trunc(status.attribute11) = pline.transaction_date
            AND (status.accounting_status <> ''CRE_ACC_SUCCESS'' or status.accounting_status is null)
            and pline.batch_id = '
                         || p_batch_id
                         || '
        group by pline.TRANSACTION_NUMBER ,
            pline.TRANSACTION_DATE ,
            pline.LEDGER ,
            pline.subledger ';
    logging_insert('PURGE', lv_batch_id, 4, 'Purge Eligibility Check Start', NULL, sysdate);
        
        OPEN purge_line_refcur FOR line_sql_data;

        LOOP
            FETCH purge_line_refcur INTO
                lv_transaction_number,
                lv_transaction_date,
                lv_ledger,
                lv_subledger;
            EXIT WHEN purge_line_refcur%notfound;
            dbms_output.put_line(lv_transaction_number
                                 || ','
                                 || lv_transaction_date
                                 || ','
                                 || lv_ledger
                                 || ','
                                 || lv_subledger);

            UPDATE wsc_ahcs_txn_purge_line_t
            SET
                purge_eligible = 'Y',
                purge_status_message = '',
                purge_status = 'IN PROCESS'
            WHERE
                    batch_id = p_batch_id
                AND ledger = lv_ledger
                AND transaction_number = lv_transaction_number
                AND transaction_date = lv_transaction_date
                AND subledger = lv_subledger;

        END LOOP;

        CLOSE purge_line_refcur;
        
        
        
        
        
    logging_insert('PURGE', lv_batch_id, 4.2, 'Update N Start', NULL, sysdate);
    
        UPDATE wsc_ahcs_txn_purge_line_t
        SET
            purge_eligible = 'N',
            purge_status_message = 'No such data found for ledger, subledger, transaction number and transaction date combination.',
--            purge_status_message = 'Transaction record(s) are in CRE_ACC_SUCCESS or currently not present in the table',
            purge_status = 'ERROR'
        WHERE
                batch_id = p_batch_id
            AND purge_eligible IS NULL;

        COMMIT;
    logging_insert('PURGE', lv_batch_id, 5, 'Purge Eligibility Check End', NULL, sysdate);
/*added NVL condition for defect (CTPFS-30362) to handle null ledger name in validation and transform failed records*/        
        line_sql := '
        delete from wsc_ahcs_'
                    || table_name
                    || '_txn_line_t  line
where 
exists 
(select 1 from wsc_ahcs_'
                    || table_name
                    || '_txn_header_t header,wsc_ahcs_int_status_t status,wsc_ahcs_txn_purge_line_t pl
where (status.accounting_status <> ''CRE_ACC_SUCCESS'' or status.accounting_status is null)
and pl.purge_eligible= ''Y'' 
and pl.batch_id ='
                    || lv_batch_id
                    || ' 
and header.batch_id = status.batch_id
and header.header_id = status.header_id
and status.batch_id = line.batch_id
and status.header_id = line.header_id
and status.line_id = line.line_id

and nvl(header.LEDGER_NAME,''NA'') = nvl(PL.LEDGER,''NA'')
and header.TRANSACTION_NUMBER = PL.TRANSACTION_NUMBER

and status.application = pl.subledger
AND trunc(status.attribute11) = pl.transaction_date
AND (status.accounting_status <> ''CRE_ACC_SUCCESS'' or status.accounting_status is null)
)';

--AND status.attribute3 = pl.transaction_number

--and header.LEDGER_NAME = PL.LEDGER
--and header.TRANSACTION_NUMBER = PL.TRANSACTION_NUMBER
--and header.TRANSACTION_DATE = PL.TRANSACTION_DATE
--and STATUS.application = PL.SUBLEDGER

logging_insert('PURGE', lv_batch_id, 6, 'Line SQL: '||line_sql, NULL, sysdate);
    
        BEGIN
            EXECUTE IMMEDIATE line_sql;
        EXCEPTION
            WHEN OTHERS THEN
                lv_sqlerrm := substr(sqlerrm, 1, 250);
                UPDATE wsc_ahcs_txn_purge_line_t
                SET
                    purge_status = 'ERROR',
                    purge_status_message = purge_status_message
                                           || 'Error in LINE Table:'
                                           || lv_sqlerrm
                                           || ' || '
                WHERE
                    batch_id = lv_batch_id;

        END;

        COMMIT;
        dbms_output.put_line('-------------------');
        
        dbms_output.put_line('-------------------');
/*added NVL condition for defect (CTPFS-30362) to handle null ledger name in validation and transform failed records*/
        hdr_sql := 'delete from wsc_ahcs_'
                   || table_name
                   || '_txn_header_t header
where 
exists 
(select 1 from wsc_ahcs_INT_STATUS_t  STATUS,wsc_ahcs_txn_purge_line_t pl
where (status.accounting_status <> ''CRE_ACC_SUCCESS'' or status.accounting_status is null)
and pl.purge_eligible= ''Y''
and pl.batch_id ='
                   || lv_batch_id
                   || ' 
and header.batch_id = status.batch_id
and header.header_id = status.header_id
and nvl(header.LEDGER_NAME,''NA'') = nvl(PL.LEDGER,''NA'')
and header.TRANSACTION_NUMBER = PL.TRANSACTION_NUMBER

and STATUS.application = PL.SUBLEDGER
AND trunc(status.attribute11) = pl.transaction_date
AND (status.accounting_status <> ''CRE_ACC_SUCCESS'' or status.accounting_status is null)
)';

--and header.TRANSACTION_DATE = PL.TRANSACTION_DATE

logging_insert('PURGE', lv_batch_id, 8, 'Header SQL: '||hdr_sql, NULL, sysdate);

        BEGIN
            EXECUTE IMMEDIATE hdr_sql;
        EXCEPTION
            WHEN OTHERS THEN
                lv_sqlerrm := substr(sqlerrm, 1, 250);
                UPDATE wsc_ahcs_txn_purge_line_t
                SET
                    purge_status = 'ERROR',
                    purge_status_message = purge_status_message
                                           || 'Error in HEADER Table:'
                                           || lv_sqlerrm
                                           || ' || '
                WHERE
                    batch_id = lv_batch_id;

        END;

        COMMIT;
        
        status_sql := 'delete from wsc_ahcs_INT_STATUS_t  STATUS
where 
exists 
(select 1 from wsc_ahcs_txn_purge_line_t pl
where (status.accounting_status <> ''CRE_ACC_SUCCESS'' or status.accounting_status is null)
and pl.purge_eligible= ''Y''
and pl.batch_id ='
                      || lv_batch_id
                      || ' 
and status.attribute3 = PL.TRANSACTION_NUMBER
and trunc(status.attribute11) = PL.TRANSACTION_DATE
and STATUS.application = PL.SUBLEDGER
)';
logging_insert('PURGE', lv_batch_id, 7, 'Status SQL: '||status_sql, NULL, sysdate);

        BEGIN
            EXECUTE IMMEDIATE status_sql;
        EXCEPTION
            WHEN OTHERS THEN
                lv_sqlerrm := substr(sqlerrm, 1, 250);
                UPDATE wsc_ahcs_txn_purge_line_t
                SET
                    purge_status = 'ERROR',
                    purge_status_message = purge_status_message
                                           || 'Error in STATUS Table:'
                                           || lv_sqlerrm
                                           || ' || '
                WHERE
                    batch_id = lv_batch_id;

        END;

        COMMIT;
        dbms_output.put_line('-------------------');
        UPDATE wsc_ahcs_txn_purge_line_t
        SET
--            purge_eligible = 'Y',
            purge_status_message = 'Transaction successfully purged',
            purge_status = 'SUCCESS'
        WHERE
                batch_id = p_batch_id
            AND purge_eligible = 'Y';

        COMMIT;
logging_insert('PURGE', lv_batch_id, 9, 'Purge End', NULL, sysdate);
    EXCEPTION
        WHEN OTHERS THEN
            lv_sqlerrm := substr(sqlerrm, 1, 500);
            UPDATE wsc_ahcs_txn_purge_line_t
            SET
                purge_status = 'ERROR',
                purge_status_message = purge_status_message
                                       || 'Error :'
                                       || lv_sqlerrm
                                       || ' || '
            WHERE
                batch_id = lv_batch_id;

            COMMIT;
    END;

END;
/