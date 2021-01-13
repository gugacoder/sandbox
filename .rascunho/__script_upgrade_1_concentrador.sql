--
--  REFATORANDO A TABELA
--  -   `valor_desconto` mudou de nome e lugar
--  -   os campos de impostos foram acrescentados
--

do $$ begin
if not exists (
  select 1 from information_schema.columns
   where table_name = 'historico_venda_item'
     and column_name = 'valor_desconto'
) then

  drop table if exists public.historico_venda_item;

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

    , frete_cupom numeric(18,2) not null
    , desconto_cupom numeric(18,2) not null
    , acrescimo_cupom numeric(18,2) not null

    , preco_unitario numeric(18,2) not null
    , custo_unitario numeric(18,2) not null
    , desconto_unitario numeric(18,2) not null
    , acrescimo_unitario numeric(18,2) not null

    , quantidade numeric(18,2) not null
    , total_bruto numeric(18,2) not null
    , total_liquido numeric(18,2) not null

    , valor_desconto numeric(18,2) not null
    , valor_acrescimo numeric(18,2) not null
    , valor_icms numeric(18,2) not null
  );

  select replica.monitorar_tabela('public.historico_venda_item')

end if;
end; $$;


--
--
--
--
-- FUNCTION public.fn__cupomfiscal__historico_venda
--
--
-- FUNCTION public.fn__cupomfiscal__historico_venda
--
create or replace function public.fn__cupomfiscal__historico_venda()
returns trigger as $$
declare
  cod_operacao bigint;
  aplicativo varchar;

  temp int;
begin
  --
  -- A única modificação no pedido que pode provocar um novo histórico de venda
  -- do item é o cancelamento do cupom fiscal.
  --
  if TG_OP != 'UPDATE' then
    return null;
  end if;

  cod_operacao := nextval('public.seq_operacao');
  aplicativo := 
    case when length(coalesce(current_setting('application_name'),'')) > 0
      then current_setting('application_name')
      else ''
    end;

  with ids as (
    -- Detectando alteracoes nos campos monitorados
    select id from (
      select id
           , idsessao
           , fechado
           , cancelado
           , datafechamento
           , frete
           , desconto
           , acrescimo
        from old_table
       union
      select id
           , idsessao
           , fechado
           , cancelado
           , datafechamento
           , frete
           , desconto
           , acrescimo
        from new_table
    ) as t
    group by id
    having count(id) = 2
  )
  insert into public.historico_venda_item (
      tp_operacao
    , cod_operacao
    , seq_operacao

    , id_pdv
    , id_caixa
    , id_sessao
    , aplicativo
    , data_movimento

    , id_cupom
    , numero_cupom
    , serie_cupom
    , data_cupom

    , id_item_cupom
    , id_item
    , id_unidade
    , indice_item_cupom

    , cupom_cancelado
    , item_cancelado

    , frete_cupom
    , desconto_cupom
    , acrescimo_cupom

    , preco_unitario
    , custo_unitario
    , desconto_unitario
    , acrescimo_unitario

    , quantidade
    , total_bruto
    , total_liquido

    , valor_desconto
    , valor_acrescimo
    , valor_icms
  )
  select
      cupomfiscal.tp_operacao
    , cod_operacao
    , cupomfiscal.seq_operacao

    , cast(pdv.identificador as int) as id_pdv
    , caixa.id as id_caixa
    , cupomfiscal.idsessao as id_sessao
    , aplicativo
    , caixa.datamovimento as data_movimento

    , cupomfiscal.id as id_cupom
    , cupomfiscal.coo as numero_cupom
    , cast(pdv.identificador as int) as serie_cupom
    , cupomfiscal.datafechamento as data_cupom

    , itemcupomfiscal.id as id_item_cupom
    , itemcupomfiscal.iditem as id_item
    , item.unidade as id_unidade
    , itemcupomfiscal.indice as indice_item_cupom

    , cupomfiscal.cancelado as cupom_cancelado
    , itemcupomfiscal.cancelado as item_cancelado

    , cupomfiscal.frete as frete_cupom
    , cupomfiscal.desconto as desconto_cupom
    , cupomfiscal.acrescimo as acrescimo_cupom

    , itemcupomfiscal.preco as preco_unitario
    , itemcupomfiscal.precocusto as custo_unitario
    , itemcupomfiscal.desconto as desconto_unitario
    , itemcupomfiscal.acrescimo as acrescimo_unitario

    , itemcupomfiscal.quantidade
    , itemcupomfiscal.totalbruto as total_bruto
    , itemcupomfiscal.totalliquido as total_liquido

    , itemcupomfiscal.totaldesconto as valor_desconto
    , round(itemcupomfiscal.quantidade * itemcupomfiscal.acrescimo, 2) as valor_acrescimo
    , round(itemcupomfiscal.totalliquido * (1::numeric - round(item.percentual_reducao / 100::numeric, 4)) * round(aliquota.percentual / 100::numeric, 4), 2) as valor_icms
  from (
    select 'D' as tp_operacao, 0 as seq_operacao, * from old_table where fechado
    union
    select 'I' as tp_operacao, 1 as seq_operacao, * from new_table where fechado
  ) as cupomfiscal
  inner join ids
          on ids.id = cupomfiscal.id
  inner join itemcupomfiscal
          on itemcupomfiscal.idcupomfiscal = cupomfiscal.id
  inner join item
          on item.id = itemcupomfiscal.iditem
  inner join sessao
          on sessao.id = cupomfiscal.idsessao
  inner join caixa
          on caixa.id = sessao.idcaixa
  inner join pdv
          on pdv.id = sessao.idpdv
  inner join ecf
          on ecf.id = pdv.idecf
  inner join aliquota
          on aliquota.id::text = itemcupomfiscal.tributacao::text
  order by itemcupomfiscal.id, cupomfiscal.tp_operacao;

  return null;
end;
$$ language plpgsql;




--
--  AJUSTANDO A TRIGGER PARA SUPORTAR AS ALTERACOES EM `desconto_total`
--
--
-- FUNCTION public.fn__itemcupomfiscal__historico_venda
--
--
-- FUNCTION public.fn__itemcupomfiscal__historico_venda
--
create or replace function public.fn__itemcupomfiscal__historico_venda()
returns trigger as $$
declare
  cod_operacao bigint;
  aplicativo varchar;
begin

  cod_operacao := nextval('public.seq_operacao');
  aplicativo := 
    case when length(coalesce(current_setting('application_name'),'')) > 0
      then current_setting('application_name')
      else ''
    end;

  if tg_op = 'DELETE' then

    insert into public.historico_venda_item (
        tp_operacao
      , cod_operacao
      , seq_operacao

      , id_pdv
      , id_caixa
      , id_sessao
      , aplicativo
      , data_movimento

      , id_cupom
      , numero_cupom
      , serie_cupom
      , data_cupom

      , id_item_cupom
      , id_item
      , id_unidade
      , indice_item_cupom

      , cupom_cancelado
      , item_cancelado

      , frete_cupom
      , desconto_cupom
      , acrescimo_cupom

      , preco_unitario
      , custo_unitario
      , desconto_unitario
      , acrescimo_unitario

      , quantidade
      , total_bruto
      , total_liquido

      , valor_desconto
      , valor_acrescimo
      , valor_icms
    )
    select
      'D' as tp_operacao
    , cod_operacao
    ,  0  as seq_operacao

    , cast(pdv.identificador as int) as id_pdv
    , caixa.id as id_caixa
    , cupomfiscal.idsessao as id_sessao
    , aplicativo
    , caixa.datamovimento as data_movimento

    , cupomfiscal.id as id_cupom
    , cupomfiscal.coo as numero_cupom
    , cast(pdv.identificador as int) as serie_cupom
    , cupomfiscal.datafechamento as data_cupom

    , itemcupomfiscal.id as id_item_cupom
    , itemcupomfiscal.iditem as id_item
    , item.unidade as id_unidade
    , itemcupomfiscal.indice as indice_item_cupom

    , cupomfiscal.cancelado as cupom_cancelado
    , itemcupomfiscal.cancelado as item_cancelado

    , cupomfiscal.frete as frete_cupom
    , cupomfiscal.desconto as desconto_cupom
    , cupomfiscal.acrescimo as acrescimo_cupom

    , itemcupomfiscal.preco as preco_unitario
    , itemcupomfiscal.precocusto as custo_unitario
    , itemcupomfiscal.desconto as desconto_unitario
    , itemcupomfiscal.acrescimo as acrescimo_unitario

    , itemcupomfiscal.quantidade
    , itemcupomfiscal.totalbruto as total_bruto
    , itemcupomfiscal.totalliquido as total_liquido

    , itemcupomfiscal.totaldesconto as valor_desconto
    , round(itemcupomfiscal.quantidade * itemcupomfiscal.acrescimo, 2) as valor_acrescimo
    , round(itemcupomfiscal.totalliquido * (1::numeric - round(item.percentual_reducao / 100::numeric, 4)) * round(aliquota.percentual / 100::numeric, 4), 2) as valor_icms
    from old_table as itemcupomfiscal
    inner join item
            on item.id = itemcupomfiscal.iditem
    inner join cupomfiscal
            on cupomfiscal.id = itemcupomfiscal.idcupomfiscal
    inner join sessao
            on sessao.id = cupomfiscal.idsessao
    inner join caixa
            on caixa.id = sessao.idcaixa
    inner join pdv
            on pdv.id = sessao.idpdv
    inner join ecf
            on ecf.id = pdv.idecf
    inner join aliquota
            on aliquota.id::text = itemcupomfiscal.tributacao::text
    where cupomfiscal.fechado
    order by itemcupomfiscal.idcupomfiscal, itemcupomfiscal.indice;

  elsif tg_op = 'INSERT' then

    insert into public.historico_venda_item (
        tp_operacao
      , cod_operacao
      , seq_operacao

      , id_pdv
      , id_caixa
      , id_sessao
      , aplicativo
      , data_movimento

      , id_cupom
      , numero_cupom
      , serie_cupom
      , data_cupom

      , id_item_cupom
      , id_item
      , id_unidade
      , indice_item_cupom

      , cupom_cancelado
      , item_cancelado

      , frete_cupom
      , desconto_cupom
      , acrescimo_cupom

      , preco_unitario
      , custo_unitario
      , desconto_unitario
      , acrescimo_unitario

      , quantidade
      , total_bruto
      , total_liquido

      , valor_desconto
      , valor_acrescimo
      , valor_icms
    )
    select
      'I' as tp_operacao
    , cod_operacao
    ,  0  as seq_operacao

    , cast(pdv.identificador as int) as id_pdv
    , caixa.id as id_caixa
    , cupomfiscal.idsessao as id_sessao
    , aplicativo
    , caixa.datamovimento as data_movimento

    , cupomfiscal.id as id_cupom
    , cupomfiscal.coo as numero_cupom
    , cast(pdv.identificador as int) as serie_cupom
    , cupomfiscal.datafechamento as data_cupom

    , itemcupomfiscal.id as id_item_cupom
    , itemcupomfiscal.iditem as id_item
    , item.unidade as id_unidade
    , itemcupomfiscal.indice as indice_item_cupom

    , cupomfiscal.cancelado as cupom_cancelado
    , itemcupomfiscal.cancelado as item_cancelado

    , cupomfiscal.frete as frete_cupom
    , cupomfiscal.desconto as desconto_cupom
    , cupomfiscal.acrescimo as acrescimo_cupom

    , itemcupomfiscal.preco as preco_unitario
    , itemcupomfiscal.precocusto as custo_unitario
    , itemcupomfiscal.desconto as desconto_unitario
    , itemcupomfiscal.acrescimo as acrescimo_unitario

    , itemcupomfiscal.quantidade
    , itemcupomfiscal.totalbruto as total_bruto
    , itemcupomfiscal.totalliquido as total_liquido

    , itemcupomfiscal.totaldesconto as valor_desconto
    , round(itemcupomfiscal.quantidade * itemcupomfiscal.acrescimo, 2) as valor_acrescimo
    , round(itemcupomfiscal.totalliquido * (1::numeric - round(item.percentual_reducao / 100::numeric, 4)) * round(aliquota.percentual / 100::numeric, 4), 2) as valor_icms
    from new_table as itemcupomfiscal
    inner join item
            on item.id = itemcupomfiscal.iditem
    inner join cupomfiscal
            on cupomfiscal.id = itemcupomfiscal.idcupomfiscal
    inner join sessao
            on sessao.id = cupomfiscal.idsessao
    inner join caixa
            on caixa.id = sessao.idcaixa
    inner join pdv
            on pdv.id = sessao.idpdv
    inner join ecf
            on ecf.id = pdv.idecf
    inner join aliquota
            on aliquota.id::text = itemcupomfiscal.tributacao::text
    where cupomfiscal.fechado
    order by itemcupomfiscal.idcupomfiscal, itemcupomfiscal.indice;
  
  elsif tg_op = 'UPDATE' then

    with ids as (
      -- Detectando alteracoes nos campos monitorados
      select id from (
        select id
             , idsessao
             , idcupomfiscal
             , iditem
             , cancelado
             , preco
             , precocusto
             , desconto
             , acrescimo
             , quantidade
             , totalbruto
             , totaldesconto
             , totalliquido
          from old_table
         union
        select id
             , idsessao
             , idcupomfiscal
             , iditem
             , cancelado
             , preco
             , precocusto
             , desconto
             , acrescimo
             , quantidade
             , totalbruto
             , totaldesconto
             , totalliquido
          from new_table
      ) as t
      group by id
      having count(id) = 2
    )
    insert into public.historico_venda_item (
        tp_operacao
      , cod_operacao
      , seq_operacao

      , id_pdv
      , id_caixa
      , id_sessao
      , aplicativo
      , data_movimento

      , id_cupom
      , numero_cupom
      , serie_cupom
      , data_cupom

      , id_item_cupom
      , id_item
      , id_unidade
      , indice_item_cupom

      , cupom_cancelado
      , item_cancelado

      , frete_cupom
      , desconto_cupom
      , acrescimo_cupom

      , preco_unitario
      , custo_unitario
      , desconto_unitario
      , acrescimo_unitario

      , quantidade
      , total_bruto
      , total_liquido

      , valor_desconto
      , valor_acrescimo
      , valor_icms
    )
    select
      itemcupomfiscal.tp_operacao
    , cod_operacao
    , itemcupomfiscal.seq_operacao

    , cast(pdv.identificador as int) as id_pdv
    , caixa.id as id_caixa
    , cupomfiscal.idsessao as id_sessao
    , aplicativo
    , caixa.datamovimento as data_movimento

    , cupomfiscal.id as id_cupom
    , cupomfiscal.coo as numero_cupom
    , cast(pdv.identificador as int) as serie_cupom
    , cupomfiscal.datafechamento as data_cupom

    , itemcupomfiscal.id as id_item_cupom
    , itemcupomfiscal.iditem as id_item
    , item.unidade as id_unidade
    , itemcupomfiscal.indice as indice_item_cupom

    , cupomfiscal.cancelado as cupom_cancelado
    , itemcupomfiscal.cancelado as item_cancelado

    , cupomfiscal.frete as frete_cupom
    , cupomfiscal.desconto as desconto_cupom
    , cupomfiscal.acrescimo as acrescimo_cupom

    , itemcupomfiscal.preco as preco_unitario
    , itemcupomfiscal.precocusto as custo_unitario
    , itemcupomfiscal.desconto as desconto_unitario
    , itemcupomfiscal.acrescimo as acrescimo_unitario

    , itemcupomfiscal.quantidade
    , itemcupomfiscal.totalbruto as total_bruto
    , itemcupomfiscal.totalliquido as total_liquido

    , itemcupomfiscal.totaldesconto as valor_desconto
    , round(itemcupomfiscal.quantidade * itemcupomfiscal.acrescimo, 2) as valor_acrescimo
    , round(itemcupomfiscal.totalliquido * (1::numeric - round(item.percentual_reducao / 100::numeric, 4)) * round(aliquota.percentual / 100::numeric, 4), 2) as valor_icms
    from (
      select 'D' as tp_operacao, 0 as seq_operacao, * from old_table
      union
      select 'I' as tp_operacao, 1 as seq_operacao, * from new_table
    ) as itemcupomfiscal
    inner join ids
            on ids.id = itemcupomfiscal.id
    inner join item
            on item.id = itemcupomfiscal.iditem
    inner join cupomfiscal
            on cupomfiscal.id = itemcupomfiscal.idcupomfiscal
    inner join sessao
            on sessao.id = cupomfiscal.idsessao
    inner join caixa
            on caixa.id = sessao.idcaixa
    inner join pdv
            on pdv.id = sessao.idpdv
    inner join ecf
            on ecf.id = pdv.idecf
    inner join aliquota
            on aliquota.id::text = itemcupomfiscal.tributacao::text
    where cupomfiscal.fechado
    order by itemcupomfiscal.idcupomfiscal, itemcupomfiscal.indice, itemcupomfiscal.tp_operacao;
  
  end if;

  return null;
end;
$$ language plpgsql;



