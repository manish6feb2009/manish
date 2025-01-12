create or replace PACKAGE XXgenai_FA_ACT_VEH_DTLS_FCM_PKG 
AS
   G_INT_STATUS_NEW		constant varchar2(1) := 'N';
    G_INT_STATUS_ERROR		constant varchar2(1) := 'E';
	G_INT_STATUS_SUCCESS	constant varchar2(1) := 'S';    

TYPE x_veh_det_rec_type
       IS
        RECORD
       ( OIC_INSTANCE_ID           			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.OIC_INSTANCE_ID%TYPE
        ,RECORD_ID                			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.RECORD_ID%TYPE
        ,BATCH_ID                 			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.BATCH_ID%TYPE
        ,TRANSACTION_ID           			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.TRANSACTION_ID%TYPE
        ,ORIGINATING_SYSTEM_ID    			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.ORIGINATING_SYSTEM_ID%TYPE
        ,REG_NO                   			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.REG_NO%TYPE
        ,VIN                      			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.VIN%TYPE
        ,VENDOR_DESCRIPTION       			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.VENDOR_DESCRIPTION%TYPE
        ,THIRD_PARTY_ID           			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.THIRD_PARTY_ID%TYPE
        ,THIRD_PARTY_VEH_STATUS   			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.THIRD_PARTY_VEH_STATUS%TYPE
        ,ODOMETER_READING         			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.ODOMETER_READING%TYPE
        ,DATE_OF_REGISTRATION     			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.DATE_OF_REGISTRATION%TYPE
        ,IN_FLEET_DATE            			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.IN_FLEET_DATE%TYPE
        ,MANUFACTURER             			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.MANUFACTURER%TYPE
        ,MODEL                    			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.MODEL%TYPE
        ,MANUFACTURER_MODEL_CODE  			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.MANUFACTURER_MODEL_CODE%TYPE
        ,DERIVATIVE               			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.DERIVATIVE%TYPE
        ,DESCRIPTION              			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.DESCRIPTION%TYPE
        ,VEHICLETYPE              			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.VEHICLETYPE%TYPE
        ,ENGINESIZECC             			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.ENGINESIZECC%TYPE
        ,FUELTYPE                 			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.FUELTYPE%TYPE
        ,MODELYEAR                			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.MODELYEAR%TYPE
        ,COLOUR_DESCRIPTION       			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.COLOUR_DESCRIPTION%TYPE
        ,TRIM_DESCRIPTION         			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.TRIM_DESCRIPTION%TYPE
        ,OCN                      			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.OCN%TYPE
        ,OWNER_AREA_NUMBER        			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.OWNER_AREA_NUMBER%TYPE
        ,PURCHASE_TYPE            			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.PURCHASE_TYPE%TYPE
        ,BOOKVALUE                			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.BOOKVALUE%TYPE
        ,DEPRECIATION_RATE        			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.DEPRECIATION_RATE%TYPE
        ,PURCHASE_ORDER_NUMBER    			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.PURCHASE_ORDER_NUMBER%TYPE
        ,LIST_PRICE               			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.LIST_PRICE%TYPE
        ,ATTRIBUTE1               			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.ATTRIBUTE1%TYPE
        ,ATTRIBUTE2               			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.ATTRIBUTE2%TYPE
        ,ATTRIBUTE3               			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.ATTRIBUTE3%TYPE
        ,ATTRIBUTE4               			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.ATTRIBUTE4%TYPE
        ,ATTRIBUTE5               			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.ATTRIBUTE5%TYPE
        ,IMPORT_UPDATE_FLAG       			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.IMPORT_UPDATE_FLAG%TYPE
        ,RUN_TIMESTAMP            			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.RUN_TIMESTAMP%TYPE
        ,CREATION_DATE            			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.CREATION_DATE%TYPE
        ,CREATED_BY               			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.CREATED_BY%TYPE
        ,LAST_UPDATE_DATE         			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.LAST_UPDATE_DATE%TYPE
        ,LAST_UPDATED_BY          			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.LAST_UPDATED_BY%TYPE
        ,LOAD_STATUS              			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.LOAD_STATUS%TYPE
        ,RECORD_STATUS            			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.RECORD_STATUS%TYPE
        ,ERROR_CODE               			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.ERROR_CODE%TYPE
        ,ERROR_SCOPE              			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.ERROR_SCOPE%TYPE
        ,FCM_PAYLOAD              			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.FCM_PAYLOAD%TYPE
        ,FCM_ACK_STATUS           			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.FCM_ACK_STATUS%TYPE
        ,FCM_ACK_MESSAGE          			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.FCM_ACK_MESSAGE%TYPE
        ,FCM_RESPONSE             			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.FCM_RESPONSE%TYPE
        ,ERROR_MESSAGE            			XXgenai_FA_ACT_VEH_DTLS_FCM_STG.ERROR_MESSAGE%TYPE
       );

       TYPE x_veh_det_table IS
         TABLE OF x_veh_det_rec_type INDEX BY BINARY_INTEGER;

     PROCEDURE main (
        p_record_type     IN x_veh_det_table,
        p_last_updated_by IN VARCHAR2,
        p_oic_instance_id IN VARCHAR2,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
     );

    PROCEDURE VALIDATE_VI_VU_DATA(p_oic_instance_id 	IN 	 VARCHAR2,									
								  p_load_status		IN	 VARCHAR2,
								  p_status_out		OUT	 VARCHAR2,
								  p_err_msg_out       OUT  VARCHAR2);

	PROCEDURE ASSIGN_BATCHID( p_oic_instance_id  IN  VARCHAR2,
							  p_load_status		 IN	 VARCHAR2,
							  p_vi_batch_size	 IN	 NUMBER,
							  p_vu_batch_size	 IN	 NUMBER,
							  p_status_out       OUT VARCHAR2,
							  p_err_msg_out      OUT VARCHAR2);

END XXgenai_FA_ACT_VEH_DTLS_FCM_PKG;