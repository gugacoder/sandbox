-- exec replica._tmp_monitorar_integracao_de_venda


select top 10 * from host.job_history
where [status] != 2