drop procedure if exists host.unschedule_job
go
create procedure host.unschedule_job
  -- Um e apenas um destes três deve ser informado.
    @procedure varchar(100) = null
  , @job_id int = null
  , @procid int = null
  -- Em caso de @procedure ou @procid múltiplos JOBs podem ser apagados.
  -- Para refinar a pesquisa pode-se indicar qualquer destes parâmetros abaixo.
  , @when_due_date_is datetime = null
  -- Suporta os curingas do comando LIKE
  , @when_description_is nvarchar(100) = null
as
begin
  declare @parameter_count_specified int

  select @parameter_count_specified = count(1)
    from (
      values (case when @procedure is null then 0 else 1 end)
           , (case when @procid    is null then 0 else 1 end)
           , (case when @job_id    is null then 0 else 1 end)
         ) as t([set])
   where [set] = 1
   
  if @parameter_count_specified != 1 begin
    raiserror (
      'Para identificação do JOB a ser removido é necessário indicar um e somente um dos parâmetros `@procedure`, `@procid` ou `@job_id`.',
      16,1)
    return 1
  end

  if @job_id is not null begin
    delete from [host].[job] where [id] = @job_id
    return
  end

  if @procid is not null begin
    set @procedure = concat(object_schema_name(@procid),'.',object_name(@procid))
  end

  delete from [host].[job]
   where [procedure] = @procedure
     and (@when_due_date_is is null or [due_date] = @when_due_date_is)
     and (@when_description_is is null or [description] like @when_description_is)
end
go
