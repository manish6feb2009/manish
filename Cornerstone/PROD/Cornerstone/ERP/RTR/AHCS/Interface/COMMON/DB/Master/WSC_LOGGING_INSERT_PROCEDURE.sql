/*==============================================*/
    /*PROCEDURE LOGGING_INSERT*/
/*==============================================*/

create or replace procedure logging_insert (p_entity_name in varchar2,
    p_batch_id in number,
    p_step_no in number,
    p_description1 in varchar2,
    p_err_msg in varchar2,
    p_creation_date in date)
is 
PRAGMA AUTONOMOUS_TRANSACTION ;
begin
insert into wsc_ahcs_int_logging_t (entity_name,
    batch_id,
    step_no,
    description1,
    err_msg ,
    creation_date)
values(p_entity_name,
    p_batch_id,
    p_step_no,
    p_description1,
    p_err_msg ,
    p_creation_date);
    commit;
end;
/