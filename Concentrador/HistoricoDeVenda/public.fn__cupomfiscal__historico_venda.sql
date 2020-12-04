--
-- FUNCTION public.fn__cupomfiscal__historico_venda
--
create or replace function public.fn__cupomfiscal__historico_venda()
returns trigger as $$
declare
  cod_operacao bigint;
  aplicativo varchar;

  counter int;
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
      id_pdv
    , id_sessao
    , aplicativo

    , id_cupom
    , id_item_cupom
    , id_item
    , id_unidade
    
    , tp_operacao
    , cod_operacao
    , seq_operacao

    , data_cupom
    , frete_cupom
    , desconto_cupom
    , acrescimo_cupom

    , cupom_cancelado
    , item_cancelado

    , preco_unitario
    , custo_unitario
    , desconto_unitario
    , acrescimo_unitario
    , quantidade
    , total_sem_desconto
    , total_desconto
    , total_com_desconto
  )
  select
      cast(pdv.identificador as int)
    , cupomfiscal.idsessao
    , aplicativo

    , cupomfiscal.id
    , itemcupomfiscal.id
    , itemcupomfiscal.iditem
    , item.unidade
    
    , cupomfiscal.tp_operacao
    , cod_operacao
    , cupomfiscal.seq_operacao

    , cupomfiscal.datafechamento
    , cupomfiscal.frete
    , cupomfiscal.desconto
    , cupomfiscal.acrescimo

    , cupomfiscal.cancelado
    , itemcupomfiscal.cancelado

    , itemcupomfiscal.preco
    , itemcupomfiscal.precocusto
    , itemcupomfiscal.desconto
    , itemcupomfiscal.acrescimo
    , itemcupomfiscal.quantidade
    , itemcupomfiscal.totalbruto
    , itemcupomfiscal.totaldesconto
    , itemcupomfiscal.totalliquido
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
  inner join pdv
          on pdv.id = sessao.idpdv
  order by itemcupomfiscal.id, cupomfiscal.tp_operacao;

  return null;
end;
$$ language plpgsql;

