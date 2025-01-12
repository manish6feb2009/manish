create or replace PACKAGE            XXgenai_COSTAR_GL_JOURNAL_INT_PKG AS
TYPE x_error_detail_rec_type IS RECORD( rec_status			VARCHAR2( 250 )
										,error_message       clob
									  );

TYPE x_err_detail_type IS TABLE OF x_error_detail_rec_type;
PROCEDURE perform_validation( p_oic_flow_id		IN 	NUMBER
							, p_file_name		IN 	 VARCHAR2
							, p_status_out      OUT VARCHAR2
							, p_err_msg_out     OUT VARCHAR2 
							);

PROCEDURE updatestagingtable( p_oic_flow_id		 IN  NUMBER
							, p_file_name		 IN  VARCHAR2 
							, p_status_out	     OUT VARCHAR2
							, p_err_msg_out      OUT VARCHAR2 
					   );

PROCEDURE update_status( p_err_detail_type   IN  x_err_detail_type
					   , p_process_flag		 IN  VARCHAR2
                       , p_failed_status     IN  VARCHAR2
					   , p_file_name     	 IN  VARCHAR2
					   , p_group_id          IN  VARCHAR2
					   , p_total_rec_count	 OUT NUMBER
					   , p_status_out        OUT VARCHAR2
					   , p_err_msg_out       OUT VARCHAR2 
					   );
PROCEDURE batch_creation(p_filename			IN VARCHAR2 
						,p_instance_id			IN VARCHAR2 
						,p_status_out        OUT  VARCHAR2
						,p_err_msg_out       OUT  VARCHAR2
                       );
END XXgenai_COSTAR_GL_JOURNAL_INT_PKG;