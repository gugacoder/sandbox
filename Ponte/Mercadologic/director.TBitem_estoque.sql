exec scriptpack.exec_sql '
  use {DBmercadologic};
  if object_id(''director.TBitem_estoque'') is null begin
    exec(''
      create view director.TBitem_estoque
      as select * from {DBdirector}.dbo.TBitem_estoque
    '')
  end
'
