drop procedure if exists [host].[do_run_all_jobs]
go
create procedure [host].[do_run_all_jobs]
  @instance uniqueidentifier,
  @extra_args [host].[tp_parameter] readonly
as
begin
  set nocount on

  declare @procedure varchar(100)
  declare @tb_procedure table (
    [procedure] varchar(100)
  )
  declare @job_history_id int
  declare @tb_job_history table (
    [job_history_id] int
  )
  declare @message nvarchar(max)

  --
  -- Detectando e incializando novas procedures `*.jobtask_*`.
  --
  insert into @tb_procedure ([procedure])
  select [procedure]
    from [host].[vw_jobtask]
   where [valid] = 1
     and not exists (
          select 1 from [host].[job]
           where [procedure] = [host].[vw_jobtask].[procedure]
     )

  select @procedure = min([procedure]) from @tb_procedure
  while @procedure is not null begin

    begin try

      exec [host].[do_run_jobtask]
        @procedure=@procedure,
        @command='init',
        @instance=@instance,
        @args=@extra_args

    end try begin catch
      set @message = concat(error_message(),' (linha ',error_line(),')')
      raiserror ('Falha inicializando JOB. (procedure = %s) - Causa: %s',10,1,@procedure,@message) with nowait
      return
    end catch
      
    select @procedure = min([procedure]) from @tb_procedure where [procedure] > @procedure
  end

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
