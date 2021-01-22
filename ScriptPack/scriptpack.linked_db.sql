drop procedure if exists scriptpack.linked_db
go
create procedure scriptpack.linked_db
as
  --
  --  Função de obtenção do nome de uma base de dados mapeada pelo ScriptPack.
  --
  --  Retorno:
  --      0   A vinculação de bases é suportada.
  --     -1   A vinculação de bases não é suportada.
  --          Os objetos de ligação do ScriptPack, usados na pesquisa de vínculo
  --          de bases, não existem na base de dados.
  --          Será necessário executar um ScriptPack pelo menos uma vez para
  --          corrigir o problema.
  --
begin
  declare @bases table (
    kind varchar(400) not null,
    name varchar(400) not null,
    valid bit not null,
    fault varchar(400) null
  )

  --
  --  DETECTANDO SCRIPTPACK...
  --

  if object_id('scriptpack.bindings') is null begin
    --  A vinculação de bases não é suportada.
    --  Os objetos de ligação do ScriptPack, usados na pesquisa de vínculo
    --  de bases, não existe na base de dados.
    --  Será necessário executar um ScriptPack pelo menos uma vez para
    --  corrigir o problema.
    declare @current_db varchar(400) = db_name()
    RAISERROR(
      '[SCRIPTPACK.DB_NAME]: CONFIGURAÇÃO INCORRETA! O suporte ao ScriptPack nesta base `%s` está comprometido. Será necessário executar um ScriptPack pelo menos uma vez para corrigir o problema.'
      ,10,1,@current_db) WITH NOWAIT

    select * from @bases
    return -1
  end

  --
  --  VALIDANDO AS BASES VINCULADAS
  --
  insert into @bases (kind, name, valid, fault)
  select kind, name, 0, 'O vínculo entre as bases não foi verificado.'
    from scriptpack.bindings

  declare @db_kind varchar(400)
  declare @db_name varchar(400)
  declare @scriptpack_supported bit
  declare @linked_back bit
  declare @sql nvarchar(4000)

  select @db_kind = min(kind) from @bases
  while @db_kind is not null begin
    select @db_name = name from @bases where kind = @db_kind

    set @scriptpack_supported = object_id(concat(@db_name,'.scriptpack.bindings'))

    set @linked_back = 0
    if @scriptpack_supported = 1 begin
      set @sql = concat('
          select @linked_back=count(1)
            from ',@db_name,'.scriptpack.bindings
           where name = ''',db_name(),'''')
      execute sp_executesql @sql, N'@linked_back bit output', @linked_back=@linked_back output
    end

    update @bases
       set valid = @linked_back
         , fault = case
             when @scriptpack_supported = 0 then
               concat('Esta base está vinculada à base `',@db_name,'` mas a base `',@db_name,'` não possui suporte ao ScriptPack, portanto, não pode ser considerada uma base vinculada.')
             when @linked_back = 0 then
               concat('Esta base está vinculada à base `',@db_name,'` mas a base `',@db_name,'` não se vincula de volta a esta base.')
             else null
           end
     where kind = @db_kind

    select @db_kind = min(kind) from @bases where kind > @db_kind
  end

  select * from @bases
end
go
