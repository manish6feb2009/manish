create or replace PACKAGE XXgenai_FA_VEH_ATTRIBUTES_PKG AS

G_MODE_CREATE        CONSTANT VARCHAR2(10) := 'CREATE';
  G_MODE_UPDATE        CONSTANT VARCHAR2(10) := 'UPDATE';
  G_MODE_MANUAL_UPDATE CONSTANT VARCHAR2(15) := 'MANUAL_UPDATE';
  G_MODE_COPY          CONSTANT VARCHAR2(10) := 'COPY';

  TYPE G_VEH_ATTR_TBL_TYPE IS TABLE OF XXgenai_FA_VEH_ATTRIBUTES%ROWTYPE INDEX BY BINARY_INTEGER;

  PROCEDURE populate_veh_attr( p_mode         IN        VARCHAR2
                             , p_vin_attr_tbl IN        G_VEH_ATTR_TBL_TYPE
                             , p_status_out       OUT       VARCHAR2
                             , p_err_msg_out      OUT       VARCHAR2
                             );
  PROCEDURE assign_sequence ( p_oic_instance_id       IN NUMBER
                            , p_user                  IN VARCHAR
							, p_status_out       OUT VARCHAR2
							, p_err_msg_out      OUT VARCHAR2 								 
                             );
END XXgenai_FA_VEH_ATTRIBUTES_PKG;