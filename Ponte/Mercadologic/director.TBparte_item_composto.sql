exec scriptpack.exec_sql '
  use {DBmercadologic};
  if object_id(''director.TBparte_item_composto'') is null begin
    exec(''
      create view director.TBparte_item_composto
      as select * from {DBdirector}.dbo.TBparte_item_composto
    '')
  end
'
