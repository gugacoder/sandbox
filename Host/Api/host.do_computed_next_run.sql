drop procedure if exists [host].[do_computed_next_run]
go
create procedure [host].[do_computed_next_run]
  @job_id int
as
begin
  set nocount on

  declare @procedure varchar(100)

  select @procedure = [procedure]
    from [host].[job]
   where [id] = @job_id
  
  if not exists (select 1 from [host].[vw_jobtask] where [procedure] = @procedure)
  begin
    update [host].[job] set [disabled] = current_timestamp where [id] = @job_id
    return
  end
  
  if exists (select 1 from [host].[job_history] with (nolock)
    where [job_id] = @job_id and [status] in (0 /* agendado */, 1 /* executando */))
  begin
    -- O JOB já existe agendado. Nada a fazer...
    return
  end

  --
  -- Computando a proxima execucao
  --
    ..... 

end
go

exec [host].[do_computed_next_run] 1
