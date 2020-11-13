--
-- PROCEDURE host.jobtask_sample_job
--
drop procedure if exists host.jobtask_sample_job
go
create procedure host.jobtask_sample_job
  -- parâmetros especiais do JOB
  @job_id bigint,
  @action varchar(10),
  @instance uniqueidentifier,
  @due_date datetime
as
begin
  declare @msg varchar(max)
  set @msg = concat('@job_id=',@job_id)     raiserror (@msg,10,1) with nowait
  set @msg = concat('@action=',@action)     raiserror (@msg,10,1) with nowait
  set @msg = concat('@instance=',@instance) raiserror (@msg,10,1) with nowait
  set @msg = concat('@due_date=',@due_date) raiserror (@msg,10,1) with nowait
end
go
