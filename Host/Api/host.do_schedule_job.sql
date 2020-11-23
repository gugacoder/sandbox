drop procedure if exists [host].[do_schedule_job]
go
create procedure [host].[do_schedule_job]
    @name varchar(100) = null
  -- Um e apenas um destes três deve ser informado.
  , @procedure varchar(100) = null
  , @procid int = null
  -- Parâmetros do JOB
  , @description nvarchar(100) = null
  -- Data para uma única execução do JOB.
  -- Quando indicada os demais parametros de agendamento seguintes
  -- não devem ser indicados.
  , @due_date datetime = null
    -- seg=1
    -- ter=2
    -- qua=4
    -- qui=8
    -- sex=16
    -- sab=32
    -- dom=64
    -- weekdays=31
    -- weekends=96
  , @days int = null
  , @time time = null
    -- Trata a data como um intervalo de repeticao.
  , @repeat bit = null
    -- Quando sequencial o intervalo de repeticao é contado somente
    -- depois da execução anterior ter terminado.
  , @delayed bit = null
  , @start_date datetime = null
  , @end_date datetime = null
  , @args [host].[tp_parameter] readonly
  -- Opções de execução
    -- Desativa a emissão da lista de JOBs gerados no fim da procedure.
  , @no_output bit = 0
as
begin
  set nocount on

  declare @job_id int
  declare @lot int
  declare @name_template nvarchar(100)
  declare @description_template nvarchar(400)
  declare @tb_job table ([id] int)
  declare @id int

  set @name = coalesce(@name, 'default')
  set @name_template = @name
  set @description_template = @description

  if @due_date is not null begin
    if coalesce(@days,0) != 0
    or coalesce(@time,'00:00:00') != '00:00:00'
    or coalesce(@repeat,0) != 0
    or coalesce(@delayed,0) != 0
    or @start_date is not null
    or @end_date is not null
    begin
      raiserror ('Quando `@due_date` é indicado os demais parâmetros de agendamento não devem ser indicados: @days, @time, @repeat, @delayed, @start_date, @end_date',16,1) with nowait
      return
    end
  end else begin
    set @time = coalesce(@time,'00:00:00')
    set @repeat = coalesce(@repeat,0)
    set @delayed = coalesce(@delayed,0)

    if @time is null begin
      raiserror ('Pelo menos o parâmetro `@time` deve ser indicado.',16,1) with nowait
      return
    end
    if @repeat = 1 and @delayed = 0 and @time = '00:00:00' begin
      raiserror ('Quando `@repeat` é indicado mas `@delayed` não é indicado, então, é esperado que o intervalo `@time` seja diferente de `00:00:00`.',16,1) with nowait
      return
    end

    if @repeat = 0 and @delayed = 1 begin
      set @repeat = 1
    end
    if coalesce(@days,0) = 0 begin
      set @days = 127
    end
  end

  if @procid is not null begin
    set @procedure = concat(object_schema_name(@procid),'.',object_name(@procid))
  end

  declare @definition table (
    [lot] int,
    [name] varchar(100),
    [description] varchar(400)
  )

  insert into @definition ([lot]) select distinct [lot] from @args

  select @lot = min([lot]) from @definition
  while @lot is not null begin

    set @name = @name_template
    set @description = @description_template

    select @name = replace(@name, '{'+[name]+'}', cast([value] as nvarchar(100)))
         , @description = replace(@description, '{'+[name]+'}', cast([value] as nvarchar(100)))
      from @args
     where [lot] = @lot

    update @definition
       set [name] = @name
         , [description] = @description
     where [lot] = @lot

    select @lot = min([lot]) from @definition where [lot] > @lot
  end

  if exists (select 1 from @definition group by [name] having count(1) > 1) begin
    raiserror ('O nome do JOB deve ser único. Use um template de nome criar uma diferenciação.',16,1) with nowait
    return
  end

  if not exists (select 1 from @definition) begin
    insert into @definition ([lot], [name], [description])
    values (1, @name, @description)
  end

  select @lot = min([lot]) from @definition
  while @lot is not null begin

    select @name = [name]
         , @description = [description]
      from @definition
     where [lot] = @lot

    begin try
      begin transaction tx

      merge into [host].[job] as target
      using (values (
          @name
        , @procedure
        , @description
        , @due_date
        , coalesce(@days,0)
        , coalesce(@time,'00:00:00')
        , coalesce(@repeat,0)
        , coalesce(@delayed,0)
        , @start_date
        , @end_date
      )) as source(
              [name]
            , [procedure]
            , [description]
            , [due_date]
            , [days]
            , [time]
            , [repeat]
            , [delayed]
            , [start_date]
            , [end_date]
          )
         on source.[name] = target.[name]
        and source.[procedure] = target.[procedure]
      when matched then
        update set
            [description] = source.[description]
          , [disabled_at] = null
          , [due_date] = source.[due_date]
          , [days] = source.[days]
          , [time] = source.[time]
          , [repeat] = source.[repeat]
          , [delayed] = source.[delayed]
          , [start_date] = source.[start_date]
          , [end_date] = source.[end_date]
      when not matched by target then
        insert (
            [name]
          , [procedure]
          , [description]
          , [due_date]
          , [days]
          , [time]
          , [repeat]
          , [delayed]
          , [start_date]
          , [end_date]
          )
        values (
            source.[name]
          , source.[procedure]
          , source.[description]
          , source.[due_date]
          , source.[days]
          , source.[time]
          , source.[repeat]
          , source.[delayed]
          , source.[start_date]
          , source.[end_date]
          )
      output inserted.[id] into @tb_job ([id]);

      select @job_id = max([id]) from @tb_job

      delete from [host].[job_parameter]
       where [job_id] = @job_id
      
      insert into [host].[job_parameter] ([job_id], [name], [value])
      select @job_id as [job_id], [name], [value]
        from @args
       where [lot] = @lot

      commit transaction tx
    end try
    begin catch
    select @@trancount
      if @@trancount > 0
        rollback transaction tx
      
      declare @message nvarchar(max) = concat(error_message(),' (linha ',error_line(),')')
      declare @severity int = error_severity()
      declare @state int = error_state()
      raiserror (@message, @severity, @state);
      return
    end catch

    select @lot = min([lot]) from @definition where [lot] > @lot
  end

  --
  -- Calculando a data da primeira execução dos JOBs
  --
  select @id = min([id]) from @tb_job
  while @id is not null begin
    begin try
      exec [host].[do_compute_next_run] @id
      select @id = min([id]) from @tb_job where [id] > @id
    end try begin catch
      set @message = concat(error_message(),' (linha ',error_line(),')')
      raiserror ('O JOB foi agendado mas a data de sua primeira execução não pôde ser computada. (job_id = %d) - Causa: %s',
        10,1,@job_id,@message) with nowait
    end catch
  end

  --
  -- Retornando os JOBs criados
  --
  if @no_output = 0 begin
    select [id] as [job_id] from @tb_job
  end
end
go
