
--+========================================================================|
--| RICE_ID             : INT018 - AXE Cloudpay Inbound to AHCS
--| Module/Object Name  : WSC_INT018_LINE_TABLE_TYPE.sql
--|
--| Description         : Line table type creation Script
--|
--| Creation Date       : 05-SEPT-2022
--|
--| Author              : JIGYASA KAMTHAN
--|
--+========================================================================|
--| Modification History
--+========================================================================|
--| Date			Who					Version	    Change Description
--| -----------------------------------------------------------------------|
--| 05-SEPT-2022	JIGYASA KAMTHAN   	Draft	    Initial draft version  |
--+========================================================================|
--------------------------------------------------------
--  DDL for Type wsc_ahcs_cloudpay_txn_line_t_type
--------------------------------------------------------
create or replace TYPE wsc_ahcs_cloudpay_txn_line_t_type FORCE AS OBJECT ( /* TODO enter attribute and method declarations here */
    batch_id              NUMBER,
    header_id             NUMBER,
    accounting_date       DATE,
    default_amt           NUMBER,
    dr                    NUMBER,
    cr                    NUMBER,
    default_currency      VARCHAR2(5 CHAR),
    conversion_rate_type  VARCHAR(10 CHAR),
    company_num           VARCHAR2(15 CHAR),
    pay_code              VARCHAR2(30 CHAR),
    gl_code               VARCHAR2(30 CHAR),
    cost_center_name      VARCHAR2(30 CHAR),
    gl_legal_entity       VARCHAR(30 CHAR),
    gl_oper_grp           VARCHAR(30 CHAR),
    gl_acct               VARCHAR(30 CHAR),
    gl_dept               VARCHAR(30 CHAR),
    gl_site               VARCHAR(30 CHAR),
    gl_ic                 VARCHAR(30 CHAR),
    gl_projects           VARCHAR(30 CHAR),
    gl_fut_1              VARCHAR(30 CHAR),
    gl_fut_2              VARCHAR(30 CHAR),
    pay_code_desc         VARCHAR2(50 CHAR),
    leg_seg_1_4           VARCHAR(50 CHAR),
    transaction_number    VARCHAR2(100 CHAR),
    leg_coa               VARCHAR(100 CHAR),
    target_coa            VARCHAR(100 CHAR),
    creation_date         DATE,
    created_by            VARCHAR2(100 CHAR),
    last_update_date      DATE,
    last_updated_by       VARCHAR2(100 CHAR),
    attribute1            NUMBER,
    attribute2            NUMBER,
    attribute3            NUMBER,
    attribute4            NUMBER,
    attribute5            NUMBER,
    attribute6            DATE,
    attribute7            DATE,
    attribute8            VARCHAR2(240 CHAR),
    attribute9            VARCHAR2(240 CHAR),
    attribute10           VARCHAR2(240 CHAR),
    attribute11           VARCHAR2(1000 CHAR),
    attribute12           VARCHAR2(1000 CHAR)
);

/ 
--------------------------------------------------------
-- DDL for Type wsc_ahcs_cloudpay_txn_line_t_type_table
--------------------------------------------------------
create or replace TYPE wsc_ahcs_cloudpay_txn_line_t_type_table
 FORCE AS TABLE OF wsc_ahcs_cloudpay_txn_line_t_type /* datatype */;


/