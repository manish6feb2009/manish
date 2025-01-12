create or replace PACKAGE BODY WSC_AHCS_MFSTATUS_TBL_UPDATE AS

  PROCEDURE wsc_ahcs_mfstatus_tbl_impacc_update (
        p_import_acc_id          IN  VARCHAR2,
        p_group_id               IN  VARCHAR2,
        p_ledger_grp_num         IN  VARCHAR2,
        p_source_system          IN  VARCHAR2,
        p_imp_accounting_status  IN  VARCHAR2
    ) AS
  BEGIN
    IF (p_imp_accounting_status ='SUCCEEDED') AND ( p_ledger_grp_num = 999 ) THEN
        dbms_output.put_line(p_ledger_grp_num || 'inside IF SUCCEEDED & 999');
        UPDATE wsc_ahcs_int_control_line_t status
        SET
            status.import_acc_id = p_import_acc_id,
            status.status = 'IMP_ACC_SUCCESS',            
                last_update_date = sysdate
        WHERE
                group_id = p_group_id
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_mf_ledger_t ml
                WHERE
                        999 = p_ledger_grp_num
                    AND ml.sub_ledger = p_source_system
                    AND ml.ledger_name = status.ledger_name
            );

        COMMIT;
    ELSIF  (p_imp_accounting_status ='SUCCEEDED')  AND ( p_ledger_grp_num <> 999 ) THEN
        dbms_output.put_line(p_ledger_grp_num || ' inside else IF SUCCEEDED & NOT 999 ');
        UPDATE wsc_ahcs_int_control_line_t status
        SET
            status.import_acc_id = p_import_acc_id,
            status.status = 'IMP_ACC_SUCCESS',
                last_update_date = sysdate
        WHERE
                group_id = p_group_id
            AND ledger_name IN (
                SELECT
                    ledger_name
                FROM
                    wsc_ahcs_int_mf_ledger_t ml
                WHERE
                        ml.ledger_grp_num = p_ledger_grp_num
                    AND ml.sub_ledger = p_source_system
                    AND ml.ledger_name = status.ledger_name
            );
            
        COMMIT;  
        
  ELSIF (p_imp_accounting_status <> 'SUCCEEDED') AND ( p_ledger_grp_num = 999 ) THEN
    dbms_output.put_line(p_ledger_grp_num || 'inside IF ERROR & 999');
        UPDATE wsc_ahcs_int_control_line_t status
        SET
            status.import_acc_id = p_import_acc_id,
            status.status = 'IMP_ACC_ERROR',
                last_update_date = sysdate
        WHERE
                group_id = p_group_id
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_mf_ledger_t ml
                WHERE
                        999 = p_ledger_grp_num
                    AND ml.sub_ledger = p_source_system
                    AND ml.ledger_name = status.ledger_name
            );
 
        COMMIT;
       
       ELSE
       dbms_output.put_line(p_ledger_grp_num || 'inside IF ERROR & NOT 999');
       UPDATE wsc_ahcs_int_control_line_t status
        SET
            status.import_acc_id = p_import_acc_id,
            status.status = 'IMP_ACC_ERROR',
                last_update_date = sysdate
        WHERE
                group_id = p_group_id
            AND ledger_name IN (
                SELECT
                    ledger_name
                FROM
                    wsc_ahcs_int_mf_ledger_t ml
                WHERE
                        ml.ledger_grp_num = p_ledger_grp_num
                    AND ml.sub_ledger = p_source_system
                    AND ml.ledger_name = status.ledger_name
            );
            
        COMMIT;  
        
        
    END IF;
  END wsc_ahcs_mfstatus_tbl_impacc_update;

  PROCEDURE wsc_ahcs_mfstatus_tbl_creacc_update (
        p_create_acc_id   IN  VARCHAR2,
        p_group_id        IN  VARCHAR2,
        p_ledger_grp_num  IN  VARCHAR2,
        p_source_system   IN  VARCHAR2
    ) AS
  BEGIN
    IF ( p_ledger_grp_num = 999 ) THEN
        dbms_output.put_line(p_ledger_grp_num || 'inside IF');
        UPDATE wsc_ahcs_int_control_line_t status
        SET
            status.create_acc_id = p_create_acc_id,
                last_update_date = sysdate
        WHERE
                status.group_id = p_group_id
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_mf_ledger_t ml
                WHERE
                        999 = p_ledger_grp_num
                    AND ml.sub_ledger = p_source_system
                    AND ml.ledger_name = status.ledger_name
            );

        COMMIT;
    ELSE
        dbms_output.put_line(p_ledger_grp_num || ' inside  else ');
        UPDATE wsc_ahcs_int_control_line_t status
        SET
            status.create_acc_id = p_create_acc_id,
                last_update_date = sysdate
        WHERE
                status.group_id = p_group_id
            AND ( ledger_name IN (
                SELECT
                    ledger_name
                FROM
                    wsc_ahcs_int_mf_ledger_t ml
                WHERE
                        ml.ledger_grp_num = p_ledger_grp_num
                    AND ml.sub_ledger = p_source_system
                    AND ml.ledger_name = status.ledger_name
            ) );

        COMMIT;
    END IF;
  END wsc_ahcs_mfstatus_tbl_creacc_update;

  PROCEDURE wsc_ahcs_status_tbl_update (
        p_ledger_grp_num         IN  VARCHAR2,
        p_source_system          IN  VARCHAR2,
        p_imp_accounting_status  IN  VARCHAR2,
        p_group_id               IN VARCHAR2
    ) AS
  BEGIN
   IF (p_imp_accounting_status ='SUCCEEDED') AND ( p_ledger_grp_num = 999 ) THEN
        dbms_output.put_line(p_ledger_grp_num || 'inside IF SUCCEEDED & 999');
        UPDATE wsc_ahcs_int_status_t status
        SET
            accounting_status = 'IMP_ACC_SUCCESS'
        WHERE
                status = 'TRANSFORM_SUCCESS'
            AND group_id = p_group_id
            AND attribute2 = 'TRANSFORM_SUCCESS'
            AND ( accounting_status IS NULL
                  OR accounting_status = 'IMP_ACC_ERROR' )
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_mf_ledger_t ml
                WHERE
                        999 = p_ledger_grp_num
                    AND ml.sub_ledger = p_source_system
                    AND ml.ledger_name = status.ledger_name
            );

        COMMIT;
     ELSIF  (p_imp_accounting_status ='SUCCEEDED')  AND ( p_ledger_grp_num <> 999 ) THEN
        dbms_output.put_line(p_ledger_grp_num || ' inside else IF SUCCEEDED & NOT 999 ');
        UPDATE wsc_ahcs_int_status_t status
        SET
            accounting_status = 'IMP_ACC_SUCCESS'
        WHERE
                status = 'TRANSFORM_SUCCESS'
            AND group_id = p_group_id
            AND attribute2 = 'TRANSFORM_SUCCESS'
            AND ( accounting_status IS NULL
                  OR accounting_status = 'IMP_ACC_ERROR' )
            AND ledger_name IN (
                SELECT DISTINCT
                    ml.ledger_name
                FROM
                    wsc_ahcs_int_mf_ledger_t ml
                WHERE
                        ml.ledger_grp_num = p_ledger_grp_num
                    AND ml.sub_ledger = p_source_system
                    AND ml.ledger_name = status.ledger_name
            );

        COMMIT;
        
        ELSIF (p_imp_accounting_status <> 'SUCCEEDED') AND ( p_ledger_grp_num = 999 ) THEN
    dbms_output.put_line(p_ledger_grp_num || 'inside IF ERROR & 999');
     UPDATE wsc_ahcs_int_status_t status
        SET
            accounting_status = 'IMP_ACC_ERROR'
        WHERE
                status = 'TRANSFORM_SUCCESS'
            AND group_id = p_group_id    
            AND attribute2 = 'TRANSFORM_SUCCESS'
            AND ( accounting_status IS NULL
                  OR accounting_status = 'IMP_ACC_ERROR' )
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    wsc_ahcs_int_mf_ledger_t ml
                WHERE
                        999 = p_ledger_grp_num
                    AND ml.sub_ledger = p_source_system
                    AND ml.ledger_name = status.ledger_name
            );

        COMMIT;
    
     ELSE
       dbms_output.put_line(p_ledger_grp_num || 'inside IF ERROR & NOT 999');
    
     UPDATE wsc_ahcs_int_status_t status
        SET
            accounting_status = 'IMP_ACC_ERROR'
        WHERE
                status = 'TRANSFORM_SUCCESS'
            AND group_id = p_group_id     
            AND attribute2 = 'TRANSFORM_SUCCESS'
            AND ( accounting_status IS NULL
                  OR accounting_status = 'IMP_ACC_ERROR' )
            AND ledger_name IN (
                SELECT DISTINCT
                    ml.ledger_name
                FROM
                    wsc_ahcs_int_mf_ledger_t ml
                WHERE
                        ml.ledger_grp_num = p_ledger_grp_num
                    AND ml.sub_ledger = p_source_system
                    AND ml.ledger_name = status.ledger_name
            );

        COMMIT;
    END IF;
  END wsc_ahcs_status_tbl_update;

END WSC_AHCS_MFSTATUS_TBL_UPDATE;
/