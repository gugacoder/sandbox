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
        cod_pdv
      , id_cupom
      , id_item_cupom
      , id_sessao
      , aplicativo
      , tp_operacao
      , cod_operacao
      , seq_operacao
      , item_cancelado
      , cupom_cancelado
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
      , item.idcupomfiscal
      , item.id
      , item.idsessao
      , aplicativo
      , 'D' -- tp_operacao
      , cod_operacao
      ,  0  -- seq_operacao
      , item.cancelado
      , cupomfiscal.cancelado
      , item.preco
      , item.precocusto
      , item.desconto
      , item.acrescimo
      , item.quantidade
      , item.totalbruto
      , item.totaldesconto
      , item.totalliquido
    --from (select old.*) as item
    from old_table as item
    inner join cupomfiscal
            on cupomfiscal.id = item.idcupomfiscal
    inner join sessao
            on sessao.id = cupomfiscal.idsessao
    inner join pdv
            on pdv.id = sessao.idpdv;

  elsif tg_op = 'INSERT' then

    insert into public.historico_venda_item (
        cod_pdv
      , id_cupom
      , id_item_cupom
      , id_sessao
      , aplicativo
      , tp_operacao
      , cod_operacao
      , seq_operacao
      , item_cancelado
      , cupom_cancelado
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
      , item.idcupomfiscal
      , item.id
      , item.idsessao
      , aplicativo
      , 'I' -- tp_operacao
      , cod_operacao
      ,  0  -- seq_operacao
      , item.cancelado
      , cupomfiscal.cancelado
      , item.preco
      , item.precocusto
      , item.desconto
      , item.acrescimo
      , item.quantidade
      , item.totalbruto
      , item.totaldesconto
      , item.totalliquido
    from new_table as item
    inner join cupomfiscal
            on cupomfiscal.id = item.idcupomfiscal
    inner join sessao
            on sessao.id = cupomfiscal.idsessao
    inner join pdv
            on pdv.id = sessao.idpdv;
  
  elsif tg_op = 'UPDATE' then

    with ids as (
      -- Detectando alteracoes nos campos monitorados
      select id from (
        select id
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
        cod_pdv
      , id_cupom
      , id_item_cupom
      , id_sessao
      , aplicativo
      , tp_operacao
      , cod_operacao
      , seq_operacao
      , item_cancelado
      , cupom_cancelado
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
      , item.idcupomfiscal
      , item.id
      , item.idsessao
      , aplicativo
      , item.tp_operacao
      , cod_operacao
      , item.seq_operacao
      , item.cancelado
      , cupomfiscal.cancelado
      , item.preco
      , item.precocusto
      , item.desconto
      , item.acrescimo
      , item.quantidade
      , item.totalbruto
      , item.totaldesconto
      , item.totalliquido
    from (
      select 'D' as tp_operacao, 0 as seq_operacao, * from old_table
      union
      select 'I' as tp_operacao, 1 as seq_operacao, * from new_table
    ) as item
    inner join ids
            on ids.id = item.id
    inner join cupomfiscal
            on cupomfiscal.id = item.idcupomfiscal
    inner join sessao
            on sessao.id = cupomfiscal.idsessao
    inner join pdv
            on pdv.id = sessao.idpdv
    order by item.id, item.tp_operacao;
  
  end if;

  return null;
end;
$$ language plpgsql;

