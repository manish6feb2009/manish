CREATE TABLE FININT.WSC_CUSTOM_ESS_JOB_HOLD_RELEASE_HISTORY 
   (ID NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY, 
	INSTANCE_ID NUMBER(20), 
	REQUEST_ID NUMBER(20), 
	JOB_NAME VARCHAR2(200), 
	SUBMISSION_NOTES VARCHAR2(150), 
	STATE VARCHAR2(20), 
	SCHEDULED_TIME VARCHAR2(22), 
	CREATED_BY VARCHAR2(20), 
	CREATION_DATE DATE DEFAULT SYSDATE, 
	LAST_UPDATED_BY VARCHAR2(20), 
	LAST_UPDATED_DATE DATE DEFAULT SYSDATE, 
	ATTRIBUTE1 VARCHAR2(200), 
	ATTRIBUTE2 VARCHAR2(50), 
	ATTRIBUTE3 VARCHAR2(50), 
	ATTRIBUTE4 VARCHAR2(50), 
	ATTRIBUTE5 VARCHAR2(50), 
	ATTRIBUTE6 VARCHAR2(50), 
	ATTRIBUTE7 VARCHAR2(50), 
	ATTRIBUTE8 VARCHAR2(50), 
	ATTRIBUTE9 VARCHAR2(50), 
	ATTRIBUTE10 VARCHAR2(50)
);

GRANT SELECT ON FININT.WSC_CUSTOM_ESS_JOB_HOLD_RELEASE_HISTORY TO FININT_RO;

COMMIT;