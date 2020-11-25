--
-- PROCEDURE replica.executar_sql_remota
--
drop procedure if exists replica.executar_sql_remota
go
create procedure replica.executar_sql_remota (
    @cod_empresa int
  , @sql nvarchar(max)
  -- Parâmetros opcionais de conectividade.
  -- Se omitidos os parâmetros são lidos da view replica.vw_empresa.
  , @provider nvarchar(50) = null
  , @driver nvarchar(50) = null
  , @servidor nvarchar(30) = null
  , @porta nvarchar(10) = null
  , @database nvarchar(50) = null
  , @usuario nvarchar(50) = null
  , @senha nvarchar(50) = null
) as
begin
  declare @status int

  if @provider is null
  or @driver   is null
  or @servidor is null
  or @porta    is null
  or @database is null
  or @usuario  is null
  or @senha    is null
  begin
    -- min(*) é usado apenas para forçar um registro nulo caso a empresa não exista.
    select @provider = coalesce(@provider, min(DFprovider), 'MSDASQL')
         , @driver   = coalesce(@driver  , min(DFdriver)  , '{PostgreSQL 64-Bit ODBC Drivers}')
         , @servidor = coalesce(@servidor, min(DFservidor))
         , @porta    = coalesce(@porta   , min(DFporta)   , '5432')
         , @database = coalesce(@database, min(DFdatabase), 'DBMercadologic')
         , @usuario  = coalesce(@usuario , min(DFusuario) , 'postgres')
         , @senha    = coalesce(@senha   , min(DFsenha)   , 'local')
      from replica.vw_empresa
     where DFcod_empresa = @cod_empresa
  end

  set @sql = concat(
   'select *
      from openrowset(
           ''',@provider,'''
         , ''Driver=',@driver,';Server=',@servidor,';Port=5432;Database=',@database,';Uid=',@usuario,';Pwd=',@senha,';''
         , ''select * from (',@sql,') as t''
           ) as t')

  exec @status = sp_executesql @sql
  
  return @status
end
go
