exec scriptpack.exec_sql '
  use {DBmercadologic};
  if object_id(''director.TBitem_estoque_origem'') is null begin
    exec(''
      create view director.TBitem_estoque_origem
      as select * from {DBdirector}.dbo.TBitem_estoque_origem
    '')
  end
'
