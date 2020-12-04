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
      , itemcupomfiscal.idsessao
      , aplicativo

      , itemcupomfiscal.idcupomfiscal
      , itemcupomfiscal.id
      , itemcupomfiscal.iditem
      , item.unidade

      , 'D' -- tp_operacao
      , cod_operacao
      ,  0  -- seq_operacao

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
    --from (select old.*) as item
    from old_table as itemcupomfiscal
    inner join item
            on item.id = itemcupomfiscal.iditem
    inner join cupomfiscal
            on cupomfiscal.id = itemcupomfiscal.idcupomfiscal
    inner join sessao
            on sessao.id = cupomfiscal.idsessao
    inner join pdv
            on pdv.id = sessao.idpdv
    where cupomfiscal.fechado;

  elsif tg_op = 'INSERT' then

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
      , itemcupomfiscal.idsessao
      , aplicativo

      , itemcupomfiscal.idcupomfiscal
      , itemcupomfiscal.id
      , itemcupomfiscal.iditem
      , item.unidade

      , 'I' -- tp_operacao
      , cod_operacao
      ,  0  -- seq_operacao

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
    from new_table as itemcupomfiscal
    inner join item
            on item.id = itemcupomfiscal.iditem
    inner join cupomfiscal
            on cupomfiscal.id = itemcupomfiscal.idcupomfiscal
    inner join sessao
            on sessao.id = cupomfiscal.idsessao
    inner join pdv
            on pdv.id = sessao.idpdv
    where cupomfiscal.fechado;
  
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
      , itemcupomfiscal.idsessao
      , aplicativo

      , itemcupomfiscal.idcupomfiscal
      , itemcupomfiscal.id
      , itemcupomfiscal.iditem
      , item.unidade
      
      , itemcupomfiscal.tp_operacao
      , cod_operacao
      , itemcupomfiscal.seq_operacao

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
    inner join pdv
            on pdv.id = sessao.idpdv
    where cupomfiscal.fechado
    order by itemcupomfiscal.id, itemcupomfiscal.tp_operacao;
  
  end if;

  return null;
end;
$$ language plpgsql;

