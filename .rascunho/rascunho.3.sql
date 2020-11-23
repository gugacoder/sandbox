exec replica._tmp_monitorar_integracao_de_venda

-- select * from host.vw_pending_job
-- exec [host].[do_run_all_jobs] @instance='9768B94B-BDCC-4B74-81EF-791BF7179EF8'
-- select count(1) from replica.evento where replicado = 0
-- select data, * from replica.vw_evento order by replica.vw_evento.data desc


drop table replica.evento
drop view replica.vw_evento

select * from INFORMATION_SCHEMA.TABLES where table_schema = 'replica'
