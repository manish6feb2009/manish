SELECT
    coa.coa_map_name,
    substr(ccid.source_segment, 1, instr(ccid.source_segment, '.', 1, 1) - 1) source_segment1,
    substr(ccid.source_segment, instr(ccid.source_segment, '.', 1, 1) + 1, decode(instr(ccid.source_segment, '.', 1, 2), 0, length(ccid.source_segment) - instr(ccid.source_segment, '.', 1, 1), instr(ccid.source_segment, '.', 1, 2) - instr(ccid.source_segment,'.', 1, 1) - 1)) source_segment2,
    substr(ccid.source_segment, instr(ccid.source_segment, '.', 1, 2) + 1, instr(ccid.source_segment, '.', 1, 3) - instr(ccid.source_segment,'.', 1, 2) - 1) source_segment3,
    substr(ccid.source_segment, instr(ccid.source_segment, '.', 1, 3) + 1, instr(ccid.source_segment, '.', 1, 4) - instr(ccid.source_segment,'.', 1, 3) - 1) source_segment4,
    substr(ccid.source_segment, instr(ccid.source_segment, '.', 1, 4) + 1, instr(ccid.source_segment, '.', 1, 5) - instr(ccid.source_segment,'.', 1, 4) - 1) source_segment5,
    substr(ccid.source_segment, instr(ccid.source_segment, '.', 1, 5) + 1, instr(ccid.source_segment, '.', 1, 6) - instr(ccid.source_segment,'.', 1, 5) - 1) source_segment6,
    substr(ccid.source_segment, instr(ccid.source_segment, '.', 1, 6) + 1, instr(ccid.source_segment, '.', 1, 7) - instr(ccid.source_segment,'.', 1, 6) - 1) source_segment7,
    CASE
        WHEN instr(ccid.source_segment, '.', 1, 7) = 0 THEN
            NULL
        ELSE
            substr(ccid.source_segment, instr(ccid.source_segment, '.', 1, 7) + 1, decode(instr(ccid.source_segment, '.', 1, 8), 0,length(ccid.source_segment) - instr(ccid.source_segment, '.', 1, 7), instr(ccid.source_segment, '.', 1, 8) - instr(ccid.source_segment, '.', 1, 7) - 1))
    END source_segment8,
    substr(ccid.source_segment, instr(ccid.source_segment, '.', 1, 8) + 1, instr(ccid.source_segment, '.', 1, 9) - instr(ccid.source_segment,'.', 1, 8) - 1) source_segment9,
    substr(ccid.source_segment, instr(ccid.source_segment, '.', 1, 9) + 1, instr(ccid.source_segment, '.', 1, 10) - instr(ccid.source_segment,'.', 1, 9) - 1) source_segment10,
    substr(ccid.target_segment, 1, instr(ccid.target_segment, '.', 1, 1) - 1) target_segment1,
    substr(ccid.target_segment, instr(ccid.target_segment, '.', 1, 1) + 1, instr(ccid.target_segment, '.', 1, 2) - instr(ccid.target_segment,'.', 1, 1) - 1) target_segment2,
    substr(ccid.target_segment, instr(ccid.target_segment, '.', 1, 2) + 1, instr(ccid.target_segment, '.', 1, 3) - instr(ccid.target_segment,'.', 1, 2) - 1) target_segment3,
    substr(ccid.target_segment, instr(ccid.target_segment, '.', 1, 3) + 1, instr(ccid.target_segment, '.', 1, 4) - instr(ccid.target_segment,'.', 1, 3) - 1) target_segment4,
    substr(ccid.target_segment, instr(ccid.target_segment, '.', 1, 4) + 1, instr(ccid.target_segment, '.', 1, 5) - instr(ccid.target_segment,'.', 1, 4) - 1) target_segment5,
    substr(ccid.target_segment, instr(ccid.target_segment, '.', 1, 5) + 1, instr(ccid.target_segment, '.', 1, 6) - instr(ccid.target_segment,'.', 1, 5) - 1) target_segment6,
    substr(ccid.target_segment, instr(ccid.target_segment, '.', 1, 6) + 1, instr(ccid.target_segment, '.', 1, 7) - instr(ccid.target_segment,'.', 1, 6) - 1) target_segment7,
    substr(ccid.target_segment, instr(ccid.target_segment, '.', 1, 7) + 1, instr(ccid.target_segment, '.', 1, 8) - instr(ccid.target_segment,'.', 1, 7) - 1) target_segment8,
    substr(ccid.target_segment, instr(ccid.target_segment, '.', 1, 8) + 1, decode(instr(ccid.target_segment, '.', 1, 9), 0, length(ccid.target_segment) - instr(ccid.target_segment, '.', 1, 8), instr(ccid.target_segment, '.', 1, 9) - instr(ccid.target_segment,'.', 1, 8) - 1)) target_segment9,
    substr(ccid.target_segment, instr(ccid.target_segment, '.', 1, 9) + 1, instr(ccid.target_segment, '.', 1, 10) - instr(ccid.target_segment,'.', 1, 9) - 1) target_segment10,
	null ERROR_MESSAGE
FROM
    wsc_gl_ccid_mapping_t  ccid,
    wsc_gl_coa_map_t       coa
WHERE
    ccid.coa_map_id = coa.coa_map_id
    and enable_flag = 'Y';