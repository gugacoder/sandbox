--
-- PROCEDURE host.agendar_job
--
drop procedure if exists host.agendar_job
go
create procedure host.agendar_job
    @job sql_variant
  , @descricao nvarchar(100) = null
  , @data_execucao datetime = null
  , @args host.args readonly
as
begin
  declare @procedure varchar(100)
  declare @id_job int
  declare @tb_job table (DFid_job int)

  if sql_variant_property(@job, 'BaseType') = 'numeric' begin
    -- Para o JOB foi informado o valor de @@procid, pelo menos este é o esperado.
    -- Com @@procid recuperamos o nome da procedure que invocou esta.
    declare @procid int = cast(@job as int)
    set @procedure = concat(object_schema_name(@procid),'.',object_name(@procid))
  end else begin
    set @procedure = cast(@job as varchar(100))
  end

  insert into host.TBjob (
      DFprocedure
    , DFdescricao
    , DFdata_execucao
  )
  output inserted.DFid_job into @tb_job
  values (
      @procedure
    , @descricao
    , coalesce(@data_execucao, current_timestamp)
  )

  select @id_job = DFid_job from @tb_job
  
  insert into host.TBjob_parametro (DFid_job, DFparametro, DFvalor)
  select @id_job, chave, valor
    from @args

end
go
