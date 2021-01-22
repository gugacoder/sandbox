exec scriptpack.exec_sql '
  use {DBmercadologic};
  if object_id(''director.TBusuario'') is null begin
    exec(''
      create view director.TBusuario
      as select * from {DBdirector}.dbo.TBusuario
    '')
  end
'
