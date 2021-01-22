--
-- View de mapeamento da tabela TBopcoes do DIRECTOR.
--
exec ('
  use {ScriptPack.Mercadologic};
  if object_id(''mlogic.vw_opcoes'') is null begin
    exec(''
      create view mlogic.vw_opcoes
      as select * from {ScriptPack.Director}.dbo.TBopcoes
    '')
  end
')
