create or replace PACKAGE BODY wsc_ahcs_reprocessing_pkg AS 
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PACKAGE             WSC_GL_AL_VALIDATION_TRANSFORMATION_PKG AS
------------------------------------------------------------------------------------------
-- COPYRIGHT (C) Wesco Inc.
--
-- Protected as an unpublished work.  All Rights Reserved.
--
-- The computer program listings, specifications, and documentation herein
-- are the property of Wesco Incorporated and shall not be
-- reproduced, copied, disclosed, or used in whole or in part for any
-- reason without the express written permission of Wesco Incorporated.
--
-- DESCRIPTION:
-- This package contains supporting procedures required for validation & transformation of data
-- staged into the staging tables that hosts data provided from the source sub-ledger applications and
-- destined for AHCS.
-- 
--
-- FILE LOCATION AND VERSION
-- $Header: WSC_GL_AL_VALIDATION_TRANSFORMATION_PKG.pkg
--
-- PRE-REQUISITES
-- The package makes an implicit call to an external packaged function, wsc_gl_coa_mapping_pkg.coa_mapping for 
-- deriving the COA segment values in the future state COA structure on the basis of legacy COA structure.
-- This package wsc_gl_coa_mapping_pkg must be compiled before installing this package.
--
-- The following staging tables must be created before 
-- 1. WSC_AHCS_AP_TXN_LINE_T
-- 2. WSC_AHCS_INT_STATUS_T 
-- 3. WSC_AHCS_INT_CONTROL_T
-- 4. wsc_gl_legal_entities_t
-- 5. wsc_gl_ccid_mapping_t
--

--
-- PROCEDURE/ FUNCTION LIST:
--
--     Procedure validate
--     Procedure transform
--     Procedure is_date

--
-- MODIFICATION HISTORY :
--
-- Name                              Date      Ver   Description
-- =================              ===========  ===   ====================================
-- Deloitte Consulting            24-JULY-2021  1.0   Created
--
----------------------------------------------------------------------------------------


    PROCEDURE reprocessing_async (
        p_file_name IN VARCHAR2
    ) IS

        CURSOR cur_get_file_details IS
        SELECT
            batch_id,
            source_application
        FROM
            wsc_ahcs_int_control_t
        WHERE
            file_name = p_file_name;

        lv_batch_id        NUMBER;
        lv_src_application VARCHAR2(100);
    BEGIN
        OPEN cur_get_file_details;
        FETCH cur_get_file_details INTO
            lv_batch_id,
            lv_src_application;
        CLOSE cur_get_file_details;
        logging_insert(NULL, lv_batch_id, 21, 'file derived', NULL,
                      sysdate);
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'IN PROGRESS'
        WHERE
            batch_id = lv_batch_id;

        COMMIT;
    /*    IF upper(lv_src_application) IN ( 'MF INV' ) THEN
            DELETE FROM wsc_ahcs_mfinv_txn_line_t l
            WHERE
                    batch_id = lv_batch_id
                AND line_seq_number = '-99999'
                AND EXISTS (
                    SELECT
                        1
                    FROM
                        wsc_ahcs_int_status_t s
                    WHERE
                        ( accounting_status IS NULL
                          OR accounting_status IN ( 'IMP_ACC_ERROR', 'CRE_ACC_ERROR' ) )
                        AND l.line_id = s.line_id
                        AND l.header_id = s.header_id
                        AND l.batch_id = s.batch_id
                )
                AND interface_id IN ( 'AIIB', 'INTR', 'INVT' );

            COMMIT;
            DELETE FROM wsc_ahcs_int_status_t
            WHERE
                    batch_id = lv_batch_id
                AND legacy_line_number = '-99999'
                AND ( accounting_status IS NULL
                      OR accounting_status IN ( 'IMP_ACC_ERROR', 'CRE_ACC_ERROR' ) )
                AND interface_id IN ( 'AIIB', 'INTR', 'INVT' );

            COMMIT;
        END IF; */

--        IF upper(lv_src_application) IN ( 'MF AR' ) THEN
--            DELETE FROM wsc_ahcs_mfar_txn_line_t line
--            WHERE
--                    batch_id = lv_batch_id
--                AND line_seq_number = '-99999'
--                AND EXISTS (
--                    SELECT
--                        1
--                    FROM
--                        wsc_ahcs_int_status_t stats
--                    WHERE
--                        ( accounting_status IS NULL
--                          OR accounting_status IN ( 'IMP_ACC_ERROR', 'CRE_ACC_ERROR' ) )
--                        AND line.batch_id = stats.batch_id
--                        AND line.header_id = stats.header_id
--                        AND line.line_id = stats.line_id
--                )
--                AND interface_id IN ( 'SALE' );
--
--            COMMIT;
--            DELETE FROM wsc_ahcs_int_status_t
--            WHERE
--                    batch_id = lv_batch_id
--                AND legacy_line_number = '-99999'
--                AND ( accounting_status IS NULL
--                      OR accounting_status IN ( 'IMP_ACC_ERROR', 'CRE_ACC_ERROR' ) )
--                AND interface_id IN ( 'SALE' );
--
--            COMMIT;
--        END IF;

        IF upper(lv_src_application) LIKE 'EBS%AP%' THEN
            logging_insert(NULL, lv_batch_id, 22, 'before scheduler job call', NULL,
                          sysdate);
            dbms_scheduler.create_job(job_name => 'AP_REPROCESSING_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_AP_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'AP_REPROCESSING ');

            logging_insert(NULL, lv_batch_id, 23, 'after scheduler job call', NULL,
                          sysdate);
        ELSIF upper(lv_src_application) LIKE 'EBS%AR%' THEN
            dbms_scheduler.create_job(job_name => 'AR_REPROCESSING_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_AR_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'AR_REPROCESSING ');
        ELSIF upper(lv_src_application) LIKE 'EBS%FA%' THEN
            dbms_scheduler.create_job(job_name => 'FA_REPROCESSING_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_FA_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'FA_REPROCESSING ');
        ELSIF upper(lv_src_application) LIKE 'ERP%POC%' THEN
            dbms_scheduler.create_job(job_name => 'POC_REPROCESSING_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_POC_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'POC_REPROCESSING ');
        ELSIF upper(lv_src_application) LIKE 'CENTRAL%INV%' THEN
            dbms_scheduler.create_job(job_name => 'CENTRAL_REPROCESSING_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
		   WSC_AHCS_CENTRAL_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'CENTRAL_REPROCESSING');
        ELSIF upper(lv_src_application) LIKE 'SALES%COM%' THEN
            dbms_scheduler.create_job(job_name => 'SALES_REPROCESSING_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
		   WSC_AHCS_CENTRAL_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'CENTRAL_REPROCESSING');
        ELSIF upper(lv_src_application) LIKE 'MF%AP%' THEN
            IF upper(substr(p_file_name, 0, instr(p_file_name, '_', 1, 3) - 1)) LIKE 'MF_AP_HDR' THEN
                dbms_scheduler.create_job(job_name => 'MFAP_REPROCESSING_'
                                                      || p_file_name
                                                      || '_'
                                                      || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                      'BEGIN 
                WSC_AHCS_MFAP_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_jti_mfap_reprocessing('
                                                                                                                                       ||
                                                                                                                                       lv_batch_id
                                                                                                                                       ||
                                                                                                                                       ');
         END;', enabled => true, auto_drop => true,
                                         comments => 'MFAP_REPROCESSING ');

            ELSE
                dbms_scheduler.create_job(job_name => 'MFAP_REPROCESSING_'
                                                      || p_file_name
                                                      || '_'
                                                      || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                      'BEGIN 
           WSC_AHCS_MFAP_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                       ||
                                                                                                                                       lv_batch_id
                                                                                                                                       ||
                                                                                                                                       ');
         END;', enabled => true, auto_drop => true,
                                         comments => 'MFAP_REPROCESSING ');
            END IF;
        ELSIF upper(lv_src_application) LIKE 'MF%AR%' THEN
            IF upper(substr(p_file_name, 0, instr(p_file_name, '_', 1, 3) - 1)) LIKE 'MF_AR_HDR' THEN
                dbms_scheduler.create_job(job_name => 'MFAR_REPROCESSING_'
                                                      || p_file_name
                                                      || '_'
                                                      || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                      'BEGIN 
           WSC_AHCS_MFAR_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_jti_mfar_reprocess('
                                                                                                                                       ||
                                                                                                                                       lv_batch_id
                                                                                                                                       ||
                                                                                                                                       ');
         END;', enabled => true, auto_drop => true,
                                         comments => 'MFAR_REPROCESSING ');

            ELSE
                dbms_scheduler.create_job(job_name => 'MFAR_REPROCESSING_'
                                                      || p_file_name
                                                      || '_'
                                                      || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                      'BEGIN 
           WSC_AHCS_MFAR_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                       ||
                                                                                                                                       lv_batch_id
                                                                                                                                       ||
                                                                                                                                       ');
         END;', enabled => true, auto_drop => true,
                                         comments => 'MFAR_REPROCESSING ');
            END IF;
        ELSIF upper(lv_src_application) LIKE '%LEASES%' THEN
            dbms_scheduler.create_job(job_name => 'LEASES_REPROCESSING_'
                                                  || replace(replace(p_file_name, ' ', ''), '-', '_')
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_LHIN_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'LEASES_REPROCESSING ');
        ELSIF upper(lv_src_application) LIKE '%CLOUDPAY%' THEN
            dbms_scheduler.create_job(job_name => 'CLOUDPAY_REPROCESSING_'
                                                  || replace(replace(p_file_name, ' ', ''), '-', '_')
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           wsc_ahcs_cp_validation_transformation_pkg.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'CLOUDPAY_REPROCESSING ');
        ELSIF upper(lv_src_application) LIKE 'PS%FA' THEN
            dbms_scheduler.create_job(job_name => 'PSFA_REPROCESSING_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           wsc_ahcs_PSFA_validation_transformation_pkg.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'PSFA_REPROCESSING ');
        ELSIF upper(lv_src_application) LIKE 'TW' THEN
            dbms_scheduler.create_job(job_name => 'TW_REPROCESSING_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_TW_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'TW_REPROCESSING ');
        ELSIF upper(lv_src_application) LIKE 'MF INV' THEN
            IF upper(substr(p_file_name, 0, instr(p_file_name, '_', 1, 3) - 1)) LIKE 'MF_IV_HDR' THEN
                dbms_scheduler.create_job(job_name => 'MFINV_REPROCESSING_'
                                                      || p_file_name
                                                      || '_'
                                                      || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                      'BEGIN 
           WSC_AHCS_MFINV_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_jti_mfinv_reprocess('
                                                                                                                                       ||
                                                                                                                                       lv_batch_id
                                                                                                                                       ||
                                                                                                                                       ');
         END;', enabled => true, auto_drop => true,
                                         comments => 'MFINV_REPROCESSING ');

            ELSE
                dbms_scheduler.create_job(job_name => 'MFINV_REPROCESSING_'
                                                      || p_file_name
                                                      || '_'
                                                      || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                      'BEGIN 
           WSC_AHCS_MFINV_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                       ||
                                                                                                                                       lv_batch_id
                                                                                                                                       ||
                                                                                                                                       ');
         END;', enabled => true, auto_drop => true,
                                         comments => 'MFINV_REPROCESSING ');
            END IF;
        ELSIF upper(lv_src_application) LIKE 'ECLIPSE' THEN
            dbms_scheduler.create_job(job_name => 'ECLIPSE_REPROCESSING_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_ECLIPSE_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'ECLIPSE_REPROCESSING ');
        ELSIF upper(lv_src_application) LIKE 'CONCUR' THEN
            dbms_scheduler.create_job(job_name => 'CONCUR_REPROCESSING_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_CNCR_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'CONCUR_REPROCESSING ');
        ELSIF upper(lv_src_application) LIKE 'SXE' THEN
            dbms_scheduler.create_job(job_name => 'SXE_REPROCESSING_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_SXE_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'SXE_REPROCESSING ');
        END IF;

    END reprocessing_async;

    PROCEDURE account_reprocessing_async (
        p_file_name IN VARCHAR2
    ) IS

        CURSOR cur_get_file_details IS
        SELECT
            batch_id,
            source_application
        FROM
            wsc_ahcs_int_control_t
        WHERE
            file_name = p_file_name;

        lv_batch_id        NUMBER;
        lv_src_application VARCHAR2(100);
    BEGIN
        OPEN cur_get_file_details;
        FETCH cur_get_file_details INTO
            lv_batch_id,
            lv_src_application;
        CLOSE cur_get_file_details;
        UPDATE wsc_ahcs_int_control_t
        SET
            status = 'IN PROGRESS'
        WHERE
            batch_id = lv_batch_id;

        COMMIT;
        IF upper(lv_src_application) NOT IN ( 'MF AP', 'MF AR', 'MF INV' ) THEN
            UPDATE wsc_ahcs_int_status_t
            SET
                accounting_status = NULL,
                status = 'TRANSFORM_FAILED',
                attribute2 = 'TRANSFORM_FAILED',
                group_id = NULL
            WHERE
                    batch_id = lv_batch_id
                AND accounting_status IN ( 'CRE_ACC_ERROR', 'IMP_ACC_ERROR' );
--            and application not in ('MF AP','MF AR','MF INV');
            COMMIT;
        END IF;

--        IF upper(lv_src_application) IN ( 'MF INV' ) THEN
--            DELETE FROM wsc_ahcs_mfinv_txn_line_t l
--            WHERE
--                    batch_id = lv_batch_id
--                AND line_seq_number = '-99999'
--                AND EXISTS (
--                    SELECT
--                        1
--                    FROM
--                        wsc_ahcs_int_status_t s
--                    WHERE
--                        ( accounting_status IS NULL
--                          OR accounting_status IN ( 'IMP_ACC_ERROR', 'CRE_ACC_ERROR' ) )
--                        AND l.line_id = s.line_id
--                        AND l.header_id = s.header_id
--                        AND l.batch_id = s.batch_id
--                )
--                AND interface_id IN ( 'AIIB', 'INTR', 'INVT' );
--
--            COMMIT;
--            DELETE FROM wsc_ahcs_int_status_t
--            WHERE
--                    batch_id = lv_batch_id
--                AND legacy_line_number = '-99999'
--                AND ( accounting_status IS NULL
--                      OR accounting_status IN ( 'IMP_ACC_ERROR', 'CRE_ACC_ERROR' ) )
--                AND interface_id IN ( 'AIIB', 'INTR', 'INVT' );
--
--            COMMIT;
--        END IF;
--
--        IF upper(lv_src_application) IN ( 'MF AR' ) THEN
--            DELETE FROM wsc_ahcs_mfar_txn_line_t line
--            WHERE
--                    batch_id = lv_batch_id
--                AND line_seq_number = '-99999'
--                AND EXISTS (
--                    SELECT
--                        1
--                    FROM
--                        wsc_ahcs_int_status_t stats
--                    WHERE
--                        ( accounting_status IS NULL
--                          OR accounting_status IN ( 'IMP_ACC_ERROR', 'CRE_ACC_ERROR' ) )
--                        AND line.batch_id = stats.batch_id
--                        AND line.header_id = stats.header_id
--                        AND line.line_id = stats.line_id
--                )
--                AND interface_id IN ( 'SALE' );
--
--            COMMIT;
--            DELETE FROM wsc_ahcs_int_status_t
--            WHERE
--                    batch_id = lv_batch_id
--                AND legacy_line_number = '-99999'
--                AND ( accounting_status IS NULL
--                      OR accounting_status IN ( 'IMP_ACC_ERROR', 'CRE_ACC_ERROR' ) )
--                AND interface_id IN ( 'SALE' );
--
--            COMMIT;
--        END IF;

        logging_insert(NULL, lv_batch_id, 21, 'file derived', NULL,
                      sysdate);
        IF upper(lv_src_application) LIKE 'EBS%AP%' THEN
            logging_insert(NULL, lv_batch_id, 22, 'before scheduler job call', NULL,
                          sysdate);
            dbms_scheduler.create_job(job_name => 'AP_ACC_ERROR_REPRO_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_AP_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'AP_ACC_ERROR_REPRO ');

            logging_insert(NULL, lv_batch_id, 23, 'after scheduler job call', NULL,
                          sysdate);
        ELSIF upper(lv_src_application) LIKE 'EBS%AR%' THEN
            dbms_scheduler.create_job(job_name => 'AR_ACC_ERROR_REPRO_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_AR_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'AR_ACC_ERROR_REPRO ');
        ELSIF upper(lv_src_application) LIKE 'EBS%FA%' THEN
            dbms_scheduler.create_job(job_name => 'FA_ACC_ERROR_REPRO_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_FA_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'FA_ACC_ERROR_REPRO ');
        ELSIF upper(lv_src_application) LIKE 'ERP%POC%' THEN
            dbms_scheduler.create_job(job_name => 'POC_ACC_ERROR_REPRO_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_POC_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'POC_ACC_ERROR_REPRO ');
        ELSIF upper(lv_src_application) LIKE 'CENTRAL%INV%' THEN
            dbms_scheduler.create_job(job_name => 'CENTRAL_ACC_ERROR_REPRO_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
		   WSC_AHCS_CENTRAL_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'CENTRAL_ACC_ERROR_REPRO');
        ELSIF upper(lv_src_application) LIKE 'SALES%COM%' THEN
            dbms_scheduler.create_job(job_name => 'SALES_ACC_ERROR_REPRO_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
		   WSC_AHCS_CENTRAL_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'CENTRAL_ACC_ERROR_REPRO');
        ELSIF upper(lv_src_application) LIKE 'MF%AP%' THEN
        --update hdr and line (TXN NUMBER)
            logging_insert('ANIXTER AP', lv_batch_id, 5000, 'accounting repro start header table update', NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_mfap_txn_header_t h
            USING (
                      SELECT DISTINCT
                          header_id,
                          batch_id,
                          accounting_status
                      FROM
                          wsc_ahcs_int_status_t
                      WHERE
                          accounting_status IN ( 'CRE_ACC_ERROR', 'IMP_ACC_ERROR' )
                          AND batch_id = lv_batch_id
                  )
            s ON ( s.accounting_status IN ( 'CRE_ACC_ERROR', 'IMP_ACC_ERROR' )
                   AND h.header_id = s.header_id
                   AND h.batch_id = s.batch_id
                   AND s.batch_id = lv_batch_id )
            WHEN MATCHED THEN UPDATE
            SET transaction_number = ( substr(transaction_number, 0, decode(instr(transaction_number, '_'), 0, length(transaction_number),
            instr(transaction_number, '_') - 1)) );
--        merge into wsc_ahcs_mfap_txn_header_t h using wsc_ahcs_int_status_t s
--        on (s.ACCOUNTING_STATUS in ('CRE_ACC_ERROR','IMP_ACC_ERROR') and h.header_id = s.header_id
--          AND h.batch_id = s.batch_id
--          AND h.batch_id = lv_batch_id)
--          WHEN MATCHED THEN
--          update set transaction_number =(substr(transaction_number, 0,decode(instr(transaction_number,'_'),
--          0,length(transaction_number),instr(transaction_number,'_')-1)));

            logging_insert('ANIXTER AP', lv_batch_id, 5001, 'accounting repro start line table update', NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_mfap_txn_line_t l
            USING wsc_ahcs_int_status_t s ON ( s.accounting_status IN ( 'CRE_ACC_ERROR', 'IMP_ACC_ERROR' )
                                               AND l.header_id = s.header_id
                                               AND l.line_id = s.line_id
                                               AND l.batch_id = s.batch_id
                                               AND l.batch_id = lv_batch_id )
            WHEN MATCHED THEN UPDATE
            SET transaction_number = ( substr(transaction_number, 0, decode(instr(transaction_number, '_'), 0, length(transaction_number),
            instr(transaction_number, '_') - 1)) ),
                attribute5 = NULL;

            logging_insert('ANIXTER AP', lv_batch_id, 5002, 'accounting repro start status table update', NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                accounting_status = NULL,
                status = 'TRANSFORM_FAILED',
                attribute2 = 'TRANSFORM_FAILED',
                attribute3 = substr(attribute3, 0, decode(instr(attribute3, '_'), 0, length(attribute3), instr(attribute3, '_') - 1)),
                group_id = NULL
            WHERE
                    batch_id = lv_batch_id
                AND accounting_status IN ( 'CRE_ACC_ERROR', 'IMP_ACC_ERROR' );

            COMMIT;
            logging_insert('ANIXTER AP', lv_batch_id, 5003, 'accounting repro start repro job', NULL,
                          sysdate);
            IF upper(substr(p_file_name, 0, instr(p_file_name, '_', 1, 3) - 1)) LIKE 'MF_AP_HDR' THEN
                dbms_scheduler.create_job(job_name => 'MFAP_ACC_ERROR_REPRO_'
                                                      || p_file_name
                                                      || '_'
                                                      || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                      'BEGIN 
           WSC_AHCS_MFAP_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_jti_mfap_reprocessing('
                                                                                                                                       ||
                                                                                                                                       lv_batch_id
                                                                                                                                       ||
                                                                                                                                       ');
         END;', enabled => true, auto_drop => true,
                                         comments => 'MFAP_ACC_ERROR_REPRO ');
            ELSE
                dbms_scheduler.create_job(job_name => 'MFAP_ACC_ERROR_REPRO_'
                                                      || p_file_name
                                                      || '_'
                                                      || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                      'BEGIN 
           WSC_AHCS_MFAP_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                       ||
                                                                                                                                       lv_batch_id
                                                                                                                                       ||
                                                                                                                                       ');
         END;', enabled => true, auto_drop => true,
                                         comments => 'MFAP_ACC_ERROR_REPRO ');
            END IF;

        ELSIF upper(lv_src_application) LIKE 'MF%AR%' THEN
            MERGE INTO wsc_ahcs_mfar_txn_header_t h
            USING (
                      SELECT DISTINCT
                          header_id,
                          batch_id,
                          accounting_status
                      FROM
                          wsc_ahcs_int_status_t
                      WHERE
                          accounting_status IN ( 'CRE_ACC_ERROR', 'IMP_ACC_ERROR' )
                          AND batch_id = lv_batch_id
                  )
            s ON ( s.accounting_status IN ( 'CRE_ACC_ERROR', 'IMP_ACC_ERROR' )
                   AND h.header_id = s.header_id
                   AND h.batch_id = s.batch_id
                   AND s.batch_id = lv_batch_id )
            WHEN MATCHED THEN UPDATE
            SET transaction_number = ( substr(transaction_number, 0, decode(instr(transaction_number, '_'), 0, length(transaction_number),
            instr(transaction_number, '_') - 1)) );

            MERGE INTO wsc_ahcs_mfar_txn_line_t l
            USING wsc_ahcs_int_status_t s ON ( s.accounting_status IN ( 'CRE_ACC_ERROR', 'IMP_ACC_ERROR' )
                                               AND l.header_id = s.header_id
                                               AND l.line_id = s.line_id
                                               AND l.batch_id = s.batch_id
                                               AND l.batch_id = lv_batch_id )
            WHEN MATCHED THEN UPDATE
            SET transaction_number = ( substr(transaction_number, 0, decode(instr(transaction_number, '_'), 0, length(transaction_number),
            instr(transaction_number, '_') - 1)) ),
                attribute5 = NULL;

            UPDATE wsc_ahcs_int_status_t
            SET
                accounting_status = NULL,
                status = 'TRANSFORM_FAILED',
                attribute2 = 'TRANSFORM_FAILED',
                attribute3 = substr(attribute3, 0, decode(instr(attribute3, '_'), 0, length(attribute3), instr(attribute3, '_') - 1)),
                group_id = NULL,
                attribute6=-1
            WHERE
                    batch_id = lv_batch_id
                AND accounting_status IN ( 'CRE_ACC_ERROR', 'IMP_ACC_ERROR' );

            COMMIT;
            IF upper(substr(p_file_name, 0, instr(p_file_name, '_', 1, 3) - 1)) LIKE 'MF_AR_HDR' THEN
                dbms_scheduler.create_job(job_name => 'MFAR_ACC_ERROR_REPRO_'
                                                      || p_file_name
                                                      || '_'
                                                      || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                      'BEGIN 
           WSC_AHCS_MFAR_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_jti_mfar_reprocess('
                                                                                                                                       ||
                                                                                                                                       lv_batch_id
                                                                                                                                       ||
                                                                                                                                       ');
         END;', enabled => true, auto_drop => true,
                                         comments => 'MFAR_ACC_ERROR_REPRO ');
            ELSE
                dbms_scheduler.create_job(job_name => 'MFAR_ACC_ERROR_REPRO_'
                                                      || p_file_name
                                                      || '_'
                                                      || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                      'BEGIN 
           WSC_AHCS_MFAR_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                       ||
                                                                                                                                       lv_batch_id
                                                                                                                                       ||
                                                                                                                                       ');
         END;', enabled => true, auto_drop => true,
                                         comments => 'MFAR_ACC_ERROR_REPRO ');
            END IF;

        ELSIF upper(lv_src_application) LIKE '%LEASES%' THEN
            dbms_scheduler.create_job(job_name => 'LEASES_ACC_ERROR_REPRO_'
                                                  || replace(replace(p_file_name, ' ', ''), '-', '_')
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_LHIN_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'LEASES_ACC_ERROR_REPRO ');
        ELSIF upper(lv_src_application) LIKE '%CLOUDPAY%' THEN
            dbms_scheduler.create_job(job_name => 'CLOUDPAY_ACC_ERROR_REPRO_'
                                                  || replace(replace(p_file_name, ' ', ''), '-', '_')
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           wsc_ahcs_cp_validation_transformation_pkg.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'CLOUDPAY_ACC_ERROR_REPRO ');
        ELSIF upper(lv_src_application) LIKE 'PS%FA' THEN
            dbms_scheduler.create_job(job_name => 'PSFA_ACC_ERROR_REPRO_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           wsc_ahcs_PSFA_validation_transformation_pkg.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'PSFA_ACC_ERROR_REPRO ');
        ELSIF upper(lv_src_application) LIKE 'TW' THEN
            dbms_scheduler.create_job(job_name => 'TW_ACC_ERROR_REPRO_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_TW_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'TW_ACC_ERROR_REPRO ');
        ELSIF upper(lv_src_application) LIKE 'MF INV' THEN
            logging_insert('ANIXTER INV', lv_batch_id, 5000, 'accounting repro start header table update', NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_mfinv_txn_header_t h
            USING (
                      SELECT DISTINCT
                          header_id,
                          batch_id,
                          accounting_status
                      FROM
                          wsc_ahcs_int_status_t
                      WHERE
                          accounting_status IN ( 'CRE_ACC_ERROR', 'IMP_ACC_ERROR' )
                          AND batch_id = lv_batch_id
                  )
            s ON ( s.accounting_status IN ( 'CRE_ACC_ERROR', 'IMP_ACC_ERROR' )
                   AND h.header_id = s.header_id
                   AND h.batch_id = s.batch_id
                   AND s.batch_id = lv_batch_id )
            WHEN MATCHED THEN UPDATE
            SET transaction_number = ( substr(transaction_number, 0, decode(instr(transaction_number, '_'), 0, length(transaction_number),
            instr(transaction_number, '_') - 1)) );

            logging_insert('ANIXTER INV', lv_batch_id, 5001, 'accounting repro start LINE table update', NULL,
                          sysdate);
            MERGE INTO wsc_ahcs_mfinv_txn_line_t l
            USING wsc_ahcs_int_status_t s ON ( s.accounting_status IN ( 'CRE_ACC_ERROR', 'IMP_ACC_ERROR' )
                                               AND l.header_id = s.header_id
                                               AND l.line_id = s.line_id
                                               AND l.batch_id = s.batch_id
                                               AND l.batch_id = lv_batch_id )
            WHEN MATCHED THEN UPDATE
            SET transaction_number = ( substr(transaction_number, 0, decode(instr(transaction_number, '_'), 0, length(transaction_number),
            instr(transaction_number, '_') - 1)) ),
                attribute5 = NULL;

            logging_insert('ANIXTER INV', lv_batch_id, 5002, 'accounting repro start STATUS table update', NULL,
                          sysdate);
            UPDATE wsc_ahcs_int_status_t
            SET
                accounting_status = NULL,
                status = 'TRANSFORM_FAILED',
                attribute2 = 'TRANSFORM_FAILED',
                attribute3 = substr(attribute3, 0, decode(instr(attribute3, '_'), 0, length(attribute3), instr(attribute3, '_') - 1)),
                group_id = NULL,
				attribute6=-1 --- added for copy line procedure on 2/20/23
            WHERE
                    batch_id = lv_batch_id
                AND accounting_status IN ( 'CRE_ACC_ERROR', 'IMP_ACC_ERROR' );

            COMMIT;
            logging_insert('ANIXTER INV', lv_batch_id, 5003, 'accounting repro start repro job', NULL,
                          sysdate);
						  
						-----------for copy line user story--------
				/*Delete from wsc_ahcs_mfinv_txn_line_t where batch_id=lv_batch_id and line_seq_number='-99999' and  ;
				commit;
				Delete from wsc_ahcs_int_status_t where batch_id=lv_batch_id and legacy_line_number='-99999' ;
				commit; */

            IF upper(substr(p_file_name, 0, instr(p_file_name, '_', 1, 3) - 1)) LIKE 'MF_IV_HDR' THEN
                dbms_scheduler.create_job(job_name => 'MFINV_ACC_ERROR_REPRO_'
                                                      || p_file_name
                                                      || '_'
                                                      || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                      'BEGIN 
           WSC_AHCS_MFINV_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_jti_mfinv_reprocess('
                                                                                                                                       ||
                                                                                                                                       lv_batch_id
                                                                                                                                       ||
                                                                                                                                       ');
         END;', enabled => true, auto_drop => true,
                                         comments => 'MFINV_ACC_ERROR_REPRO ');
            ELSE
                dbms_scheduler.create_job(job_name => 'MFINV_ACC_ERROR_REPRO_'
                                                      || p_file_name
                                                      || '_'
                                                      || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                      'BEGIN 
           WSC_AHCS_MFINV_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                       ||
                                                                                                                                       lv_batch_id
                                                                                                                                       ||
                                                                                                                                       ');
         END;', enabled => true, auto_drop => true,
                                         comments => 'MFINV_ACC_ERROR_REPRO ');
            END IF;

        ELSIF upper(lv_src_application) LIKE 'ECLIPSE' THEN
            dbms_scheduler.create_job(job_name => 'ECLIPSE_ACC_ERROR_REPRO_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_ECLIPSE_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'ECLIPSE_ACC_ERROR_REPRO ');
        ELSIF upper(lv_src_application) LIKE 'CONCUR' THEN
            dbms_scheduler.create_job(job_name => 'CONCUR_ACC_ERROR_REPRO_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_CNCR_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing_p('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'CONCUR_ACC_ERROR_REPRO ');
        ELSIF upper(lv_src_application) LIKE 'SXE' THEN
            dbms_scheduler.create_job(job_name => 'SXE_ACC_ERROR_REPRO_'
                                                  || p_file_name
                                                  || '_'
                                                  || to_char(sysdate, 'DD_MON_YYYY_HH24SS'), job_type => 'PLSQL_BLOCK', job_action =>
                                                  'BEGIN 
           WSC_AHCS_SXE_VALIDATION_TRANSFORMATION_PKG.leg_coa_transformation_reprocessing('
                                                                                                                                   ||
                                                                                                                                   lv_batch_id
                                                                                                                                   ||
                                                                                                                                   ');
         END;', enabled => true, auto_drop => true,
                                     comments => 'SXE_ACC_ERROR_REPRO ');
        END IF;

    END account_reprocessing_async;

END wsc_ahcs_reprocessing_pkg;
/