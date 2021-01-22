exec scriptpack.exec_sql '
  use DBmercadologic;
  if object_id(''director.TBempresa_atacado_varejo'') is null begin
    exec(''
      create view director.TBempresa_atacado_varejo
      as select * from DBdirector.dbo.TBempresa_atacado_varejo
    '')
  end
'
