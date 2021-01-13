select id_item
     , indice_item_cupom
     , quantidade
     , total_bruto
     , total_liquido
     , valor_icms
 from replica.historico_venda_item
where id_cupom = 518433
  and id_item = 548

exec replica.replicar_mercadologic 7

select * from replica.vw_empresa 7


