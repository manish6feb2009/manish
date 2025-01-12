CREATE OR REPLACE EDITIONABLE PACKAGE "genai_CUSTOM"."XXgenai_FA_DEP_ENGINE_RATES_PKG" AS 
  
    PROCEDURE insert_pre_stg (
        p_oic_instance_id IN NUMBER,
        p_file_name       IN VARCHAR2,
        P_SOURCE            IN VARCHAR2,
        P_BATCH_ID          IN NUMBER,
        p_status_out      OUT VARCHAR2,
        p_err_msg_out     OUT VARCHAR2
    );
  
  PROCEDURE main_proc(
  p_oic_instance_id IN NUMBER,
  P_BATCH_ID          IN NUMBER,
  p_file_name       IN VARCHAR2,
  p_status_out   OUT VARCHAR2,
  p_err_msg_out   OUT VARCHAR2
                     );
        

PROCEDURE assign_batchid (
        p_oic_instance_id  IN NUMBER,
        p_status_out  OUT VARCHAR2,
        p_err_msg_out OUT VARCHAR2
    );

END XXgenai_FA_DEP_ENGINE_RATES_PKG;

