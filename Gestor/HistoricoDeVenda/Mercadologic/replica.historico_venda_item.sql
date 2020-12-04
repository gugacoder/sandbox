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
