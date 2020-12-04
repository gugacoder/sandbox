--
-- TABELA public.historico_venda_item
--
-- drop table if exists public.historico_venda_item;
create table if not exists public.historico_venda_item (
    id bigserial not null primary key
  , id_pdv int not null
  , id_sessao int not null
  , aplicativo text null

  , id_cupom int not null
  , id_item_cupom int not null
  , id_item int not null
  , id_unidade int not null

    -- I: INSERT
    -- D: DELETE
  , tp_operacao char not null
  , cod_operacao bigint not null
  , seq_operacao int not null
  , data_operacao timestamp not null default now()

  , data_cupom timestamp not null
  , frete_cupom numeric not null
  , desconto_cupom numeric not null
  , acrescimo_cupom numeric not null

  , cupom_cancelado boolean not null
  , item_cancelado boolean not null

  , preco_unitario numeric not null
  , custo_unitario numeric not null
  , desconto_unitario numeric not null
  , acrescimo_unitario numeric not null
  , quantidade numeric not null
  , total_sem_desconto numeric not null
  , total_desconto numeric not null
  , total_com_desconto numeric not null
);
