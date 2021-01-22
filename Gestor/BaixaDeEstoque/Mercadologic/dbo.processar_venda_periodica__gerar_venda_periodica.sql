drop procedure if exists processar_venda_periodica__gerar_venda_periodica
go
create procedure processar_venda_periodica__gerar_venda_periodica (
    @cod_empresa int
  , @id_usuario int
  , @id_formulario int
) as
  --
  --  Sumariza e salva a venda peródica dos itens a partir dos dados
  --  replicados do PDV para a base SQLServer do Mercadologic (DBmercadologic).
  --
begin
  declare @tb_ids_replica table (id_replica bigint)
  declare @data_status datetime = current_timestamp

  -- Percentual de encargo bancário p/cálculo da margem de lucro do item
  declare @encargos decimal(18,4) = (
    select replace(replace(DFvalor,'.',''),',','.')
      from director.TBopcoes with (nolock)
     where DFcodigo = 551
  )

  begin try
    begin transaction tx

    --
    -- ELENCANDO O HISTORICO QUE SERÁ PROCESSADO
    --
    insert into replica.status_historico_venda_item (id_replica, tipo_status, data_status)
    output inserted.id_replica into @tb_ids_replica
    select id_replica
         , 'E' as tipo_status -- E: Estoque Atualizado
         , data_status = @data_status
      from replica.historico_venda_item with (nolock)
     where (@cod_empresa is null or cod_empresa = @cod_empresa)
       and exists (
             select 1 from dbo.vw_empresa_venda_periodica
              where DFcod_empresa = historico_venda_item.cod_empresa
                and DFvenda_periodica_ativada = 1)
       and not exists (
              select 1 from replica.status_historico_venda_item with (nolock)
               where id_replica = replica.historico_venda_item.id_replica)
       and exists (
              select 1 from director.TBunidade_item_estoque with (nolock)
               where DFcod_item_estoque = replica.historico_venda_item.id_item
                 and DFcod_unidade = replica.historico_venda_item.id_unidade)

    --
    -- AGRUPANDO E REGISTRANDO A VENDA NA TABELA DE VENDA
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
        from replica.historico_venda_item as historico_venda_item with (nolock)
       inner join director.TBitem_estoque_atacado_varejo with (nolock)
               on TBitem_estoque_atacado_varejo.DFcod_item_estoque_atacado_varejo = historico_venda_item.id_item
       inner join director.TBempresa_atacado_varejo with (nolock)
               on TBempresa_atacado_varejo.DFcod_empresa = historico_venda_item.cod_empresa
       inner join director.TBunidade_item_estoque
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
    insert into TBvenda_periodica (
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
      , DFvalor_desconto
      , DFestoque_atualizado
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
         , 0 as DFvalor_desconto
         , 0 as DFestoque_atualizado
      from venda
     group by
           DFid_unidade_item_estoque
         , DFcod_empresa
         , DFdata_venda
     
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

-- exec processar_venda_periodica__gerar_venda_periodica 7, 1, null
