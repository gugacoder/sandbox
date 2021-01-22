exec scriptpack.exec_sql '
  use {DBmercadologic};
  if object_id(''director.TBitem_estoque_atacado_varejo'') is null begin
    exec(''
      create view director.TBitem_estoque_atacado_varejo
      as select * from {DBdirector}.dbo.TBitem_estoque_atacado_varejo
    '')
  end
'
