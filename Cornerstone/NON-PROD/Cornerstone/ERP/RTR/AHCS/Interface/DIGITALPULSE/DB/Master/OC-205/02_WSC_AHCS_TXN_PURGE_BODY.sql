CREATE OR REPLACE PACKAGE BODY FININT.WSC_AHCS_TXN_PURGE_PKG
AS
    PROCEDURE delete_data_system (p_batch_id NUMBER)
    IS
        lv_batch_id             NUMBER;
        line_sql                VARCHAR2 (1000);
        status_sql              VARCHAR2 (1000);
        hdr_sql                 VARCHAR2 (1000);
        purge_line_refcur       SYS_REFCURSOR;
        lv_transaction_number   VARCHAR2 (100);
        lv_transaction_date     DATE;
        lv_ledger               VARCHAR2 (100);
        lv_subledger            VARCHAR2 (10);
        line_sql_data           VARCHAR2 (1000);
        table_name              VARCHAR2 (10);
        lv_sqlerrm              VARCHAR (2000);
    BEGIN
        lv_batch_id := p_batch_id;

        logging_insert ('PURGE',
                        lv_batch_id,
                        1,
                        'Purge Start',
                        NULL,
                        SYSDATE);

        SELECT DISTINCT subledger
          INTO lv_subledger
          FROM wsc_ahcs_txn_purge_hdr_t
         WHERE batch_id = lv_batch_id;

        logging_insert ('PURGE',
                        lv_batch_id,
                        2,
                        'lv_subledger: ' || lv_subledger,
                        NULL,
                        SYSDATE);


        IF lv_subledger = 'CENTRAL'
        THEN
            table_name := 'CENTRAL';
        ELSIF lv_subledger = 'CLOUDPAY'
        THEN
            table_name := 'CP';
        ELSIF lv_subledger = 'CONCUR'
        THEN
            table_name := 'CNCR';
        ELSIF lv_subledger = 'EBS AP'
        THEN
            table_name := 'AP';
        ELSIF lv_subledger = 'EBS AR'
        THEN
            table_name := 'AR';
        ELSIF lv_subledger = 'EBS FA'
        THEN
            table_name := 'FA';
        ELSIF lv_subledger = 'ECLIPSE'
        THEN
            table_name := 'ECLIPSE';
        ELSIF lv_subledger = 'ERP_POC'
        THEN
            table_name := 'POC';
        ELSIF lv_subledger = 'LEASES'
        THEN
            table_name := 'LHIN';
        ELSIF lv_subledger = 'MF AP'
        THEN
            table_name := 'MFAP';
        ELSIF lv_subledger = 'MF AR'
        THEN
            table_name := 'MFAR';
        ELSIF lv_subledger = 'MF INV'
        THEN
            table_name := 'MFINV';
        ELSIF lv_subledger = 'PS FA'
        THEN
            table_name := 'PSFA';
        ELSIF lv_subledger = 'SXE'
        THEN
            table_name := 'SXE';
        ELSIF lv_subledger = 'TW'
        THEN
            table_name := 'TW';
        END IF;

        logging_insert ('PURGE',
                        lv_batch_id,
                        3,
                        'Table: ' || table_name,
                        NULL,
                        SYSDATE);

        DBMS_OUTPUT.put_line (lv_subledger);
        DBMS_OUTPUT.put_line (table_name);
        DBMS_OUTPUT.put_line ('----------------------------------');

        /*added NVL condition for defect (CTPFS-30362) to handle null ledger name in validation and transform failed records*/
        line_sql_data := 'SELECT
            pline.TRANSACTION_NUMBER as TRANSACTION_NUMBER,
            pline.TRANSACTION_DATE as TRANSACTION_DATE,
            pline.LEDGER as LEDGER,
            pline.subledger as subledger	
        FROM
            wsc_ahcs_int_status_t status,
            WSC_AHCS_TXN_PURGE_LINE_T pline,
            wsc_ahcs_' || table_name || '_txn_header_t header
        WHERE
                header.batch_id = status.batch_id
            AND header.header_id = status.header_id
            AND nvl(header.ledger_name,''NA'') = nvl(pline.ledger,''NA'')
            and status.application = pline.subledger
            AND status.attribute3 = pline.transaction_number
            AND trunc(status.attribute11) = pline.transaction_date
            AND (status.accounting_status = ''CRE_ACC_SUCCESS'')
            and pline.batch_id = ' || p_batch_id || '
        group by pline.TRANSACTION_NUMBER ,
            pline.TRANSACTION_DATE ,
            pline.LEDGER ,
            pline.subledger ';
        logging_insert ('PURGE',
                        lv_batch_id,
                        4.1,
                        'N Purge Eligibility CRE_ACC_SUCCESS Start',
                        NULL,
                        SYSDATE);

        OPEN purge_line_refcur FOR line_sql_data;

        LOOP
            FETCH purge_line_refcur
                INTO lv_transaction_number,
                     lv_transaction_date,
                     lv_ledger,
                     lv_subledger;

            EXIT WHEN purge_line_refcur%NOTFOUND;
            DBMS_OUTPUT.put_line (
                   lv_transaction_number
                || ','
                || lv_transaction_date
                || ','
                || lv_ledger
                || ','
                || lv_subledger);

            UPDATE wsc_ahcs_txn_purge_line_t
               SET purge_eligible = 'N',
                   --            purge_status_message = 'Transaction record(s) are in CRE_ACC_SUCCESS',
                   purge_status_message =
                       'Transaction can�t be purged as its successfully accounted in AHCS',
                   purge_status = 'ERROR'
             WHERE     batch_id = p_batch_id
                   AND ledger = lv_ledger
                   AND transaction_number = lv_transaction_number
                   AND transaction_date = lv_transaction_date
                   AND subledger = lv_subledger;
        END LOOP;

        CLOSE purge_line_refcur;

        /*added NVL condition for defect (CTPFS-30362) to handle null ledger name in validation and transform failed records*/
        line_sql_data :=
               'SELECT
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
        logging_insert ('PURGE',
                        lv_batch_id,
                        4,
                        'Purge Eligibility Check Start',
                        NULL,
                        SYSDATE);

        OPEN purge_line_refcur FOR line_sql_data;

        LOOP
            FETCH purge_line_refcur
                INTO lv_transaction_number,
                     lv_transaction_date,
                     lv_ledger,
                     lv_subledger;

            EXIT WHEN purge_line_refcur%NOTFOUND;
            DBMS_OUTPUT.put_line (
                   lv_transaction_number
                || ','
                || lv_transaction_date
                || ','
                || lv_ledger
                || ','
                || lv_subledger);

            UPDATE wsc_ahcs_txn_purge_line_t
               SET purge_eligible = 'Y',
                   purge_status_message = '',
                   purge_status = 'IN PROCESS'
             WHERE     batch_id = p_batch_id
                   AND ledger = lv_ledger
                   AND transaction_number = lv_transaction_number
                   AND transaction_date = lv_transaction_date
                   AND subledger = lv_subledger;
        END LOOP;

        CLOSE purge_line_refcur;



        logging_insert ('PURGE',
                        lv_batch_id,
                        4.2,
                        'Update N Start',
                        NULL,
                        SYSDATE);

        UPDATE wsc_ahcs_txn_purge_line_t
           SET purge_eligible = 'N',
               purge_status_message =
                   'No such data found for ledger, subledger, transaction number and transaction date combination.',
               --            purge_status_message = 'Transaction record(s) are in CRE_ACC_SUCCESS or currently not present in the table',
               purge_status = 'ERROR'
         WHERE batch_id = p_batch_id AND purge_eligible IS NULL;

        COMMIT;
        logging_insert ('PURGE',
                        lv_batch_id,
                        5,
                        'Purge Eligibility Check End',
                        NULL,
                        SYSDATE);
        /*added NVL condition for defect (CTPFS-30362) to handle null ledger name in validation and transform failed records*/
        line_sql :=
               '
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

        logging_insert ('PURGE',
                        lv_batch_id,
                        6,
                        'Line SQL: ' || line_sql,
                        NULL,
                        SYSDATE);

        BEGIN
            EXECUTE IMMEDIATE line_sql;
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_sqlerrm := SUBSTR (SQLERRM, 1, 250);

                UPDATE wsc_ahcs_txn_purge_line_t
                   SET purge_status = 'ERROR',
                       purge_status_message =
                              purge_status_message
                           || 'Error in LINE Table:'
                           || lv_sqlerrm
                           || ' || '
                 WHERE batch_id = lv_batch_id;
        END;

        COMMIT;
        DBMS_OUTPUT.put_line ('-------------------');

        DBMS_OUTPUT.put_line ('-------------------');
        /*added NVL condition for defect (CTPFS-30362) to handle null ledger name in validation and transform failed records*/
        hdr_sql :=
               'delete from wsc_ahcs_'
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

        logging_insert ('PURGE',
                        lv_batch_id,
                        8,
                        'Header SQL: ' || hdr_sql,
                        NULL,
                        SYSDATE);

        BEGIN
            EXECUTE IMMEDIATE hdr_sql;
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_sqlerrm := SUBSTR (SQLERRM, 1, 250);

                UPDATE wsc_ahcs_txn_purge_line_t
                   SET purge_status = 'ERROR',
                       purge_status_message =
                              purge_status_message
                           || 'Error in HEADER Table:'
                           || lv_sqlerrm
                           || ' || '
                 WHERE batch_id = lv_batch_id;
        END;

        COMMIT;

        status_sql :=
               'delete from wsc_ahcs_INT_STATUS_t  STATUS
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
        logging_insert ('PURGE',
                        lv_batch_id,
                        7,
                        'Status SQL: ' || status_sql,
                        NULL,
                        SYSDATE);

        BEGIN
            EXECUTE IMMEDIATE status_sql;
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_sqlerrm := SUBSTR (SQLERRM, 1, 250);

                UPDATE wsc_ahcs_txn_purge_line_t
                   SET purge_status = 'ERROR',
                       purge_status_message =
                              purge_status_message
                           || 'Error in STATUS Table:'
                           || lv_sqlerrm
                           || ' || '
                 WHERE batch_id = lv_batch_id;
        END;

        COMMIT;
        DBMS_OUTPUT.put_line ('-------------------');

        UPDATE wsc_ahcs_txn_purge_line_t
           SET                             --            purge_eligible = 'Y',
               purge_status_message = 'Transaction successfully purged',
               purge_status = 'SUCCESS'
         WHERE batch_id = p_batch_id AND purge_eligible = 'Y';

        COMMIT;
        logging_insert ('PURGE',
                        lv_batch_id,
                        9,
                        'Purge End',
                        NULL,
                        SYSDATE);
    EXCEPTION
        WHEN OTHERS
        THEN
            lv_sqlerrm := SUBSTR (SQLERRM, 1, 500);

            UPDATE wsc_ahcs_txn_purge_line_t
               SET purge_status = 'ERROR',
                   purge_status_message =
                          purge_status_message
                       || 'Error :'
                       || lv_sqlerrm
                       || ' || '
             WHERE batch_id = lv_batch_id;

            COMMIT;
    END;


    /* procedure added for OC-205 Purge for LSI source */
    PROCEDURE delete_data_lsi (p_batch_id NUMBER)
    IS
        lv_transaction_number   VARCHAR2 (100);
        lv_transaction_date     DATE;
        lv_ledger               VARCHAR2 (100);
        lv_subledger            VARCHAR2 (100);
        lv_header_batch_id      VARCHAR2 (100);
        lv_header_header_id     VARCHAR2 (100);
        lv_acc_status           VARCHAR2 (100);
        --p_batch_id              NUMBER := 11;
        lv_errm                 VARCHAR (1000);

        CURSOR purge_data_cursor IS
              SELECT pline.TRANSACTION_NUMBER,
                     pline.TRANSACTION_DATE,
                     pline.LEDGER,
                     pline.subledger,
                     status.accounting_status,
                     header.BATCH_ID      header_batch_id,
                     header.header_id     header_header_id
                FROM wsc_ahcs_int_status_t               status,
                     WSC_AHCS_TXN_PURGE_LINE_T           pline,
                     WSC_AHCS_LSI_NETTING_ENTRY_HEADERS_T header
               WHERE     1 = 1
                     AND header.batch_id(+) = status.batch_id
                     AND header.header_id(+) = status.header_id
                     AND NVL (header.ledger_name, 'NA') =
                         NVL (pline.ledger, 'NA')
                     AND status.application = pline.subledger
                     AND status.attribute3 = pline.transaction_number
                     AND TRUNC (status.attribute11) = pline.transaction_date
                     AND pline.batch_id = p_batch_id
            GROUP BY pline.TRANSACTION_NUMBER,
                     pline.TRANSACTION_DATE,
                     pline.LEDGER,
                     pline.subledger,
                     status.accounting_status,
                     header.BATCH_ID,
                     header.header_id,
                     pline.line_id;
    BEGIN
        logging_insert ('PURGE_LSI',
                        p_batch_id,
                        1,
                        'Purge Start',
                        NULL,
                        SYSDATE);

        OPEN purge_data_cursor;

        LOOP
            FETCH purge_data_cursor
                INTO lv_transaction_number,
                     lv_transaction_date,
                     lv_ledger,
                     lv_subledger,
                     lv_acc_status,
                     lv_header_batch_id,
                     lv_header_header_id;

            EXIT WHEN purge_data_cursor%NOTFOUND;
            DBMS_OUTPUT.put_line (
                   lv_transaction_number
                || ','
                || lv_transaction_date
                || ','
                || lv_ledger
                || ','
                || lv_subledger
                || ','
                || lv_acc_status);


            logging_insert ('PURGE_LSI',
                            p_batch_id,
                            2,
                            'lv_acc_status: ' || lv_acc_status,
                            NULL,
                            SYSDATE);

            CASE
                WHEN lv_acc_status = 'CRE_ACC_SUCCESS'
                THEN
                    -- Validation for those transactions are NOT elegeible for purging
                    UPDATE wsc_ahcs_txn_purge_line_t
                       SET purge_eligible = 'N',
                           purge_status_message =
                               'Transaction can�t be purged as its successfully accounted in AHCS',
                           purge_status = 'ERROR'
                     WHERE     batch_id = p_batch_id
                           AND ledger = lv_ledger
                           AND transaction_number = lv_transaction_number
                           AND transaction_date = lv_transaction_date;

                    DBMS_OUTPUT.put_line ('rowcount: ' || SQL%ROWCOUNT);
                -- Validation for those transactions are elegeible for purging
                WHEN lv_acc_status = 'CRE_ACC_ERROR' OR lv_acc_status IS NULL
                THEN
                    UPDATE wsc_ahcs_txn_purge_line_t
                       SET purge_eligible = 'Y',
                           purge_status_message = NULL,
                           purge_status = 'IN PROCESS',
                           ATTRIBUTE1 = lv_header_batch_id,
                           ATTRIBUTE2 = lv_header_header_id
                     WHERE     batch_id = p_batch_id
                           AND ledger = lv_ledger
                           AND transaction_number = lv_transaction_number
                           AND transaction_date = lv_transaction_date
                           AND subledger = lv_subledger;

                    DBMS_OUTPUT.put_line ('rowcount: ' || SQL%ROWCOUNT);
                -- Validation for accounting status not expected
                ELSE
                    UPDATE wsc_ahcs_txn_purge_line_t
                       SET purge_eligible = 'N',
                           purge_status_message = 'ERROR Accounting Status not expected',
                           purge_status =
                               'ERROR',
                           ATTRIBUTE1 = lv_header_batch_id,
                           ATTRIBUTE2 = lv_header_header_id
                     WHERE     batch_id = p_batch_id
                           AND ledger = lv_ledger
                           AND transaction_number = lv_transaction_number
                           AND transaction_date = lv_transaction_date
                           AND subledger = lv_subledger;
            END CASE;
        END LOOP;

        CLOSE purge_data_cursor;

        COMMIT;

        logging_insert ('PURGE_LSI',
                        p_batch_id,
                        3,
                        'After close cursor',
                        NULL,
                        SYSDATE);


        -- update purge table lines when data not found
        UPDATE wsc_ahcs_txn_purge_line_t
           SET purge_eligible = 'N',
               purge_status_message =
                   'No such data found for ledger, subledger, transaction number and transaction date combination.',
               purge_status = 'ERROR'
         WHERE batch_id = p_batch_id AND purge_eligible IS NULL;

        COMMIT;

        logging_insert ('PURGE_LSI',
                        p_batch_id,
                        4,
                        'Purge Eligibility Check End',
                        NULL,
                        SYSDATE);

        logging_insert ('PURGE_LSI',
                        p_batch_id,
                        5,
                        'Delete... start',
                        NULL,
                        SYSDATE);

        -- Delete from status
        BEGIN
            DELETE FROM
                WSC_AHCS_INT_STATUS_T STATUS
                  WHERE EXISTS
                            (SELECT 1
                               FROM wsc_ahcs_txn_purge_line_t pl
                              WHERE     (   status.accounting_status <>
                                            'CRE_ACC_SUCCESS'
                                         OR status.accounting_status IS NULL)
                                    AND pl.purge_eligible = 'Y'
                                    AND pl.batch_id = p_batch_id
                                    AND status.attribute3 =
                                        PL.TRANSACTION_NUMBER
                                    AND TRUNC (status.attribute11) =
                                        PL.TRANSACTION_DATE
                                    AND STATUS.application = PL.SUBLEDGER);

            DBMS_OUTPUT.put_line ('rowcount: ' || SQL%ROWCOUNT);
            COMMIT;
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_errm :=
                    SUBSTR (
                           lv_errm
                        || ',wsc_ahcs_int_status_t, SQLERRM: '
                        || SQLERRM,
                        1,
                        1000);

                UPDATE wsc_ahcs_txn_purge_line_t pl
                   SET pl.purge_status = 'ERROR',
                       pl.purge_status_message =
                           SUBSTR (
                                  pl.purge_status_message
                               || 'Error :'
                               || lv_errm,
                               1,
                               1000)
                 WHERE pl.batch_id = p_batch_id;
                 COMMIT;
        END;

        -- Delete from headers
        BEGIN
            DELETE FROM
                wsc_ahcs_lsi_netting_entry_headers_t hnet
                  WHERE EXISTS
                            (SELECT 1
                               FROM wsc_ahcs_txn_purge_line_t pl
                              WHERE     pl.purge_eligible = 'Y'
                                    AND pl.batch_id = p_batch_id
                                    AND hnet.transaction_number =
                                        PL.transaction_number
                                    AND hnet.batch_id = ATTRIBUTE1
                                    AND hnet.header_id = ATTRIBUTE2);

            DBMS_OUTPUT.put_line ('rowcount: ' || SQL%ROWCOUNT);
            COMMIT;
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_errm :=
                    SUBSTR (
                           lv_errm
                        || ',wsc_ahcs_lsi_netting_entry_headers_t, SQLERRM: '
                        || SQLERRM,
                        1,
                        1000);

                UPDATE wsc_ahcs_txn_purge_line_t pl
                   SET pl.purge_status = 'ERROR',
                       pl.purge_status_message =
                           SUBSTR (
                                  pl.purge_status_message
                               || 'Error :'
                               || lv_errm,
                               1,
                               1000)
                 WHERE pl.batch_id = p_batch_id;
                 COMMIT;
        END;



        --                Delete from lines
        BEGIN
            DELETE FROM
                WSC_AHCS_LSI_NETTING_ENTRY_T lnet
                  WHERE EXISTS
                            (SELECT 1
                               FROM wsc_ahcs_txn_purge_line_t pl
                              WHERE     pl.purge_eligible = 'Y'
                                    AND pl.batch_id = p_batch_id
                                    AND lnet.transaction_number =
                                        pl.transaction_number
                                    AND lnet.batch_id = ATTRIBUTE1
                                    AND lnet.header_id = ATTRIBUTE2
                                    AND lnet.ledger = pl.ledger);

            DBMS_OUTPUT.put_line ('rowcount: ' || SQL%ROWCOUNT);
            COMMIT;
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_errm :=
                    SUBSTR (
                           lv_errm
                        || ',wsc_ahcs_lsi_netting_entry_t, SQLERRM: '
                        || SQLERRM,
                        1,
                        1000);

                UPDATE wsc_ahcs_txn_purge_line_t pl
                   SET pl.purge_status = 'ERROR',
                       pl.purge_status_message =
                           SUBSTR (
                                  pl.purge_status_message
                               || 'Error :'
                               || lv_errm,
                               1,
                               1000)
                 WHERE pl.batch_id = p_batch_id;
                 COMMIT;
        END;

        logging_insert ('PURGE_LSI',
                        p_batch_id,
                        6,
                        'Delete... end',
                        NULL,
                        SYSDATE);

        -- Update table to indicate transaction is purged
        UPDATE wsc_ahcs_txn_purge_line_t
           SET purge_status_message = 'Transaction successfully purged',
               purge_status = 'SUCCESS'
         WHERE batch_id = p_batch_id AND purge_eligible = 'Y';

        COMMIT;
        logging_insert ('PURGE_LSI',
                        p_batch_id,
                        7,
                        'Purge LSI process End',
                        NULL,
                        SYSDATE);
    EXCEPTION
        WHEN OTHERS
        THEN
            lv_errm :=
                SUBSTR (lv_errm || ',main when others, SQLERRM: ' || SQLERRM,
                        1,
                        1000);

            UPDATE wsc_ahcs_txn_purge_line_t pl
               SET pl.purge_status = 'ERROR',
                   pl.purge_status_message =
                       SUBSTR (
                           pl.purge_status_message || 'Error :' || lv_errm,
                           1,
                           1000)
             WHERE pl.batch_id = p_batch_id;

            COMMIT;
    END;                                                      -- lsi procedure
END;                                                                -- end pkg
/
