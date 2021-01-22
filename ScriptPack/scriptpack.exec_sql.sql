drop procedure if exists scriptpack.exec_sql
go
create procedure scriptpack.exec_sql (@sql nvarchar(max))
as
  -- 
  --  Procedimento de execução de uma SQL com abstração do nome de bases
  --  de dados vinculadas pelo ScriptPack.
  --
  --  Variável com o nome da base de dados é substituída pelo nome mapeado
  --  pelo ScriptPack.
  --  
  --  A variável pode ser especificada em uma das seguintes formas:
  --      {NomeDaBase}
  --      {DBnome_da_base}
  --      {ScriptPack.NomeDaBase}
  --      {ScriptPack.DBnome_da_base}
  --
  --  Exemplo:
  --      exec scriptpack.exec_sql '
  --        create view {Mercadologic}.director.TBopcoes
  --        as select * from {Director}.dbo.TBopcoes'
  --
begin
  declare @bases table (
    kind varchar(400),
    name varchar(400),
    valid bit,
    fault varchar(400)
  )

  insert into @bases
    exec scriptpack.linked_db

  select @sql = replace(@sql, concat('{ScriptPack.DB',kind,'}'), name)
       , @sql = replace(@sql, concat('{ScriptPack.DB',kind,'}'), name)
       , @sql = replace(@sql, concat('{DB',kind,'}'), name)
       , @sql = replace(@sql, concat('{',kind,'}'), name)
    from @bases
   where valid = 1
   order by len(kind) desc

  RAISERROR('[EXEC SQL]: %s',10,1,@sql) WITH NOWAIT

  exec sp_executesql @sql
end
go

exec scriptpack.exec_sql 'select top 10 * from {DBdirector}.dbo.TBopcoes'
