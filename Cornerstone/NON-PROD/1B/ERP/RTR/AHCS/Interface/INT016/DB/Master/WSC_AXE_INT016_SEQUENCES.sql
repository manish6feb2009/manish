--+========================================================================|
--| RICE_ID             : INT016 Journal feed from Concur to AHCS
--| Module/Object Name  : WSC_AXE_INT016_SEQUENCE.sql
--|
--| Description         : Object to contain POC Sequences creation Script
--|
--| Creation Date       : 29-AUG-2022
--|
--| Author              : Syed Zafer Ali
--|
--+========================================================================|
--| Modification History
--+========================================================================|
--| Date			Who					Version	    Change Description
--| -----------------------------------------------------------------------|
--| 29-AUG-20221	Syed Zafer Ali  	Draft	    Initial draft version  |
--+========================================================================|

-- DROP SEQUENCE  "FININT"."WSC_POC_HEADER_S1" ;
-- /
-- DROP SEQUENCE  "FININT"."WSC_POC_LINE_S1" ;
-- /

    CREATE SEQUENCE  "FININT"."WSC_CONCUR_HEADER_S1"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20;
    
    CREATE SEQUENCE  "FININT"."WSC_CONCUR_LINE_S1"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20;