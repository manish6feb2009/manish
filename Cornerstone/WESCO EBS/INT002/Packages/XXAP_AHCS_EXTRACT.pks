/* Formatted on 10/26/2023 1:09:35 PM (QP5 v5.300) */
CREATE OR REPLACE PACKAGE APPS.XXAP_AHCS_EXTRACT
AS
    -- -----------------------------------------------------------------------------
    -- ------------------------------------------------------------------------- --
    --  Change Log:
    --  Version       Date       Author         Description
    -- -------- ------------ -------------  --------------------------------------
    --    1.0   15-Jul-2021  Laxman M       CornerStone Project - IINT002-Wesco EBS AP Inbound to AHCS
    -- ------------------------------------------------------------------------- --
    PROCEDURE extract_daily_records (p_out_err_msg             OUT VARCHAR2,
                                     p_out_ret_code            OUT NUMBER,
                                     p_in_run_mode          IN     VARCHAR2,
                                     p_in_run_date_from     IN     VARCHAR2,
                                     p_in_date_from_exsts   IN     VARCHAR2,
                                     p_in_run_date_to       IN     VARCHAR2,
                                     p_in_period            IN     VARCHAR2,
                                     p_in_chr_err_email     IN     VARCHAR2,
                                     p_no_params_check      IN     VARCHAR2,
                                     p_outfile_directory    IN     VARCHAR2);

    PROCEDURE load_errors (p_out_err_msg           OUT VARCHAR2,
                           p_out_ret_code          OUT NUMBER,
                           p_in_chr_err_email   IN     VARCHAR2);
END XXAP_AHCS_EXTRACT;
/