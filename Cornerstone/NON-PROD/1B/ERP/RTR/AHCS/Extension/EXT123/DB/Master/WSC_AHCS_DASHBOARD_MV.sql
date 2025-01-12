
	
  CREATE MATERIALIZED VIEW "FININT"."WSC_AHCS_DSHB2_UNI_REC_V" ("RW", "APPLICATION", "LEGACY_HEADER_ID", "LEGACY_LINE_NUMBER", "INTERFACE_ID")
  ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" 
  BUILD IMMEDIATE
  USING INDEX 
  REFRESH FORCE ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  USING ENFORCED CONSTRAINTS DISABLE ON QUERY COMPUTATION DISABLE QUERY REWRITE
  AS SELECT
            rw,
            application,
			legacy_header_id,
            legacy_line_number,
            interface_id
        FROM
            (
                SELECT  
                    ROWID rw,
                    application,
                    legacy_header_id,
                    legacy_line_number,
                    interface_id,
                    RANK()
                    OVER( PARTITION BY application,decode(application,'CENTRAL',header_id,nvl(legacy_header_id,header_id)),decode(application,'CENTRAL',line_id,nvl(legacy_line_number,line_id))
                        ORDER BY
                            last_updated_date DESC
                    )     rnk
                FROM
                    wsc_ahcs_int_status_t
            )
        WHERE
            rnk = 1;

   COMMENT ON MATERIALIZED VIEW "FININT"."WSC_AHCS_DSHB2_UNI_REC_V"  IS 'snapshot table for snapshot FININT.WSC_AHCS_DSHB2_UNI_REC_V';




  
  CREATE MATERIALIZED VIEW "FININT"."WSC_AHCS_DSHB2_DR_CR_V" ("APPLICATION", "SOURCE_SYSTEM", "INTERFACE_PROC_STATUS", "CREATE_ACC_STATUS", "ACCOUNTING_PERIOD", "CR", "DR")
  SEGMENT CREATION IMMEDIATE
  ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" 
  BUILD IMMEDIATE
  USING INDEX 
  REFRESH FORCE ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  USING ENFORCED CONSTRAINTS DISABLE ON QUERY COMPUTATION DISABLE QUERY REWRITE
  AS SELECT
    *
    FROM
    (
        SELECT
            *
        FROM
            (
                SELECT
                decode(status.application,'ERP_POC','ERP POC','CENTRAL','Central','ECLIPSE','ECLPS',
                'SXE','SXEUS','TW','APS Treasury','MF INV','MF INVENTORY',status.application) application,
--		           decode(status.interface_id,'SALE','SII','CASH','CRI','LSIR','LSI','SPER','SPR','ARIN','ARI',substr(status.interface_id,1,3)) SOURCE_SYSTEM,
--                   decode(decode(status.interface_id,'SALE','SII','CASH','CRI','LSIR','LSI','SPER','SPR','ARIN','ARI',substr(status.interface_id,1,3)),'IFR','FII','COQ','CQI','OFR','FTI','INT','ICI','INV','ISI','SPE','SPC','IBI','IBI','IRI','IRI','DAI','DAI','AII','AII',substr(status.interface_id,1,3)) SOURCE_SYSTEM,

		           decode(status.interface_id,'SALE','SII','CASH','CRI','LSIR','LSI','SPER','SPR','ARIN','ARI','IFRT','FII','COQI','CQI','OFRT','FTI','INTR','ICI','INVT','ISI','SPEC','SPC',substr(status.interface_id,1,3)) 
                   SOURCE_SYSTEM,

--                    status.interface_id                          source_system,
                    abs(SUM(nvl(status.value, 0)))             status_sum,
        CASE
            WHEN ( status.attribute2 IN ( 'TRANSFORM_FAILED', 'VALIDATION_SUCCESS' )
                   OR status.attribute2 IS NULL ) THEN
                'Reprocessing Error'
            WHEN status.attribute2 = 'VALIDATION_FAILED' THEN
                'Re-extract Error'
            WHEN status.attribute2 = 'TRANSFORM_SUCCESS' THEN
                'Success'
            ELSE
                initcap(status.attribute2)
        END                                 interface_proc_status,

CASE
            WHEN status.attribute2 = 'TRANSFORM_SUCCESS'
                 AND status.accounting_status = 'CRE_ACC_SUCCESS' THEN
                'Final Accounted'
            WHEN status.attribute2 = 'TRANSFORM_SUCCESS'
                 AND status.accounting_status = 'Draft' THEN
                'Draft Accounted'    
            WHEN status.attribute2 = 'TRANSFORM_SUCCESS'
                 AND ( status.accounting_status IN ( 'CRE_ACC_ERROR' ) ) THEN
                'Error'
            WHEN status.attribute2 = 'TRANSFORM_SUCCESS'
                 AND ( status.accounting_status IN (  'IMP_ACC_ERROR' ) ) THEN
                'Import Error'    
            WHEN status.attribute2 = 'TRANSFORM_SUCCESS'
                 AND status.accounting_status = 'IMP_ACC_SUCCESS' THEN
                'Accounting Pending'
			WHEN status.attribute2 = 'TRANSFORM_SUCCESS'
                 AND status.accounting_status IS NULL THEN
                'Import Pending'
			WHEN ( status.attribute2 IN ( 'TRANSFORM_FAILED', 'VALIDATION_SUCCESS' )
                   OR status.attribute2 IS NULL ) THEN
                'NA'
            WHEN status.attribute2 = 'VALIDATION_FAILED' THEN
                'NA'
            ELSE
                NULL
        END                                 create_acc_status,

--                    status.attribute2,
--                    status.accounting_status                     accounting_status,
                    to_char(status.attribute11, 'MON-YY')        accounting_period,
                    status.cr_dr_indicator                       cd_indicator
                FROM
                    wsc_ahcs_int_status_t     status,
                    wsc_ahcs_dshb2_uni_rec_v  uni_rec_v
                WHERE
                    uni_rec_v.rw = status.rowid 
                GROUP BY
--                    status.attribute2,
--                    status.accounting_status,
CASE
            WHEN ( status.attribute2 IN ( 'TRANSFORM_FAILED', 'VALIDATION_SUCCESS' )
                   OR status.attribute2 IS NULL ) THEN
                'Reprocessing Error'
            WHEN status.attribute2 = 'VALIDATION_FAILED' THEN
                'Re-extract Error'
            WHEN status.attribute2 = 'TRANSFORM_SUCCESS' THEN
                'Success'
            ELSE
                initcap(status.attribute2)
        END                                 ,

CASE
            WHEN status.attribute2 = 'TRANSFORM_SUCCESS'
                 AND status.accounting_status = 'CRE_ACC_SUCCESS' THEN
                'Final Accounted'
            WHEN status.attribute2 = 'TRANSFORM_SUCCESS'
                 AND status.accounting_status = 'Draft' THEN
                'Draft Accounted'    
            WHEN status.attribute2 = 'TRANSFORM_SUCCESS'
                 AND ( status.accounting_status IN ( 'CRE_ACC_ERROR' ) ) THEN
                'Error'
            WHEN status.attribute2 = 'TRANSFORM_SUCCESS'
                 AND ( status.accounting_status IN (  'IMP_ACC_ERROR' ) ) THEN
                'Import Error'    
            WHEN status.attribute2 = 'TRANSFORM_SUCCESS'
                 AND status.accounting_status = 'IMP_ACC_SUCCESS' THEN
                'Accounting Pending'
			WHEN status.attribute2 = 'TRANSFORM_SUCCESS'
                 AND status.accounting_status IS NULL THEN
                'Import Pending'
			WHEN ( status.attribute2 IN ( 'TRANSFORM_FAILED', 'VALIDATION_SUCCESS' )
                   OR status.attribute2 IS NULL ) THEN
                'NA'
            WHEN status.attribute2 = 'VALIDATION_FAILED' THEN
                'NA'
            ELSE
                NULL
        END                                 ,
                    to_char(status.attribute11, 'MON-YY'),
                    status.cr_dr_indicator,
                    
                decode(status.application,'ERP_POC','ERP POC','CENTRAL','Central','ECLIPSE','ECLPS',
                'SXE','SXEUS','TW','APS Treasury','MF INV','MF INVENTORY',status.application) ,
                    status.interface_id
            )
    ) PIVOT (
        SUM ( status_sum )
        FOR cd_indicator
        IN ( 'CR',
        'DR' )
    );

   COMMENT ON MATERIALIZED VIEW "FININT"."WSC_AHCS_DSHB2_DR_CR_V"  IS 'snapshot table for snapshot FININT.WSC_AHCS_DSHB2_DR_CR_V';





  
  CREATE MATERIALIZED VIEW "FININT"."WSC_AHCS_DSHB2_MAIN_V" ("APPLICATION", "SOURCE_SYSTEM", "INTERFACE_PROC_STATUS", "CREATE_ACC_STATUS", "ACCOUNTING_PERIOD", "NUM_ROW")
  SEGMENT CREATION IMMEDIATE
  ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" 
  BUILD IMMEDIATE
  USING INDEX 
  REFRESH FORCE ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  USING ENFORCED CONSTRAINTS DISABLE ON QUERY COMPUTATION DISABLE QUERY REWRITE
  AS SELECT  
        decode(wais.application,'ERP_POC','ERP POC','CENTRAL','Central','ECLIPSE','ECLPS','SXE','SXEUS','TW','APS Treasury','MF INV','MF INVENTORY',wais.application),
--		wais.interface_id SOURCE_SYSTEM,
--        decode(decode(wais.interface_id,'SALE','SII','CASH','CRI','LSIR','LSI','SPER','SPR','ARIN','ARI',substr(wais.interface_id,1,3)),'IFR','FII','COQ','CQI','OFR','FTI','INT','ICI','INV','ISI','SPE','SPC','IBI','IBI','IRI','IRI','DAI','DAI','AII','AII',substr(wais.interface_id,1,3)) SOURCE_SYSTEM,

       decode(wais.interface_id,'SALE','SII','CASH','CRI','LSIR','LSI','SPER','SPR','ARIN','ARI','IFRT','FII','COQI','CQI','OFRT','FTI','INTR','ICI','INVT','ISI','SPEC','SPC',substr(wais.interface_id,1,3)) 
       SOURCE_SYSTEM,

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
                 AND wais.accounting_status = 'IMP_ACC_SUCCESS' THEN
                'Accounting Pending'
			WHEN wais.attribute2 = 'TRANSFORM_SUCCESS'
                 AND wais.accounting_status IS NULL THEN
                'Import Pending'
			WHEN ( wais.attribute2 IN ( 'TRANSFORM_FAILED', 'VALIDATION_SUCCESS' )
                   OR wais.attribute2 IS NULL ) THEN
                'NA'
            WHEN wais.attribute2 = 'VALIDATION_FAILED' THEN
                'NA'
            ELSE
                NULL
        END                                 create_acc_status,

--        wais.attribute2 ATTRIBUTE2,
--        wais.accounting_status ACCOUNTING_STATUS,
        to_char(wais.attribute11, 'MON-YY') accounting_period,
        
        COUNT(1)                            num_rows
--        ,
--         decode(wais.accounting_status, 'CRE_ACC_SUCCESS', 'none', 'IMP_ACC_SUCCESS', 'none','Draft','none','CRE_ACC_ERROR', 'none','IMP_ACC_ERROR',  'none',decode(wais.attribute2,'TRANSFORM_SUCCESS',null,'OTH'),'none',
--               '0')                           dummy,
--        decode(wais.accounting_status,'CRE_ACC_ERROR','apg','IMP_ACC_ERROR','none','none') DUMMY4
    FROM
        wsc_ahcs_int_status_t wais,
        WSC_AHCS_DSHB2_UNI_REC_V b 
    WHERE 
            wais.legacy_header_id = b.legacy_header_id(+)
        AND wais.legacy_line_number = b.legacy_line_number(+)
        AND wais.application = NVL(b.application,wais.application)
        AND wais.rowid = NVL(b.rw,wais.rowid)
        and nvl(b.interface_id,'X') = nvl(wais.interface_id,'X')
    GROUP BY
        wais.application,
		wais.interface_id,
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
        END                                 ,

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
                 AND wais.accounting_status = 'IMP_ACC_SUCCESS' THEN
                'Accounting Pending'
			WHEN wais.attribute2 = 'TRANSFORM_SUCCESS'
                 AND wais.accounting_status IS NULL THEN
                'Import Pending'
			WHEN ( wais.attribute2 IN ( 'TRANSFORM_FAILED', 'VALIDATION_SUCCESS' )
                   OR wais.attribute2 IS NULL ) THEN
                'NA'
            WHEN wais.attribute2 = 'VALIDATION_FAILED' THEN
                'NA'
            ELSE
                NULL
        END                                 ,

--        wais.attribute2,
--        wais.accounting_status,
        to_char(wais.attribute11, 'MON-YY');

   COMMENT ON MATERIALIZED VIEW "FININT"."WSC_AHCS_DSHB2_MAIN_V"  IS 'snapshot table for snapshot FININT.WSC_AHCS_DSHB2_MAIN_V';

