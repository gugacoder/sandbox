drop procedure if exists [host].[run_job]
go
create procedure [host].[run_job]
  -- Identificação da procedure.
  -- Informe um ou o outro.
  -- Se forem informados ambos uma validação será feita para determinar
  -- se o nome da procedure é exatamente o mesmo cadastrado no JOB.
  @job_id int = null,
  @procedure varchar(100) = null,
  -- Parâmetros do JOB
  @command varchar(10) = null,
  @instance uniqueidentifier = null,
  @args host.parameter readonly
as
begin
  set nocount on

  declare @sql nvarchar(max)
  declare @declaration  nvarchar(max)
  declare @params host.parameter
  declare @job_procedure varchar(100)

  set @command = coalesce(@command, 'exec')
    
  if @procedure is null and @job_id is null begin
    raiserror ('Ou o ID do JOB ou o nome da procedure deve ser indicado.',16,1) with nowait
    return
  end

  if @job_id is not null begin
    select @job_procedure = [procedure] from [host].[job] where [id] = @job_id
    if @job_procedure is null begin
      raiserror ('O JOB não existe. (id: %d)',16,1,@job_id) with nowait
      return
    end
    if @procedure is not null and @procedure != @job_procedure begin
      raiserror ('O JOB existe mas não corresponde à procedure indicada. (id: %d, procedure do job: `%s`, procedure indicada: `%s`)',16,1,
        @job_id,@job_procedure,@procedure) with nowait
      return
    end
    set @procedure = coalesce(@procedure, @job_procedure)
  end

  set @sql = 'exec ' + @procedure

  select @sql = @sql + ' ' + [name] + ','
    from host.vw_jobtask_parameter
   where [procedure] = @procedure

  set @sql = left(@sql, len(@sql)-1)

  insert into @params ([name], [value]) values ('@command', @command)
  insert into @params ([name], [value]) values ('@instance', @instance)
  insert into @params ([name], [value]) values ('@job_id', @job_id)
  insert into @params ([name], [value]) select '@due_date', [due_date] from [host].[job] where [id] = @job_id
  -- versao de parametros em pt-BR
  insert into @params ([name], [value]) 
  select [pt].[name_pt], [params].[value]
    from @params as [params] inner join (values
      ('@command','@comando'),
      ('@instance','@instancia'),
      ('@job_id','@id_job'),
      ('@due_date','@data_execucao')
    ) as [pt]([name], [name_pt]) on [params].[name] = [pt].[name]

  insert into @params ([name], [value])
  select [name], [value]
    from @args
   where [name] not in (select [name] from @params)

  insert into @params ([name], [value])
  select [name], [value]
    from [host].[job_parameter]
   where [job_id] = @job_id
     and [name] not in (select [name] from @params)

  select @declaration = 
    isnull(@declaration, '') +
      'declare ' + [name] + ' ' + [type] + ' = (' +
        'select cast([value] as ' + [type] + ') from @params where [name] = ''' + [name] + '''); '
    from (
      select [host].[vw_jobtask_parameter].[name]
           , [host].[vw_jobtask_parameter].[type]
        from [host].[vw_jobtask_parameter]
        left join @params as [params]
               on [params].[name] = [host].[vw_jobtask_parameter].[name]
       where [host].[vw_jobtask_parameter].[procedure] = @procedure
    ) as t

  set @sql = @declaration + @sql

  exec sp_executesql
      @sql
    , N'@params [host].[parameter] readonly'
    , @params
end
go

