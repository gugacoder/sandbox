drop procedure if exists [host].[do_unschedule_job]
go
create procedure [host].[do_unschedule_job]
  -- Identifica��o do JOB.
  -- Apenas um destes par�metros deve ser indicado.
    @procedure varchar(100) = null
  , @job_id int = null
  , @procid int = null
  -- Em caso de @procedure ou @procid m�ltiplos JOBs podem ser apagados.
  -- Para refinar a pesquisa pode-se indicar qualquer destes par�metros abaixo.
  , @name varchar(100) = null
  -- Par�metros com suporte ao comando LIKE
  , @when_name_is_like varchar(100) = null
  , @when_description_is_like nvarchar(100) = null
as
begin
  declare @parameter_count_specified int

  select @parameter_count_specified = count(1)
    from (
      values (case when @procedure   is null then 0 else 1 end)
           , (case when @procid      is null then 0 else 1 end)
           , (case when @job_id      is null then 0 else 1 end)
         ) as t([set])
   where [set] = 1
   
  if @parameter_count_specified != 1 begin
    raiserror (
      'Para identifica��o do JOB a ser removido � necess�rio indicar um e somente um dos par�metros `@procedure`, `@procid` ou `@job_id`.',
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

  begin try

    begin transaction tx

    delete from [host].[job]
     where [procedure] = @procedure
       and (@name is null or [name] = @name)
       and (@when_name_is_like is null or [name] like @when_name_is_like)
       and (@when_description_is_like is null or [description] like @when_description_is_like)

    commit transaction tx
  
  end try
  begin catch
    if @@trancount > 0
      rollback transaction tx
    
    declare @message nvarchar(max) = concat(error_message(),' (linha ',error_line(),')')
    declare @severity int = error_severity()
    declare @state int = error_state()
    raiserror (@message, @severity, @state);
  end catch
end
go
