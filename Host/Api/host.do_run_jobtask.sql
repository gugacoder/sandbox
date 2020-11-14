drop procedure if exists [host].[do_run_jobtask]
go
create procedure [host].[do_run_jobtask]
  @procedure varchar(100) = null,
  @command varchar(10) = null,
  @instance uniqueidentifier = null,
  @args [host].[tp_parameter] readonly
as
begin
  set nocount on

  declare @sql nvarchar(max)
  declare @declaration  nvarchar(max)
  declare @params [host].[tp_parameter]

  set @command = coalesce(@command, 'exec')
    
  set @sql = 'exec ' + @procedure

  select @sql = @sql + ' ' + [name] + ','
    from host.vw_jobtask_parameter
   where [procedure] = @procedure

  set @sql = left(@sql, len(@sql)-1)

  insert into @params ([name], [value]) values ('@command', @command)
  insert into @params ([name], [value]) values ('@instance', @instance)
  -- versao de parametros em pt-BR
  insert into @params ([name], [value]) 
  select [pt].[name_pt], [params].[value]
    from @params as [params] inner join (values
      ('@command','@comando'),
      ('@instance','@instancia')
    ) as [pt]([name], [name_pt]) on [params].[name] = [pt].[name]

  insert into @params ([name], [value])
  select [name], [value] from @args
   where [name] not in (select [name] from @params)
  
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

