



declare @args host.args
declare @instancia uniqueidentifier = newid()

insert into @args values ('@cod_empresa', 7)
insert into @args values ('@id_usuario', 1)
insert into @args values ('@parametro', N'Olá, mundo!')
insert into @args values ('@none', null)
insert into @args values ('@id_job', 140404)
insert into @args values ('@instancia', @instancia)

exec host.executar_job 'host.jobtask_exemplo_de_job_manual'
  , @args=@args, @instancia=@instancia, @automatico=1, @comando='init'

-- exec host.jobtask_exemplo_de_job_automatico @cod_empresa, @id_usuario, @comando, @instancia, @data_execucao, @automatico






/*
exec sp_describe_undeclared_parameters @tsql =   
N'SELECT object_id, name, type_desc   
FROM sys.indexes  
WHERE object_id = @id OR NAME = @name',  
@params = N'@id int'  
  */
