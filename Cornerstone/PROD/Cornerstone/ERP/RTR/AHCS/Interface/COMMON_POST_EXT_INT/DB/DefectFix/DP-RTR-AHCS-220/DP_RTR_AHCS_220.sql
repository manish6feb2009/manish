--US DP-RTR-AHCS-220 -- 29 June 2023
UPDATE finint.wsc_ahcs_mf_bsr_assignment_line_t
SET bsr_assignment = 'UBSR'
WHERE gl_account = '115111';

commit;
-- output: 1 row updated---