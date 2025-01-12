create or replace PACKAGE WSC_AHCS_REPROCESSING_PKG AS 
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


   PROCEDURE reprocessing_async(P_FILE_NAME IN VARCHAR2);

END WSC_AHCS_REPROCESSING_PKG;
/