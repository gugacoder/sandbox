exec scriptpack.exec_sql '
  use DBmercadologic;
  if object_id(''director.TBempresa'') is null begin
    exec(''
      create view director.TBempresa
      as select * from DBdirector.dbo.TBempresa
    '')
  end
'
