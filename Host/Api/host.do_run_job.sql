drop procedure if exists [host].[do_run_job]
go
create procedure [host].[do_run_job]
  @job_history_id int,
  @instance uniqueidentifier,
  @extra_args [host].[tp_parameter] readonly
as
begin
  set nocount on

  declare @sql nvarchar(max)
  declare @job_id int
  declare @procedure varchar(100)
  declare @instance uniqueidentifier
  declare @declaration  nvarchar(max)
  declare @status int
  declare @fault nvarchar(max)
  declare @params [host].[tp_parameter]
  declare @message nvarchar(max)
  declare @severity int
  declare @state int

  select @job_id = [host].[job].[id]
       , @procedure = [host].[job].[procedure]
    from [host].[job]
   inner join [host].[job_history]
           on [host].[job_history].[job_id] = [host].[job].[id]
   where [host].[job_history].[id] = @job_history_id

  insert into @params ([name], [value])
  select [name], [value] from @extra_args

  insert into @params ([name], [value])
  select [name], [value]
    from [host].[job_parameter]
   where [job_id] = @job_id
     and [name] not in (select [name] from @params)

  --
  -- Registrando o início de execucao do JOB
  --
  begin try
    begin transaction tx
    
    update [host].[job_history]
       set [start_date] = current_timestamp
         , [instance] = @instance
     where [id] = @job_history_id

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

  --
  -- Executando o JOB
  --
  begin try
      
    exec host.do_run_jobtask
        @procedure=@procedure
      , @instance=@instance
      , @args=@params

    set @status = 1 -- bem sucedido
  end try
  begin catch
    set @status = -1 -- mal sucedido
    set @fault = concat(error_message(),' (linha ',error_line(),')')
  end catch

  --
  -- Registrando o status de execucao do JOB
  --
  begin try
    begin transaction tx
    
    update [host].[job_history]
       set [end_date] = current_timestamp
         , [status] = @status
         , [fault] = @fault
         , [stack_trace] = null
     where [id] = @job_history_id

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
end
go
