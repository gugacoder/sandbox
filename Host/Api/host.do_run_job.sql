drop procedure if exists [host].[do_run_job]
go
create procedure [host].[do_run_job]
  @job_history_id int,
  @instance uniqueidentifier,
  @extra_args [host].[tp_parameter] readonly
as
begin
  set nocount on

  declare @job_id int
  declare @procedure varchar(100)
  declare @locked bit
  declare @locked_instance nvarchar(400)
  declare @one_shot bit
  declare @sql nvarchar(max)
  declare @declaration  nvarchar(max)
  declare @status int
  declare @fault nvarchar(max)
  declare @params [host].[tp_parameter]
  declare @message nvarchar(max)
  declare @severity int
  declare @state int

  select @job_id = [host].[job].[id]
       , @procedure = [host].[job].[procedure]
       , @one_shot = case when [host].[job].[due_date] is not null then 1 else 0 end
    from [host].[job] with (nolock)
   inner join [host].[job_history] with (nolock)
           on [host].[job_history].[job_id] = [host].[job].[id]
   where [host].[job_history].[id] = @job_history_id

  if @procedure is null begin
    raiserror ('O histórico de JOB não existe. (job_history_id = %d)',16,1,@job_history_id) with nowait
    return
  end

  --
  -- Registrando o início de execucao do JOB
  --
  begin try
    begin transaction tx
    
    update [host].[job_history]
       set [start_date] = current_timestamp
         , [instance] = @instance
     where [id] = @job_history_id
       and [instance] is null
       and [status] = 0

    -- Somente uma instância pode capturar o JOB para execucao
    -- Se a SQL acima conseguir associar o JOB à instância consideramos o JOB
    -- travado para esta instância.
    set @locked = @@rowcount

    commit transaction tx
  end try
  begin catch
    if @@trancount > 0
      rollback transaction tx
    
    set @message = concat(error_message(),' (linha ',error_line(),')')
    set @severity = error_severity()
    set @state = error_state()
    raiserror (@message, @severity, @state);
    return
  end catch

  -- Somente uma instância pode capturar o JOB para execucao
  if @locked = 0 begin
    select @locked_instance = cast([instance] as nvarchar(400))
      from [host].[job_history] with (nolock)
     where [id] = @job_history_id
    raiserror (
      'O JOB já foi executado ou está em execução por outra instância. (job_id = %d, job_history_id = %d, locked_instance = {%s})',
      16,1,@job_id,@job_history_id,@locked_instance) with nowait
    return
  end

  --
  -- Preparando parâmetros do JOB
  --

  insert into @params ([name], [value])
  select [name], [value] from @extra_args

  insert into @params ([name], [value])
  select [name], [value]
    from [host].[job_parameter] with (nolock)
   where [job_id] = @job_id
     and [name] not in (select [name] from @params)

  --
  -- Executando o JOB
  --
  begin try
      
    exec host.do_run_jobtask
        @procedure=@procedure
      , @instance=@instance
      , @args=@params

  end try
  begin catch
    set @fault = concat(error_message(),' (linha ',error_line(),')')
  end catch

  --
  -- Registrando o status de execucao do JOB
  --
  begin try
    begin transaction tx
    
    update [host].[job_history]
       set [end_date] = current_timestamp
         , [fault] = @fault
         , [stack_trace] = null
     where [id] = @job_history_id

    if @one_shot = 1 begin
      update [host].[job]
         set [disabled_at] = current_timestamp
       where [id] = @job_id
    end

    commit transaction tx
    raiserror ('JOB executado. (job_id = %d, job_history_id = %d)',10,1,@job_id,@job_history_id) with nowait
  end try
  begin catch
    if @@trancount > 0
      rollback transaction tx
      
    set @message = concat(error_message(),' (linha ',error_line(),')')
    set @severity = error_severity()
    set @state = error_state()
    raiserror (@message, @severity, @state) with nowait
    return
  end catch

  --
  -- Calculando a data da próxima execução do JOB
  --
  exec [host].[do_compute_next_run] @job_id

end
go
