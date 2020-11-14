--
-- CADASTRANDO OS JOBS
--
exec host.do_unschedule_job @procedure='host.jobtask_sample_job',@name='oneshot'
exec host.do_unschedule_job @procedure='host.jobtask_sample_job',@name='repeated'
exec host.do_unschedule_job @procedure='host.jobtask_sample_job',@name='delayed'
--
declare @due_date datetime = current_timestamp
exec host.do_schedule_job @no_output=1,@procedure='host.jobtask_sample_job',@name='oneshot',@due_date=@due_date
exec host.do_schedule_job @no_output=1,@procedure='host.jobtask_sample_job',@name='repeated',@days=0,@time='00:30:00',@repeat=1,@start_date='2020-11-14 16:00'
exec host.do_schedule_job @no_output=1,@procedure='host.jobtask_sample_job',@name='delayed',@days=0,@time='00:30:00',@delayed=1
--

GO

select * from host.job
select * from host.job_history
select * from host.vw_pending_job

GO

--
-- EXECUTANDO OS JOBS
--
--
update host.job_history set due_date = current_timestamp where due_date > current_timestamp
select * from host.vw_pending_job
--
declare @guid uniqueidentifier = newid()
declare @id int
declare @tb_id table (id int)
insert into @tb_id select job_history_id from host.vw_pending_job
select @id = min(id) from @tb_id
while @id is not null begin
  exec [host].[do_run_job] @id, @guid
  select @id = min(id) from @tb_id where id > @id
end
--
select status, fault, * from host.job_history

GO

--
-- DRAFTS...
--
declare @guid uniqueidentifier = newid()
exec [host].[do_run_job] 1, @guid
