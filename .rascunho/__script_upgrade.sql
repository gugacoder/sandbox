use DBmercadologic


--
-- PROCEDURE replica.clonar_tabela_mercadologic
--
drop procedure if exists replica.clonar_tabela_mercadologic
go
create procedure replica.clonar_tabela_mercadologic (
    @cod_empresa int
  , @tabela_mercadologic varchar(100)
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

  declare @esquema varchar(100)
  declare @tabela varchar(100)
  declare @tabela_replica varchar(100)
  declare @view_replica varchar(100)
  declare @view_replica_director varchar(100)
  declare @sql nvarchar(max)
  declare @tb_campo table (
    nome varchar(100),
    tipo_pgsql varchar(100),
    tipo_mssql varchar(100),
    tamanho int,
    aceita_nulo bit,
    posicao int
  )

  if @tabela_mercadologic like '%.%' begin
    set @esquema = replica.SPLIT_PART(@tabela_mercadologic, '.', 1)
    set @tabela = replica.SPLIT_PART(@tabela_mercadologic, '.', 2)
  end else begin
    set @esquema = 'public'
    set @tabela = @tabela_mercadologic
  end

  --
  -- CONSTRUINDO A TABELA DE REPLICA SE NECESSARIO
  --
  exec replica.criar_cabecalho_tabela_mercadologic
    @tabela_mercadologic,
    @tabela_replica output,
    @view_replica output,
    @view_replica_director output

  --
  -- OBTENDO OS CAMPOS DA TABELA NO MERCADOLOGIC
  --
  set @sql = '
    select *
      from openrowset(
           '''+@provider+'''
         , ''Driver='+@driver+';Server='+@servidor+';Port=5432;Database='+@database+';Uid='+@usuario+';Pwd='+@senha+';''
         , ''select column_name
                  , data_type
                  , character_maximum_length
                  , case is_nullable when ''''YES'''' then true else false end is_nullable
                  , ordinal_position
               from information_schema.columns
              where table_schema = '''''+@esquema+'''''
                and table_name = '''''+@tabela+''''';''
           ) as t'

  insert into @tb_campo (nome, tipo_pgsql, tamanho, aceita_nulo, posicao)
    exec sp_executesql @sql

  ; with tipo as (
    select * from ( values 
      ('boolean', 'bit'),
      ('timestamp', 'datetime'),
      ('timestamp without time zone', 'datetime'),
      ('date', 'date'),
      ('time', 'time'),
      ('character varying', 'nvarchar'),
      ('varchar', 'nvarchar'),
      ('character', 'char'),
      ('char', 'char'),
      ('text', 'nvarchar'),
      ('money', 'decimal'),
      ('smallint', 'smallint'),
      ('integer', 'int'),
      ('bigint', 'bigint'),
      ('decimal', 'decimal(18,4)'),
      ('numeric', 'decimal(18,4)'),
      ('real', 'decimal(18,4)'),
      ('double precision', 'decimal(18,4)'),
      ('serial', 'int'),
      ('bigserial', 'bigint')
    ) as t(tipo_postgres, tipo_sqlserver)
  )
  update campo
     set tipo_mssql =
         case
           when campo.nome like 'xml[_]%'
             then 'xml'
           when tipo.tipo_sqlserver like '%varchar'
             then concat(tipo.tipo_sqlserver, '(max)') 
           when campo.tamanho is not null
             then concat(tipo.tipo_sqlserver, '(', campo.tamanho, ')') 
           else tipo.tipo_sqlserver
         end
    from @tb_campo as campo
   inner join tipo
           on tipo.tipo_postgres = campo.tipo_pgsql

  --
  -- ACRESCENTANDO OS CAMPOS DA TABELA DE REPLICA
  -- Com base nos campos obtidos da tabela no Mercadologic.
  --
  set @sql = ''
  select @sql = @sql + concat(
        'alter table ', @tabela_replica
      , ' add ', nome, ' ', tipo_mssql, ' null '
      , ';')
    from @tb_campo as campo
   where nome != 'cod_empresa'
     and not exists (
      select * from sys.columns
       where object_id = object_id(@tabela_replica)
         and name = campo.nome
   )
   order by posicao

  exec sp_executesql @sql
  raiserror(N'TABELA DE RÉPLICA CLONADA: %s',10,1,@tabela_replica) with nowait

  --
  -- ATUALIZANDO A ESTRUTURA DAS VIEWS
  --
  exec sp_refreshview @view_replica

  set @sql = concat('use DBdirector; exec sp_refreshview ''',@view_replica_director,'''')
  exec (@sql)

end
go



--
-- PROCEDURE replica.criar_cabecalho_tabela_mercadologic
--
drop procedure if exists replica.criar_cabecalho_tabela_mercadologic
go
create procedure replica.criar_cabecalho_tabela_mercadologic (
  @tabela_mercadologic varchar(100),
  @tabela_replica varchar(100) = null output,
  @view_replica varchar(100) = null output,
  @view_replica_director varchar(100) = null output
) as
begin
  declare @esquema varchar(100)
  declare @tabela varchar(100)
  declare @objeto varchar(100)
  declare @sql nvarchar(max)

  if @tabela_mercadologic like '%.%' begin
    set @esquema = replica.SPLIT_PART(@tabela_mercadologic, '.', 1)
    set @tabela = replica.SPLIT_PART(@tabela_mercadologic, '.', 2)
  end else begin
    set @esquema = 'public'
    set @tabela = @tabela_mercadologic
  end

  if @esquema = 'public' begin
    set @tabela_replica = concat('replica.',@tabela)
    set @view_replica = concat('replica.vw_',@tabela)
    set @view_replica_director = concat('mlogic.vw_replica_',@tabela)
  end else begin
    set @tabela_replica = concat('replica.',@esquema,'_',@tabela)
    set @view_replica = concat('replica.vw_',@esquema,'_',@tabela)
    set @view_replica_director = concat('mlogic.vw_replica_',@esquema,'_',@tabela)
  end

  --
  -- CONSTRUINDO A TABELA COM SEUS CAMPOS DE CABEÇALHO
  --
  if object_id(@tabela_replica) is null begin
    set @sql = concat(
      'create table ',@tabela_replica,' (
         id_replica bigint not null identity(1,1) primary key,
         excluido bit not null default (0),
         cod_empresa int not null
       )')
    exec sp_executesql @sql
    raiserror(N'TABELA DE RÉPLICA CRIADA: %s',10,1,@tabela_replica) with nowait
  end

  set @objeto = concat('IX__',replace(@tabela_replica,'.','_'),'__excluido') 
  if not exists (select 1 from sys.indexes where name = @objeto) begin
    set @sql = concat('create index ',@objeto,' on ',@tabela_replica,' (excluido)')
    exec sp_executesql @sql
    raiserror(N'ÍNDICE CRIADO: %s',10,1,@objeto) with nowait
  end

  set @objeto = concat('IX__',replace(@tabela_replica,'.','_'),'__cod_empresa') 
  if not exists (select 1 from sys.indexes where name = @objeto) begin
    set @sql = concat('create index ',@objeto,' on ',@tabela_replica,' (cod_empresa)')
    exec sp_executesql @sql
    raiserror(N'ÍNDICE CRIADO: %s',10,1,@objeto) with nowait
  end

  --
  -- CADASTRANDO UMA VIEW PARA EXIBIR APENAS OS CAMPOS NAO-EXCLUIDOS
  --
  if object_id(@view_replica) is null begin
    set @sql = concat('
      create view ',@view_replica,' as select * from ',@tabela_replica,' where excluido = 0')
    exec sp_executesql @sql
    raiserror(N'VIEW DE RÉPLICA CRIADA: %s',10,1,@view_replica) with nowait
  end

  --
  -- CADASTRANDO UMA VIEW NA BASE DO DIRECTOR
  --
  set @objeto = concat('DBdirector.',@view_replica_director)
  if object_id(@objeto) is null begin
    set @sql = concat('
      use DBdirector;
      exec (''
        create view ',@view_replica_director,'
        as select * from DBmercadologic.',@tabela_replica,' where excluido = 0
      '')')
    exec sp_executesql @sql
    raiserror(N'VIEW DE RÉPLICA CRIADA NO DBDIRECTOR: %s',10,1,@view_replica_director) with nowait
  end
  
end
go



exec sp_rename 'replica.historico_venda_item.id_replicacao', 'id_replica', 'COLUMN'




--
-- TABELA replica.historico_venda_item
--
-- De uma forma geral não é necessário construir as tabelas de réplica
-- via script porque elas são construídas dinamicamente pela procedure
-- `replica.clonar_tabela_mercadologic`.
-- 
-- Porém, em contextos como o da tabela `replica.historico_venda_item` é
-- importante tê-las construídas previamente para permitir a ligação
-- de chaves estrangeiras em tabelas terceiras.
-- 
if object_id('replica.historico_venda_item') is null begin
  create table replica.historico_venda_item (
      id_replica bigint not null identity(1,1) primary key
    , excluido bit not null default (0)
    , cod_empresa int not null

    , id bigint null
    , id_pdv int null
    , id_sessao int null
    , aplicativo varchar(max) null

    , id_cupom int null
    , id_item_cupom int null
    , id_item int null
    , id_unidade int null

      -- I: INSERT
      -- D: DELETE
    , tp_operacao char null
    , cod_operacao bigint null
    , seq_operacao int null
    , data_operacao datetime null

    , data_cupom datetime null
    , frete_cupom decimal(18,4) null
    , desconto_cupom decimal(18,4) null
    , acrescimo_cupom decimal(18,4) null

    , cupom_cancelado bit null
    , item_cancelado bit null

    , preco_unitario decimal(18,4) null
    , custo_unitario decimal(18,4) null
    , desconto_unitario decimal(18,4) null
    , acrescimo_unitario decimal(18,4) null
    , quantidade decimal(18,4) null
    , total_sem_desconto decimal(18,4) null
    , total_desconto decimal(18,4) null
    , total_com_desconto decimal(18,4) null
  )
end

if not exists (select 1 from sys.indexes where name = 'IX__replica_historico_venda_item__excluido') begin
  create index IX__replica_historico_venda_item__excluido on replica.historico_venda_item (excluido)
end

if not exists (select 1 from sys.indexes where name = 'IX__replica_historico_venda_item__cod_empresa') begin
  create index IX__replica_historico_venda_item__cod_empresa on replica.historico_venda_item (cod_empresa)
end

if not exists (select 1 from sys.indexes where name = 'IX__replica_historico_venda_item__id_pdv') begin
  create index IX__replica_historico_venda_item__id_pdv on replica.historico_venda_item (id_pdv)
end

if not exists (select 1 from sys.indexes where name = 'IX__replica_historico_venda_item__id_item') begin
  create index IX__replica_historico_venda_item__id_item on replica.historico_venda_item (id_item)
end

if not exists (select 1 from sys.indexes where name = 'IX__replica_historico_venda_item__id_unidade') begin
  create index IX__replica_historico_venda_item__id_unidade on replica.historico_venda_item (id_unidade)
end

if not exists (select 1 from sys.indexes where name = 'IX__replica_historico_venda_item__data_operacao') begin
  create index IX__replica_historico_venda_item__data_operacao on replica.historico_venda_item (data_operacao)
end

if not exists (select 1 from sys.indexes where name = 'IX__replica_historico_venda_item__data_cupom') begin
  create index IX__replica_historico_venda_item__data_cupom on replica.historico_venda_item (data_cupom)
end

if not exists (select 1 from sys.indexes where name = 'IX__replica_historico_venda_item__cupom_cancelado') begin
  create index IX__replica_historico_venda_item__cupom_cancelado on replica.historico_venda_item (cupom_cancelado)
end

if not exists (select 1 from sys.indexes where name = 'IX__replica_historico_venda_item__item_cancelado') begin
  create index IX__replica_historico_venda_item__item_cancelado on replica.historico_venda_item (item_cancelado)
end




--
-- TABELA replica.status_historico_venda_item
--
-- drop table if exists replica.status_historico_venda_item
if object_id('replica.status_historico_venda_item') is null begin
  create table replica.status_historico_venda_item (
    id_replica bigint not null
      constraint FK__replica__status_historico_venda_item__id_replica
         foreign key
      references replica.historico_venda_item (id_replica),
    -- E: Estoque atualizado
    -- F: Financeiro atualizado
    tipo_status char not null,
    data_status datetime not null default current_timestamp,
    constraint PK__replica__status_historico_venda_item
       primary key nonclustered (id_replica, tipo_status)
  );
end




exec sp_refreshview 'replica.vw_historico_venda_item'




use DBdirector



--
-- TABELA mlogic.vw_status_historico_venda_item
--
exec ('
  use DBdirector;
  if object_id(''mlogic.vw_status_historico_venda_item'') is null begin
    exec(''
      create view mlogic.vw_status_historico_venda_item
      as select * from DBmercadologic.replica.status_historico_venda_item
    '')
  end
')


exec sp_refreshview 'mlogic.vw_replica_historico_venda_item'

select top 10 * from mlogic.vw_replica_historico_venda_item
select top 10 * from mlogic.vw_status_historico_venda_item

