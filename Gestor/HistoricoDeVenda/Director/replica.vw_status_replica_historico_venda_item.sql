--
-- TABELA mlogic.vw_status_historico_venda_item
--
exec ('
  use {ScriptPack.Director};
  if object_id(''mlogic.vw_status_historico_venda_item'') is null begin
    exec(''
      create view mlogic.vw_status_historico_venda_item
      as select * from {ScriptPack.Mercadologic}.replica.status_historico_venda_item
    '')
  end
')
