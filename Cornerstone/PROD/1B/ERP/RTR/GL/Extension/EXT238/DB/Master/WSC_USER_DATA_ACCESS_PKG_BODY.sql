create or replace Package BODY WSC_USER_DATA_ACCESS_PKG IS

Procedure INSERT_REC(P_INS_VAL WSC_USER_DATA_ACCESS_T_TAB,
	P_ERR_MSG OUT VARCHAR2,
	P_ERR_CODE OUT VARCHAR2) IS
					 
	--L_ERR_MSG VARCHAR2(2000);
	--L_ERR_CODE VARCHAR2(2);
BEGIN
	FOR i in P_INS_VAL.FIRST..P_INS_VAL.LAST LOOP
		Begin
			insert into WSC_USER_DATA_ACCESS_T (LEDGER_INTER_ORG_NAME,
                LEDGER_INTER_ORG_ID,
                LEGAL_ENTITY_ID,
                ACTIVE_FLAG,
                USERNAME,
                ENTITY_TYPE,
                COMPLETION_DATE)
            values (
                P_INS_VAL(i).LEDGER_INTER_ORG_NAME,
                P_INS_VAL(i).LEDGER_INTER_ORG_ID,
                P_INS_VAL(i).LEGAL_ENTITY_ID,
                P_INS_VAL(i).ACTIVE_FLAG,
                P_INS_VAL(i).USERNAME,
                P_INS_VAL(i).ENTITY_TYPE,
                P_INS_VAL(i).COMPLETION_DATE
            );
        Commit;
		Exception
			WHEN OTHERS THEN
				P_ERR_MSG := P_ERR_MSG ||' . ' ||SQLERRM; 
				P_ERR_CODE := SQLCODE;
		END;       
	END LOOP;

	EXCEPTION
		WHEN OTHERS THEN
			P_ERR_MSG := 'Error while inserting ' ||' . ' || P_ERR_MSG ;
			P_ERR_CODE := 2; 
	END;
end WSC_USER_DATA_ACCESS_PKG;
/