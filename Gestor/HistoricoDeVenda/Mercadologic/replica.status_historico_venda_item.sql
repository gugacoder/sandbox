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

