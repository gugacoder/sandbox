exec scriptpack.exec_sql '
  use DBmercadologic;
  if object_id(''director.TBunidade_item_estoque'') is null begin
    exec(''
      create view director.TBunidade_item_estoque
      as select * from DBdirector.dbo.TBunidade_item_estoque
    '')
  end
'
