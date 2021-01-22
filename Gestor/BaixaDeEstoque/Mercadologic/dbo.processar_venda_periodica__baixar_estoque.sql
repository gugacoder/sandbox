drop procedure if exists processar_venda_periodica__baixar_estoque
go
create procedure processar_venda_periodica__baixar_estoque (
    @cod_empresa int
  , @id_usuario int
  , @id_formulario int
) as
  --
  --  Realiza a baixa de estoque a partir da venda periódica.
  --
begin
  --
  -- OBSERVACOES
  --
  -- -  A opção 1514 (Não Permitir baixa de estoque se existir outra data de baixa em aberto.)
  --    não está sendo usada porque a baixa de estoque está sendo sequencial e para todos os dias
  --    em aberto.
  --
  -- -  Este algoritmo pode produzir mais de uma baixa de estoque por dia.
  --    Portanto, o termo VENDA DIÁRIA não representa extamente o resultado deste algoritmo.
  --    Melhor seria chamar o procedimento de VENDA PERÍODICA ou algo similar.
  --

  declare @tb_ids_venda_periodica table (DFid_venda_periodica bigint)
  declare @tb_resumo_venda table (
      DFcod_empresa int
    , DFid_unidade_item_estoque int
    , DFcod_item_estoque int
    , DFestoque_atualizado bit
    , DFestoque_anterior decimal(18,4)
    , DFvenda_media decimal(18,4)
    , DFcusto_medio decimal(18,4)
    , DFquantidade_movimentada decimal(18,4)
    , DFestoque_atual decimal(18,4)
    , DFcusto_lucro decimal(18,4)
    , DFpreco_venda decimal(18,4)
  )

  --
  -- COLETANDO PARÂMETROS
  --
  declare @id_tipo_estoque int = (
    select DFvalor from director.TBopcoes with (nolock) where DFcodigo = 553)
  declare @id_motivo_movto int = (
    select DFvalor from director.TBopcoes with (nolock) where DFcodigo = 966)

  declare @tipo_lancamento char
  declare @motivo_perda bit

  select @tipo_lancamento = DFtipo_lancamento
       , @motivo_perda = DFmotivo_perda
    from director.TBmotivo_movto_endereco  with (nolock)
   where DFcod_motivo_movto_endereco = @id_motivo_movto

  begin try
    begin transaction tx

    --
    -- ELENCANDO A VENDA PERIÓDICA QUE SERÁ PROCESSADA
    --
    update TBvenda_periodica
       set DFestoque_atualizado = 1
    output inserted.DFid_venda_periodica into @tb_ids_venda_periodica
     where DFestoque_atualizado = 0
       and (@cod_empresa is null or DFcod_empresa = @cod_empresa)
       and exists (
             select 1 from dbo.vw_empresa_venda_periodica
              where DFcod_empresa = TBvenda_periodica.DFcod_empresa
                and DFvenda_periodica_ativada = 1)

    --
    -- CALCULANDO A ALTERAÇÃO DE ESTOQUE
    --
    ; with venda_periodica as (
      select TBvenda_periodica.DFid_venda_periodica
           , TBvenda_periodica.DFcod_empresa
           , TBvenda_periodica.DFdata_venda
           , TBvenda_periodica.DFid_unidade_item_estoque
           , TBvenda_periodica.DFvalor_venda
           , TBvenda_periodica.DFcusto_venda
           , (TBunidade_item_estoque.DFfator_conversao * TBvenda_periodica.DFquantidade_vendida) * -1  as DFquantidade_vendida
           , TBvenda_periodica.DFestoque_atualizado
           , TBitem_estoque_atacado_varejo.DForigem_estoque
        from TBvenda_periodica with (nolock)
       inner join director.TBunidade_item_estoque with (nolock)
               on TBunidade_item_estoque.DFid_unidade_item_estoque = TBvenda_periodica.DFid_unidade_item_estoque
       inner join director.TBitem_estoque with (nolock)
               on TBunidade_item_estoque.DFcod_item_estoque = TBitem_estoque.DFcod_item_estoque
       inner join director.TBitem_estoque_atacado_varejo with (nolock)
               on TBitem_estoque_atacado_varejo.DFcod_item_estoque_atacado_varejo = TBitem_estoque.DFcod_item_estoque
       where exists (
               select 1 from @tb_ids_venda_periodica
                where DFid_venda_periodica = TBvenda_periodica.DFid_venda_periodica)
         and TBitem_estoque_atacado_varejo.DForigem_estoque <> 'S'
         and TBitem_estoque.DFestoque_atualizado_baixa_venda = 0
       union
      select TBvenda_periodica.DFid_venda_periodica
           , TBvenda_periodica.DFcod_empresa
           , TBvenda_periodica.DFdata_venda
           , TBparte_item_composto.DFid_unidade_item_estoque
           , VWPRECO1.DFpreco_praticado * TBunidade_item_estoque.DFfator_conversao * TBvenda_periodica.DFquantidade_vendida * TBparte_item_composto.DFqtde * TBunidade_baixada.DFfator_conversao as DFvalor_venda
           , VWPRECO1.DFcusto_real * TBunidade_item_estoque.DFfator_conversao * TBvenda_periodica.DFquantidade_vendida * TBparte_item_composto.DFqtde * TBunidade_baixada.DFfator_conversao as DFcusto_venda
           , TBunidade_item_estoque.DFfator_conversao * TBvenda_periodica.DFquantidade_vendida * TBparte_item_composto.DFqtde * TBunidade_baixada.DFfator_conversao * -1  as DFquantidade_vendida
           , TBvenda_periodica.DFestoque_atualizado
           , TBitem_estoque_atacado_varejo.DForigem_estoque 
        from TBvenda_periodica with (nolock)
       inner join director.TBunidade_item_estoque  with (nolock)
               on TBunidade_item_estoque.DFid_unidade_item_estoque = TBvenda_periodica.DFid_unidade_item_estoque
       inner join director.TBitem_estoque  with (nolock)
               on TBunidade_item_estoque.DFcod_item_estoque = TBitem_estoque.DFcod_item_estoque
       inner join director.TBparte_item_composto with (nolock)
               on TBparte_item_composto.DFcod_item_estoque = TBitem_estoque.DFcod_item_estoque
       inner join director.TBunidade_item_estoque as TBunidade_baixada with (nolock)
               on TBunidade_baixada.DFid_unidade_item_estoque = TBparte_item_composto.DFid_unidade_item_estoque
       inner join director.TBitem_estoque_atacado_varejo  with (nolock)
               on TBitem_estoque_atacado_varejo.DFcod_item_estoque_atacado_varejo = TBunidade_baixada.DFcod_item_estoque
       inner join director.VWPRECO1 with (nolock)
               on VWPRECO1.DFid_unidade_item_estoque = TBunidade_baixada.DFid_unidade_item_estoque
              and VWPRECO1.DFcod_empresa = TBvenda_periodica.DFcod_empresa
       where exists (
               select 1 from @tb_ids_venda_periodica
                where DFid_venda_periodica = TBvenda_periodica.DFid_venda_periodica)
         and TBitem_estoque_atacado_varejo.DForigem_estoque <> 'S'
         and TBitem_estoque.DFestoque_atualizado_baixa_venda = 1
       union
      select TBvenda_periodica.DFid_venda_periodica
           , TBvenda_periodica.DFcod_empresa
           , TBvenda_periodica.DFdata_venda
           , TBitem.DFunidade_controle as DFid_unidade_item_estoque
           , TBvenda_periodica.DFvalor_venda
           , TBvenda_periodica.DFcusto_venda
           , (TBunidade_item_estoque.DFfator_conversao * TBvenda_periodica.DFquantidade_vendida) * -1 as DFquantidade_vendida
           , TBvenda_periodica.DFestoque_atualizado
           , TBitem_estoque_atacado_varejo.DForigem_estoque
        from TBvenda_periodica  with (nolock)
       inner join director.TBunidade_item_estoque  with (nolock)
               on TBunidade_item_estoque.DFid_unidade_item_estoque = TBvenda_periodica.DFid_unidade_item_estoque
       inner join director.TBitem_estoque  with (nolock)
               on TBunidade_item_estoque.DFcod_item_estoque = TBitem_estoque.DFcod_item_estoque
       inner join director.TBitem_estoque_atacado_varejo  with (nolock)
               on TBitem_estoque_atacado_varejo.DFcod_item_estoque_atacado_varejo = TBitem_estoque.DFcod_item_estoque
       inner join director.TBitem_estoque_origem  with (nolock)
               on TBitem_estoque.DFcod_item_estoque = TBitem_estoque_origem.DFcod_item_estoque
       inner join director.TBitem_estoque as TBitem  with (nolock)
               on TBitem_estoque_origem.DFcod_item_estoque_origem = TBitem.DFcod_item_estoque
       where exists (
               select 1 from @tb_ids_venda_periodica
                where DFid_venda_periodica = TBvenda_periodica.DFid_venda_periodica)
         and TBitem_estoque_atacado_varejo.DForigem_estoque = 'S'
         and TBitem_estoque.DFestoque_atualizado_baixa_venda = 0 
       union
      select TBvenda_periodica.DFid_venda_periodica
           , TBvenda_periodica.DFcod_empresa
           , TBvenda_periodica.DFdata_venda
           , TBitem.DFunidade_controle as DFid_unidade_item_estoque
           , VWPRECO1.DFpreco_praticado * TBunidade_item_estoque.DFfator_conversao * TBvenda_periodica.DFquantidade_vendida * TBparte_item_composto.DFqtde * TBunidade_baixada.DFfator_conversao as DFvalor_venda
           , VWPRECO1.DFcusto_real * TBunidade_item_estoque.DFfator_conversao * TBvenda_periodica.DFquantidade_vendida * TBparte_item_composto.DFqtde * TBunidade_baixada.DFfator_conversao as DFcusto_venda
           , TBunidade_item_estoque.DFfator_conversao * TBvenda_periodica.DFquantidade_vendida * TBparte_item_composto.DFqtde * TBunidade_baixada.DFfator_conversao * -1 as DFquantidade_vendida
           , TBvenda_periodica.DFestoque_atualizado
           , TBitem_estoque_atacado_varejo.DForigem_estoque
        from TBvenda_periodica  with (nolock)
       inner join director.TBunidade_item_estoque  with (nolock)
               on TBunidade_item_estoque.DFid_unidade_item_estoque = TBvenda_periodica.DFid_unidade_item_estoque
       inner join director.TBitem_estoque  with (nolock)
               on TBunidade_item_estoque.DFcod_item_estoque = TBitem_estoque.DFcod_item_estoque
       inner join director.TBparte_item_composto with (nolock)
               on TBparte_item_composto.DFcod_item_estoque = TBitem_estoque.DFcod_item_estoque
       inner join director.TBunidade_item_estoque as TBunidade_baixada with (nolock)
               on TBunidade_baixada.DFid_unidade_item_estoque = TBparte_item_composto.DFid_unidade_item_estoque
       inner join director.TBitem_estoque_atacado_varejo  with (nolock)
               on TBitem_estoque_atacado_varejo.DFcod_item_estoque_atacado_varejo = TBunidade_baixada.DFcod_item_estoque 
       inner join director.TBitem_estoque_origem  with (nolock)
               on TBunidade_baixada.DFcod_item_estoque = TBitem_estoque_origem.DFcod_item_estoque
       inner join director.TBitem_estoque as TBitem with (nolock)
               on TBitem_estoque_origem.DFcod_item_estoque_origem = TBitem.DFcod_item_estoque
       inner join director.VWPRECO1 with (nolock)
               on VWPRECO1.DFid_unidade_item_estoque = TBitem.DFunidade_controle
              and VWPRECO1.DFcod_empresa = TBvenda_periodica.DFcod_empresa
       where exists (
               select 1 from @tb_ids_venda_periodica
                where DFid_venda_periodica = TBvenda_periodica.DFid_venda_periodica)
         and TBitem_estoque_atacado_varejo.DForigem_estoque = 'S'
         and TBitem_estoque.DFestoque_atualizado_baixa_venda = 1 
    )
    insert into @tb_resumo_venda
    select venda_periodica.DFcod_empresa
         , venda_periodica.DFid_unidade_item_estoque
         , TBunidade_item_estoque.DFcod_item_estoque
         , venda_periodica.DFestoque_atualizado
         , isnull(TBhistorico_estoque.DFquantidade_atual,0) as DFestoque_anterior
         , cast((sum(venda_periodica.DFvalor_venda) / sum(venda_periodica.DFquantidade_vendida*-1)) as decimal(18,2)) as DFvenda_media
         , cast((sum(venda_periodica.DFcusto_venda) / sum(venda_periodica.DFquantidade_vendida*-1)) as decimal(18,2)) as DFcusto_medio
         , sum(venda_periodica.DFquantidade_vendida) as DFquantidade_movimentada
         , isnull(TBhistorico_estoque.DFquantidade_atual,0) + sum(venda_periodica.DFquantidade_vendida) as DFestoque_atual
         , cast(0 as decimal (18,4)) as DFcusto_lucro
         , cast(0 as decimal (18,4)) as DFpreco_venda
      from venda_periodica with (nolock)
      left join director.TBhistorico_estoque with (nolock)
             on TBhistorico_estoque.DFcod_empresa = venda_periodica.DFcod_empresa
            and TBhistorico_estoque.DFid_unidade_item_estoque = venda_periodica.DFid_unidade_item_estoque
            and TBhistorico_estoque.DFid_tipo_estoque = @id_tipo_estoque
            and TBhistorico_estoque.DFstatus = 1
     inner join director.TBunidade_item_estoque with (nolock)
             on venda_periodica.DFid_unidade_item_estoque = TBunidade_item_estoque.DFid_unidade_item_estoque
     group by venda_periodica.DFcod_empresa
            , venda_periodica.DFid_unidade_item_estoque
            , TBunidade_item_estoque.DFcod_item_estoque
            , venda_periodica.DFestoque_atualizado
            , TBhistorico_estoque.DFquantidade_atual 

    --
    -- MARCANDO O ESTOQUE ATUAL COMO HISTÓRICO
    --
    update director.TBhistorico_estoque
       set DFstatus = 0
      from director.TBhistorico_estoque
     inner join @tb_resumo_venda as venda_periodica
             on venda_periodica.DFcod_empresa = TBhistorico_estoque.DFcod_empresa
            and venda_periodica.DFid_unidade_item_estoque = TBhistorico_estoque.DFid_unidade_item_estoque
     where TBhistorico_estoque.DFstatus = 1
       and TBhistorico_estoque.DFid_tipo_estoque = @id_tipo_estoque

    --
    -- ATUALIZANDO O ESTOQUE
    --  
    insert into director.TBhistorico_estoque (
        DFcod_empresa
      , DFid_usuario
      , DFid_unidade_item_estoque
      , DFcod_motivo_movto_endereco
      , DFid_tipo_estoque
      , DFstatus
      , DFdata_alteracao
      , DFquantidade_movimentada
      , DFquantidade_atual
      , DFpreco_venda
      , DFcusto_real
      , DFid_formulario
      , DFcomplemento
      , DFtipo_lancamento
      , DFmotivo_perda
    ) 
    select DFcod_empresa
         , @id_usuario as DFid_usuario
         , DFid_unidade_item_estoque
         , @id_motivo_movto as DFcod_motivo_movto_endereco
         , @id_tipo_estoque as DFid_tipo_estoque
         , 1 as DFstatus
         , current_timestamp as DFdata_alteracao
         , DFquantidade_movimentada
         , DFestoque_atual as DFquantidade_atual
         , DFvenda_media as DFpreco_venda
         , DFcusto_medio as DFcusto_real
         , @id_formulario as DFid_formulario
         , concat(
             'IMPORTACAO AUTOM. VENDA LOJA ',
             left('000',(case when len(DFcod_empresa) < 3 then 3-len(DFcod_empresa) else 0 end)),
             DFcod_empresa,
             ' DIA ',
             convert(nvarchar(100), current_timestamp, 103)
           ) as DFcomplemento
         , @tipo_lancamento as DFtipo_lancamento
         , @motivo_perda as DFmotivo_perda
      from @tb_resumo_venda

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

-- exec processar_venda_periodica__baixar_estoque 7, 1, 0
