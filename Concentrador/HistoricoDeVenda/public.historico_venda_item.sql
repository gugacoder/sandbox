--
-- TABELA public.historico_venda_item
--
-- drop table if exists public.historico_venda_item;
create table if not exists public.historico_venda_item (
    id bigserial not null primary key

    -- I: INSERT
    -- D: DELETE
  , tp_operacao char not null
  , cod_operacao bigint not null
  , seq_operacao int not null
  , data_operacao timestamp not null default now()

  , id_pdv int not null
  , id_caixa int not null
  , id_sessao int not null
  , aplicativo text null
  , data_movimento date not null

  , id_cupom int not null
  , numero_cupom int not null
  , serie_cupom int not null
  , data_cupom timestamp not null

  , id_item_cupom int not null
  , id_item int not null
  , id_unidade int not null
  , indice_item_cupom int not null

  , cupom_cancelado boolean not null
  , item_cancelado boolean not null

  , frete_cupom numeric(18,4) not null
  , desconto_cupom numeric(18,4) not null
  , acrescimo_cupom numeric(18,4) not null

  , preco_unitario numeric(18,4) not null
  , custo_unitario numeric(18,4) not null
  , desconto_unitario numeric(18,4) not null
  , acrescimo_unitario numeric(18,4) not null

  , quantidade numeric(18,4) not null
  , total_bruto numeric(18,4) not null
  , total_liquido numeric(18,4) not null

  , valor_desconto numeric(18,4) not null
  , valor_acrescimo numeric(18,4) not null
  , valor_icms numeric(18,4) not null
);
