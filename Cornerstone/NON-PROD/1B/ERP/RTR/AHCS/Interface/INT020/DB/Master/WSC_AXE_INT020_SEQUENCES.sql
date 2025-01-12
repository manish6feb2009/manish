--+========================================================================|
--| RICE_ID             : INT020- Monthly journal feed from LEASES to AHCS
--| Module/Object Name  : WSC_AXE_LHIN_SEQUENCE.sql
--|
--| Description         : Object to contain POC Sequences creation Script
--|
--| Creation Date       : 17-MAY-2022
--|
--| Author              : Syed Zafer Ali
--|
--+========================================================================|
--| Modification History
--+========================================================================|
--| Date			Who					Version	    Change Description
--| -----------------------------------------------------------------------|
--| 17-MAY-20221	Syed Zafer Ali  	Draft	    Initial draft version  |
--+========================================================================|

-- DROP SEQUENCE  "FININT"."WSC_POC_HEADER_S1" ;
-- /
-- DROP SEQUENCE  "FININT"."WSC_POC_LINE_S1" ;
-- /

    CREATE SEQUENCE  "FININT"."WSC_LHIN_HEADER_S1"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20;
    CREATE SEQUENCE  "FININT"."WSC_LHIN_LINE_S1"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20;
	CREATE SEQUENCE  "FININT"."WSC_LHIN_TMP_LINE_NBR_S1"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20;