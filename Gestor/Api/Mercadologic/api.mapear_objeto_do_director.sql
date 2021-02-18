drop procedure if exists api.mapear_objeto_do_director
go
create procedure api.mapear_objeto_do_director
  -- Nome de uma tabela ou view no DBDIRECTOR, precedido pelo esquema.
  -- Se o esquema for omitido será assumido o esquema 'dbo'.
  -- Exemplos:
  --    'TBusuario'
  --    'dbo.TBusuario'
  --    'vortex.TBusuario'
  @tabela sysname
as
-- Procedure de mapeamento de objetos do DIRECTOR
-- 
-- A procedure cria uma view no esquema 'director' apontando para o
-- objeto do DIRECTOR. O objeto pode ser uma tabela ou uma view.
--
-- Caso o objeto do DIRECTOR tenha um esquema diferente de 'dbo',
-- então, o nome do esquema será adicionado como prefixo no nome da view.
--
-- Exemplos:
--
--    exec api.criar_view_de_pont 'TBusuario'
--        Produz a view: 'director.TBusuario'
--
--    exec api.criar_view_de_pont 'dbo.TBusuario'
--        Produz a view: 'director.TBusuario'
--
--    exec api.criar_view_de_pont 'vortex.TBusuario'
--        Produz a view: 'director.vortex_TBusuario'
begin
  if @tabela is null begin
    raiserror ('Nome da tabela não informado.', 16, 1)
    return
  end

  declare @esquema sysname
  declare @objeto sysname
  declare @view sysname

  if @tabela like '%.%' begin
    set @esquema = api.SPLIT_PART(@tabela,'.',1)
    set @tabela = api.SPLIT_PART(@tabela,'.',2)
  end else begin
    set @esquema = 'dbo'
  end 

  set @objeto = concat(@esquema,'.',@tabela)
  if @esquema = 'dbo' begin
    set @view = concat('director.',@tabela)
  end else begin
    set @view = concat('director.',@esquema,'_',@tabela)
  end

  declare @sql varchar(400) = concat('
    use {DBmercadologic};
    if object_id(''',@view,''') is null begin
      exec(''
        create view ',@view,'
        as select * from {DBdirector}.',@objeto,'
      '')
    end else begin
      exec sp_refreshview ''',@view,'''
    end'
  )

  exec scriptpack.exec_sql @sql

end
go
