--
-- PROCEDURE mlogic.baixar_estoque_itens_vendidos
--
drop procedure if exists mlogic.baixar_estoque_itens_vendidos
go
create procedure mlogic.baixar_estoque_itens_vendidos (
    @cod_empresa int = null
  , @id_usuario int = null
  , @id_formulario int = 0
) as
 --
 -- Baixa o estoque dos itens vendidos nos PDVs disponíveis e pendentes na
 -- tabela de venda diária do DIRECTOR.
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

  declare @tb_ids_venda_diaria table (DFid_venda_diaria bigint)
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
  declare @id_tipo_estoque int = (select DFvalor from TBopcoes with (nolock) where DFcodigo = 553)
  declare @id_motivo_movto int = (select DFvalor from TBopcoes with (nolock) where DFcodigo = 966)

  declare @tipo_lancamento char
  declare @motivo_perda bit

  select @tipo_lancamento = DFtipo_lancamento
       , @motivo_perda = DFmotivo_perda
    from TBmotivo_movto_endereco  with (nolock)
   where DFcod_motivo_movto_endereco = @id_motivo_movto

  if @id_usuario is null begin
    select @id_usuario = min(DFid_usuario) from TBusuario where DFnivel_usuario = 99
  end

  begin try
    begin transaction tx

    --
    -- ELENCANDO A VENDA DIARIA QUE SERÁ PROCESSADA
    --
    update rascunho.TBvenda_diaria
       set DFestoque_atualizado = 1
    output inserted.DFid_venda_diaria into @tb_ids_venda_diaria
     where DFestoque_atualizado = 0
       and (@cod_empresa is null or DFcod_empresa = @cod_empresa)

    --
    -- CALCULANDO A ALTERAÇÃO DE ESTOQUE
    --
    ; with venda_diaria as (
      select TBvenda_diaria.DFid_venda_diaria
           , TBvenda_diaria.DFcod_empresa
           , TBvenda_diaria.DFdata_venda
           , TBvenda_diaria.DFid_unidade_item_estoque
           , TBvenda_diaria.DFvalor_venda
           , TBvenda_diaria.DFcusto_venda
           , (TBunidade_item_estoque.DFfator_conversao * TBvenda_diaria.DFquantidade_vendida) * -1  as DFquantidade_vendida
           , TBvenda_diaria.DFestoque_atualizado
           , TBitem_estoque_atacado_varejo.DForigem_estoque
        from rascunho.TBvenda_diaria with (nolock)
       inner join TBunidade_item_estoque with (nolock)
               on TBunidade_item_estoque.DFid_unidade_item_estoque = TBvenda_diaria.DFid_unidade_item_estoque
       inner join TBitem_estoque with (nolock)
               on TBunidade_item_estoque.DFcod_item_estoque = TBitem_estoque.DFcod_item_estoque
       inner join TBitem_estoque_atacado_varejo with (nolock)
               on TBitem_estoque_atacado_varejo.DFcod_item_estoque_atacado_varejo = TBitem_estoque.DFcod_item_estoque
       where exists (
               select 1 from @tb_ids_venda_diaria
                where DFid_venda_diaria = TBvenda_diaria.DFid_venda_diaria)
         and TBitem_estoque_atacado_varejo.DForigem_estoque <> 'S'
         and TBitem_estoque.DFestoque_atualizado_baixa_venda = 0
       union
      select TBvenda_diaria.DFid_venda_diaria
           , TBvenda_diaria.DFcod_empresa
           , TBvenda_diaria.DFdata_venda
           , TBparte_item_composto.DFid_unidade_item_estoque
           , VWPRECO1.DFpreco_praticado * TBunidade_item_estoque.DFfator_conversao * TBvenda_diaria.DFquantidade_vendida * TBparte_item_composto.DFqtde * TBunidade_baixada.DFfator_conversao as DFvalor_venda
           , VWPRECO1.DFcusto_real * TBunidade_item_estoque.DFfator_conversao * TBvenda_diaria.DFquantidade_vendida * TBparte_item_composto.DFqtde * TBunidade_baixada.DFfator_conversao as DFcusto_venda
           , TBunidade_item_estoque.DFfator_conversao * TBvenda_diaria.DFquantidade_vendida * TBparte_item_composto.DFqtde * TBunidade_baixada.DFfator_conversao * -1  as DFquantidade_vendida
           , TBvenda_diaria.DFestoque_atualizado
           , TBitem_estoque_atacado_varejo.DForigem_estoque 
        from TBvenda_diaria with (nolock)
       inner join TBunidade_item_estoque  with (nolock)
               on TBunidade_item_estoque.DFid_unidade_item_estoque = TBvenda_diaria.DFid_unidade_item_estoque
       inner join TBitem_estoque  with (nolock)
               on TBunidade_item_estoque.DFcod_item_estoque = TBitem_estoque.DFcod_item_estoque
       inner join TBparte_item_composto with (nolock)
               on TBparte_item_composto.DFcod_item_estoque = TBitem_estoque.DFcod_item_estoque
       inner join TBunidade_item_estoque as TBunidade_baixada with (nolock)
               on TBunidade_baixada.DFid_unidade_item_estoque = TBparte_item_composto.DFid_unidade_item_estoque
       inner join TBitem_estoque_atacado_varejo  with (nolock)
               on TBitem_estoque_atacado_varejo.DFcod_item_estoque_atacado_varejo = TBunidade_baixada.DFcod_item_estoque
       inner join VWPRECO1 with (nolock)
               on VWPRECO1.DFid_unidade_item_estoque = TBunidade_baixada.DFid_unidade_item_estoque
              and VWPRECO1.DFcod_empresa = TBvenda_diaria.DFcod_empresa
       where exists (
               select 1 from @tb_ids_venda_diaria
                where DFid_venda_diaria = TBvenda_diaria.DFid_venda_diaria)
         and TBitem_estoque_atacado_varejo.DForigem_estoque <> 'S'
         and TBitem_estoque.DFestoque_atualizado_baixa_venda = 1
       union
      select TBvenda_diaria.DFid_venda_diaria
           , TBvenda_diaria.DFcod_empresa
           , TBvenda_diaria.DFdata_venda
           , TBitem.DFunidade_controle as DFid_unidade_item_estoque
           , TBvenda_diaria.DFvalor_venda
           , TBvenda_diaria.DFcusto_venda
           , (TBunidade_item_estoque.DFfator_conversao * TBvenda_diaria.DFquantidade_vendida) * -1 as DFquantidade_vendida
           , TBvenda_diaria.DFestoque_atualizado
           , TBitem_estoque_atacado_varejo.DForigem_estoque
        from TBvenda_diaria  with (nolock)
       inner join TBunidade_item_estoque  with (nolock)
               on TBunidade_item_estoque.DFid_unidade_item_estoque = TBvenda_diaria.DFid_unidade_item_estoque
       inner join TBitem_estoque  with (nolock)
               on TBunidade_item_estoque.DFcod_item_estoque = TBitem_estoque.DFcod_item_estoque
       inner join TBitem_estoque_atacado_varejo  with (nolock)
               on TBitem_estoque_atacado_varejo.DFcod_item_estoque_atacado_varejo = TBitem_estoque.DFcod_item_estoque
       inner join TBitem_estoque_origem  with (nolock)
               on TBitem_estoque.DFcod_item_estoque = TBitem_estoque_origem.DFcod_item_estoque
       inner join TBitem_estoque as TBitem  with (nolock)
               on TBitem_estoque_origem.DFcod_item_estoque_origem = TBitem.DFcod_item_estoque
       where exists (
               select 1 from @tb_ids_venda_diaria
                where DFid_venda_diaria = TBvenda_diaria.DFid_venda_diaria)
         and TBitem_estoque_atacado_varejo.DForigem_estoque = 'S'
         and TBitem_estoque.DFestoque_atualizado_baixa_venda = 0 
       union
      select TBvenda_diaria.DFid_venda_diaria
           , TBvenda_diaria.DFcod_empresa
           , TBvenda_diaria.DFdata_venda
           , TBitem.DFunidade_controle as DFid_unidade_item_estoque
           , VWPRECO1.DFpreco_praticado * TBunidade_item_estoque.DFfator_conversao * TBvenda_diaria.DFquantidade_vendida * TBparte_item_composto.DFqtde * TBunidade_baixada.DFfator_conversao as DFvalor_venda
           , VWPRECO1.DFcusto_real * TBunidade_item_estoque.DFfator_conversao * TBvenda_diaria.DFquantidade_vendida * TBparte_item_composto.DFqtde * TBunidade_baixada.DFfator_conversao as DFcusto_venda
           , TBunidade_item_estoque.DFfator_conversao * TBvenda_diaria.DFquantidade_vendida * TBparte_item_composto.DFqtde * TBunidade_baixada.DFfator_conversao * -1 as DFquantidade_vendida
           , TBvenda_diaria.DFestoque_atualizado
           , TBitem_estoque_atacado_varejo.DForigem_estoque
        from TBvenda_diaria  with (nolock)
       inner join TBunidade_item_estoque  with (nolock)
               on TBunidade_item_estoque.DFid_unidade_item_estoque = TBvenda_diaria.DFid_unidade_item_estoque
       inner join TBitem_estoque  with (nolock)
               on TBunidade_item_estoque.DFcod_item_estoque = TBitem_estoque.DFcod_item_estoque
       inner join TBparte_item_composto with (nolock)
               on TBparte_item_composto.DFcod_item_estoque = TBitem_estoque.DFcod_item_estoque
       inner join TBunidade_item_estoque as TBunidade_baixada with (nolock)
               on TBunidade_baixada.DFid_unidade_item_estoque = TBparte_item_composto.DFid_unidade_item_estoque
       inner join TBitem_estoque_atacado_varejo  with (nolock)
               on TBitem_estoque_atacado_varejo.DFcod_item_estoque_atacado_varejo = TBunidade_baixada.DFcod_item_estoque 
       inner join TBitem_estoque_origem  with (nolock)
               on TBunidade_baixada.DFcod_item_estoque = TBitem_estoque_origem.DFcod_item_estoque
       inner join TBitem_estoque as TBitem with (nolock)
               on TBitem_estoque_origem.DFcod_item_estoque_origem = TBitem.DFcod_item_estoque
       inner join VWPRECO1 with (nolock)
               on VWPRECO1.DFid_unidade_item_estoque = TBitem.DFunidade_controle
              and VWPRECO1.DFcod_empresa = TBvenda_diaria.DFcod_empresa
       where exists (
               select 1 from @tb_ids_venda_diaria
                where DFid_venda_diaria = TBvenda_diaria.DFid_venda_diaria)
         and TBitem_estoque_atacado_varejo.DForigem_estoque = 'S'
         and TBitem_estoque.DFestoque_atualizado_baixa_venda = 1 
    )
    insert into @tb_resumo_venda
    select venda_diaria.DFcod_empresa
         , venda_diaria.DFid_unidade_item_estoque
         , TBunidade_item_estoque.DFcod_item_estoque
         , venda_diaria.DFestoque_atualizado
         , isnull(TBhistorico_estoque.DFquantidade_atual,0) as DFestoque_anterior
         , cast((sum(venda_diaria.DFvalor_venda) / sum(venda_diaria.DFquantidade_vendida*-1)) as decimal(18,2)) as DFvenda_media
         , cast((sum(venda_diaria.DFcusto_venda) / sum(venda_diaria.DFquantidade_vendida*-1)) as decimal(18,2)) as DFcusto_medio
         , sum(venda_diaria.DFquantidade_vendida) as DFquantidade_movimentada
         , isnull(TBhistorico_estoque.DFquantidade_atual,0) + sum(venda_diaria.DFquantidade_vendida) as DFestoque_atual
         , cast(0 as decimal (18,4)) as DFcusto_lucro
         , cast(0 as decimal (18,4)) as DFpreco_venda
      from venda_diaria
      left join rascunho.TBhistorico_estoque
             on TBhistorico_estoque.DFcod_empresa = venda_diaria.DFcod_empresa
            and TBhistorico_estoque.DFid_unidade_item_estoque = venda_diaria.DFid_unidade_item_estoque
            and TBhistorico_estoque.DFid_tipo_estoque = @id_tipo_estoque
            and TBhistorico_estoque.DFstatus = 1
     inner join TBunidade_item_estoque with (nolock)
             on venda_diaria.DFid_unidade_item_estoque = TBunidade_item_estoque.DFid_unidade_item_estoque
     group by venda_diaria.DFcod_empresa
            , venda_diaria.DFid_unidade_item_estoque
            , TBunidade_item_estoque.DFcod_item_estoque
            , venda_diaria.DFestoque_atualizado
            , TBhistorico_estoque.DFquantidade_atual 

    --
    -- MARCANDO O ESTOQUE ATUAL COMO HISTÓRICO
    --
    update rascunho.TBhistorico_estoque
       set DFstatus = 0
      from rascunho.TBhistorico_estoque
     inner join @tb_resumo_venda as venda_diaria
             on venda_diaria.DFcod_empresa = TBhistorico_estoque.DFcod_empresa
            and venda_diaria.DFid_unidade_item_estoque = TBhistorico_estoque.DFid_unidade_item_estoque
     where TBhistorico_estoque.DFstatus = 1
       and TBhistorico_estoque.DFid_tipo_estoque = @id_tipo_estoque

    --
    -- ATUALIZANDO O ESTOQUE
    --  
    insert into rascunho.TBhistorico_estoque (
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
