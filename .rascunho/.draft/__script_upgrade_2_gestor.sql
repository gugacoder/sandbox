drop table if exists replica.status_historico_venda_item;
drop table if exists replica.historico_venda_item;



--
-- TABELA replica.historico_venda_item
--
if object_id('replica.historico_venda_item') is null begin
  create table replica.historico_venda_item (
      id_replica bigint not null identity(1,1) primary key
    , excluido bit not null default (0)
    , cod_empresa int not null

    , id bigint not null

      --I: INSERT
      --D: DELETE
    , tp_operacao char not null
    , cod_operacao bigint not null
    , seq_operacao int not null
    , data_operacao datetime not null

    , id_pdv int not null
    , id_caixa int not null
    , id_sessao int not null
    , aplicativo varchar(100) null
    , data_movimento date not null

    , id_cupom int not null
    , numero_cupom int not null
    , serie_cupom int not null
    , data_cupom datetime not null

    , id_item_cupom int not null
    , id_item int not null
    , id_unidade int not null
    , indice_item_cupom int not null

    , cupom_cancelado bit not null
    , item_cancelado bit not null

    , frete_cupom decimal(18,2) not null
    , desconto_cupom decimal(18,2) not null
    , acrescimo_cupom decimal(18,2) not null

    , preco_unitario decimal(18,2) not null
    , custo_unitario decimal(18,2) not null
    , desconto_unitario decimal(18,2) not null
    , acrescimo_unitario decimal(18,2) not null

    , quantidade decimal(18,2) not null
    , total_bruto decimal(18,2) not null
    , total_liquido decimal(18,2) not null

    , valor_desconto decimal(18,2) not null
    , valor_acrescimo decimal(18,2) not null
    , valor_icms decimal(18,2) not null
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

if not exists (select 1 from sys.indexes where name = 'IX__replica_historico_venda_item__data_movimento') begin
  create index IX__replica_historico_venda_item__data_movimento on replica.historico_venda_item (data_movimento)
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

