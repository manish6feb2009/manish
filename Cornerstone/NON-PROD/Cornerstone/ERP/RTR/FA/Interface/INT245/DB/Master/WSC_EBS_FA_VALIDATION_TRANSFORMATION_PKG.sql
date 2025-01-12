create or replace PACKAGE          "WSC_EBS_FA_VALIDATION_TRANSFORMATION_PKG" AS 
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PACKAGE             WSC_EBS_FA_VALIDATION_TRANSFORMATION_PKG AS
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
-- staged into the staging tables that hosts data provided from the EBS Asset Invoices and
-- destined for Cloud FA
-- 
--
-- FILE LOCATION AND VERSION
-- $Header: WSC_EBS_FA_VALIDATION_TRANSFORMATION_PKG.pkg
--
-- PRE-REQUISITES
-- The package makes an implicit call to an external packaged function, wsc_gl_coa_mapping_pkg.coa_mapping for 
-- deriving the COA segment values in the future state COA structure on the basis of legacy COA structure.
-- This package wsc_gl_coa_mapping_pkg must be compiled before installing this package.
--
-- The following staging tables must be created before 
-- 1. WSC_EBS_FA_TXN_T
-- 2. WSC_GEN_INT_CONTROL_T
-- 3. wsc_gl_legal_entities_t
-- 4. wsc_gl_ccid_mapping_t
-- 5. WSC_GEN_INT_status_T

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
-- Deloitte Consulting            15-JAN-2024  1.0   Created
--
----------------------------------------------------------------------------------------


   PROCEDURE data_validation(p_batch_id IN number);
   PROCEDURE leg_data_transformation(p_batch_id IN number);
   FUNCTION  IS_DATE_NULL(p_string IN date) RETURN NUMBER;
   FUNCTION  IS_NUMBER_NULL(p_string IN number) RETURN NUMBER;
   FUNCTION  IS_VARCHAR2_NULL(p_string IN varchar2) RETURN NUMBER;
   PROCEDURE Insert_Asset_Created_IN_PaaS(IN_ASSET_CREATE WSC_EBS_FA_ASSET_CREATED_T_TYPE_TABLE);
    PROCEDURE UPDATE_REC (P_BATCH_NAME VARCHAR2,LV_LOAD_ID NUMBER);
    PROCEDURE CALL_ASYC_UPDATE(P_BATCH_NAME VARCHAR2,LV_LOAD_ID NUMBER);
    PROCEDURE UPDATE_ESS_ID(P_JOB_ID NUMBER,P_BATCH_ID NUMBER);
    PROCEDURE Insert_Categories_IN_PaaS(IN_ASSET_CATEGORIES WSC_EBS_FA_ASSET_CATEGORIES_T_TYPE_TABLE);
    PROCEDURE MERGE_Categories_IN_PaaS;
    PROCEDURE Insert_Locations_IN_PaaS(IN_ASSET_LOCATIONS WSC_EBS_FA_ASSET_LOCATIONS_T_TYPE_TABLE);
	PROCEDURE Merge_Locations_IN_PaaS;
END WSC_EBS_FA_VALIDATION_TRANSFORMATION_PKG;
/
