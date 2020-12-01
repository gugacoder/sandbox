--
-- PROCEDURE replica.clonar_tabelas_monitoradas_mercadologic
--
drop procedure if exists replica.clonar_tabelas_monitoradas_mercadologic
go
create procedure replica.clonar_tabelas_monitoradas_mercadologic (
    @cod_empresa int
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
  if @provider is null
  or @driver   is null
  or @servidor is null
  or @porta    is null
  or @database is null
  or @usuario  is null
  or @senha    is null
  begin
    -- min() é usado apenas para forçar um registro nulo caso a empresa não exista.
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

  declare @sql nvarchar(max)
  declare @tb_tabela table (
      id int primary key identity(1,1)
    , esquema varchar(100)
    , tabela varchar(100)
  )

  set @sql = '
    select esquema, tabela
      from openrowset(
           '''+@provider+'''
         , ''Driver='+@driver+';Server='+@servidor+';Port=5432;Database='+@database+';Uid='+@usuario+';Pwd='+@senha+';''
         , ''select esquema, tabela from replica.vw_tabela_monitorada;''
           ) as t'

  insert into @tb_tabela (esquema, tabela)
    exec sp_executesql @sql
  
  declare @id int, @tabela varchar(100)

  select @id = min(id) from @tb_tabela
  while @id is not null begin
    select @tabela = concat(esquema,'.',tabela) from @tb_tabela where id = @id

    exec replica.clonar_tabela_mercadologic 
        @cod_empresa
      , @tabela
      , @provider
      , @driver
      , @servidor
      , @porta
      , @database
      , @usuario
      , @senha

    select @id = min(id) from @tb_tabela where id > @id
  end
end
go

