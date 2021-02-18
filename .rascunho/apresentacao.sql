use DBmercadologic

-- exec replica.jobtask_replicar_mercadologic 'init'
-- exec dbo.jobtask_processar_venda_periodica 'init'
exec replica.jobtask_replicar_mercadologic 'exec', 7
exec dbo.jobtask_processar_venda_periodica 'exec', 7

select * from TBvenda_periodica
select * from director.TBvenda_diaria
select * from director.TBhistorico_estoque
