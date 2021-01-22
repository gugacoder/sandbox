-- TODO: Temporariamente estamos direcionando o estoque para uma tabela de rascunho
-- para testes de comparação com a venda diária atual.
exec scriptpack.exec_sql '
  use {DBmercadologic};
  if object_id(''director.TBmotivo_movto_endereco'') is null begin
    exec(''
      create view director.TBmotivo_movto_endereco
      as select * from {DBdirector}.dbo.TBmotivo_movto_endereco
    '')
  end'
