use DBdirector

drop table if exists #TBhistorico_venda_item_pendente
drop table if exists #TBmovimento

select id_replica
     , id_item
     , id_unidade
     , tp_operacao
     , case tp_operacao when 'I' then -quantidade else quantidade end as movimento
  into #TBhistorico_venda_item_pendente
  from mlogic.vw_replica_historico_venda_item
 where (cupom_cancelado = 0 and item_cancelado = 0)
   and not exists (
      select *
        from mlogic.vw_status_historico_venda_item
       where id_replica = vw_replica_historico_venda_item.id_replica
         and tipo_status = 'E'
   )

; with movimento as (
  select id_item
       , id_unidade
       , sum(movimento) as movimento
    from #TBhistorico_venda_item_pendente
   group by id_item, id_unidade
  having sum(movimento) != 0
)
select top 10
       TBitem_estoque.DFcod_item_estoque
     , TBitem_estoque.DFdescricao
     , case when movimento < 0 then 'S' else 'E' end as DFtipo_movimento
     , case when movimento < 0 then -movimento else movimento end as DFqtde_movimento
     , TBunidade.DFcod_unidade
     , TBunidade.DFdescricao as DFunidade
  into #TBmovimento
  from movimento
 inner join TBitem_estoque
         on TBitem_estoque.DFcod_item_estoque = id_item
 inner join TBunidade
         on TBunidade.DFcod_unidade = id_unidade
 order by DFcod_item_estoque

select top 2 * from #TBhistorico_venda_item_pendente
select * from #TBmovimento


/*
insert into mlogic.vw_status_historico_venda_item (id_replica, tipo_status)
select id_replica, 'E' from mlogic.vw_replica_historico_venda_item
where data_cupom < '2020-12-03'

delete from mlogic.vw_status_historico_venda_item
*/