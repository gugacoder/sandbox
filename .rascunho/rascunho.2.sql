declare
    @cod_empresa int = 8
  , @provider nvarchar(50) = null
  , @driver nvarchar(50) = null
  , @servidor nvarchar(30) = null
  , @porta nvarchar(10) = null
  , @database nvarchar(50) = null
  , @usuario nvarchar(50) = null
  , @senha nvarchar(50) = null

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

  exec replica.clonar_tabelas_monitoradas_mercadologic
       @cod_empresa
     , @provider
     , @driver
     , @servidor
     , @porta
     , @database
     , @usuario
     , @senha

  exec replica.replicar_mercadologic_eventos
       @cod_empresa
     , @provider
     , @driver
     , @servidor
     , @porta
     , @database
     , @usuario
     , @senha

  exec replica.replicar_mercadologic_tabelas_pendentes
       @cod_empresa
     , @provider
     , @driver
     , @servidor
     , @porta
     , @database
     , @usuario
     , @senha

  raiserror(N'REPLICAÇÃO DO CONCENTRADOR NO GESTOR CONCLUÍDA.',10,1) with nowait
end
go
