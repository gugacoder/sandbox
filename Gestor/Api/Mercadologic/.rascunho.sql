
if object_id('director.TBhistorico_estoque') is null begin
  create table director.TBhistorico_estoque (
    DFid_historico_estoque int identity(1,1) not null,
    DFcod_empresa int not null,
    DFid_usuario int not null,
    DFid_unidade_item_estoque int not null,
    DFcod_motivo_movto_endereco int not null,
    DFid_tipo_estoque int not null,
    DFstatus tinyint not null,
    DFdata_alteracao smalldatetime not null,
    DFquantidade_movimentada decimal(18, 3) null,
    Dfquantidade_Atual decimal(18, 3) null,
    DFpreco_venda decimal(18, 4) null,
    DFcusto_real decimal(18, 4) null,
    DFid_formulario int not null default (0),
    DFcomplemento nvarchar(50) null,
    DFtipo_lancamento nvarchar(1) not null default ('M'),
    DFpendencia bit not null default (0),
    DFmotivo_perda bit not null default (0),
    DFmotivo_quebra bit not null default (0),
    DFmotivo_uso_consumo bit not null default (0),
    DFcod_setor_alteracao_estoque int null
  )
end


if object_id('director.TBvenda_diaria') is null begin
  create table director.TBvenda_diaria (
    DFid_venda_diaria bigint identity(1,1) not null,
    DFid_unidade_item_estoque int not null,
    DFcod_empresa int not null,
    DFdata_venda smalldatetime not null,
    DFquantidade_vendida decimal(18, 4) not null,
    DFvalor_venda decimal(18, 4) not null,
    DFcusto_venda decimal(18, 4) not null,
    DFvalor_icms decimal(18, 4) not null,
    DFvalor_pis decimal(18, 6) not null,
    DFvalor_cofins decimal(18, 6) not null,
    DFvalor_encargos decimal(18, 6) not null,
    DFestoque_atualizado bit not null default 0,
    DFvalor_desconto decimal(18, 4) not null,
    DFcusto_contabil_venda decimal(18, 4) not null
  )
  
  create index IX__TBvenda_diaria__DFid_unidade_item_estoque
      on director.TBvenda_diaria (DFid_unidade_item_estoque)

  create index IX__TBvenda_diaria__DFcod_empresa
      on director.TBvenda_diaria (DFcod_empresa)

  create index IX__TBvenda_diaria__DFdata_venda
      on director.TBvenda_diaria (DFdata_venda)

  create index IX__TBvenda_diaria__DFestoque_atualizado
      on director.TBvenda_diaria (DFestoque_atualizado)
end
