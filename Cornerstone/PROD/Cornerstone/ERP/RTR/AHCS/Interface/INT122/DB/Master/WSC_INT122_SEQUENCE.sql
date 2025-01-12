--+========================================================================|
--| RICE_ID             : INT122 - INT122 - Daily GL journal feed from ERP POC to AHCS
--| Module/Object Name  : WSC_POC_SEQUENCE.sql
--|
--| Description         : Object to contain POC Sequences creation Script
--|
--| Creation Date       : 06-SEPT-2021
--|
--| Author              : Syed Zafer Ali
--|
--+========================================================================|
--| Modification History
--+========================================================================|
--| Date			Who					Version	    Change Description
--| -----------------------------------------------------------------------|
--| 06-SEPT-2021	Syed Zafer Ali  	Draft	    Initial draft version  |
--+========================================================================|

-- DROP SEQUENCE  "FININT"."WSC_POC_HEADER_S1" ;
-- /
-- DROP SEQUENCE  "FININT"."WSC_POC_LINE_S1" ;
-- /

CREATE SEQUENCE  "FININT"."WSC_POC_HEADER_S1"  MINVALUE 1 MAXVALUE 99999999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20;  
CREATE SEQUENCE  "FININT"."WSC_POC_LINE_S1"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 ;