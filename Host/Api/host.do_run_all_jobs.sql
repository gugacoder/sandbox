drop procedure if exists [host].[do_run_all_jobs]
go
create procedure [host].[do_run_all_jobs]
  @instance uniqueidentifier,
  @extra_args [host].[tp_parameter] readonly
as
begin
  set nocount on

  declare @message nvarchar(max)
  declare @job_history_id int
  declare @tb_job_history table (
    [job_history_id] int
  )

  --
  -- Detectando e incializando novas procedures `*.jobtask_*`.
  --
  exec [host].[do_detect_new_jobtasks] @instance, @extra_args

  --
  -- Executando JOBs agendados.
  --
  insert into @tb_job_history ([job_history_id])
  select [job_history_id]
    from [host].[vw_pending_job]

  select @job_history_id = min([job_history_id])
    from @tb_job_history

  while @job_history_id is not null begin

    begin try

      exec host.do_run_job
        @job_history_id,
        @instance,
        @extra_args

    end try begin catch
      set @message = concat(error_message(),' (linha ',error_line(),')')
      raiserror ('Falha executando o JOB. (job_history_id = %d) - Causa: %s',10,1,@job_history_id,@message) with nowait
      return
    end catch

    select @job_history_id = min([job_history_id])
      from @tb_job_history
     where [job_history_id] > @job_history_id
  end
end
go
