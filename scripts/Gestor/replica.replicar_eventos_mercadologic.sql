--
-- PROCEDURE replica.replicar_eventos_mercadologic
--
drop procedure if exists replica.replicar_eventos_mercadologic
go
create procedure replica.replicar_eventos_mercadologic (
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

  declare @sql nvarchar(max)
  declare @ultimo_id_evento varchar(100)
  declare @maximo_ids_por_vez varchar(100) = 1000 -- Quantidade de registros importados por vez.
  declare @tb_evento table (
      id int primary key
    , esquema varchar(100)
    , tabela varchar(100)
    , chave int
    , acao varchar(100)
    , data datetime
    , versao int
    , origem varchar(100)
  )

  select @ultimo_id_evento = coalesce(max(id), 0)
    from replica.evento

  set @sql = '
    select *
      from openrowset(
           '''+@provider+'''
         , ''Driver='+@driver+';Server='+@servidor+';Port=5432;Database='+@database+';Uid='+@usuario+';Pwd='+@senha+';''
         , ''select evento.id
                  , esquema.texto as esquema
                  , tabela.texto as tabela
                  , evento.chave
                  , evento.acao
                  , evento.data
                  , evento.versao
                  , origem.texto as origem
               from replica.evento
              inner join replica.texto as esquema on esquema.id = evento.id_esquema
              inner join replica.texto as tabela  on tabela .id = evento.id_tabela
              inner join replica.texto as origem  on origem .id = evento.id_origem
              where evento.id between '+@ultimo_id_evento+' and '+@ultimo_id_evento+'+'+@maximo_ids_por_vez+'
              order by evento.id;''
           ) as t'
  insert into @tb_evento
    exec sp_executesql @sql

  ; with texto_remoto as (
    select esquema as texto from @tb_evento
    union select tabela from @tb_evento
    union select origem from @tb_evento
  )
  merge replica.texto
  using texto_remoto on texto_remoto.texto = replica.texto.texto
   when not matched by target then insert (texto) values (texto_remoto.texto);
  
  ; with evento_remoto as (
    select @cod_empresa as cod_empresa
         , evento.id
         , esquema.id as id_esquema
         , tabela.id as id_tabela
         , evento.chave
         , evento.acao
         , evento.data
         , evento.versao
         , origem.id as id_origem
      from @tb_evento as evento
     inner join replica.texto as esquema on esquema.texto = evento.esquema
     inner join replica.texto as tabela  on tabela .texto = evento.tabela
     inner join replica.texto as origem  on origem .texto = evento.origem
  )
  merge replica.evento
  using evento_remoto
     on evento_remoto.cod_empresa = replica.evento.cod_empresa
    and evento_remoto.id = replica.evento.id
   when not matched by target then
        insert (
            cod_empresa
          , id
          , id_esquema
          , id_tabela
          , chave
          , acao
          , data
          , versao
          , id_origem
          )
        values (
            evento_remoto.cod_empresa
          , evento_remoto.id
          , evento_remoto.id_esquema
          , evento_remoto.id_tabela
          , evento_remoto.chave
          , evento_remoto.acao
          , evento_remoto.data
          , evento_remoto.versao
          , evento_remoto.id_origem
        );

  raiserror(N'EVENTOS DO CONCENTRADOR REGISTRADOS NO GESTOR.',10,1) with nowait
end
go

exec replica.replicar_eventos_mercadologic 7
select top 10 * from replica.vw_evento order by 1 desc
-- delete from replica.evento
