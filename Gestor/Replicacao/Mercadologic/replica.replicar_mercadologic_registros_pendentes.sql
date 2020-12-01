--
-- PROCEDURE replicar_mercadologic_registros_pendentes
--
drop procedure if exists replica.replicar_mercadologic_registros_pendentes
go
create procedure replica.replicar_mercadologic_registros_pendentes (
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

  -- Colecao de dados processados
  declare @tb_registro replica.tp_id
  declare @tb_evento table (
    id_evento int,
    tabela varchar(100),
    cod_registro int
  )

  -- Controle do looping
  declare @ultimo_id_evento int
  declare @ultimo_id_evento_visto int
  declare @tabela varchar(100)

  while 1=1 begin

    -- Elencando os eventos que serão processados
    delete from @tb_evento
    insert into @tb_evento (id_evento, tabela, cod_registro)
    select top (@maximo_ids_por_vez)
           evento.id_evento,
           concat(esquema.texto,'.',tabela.texto),
           evento.cod_registro
      from replica.evento as evento with (nolock)
     inner join replica.texto as esquema with (nolock) on esquema.id = evento.id_esquema
     inner join replica.texto as tabela with (nolock)  on tabela .id = evento.id_tabela
     where evento.cod_empresa = @cod_empresa
       and status = 0
     order by evento.id_evento

    if not exists (select 1 from @tb_evento)
      break

    -- Validando o resultado do looping anterior.
    -- Se o looping anterior não produziu efeitos então temos ainda o mesmo conjunto de
    -- dados para processar. Para evitar ficarmos agarrados eternamente nestes dados
    -- vamos apenas desistir.
    set @ultimo_id_evento = (select max(id_evento) from @tb_evento)
    if @ultimo_id_evento = @ultimo_id_evento_visto begin
      -- A última interacao não replicou dados realmente
      raiserror ('A ÚLTIMA TENTATIVA DE REPLICAÇÃO NÃO FOI BEM SUCEDIDA',10,1)
      break
    end
    set @ultimo_id_evento_visto = @ultimo_id_evento

    set @tabela = (select min(tabela) from @tb_evento)
    while @tabela is not null begin
    
      delete from @tb_registro
      insert into @tb_registro (id)
      select distinct cod_registro
        from @tb_evento
       where tabela = @tabela

      begin try
        begin transaction tx

        exec replica.replicar_mercadologic_registros
             @cod_empresa=@cod_empresa
           , @tabela_mercadologic=@tabela
           , @tb_registro=@tb_registro
           -- Parâmetros opcionais de conectividade.
           -- Se omitidos os parâmetros são lidos da view replica.vw_empresa.
           , @provider=@provider
           , @driver=@driver
           , @servidor=@servidor
           , @porta=@porta
           , @database=@database
           , @usuario=@usuario
           , @senha=@senha

        merge replica.evento as evento
        using @tb_evento as tb_evento
           on tb_evento.id_evento = evento.id_evento
          and tb_evento.tabela = @tabela
         when matched then update
              set status = 1
                , falha = null
                , falha_detalhada = null;

        commit transaction tx
      end try
      begin catch
        if @@trancount > 0
          rollback transaction tx

        -- Todo o bloco de eventos será marcado como falhado e status -1.
        -- Uma revisão desse bloco será feito pela procedure
        -- "replica.replicar_mercadologic_registros_falhados" para determinar
        -- quais eventos realmente estão falhando, marcando estes registros como
        -- statis -2 e os registros bons como status 1.
        merge replica.evento as evento
        using @tb_evento as tb_evento
           on tb_evento.id_evento = evento.id_evento
          and tb_evento.tabela = @tabela
         when matched then update
              set status = -1
                , falha = concat(error_message(),' (linha ',error_line(),')')
                , falha_detalhada = null;

      end catch

      waitfor delay '00:00:01';
      set @tabela = (select min(tabela) from @tb_evento where tabela > @tabela)
    end

    if @looping_unico = 1
      break
  end
end
go

