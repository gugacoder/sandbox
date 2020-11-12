--
-- PROCEDURE host.executar_job
--
drop procedure if exists host.executar_job
go
create procedure host.executar_job
  @procedure varchar(100),
  @comando varchar(10) = 'exec',
  @instancia uniqueidentifier = null,
  @automatico bit = 0,
  @args host.args readonly
as
begin
  declare @sql nvarchar(max)
  declare @declaracao  nvarchar(max)
  declare @params host.args

  set @sql = 'exec ' + @procedure

  select @sql = @sql + ' ' + DFparametro + ','
    from host.vw_jobtask_parametro
   where DFprocedure = @procedure
   order by DFordem

  set @sql = left(@sql, len(@sql)-1)

  insert into @params (chave, valor) values ('@comando', @comando)
  insert into @params (chave, valor) values ('@instancia', @instancia)
  insert into @params (chave, valor) values ('@automatico', @automatico)
  
  insert into @params (chave, valor)
  select chave, valor
    from @args
   where chave not in (select chave from @params)

  select @declaracao = 
    isnull(@declaracao, '') +
      'declare ' + chave + ' ' + tipo + ' = (' +
        'select cast(valor as ' + tipo + ') from @params where chave = ''' + chave + '''); '
    from (
    select host.vw_jobtask_parametro.DFparametro as chave
         , params.valor
         , host.vw_jobtask_parametro.DFtipo as tipo
      from host.vw_jobtask_parametro
      left join @params as params
             on params.chave = host.vw_jobtask_parametro.DFparametro
     where host.vw_jobtask_parametro.DFprocedure = @procedure
  ) as params 

  set @sql = @declaracao + @sql
  print @sql

  exec sp_executesql
      @sql
    , N'@params host.args readonly'
    , @params
end
go
