------------------------------------------------------------
-- WSC_AHCS_COA_CONCAT_SEGMENT Success Wesco
------------------------------------------------------------

SELECT
    decode(COA_NAME,'Wesco to Cloud','WESCO to Cloud',COA_NAME) COA_MAP_NAME,
    SOURCE_SEGMENT1,
    SOURCE_SEGMENT2,
    SOURCE_SEGMENT3,
    SOURCE_SEGMENT4,
    SOURCE_SEGMENT5,
    SOURCE_SEGMENT6,
    SOURCE_SEGMENT7,
    SOURCE_SEGMENT8,
    SOURCE_SEGMENT9,
    SOURCE_SEGMENT10,
    substr(TARGET_COA, 1, instr(TARGET_COA, '.', 1, 1) - 1) target_segment1,
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 1) + 1, instr(TARGET_COA, '.', 1, 2) - instr(TARGET_COA,'.', 1, 1) - 1) target_segment2,
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 2) + 1, instr(TARGET_COA, '.', 1, 3) - instr(TARGET_COA,'.', 1, 2) - 1) target_segment3,
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 3) + 1, instr(TARGET_COA, '.', 1, 4) - instr(TARGET_COA,'.', 1, 3) - 1) target_segment4,
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 4) + 1, instr(TARGET_COA, '.', 1, 5) - instr(TARGET_COA,'.', 1, 4) - 1) target_segment5,
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 5) + 1, instr(TARGET_COA, '.', 1, 6) - instr(TARGET_COA,'.', 1, 5) - 1) target_segment6,
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 6) + 1, instr(TARGET_COA, '.', 1, 7) - instr(TARGET_COA,'.', 1, 6) - 1) target_segment7,
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 7) + 1, instr(TARGET_COA, '.', 1, 8) - instr(TARGET_COA,'.', 1, 7) - 1) target_segment8,
    case
    when target_coa like '%.%' then substr(TARGET_COA, instr(TARGET_COA, '.', 1, 8) + 1, decode(instr(TARGET_COA, '.', 1, 9), 0, length(TARGET_COA) - instr(TARGET_COA, '.', 1, 8), instr(TARGET_COA, '.', 1, 9) - instr(TARGET_COA,'.', 1, 8) - 1)) 
    else null end target_segment9, 
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 9) + 1, instr(TARGET_COA, '.', 1, 10) - instr(TARGET_COA,'.', 1, 9) - 1) target_segment10,
    case
    when target_coa like '%.%' then null
    else target_coa end error_message
FROM
    WSC_AHCS_COA_CONCAT_SEGMENT
    where target_coa like '%.%'
	and coa_name = 'Wesco to Cloud'
order by wsc_seq_num;

------------------------------------------------------------
-- WSC_AHCS_COA_CONCAT_SEGMENT Error Wesco
------------------------------------------------------------
	
SELECT
    decode(COA_NAME,'Wesco to Cloud','WESCO to Cloud',COA_NAME) COA_MAP_NAME,
    SOURCE_SEGMENT1,
    SOURCE_SEGMENT2,
    SOURCE_SEGMENT3,
    SOURCE_SEGMENT4,
    SOURCE_SEGMENT5,
    SOURCE_SEGMENT6,
    SOURCE_SEGMENT7,
    SOURCE_SEGMENT8,
    SOURCE_SEGMENT9,
    SOURCE_SEGMENT10,
    substr(TARGET_COA, 1, instr(TARGET_COA, '.', 1, 1) - 1) target_segment1,
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 1) + 1, instr(TARGET_COA, '.', 1, 2) - instr(TARGET_COA,'.', 1, 1) - 1) target_segment2,
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 2) + 1, instr(TARGET_COA, '.', 1, 3) - instr(TARGET_COA,'.', 1, 2) - 1) target_segment3,
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 3) + 1, instr(TARGET_COA, '.', 1, 4) - instr(TARGET_COA,'.', 1, 3) - 1) target_segment4,
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 4) + 1, instr(TARGET_COA, '.', 1, 5) - instr(TARGET_COA,'.', 1, 4) - 1) target_segment5,
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 5) + 1, instr(TARGET_COA, '.', 1, 6) - instr(TARGET_COA,'.', 1, 5) - 1) target_segment6,
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 6) + 1, instr(TARGET_COA, '.', 1, 7) - instr(TARGET_COA,'.', 1, 6) - 1) target_segment7,
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 7) + 1, instr(TARGET_COA, '.', 1, 8) - instr(TARGET_COA,'.', 1, 7) - 1) target_segment8,
    case
    when target_coa like '%.%' then substr(TARGET_COA, instr(TARGET_COA, '.', 1, 8) + 1, decode(instr(TARGET_COA, '.', 1, 9), 0, length(TARGET_COA) - instr(TARGET_COA, '.', 1, 8), instr(TARGET_COA, '.', 1, 9) - instr(TARGET_COA,'.', 1, 8) - 1)) 
    else null end target_segment9, 
    substr(TARGET_COA, instr(TARGET_COA, '.', 1, 9) + 1, instr(TARGET_COA, '.', 1, 10) - instr(TARGET_COA,'.', 1, 9) - 1) target_segment10,
    case
    when target_coa like '%.%' then null
    else target_coa end error_message
FROM
    WSC_AHCS_COA_CONCAT_SEGMENT
    where target_coa not like '%.%'
	and coa_name = 'Wesco to Cloud'
order by wsc_seq_num;