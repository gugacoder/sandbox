drop procedure if exists host.schedule_job
go
create procedure host.schedule_job
    @name varchar(100)
  -- Um e apenas um destes três deve ser informado.
  , @procedure varchar(100) = null
  , @procid int = null
  -- Parâmetros do JOB
  , @description nvarchar(100) = null
  , @due_date datetime = null
  , @args host.parameter readonly
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
    raiserror ('O nome do JOB deve ser único. Use um template de nome criar uma diferenciação.',16,1) with nowait
    return
  end

  select @lot = min([lot]) from @definition
  while @lot is not null begin

    select @name = [name]
         , @description = [description]
      from @definition
     where [lot] = @lot

    merge into [host].[job] as target
    using (values (
        @name
      , @procedure
      , coalesce(@due_date, current_timestamp)
      , @description
    )) as source([name], [procedure], [due_date], [description])
       on source.[name] = target.[name]
      and source.[procedure] = target.[procedure]
    when matched then
      update set
        [due_date] = source.[due_date],
        [description] = source.[description]
    when not matched by target then
      insert ([name], [procedure], [due_date], [description])
      values (source.[name], source.[procedure], source.[due_date], source.[description])
    output inserted.[id] into @tb_job ([id]);

    select @job_id = max([id]) from @tb_job

    delete from [host].[job_parameter]
     where [job_id] = @job_id
    
    insert into [host].[job_parameter] ([job_id], [name], [value])
    select @job_id as [job_id], [name], [value]
      from @args
     where [lot] = @lot

    select @lot = min([lot]) from @definition where [lot] > @lot
  end

  -- Retornando os JOBs criados
  select [id] as [job_id] from @tb_job
end
go
