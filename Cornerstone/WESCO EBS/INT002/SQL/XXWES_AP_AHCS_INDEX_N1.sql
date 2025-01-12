CREATE INDEX xxwes_ap_ahcs_hdr_stg_N1
    ON xxwes_ap_ahcs_hdr_stg (leg_ae_header_id, status);

CREATE INDEX xxwes_ap_ahcs_hdr_stg_N2
    ON xxwes_ap_ahcs_hdr_stg (file_name);

CREATE INDEX xxwes_ap_ahcs_line_stg_N1
    ON xxwes_ap_ahcs_line_stg (leg_ae_header_id);

CREATE INDEX xxwes_ap_ahcs_line_stg_N2
    ON xxwes_ap_ahcs_line_stg (file_name);

CREATE INDEX xxap_ebs_to_ahcs_errs_N1
    ON xxap_ebs_to_ahcs_errs (leg_ae_header_id);

CREATE INDEX xxap_ebs_to_ahcs_errs_N2
    ON xxap_ebs_to_ahcs_errs (file_name);

CREATE INDEX xxwes_ebs_to_ahcs_ctl_N1
    ON xxwes_ebs_to_ahcs_ctl (file_name);