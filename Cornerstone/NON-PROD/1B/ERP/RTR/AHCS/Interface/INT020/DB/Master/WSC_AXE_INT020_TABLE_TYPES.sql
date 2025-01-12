create or replace TYPE wsc_lhin_tmp_t_type FORCE AS OBJECT (
    batch_id             NUMBER,
    rice_id              VARCHAR2(20),
    capital_lease_id     VARCHAR2(100),
    apply_date           VARCHAR2(100),
    file_id              VARCHAR2(100),
    name                 VARCHAR2(100),
    category             VARCHAR2(100),
    type                 VARCHAR2(100),
    amount               VARCHAR2(100),
    org_fiscal_year      VARCHAR2(100),
    org_fiscal_period    VARCHAR2(100),
    fiscal_year          VARCHAR2(100),
    fiscal_period        VARCHAR2(100),
    account              VARCHAR2(100),
    account_description  VARCHAR2(100),
    record_id            VARCHAR2(100),
    business_unit        VARCHAR2(100),
    location             VARCHAR2(100),
    country              VARCHAR2(100),
    amount_tag           VARCHAR2(100),
    vendor_number        VARCHAR2(100),
    non_ps_vendor_number VARCHAR2(100),
    currency             VARCHAR2(100),
    asset_type           VARCHAR2(100),
    sub_type             VARCHAR2(100),
    lease_classification VARCHAR2(100),
    src_batch_id         VARCHAR2(100),
    department           VARCHAR2(100),
    created_by           VARCHAR2(100),
    creation_date        DATE,
    CONSTRUCTOR FUNCTION wsc_lhin_tmp_t_type RETURN SELF AS RESULT
);

/

create or replace TYPE BODY wsc_lhin_tmp_t_type AS
    CONSTRUCTOR FUNCTION wsc_lhin_tmp_t_type RETURN SELF AS RESULT AS
    BEGIN
        RETURN;
    END;

END;

/

create or replace TYPE wsc_lhin_tmp_t_type_table FORCE AS
    TABLE OF wsc_lhin_tmp_t_type;
	/