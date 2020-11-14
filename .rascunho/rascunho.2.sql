

select * from host.vw_jobtask
select * from host.vw_jobtask_parameter


-- exec host.jobtask_exemplo_de_job_automatico @cod_empresa, @id_usuario, @comando, @instancia, @data_execucao, @automatico


/*
exec sp_describe_undeclared_parameters @tsql =   
N'SELECT object_id, name, type_desc   
FROM sys.indexes  
WHERE object_id = @id OR NAME = @name',  
@params = N'@id int'  
  */
