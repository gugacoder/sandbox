--
-- PROCEDURE host.agendar_job
--
drop procedure if exists host.agendar_job
go
create procedure host.desagendar_job
    @job sql_variant
  , @data_execucao datetime = null
as
begin
  declare @procedure varchar(100)

  if sql_variant_property(@job, 'BaseType') = 'numeric' begin
    -- Para o JOB foi informado o valor de @@procid, pelo menos este é o esperado.
    -- Com @@procid recuperamos o nome da procedure que invocou esta.
    declare @procid int = cast(@job as int)
    set @procedure = concat(object_schema_name(@procid),'.',object_name(@procid))
  end else begin
    set @procedure = cast(@job as varchar(100))
  end

  delete from host.TBjob
   where DFprocedure = @procedure
     and (@data_execucao is null or DFdata_execucao = @data_execucao)
end
go
