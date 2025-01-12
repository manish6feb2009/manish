--------------------------------------------------------
--  File created - Monday-September-06-2021   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Sequence WSC_AP_HEADER_T_S1
--------------------------------------------------------
--+========================================================================|
--| RICE_ID             : INTOO2 - WESCO EBS AP Inbound to AHCS
--| Module/Object Name  : WSC_AP_HEADER_T_S1.sql
--|
--| Description         : Sequence to generate HEADER_ID Script
--|
--| Creation Date       : 03-sept-2021
--|
--| Author              : JIGYASA KAMTHAN
--|
--+========================================================================|
--| Modification History
--+========================================================================|
--| Date			Who					Version	    Change Description
--| -----------------------------------------------------------------------|
--| 		JIGYASA KAMTHAN   	Draft	    Initial draft version  |
--+========================================================================|

   CREATE SEQUENCE  "FININT"."WSC_AP_HEADER_T_S1"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 ORDER  NOCYCLE ;


--------------------------------------------------------
--  File created - Monday-September-06-2021   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Sequence WSC_AP_LINE_T_S1
--------------------------------------------------------
--+========================================================================|
--| RICE_ID             : INTOO2 - WESCO EBS AP Inbound to AHCS
--| Module/Object Name  : WSC_AP_LINE_T_S1.sql
--|
--| Description         : Sequence to generate LINE_ID Script
--|
--| Creation Date       : 03-sept-2021
--|
--| Author              : JIGYASA KAMTHAN
--|
--+========================================================================|
--| Modification History
--+========================================================================|
--| Date			Who					Version	    Change Description
--| -----------------------------------------------------------------------|
--| 		JIGYASA KAMTHAN   	Draft	    Initial draft version  |
--+========================================================================|



   CREATE SEQUENCE  "FININT"."WSC_AP_LINE_T_S1"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 ORDER  NOCYCLE;


COMMIT;