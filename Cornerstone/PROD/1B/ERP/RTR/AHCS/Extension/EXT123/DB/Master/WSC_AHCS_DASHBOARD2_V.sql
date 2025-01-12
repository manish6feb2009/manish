
  CREATE OR REPLACE FORCE EDITIONABLE VIEW "FININT"."WSC_AHCS_DASHBOARD2_V" ("APPLICATION", "SOURCE_SYSTEM", "ACCOUNTING_PERIOD", "INTERFACE_PROC_STATUS", "CREATE_ACC_STATUS", "TOTAL_CR", "TOTAL_DR", "NUM_ROWS", "DUMMY", "DUMMY4") AS 
  select MAIN_V.APPLICATION,
MAIN_V.SOURCE_SYSTEM,
MAIN_V.ACCOUNTING_PERIOD,
MAIN_V.interface_proc_status,
MAIN_V.create_acc_status,
DR_CR_V.CR,
DR_CR_V.DR,
MAIN_V.NUM_ROW,
 decode(MAIN_V.create_acc_status, 'Final Accounted', 'none', 'Import Pending', 'none', 'Accounting Pending', 'none','Draft Accounted','none','Error', 'none','Import Error',  'none',decode(MAIN_V.interface_proc_status,'TRANSFORM_SUCCESS',null,'OTH'),'none',
               '0')                           dummy,
        decode(MAIN_V.create_acc_status,'Error','apg','Import Error','none','none') DUMMY4
from WSC_AHCS_DSHB2_DR_CR_V DR_CR_V,WSC_AHCS_DSHB2_MAIN_V MAIN_V
where 
MAIN_V.APPLICATION = DR_CR_V.APPLICATION 
and 
nvl(MAIN_V.SOURCE_SYSTEM,'X') = nvl(DR_CR_V.SOURCE_SYSTEM,'X') 
and
MAIN_V.ACCOUNTING_PERIOD = DR_CR_V.ACCOUNTING_PERIOD 
and
nvl(MAIN_V.CREATE_ACC_STATUS ,'X') = nvl(DR_CR_V.CREATE_ACC_STATUS ,'X')
and
MAIN_V.interface_proc_status = DR_CR_V.interface_proc_status;


/