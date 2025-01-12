/* Formatted on 10/26/2023 2:03:46 PM (QP5 v5.300) */
CREATE OR REPLACE PACKAGE BODY APPS.XXAP_AHCS_EXTRACT
AS
    -- -----------------------------------------------------------------------------
    -- ------------------------------------------------------------------------- --
    --  Change Log:
    --  Version       Date       Author         Description
    -- -------- ------------ -------------  --------------------------------------
    --    1.0   15-Jul-2021  Laxman M       CornerStone Project - IINT002-Wesco EBS AP Inbound to AHCS
    --    1.1   25-Feb-2022  Laxman M       Added for Jira CTPFS-4342
    --    1.2   26-Oct-2022  Laxman M       Fixed header line FCLOSE Issues
    -- ------------------------------------------------------------------------- --

    PROCEDURE email_error_notification (p_message        IN VARCHAR2,
                                        p_in_chr_email      VARCHAR2)
    IS
        l_chr_sender          VARCHAR2 (50) := 'alerts@wescodist.com';
        l_chr_email           VARCHAR2 (200);
        l_chr_email_subject   VARCHAR2 (500) := NULL;
        l_num_priority        NUMBER (1) := 1; -- 1 high, 2 medium, 3 normal --
        l_chr_email_body      VARCHAR2 (4000);
        l_chr_instance_name   VARCHAR2 (100);
    BEGIN
        SELECT instance_name INTO l_chr_instance_name FROM v$instance;

        IF (p_in_chr_email IS NOT NULL)
        THEN
            l_chr_email := p_in_chr_email;
        ELSE
            BEGIN
                SELECT description
                  INTO l_chr_email
                  FROM fnd_lookup_values
                 WHERE     lookup_type = 'XXAU_AHCS_ERROR_FEED_DETAILS'
                       AND language = 'US'
                       AND enabled_flag = 'Y'
                       AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                       AND NVL (end_date_active, SYSDATE)
                       AND lookup_code = 'ERROR_NOTIFY_EMAIL'; --'XXAP_ERROR_EMAIL';
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line (
                        apps.fnd_file.LOG,
                        'Email Details are not available in lookup XXAU_AHCS_ERROR_FEED_DETAILS hence not sending any email');
                    RETURN;
            END;
        END IF;

        fnd_file.put_line (apps.fnd_file.LOG, 'Email: ' || l_chr_email);

        l_chr_email_subject :=
               l_chr_instance_name
            || ' - AP Extract Program from EBS to AHCS Failure/Warning alert '
            || TO_CHAR (SYSDATE, 'mm/dd/yyyy hh:mi:ss am');
        l_chr_email_body :=
               p_message
            || CHR (10)
            || CHR (10)
            || ' Request ID: '
            || fnd_global.conc_request_id
            || CHR (10)
            || CHR (10)
            || ' ** Please Contact System Support **';

        UTL_MAIL.SEND (sender       => l_chr_sender,
                       recipients   => l_chr_email,
                       subject      => l_chr_email_subject,
                       MESSAGE      => l_chr_email_body,
                       priority     => l_num_priority);
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line (fnd_file.LOG,
                               'Error while sending email: ' || SQLERRM);
    END email_error_notification;

    PROCEDURE purge_old_stage_data
    IS
        l_num_purge_days   NUMBER;
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        BEGIN
            SELECT tag
              INTO l_num_purge_days
              FROM fnd_lookup_values
             WHERE     lookup_type = 'XXAU_AHCS_ERROR_FEED_DETAILS'
                   AND language = 'US'
                   AND enabled_flag = 'Y'
                   AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                   AND NVL (end_date_active, SYSDATE)
                   AND lookup_code = 'MAX_PURGE_DAYS';
        EXCEPTION
            WHEN OTHERS
            THEN
                l_num_purge_days := 365;
                fnd_file.put_line (
                    fnd_file.LOG,
                    'Purge Days in Lookup XXAU_AHCS_ERROR_FEED_DETAILS is  not defined so considering as 365 days');
        END;

        fnd_file.put_line (fnd_file.LOG, 'Purge Days :' || l_num_purge_days);


        DELETE FROM xxwes_ap_ahcs_hdr_stg
              WHERE creation_Date < SYSDATE - l_num_purge_days;

        fnd_file.put_line (fnd_file.LOG,
                           'No. of Header records purged: ' || SQL%ROWCOUNT);

        DELETE FROM xxwes_ap_ahcs_line_stg
              WHERE creation_Date < SYSDATE - l_num_purge_days;

        fnd_file.put_line (fnd_file.LOG,
                           'No. of Line records purged: ' || SQL%ROWCOUNT);

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line (
                fnd_file.LOG,
                '*****Unexpected error while purging data: ' || SQLERRM);
            ROLLBACK;
    END purge_old_stage_data;

    PROCEDURE extract_daily_records (p_out_err_msg             OUT VARCHAR2,
                                     p_out_ret_code            OUT NUMBER,
                                     p_in_run_mode          IN     VARCHAR2,
                                     p_in_run_date_from     IN     VARCHAR2,
                                     p_in_date_from_exsts   IN     VARCHAR2,
                                     p_in_run_date_to       IN     VARCHAR2,
                                     p_in_period            IN     VARCHAR2,
                                     p_in_chr_err_email     IN     VARCHAR2,
                                     p_no_params_check      IN     VARCHAR2,
                                     p_outfile_directory    IN     VARCHAR2)
    IS
        l_chr_file_name            VARCHAR2 (50)
            := 'EBS_AP_' || TO_CHAR (SYSDATE, 'YYYYMMDD_HH24MISS'); --Added for Jira CTPFS-4342
        l_chr_hdr_file_name        VARCHAR2 (50) := l_chr_file_name || '.HDR';
        l_chr_line_file_name       VARCHAR2 (50) := l_chr_file_name || '.LIN';
        l_chr_ctl_hdr_file_name    VARCHAR2 (50)
            :=    'EBS_AP_CTL_'
               || TO_CHAR (SYSDATE, 'YYYYMMDD_HH24MISS')
               || '.HDR';
        l_chr_ctl_line_file_name   VARCHAR2 (50)
            :=    'EBS_AP_CTL_'
               || TO_CHAR (SYSDATE, 'YYYYMMDD_HH24MISS')
               || '.LIN';
        l_trg_file_name            VARCHAR2 (50) := l_chr_file_name || '.TRG';
        l_hdr_file_handle          UTL_FILE.FILE_TYPE;
        l_line_file_handle         UTL_FILE.FILE_TYPE;
        l_ctl_hdr_file_handle      UTL_FILE.FILE_TYPE;
        l_ctl_line_file_handle     UTL_FILE.FILE_TYPE;
        l_trg_file_handle          UTL_FILE.FILE_TYPE;
        v_message                  VARCHAR (1000) := NULL;
        l_num_ae_header_id         NUMBER := 0;
        l_exc_hdr                  EXCEPTION;
        l_chr_hdr_heading          VARCHAR2 (1000);
        l_chr_line_heading         VARCHAR2 (1000);
        l_num_hdr_count            NUMBER := 0;
        l_num_hdr_total_amt        NUMBER := 0;
        l_num_line_count           NUMBER := 0;
        l_num_line_total_amount    NUMBER := 0;
        l_dt_start_date            DATE;
        l_chr_out_file_dir         VARCHAR2 (50);
        l_chr_bi_out_file_dir      VARCHAR2 (50);
        l_num_max_purge_days       NUMBER := 30;
        l_exc_others               EXCEPTION;
        L_CHR_ERR_MSG              VARCHAR2 (3000);
        l_last_run_date_from       DATE;
        l_last_run_date_to         DATE;
        l_num_days                 NUMBER := 0;
        l_chr_trd_partner_name     po_vendors.vendor_name%TYPE := NULL;
        l_chr_trd_partner_nbr      po_vendors.segment1%TYPE := NULL;
        l_chr_trd_partner_site     po_vendor_sites_all.vendor_site_code%TYPE
                                       := NULL;
        l_num_max_days_back        NUMBER;               --Added for artf71080
        l_num_hdr_ctr              NUMBER := 0;
        l_num_line_ctr             NUMBER := 0;
        l_num_trg_ctr              NUMBER := 0;
        l_chr_ftp_path             VARCHAR2 (200) := NULL;


        CURSOR c_extract_daily (
            p_in_dt_run_date_from      DATE,
            p_in_dt_run_date_to        DATE,
            p_in_chr_run_mode          VARCHAR2,
            p_in_num_max_purge_days    NUMBER)
        IS
            WITH xeh_data
                 AS (SELECT xeh.ae_header_id
                       FROM xla_ae_headers xeh
                      WHERE     1 = 1
                            AND p_in_chr_run_mode IN ('B', 'N')
                            AND xeh.accounting_Date BETWEEN p_in_dt_run_date_from
                                                        AND p_in_dt_run_date_to
                            AND NOT EXISTS
                                    (SELECT 1
                                       FROM xxwes_ap_ahcs_hdr_stg hdr_stg
                                      WHERE     hdr_stg.leg_ae_header_id =
                                                    xeh.ae_header_id
                                            AND hdr_stg.status =
                                                    'SENT TO OIC')
                     UNION
                     SELECT xeh.ae_header_id
                       FROM xla_ae_headers xeh, xxwes_ap_ahcs_hdr_stg hdr_stg
                      WHERE     1 = 1
                            AND p_in_chr_run_mode IN ('B', 'E')
                            AND xeh.ae_header_id = hdr_stg.leg_ae_header_id
                            AND hdr_stg.status = 'ERROR'),
                 xla_data
                 AS (SELECT DISTINCT
                            xte.transaction_number                  source_trn_nbr,
                            'XXAP'                                  source_system,
                            xeh.ae_header_id                        leg_ae_header_id,
                            xe.event_type_code                      event_type,
                            xevt.event_class_code                   event_class,
                            SUM (xel.accounted_dr)
                                OVER (PARTITION BY xeh.ae_header_id)
                                trn_amount,
                            xeh.accounting_Date                     acc_date,
                            SUBSTR (REPLACE (xeh.description, '|', ' '),
                                    1,
                                    1000)
                                header_desc,       --Fixed for Jira CTPFS-1515
                            xeh.je_category_name                    je_category,
                            xeh.gl_transfer_status_code,
                            xel.gl_sl_link_table,
                            xel.gl_sl_link_id,
                            xel.application_id,
                            (  NVL ( (xel.entered_dr), 0)
                             - NVL ( (xel.entered_cr), 0))
                                ent_amt,
                            (  NVL ( (xel.accounted_dr), 0)
                             - NVL ( (xel.accounted_cr), 0))
                                acc_amt,
                            xel.AE_LINE_NUM                         LEG_AE_LINE_NBR,
                            xel.accounting_class_code               acc_class,
                            SUBSTR (REPLACE (xel.description, '|', ' '),
                                    1,
                                    1000)
                                line_desc,         --Fixed for Jira CTPFS-1515
                            xel.currency_code                       default_currency,
                            ROUND (xel.currency_conversion_rate, 4) fx_rate,
                            xel.code_combination_id
                                code_combination_id,
                            DECODE (
                                SIGN (
                                      NVL ( (xel.accounted_dr), 0)
                                    - NVL ( (xel.accounted_cr), 0)),
                                1, 'DR',
                                -1, 'CR',
                                0, 'DR')
                                dr_cr_flag,
                            (SELECT sob.currency_code
                               FROM gl_sets_of_books               sob,
                                    apps.ap_system_parameters_all  asp
                              WHERE     sob.set_of_books_id =
                                            asp.set_of_books_id
                                    AND asp.org_id = xte.security_id_int_1)
                                acc_currency,
                            xte.entity_code,
                            xte.source_id_int_1,
                            xte.ledger_id
                       FROM xla_ae_lines                  xel,
                            xla_ae_headers                xeh,
                            xla_events                    xe,
                            xla_event_types_b             xevt,
                            xla.xla_transaction_entities  xte,
                            xeh_data                      xd
                      WHERE     xte.application_id = 200
                            AND xel.application_id = 200
                            AND xeh.application_id = 200
                            AND xe.application_id = 200
                            AND xevt.event_type_code = xe.event_type_code
                            AND xe.entity_id = xte.entity_id
                            AND xe.event_id = xeh.event_id
                            AND xd.ae_header_id = xeh.ae_header_id
                            AND xel.ae_header_id = xeh.ae_header_id
                            AND xte.entity_code IN
                                    ('AP_INVOICES', 'AP_PAYMENTS')
                            AND xte.entity_id = xeh.entity_id)
              SELECT DISTINCT source_trn_nbr,
                              source_system,
                              leg_ae_header_id,
                              event_type,
                              event_class,
                              trn_amount,
                              acc_date,
                              SUBSTR (header_desc, 1, 1000) header_desc,
                              led.name                    leg_led_name,
                              gjb.name                    je_batch_name,
                              gjh.name                    je_name,
                              xd.je_category,
                              l_chr_file_name             file_name,
                              ent_amt,
                              acc_amt,
                              default_currency,
                              acc_currency,
                              gcc.segment1                leg_seg1,
                              gcc.segment2                leg_seg2,
                              gcc.segment3                leg_seg3,
                              gcc.segment4                leg_seg4,
                              gcc.segment5                leg_seg5,
                              gcc.segment6                leg_seg6,
                              gcc.segment7                leg_seg7,
                              acc_class,
                              dr_cr_flag,
                              LEG_AE_LINE_NBR,
                              gir.je_line_num             JE_LINE_NBR,
                              SUBSTR (line_desc, 1, 1000) line_desc,
                              NVL (fx_rate, 1)            fx_rate,
                              entity_code,
                              source_id_int_1,
                              xd.ledger_id
                FROM xla_data            xd,
                     gl_import_references gir,
                     gl_je_headers       gjh,
                     gl_je_batches       gjb,
                     gl_ledgers          led,
                     gl_code_combinations gcc
               WHERE     xd.GL_SL_LINK_ID = gir.GL_SL_LINK_ID
                     AND xd.GL_SL_LINK_TABLE = gir.GL_SL_LINK_TABLE
                     AND gjh.je_header_id = gir.je_header_id
                     AND gjb.je_batch_id = gir.je_batch_id
                     AND led.ledger_id = gjh.ledger_id
                     AND gjh.status = 'P'
                     AND gcc.code_combination_id = xd.code_combination_id
            ORDER BY leg_ae_header_id;

        CURSOR fetch_hdr_details (p_in_chr_filename IN VARCHAR2)
        IS
            SELECT SOURCE_TRN_NBR,
                   SOURCE_SYSTEM,
                   LEG_AE_HEADER_ID,
                   TRD_PARTNER_NAME,
                   TRD_PARTNER_NBR,
                   TRD_PARTNER_SITE,
                   EVENT_TYPE,
                   EVENT_CLASS,
                   TRN_AMOUNT,
                   ACC_DATE,
                   HEADER_DESC,
                   LEG_LED_NAME,
                   JE_BATCH_NAME,
                   JE_NAME,
                   JE_CATEGORY,
                   FILE_NAME
              FROM xxwes_ap_ahcs_hdr_stg
             WHERE file_name = p_in_chr_filename;

        CURSOR fetch_line_details (p_in_chr_filename VARCHAR2)
        IS
            SELECT source_trn_nbr,
                   leg_ae_header_id,
                   ent_amt,
                   acc_amt,
                   default_currency,
                   acc_currency,
                   leg_seg1,
                   leg_seg2,
                   leg_seg3,
                   leg_seg4,
                   leg_seg5,
                   leg_seg6,
                   leg_seg7,
                   acc_class,
                   dr_cr_flag,
                   leg_ae_line_nbr,
                   je_line_nbr,
                   line_desc,
                   fx_rate
              FROM xxwes_ap_ahcs_line_stg
             WHERE file_name = p_in_chr_filename;
    BEGIN
        p_out_ret_code := 0;
        v_message := NULL;
        l_num_ae_header_id := 0;
        l_dt_start_date := SYSDATE;
        l_chr_err_msg := NULL;

        fnd_file.put_line (apps.fnd_file.LOG,
                           'p_in_run_mode: ' || p_in_run_mode);

        fnd_file.put_line (apps.fnd_file.LOG,
                           'Accounting Date From: ' || p_in_run_date_from);

        fnd_file.put_line (apps.fnd_file.LOG,
                           'Accounting Date To: ' || p_in_run_date_to);

        fnd_file.put_line (apps.fnd_file.LOG, 'Period Name: ' || p_in_period);

        --
        --Call procedure for Purging old staging table data
        --
        purge_old_stage_data ();

        l_num_hdr_count := 0;
        l_num_line_count := 0;

        IF (p_in_run_date_from IS NULL AND p_in_period IS NULL)
        THEN
            p_out_err_msg :=
                '***** Either From Date or Period Name should be provided*******';
            p_out_ret_code := 2;
            fnd_file.put_line (apps.fnd_file.LOG, l_chr_err_msg);
            RETURN;
        END IF;

        IF (p_in_run_date_From IS NOT NULL)
        THEN
            l_last_run_date_from :=
                fnd_date.canonical_to_date (p_in_run_date_from);
        END IF;

        IF (p_in_run_date_to IS NOT NULL)
        THEN
            l_last_run_date_to :=
                fnd_date.canonical_to_date (p_in_run_date_to);
        ELSE
            l_last_run_date_to :=
                fnd_date.canonical_to_date (p_in_run_date_from);
        END IF;

        --        END IF;

        IF (l_last_run_date_to < l_last_run_date_from)
        THEN
            p_out_err_msg := '***** From Date cannot be Greater than To Date';
            p_out_ret_code := 2;
            fnd_file.put_line (apps.fnd_file.LOG, l_chr_err_msg);
            RETURN;
        END IF;

        l_num_days := 0;

        SELECT (l_last_run_date_to - l_last_run_date_from) + 1
          INTO l_num_days
          FROM DUAL;

        fnd_file.put_line (fnd_file.LOG, l_num_days);

        IF l_num_days > 31
        THEN
            p_out_err_msg :=
                '***** Days between the from and to dates cannot be more than 31 Days';
            p_out_ret_code := 2;
            fnd_file.put_line (apps.fnd_file.LOG, p_out_err_msg);
            email_error_notification (p_out_err_msg, p_in_chr_err_email);
            RETURN;
        END IF;

        IF p_in_period IS NOT NULL
        THEN
            --
            -- If Period is given extract Period start date and end date
            --
            BEGIN
                SELECT TRUNC (start_date), TRUNC (end_date)
                  INTO l_last_run_date_from, l_last_run_date_to
                  FROM gl_periods
                 WHERE period_name = p_in_period;
            EXCEPTION
                WHEN OTHERS
                THEN
                    p_out_err_msg :=
                        '***** Error while fetching period start and end dates';
                    p_out_ret_code := 2;
                    fnd_file.put_line (apps.fnd_file.LOG, p_out_err_msg);
                    email_error_notification (p_out_err_msg,
                                              p_in_chr_err_email);
            END;
        END IF;

        apps.fnd_file.put_line (
            apps.fnd_file.LOG,
            'Accounting Date from:                 ' || l_last_run_date_from);
        apps.fnd_file.put_line (
            apps.fnd_file.LOG,
            'Accounting Date to:                 ' || l_last_run_date_to);

        /*Start chages for artf71080*/
        BEGIN
            SELECT TO_NUMBER (tag)
              INTO l_num_max_days_back
              FROM fnd_lookup_values
             WHERE     lookup_type = 'XXAU_AHCS_ERROR_FEED_DETAILS'
                   AND language = 'US'
                   AND enabled_flag = 'Y'
                   AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                   AND NVL (end_date_active, SYSDATE)
                   AND lookup_code = 'MAX_DAYS_BACK';
        EXCEPTION
            WHEN OTHERS
            THEN
                l_num_max_days_back := 60;
                fnd_file.put_line (
                    apps.fnd_file.LOG,
                    'Max Days to Consider for Processing Error Records defaulted to 180 as it is not set: ');
        END;

        apps.fnd_file.put_line (
            apps.fnd_file.LOG,
            'Max days back setup for processing: ' || l_num_max_days_back);

        --
        --Check whether period start date or accounting date from are not older than Max days in the lookup
        --
        IF (TRUNC (SYSDATE) - TRUNC (l_last_run_date_from) >
                l_num_max_days_back)
        THEN
            p_out_err_msg :=
                   '*****Period Start date or Accounting Start Dates are older than '
                || l_num_max_days_back
                || ' days. Kindly adjust MAX_DAYS_BACK in lookup XXAU_AHCS_ERROR_FEED_DETAILS before resubmission';
            p_out_ret_code := 2;
            fnd_file.put_line (apps.fnd_file.LOG, p_out_err_msg);
            --` email_error_notification (p_out_err_msg, p_in_chr_err_email);
            RETURN;
        END IF;

        /*End chages for artf71080*/
        apps.fnd_file.put_line (
            apps.fnd_file.LOG,
            'Input FTP Directory: ' || p_outfile_directory);

        IF (p_outfile_directory IS NOT NULL)
        THEN
            BEGIN
                SELECT SUBSTR (directory_path, 1, 50)
                  INTO l_chr_ftp_path
                  FROM sys.dba_directories
                 WHERE directory_name = p_outfile_directory;
            EXCEPTION
                WHEN OTHERS
                THEN
                    p_out_err_msg :=
                           '*****Unexpected error verifying input outbound directory details'
                        || SQLCODE
                        || '.  Message = '
                        || SQLERRM;
                    p_out_ret_code := 2;
                    email_error_notification (p_out_err_msg,
                                              p_in_chr_err_email);
                    RETURN;
            END;

            l_chr_out_file_dir := p_outfile_directory;
        ELSE
            apps.fnd_file.put_line (
                apps.fnd_file.LOG,
                'Input FTP Directoryis blank so fetching from Lookup: ');

            BEGIN
                SELECT meaning
                  INTO l_chr_out_file_dir
                  FROM fnd_lookup_values
                 WHERE     lookup_type = 'XXAU_AHCS_ERROR_FEED_DETAILS'
                       AND language = 'US'
                       AND enabled_flag = 'Y'
                       AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                       AND NVL (end_date_active, SYSDATE)
                       AND lookup_code = 'XXAP';
            EXCEPTION
                WHEN OTHERS
                THEN
                    p_out_err_msg :=
                           '*****Unexpected error querying outbound directory details'
                        || SQLCODE
                        || '.  Message = '
                        || SQLERRM;
                    p_out_ret_code := 2;
                    email_error_notification (p_out_err_msg,
                                              p_in_chr_err_email);
                    RETURN;
            END;
        END IF;

        fnd_file.put_line (
            apps.fnd_file.LOG,
            'AP Extract outbound directory: ' || l_chr_out_file_dir);

        BEGIN
            SELECT                                           --'XXAP_OUTBOUND'
                  description
              INTO l_chr_bi_out_file_dir
              FROM fnd_lookup_values
             WHERE     lookup_type = 'XXAU_AHCS_ERROR_FEED_DETAILS'
                   AND language = 'US'
                   AND enabled_flag = 'Y'
                   AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                   AND NVL (end_date_active, SYSDATE)
                   AND lookup_code = 'XXAP_BI_DIR';
        EXCEPTION
            WHEN OTHERS
            THEN
                l_chr_bi_out_file_dir := NULL;
        END;

        BEGIN
            SELECT TO_NUMBER (tag)
              INTO l_num_max_purge_days
              FROM fnd_lookup_values
             WHERE     lookup_type = 'XXAU_AHCS_ERROR_FEED_DETAILS'
                   AND language = 'US'
                   AND enabled_flag = 'Y'
                   AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                   AND NVL (end_date_active, SYSDATE)
                   AND lookup_code = 'MAX_PURGE_DAYS';
        EXCEPTION
            WHEN OTHERS
            THEN
                l_num_max_purge_days := 180;
                fnd_file.put_line (
                    apps.fnd_file.LOG,
                    'Max Days to Consider for Processing Error Records defaulted to 180 as it is not set: ');
        END;

        fnd_file.put_line (apps.fnd_file.LOG,
                           'BI Directory: ' || l_chr_bi_out_file_dir);
        fnd_file.put_line (
            fnd_file.LOG,
               'The AP BI Header Control file name:  '
            || l_chr_ctl_hdr_file_name);
        fnd_file.put_line (
            fnd_file.LOG,
            'The AP BI Line Control file name:  ' || l_chr_ctl_line_file_name);

        fnd_file.put_line (fnd_file.LOG,
                           'max purge days: ' || l_num_max_purge_days);


        FOR extract_daily_rec IN c_extract_daily (l_last_run_date_from,
                                                  l_last_run_date_to,
                                                  p_in_run_mode,
                                                  l_num_max_purge_days)
        LOOP
            BEGIN
                IF (l_num_ae_header_id <> extract_daily_rec.leg_ae_header_id)
                THEN
                    BEGIN
                        --
                        --Insert into Header Table
                        --
                        v_message := NULL;
                        l_chr_trd_partner_name := NULL;
                        l_chr_trd_partner_nbr := NULL;
                        l_chr_trd_partner_site := NULL;

                        --
                        --Derive Trading Partner details
                        --
                        --                        fnd_file.put_line (
                        --                            fnd_file.LOG,
                        --                               extract_daily_rec.leg_ae_header_id
                        --                            || '_'
                        --                            || extract_daily_rec.entity_code
                        --                            || '_'
                        --                            || extract_daily_rec.source_id_int_1
                        --                            || '_'
                        --                            || extract_daily_rec.ledger_id
                        --                            || '_'
                        --                            || TO_CHAR (extract_daily_rec.ACC_DATE,
                        --                                        'yyyy-mm-dd'));

                        BEGIN
                            IF (extract_daily_rec.entity_code = 'AP_INVOICES')
                            THEN
                                SELECT DISTINCT
                                       SUBSTR (
                                           NVL (
                                               pv.vendor_name,
                                               (SELECT remit_to_supplier_name
                                                  FROM ap_invoice_payments_all
                                                       aipa
                                                 WHERE     aipa.invoice_id =
                                                               ai.invoice_id
                                                       AND aipa.reversal_flag
                                                               IS NULL)),
                                           1,
                                           100)
                                           trd_partner_name,   --CAB 9-21-2021
                                       --pv.PARTY_NUMBER                   trd_partner_nbr,  --CAB CTPFS-841
                                       pv.segment1           trd_partner_nbr, --CAB CTPFS-841
                                       pvsa.vendor_site_code trd_partner_site
                                  INTO l_chr_trd_partner_name,
                                       l_chr_trd_partner_nbr,
                                       l_chr_trd_partner_site
                                  FROM ap_invoices_all      ai,
                                       po_vendors           pv,
                                       po_vendor_sites_all  pvsa
                                 WHERE     ai.invoice_id =
                                               extract_daily_rec.source_id_int_1
                                       AND ai.set_of_books_id =
                                               extract_daily_rec.ledger_id
                                       AND ai.vendor_site_id =
                                               pvsa.vendor_site_id(+)
                                       AND ai.vendor_id = pv.vendor_id(+)
                                       AND ROWNUM < 2;
                            ELSIF (extract_daily_rec.entity_code =
                                       'AP_PAYMENTS')
                            THEN
                                SELECT DISTINCT
                                       SUBSTR (
                                           NVL (pv.vendor_name,
                                                aipa.remit_to_supplier_name),
                                           1,
                                           100)
                                           trd_partner_name,   --CAB 9-19-2021
                                       pv.segment1           trd_partner_nbr,
                                       pvsa.vendor_site_code trd_partner_site
                                  INTO l_chr_trd_partner_name,
                                       l_chr_trd_partner_nbr,
                                       l_chr_trd_partner_site
                                  FROM ap_invoices_all          ai,
                                       po_vendors               pv,
                                       po_vendor_sites_all      pvsa,
                                       ap_invoice_payments_all  aipa
                                 WHERE     aipa.check_id =
                                               extract_daily_rec.source_id_int_1
                                       AND ai.set_of_books_id =
                                               extract_daily_rec.ledger_id
                                       AND aipa.invoice_id = ai.invoice_id
                                       AND ai.vendor_site_id =
                                               pvsa.vendor_site_id(+)
                                       AND ai.vendor_id = pv.vendor_id(+)
                                       AND ROWNUM < 2;
                            END IF;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                v_message :=
                                       'Error While fetching Vendor Details: || '
                                    || SQLERRM;
                                fnd_file.put_line (fnd_file.LOG, v_message);
                                RAISE l_exc_hdr;
                        END;



                        INSERT INTO xxwes_ap_ahcs_hdr_stg (source_trn_nbr,
                                                           source_system,
                                                           leg_ae_header_id,
                                                           trd_partner_name,
                                                           trd_partner_nbr,
                                                           trd_partner_site,
                                                           event_type,
                                                           event_class,
                                                           trn_amount,
                                                           acc_date,
                                                           header_desc,
                                                           leg_led_name,
                                                           je_batch_name,
                                                           je_name,
                                                           je_category,
                                                           file_name,
                                                           created_by,
                                                           creation_date,
                                                           last_updated_by,
                                                           last_update_login,
                                                           last_update_date,
                                                           status,
                                                           conc_program_id,
                                                           request_id)
                                 VALUES (
                                            extract_daily_rec.SOURCE_TRN_NBR,
                                            extract_daily_rec.SOURCE_SYSTEM,
                                            extract_daily_rec.LEG_AE_HEADER_ID,
                                            l_chr_trd_partner_name,
                                            l_chr_trd_partner_nbr,
                                            l_chr_trd_partner_site,
                                            extract_daily_rec.EVENT_TYPE,
                                            extract_daily_rec.EVENT_CLASS,
                                            extract_daily_rec.TRN_AMOUNT,
                                            TO_CHAR (
                                                extract_daily_rec.ACC_DATE,
                                                'yyyy-mm-dd'),
                                            extract_daily_rec.HEADER_DESC,
                                            extract_daily_rec.LEG_LED_NAME,
                                            extract_daily_rec.JE_BATCH_NAME,
                                            extract_daily_rec.JE_NAME,
                                            extract_daily_rec.JE_CATEGORY,
                                            extract_daily_rec.FILE_NAME,
                                            fnd_global.user_id,
                                            SYSDATE,
                                            fnd_global.user_id,
                                            fnd_global.login_id,
                                            SYSDATE,
                                            'New',
                                            fnd_global.conc_program_id,
                                            fnd_global.conc_request_id);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            v_message :=
                                   'Error While inserting Hdr ID: || '
                                || SQLERRM;
                            fnd_file.put_line (
                                fnd_file.LOG,
                                'Error while HDR insertion: ' || SQLERRM);
                            RAISE l_exc_hdr;
                    END;

                    l_num_hdr_count := l_num_hdr_count + 1;
                    l_num_ae_header_id := extract_daily_rec.leg_ae_header_id;
                --                ELSE
                --                        fnd_file.put_line (
                --                            fnd_file.LOG,'AE Header ID Exists in Hdr Table') ;
                END IF;

                --
                --Insert into Line Staging Table
                --
                BEGIN
                    INSERT INTO xxwes_ap_ahcs_line_stg (source_trn_nbr,
                                                        leg_ae_header_id,
                                                        ent_amt,
                                                        acc_amt,
                                                        default_currency,
                                                        acc_currency,
                                                        leg_seg1,
                                                        leg_seg2,
                                                        leg_seg3,
                                                        leg_seg4,
                                                        leg_seg5,
                                                        leg_seg6,
                                                        leg_seg7,
                                                        acc_class,
                                                        dr_cr_flag,
                                                        leg_ae_line_nbr,
                                                        je_line_nbr,
                                                        line_desc,
                                                        fx_rate,
                                                        created_by,
                                                        creation_date,
                                                        last_updated_by,
                                                        last_update_login,
                                                        last_update_date,
                                                        file_name,
                                                        status,
                                                        conc_program_id,
                                                        request_id)
                         VALUES (extract_daily_rec.SOURCE_TRN_NBR,
                                 extract_daily_rec.LEG_AE_HEADER_ID,
                                 extract_daily_rec.ENT_AMT,
                                 extract_daily_rec.ACC_AMT,
                                 extract_daily_rec.DEFAULT_CURRENCY,
                                 extract_daily_rec.ACC_CURRENCY,
                                 extract_daily_rec.LEG_SEG1,
                                 extract_daily_rec.LEG_SEG2,
                                 extract_daily_rec.LEG_SEG3,
                                 extract_daily_rec.LEG_SEG4,
                                 extract_daily_rec.LEG_SEG5,
                                 extract_daily_rec.LEG_SEG6,
                                 extract_daily_rec.LEG_SEG7,
                                 extract_daily_rec.ACC_CLASS,
                                 extract_daily_rec.DR_CR_FLAG,
                                 extract_daily_rec.LEG_AE_LINE_NBR,
                                 extract_daily_rec.JE_LINE_NBR,
                                 extract_daily_rec.LINE_DESC,
                                 extract_daily_rec.FX_RATE,
                                 fnd_global.user_id,
                                 SYSDATE,
                                 fnd_global.user_id,
                                 fnd_global.login_id,
                                 SYSDATE,
                                 extract_daily_rec.FILE_NAME,
                                 'New',
                                 fnd_global.conc_program_id,
                                 fnd_global.conc_request_id);

                    l_num_line_count := l_num_line_count + 1;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line (
                            fnd_file.LOG,
                            'Error while Line insertion: ' || SQLERRM);
                END;
            EXCEPTION
                WHEN l_exc_hdr
                THEN
                    ROLLBACK;
                    fnd_file.put_line (
                        fnd_file.LOG,
                        'Rolling Back Changes as Error occurred' || v_message);
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    fnd_file.put_line (
                        fnd_file.LOG,
                        'Unexpected Error occurred: ' || SQLERRM);
            END;

            COMMIT;
        END LOOP;

        --
        --Write HEader File
        --
        l_chr_hdr_heading :=
               'SOURCE_TRN_NBR'
            || '|'
            || 'SOURCE_SYSTEM'
            || '|'
            || 'LEG_AE_HEADER_ID'
            || '|'
            || 'TRD_PARTNER_NAME'
            || '|'
            || 'TRD_PARTNER_NBR'
            || '|'
            || 'TRD_PARTNER_SITE'
            || '|'
            || 'EVENT_TYPE'
            || '|'
            || 'EVENT_CLASS'
            || '|'
            || 'TRN_AMOUNT'
            || '|'
            || 'ACC_DATE'
            || '|'
            || 'HEADER_DESC'
            || '|'
            || 'LEG_LED_NAME'
            || '|'
            || 'JE_BATCH_NAME'
            || '|'
            || 'JE_NAME'
            || '|'
            || 'JE_CATEGORY'
            || '|'
            || 'FILE_NAME';

        l_chr_line_heading :=
               'SOURCE_TRN_NBR'
            || '|'
            || 'LEG_AE_HEADER_ID'
            || '|'
            || 'ENT_AMT'
            || '|'
            || 'ACC_AMT'
            || '|'
            || 'ENT_CURRENCY'
            || '|'
            || 'ACC_CURRENCY'
            || '|'
            || 'LEG_SEG1'
            || '|'
            || 'LEG_SEG2'
            || '|'
            || 'LEG_SEG3'
            || '|'
            || 'LEG_SEG4'
            || '|'
            || 'LEG_SEG5'
            || '|'
            || 'LEG_SEG6'
            || '|'
            || 'LEG_SEG7'
            || '|'
            || 'ACC_CLASS'
            || '|'
            || 'DR_CR_FLAG'
            || '|'
            || 'LEG_AE_LINE_NBR'
            || '|'
            || 'JE_LINE_NBR'
            || '|'
            || 'LINE_DESC'
            || '|'
            || 'FX_RATE';

        --
        --Write Header File
        --
        FOR rec_hdr_details IN fetch_hdr_details (l_chr_file_name)
        LOOP
            IF (fetch_hdr_details%ROWCOUNT = 1)
            THEN
                fnd_file.put_line (
                    fnd_file.LOG,
                    'Header Filename: ' || l_chr_hdr_file_name);
                --
                --Open the header file for writing
                --
                l_hdr_file_handle :=
                    UTL_FILE.fopen (l_chr_out_file_dir,
                                    l_chr_hdr_file_name,
                                    'W',
                                    10000);        --Added for Jira CTPFS-4342
                --
                --Write Header file headings
                --
                UTL_FILE.put_line (l_hdr_file_handle, l_chr_hdr_heading);
            END IF;

            UTL_FILE.put_line (
                l_hdr_file_handle,
                   rec_hdr_details.SOURCE_TRN_NBR
                || '|'
                || rec_hdr_details.SOURCE_SYSTEM
                || '|'
                || rec_hdr_details.LEG_AE_HEADER_ID
                || '|'
                || rec_hdr_details.TRD_PARTNER_NAME
                || '|'
                || rec_hdr_details.TRD_PARTNER_NBR
                || '|'
                || rec_hdr_details.TRD_PARTNER_SITE
                || '|'
                || rec_hdr_details.EVENT_TYPE
                || '|'
                || rec_hdr_details.EVENT_CLASS
                || '|'
                || rec_hdr_details.TRN_AMOUNT
                || '|'
                || rec_hdr_details.ACC_DATE
                || '|'
                || rec_hdr_details.HEADER_DESC
                || '|'
                || rec_hdr_details.LEG_LED_NAME
                || '|'
                || rec_hdr_details.JE_BATCH_NAME
                || '|'
                || rec_hdr_details.JE_NAME
                || '|'
                || rec_hdr_details.JE_CATEGORY
                || '|'
                || rec_hdr_details.FILE_NAME);
        END LOOP;

        fnd_file.put_line (fnd_file.LOG, 'Header Count: ' || l_num_hdr_count);

        l_num_hdr_ctr := 0;

        WHILE (UTL_FILE.IS_OPEN (l_hdr_file_handle) AND l_num_hdr_ctr < 6)
        LOOP
            BEGIN
                l_num_hdr_ctr := l_num_hdr_ctr + 1;
                UTL_FILE.FFLUSH (l_hdr_file_handle);
                fnd_file.put_line (fnd_file.LOG,
                                   'Before closing Header file');
                UTL_FILE.fclose (l_hdr_file_handle);
            EXCEPTION
                WHEN OTHERS
                THEN
                    IF (l_num_hdr_ctr < 6)
                    THEN
                        fnd_file.put_line (
                            fnd_file.LOG,
                               'Before going to sleep while closing Header file: '
                            || l_num_hdr_ctr);
                        DBMS_LOCK.SLEEP (20);
                    ELSE
                        p_out_err_msg :=
                               '*****Unexpected error while closing header file: '
                            || SQLCODE
                            || '.  Message = '
                            || SQLERRM;
                        p_out_ret_code := 2;
                        fnd_file.put_line (fnd_file.LOG, p_out_err_msg);
                        email_error_notification (p_out_err_msg,
                                                  p_in_chr_err_email);
                        RETURN;
                    END IF;
            END;
        --        ELSE
        --            fnd_file.put_line (fnd_file.LOG, 'Header File is not prepared: ');
        --        END IF;
        END LOOP;

        FOR rec_line_details IN fetch_line_details (l_chr_file_name)
        LOOP
            IF (fetch_line_details%ROWCOUNT = 1)
            THEN
                fnd_file.put_line (fnd_file.LOG,
                                   'Line Filename: ' || l_chr_line_file_name);
                --
                --Open the Line file for writing
                --
                l_line_file_handle :=
                    UTL_FILE.fopen (l_chr_out_file_dir,
                                    l_chr_line_file_name,
                                    'W',
                                    10000);
                --
                --Write Line file headings
                --
                UTL_FILE.put_line (l_line_file_handle, l_chr_line_heading);
            END IF;

            UTL_FILE.put_line (
                l_line_file_handle,
                   rec_line_details.SOURCE_TRN_NBR
                || '|'
                || rec_line_details.LEG_AE_HEADER_ID
                || '|'
                || rec_line_details.ENT_AMT
                || '|'
                || rec_line_details.ACC_AMT
                || '|'
                || rec_line_details.DEFAULT_CURRENCY
                || '|'
                || rec_line_details.ACC_CURRENCY
                || '|'
                || rec_line_details.LEG_SEG1
                || '|'
                || rec_line_details.LEG_SEG2
                || '|'
                || rec_line_details.LEG_SEG3
                || '|'
                || rec_line_details.LEG_SEG4
                || '|'
                || rec_line_details.LEG_SEG5
                || '|'
                || rec_line_details.LEG_SEG6
                || '|'
                || rec_line_details.LEG_SEG7
                || '|'
                || rec_line_details.ACC_CLASS
                || '|'
                || rec_line_details.DR_CR_FLAG
                || '|'
                || rec_line_details.LEG_AE_LINE_NBR
                || '|'
                || rec_line_details.JE_LINE_NBR
                || '|'
                || rec_line_details.LINE_DESC
                || '|'
                || rec_line_details.FX_RATE);
        END LOOP;



        l_num_line_ctr := 0;

        WHILE (UTL_FILE.IS_OPEN (l_line_file_handle) AND l_num_line_ctr < 6)
        LOOP
            BEGIN
                l_num_line_ctr := l_num_line_ctr + 1;
                UTL_FILE.FFLUSH (l_line_file_handle);
                fnd_file.put_line (fnd_file.LOG, 'Before closing Line file');
                UTL_FILE.fclose (l_line_file_handle);
            EXCEPTION
                WHEN OTHERS
                THEN
                    IF (l_num_line_ctr < 6)
                    THEN
                        fnd_file.put_line (
                            fnd_file.LOG,
                               'Before going to sleep while closing line file: '
                            || l_num_line_ctr);
                        DBMS_LOCK.SLEEP (20);
                    ELSE
                        p_out_err_msg :=
                               '*****Unexpected error while closing Line file: '
                            || SQLCODE
                            || '.  Message = '
                            || SQLERRM;
                        p_out_ret_code := 2;
                        fnd_file.put_line (fnd_file.LOG, p_out_err_msg);
                        email_error_notification (p_out_err_msg,
                                                  p_in_chr_err_email);
                        RETURN;
                    END IF;
            END;
        --        ELSE
        --            fnd_file.put_line (fnd_file.LOG, 'Line File is not prepared: ');
        --        END IF;
        END LOOP;

        fnd_file.put_line (fnd_file.LOG, 'Line Count: ' || l_num_line_count);

        --
        --Insert File Details into Control Table
        --
        fnd_file.put_line (fnd_file.LOG, 'Before inserting into CTL table: ');

        BEGIN
            INSERT INTO xxwes_ebs_to_ahcs_ctl (APPLICATION_CODE,
                                               LAST_RUN_DATE,
                                               FILE_NAME,
                                               HEADER_RECORDS,
                                               LINE_RECORDS,
                                               REQUEST_ID,
                                               START_DATE,
                                               END_DATE,
                                               PERIOD_NAME,
                                               STATUS,
                                               CREATION_DATE,
                                               CREATED_BY,
                                               LAST_UPDATE_DATE,
                                               LAST_UPDATED_BY,
                                               LAST_UPDATE_LOGIN,
                                               attribute1,
                                               attribute2)
                SELECT 'XXAP',
                       SYSDATE,
                       l_chr_file_name,
                       l_num_hdr_count,
                       l_num_line_count,
                       fnd_global.conc_request_id,
                       l_dt_start_date,
                       SYSDATE,
                       p_in_period,                --Added for Jira CTPFS-4342
                       'SENT TO OIC',
                       SYSDATE,
                       fnd_global.user_id,
                       SYSDATE,
                       fnd_global.user_id,
                       fnd_global.login_id,
                       TO_CHAR (l_last_run_date_from, 'mmddyyyy'),
                       TO_CHAR (l_last_run_date_to, 'mmddyyyy')
                  FROM DUAL;

            COMMIT;
        EXCEPTION
            WHEN OTHERS
            THEN
                p_out_err_msg :=
                       'Unexpected error in inserting into Control table: '
                    || SQLERRM;
                fnd_file.put_line (fnd_file.LOG, p_out_err_msg);
                email_error_notification (p_out_err_msg, p_in_chr_err_email);
        END;

        --
        --Place Trigger File
        --
        IF (l_num_hdr_count > 0 AND l_num_line_count > 0)
        THEN
            BEGIN
                l_trg_file_handle :=
                    UTL_FILE.fopen (l_chr_out_file_dir,
                                    l_trg_file_name,
                                    'W',
                                    10000);        --Added for Jira CTPFS-4342

                l_num_trg_ctr := 0;

                WHILE (    UTL_FILE.IS_OPEN (l_trg_file_handle)
                       AND l_num_trg_ctr < 6)
                LOOP
                    BEGIN
                        l_num_trg_ctr := l_num_trg_ctr + 1;
                        UTL_FILE.FFLUSH (l_trg_file_handle);
                        fnd_file.put_line (fnd_file.LOG,
                                           'Before closing Trigger file');
                        UTL_FILE.fclose (l_trg_file_handle);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            IF (l_num_trg_ctr < 6)
                            THEN
                                fnd_file.put_line (
                                    fnd_file.LOG,
                                       'Before going to sleep while closing trigger file: '
                                    || l_num_trg_ctr);
                                DBMS_LOCK.SLEEP (20);
                            ELSE
                                p_out_err_msg :=
                                       '*****Unexpected error while closing trigger file: '
                                    || SQLCODE
                                    || '.  Message = '
                                    || SQLERRM;
                                p_out_ret_code := 2;
                                fnd_file.put_line (fnd_file.LOG,
                                                   p_out_err_msg);
                                email_error_notification (p_out_err_msg,
                                                          p_in_chr_err_email);
                                RETURN;
                            END IF;
                    END;
                END LOOP;
            --                ELSE
            --                    fnd_file.put_line (fnd_file.LOG,
            --                                       'Trigger File is not prepared: ');
            --                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line (
                        fnd_file.LOG,
                           'Unexpected error while placing Trigger file: '
                        || SQLERRM);
            END;

            fnd_file.put_line (
                fnd_file.LOG,
                'Before updating xxwes_ap_ahcs_hdr_stg to SENT TO OIC: ');

            BEGIN
                --
                --Update HDR and Line Staging Table record status to Sent to OIC
                --
                UPDATE xxwes_ap_ahcs_hdr_stg
                   SET status = 'SENT TO OIC'
                 WHERE file_name = l_chr_file_name;

                fnd_file.put_line (
                    fnd_file.LOG,
                       'No. of Header Records marked Sent to OIC: '
                    || SQL%ROWCOUNT);

                UPDATE xxwes_ap_ahcs_line_stg
                   SET status = 'SENT TO OIC'
                 WHERE file_name = l_chr_file_name;

                fnd_file.put_line (
                    fnd_file.LOG,
                       'No. of Line Records marked Sent to OIC: '
                    || SQL%ROWCOUNT);

                COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line (
                        fnd_file.LOG,
                           'Unexpected error while updating header and line table records to SENT TO OIC: '
                        || SQLERRM);
            END;

            --
            --Mark Error Records as Reprocessed when job submitted in Run Mode B, E
            --


            BEGIN
                UPDATE xxap_ebs_to_ahcs_errs err
                   SET status = 'REPROCESSED',
                       last_update_date = SYSDATE,
                       last_updated_by = fnd_global.user_id
                 WHERE     1 = 1
                       AND status = 'NEW'
                       AND EXISTS
                               (SELECT 1
                                  FROM xxwes_ap_ahcs_hdr_stg hdr
                                 WHERE     file_name = l_chr_file_name
                                       AND hdr.leg_ae_header_id =
                                               err.leg_ae_header_id
                                       AND status = 'SENT TO OIC');

                fnd_file.put_line (
                    fnd_file.LOG,
                       'No. of Error records updated to Reprocessed: '
                    || SQL%ROWCOUNT);

                COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line (
                        fnd_file.LOG,
                           'Unexpected error while updating reprocessed records in error table to SENT TO OIC: '
                        || SQLERRM);
            END;

            --
            --Move the Files to BI Directory
            --
            IF (l_chr_bi_out_file_dir IS NOT NULL)
            THEN
                fnd_file.put_line (
                    fnd_file.LOG,
                       'Before Copying files to BI Directory: '
                    || l_chr_bi_out_file_dir);

                BEGIN
                    UTL_FILE.FCOPY (src_location    => l_chr_out_file_dir,
                                    src_filename    => l_chr_hdr_file_name,
                                    dest_location   => l_chr_bi_out_file_dir,
                                    dest_filename   => l_chr_hdr_file_name);
                    UTL_FILE.FCOPY (src_location    => l_chr_out_file_dir,
                                    src_filename    => l_chr_line_file_name,
                                    dest_location   => l_chr_bi_out_file_dir,
                                    dest_filename   => l_chr_line_file_name);
                    UTL_FILE.FCOPY (src_location    => l_chr_out_file_dir,
                                    src_filename    => l_trg_file_name,
                                    dest_location   => l_chr_bi_out_file_dir,
                                    dest_filename   => l_trg_file_name);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        p_out_err_msg :=
                               'Error Occurred while copying to BI Directory: '
                            || SQLERRM;
                        p_out_ret_code := 2;
                        fnd_file.put_line (fnd_file.LOG, p_out_err_msg);
                        email_error_notification (p_out_err_msg,
                                                  p_in_chr_err_email);
                        RETURN;
                END;

                BEGIN
                    SELECT SUM (trn_amount)
                      INTO l_num_hdr_total_amt
                      FROM apps.XXWES_AP_AHCS_HDR_STG
                     WHERE     status = 'SENT TO OIC'
                           AND file_name = l_chr_file_name;



                    -- Write BI Hdr Control file
                    l_ctl_hdr_file_handle :=
                        UTL_FILE.fopen (l_chr_bi_out_file_dir,
                                        l_chr_ctl_hdr_file_name,
                                        'W',
                                        10000);    --Added for Jira CTPFS-4342
                    UTL_FILE.PUT_LINE (l_ctl_hdr_file_handle,
                                       'Record_Count|Trn_Amount');
                    UTL_FILE.PUT_LINE (
                        l_ctl_hdr_file_handle,
                        l_num_hdr_count || '|' || l_num_hdr_total_amt);


                    IF (UTL_FILE.IS_OPEN (l_ctl_hdr_file_handle))
                    THEN
                        BEGIN
                            UTL_FILE.FFLUSH (l_ctl_hdr_file_handle);
                            fnd_file.put_line (
                                fnd_file.LOG,
                                'Before closing BI Control hdr file');
                            UTL_FILE.fclose (l_ctl_hdr_file_handle);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                p_out_err_msg :=
                                       '*****Unexpected error while closing BI Control hdr file: '
                                    || SQLCODE
                                    || '.  Message = '
                                    || SQLERRM;
                                p_out_ret_code := 2;
                                fnd_file.put_line (fnd_file.LOG,
                                                   p_out_err_msg);
                                RETURN;
                        END;
                    ELSE
                        fnd_file.put_line (
                            fnd_file.LOG,
                            'BI control hdr File is not prepared: ');
                    END IF;

                    l_num_line_total_amount := 0;

                    SELECT SUM (ACC_AMT)
                      INTO l_num_line_total_amount
                      FROM XXWES_AP_AHCS_line_STG
                     WHERE     status = 'SENT TO OIC'
                           AND file_name = l_chr_file_name;


                    -- Write BI Line Control file
                    l_ctl_line_file_handle :=
                        UTL_FILE.fopen (l_chr_bi_out_file_dir,
                                        l_chr_ctl_line_file_name,
                                        'W',
                                        10000);    --Added for Jira CTPFS-4342
                    UTL_FILE.PUT_LINE (l_ctl_line_file_handle,
                                       'Record_Count|ACC_AMT');
                    UTL_FILE.PUT_LINE (
                        l_ctl_line_file_handle,
                        l_num_line_count || '|' || l_num_line_total_amount);

                    IF (UTL_FILE.IS_OPEN (l_ctl_line_file_handle))
                    THEN
                        BEGIN
                            UTL_FILE.FFLUSH (l_ctl_line_file_handle);
                            fnd_file.put_line (
                                fnd_file.LOG,
                                'Before closing BI Control line file');
                            UTL_FILE.fclose (l_ctl_line_file_handle);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                p_out_err_msg :=
                                       '*****Unexpected error while closing BI Control line file: '
                                    || SQLCODE
                                    || '.  Message = '
                                    || SQLERRM;
                                p_out_ret_code := 2;
                                fnd_file.put_line (fnd_file.LOG,
                                                   p_out_err_msg);
                                RETURN;
                        END;
                    ELSE
                        fnd_file.put_line (
                            fnd_file.LOG,
                            'BI control line File is not prepared: ');
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line (
                            fnd_file.LOG,
                               'Error Occurred while writing header/line control files to BI Directory: '
                            || SQLERRM);
                        email_error_notification (
                               'Error Occurred while writing header/line control files to BI Directory: '
                            || SQLERRM,
                            p_in_chr_err_email);
                END;
            ELSE
                fnd_file.put_line (fnd_file.LOG,
                                   'BI Directory details are not available');
            END IF;
        ELSE
            fnd_file.put_line (
                fnd_file.LOG,
                'No File is created as there are no Header and Line records');
        END IF;
    EXCEPTION
        WHEN l_exc_others
        THEN
            p_out_ret_code := 2;
            p_out_err_msg := SUBSTR (l_chr_err_msg, 1, 150);
            email_error_notification (p_out_err_msg, p_in_chr_err_email);
        WHEN OTHERS
        THEN
            p_out_ret_code := SQLCODE;
            p_out_err_msg := SUBSTR (SQLERRM, 1, 150);
            ROLLBACK;
            fnd_file.put_line (fnd_file.LOG, p_out_err_msg);
            email_error_notification (p_out_err_msg, p_in_chr_err_email);
    END;



    PROCEDURE load_errors (p_out_err_msg           OUT VARCHAR2,
                           p_out_ret_code          OUT NUMBER,
                           p_in_chr_err_email   IN     VARCHAR2)
    IS
        CURSOR cur_error_files_to_check
        IS
            SELECT file_name, request_id, start_date
              FROM xxwes_ebs_to_ahcs_ctl
             WHERE application_code = 'XXAP' AND status = 'SENT TO OIC';

        rec_error_files_to_check       cur_error_files_to_check%ROWTYPE;

        l_error_file_to_find           VARCHAR2 (100);
        l_num_max_err_file_wait_days   NUMBER;
        l_done_file_to_find            VARCHAR2 (100);
        l_file_exists                  BOOLEAN;
        l_file_error_occurred          BOOLEAN;
        l_file_len                     NUMBER;
        l_blocksize                    NUMBER;
        l_error_count                  NUMBER := 0;
        l_error_file                   UTL_FILE.FILE_TYPE;
        s_error_record                 VARCHAR2 (1000);
        l_error_file_line              NUMBER;
        l_file_error_count             NUMBER;
        l_file_found_count             NUMBER;
        l_existing_rec_count           NUMBER;
        l_app_code_value               VARCHAR2 (50);
        l_file_name_value              VARCHAR2 (100);
        l_leg_header_id_value          VARCHAR2 (50);
        l_leg_line_num_value           VARCHAR2 (50);
        l_status_value                 VARCHAR2 (100);
        l_error_msg_value              VARCHAR2 (1000);
        l_cr_dr_value                  VARCHAR2 (100);
        l_curr_value                   VARCHAR2 (100);
        l_amount_value                 VARCHAR2 (100);
        l_source_coa_value             VARCHAR2 (100);
        l_current_request_id           FND_CONCURRENT_REQUESTS.REQUEST_ID%TYPE;
        l_current_proc                 VARCHAR2 (60)
                                           := 'XXAP_AHCS_EXTRACT.LOAD_ERRORS';
        ln_leg_line_num_value          xxap_ebs_to_ahcs_errs.LEG_AE_LINE_NBR%TYPE;
        ln_amount_value                xxap_ebs_to_ahcs_errs.AMOUNT%TYPE;
        l_error_file_directory         FND_LOOKUP_VALUES.DESCRIPTION%TYPE;
        l_error_arch_directory         FND_LOOKUP_VALUES.TAG%TYPE;
    BEGIN
        l_current_request_id := fnd_global.conc_request_id;

        fnd_file.put_line (
            fnd_file.LOG,
               'Beginning '
            || l_current_proc
            || ' at '
            || TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS'));

        -----------------------------------------------------------------------------
        --Determine DBA directories where files will be picked up at and archived to
        --  This is stored in a common lookup XXAU_AHCS_ERROR_FEED_DETAILS
        -----------------------------------------------------------------------------
        BEGIN
            SELECT description pickup_directory, tag archive_directory
              INTO l_error_file_directory, l_error_arch_directory
              FROM fnd_lookup_values
             WHERE     lookup_type = 'XXAU_AHCS_ERROR_FEED_DETAILS'
                   AND language = 'US'
                   AND enabled_flag = 'Y'
                   AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                   AND NVL (end_date_active, SYSDATE)
                   AND lookup_code = 'XXAP';
        EXCEPTION
            WHEN OTHERS
            THEN
                p_out_err_msg :=
                       '*****Unexpected error querying directories.  '
                    || SQLCODE
                    || '.  Message = '
                    || SQLERRM;
                p_out_ret_code := 2;
                RETURN;
        END;

        fnd_file.put_line (
            fnd_file.LOG,
            '    l_error_file_directory = ' || l_error_file_directory);
        fnd_file.put_line (
            fnd_file.LOG,
            '    l_error_arch_directory = ' || l_error_arch_directory);
        fnd_file.put_line (fnd_file.LOG, ' ');


        ----------------------------------------------------------------------------------------------------------------------------------------
        --For any files not received back in last X days, mark as "processed by OIC".  Should not get any errors back after that amount of time
        --  (X is a parameter - l_num_max_err_file_wait_days) This is the max # of days we wait to receive an error file back after sending a data file
        ----------------------------------------------------------------------------------------------------------------------------------------
        BEGIN
            fnd_file.put_line (
                fnd_file.LOG,
                   '  Beginning AP control table updates at '
                || TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS'));

            --
            --Extract Maximum Purge Days to be considered to treat deemed success
            --
            BEGIN
                SELECT tag
                  INTO l_num_max_err_file_wait_days
                  FROM fnd_lookup_values
                 WHERE     lookup_type = 'XXAU_AHCS_ERROR_FEED_DETAILS'
                       AND language = 'US'
                       AND enabled_flag = 'Y'
                       AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                       AND NVL (end_date_active, SYSDATE)
                       AND lookup_code = 'MAX_ERROR_FILE_WAIT_DAYS';
            EXCEPTION
                WHEN OTHERS
                THEN
                    l_num_max_err_file_wait_days := 5;
            END;


            fnd_file.put_line (
                fnd_file.LOG,
                   '    l_num_max_err_file_wait_days     = '
                || l_num_max_err_file_wait_days);

            UPDATE xxwes_ebs_to_ahcs_ctl
               SET status = 'PROCESSED BY OIC'
             WHERE     application_code = 'XXAP'
                   AND status = 'SENT TO OIC'
                   AND end_date < (SYSDATE - l_num_max_err_file_wait_days);

            fnd_file.put_line (
                fnd_file.LOG,
                   '  Completed ap control table updates at '
                || TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS'));
            fnd_file.put_line (fnd_file.LOG,
                               '    Records updated = ' || SQL%ROWCOUNT);
            fnd_file.put_line (fnd_file.LOG, ' ');
        EXCEPTION
            WHEN OTHERS
            THEN
                p_out_err_msg :=
                       '*****Unexpected error updating status to PROCESSED BY OIC for older files.  '
                    || SQLCODE
                    || '.  Message = '
                    || SQLERRM;
                p_out_ret_code := 2;
                email_error_notification (p_out_err_msg, p_in_chr_err_email);
                RETURN;
        END;

        --------------------------------------------------------------------------------------
        -- Loop through all the files sent to OIC to see what errors we should be looking for
        --------------------------------------------------------------------------------------
        BEGIN
            fnd_file.put_line (
                fnd_file.LOG,
                   '  Beginning cursor of files to check for at '
                || TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS'));
            l_file_found_count := 0;

            OPEN cur_error_files_to_check;

            LOOP
                FETCH cur_error_files_to_check INTO rec_error_files_to_check;

                EXIT WHEN cur_error_files_to_check%NOTFOUND;

                fnd_file.put_line (
                    fnd_file.LOG,
                       '    Need to check for error file *** '
                    || rec_error_files_to_check.file_name
                    || ' ***');
                ---------------------------------------------------------------------------------------------
                -- If errors occur, a file with errors will be sent back and have the same base file name,
                --   but with a .ERR extension.  Once the .ERR file is completely written, a corresponding
                --   .DONE file will be created.  This will be empty - just used to confirm the completeness
                --   of the error file.
                ---------------------------------------------------------------------------------------------
                l_error_file_to_find :=
                    rec_error_files_to_check.file_name || '.ERR';
                l_done_file_to_find :=
                    rec_error_files_to_check.file_name || '.DONE';
                l_file_error_occurred := FALSE;

                ------------------------------------------------------------------------------------
                -- First, check if the .DONE file exists.  If so, then check if the .ERR file exists
                ------------------------------------------------------------------------------------
                BEGIN
                    UTL_FILE.FGETATTR (l_error_file_directory,
                                       l_done_file_to_find,
                                       l_file_exists,
                                       l_file_len,
                                       l_blocksize);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line (
                            fnd_file.LOG,
                               '      *****Unexpected error checking if the file '
                            || l_done_file_to_find
                            || ' exists.  '
                            || SQLCODE
                            || '.  Message = '
                            || SQLERRM);
                        fnd_file.put_line (
                            fnd_file.LOG,
                            '      Continuing to check for more files as necessary');
                        l_error_count := l_error_count + 1;
                        l_file_error_occurred := TRUE;
                END;

                ----------------------------------------------------
                -- Found the .DONE file.  Now, check for .ERR file
                ----------------------------------------------------
                IF ( (NOT l_file_error_occurred) AND (l_file_exists))
                THEN
                    BEGIN
                        --Done file exists.  Make sure the corresponding error file exists
                        fnd_file.put_line (
                            fnd_file.LOG,
                               '      Done file '
                            || l_done_file_to_find
                            || ' found.');

                        BEGIN
                            UTL_FILE.FGETATTR (l_error_file_directory,
                                               l_error_file_to_find,
                                               l_file_exists,
                                               l_file_len,
                                               l_blocksize);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                fnd_file.put_line (
                                    fnd_file.LOG,
                                       '      *****Unexpected error checking if the file '
                                    || l_error_file_to_find
                                    || ' exists.  '
                                    || SQLCODE
                                    || '.  Message = '
                                    || SQLERRM);
                                fnd_file.put_line (
                                    fnd_file.LOG,
                                    '      Continuing to check for more files as necessary');
                                l_error_count := l_error_count + 1;
                                l_file_error_occurred := TRUE;
                        END;

                        ------------------------------------------------------------------------------------
                        -- Found a .DONE and an .ERR file.  Open the .ERR file for reading
                        ------------------------------------------------------------------------------------
                        IF ( (NOT l_file_error_occurred) AND (l_file_exists))
                        THEN
                            BEGIN
                                fnd_file.put_line (
                                    fnd_file.LOG,
                                       '      Error file '
                                    || l_error_file_to_find
                                    || ' found.');
                                l_error_file :=
                                    UTL_FILE.FOPEN (l_error_file_directory,
                                                    l_error_file_to_find,
                                                    'R');
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    fnd_file.put_line (
                                        fnd_file.LOG,
                                           '      *****Unexpected error opening file '
                                        || l_error_file_to_find
                                        || '.  '
                                        || SQLCODE
                                        || '.  Message = '
                                        || SQLERRM);
                                    fnd_file.put_line (
                                        fnd_file.LOG,
                                        '      Continuing to check for more files as necessary');
                                    l_error_count := l_error_count + 1;
                                    l_file_error_occurred := TRUE;
                            END;

                            ------------------------------------------------------------------------------------
                            -- Loop through all the records in the .ERR file, parse out the individual values,
                            --   and insert them into an error table.  Before inserting them into the error
                            --   table, check to make sure the record for that header, line and file do not
                            --   already exist.  If so, skip that record.
                            -- NOTE: The first record in the error file will contain the header record with
                            --   field names and will be skipped
                            ------------------------------------------------------------------------------------
                            IF (NOT l_file_error_occurred)
                            THEN
                                fnd_file.put_line (
                                    fnd_file.LOG,
                                    '      Error file opened...');
                                fnd_file.put_line (fnd_file.LOG, ' ');
                                l_file_error_count := 0;
                                l_error_file_line := 0;
                                l_file_found_count := l_file_found_count + 1;

                                LOOP
                                    BEGIN
                                        UTL_FILE.GET_LINE (l_error_file,
                                                           s_error_record);
                                        l_error_file_line :=
                                            l_error_file_line + 1;
                                        fnd_file.put_line (
                                            fnd_file.LOG,
                                               '        Line '
                                            || l_error_file_line
                                            || (CASE l_error_file_line
                                                    WHEN 1 THEN '(HEADER)'
                                                    ELSE '        '
                                                END)
                                            || ' read.  Contents = '
                                            || s_error_record);

                                        IF (    (l_error_file_line > 1)
                                            AND (TRIM (s_error_record)
                                                     IS NOT NULL))
                                        THEN             --Skip the header row
                                            BEGIN
                                                SELECT REGEXP_SUBSTR (
                                                           s_error_record,
                                                           '([^|]*)(\||$)',
                                                           1,
                                                           1,
                                                           NULL,
                                                           1)
                                                           AS app,
                                                       REGEXP_SUBSTR (
                                                           s_error_record,
                                                           '([^|]*)(\||$)',
                                                           1,
                                                           2,
                                                           NULL,
                                                           1)
                                                           AS file_name,
                                                       REGEXP_SUBSTR (
                                                           s_error_record,
                                                           '([^|]*)(\||$)',
                                                           1,
                                                           3,
                                                           NULL,
                                                           1)
                                                           AS leg_header_id,
                                                       REGEXP_SUBSTR (
                                                           s_error_record,
                                                           '([^|]*)(\||$)',
                                                           1,
                                                           4,
                                                           NULL,
                                                           1)
                                                           AS leg_line_number,
                                                       REGEXP_SUBSTR (
                                                           s_error_record,
                                                           '([^|]*)(\||$)',
                                                           1,
                                                           5,
                                                           NULL,
                                                           1)
                                                           AS status,
                                                       REGEXP_SUBSTR (
                                                           s_error_record,
                                                           '([^|]*)(\||$)',
                                                           1,
                                                           6,
                                                           NULL,
                                                           1)
                                                           AS error_message,
                                                       REGEXP_SUBSTR (
                                                           s_error_record,
                                                           '([^|]*)(\||$)',
                                                           1,
                                                           7,
                                                           NULL,
                                                           1)
                                                           AS cr_dr,
                                                       REGEXP_SUBSTR (
                                                           s_error_record,
                                                           '([^|]*)(\||$)',
                                                           1,
                                                           8,
                                                           NULL,
                                                           1)
                                                           AS currency,
                                                       REGEXP_SUBSTR (
                                                           s_error_record,
                                                           '([^|]*)(\||$)',
                                                           1,
                                                           9,
                                                           NULL,
                                                           1)
                                                           AS amount,
                                                       REGEXP_SUBSTR (
                                                           s_error_record,
                                                           '([^|]*)(\||$)',
                                                           1,
                                                           10,
                                                           NULL,
                                                           1)
                                                           AS source_coa
                                                  INTO l_app_code_value,
                                                       l_file_name_value,
                                                       l_leg_header_id_value,
                                                       l_leg_line_num_value,
                                                       l_status_value,
                                                       l_error_msg_value,
                                                       l_cr_dr_value,
                                                       l_curr_value,
                                                       l_amount_value,
                                                       l_source_coa_value
                                                  FROM DUAL;
                                            EXCEPTION
                                                WHEN OTHERS
                                                THEN
                                                    fnd_file.put_line (
                                                        fnd_file.LOG,
                                                           '      *****Unexpected error parsing line '
                                                        || l_error_file_line
                                                        || ' in file '
                                                        || l_error_file_to_find
                                                        || '.  '
                                                        || SQLCODE
                                                        || '.  Message = '
                                                        || SQLERRM);
                                                    fnd_file.put_line (
                                                        fnd_file.LOG,
                                                        '      Continuing to process next line');
                                                    l_file_error_count :=
                                                          l_file_error_count
                                                        + 1;
                                                    l_file_error_occurred :=
                                                        TRUE;
                                            END;

                                            IF (NOT l_file_error_occurred)
                                            THEN
                                                BEGIN
                                                    IF (TRIM (
                                                            l_leg_line_num_value)
                                                            IS NULL)
                                                    THEN
                                                        ln_leg_line_num_value :=
                                                            NULL;
                                                    ELSE
                                                        ln_leg_line_num_value :=
                                                            TO_NUMBER (
                                                                l_leg_line_num_value);
                                                    END IF;

                                                    IF (TRIM (l_amount_value)
                                                            IS NULL)
                                                    THEN
                                                        ln_amount_value :=
                                                            NULL;
                                                    ELSE
                                                        ln_amount_value :=
                                                            TO_NUMBER (
                                                                l_amount_value);
                                                    END IF;

                                                    -----------------------------------------------------------------------------------------------
                                                    -- Check to make sure error record doesn't already exist for this header/line/file combination
                                                    -----------------------------------------------------------------------------------------------
                                                    BEGIN
                                                        SELECT COUNT (*)
                                                          INTO l_existing_rec_count
                                                          FROM xxap_ebs_to_ahcs_errs
                                                         WHERE     file_name =
                                                                       rec_error_files_to_check.file_name
                                                               AND leg_ae_header_id =
                                                                       TO_NUMBER (
                                                                           l_leg_header_id_value)
                                                               AND NVL (
                                                                       leg_ae_line_nbr,
                                                                       -99) =
                                                                       NVL (
                                                                           ln_leg_line_num_value,
                                                                           -99);
                                                    EXCEPTION
                                                        WHEN OTHERS
                                                        THEN
                                                            fnd_file.put_line (
                                                                fnd_file.LOG,
                                                                   '      *****Unexpected error checking if line '
                                                                || l_error_file_line
                                                                || ' from file '
                                                                || l_error_file_to_find
                                                                || ' already exists in error table.');
                                                            fnd_file.put_line (
                                                                fnd_file.LOG,
                                                                   '        '
                                                                || SQLCODE
                                                                || '.  Message = '
                                                                || SQLERRM);
                                                            fnd_file.put_line (
                                                                fnd_file.LOG,
                                                                '      Continuing to process next line');
                                                            l_file_error_count :=
                                                                  l_file_error_count
                                                                + 1;
                                                            l_file_error_occurred :=
                                                                TRUE;
                                                            l_existing_rec_count :=
                                                                -1;
                                                    END;

                                                    IF (l_existing_rec_count =
                                                            0)
                                                    THEN
                                                        BEGIN
                                                            INSERT
                                                              INTO xxap_ebs_to_ahcs_errs (
                                                                       source_system,
                                                                       file_name,
                                                                       leg_ae_header_id,
                                                                       leg_ae_line_nbr,
                                                                       status,
                                                                       error_message,
                                                                       cr_dr,
                                                                       currency,
                                                                       amount,
                                                                       source_coa,
                                                                       creation_date,
                                                                       created_by,
                                                                       last_update_date,
                                                                       last_updated_by,
                                                                       last_update_login,
                                                                       conc_program_id,
                                                                       request_id)
                                                                VALUES (
                                                                           l_app_code_value,
                                                                           l_file_name_value,
                                                                           TO_NUMBER (
                                                                               l_leg_header_id_value),
                                                                           ln_leg_line_num_value,
                                                                           'NEW',
                                                                           l_error_msg_value,
                                                                           l_cr_dr_value,
                                                                           l_curr_value,
                                                                           ln_amount_value,
                                                                           l_source_coa_value,
                                                                           SYSDATE,
                                                                           fnd_global.user_id,
                                                                           SYSDATE,
                                                                           fnd_global.user_id,
                                                                           fnd_global.login_id,
                                                                           fnd_global.conc_program_id,
                                                                           fnd_global.conc_request_id);

                                                            fnd_file.put_line (
                                                                fnd_file.LOG,
                                                                '          Record successfully inserted into error table for reprocessing');
                                                        EXCEPTION
                                                            WHEN OTHERS
                                                            THEN
                                                                fnd_file.put_line (
                                                                    fnd_file.LOG,
                                                                       '      *****Unexpected error inserting line '
                                                                    || l_error_file_line
                                                                    || ' from file '
                                                                    || l_error_file_to_find
                                                                    || ' into error table.');
                                                                fnd_file.put_line (
                                                                    fnd_file.LOG,
                                                                       '        '
                                                                    || SQLCODE
                                                                    || '.  Message = '
                                                                    || SQLERRM);
                                                                fnd_file.put_line (
                                                                    fnd_file.LOG,
                                                                    '      Continuing to process next line');
                                                                l_file_error_count :=
                                                                      l_file_error_count
                                                                    + 1;
                                                                l_file_error_occurred :=
                                                                    TRUE;
                                                        END;
                                                    ELSE
                                                        fnd_file.put_line (
                                                            fnd_file.LOG,
                                                            '          Record already exists for this file / header id / line number.  Skipping');
                                                    END IF;
                                                END;
                                            END IF;
                                        ELSIF (l_error_file_line = 1)
                                        THEN
                                            fnd_file.put_line (
                                                fnd_file.LOG,
                                                '          Header record skipped');
                                        ELSIF (TRIM (s_error_record) IS NULL)
                                        THEN
                                            fnd_file.put_line (
                                                fnd_file.LOG,
                                                '          Blank record skipped');
                                        END IF;
                                    EXCEPTION
                                        WHEN NO_DATA_FOUND
                                        THEN
                                            fnd_file.put_line (
                                                fnd_file.LOG,
                                                   '      End of file '
                                                || l_error_file_to_find
                                                || ' reached.');
                                            fnd_file.put_line (fnd_file.LOG,
                                                               ' ');
                                            EXIT;
                                        WHEN OTHERS
                                        THEN
                                            fnd_file.put_line (
                                                fnd_file.LOG,
                                                   '      *****Unexpected error processing file '
                                                || l_error_file_to_find
                                                || '.');
                                            fnd_file.put_line (
                                                fnd_file.LOG,
                                                   '        '
                                                || SQLCODE
                                                || '.  Message = '
                                                || SQLERRM);
                                            fnd_file.put_line (
                                                fnd_file.LOG,
                                                '      Continuing to process next line');
                                            l_file_error_count :=
                                                l_file_error_count + 1;
                                            l_file_error_occurred := TRUE;
                                    END;
                                END LOOP;

                                fnd_file.put_line (
                                    fnd_file.LOG,
                                       '      File '
                                    || l_error_file_to_find
                                    || ' complete.');
                                fnd_file.put_line (
                                    fnd_file.LOG,
                                       '        '
                                    || l_error_file_line
                                    || '  lines read');
                                fnd_file.put_line (
                                    fnd_file.LOG,
                                       '        '
                                    || l_file_error_count
                                    || ' errors occurred');
                                UTL_FILE.FCLOSE (l_error_file);
                            END IF;

                            -----------------------------------------------
                            --Copy the error file to the archive directory
                            -----------------------------------------------
                            BEGIN
                                UTL_FILE.FCOPY (
                                    src_location    => l_error_file_directory,
                                    src_filename    => l_error_file_to_find,
                                    dest_location   => l_error_arch_directory,
                                    dest_filename   => l_error_file_to_find);
                                fnd_file.put_line (
                                    fnd_file.LOG,
                                       '      Error file archived to '
                                    || l_error_arch_directory
                                    || '.');
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    fnd_file.put_line (
                                        fnd_file.LOG,
                                           '      *****Unexpected error archiving file '
                                        || l_error_file_to_find);
                                    fnd_file.put_line (
                                        fnd_file.LOG,
                                           '        '
                                        || SQLCODE
                                        || '.  Message = '
                                        || SQLERRM);
                                    l_file_error_occurred := TRUE;
                            END;

                            -----------------------------------------------
                            --Remove the error file from the error directory
                            -----------------------------------------------
                            BEGIN
                                UTL_FILE.FREMOVE (
                                    location   => l_error_file_directory,
                                    filename   => l_error_file_to_find);
                                fnd_file.put_line (
                                    fnd_file.LOG,
                                       '      Error file deleted from '
                                    || l_error_file_directory
                                    || '.');
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    fnd_file.put_line (
                                        fnd_file.LOG,
                                           '      *****Unexpected error deleting file '
                                        || l_error_file_to_find);
                                    fnd_file.put_line (
                                        fnd_file.LOG,
                                           '        '
                                        || SQLCODE
                                        || '.  Message = '
                                        || SQLERRM);
                                    l_file_error_occurred := TRUE;
                            END;

                            -----------------------------------------------
                            --Copy the done file to the archive directory
                            -----------------------------------------------
                            BEGIN
                                UTL_FILE.FCOPY (
                                    src_location    => l_error_file_directory,
                                    src_filename    => l_done_file_to_find,
                                    dest_location   => l_error_arch_directory,
                                    dest_filename   => l_done_file_to_find);
                                fnd_file.put_line (
                                    fnd_file.LOG,
                                       '      Done file archived to '
                                    || l_error_arch_directory
                                    || '.');
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    fnd_file.put_line (
                                        fnd_file.LOG,
                                           '      *****Unexpected error archiving file '
                                        || l_done_file_to_find);
                                    fnd_file.put_line (
                                        fnd_file.LOG,
                                           '        '
                                        || SQLCODE
                                        || '.  Message = '
                                        || SQLERRM);
                                    l_file_error_occurred := TRUE;
                            END;

                            -------------------------------------------------
                            -- Remove the done file from the error directory
                            -------------------------------------------------
                            BEGIN
                                UTL_FILE.FREMOVE (
                                    location   => l_error_file_directory,
                                    filename   => l_done_file_to_find);
                                fnd_file.put_line (
                                    fnd_file.LOG,
                                       '      Done file deleted from '
                                    || l_error_file_directory
                                    || '.');
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    fnd_file.put_line (
                                        fnd_file.LOG,
                                           '      *****Unexpected error deleting file '
                                        || l_done_file_to_find);
                                    fnd_file.put_line (
                                        fnd_file.LOG,
                                           '        '
                                        || SQLCODE
                                        || '.  Message = '
                                        || SQLERRM);
                                    l_file_error_occurred := TRUE;
                            END;

                            fnd_file.put_line (fnd_file.LOG, '  ');

                            -----------------------------------------------------------------
                            -- Update control table to show that the error file was received
                            -----------------------------------------------------------------
                            BEGIN
                                fnd_file.put_line (
                                    fnd_file.LOG,
                                       '  Beginning FA control table updates at '
                                    || TO_CHAR (SYSDATE,
                                                'YYYY/MM/DD HH24:MI:SS'));

                                UPDATE xxwes_ebs_to_ahcs_ctl
                                   SET status = 'ERROR FILE RECEIVED',
                                       last_update_date = SYSDATE
                                 WHERE     application_code = 'XXAP'
                                       AND file_name =
                                               rec_error_files_to_check.file_name;

                                fnd_file.put_line (
                                    fnd_file.LOG,
                                       '  Completed FA control table updates at '
                                    || TO_CHAR (SYSDATE,
                                                'YYYY/MM/DD HH24:MI:SS'));
                                fnd_file.put_line (
                                    fnd_file.LOG,
                                    '    Records updated = ' || SQL%ROWCOUNT);
                                fnd_file.put_line (fnd_file.LOG, ' ');
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    p_out_err_msg :=
                                           '*****Unexpected error updating status to ERROR FILE RECEIVED for file '
                                        || rec_error_files_to_check.file_name
                                        || '.  '
                                        || SQLCODE
                                        || '.  Message = '
                                        || SQLERRM;
                                    p_out_ret_code := 2;
                                    RETURN;
                            END;

                            --
                            --Update Hdr and Line Tables with error
                            --
                            BEGIN
                                UPDATE xxwes_ap_ahcs_hdr_stg hdr
                                   SET status = 'ERROR'
                                 WHERE     file_name =
                                               rec_error_files_to_check.file_name
                                       AND EXISTS
                                               (SELECT 1
                                                  FROM xxap_ebs_to_ahcs_errs
                                                       err
                                                 WHERE     err.file_name =
                                                               hdr.file_name
                                                       AND err.leg_ae_header_id =
                                                               hdr.leg_ae_header_id);

                                fnd_file.put_line (
                                    fnd_file.LOG,
                                       'No. of Header Records marked as Error: '
                                    || SQL%ROWCOUNT);

                                UPDATE xxwes_ap_ahcs_line_stg line
                                   SET status = 'ERROR'
                                 WHERE     1 = 1
                                       AND file_name =
                                               rec_error_files_to_check.file_name
                                       AND EXISTS
                                               (SELECT 1
                                                  FROM xxap_ebs_to_ahcs_errs
                                                       err
                                                 WHERE     err.file_name =
                                                               line.file_name
                                                       AND err.leg_ae_header_id =
                                                               line.leg_ae_header_id);

                                fnd_file.put_line (
                                    fnd_file.LOG,
                                       'No. of Line Records marked as Error: '
                                    || SQL%ROWCOUNT);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    fnd_file.put_line (
                                        fnd_file.LOG,
                                           'Unexpected error while updating header and line table records to Error: '
                                        || SQLERRM);
                            END;

                            ----------------------------------------------------------------
                            --Commit changes to error table and control table for this file
                            ----------------------------------------------------------------
                            COMMIT;
                        ELSE
                            fnd_file.put_line (
                                fnd_file.LOG,
                                   '      Error file '
                                || l_error_file_to_find
                                || ' not found.  Continuing to see if more error files are ready for processing...');
                            fnd_file.put_line (fnd_file.LOG, ' ');
                            l_error_count := l_error_count + 1;
                        END IF;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            IF (cur_error_files_to_check%ISOPEN)
                            THEN
                                CLOSE cur_error_files_to_check;
                            END IF;

                            p_out_err_msg :=
                                   '*****Unexpected error checking for and processing error file.  '
                                || SQLCODE
                                || '.  Message = '
                                || SQLERRM;
                            p_out_ret_code := 2;
                            fnd_file.put_line (fnd_file.LOG, p_out_err_msg);
                            email_error_notification (p_out_err_msg,
                                                      p_in_chr_err_email);
                            RETURN;
                    END;
                ELSE
                    IF (NOT l_file_error_occurred)
                    THEN
                        fnd_file.put_line (
                            fnd_file.LOG,
                               '      DONE file '
                            || l_done_file_to_find
                            || ' not found.  Continuing to see if more error files are ready for processing...');
                        fnd_file.put_line (fnd_file.LOG, ' ');
                    END IF;
                END IF;
            END LOOP;

            fnd_file.put_line (
                fnd_file.LOG,
                   '  Completed cursor of files to check for at '
                || TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS'));

            IF (cur_error_files_to_check%ISOPEN)
            THEN
                CLOSE cur_error_files_to_check;
            END IF;

            IF (l_error_count > 0)
            THEN
                p_out_err_msg :=
                       'At least 1 error occurred.  Please review log file for request id '
                    || l_current_request_id
                    || ' for more details';
                p_out_ret_code := 2;
                fnd_file.put_line (fnd_file.LOG, ' ');
                email_error_notification (p_out_err_msg, p_in_chr_err_email);
                RETURN;
            ELSE
                p_out_err_msg := 'Completed successfully';
                fnd_file.put_line (fnd_file.LOG, ' ');
                fnd_file.put_line (fnd_file.LOG, p_out_err_msg);

                IF (l_file_found_count > 0)
                THEN
                    fnd_file.put_line (
                        fnd_file.LOG,
                           '  '
                        || l_file_found_count
                        || ' error files found and processed');
                ELSE
                    fnd_file.put_line (fnd_file.LOG,
                                       '  No error files found');
                END IF;

                p_out_ret_code := 0;
                RETURN;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                IF (cur_error_files_to_check%ISOPEN)
                THEN
                    CLOSE cur_error_files_to_check;
                END IF;

                p_out_err_msg :=
                       '*****Unexpected error looping through ERROR files to check for.  '
                    || SQLCODE
                    || '.  Message = '
                    || SQLERRM;
                p_out_ret_code := 2;
                fnd_file.put_line (fnd_file.LOG, p_out_err_msg);
                email_error_notification (p_out_err_msg, p_in_chr_err_email);
                RETURN;
        END;
    END load_errors;
END XXAP_AHCS_EXTRACT;
/