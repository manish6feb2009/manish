/* Formatted on 8/10/2021 2:50:07 PM (QP5 v5.300) */
CREATE TABLE XXWESCO.XXAP_EBS_TO_AHCS_ERRS
(
    SOURCE_SYSTEM       VARCHAR2 (100) NOT NULL,
    FILE_NAME           VARCHAR2 (100) NOT NULL,
    LEG_AE_HEADER_ID    NUMBER NOT NULL,
    LEG_AE_LINE_NBR     NUMBER,
    STATUS              VARCHAR2 (100) NOT NULL,
    ERROR_MESSAGE       VARCHAR2 (1000),
    CR_DR               VARCHAR2 (100),
    CURRENCY            VARCHAR2 (100),
    AMOUNT              NUMBER,
    SOURCE_COA          VARCHAR2 (100),
    CREATION_DATE       DATE DEFAULT SYSDATE,
    CREATED_BY          NUMBER,
    LAST_UPDATE_DATE    DATE DEFAULT SYSDATE,
    LAST_UPDATED_BY     NUMBER,
    LAST_UPDATE_LOGIN   NUMBER,
    CONC_PROGRAM_ID     NUMBER,
    REQUEST_ID          NUMBER
);

GRANT ALL ON XXWESCO.XXAP_EBS_TO_AHCS_ERRS TO apps;