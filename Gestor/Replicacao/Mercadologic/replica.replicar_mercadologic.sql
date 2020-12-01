--
-- PROCEDURE replica.replicar_mercadologic
--
drop procedure if exists replica.replicar_mercadologic
go
create procedure replica.replicar_mercadologic (
    @cod_empresa int
  , @maximo_de_registros int = null
  -- Par�metros opcionais de conectividade.
  -- Se omitidos os par�metros s�o lidos da view replica.vw_empresa.
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
    -- min(*) � usado apenas para for�ar um registro nulo caso a empresa n�o exista.
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
       @cod_empresa=@cod_empresa
     , @provider=@provider
     , @driver=@driver
     , @servidor=@servidor
     , @porta=@porta
     , @database=@database
     , @usuario=@usuario
     , @senha=@senha

  exec replica.replicar_mercadologic_eventos
       @cod_empresa=@cod_empresa
     , @maximo_de_registros=@maximo_de_registros
     , @provider=@provider
     , @driver=@driver
     , @servidor=@servidor
     , @porta=@porta
     , @database=@database
     , @usuario=@usuario
     , @senha=@senha

  exec replica.replicar_mercadologic_tabelas_pendentes
       @cod_empresa=@cod_empresa
     , @maximo_de_registros=@maximo_de_registros
     , @provider=@provider
     , @driver=@driver
     , @servidor=@servidor
     , @porta=@porta
     , @database=@database
     , @usuario=@usuario
     , @senha=@senha

  raiserror(N'REPLICA��O DO CONCENTRADOR NO GESTOR CONCLU�DA.',10,1) with nowait
end
go

