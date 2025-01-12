/*=====================================================*/
             /* INDEX XX_IMD_INTEG_MASTER_T_PK */
/*=====================================================*/
  CREATE UNIQUE INDEX "DGTL_PLS"."XX_IMD_INTEG_MASTER_T_PK" ON "DGTL_PLS"."XX_IMD_INTEGRATION_MASTER_T" ("ID") COMPUTE STATISTICS;


/*=====================================================*/
             /* INDEX XX_IMD_INTEG_RUN_T_PK */
/*=====================================================*/
  CREATE UNIQUE INDEX "DGTL_PLS"."XX_IMD_INTEG_RUN_T_PK" ON "DGTL_PLS"."XX_IMD_INTEGRATION_RUN_T" ("ID") COMPUTE STATISTICS;


/*=====================================================*/
             /* INDEX XX_IMD_INTEG_ACTIVITY_T_PK */
/*=====================================================*/
  CREATE UNIQUE INDEX "DGTL_PLS"."XX_IMD_INTEG_ACTIVITY_T_PK" ON "DGTL_PLS"."XX_IMD_INTEGRATION_ACTIVITY_T" ("ID") COMPUTE STATISTICS;


/*=====================================================*/
             /* INDEX SYS_C0076729 */
/*=====================================================*/
 -- CREATE UNIQUE INDEX "DGTL_PLS"."SYS_C0076729" ON "DGTL_PLS"."XX_IMD_ADDITIONAL_INFO_T" ("ID") COMPUTE STATISTICS;



