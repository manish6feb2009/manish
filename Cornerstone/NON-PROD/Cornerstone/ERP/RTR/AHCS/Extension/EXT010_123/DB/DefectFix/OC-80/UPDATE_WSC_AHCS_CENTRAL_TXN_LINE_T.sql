UPDATE FININT.WSC_AHCS_CENTRAL_TXN_LINE_T
SET leg_seg2 = '7998', 
    leg_coa = Replace(leg_coa, '0000', '7998')
WHERE batch_id =  1640
AND leg_seg2 = '0000';
