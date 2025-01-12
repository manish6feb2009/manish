--------------------------------------------------------
--  File created - Friday-March-17-2023   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package WSC_AHCS_MFAP_VALIDATION_TRANSFORMATION_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "FININT"."WSC_AHCS_MFAP_VALIDATION_TRANSFORMATION_PKG" AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */
  ------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PACKAGE             wsc_ahcs_mfap_validation_transformation_pkg AS
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
-- $Header: wsc_ahcs_mfap_validation_transformation_pkg.pkg
--
-- PRE-REQUISITES
-- The package makes an implicit call to an external packaged function, wsc_gl_coa_mapping_pkg.coa_mapping for 
-- deriving the COA segment values in the future state COA structure on the basis of legacy COA structure.
-- This package wsc_gl_coa_mapping_pkg must be compiled before installing this package.
--
-- The following staging tables must be created before 
-- 1. wsc_ahcs_mfap_txn_line_t
-- 2. WSC_AHCS_INT_STATUS_T 
-- 3. WSC_AHCS_INT_CONTROL_T
-- 4. wsc_gl_legal_entities_t
-- 5. wsc_gl_ccid_mapping_t
-- 6. wsc_ahcs_mfap_txn_header_t

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
-- Deloitte Consulting            FEB 2022      1.0   Created
-- Build defect CTPFS-28030       MAR 2023            Updated
----------------------------------------------------------------------------------------


    PROCEDURE data_validation (
        p_batch_id IN NUMBER
    );

    PROCEDURE wsc_ledger_name_derivation (
        p_batch_id IN NUMBER
    );


    PROCEDURE leg_coa_transformation (
        p_batch_id IN NUMBER
    );

    PROCEDURE leg_coa_transformation_reprocessing (
        p_batch_id IN NUMBER
    );

    FUNCTION is_date_null (
        p_string IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION is_long_null (
        p_string IN LONG
    ) RETURN NUMBER;

    FUNCTION is_number_null (
        p_string IN NUMBER
    ) RETURN NUMBER;

    FUNCTION is_varchar2_null (
        p_string IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE cresus_data_validation (
        p_batch_id IN NUMBER
    );

    PROCEDURE wsc_ahcs_mfap_grp_id_upd_p (
        in_grp_id IN NUMBER
    );

    PROCEDURE wsc_ahcs_mfap_ctrl_line_tbl_ucm_update (
        p_ucmdoc_id       IN  VARCHAR2,
        p_group_id        IN  VARCHAR2,
        p_ledger_grp_num  IN  VARCHAR2
    );

     PROCEDURE wsc_ahcs_mfap_ctrl_line_tbl_ledger_grp_num_update (      
        p_group_id        IN  VARCHAR2,
        p_ledger_grp_num  IN  VARCHAR2
    );

 PROCEDURE leg_coa_transformation_JTI_MFAP (
        p_batch_id IN NUMBER
    );

      PROCEDURE leg_coa_transformation_jti_mfap_reprocessing (
        p_batch_id IN NUMBER
    );
END wsc_ahcs_mfap_validation_transformation_pkg;

/
