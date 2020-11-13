drop procedure if exists host.schedule_job
go
create procedure host.schedule_job
  -- Um e apenas um destes três deve ser informado.
    @procedure varchar(100) = null
  , @procid int = null
  -- Parâmetros do JOB
  , @description nvarchar(100) = null
  , @due_date datetime = null
  , @args host.parameter readonly
  , @job_id int = null output
  -- Versao dos parametros em pt-BR para compatibilidade
  , @id_job int = null output
as
begin
  declare @tb_job table ([id] int)

  if @procid is not null begin
    set @procedure = concat(object_schema_name(@procid),'.',object_name(@procid))
  end

  insert into [host].[job] (
      [procedure]
    , [due_date]
    , [description]
  )
  output inserted.[id] into @tb_job ([id])
  values (
      @procedure
    , coalesce(@due_date, current_timestamp)
    , @description
  )

  select @job_id = [id] from @tb_job
  set @id_job = @job_id
  
  insert into [host].[job_parameter] (job_id, [name], [value])
  select @job_id, [name], [value]
    from @args
end
go
