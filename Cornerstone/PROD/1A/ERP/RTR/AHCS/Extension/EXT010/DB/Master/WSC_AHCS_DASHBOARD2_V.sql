
  CREATE OR REPLACE FORCE EDITIONABLE VIEW "FININT"."WSC_AHCS_DASHBOARD2_V" ("APPLICATION", "ACCOUNTING_PERIOD", "INTERFACE_PROC_STATUS", "CREATE_ACC_STATUS", "TOTAL_CR", "TOTAL_DR", "NUM_ROWS", "DUMMY", "DUMMY4") AS 
  WITH main_data AS (
        SELECT
            rw,
            application,
            legacy_header_id,
            legacy_line_number
        FROM
            (
                SELECT  /*+  INDEX_JOIN(WSC_AHCS_INT_STATUS_HEADER_ID_I,WSC_AHCS_INT_STATUS_LINE_ID_I)*/
                    ROWID rw,
                    application,
                    legacy_header_id,
                    legacy_line_number,
                    RANK()
                    OVER( PARTITION BY application,decode(application,'CENTRAL',header_id,legacy_header_id),decode(application,'CENTRAL',line_id,legacy_line_number)
                        ORDER BY
                            last_updated_date DESC
                    )     rnk
                FROM
                    wsc_ahcs_int_status_t 
            )
        WHERE
            rnk = 1
    )
    SELECT  /*+  INDEX_JOIN(WSC_AHCS_INT_STATUS_HEADER_ID_I,WSC_AHCS_INT_STATUS_LINE_ID_I)*/ 
        decode(wais.application,'ERP_POC','ERP POC','CENTRAL','Central',wais.application),
        to_char(wais.attribute11, 'MON-YY') accounting_period,
        CASE
            WHEN ( wais.attribute2 IN ( 'TRANSFORM_FAILED', 'VALIDATION_SUCCESS' )
                   OR wais.attribute2 IS NULL ) THEN
                'Reprocessing Error'
            WHEN wais.attribute2 = 'VALIDATION_FAILED' THEN
                'Re-extract Error'
            WHEN wais.attribute2 = 'TRANSFORM_SUCCESS' THEN
                'Success'
            ELSE
                initcap(wais.attribute2)
        END                                 interface_proc_status,
        CASE
            WHEN wais.attribute2 = 'TRANSFORM_SUCCESS'
                 AND wais.accounting_status = 'CRE_ACC_SUCCESS' THEN
                'Final Accounted'
            WHEN wais.attribute2 = 'TRANSFORM_SUCCESS'
                 AND wais.accounting_status = 'Draft' THEN
                'Draft Accounted'    
            WHEN wais.attribute2 = 'TRANSFORM_SUCCESS'
                 AND ( wais.accounting_status IN ( 'CRE_ACC_ERROR' ) ) THEN
                'Error'
            WHEN wais.attribute2 = 'TRANSFORM_SUCCESS'
                 AND ( wais.accounting_status IN (  'IMP_ACC_ERROR' ) ) THEN
                'Import Error'    
            WHEN wais.attribute2 = 'TRANSFORM_SUCCESS'
                 AND ( wais.accounting_status = 'IMP_ACC_SUCCESS'
                       OR wais.accounting_status IS NULL ) THEN
                'Pending'
            WHEN ( wais.attribute2 IN ( 'TRANSFORM_FAILED', 'VALIDATION_SUCCESS' )
                   OR wais.attribute2 IS NULL ) THEN
                'NA'
            WHEN wais.attribute2 = 'VALIDATION_FAILED' THEN
                'NA'
            ELSE
                NULL
        END                                 create_acc_status,
         (SELECT /*+  INDEX(WSC_AHCS_INT_STATUS_ATT2_STTS_I)*/ SUM(nvl(abs(dr_cr.value), 0)) FROM wsc_ahcs_int_status_t dr_cr,main_data
          WHERE DR_CR.application=wais.application
        AND DR_CR.attribute2=wais.attribute2
        AND NVL(DR_CR.accounting_status,'X')=NVL(wais.accounting_status,'X')
        AND to_char(dr_cr.attribute11, 'MON-YY')=to_char(wais.attribute11, 'MON-YY')
        and dr_cr.CR_DR_INDICATOR='CR' and main_data.rw=dr_cr.rowid) total_cr,
         (SELECT /*+  INDEX(WSC_AHCS_INT_STATUS_ATT2_STTS_I)*/ SUM(nvl(abs(dr_cr.value), 0)) FROM wsc_ahcs_int_status_t dr_cr,main_data
          WHERE DR_CR.application=wais.application
        AND DR_CR.attribute2=wais.attribute2
        AND NVL(DR_CR.accounting_status,'X')=NVL(wais.accounting_status,'X')
        AND to_char(dr_cr.attribute11, 'MON-YY')=to_char(wais.attribute11, 'MON-YY')
        and dr_cr.CR_DR_INDICATOR='DR' and main_data.rw=dr_cr.rowid) total_dr,
        COUNT(1)                            num_rows,
         decode(wais.accounting_status, 'CRE_ACC_SUCCESS', 'none', 'IMP_ACC_SUCCESS', 'none','Draft','none','CRE_ACC_ERROR', 'none','IMP_ACC_ERROR',  'none',decode(wais.attribute2,'TRANSFORM_SUCCESS',null,'OTH'),'none',
               '0')                           dummy,
        decode(wais.accounting_status,'CRE_ACC_ERROR','apg','IMP_ACC_ERROR','none','none') DUMMY4
    FROM
        wsc_ahcs_int_status_t wais,
        main_data             b 
    WHERE 
            wais.legacy_header_id = b.legacy_header_id(+)
        AND wais.legacy_line_number = b.legacy_line_number(+)
        AND wais.application = NVL(b.application,wais.application)
        AND wais.rowid = NVL(b.rw,wais.rowid)
    GROUP BY
        wais.application,
        wais.attribute2,
        wais.accounting_status,
        to_char(wais.attribute11, 'MON-YY');
/

