select id_cupom
     , cast(max(cast(cupom_cancelado as int)) as bit) as cancelado
     , sum(valor) as total
     , count(distinct id_item_cupom) itens
  from (
  select id_cupom
       , cupom_cancelado
       , case 
           when item_cancelado = 1 then 0
           when tp_operacao = 'D' then -total_com_desconto
           else total_com_desconto
         end valor
       , id_item_cupom
    from mlogic.vw_replica_historico_venda_item
) as t
 where cupom_cancelado = 1
   and id_cupom = 1113009
 group by id_cupom
