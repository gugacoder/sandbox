--
-- PROCEDURE replicar_mercadologic_tabelas_pendentes
--
drop procedure if exists replica.replicar_mercadologic_tabelas_pendentes
go
create procedure replica.replicar_mercadologic_tabelas_pendentes (
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

  declare @id_evento int
  declare @tabela varchar(100)
  declare @chave_tabela int
  
  select @id_evento = min(id_evento)
    from replica.evento with (nolock)
   where cod_empresa = @cod_empresa
     and status = 0

  while @id_evento is not null begin
  
    select @tabela = concat(esquema.texto,'.',tabela.texto)
         , @chave_tabela = evento.chave
      from replica.evento
     inner join replica.texto esquema on esquema.id = evento.id_esquema
     inner join replica.texto tabela on tabela.id = evento.id_tabela
     where evento.id_evento = @id_evento

    exec replica.replicar_mercadologic_tabela
         @id_evento
       , @provider
       , @driver
       , @servidor
       , @porta
       , @database
       , @usuario
       , @senha

    select @id_evento = min(id_evento)
      from replica.evento with (nolock)
     where cod_empresa = @cod_empresa
       and status = 0
       and id_evento > @id_evento
  end

  return 1 -- sucesso
end
go







