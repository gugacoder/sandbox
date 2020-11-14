drop procedure if exists [host].[do_schedule_job]
go
create procedure [host].[do_schedule_job]
    @name varchar(100)
  -- Um e apenas um destes tr�s deve ser informado.
  , @procedure varchar(100) = null
  , @procid int = null
  -- Par�metros do JOB
  , @description nvarchar(100) = null
  -- Data para uma �nica execu��o do JOB.
  -- Quando indicada os demais parametros de agendamento seguintes
  -- n�o devem ser indicados.
  , @due_time datetime = null
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
    -- Quando sequencial o intervalo de repeticao � contado somente
    -- depois da execu��o anterior ter terminado.
  , @sequential bit = null
  , @start_date datetime = null
  , @end_date datetime = null
  , @args [host].[tp_parameter] readonly
as
begin
  set nocount on

  declare @job_id int
  declare @lot int
  declare @name_template nvarchar(100) = coalesce(@name,'job')
  declare @description_template nvarchar(400) = @description
  declare @tb_job table ([id] int)

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
    raiserror ('O nome do JOB deve ser �nico. Use um template de nome criar uma diferencia��o.',16,1) with nowait
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
      begin transaction x

      merge into [host].[job] as target
      using (values (
          @name
        , @procedure
        , @description
        , @days
        , @time
        , @repeat
        , @sequential
        , @start_date
        , @end_date
      )) as source(
              [name]
            , [procedure]
            , [description]
            , [days]
            , [time]
            , [repeat]
            , [sequential]
            , [start_date]
            , [end_date]
          )
         on source.[name] = target.[name]
        and source.[procedure] = target.[procedure]
      when matched then
        update set
            [description] = source.[description]
          , [days] = source.[days]
          , [time] = source.[time]
          , [repeat] = source.[repeat]
          , [sequential] = source.[sequential]
          , [start_date] = source.[start_date]
          , [end_date] = source.[end_date]
      when not matched by target then
        insert (
            [name]
          , [procedure]
          , [description]
          , [days]
          , [time]
          , [repeat]
          , [sequential]
          , [start_date]
          , [end_date]
          )
        values (
            source.[name]
          , source.[procedure]
          , source.[description]
          , source.[days]
          , source.[time]
          , source.[repeat]
          , source.[sequential]
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

  -- Retornando os JOBs criados
  select [id] as [job_id] from @tb_job
end
go
