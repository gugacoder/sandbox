--
-- PROCEDURE replica.replicar_mercadologic_registros_falhados
--
drop procedure if exists replica.replicar_mercadologic_registros_falhados
go
create procedure replica.replicar_mercadologic_registros_falhados (
    @cod_empresa int
  , @maximo_de_registros int = null
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
  -- 
  -- Se @maximo_de_registros é informado, a procedure processa esse número de registros e sai.
  -- Se @maximo_de_registros é omitido, a procedure processa todos os registros disponíveis
  -- nas tabelas, enquanto houverem registros pendentes.
  -- 
  declare @looping_unico bit = case when @maximo_de_registros is not null then 1 else 0 end
  declare @maximo_ids_por_vez int = coalesce(@maximo_de_registros, 1000)

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
  declare @contagem int
  declare @ultimo_id_evento int
  declare @tb_evento table (
      id int primary key
    , esquema varchar(100)
    , tabela varchar(100)
    , origem varchar(100)
    , cod_registro int
    , acao varchar(100)
    , data datetime
  )
  
  while 1=1 begin
    delete from @tb_evento

    select @ultimo_id_evento = coalesce(max(id_remoto), 0)
      from replica.evento with (nolock)
     where cod_empresa = @cod_empresa

    set @sql = concat('
      select *
        from openrowset(
             ''',@provider,'''
           , ''Driver=',@driver,';Server=',@servidor,';Port=5432;Database=',@database,';Uid=',@usuario,';Pwd=',@senha,';''
           , ''select evento.id
                    , esquema.texto as esquema
                    , tabela.texto as tabela
                    , origem.texto as origem
                    , evento.cod_registro
                    , evento.acao
                    , evento.data
                 from replica.evento
                inner join replica.texto as esquema on esquema.id = evento.id_esquema
                inner join replica.texto as tabela  on tabela .id = evento.id_tabela
                inner join replica.texto as origem  on origem .id = evento.id_origem
                where evento.id > ',@ultimo_id_evento,'
                order by evento.id
                limit ',@maximo_ids_por_vez,';''
             ) as t')
    insert into @tb_evento
      exec sp_executesql @sql

    if not exists (select 1 from @tb_evento)
      break;

    --
    -- INSERINDO TABELA E ESQUEMA NA TABELA DE TEXTO
    --
    ; with texto_remoto as (
      select esquema as texto from @tb_evento
      union select tabela from @tb_evento
      union select origem from @tb_evento
    )
    merge replica.texto
    using texto_remoto on texto_remoto.texto = replica.texto.texto
     when not matched by target then insert (texto) values (texto_remoto.texto);
    
    --
    -- CADASTRANDO O EVENTO
    --
    ; with evento_remoto as (
      select evento.id
           , esquema.id as id_esquema
           , tabela.id as id_tabela
           , origem.id as id_origem
           , @cod_empresa as cod_empresa
           , evento.cod_registro
           , evento.acao
           , evento.data
        from @tb_evento as evento
       inner join replica.texto as esquema on esquema.texto = evento.esquema
       inner join replica.texto as tabela  on tabela .texto = evento.tabela
       inner join replica.texto as origem  on origem .texto = evento.origem
    )
    merge replica.evento
    using evento_remoto
       on evento_remoto.cod_empresa = replica.evento.cod_empresa
      and evento_remoto.id = replica.evento.id_remoto
     when not matched by target then
          insert (
              id_remoto
            , id_esquema
            , id_tabela
            , id_origem
            , cod_empresa
            , cod_registro
            , acao
            , data
            )
          values (
              evento_remoto.id
            , evento_remoto.id_esquema
            , evento_remoto.id_tabela
            , evento_remoto.id_origem
            , evento_remoto.cod_empresa
            , evento_remoto.cod_registro
            , evento_remoto.acao
            , evento_remoto.data
          );

    set @contagem = @@rowcount

    if @contagem = 0 begin
      break;
    end else if @contagem = 1 begin
      raiserror(N'1 EVENTO DO CONCENTRADOR REGISTRADO NO GESTOR.',10,1) with nowait
    end else begin
      raiserror(N'%d EVENTOS DO CONCENTRADOR REGISTRADOS NO GESTOR.',10,1,@contagem) with nowait
    end

    if @looping_unico = 1
      break

    waitfor delay '00:00:01';
  end
end
go
