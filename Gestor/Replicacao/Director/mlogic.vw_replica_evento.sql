--
-- VIEW mlogic.vw_evento
--
drop view if exists mlogic.vw_replica_evento
go
create view mlogic.vw_replica_evento as 
select * from {ScriptPack.Mercadologic}.replica.evento
go

