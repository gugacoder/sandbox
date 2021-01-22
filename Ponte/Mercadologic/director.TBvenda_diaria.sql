-- TODO: APENAS DURANTE OS TESTES VAMOS USAR UMA TABELA TEMPORARIA EM VEZ DA VIEW
/*
exec scriptpack.exec_sql '
  use {DBmercadologic};
  if object_id(''director.TBvenda_diaria'') is null begin
    exec(''
      create view director.TBvenda_diaria
      as select * from {DBdirector}.director.TBvenda_diaria
    '')
  end
'
*/
-- drop table director.TBvenda_diaria
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
