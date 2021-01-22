-- TODO: APENAS DURANTE OS TESTES VAMOS USAR UMA TABELA TEMPORARIA EM VEZ DA VIEW
/*
exec scriptpack.exec_sql '
  use {DBmercadologic};
  if object_id(''director.TBhistorico_estoque'') is null begin
    exec(''
      create view director.TBhistorico_estoque
      as select * from {DBdirector}.dbo.TBhistorico_estoque
    '')
  end
'
*/
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
