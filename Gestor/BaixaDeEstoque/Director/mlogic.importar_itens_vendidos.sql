--
-- PROCEDURE mlogic.importar_itens_vendidos
--
drop procedure if exists mlogic.importar_itens_vendidos
go
create procedure mlogic.importar_itens_vendidos (
    @cod_empresa int = null
) as
  --
  -- Importa para a base do DIRECTOR os itens vendidos nos PDVs e pendentes de importação.
  -- 
begin

  --
  -- COLECTANDO PARAMETROS
  --
  declare @encargos decimal(18,4) = 0

  select @encargos = replace(replace(DFvalor,'.',''),',','.')
    from TBopcoes with (nolock)
   where DFcodigo = 551;

  --
  -- ELENCANDO O HISTORICO QUE SERÁ PROCESSADO
  --
  declare @tb_ids_replica table (id_replica bigint)

  insert into @tb_ids_replica
  select id_replica
    from mlogic.vw_replica_historico_venda_item
   where (@cod_empresa is null or cod_empresa = @cod_empresa)
     and not exists (
      select 1 from mlogic.vw_status_historico_venda_item
       where id_replica = vw_replica_historico_venda_item.id_replica
   )

  begin try
    begin transaction tx

    --
    -- AGRUPANDO A VENDA E REGISTRANDO NA TABELA DE VENDA
    --
    ; with
    venda_crua as (
      select historico_venda_item.tp_operacao
           , TBunidade_item_estoque.DFid_unidade_item_estoque
           , historico_venda_item.cod_empresa as DFcod_empresa
           , historico_venda_item.data_movimento as DFdata_venda
           , historico_venda_item.quantidade as DFquantidade_vendida
           , historico_venda_item.total_liquido as DFvalor_venda
           , (historico_venda_item.custo_unitario * historico_venda_item.quantidade) as DFcusto_venda
           , historico_venda_item.valor_icms as DFvalor_icms
           , case when TBitem_estoque_atacado_varejo.DFpis = 1
               then historico_venda_item.total_liquido * TBempresa_atacado_varejo.DFpercentual_pis / 100
               else 0
             end DFvalor_pis
           , case when TBitem_estoque_atacado_varejo.DFcofins = 1
               then historico_venda_item.total_liquido * TBempresa_atacado_varejo.DFpercentual_cofins / 100
               else 0
             end as DFvalor_cofins
           , historico_venda_item.total_liquido * @encargos / 100 as DFvalor_encargos
        from mlogic.vw_replica_historico_venda_item as historico_venda_item with (nolock)
       inner join TBitem_estoque_atacado_varejo with (nolock)
               on TBitem_estoque_atacado_varejo.DFcod_item_estoque_atacado_varejo = historico_venda_item.id_item
       inner join TBempresa_atacado_varejo with (nolock)
               on TBempresa_atacado_varejo.DFcod_empresa = historico_venda_item.cod_empresa
       inner join TBunidade_item_estoque
               on TBunidade_item_estoque.DFcod_item_estoque = historico_venda_item.id_item
              and TBunidade_item_estoque.DFcod_unidade = historico_venda_item.id_unidade
       where exists (select 1 from @tb_ids_replica where id_replica = historico_venda_item.id_replica)
         and not (historico_venda_item.cupom_cancelado = 1 or historico_venda_item.item_cancelado = 1)
    ),
    venda as (
      select DFid_unidade_item_estoque
           , DFcod_empresa
           , DFdata_venda
           , case tp_operacao when 'D' then -DFquantidade_vendida   else DFquantidade_vendida   end as DFquantidade_vendida  
           , case tp_operacao when 'D' then -DFvalor_venda          else DFvalor_venda          end as DFvalor_venda         
           , case tp_operacao when 'D' then -DFcusto_venda          else DFcusto_venda          end as DFcusto_venda         
           , case tp_operacao when 'D' then -DFvalor_icms           else DFvalor_icms           end as DFvalor_icms          
           , case tp_operacao when 'D' then -DFvalor_pis            else DFvalor_pis            end as DFvalor_pis           
           , case tp_operacao when 'D' then -DFvalor_cofins         else DFvalor_cofins         end as DFvalor_cofins        
           , case tp_operacao when 'D' then -DFvalor_encargos       else DFvalor_encargos       end as DFvalor_encargos      
        from venda_crua
    )
    insert into rascunho.TBvenda_diaria (
        DFid_unidade_item_estoque
      , DFcod_empresa
      , DFdata_venda
      , DFquantidade_vendida
      , DFvalor_venda
      , DFcusto_venda
      , DFvalor_icms
      , DFvalor_pis
      , DFvalor_cofins
      , DFvalor_encargos
      , DFestoque_atualizado
      , DFvalor_desconto
      , DFcusto_contabil_venda
    )
    select DFid_unidade_item_estoque
         , DFcod_empresa
         , DFdata_venda
         , sum(DFquantidade_vendida) as DFquantidade_vendida
         , sum(DFvalor_venda) as DFvalor_venda
         , sum(DFcusto_venda) as DFcusto_venda
         , sum(DFvalor_icms) as DFvalor_icms
         , sum(DFvalor_pis) as DFvalor_pis
         , sum(DFvalor_cofins) as DFvalor_cofins
         , sum(DFvalor_encargos) as DFvalor_encargos
         , 0 as DFestoque_atualizado
         , 0 as DFvalor_desconto
         , null as DFcusto_contabil_venda
      from venda
     group by
           DFid_unidade_item_estoque
         , DFcod_empresa
         , DFdata_venda

    --
    -- MARCANDO O HISTÓRICO DE VENDA DO ITEM COMO BAIXADO NO ESTOQUE
    --
    declare @data_status datetime = current_timestamp

    insert into mlogic.vw_status_historico_venda_item (id_replica, tipo_status, data_status)
    select id_replica
         , 'E' as tipo_status -- E: Estoque Atualizado
         , data_status = @data_status
     from @tb_ids_replica
     
    commit transaction tx
  end try
  begin catch
    if @@trancount > 0
      rollback transaction tx
      
    declare @mensagem nvarchar(max) = concat(error_message(),' (linha ',error_line(),')')
    declare @severidade int = error_severity()
    declare @estado int = error_state()

    raiserror (@mensagem, @severidade, @estado) with nowait
  end catch

end
go
