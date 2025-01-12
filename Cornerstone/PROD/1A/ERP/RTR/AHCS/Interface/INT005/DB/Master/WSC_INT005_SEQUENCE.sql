--------------------------------------------------------
--  File created - Friday-September-03-2021   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Sequence WES_AR_HEADER_S1
--------------------------------------------------------
--+========================================================================|
--| RICE_ID             : INTOO5 - WESCO EBS AR Inbound to AHCS
--| Module/Object Name  : WSC_AR_HEADER_S1.sql
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

   CREATE SEQUENCE  "FININT"."WSC_AR_HEADER_S1"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 ORDER  NOCYCLE;

--------------------------------------------------------
--  File created - Friday-September-03-2021   
--------------------------------------------------------
--+========================================================================|
--| RICE_ID             : INTOO5 - WESCO EBS AR Inbound to AHCS
--| Module/Object Name  : WSC_AR_LINE_S1.sql
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
--------------------------------------------------------
--  DDL for Sequence WES_AR_LINE_S1
--------------------------------------------------------


   CREATE SEQUENCE  "FININT"."WSC_AR_LINE_S1"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 ORDER  NOCYCLE;


commit;