--
-- PROCEDURE host.jobtask_exemplo_de_job_manual
--
drop procedure if exists host.jobtask_exemplo_de_job_manual
go
create procedure host.jobtask_exemplo_de_job_manual
  -- parâmetros personalizados
  @parametro varchar(100),
  -- parâmetros especiais de contexto
  @cod_empresa int = null,
  @id_usuario int = null,
  -- parâmetros especiais do JOB
  @id_job bigint,
  @comando varchar(10),
  @instancia uniqueidentifier,
  @data_execucao datetime
  -- Um JOB é considerado manual quando não possui este parâmetro:
  -- @automatico bit
as
begin

  declare @msg varchar(max)
  set @msg = concat('@parametro=',@parametro)         raiserror (@msg,10,1) with nowait
  set @msg = concat('@cod_empresa=',@cod_empresa)     raiserror (@msg,10,1) with nowait
  set @msg = concat('@id_usuario=',@id_usuario)       raiserror (@msg,10,1) with nowait
  set @msg = concat('@id_job=',@id_job)               raiserror (@msg,10,1) with nowait
  set @msg = concat('@comando=',@comando)             raiserror (@msg,10,1) with nowait
  set @msg = concat('@instancia=',@instancia)         raiserror (@msg,10,1) with nowait
  set @msg = concat('@data_execucao=',@data_execucao) raiserror (@msg,10,1) with nowait
  
  raiserror ('Running job mannually: %s',10,1,@parametro) with nowait
end
go
