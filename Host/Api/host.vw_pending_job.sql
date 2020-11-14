drop view if exists [host].[vw_pending_job]
go
create view [host].[vw_pending_job]
as
select [id] as [job_history_id]
     , [job_id]
     , [due_date]
  from [host].[job_history]
 where [status] = 0
   and [due_date] <= current_timestamp
go
