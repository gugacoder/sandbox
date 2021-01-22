exec scriptpack.exec_sql '
  use {DBmercadologic};
  if object_id(''director.VWPRECO1'') is null begin
    exec(''
      create view director.VWPRECO1
      as select * from {DBdirector}.dbo.VWPRECO1
    '')
  end
'
