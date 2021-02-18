if object_id('mlogic.vw_replica_historico_venda_item') is not null begin
  exec sp_refreshview 'mlogic.vw_replica_historico_venda_item'
end
