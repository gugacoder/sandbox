

-- PARTE 1: ELENCANDO O HISTORICO QUE SERÁ PROCESSADO
declare @tb_replica table (id_replica bigint)

insert into @tb_replica
select 
       top 10 -- APENAS PARA TESTES
       id_replica
  from replica.historico_venda_item
 where not exists (
    select * from replica.status_historico_venda_item
     where status_historico_venda_item.id_replica = historico_venda_item.id_replica
   -- limites do teste
     --and data_cupom > '2021-01-07'
     --and id_cupom = 1542757
 )

-- PARTE 2: AGRUPANDO A VENDA E REGISTRANDO NA TABELA DE VENDA
; with
venda_crua as (
  select tp_operacao
       , id_item as DFcod_item_estoque
       , id_unidade as DFcod_unidade
       , cod_empresa as DFcod_empresa
       , cast(data_cupom as date) as DFdata_venda
       , quantidade as DFquantidade_vendida
       , total_com_desconto as DFvalor_venda
       , (custo_unitario * quantidade) as DFcusto_venda
       , 0 /* rever */ as DFvalor_icms
       , 0 /* rever */ as DFvalor_pis
       , 0 /* rever */ as DFvalor_cofins
       , 0 /* rever */ as DFvalor_encargos
       , 0 as DFvalor_desconto
       , 0 /* rever */ as DFcusto_contabil_venda
    from replica.historico_venda_item
   inner join @tb_replica as tb_replica
           on tb_replica.id_replica = historico_venda_item.id_replica
   where not (cupom_cancelado = 1 or item_cancelado = 1)
),
venda as (
  select DFcod_item_estoque
       , DFcod_unidade
       , DFcod_empresa
       , DFdata_venda
       , case tp_operacao when 'D' then -DFquantidade_vendida   else DFquantidade_vendida   end as DFquantidade_vendida  
       , case tp_operacao when 'D' then -DFvalor_venda          else DFvalor_venda          end as DFvalor_venda         
       , case tp_operacao when 'D' then -DFcusto_venda          else DFcusto_venda          end as DFcusto_venda         
       , case tp_operacao when 'D' then -DFvalor_icms           else DFvalor_icms           end as DFvalor_icms          
       , case tp_operacao when 'D' then -DFvalor_pis            else DFvalor_pis            end as DFvalor_pis           
       , case tp_operacao when 'D' then -DFvalor_cofins         else DFvalor_cofins         end as DFvalor_cofins        
       , case tp_operacao when 'D' then -DFvalor_encargos       else DFvalor_encargos       end as DFvalor_encargos      
       , case tp_operacao when 'D' then -DFvalor_desconto       else DFvalor_desconto       end as DFvalor_desconto      
       , case tp_operacao when 'D' then -DFcusto_contabil_venda else DFcusto_contabil_venda end as DFcusto_contabil_venda
    from venda_crua
)
select DFcod_item_estoque
     , DFcod_unidade
     , DFdata_venda
     , 0 as DFestoque_atualizado
     , sum(DFquantidade_vendida) as DFquantidade_vendida
     , sum(DFvalor_venda) as DFvalor_venda
     , sum(DFcusto_venda) as DFcusto_venda
     , sum(DFvalor_icms) as DFvalor_icms
     , sum(DFvalor_pis) as DFvalor_pis
     , sum(DFvalor_cofins) as DFvalor_cofins
     , sum(DFvalor_encargos) as DFvalor_encargos
     , sum(DFvalor_desconto) as DFvalor_desconto
     , sum(DFcusto_contabil_venda) as DFcusto_contabil_venda
  from venda
 group by
       DFcod_item_estoque
     , DFcod_unidade
     , DFcod_empresa
     , DFdata_venda

/*
select id_item
     , sum(case tp_operacao when 'D' then -quantidade else quantidade end)
  from replica.historico_venda_item
 where not (cupom_cancelado = 1 or item_cancelado = 1)
   and id_cupom = 1542757
 group by id_item
*/

