drop procedure if exists [host].[do_compute_next_run]
go
create procedure [host].[do_compute_next_run]
  @job_id int
as
begin
  set nocount on

  declare @procedure varchar(100)
  declare @disabled_at datetime
  declare @message nvarchar(max)
  declare @severity int
  declare @state int
  declare @current_due_date nvarchar(100)

  select @procedure = [procedure]
       , @disabled_at = [disabled_at]
    from [host].[job] with (nolock)
   where [id] = @job_id

  if @disabled_at is not null begin
    raiserror ('A data da próxima execução do JOB não pôde ser computada porque o JOB está desativado. (job_id = %d)',10,1,@job_id) with nowait
    return
  end
  
  if not exists (
    select 1 from [host].[vw_jobtask] with (nolock)
     where [procedure] = @procedure and [valid] = 1)
  begin
    begin try
      begin transaction tx
      update [host].[job]
         set [disabled_at] = current_timestamp
       where [id] = @job_id
      raiserror ('O JOB foi desativado porque a procedure não existe mais ou deixou de ser válida. (job_id = %d)',10,1,@job_id) with nowait
      commit transaction tx
    end try begin catch
      if @@trancount > 0 rollback transaction tx
      set @message = concat(error_message(),' (linha ',error_line(),')')
      set @severity = error_severity()
      set @state = error_state()
      raiserror (@message, @severity, @state);
    end catch
    return
  end
  
  select @current_due_date = convert(nvarchar(100),[due_date],120)
    from [host].[job_history] with (nolock)
   where [job_id] = @job_id and [status] in (0 /* agendado */, 1 /* executando */)

  if @current_due_date is not null begin
    raiserror ('Nada a ser feito. O JOB já está agendado. (job_id = %d, due_date = %s)',10,1,@job_id,@current_due_date) with nowait
    return
  end

  --
  -- Obtendo parâmetros
  --
  declare
      @due_date datetime
    , @days int
    , @time time
    , @repeat bit
    , @delayed bit
    , @start_date datetime
    , @end_date datetime

  select @due_date = [due_date]
       , @days = [days]
       , @time = [time]
       , @repeat = [repeat]
       , @delayed = [delayed]
       , @start_date = [start_date]
       , @end_date = [end_date]
   from [host].[job] with (nolock)
  where [id] = @job_id

  --
  -- Reagindo à data de expiração do JOB
  --
  if @end_date is not null and @end_date < current_timestamp begin
    begin try
      begin transaction tx
      update [host].[job]
         set [disabled_at] = current_timestamp
       where [id] = @job_id
      raiserror ('O JOB foi desativado porque está expirado. (job_id = %d, end_date > current_timestamp)',10,1,@job_id) with nowait
      commit transaction tx
    end try begin catch
      if @@trancount > 0 rollback transaction tx
      set @message = concat(error_message(),' (linha ',error_line(),')')
      set @severity = error_severity()
      set @state = error_state()
      raiserror (@message, @severity, @state);
    end catch

    return
  end

  --
  -- Computando a próxima data de execução do JOB
  --
  if @due_date is null begin
    
    if @days = 0 begin
      begin try
        begin transaction tx
        update [host].[job]
           set [disabled_at] = current_timestamp
         where [id] = @job_id
        raiserror ('O JOB foi desativado porque os parâmetros de agendamento são inválidos. (job_id = %d, days = 0)',10,1,@job_id) with nowait
        commit transaction tx
      end try begin catch
        if @@trancount > 0 rollback transaction tx
        set @message = concat(error_message(),' (linha ',error_line(),')')
        set @severity = error_severity()
        set @state = error_state()
        raiserror (@message, @severity, @state);
      end catch

      return
    end
    
    -- Construindo uma tabela com as datas futuras dos dias da semana cadastrados no JOB
    declare @date_table table (
      [day] int,
      [weekday] as datepart(dw, dateadd(d,[day],cast(current_timestamp as date))),
      [weight] as power(2,(datepart(dw, dateadd(d,[day],cast(current_timestamp as date)))-1)),
      [date] as dateadd(d,[day],cast(current_timestamp as date))
    )
    insert into @date_table ([day]) values (0),(1),(2),(3),(4),(5),(6),(7)
    delete from @date_table where [weight] & @days = 0

    if @delayed = 1 begin

      -- Próxima data depois da última execução acrescida do atraso
      select @due_date = coalesce(max([end_date]) + cast(@time as datetime), current_timestamp)
        from [host].[job_history]
       where [job_id] = @job_id

    end if @repeat = 1 begin

      -- Próxima execução periódica a partr da data de início
      set @start_date = coalesce(@start_date, cast(current_timestamp as date))

      ; with [times] as (
        select @start_date as [time]
        union all
        select [time] + cast(@time as datetime) from [times] -- calculando hora recursivamente
      )
      select top 1 @due_date = [times].[time]
        from [times]
       where [times].[time] >= current_timestamp
         and exists (
              select 1 from @date_table as [date_table]
               where [date] = cast([times].[time] as date)
         )
      option (maxrecursion 0)

    end else begin

      -- Próxima data na hora marcada
      select @due_date = min([date])
        from (select cast([date] as datetime) + cast(@time as datetime) from @date_table) as t([date])
       where [date] >= current_timestamp

    
    end
  end

  begin try
    begin transaction tx
    
    insert into [host].[job_history] ([job_id], [due_date])
    values (@job_id, @due_date)
    
    set @message = concat('JOB ',@job_id,' agendado para ',convert(nvarchar(100),@due_date,120))
    raiserror (@message,10,1) with nowait
    
    commit transaction tx
  end try begin catch
    if @@trancount > 0 rollback transaction tx
    set @message = concat(error_message(),' (linha ',error_line(),')')
    set @severity = error_severity()
    set @state = error_state()
    raiserror (@message, @severity, @state);
  end catch

end
go
