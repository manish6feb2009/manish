create or replace Package WSC_CCID_MISMATCH_REPORT As
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PACKAGE             WSC_CCID_MISMATCH_REPORT AS
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
-- This package contains supporting procedures required for validation of cache table & update data
-- from cache table. Also include download csv procedure, which will be call from the apex
-- give you the result of cache table validation data where mismatch data sorting first.
-- 
--
--
-- The following staging tables must be created before 
-- 1. WSC_CCID_MISMATCH_DATA_HDR_T
-- 2. WSC_CCID_MISMATCH_DATA_T
-- 3. WSC_CCID_MISMATCH_REPORT_T


--
-- PROCEDURE/ FUNCTION LIST:
--
--     Procedure WSC_CCID
--     Procedure WSC_CCID_ALL
--     Procedure WSC_CCID_UPDATE
--     Procedure WSC_MISMATCH_CCID_DOWNLOAD

--
-- MODIFICATION HISTORY :
--
-- Name                              Date      Ver   Description
-- =================              ===========  ===   ====================================
-- Deloitte Consulting            20-JAN-2023  1.0   Created
--
----------------------------------------------------------------------------------------


    
PROCEDURE WSC_CCID(P_COA_MAP_ID number, P_BATCH_ID number, P_USERNAME varchar2);

PROCEDURE WSC_CCID_ALL(P_COA_MAP_ID number, P_USERNAME varchar2);


PROCEDURE WSC_CCID_UPDATE(P_USERNAME varchar2, P_COA_MAP_NAME varchar2);

PROCEDURE WSC_MISMATCH_CCID_DOWNLOAD(o_Clobdata OUT CLOB,
                        P_CCID_MAP_NAME IN varchar2);

end WSC_CCID_MISMATCH_REPORT;
/