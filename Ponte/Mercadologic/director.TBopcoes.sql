exec scriptpack.exec_sql '
  use {DBmercadologic};
  if object_id(''director.TBopcoes'') is null begin
    exec(''
      create view director.TBopcoes
      as select * from {DBdirector}.dbo.TBopcoes
    '')
  end
'
