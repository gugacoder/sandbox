drop procedure if exists processar_venda_periodica__gerar_venda_diaria
go
create procedure processar_venda_periodica__gerar_venda_diaria (
    @cod_empresa int
  , @id_usuario int
  , @id_formulario int
) as
  --
  --  Atualiza a venda diária a partir da venda periódica depois da baixa
  --  de estoque efetuada.
  --
begin

  declare @tb_ids_venda_periodica table (DFid_venda_periodica bigint)

  begin try
    begin transaction tx

    --
    -- ELENCANDO A VENDA PERIODICA QUE SERÁ PROCESSADA
    --
    update TBvenda_periodica
       set DFvenda_diaria_atualizada = 1
    output inserted.DFid_venda_periodica into @tb_ids_venda_periodica
     where (@cod_empresa is null or DFcod_empresa = @cod_empresa)
       and DFestoque_atualizado = 1
       and DFvenda_diaria_atualizada = 0
       and exists (
             select 1 from dbo.vw_empresa_venda_periodica
              where DFcod_empresa = TBvenda_periodica.DFcod_empresa
                and DFvenda_periodica_ativada = 1)
    
    --
    -- SUMARIZANDO A VENDA PERIODICA E ATUALIZANDO A VENDA DIARIA
    --
    ; with venda as (
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
           , sum(DFvalor_desconto) as DFvalor_desconto
           , 0 as DFcusto_contabil_venda
           , 1 as DFestoque_atualizado
        from TBvenda_periodica with (nolock)
       inner join @tb_ids_venda_periodica as tb_ids_venda_periodica
               on tb_ids_venda_periodica.DFid_venda_periodica = TBvenda_periodica.DFid_venda_periodica 
       group by DFid_unidade_item_estoque
              , DFcod_empresa
              , DFdata_venda
    )
    merge director.TBvenda_diaria
    using venda
       on venda.DFid_unidade_item_estoque = TBvenda_diaria.DFid_unidade_item_estoque
      and venda.DFcod_empresa = TBvenda_diaria.DFcod_empresa
      and venda.DFdata_venda = TBvenda_diaria.DFdata_venda
    when matched then
      update
         set DFquantidade_vendida = TBvenda_diaria.DFquantidade_vendida + venda.DFquantidade_vendida
           , DFvalor_venda = TBvenda_diaria.DFvalor_venda + venda.DFvalor_venda
           , DFcusto_venda = TBvenda_diaria.DFcusto_venda + venda.DFcusto_venda
           , DFvalor_icms = TBvenda_diaria.DFvalor_icms + venda.DFvalor_icms
           , DFvalor_pis = TBvenda_diaria.DFvalor_pis + venda.DFvalor_pis
           , DFvalor_cofins = TBvenda_diaria.DFvalor_cofins + venda.DFvalor_cofins
           , DFvalor_encargos = TBvenda_diaria.DFvalor_encargos + venda.DFvalor_encargos
           , DFvalor_desconto = TBvenda_diaria.DFvalor_desconto + venda.DFvalor_desconto
    when not matched then
      insert (DFid_unidade_item_estoque
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
            , DFcusto_contabil_venda
            , DFestoque_atualizado)
      values (venda.DFid_unidade_item_estoque
            , venda.DFcod_empresa
            , venda.DFdata_venda
            , venda.DFquantidade_vendida
            , venda.DFvalor_venda
            , venda.DFcusto_venda
            , venda.DFvalor_icms
            , venda.DFvalor_pis
            , venda.DFvalor_cofins
            , venda.DFvalor_encargos
            , venda.DFvalor_desconto
            , venda.DFcusto_contabil_venda
            , venda.DFestoque_atualizado)
    ;

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

-- exec processar_venda_periodica__gerar_venda_diaria 7, 1, 0
