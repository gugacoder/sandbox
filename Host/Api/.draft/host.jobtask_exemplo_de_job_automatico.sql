--
-- PROCEDURE host.jobtask_exemplo_de_job_automatico
--
drop procedure if exists host.jobtask_exemplo_de_job_automatico
go
create procedure host.jobtask_exemplo_de_job_automatico
  -- parâmetros especiais de contexto
  @cod_empresa int,
  @id_usuario int,
  -- parâmetros especiais do JOB
  @id_job bigint,
  @comando varchar(10),
  @instancia uniqueidentifier,
  @data_execucao datetime,
  @automatico bit
as
begin

  declare @msg varchar(max)
  set @msg = concat('@cod_empresa=',@cod_empresa)     raiserror (@msg,10,1) with nowait
  set @msg = concat('@id_usuario=',@id_usuario)       raiserror (@msg,10,1) with nowait
  set @msg = concat('@id_job=',@id_job)               raiserror (@msg,10,1) with nowait
  set @msg = concat('@comando=',@comando)             raiserror (@msg,10,1) with nowait
  set @msg = concat('@instancia=',@instancia)         raiserror (@msg,10,1) with nowait
  set @msg = concat('@data_execucao=',@data_execucao) raiserror (@msg,10,1) with nowait
  set @msg = concat('@automatico=',@automatico)       raiserror (@msg,10,1) with nowait
  
  if @comando = 'init' begin
    
    if @data_execucao is null set @data_execucao = current_timestamp

    exec host.agendar_job
      @job=@@procid,
      @descricao='Exemplo de JOB automático',
      @data_execucao=@data_execucao

  end else if @comando = 'exec' begin

    declare @job_data_execucao datetime = current_timestamp
    declare @args host.args

    insert into @args values ('@parametro', 'Hello, world! It works! It really works!')

    exec host.agendar_job
      @job='host.jobtask_exemplo_de_job_manual',
      @descricao='Executando um outro JOB manualmente...',
      @data_execucao=@job_data_execucao,
      @args=@args

  end
end
go
